import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart'
    show mensajeDeErrorCheque, relojChequesProvider;
import 'package:bosque_flutter/data/repositories/verificaciones_impl.dart';
import 'package:bosque_flutter/domain/entities/cheque_pendiente_verificacion_entity.dart';
import 'package:bosque_flutter/domain/entities/opcion_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/pagina_verificacion_entity.dart';
import 'package:bosque_flutter/domain/entities/pendientes_verificacion_filtro_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_filtro_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_preparada_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_registro_entity.dart';
import 'package:bosque_flutter/domain/repositories/verificaciones_repository.dart';

/// Repositorio de «Verificar Cheques» (vista 77).
///
/// Perezoso y tipado contra la interfaz: `main.dart` no lo conoce y una prueba lo
/// sustituye con `verificacionesRepositoryProvider.overrideWithValue(falso)`.
final verificacionesRepositoryProvider = Provider<VerificacionesRepository>(
  (ref) => VerificacionesImpl(),
);

/// Los estados de cheque (`PEN` / `CER`) del filtro del modal de pendientes.
/// Cambian nunca: se piden una vez por sesion. Si falla, `ref.invalidate` los
/// vuelve a pedir.
final estadosChequeVerificacionProvider =
    FutureProvider<List<OpcionChequeEntity>>(
      (ref) => ref.watch(verificacionesRepositoryProvider).obtenerEstadosCheque(),
    );

/// Hoy, sin hora, segun el reloj del modulo de cheques (una prueba lo fija con
/// `relojChequesProvider`).
DateTime _hoy(Ref ref) {
  final n = ref.read(relojChequesProvider)();
  return DateTime(n.year, n.month, n.day);
}

// ═══════════════════════════════════════════════════════════════════════════
// LISTA PRINCIPAL
// ═══════════════════════════════════════════════════════════════════════════

/// Estado de la lista principal: el dia consultado, la pagina y lo que devolvio
/// el servidor.
@immutable
class EstadoGrillaVerificaciones {
  const EstadoGrillaVerificaciones({
    required this.filtro,
    this.resultado,
    this.cargando = false,
    this.error,
    this.iniciado = false,
  });

  /// Dia, pagina y tamano que se consultan.
  final VerificacionFiltroEntity filtro;

  /// La ultima pagina recibida. Null antes de la primera consulta o tras un
  /// error; durante una recarga se conserva la anterior para que la tabla no
  /// parpadee.
  final PaginaVerificacionEntity<VerificacionFilaEntity>? resultado;

  final bool cargando;

  /// El mensaje del backend de la ultima consulta fallida, listo para mostrar.
  final String? error;

  /// Ya se hizo la primera consulta.
  final bool iniciado;

  DateTime? get fechaBanco => filtro.fechaBanco;
  int get pagina => filtro.pagina;
  List<VerificacionFilaEntity> get filas => resultado?.filas ?? const [];
  int get total => resultado?.total ?? 0;
  int get totalPaginas => resultado?.totalPaginas ?? 0;
  bool get hayAnterior => filtro.pagina > 1;
  bool get haySiguiente => filtro.pagina < totalPaginas;

  /// Consulto bien y no hubo ninguna fila: estado vacio, no un error.
  bool get sinResultados =>
      !cargando && error == null && resultado != null && resultado!.filas.isEmpty;

  EstadoGrillaVerificaciones copyWith({
    VerificacionFiltroEntity? filtro,
    PaginaVerificacionEntity<VerificacionFilaEntity>? resultado,
    bool? cargando,
    String? error,
    bool? iniciado,
    bool limpiarError = false,
  }) => EstadoGrillaVerificaciones(
    filtro: filtro ?? this.filtro,
    resultado: resultado ?? this.resultado,
    cargando: cargando ?? this.cargando,
    error: limpiarError ? null : (error ?? this.error),
    iniciado: iniciado ?? this.iniciado,
  );
}

/// La lista principal: las verificaciones de un dia (hoy al abrir) o de todos.
/// Toda la paginacion es del servidor.
///
/// autoDispose: al salir de la pantalla se libera y la proxima visita empieza
/// limpia, con hoy. Si dos consultas se cruzan solo vale la ultima: la respuesta
/// vieja se descarta en vez de pisar a la nueva.
class GrillaVerificacionesNotifier
    extends StateNotifier<EstadoGrillaVerificaciones> {
  GrillaVerificacionesNotifier(Ref ref)
    : _ref = ref,
      super(
        EstadoGrillaVerificaciones(
          filtro: VerificacionFiltroEntity(fechaBanco: _hoy(ref)),
        ),
      );

  final Ref _ref;
  int _consulta = 0;

  VerificacionesRepository get _repo => _ref.read(verificacionesRepositoryProvider);

  /// Hoy, segun el reloj del modulo.
  DateTime get hoy => _hoy(_ref);

  /// La primera consulta, la del dia de hoy. Repetirla no hace nada.
  Future<void> iniciar() async {
    if (state.iniciado) return;
    state = state.copyWith(iniciado: true);
    await _cargar();
  }

  Future<void> recargar() => _cargar();

  /// Cambia el dia consultado (null = todas las verificaciones) y vuelve a la
  /// primera pagina.
  Future<void> buscarPorFecha(DateTime? fecha) {
    final dia = fecha == null ? null : DateTime(fecha.year, fecha.month, fecha.day);
    state = state.copyWith(
      filtro: VerificacionFiltroEntity(
        fechaBanco: dia,
        pagina: 1,
        tamanio: state.filtro.tamanio,
      ),
    );
    return _cargar();
  }

  Future<void> irAHoy() => buscarPorFecha(hoy);

  Future<void> siguiente() => _irA(state.pagina + 1);
  Future<void> anterior() => _irA(state.pagina - 1);

  Future<void> _irA(int pagina) {
    if (pagina < 1) return Future.value();
    state = state.copyWith(filtro: state.filtro.copyWith(pagina: pagina));
    return _cargar();
  }

  Future<void> _cargar() async {
    final mia = ++_consulta;
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final r = await _repo.listar(state.filtro);
      if (!mounted || mia != _consulta) return;
      // Si la pagina pedida ya no existe (se anularon filas), el servidor la
      // acota a la ultima: la pantalla sigue a lo que dice el servidor.
      state = state.copyWith(
        resultado: r,
        cargando: false,
        filtro: state.filtro.copyWith(pagina: r.pagina),
      );
    } catch (e) {
      if (!mounted || mia != _consulta) return;
      state = state.copyWith(cargando: false, error: mensajeDeErrorCheque(e));
    }
  }
}

final grillaVerificacionesProvider = StateNotifierProvider.autoDispose<
  GrillaVerificacionesNotifier,
  EstadoGrillaVerificaciones
>((ref) => GrillaVerificacionesNotifier(ref));

// ═══════════════════════════════════════════════════════════════════════════
// MODAL «CHEQUES PENDIENTES SIN REGULARIZAR»
// ═══════════════════════════════════════════════════════════════════════════

@immutable
class EstadoPendientesVerificacion {
  const EstadoPendientesVerificacion({
    this.filtro = const PendientesVerificacionFiltroEntity(),
    this.resultado,
    this.cargando = false,
    this.error,
  });

  final PendientesVerificacionFiltroEntity filtro;
  final PaginaVerificacionEntity<ChequePendienteVerificacionEntity>? resultado;
  final bool cargando;
  final String? error;

  int get pagina => filtro.pagina;
  List<ChequePendienteVerificacionEntity> get filas =>
      resultado?.filas ?? const [];
  int get total => resultado?.total ?? 0;
  int get totalPaginas => resultado?.totalPaginas ?? 0;
  bool get hayAnterior => filtro.pagina > 1;
  bool get haySiguiente => filtro.pagina < totalPaginas;

  bool get sinResultados =>
      !cargando && error == null && resultado != null && resultado!.filas.isEmpty;

  EstadoPendientesVerificacion copyWith({
    PendientesVerificacionFiltroEntity? filtro,
    PaginaVerificacionEntity<ChequePendienteVerificacionEntity>? resultado,
    bool? cargando,
    String? error,
    bool limpiarError = false,
  }) => EstadoPendientesVerificacion(
    filtro: filtro ?? this.filtro,
    resultado: resultado ?? this.resultado,
    cargando: cargando ?? this.cargando,
    error: limpiarError ? null : (error ?? this.error),
  );
}

/// Los cheques sin verificacion valida que ofrece el modal «Nuevo». Abre con lo
/// que abria el legacy (`inicializarModal`): cheques pendientes y solo los de
/// fecha de cobranza de hoy.
///
/// autoDispose: cada vez que se abre el modal empieza de cero.
class PendientesVerificacionNotifier
    extends StateNotifier<EstadoPendientesVerificacion> {
  PendientesVerificacionNotifier(Ref ref)
    : _ref = ref,
      super(const EstadoPendientesVerificacion());

  final Ref _ref;
  int _consulta = 0;

  VerificacionesRepository get _repo => _ref.read(verificacionesRepositoryProvider);

  Future<void> iniciar() => _cargar();
  Future<void> recargar() => _cargar();

  /// Cambia el estado del cheque (null = todos) y vuelve a la primera pagina.
  Future<void> elegirEstado(String? estado) {
    state = state.copyWith(
      filtro: PendientesVerificacionFiltroEntity(
        estado: estado,
        soloCobranzaHoy: state.filtro.soloCobranzaHoy,
        pagina: 1,
        tamanio: state.filtro.tamanio,
      ),
    );
    return _cargar();
  }

  /// `true` = solo la fecha de cobranza de hoy; `false` = hoy y anteriores.
  Future<void> elegirSoloHoy(bool soloHoy) {
    state = state.copyWith(
      filtro: state.filtro.copyWith(soloCobranzaHoy: soloHoy, pagina: 1),
    );
    return _cargar();
  }

  Future<void> siguiente() => _irA(state.pagina + 1);
  Future<void> anterior() => _irA(state.pagina - 1);

  Future<void> _irA(int pagina) {
    if (pagina < 1) return Future.value();
    state = state.copyWith(filtro: state.filtro.copyWith(pagina: pagina));
    return _cargar();
  }

  Future<void> _cargar() async {
    final mia = ++_consulta;
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final r = await _repo.listarPendientes(state.filtro);
      if (!mounted || mia != _consulta) return;
      state = state.copyWith(
        resultado: r,
        cargando: false,
        filtro: state.filtro.copyWith(pagina: r.pagina),
      );
    } catch (e) {
      if (!mounted || mia != _consulta) return;
      state = state.copyWith(cargando: false, error: mensajeDeErrorCheque(e));
    }
  }
}

final pendientesVerificacionProvider = StateNotifierProvider.autoDispose<
  PendientesVerificacionNotifier,
  EstadoPendientesVerificacion
>((ref) => PendientesVerificacionNotifier(ref));

/// Cuantos cheques esperan una verificacion: pendientes, sin ninguna valida y con
/// fecha de cobranza de hoy o anterior. Es el «Sin verificar» del encabezado y
/// sale del `total` del servidor (se pide una fila, solo para leer el total).
/// Si falla, el encabezado simplemente no lo muestra.
final chequesSinVerificarProvider = FutureProvider.autoDispose<int>((ref) async {
  final r = await ref
      .watch(verificacionesRepositoryProvider)
      .listarPendientes(
        const PendientesVerificacionFiltroEntity(
          estado: 'PEN',
          soloCobranzaHoy: false,
          pagina: 1,
          tamanio: 1,
        ),
      );
  return r.total;
});

// ═══════════════════════════════════════════════════════════════════════════
// ESCRITURAS
// ═══════════════════════════════════════════════════════════════════════════

@immutable
class EstadoOperacionVerificacion {
  const EstadoOperacionVerificacion({this.ocupado = false, this.error});

  /// Hay una escritura (o una preparacion) en vuelo.
  final bool ocupado;

  /// El mensaje del backend de la ultima operacion fallida, tal cual.
  final String? error;
}

/// Registrar, anular y preparar una verificacion. Al guardar o anular bien,
/// relee la lista principal y la del modal (solo si hay una pantalla usandolas)
/// y vuelve a pedir cuantos cheques faltan por verificar.
class OperacionesVerificacionesNotifier
    extends StateNotifier<EstadoOperacionVerificacion> {
  OperacionesVerificacionesNotifier(this._ref)
    : super(const EstadoOperacionVerificacion());

  final Ref _ref;

  VerificacionesRepository get _repo => _ref.read(verificacionesRepositoryProvider);

  Future<T?> _ejecutar<T>(
    Future<T> Function() accion, {
    required bool refrescar,
  }) async {
    if (state.ocupado) return null;
    state = const EstadoOperacionVerificacion(ocupado: true);
    try {
      final r = await accion();
      if (!mounted) return r;
      state = const EstadoOperacionVerificacion();
      if (refrescar) _refrescar();
      return r;
    } catch (e) {
      if (mounted) {
        state = EstadoOperacionVerificacion(error: mensajeDeErrorCheque(e));
      }
      return null;
    }
  }

  /// Una escritura mueve la lista principal (entra, cambia o se anula una fila),
  /// la de pendientes (el cheque ya no esta pendiente) y el contador.
  void _refrescar() {
    if (_ref.exists(grillaVerificacionesProvider)) {
      _ref.read(grillaVerificacionesProvider.notifier).recargar();
    }
    _refrescarPendientes();
    _ref.invalidate(chequesSinVerificarProvider);
  }

  void _refrescarPendientes() {
    if (_ref.exists(pendientesVerificacionProvider)) {
      _ref.read(pendientesVerificacionProvider.notifier).recargar();
    }
  }

  void limpiarError() {
    if (state.error != null) state = const EstadoOperacionVerificacion();
  }

  /// Al elegir un cheque del modal. Es una lectura: no refresca nada salvo si
  /// falla, porque entonces la lista de pendientes esta vieja (el cheque ya lo
  /// verifico otro, o se cerro).
  Future<VerificacionPreparadaEntity?> preparar(BigInt codCheque) async {
    final r = await _ejecutar(() => _repo.preparar(codCheque), refrescar: false);
    if (r == null) _refrescarPendientes();
    return r;
  }

  /// Alta ([VerificacionRegistroEntity.codvd] 0) o edicion. Devuelve el `codvd`.
  Future<BigInt?> registrar(VerificacionRegistroEntity registro) =>
      _ejecutar(() => _repo.registrar(registro), refrescar: true);

  /// Devuelve el mensaje del servidor («Verificación anulada.» o que ya estaba
  /// anulada).
  Future<String?> anular(BigInt codvd) =>
      _ejecutar(() => _repo.anular(codvd), refrescar: true);
}

final operacionesVerificacionesProvider = StateNotifierProvider.autoDispose<
  OperacionesVerificacionesNotifier,
  EstadoOperacionVerificacion
>((ref) => OperacionesVerificacionesNotifier(ref));
