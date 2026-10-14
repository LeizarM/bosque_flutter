import 'package:bosque_flutter/core/ui/mensaje_error_tareas.dart';
import 'package:bosque_flutter/data/repositories/caja_chica_flujo_impl.dart';
import 'package:bosque_flutter/domain/repositories/caja_chica_flujo_repository.dart';
import 'package:bosque_flutter/domain/entities/caja_chica_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_caja_chica_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Marca de "no cambiar" para poder limpiar `errorCarga` pasándole null.
const _igual = Object();

class CajaChicaFlujoState {
  final List<CajaChicaEntity> items;
  final bool cargando;

  /// Si alguna lectura terminó bien; evita mostrar «sin movimientos» tras una
  /// lectura fallida.
  final bool cargado;

  /// Por qué falló la última lectura; queda hasta la próxima buena.
  final Object? errorCarga;
  final bool guardando;
  final bool cerrandoLote;
  final String? mensajeError;

  /// Talonarios de vales entregados a la sucursal (archivo SQL 93).
  final List<TalonarioCajaChica> talonarios;

  /// Por qué no se pudieron leer los talonarios; el libro sigue sirviendo.
  final Object? errorTalonarios;

  /// Las reglas del número de recibo en palabras (archivo SQL 99); null si
  /// no llegaron. Las escribe el SP: la app no repite reglas.
  final ReglasReciboCajaChica? reglas;

  const CajaChicaFlujoState({
    this.items = const [],
    this.cargando = false,
    this.cargado = false,
    this.errorCarga,
    this.guardando = false,
    this.cerrandoLote = false,
    this.mensajeError,
    this.talonarios = const [],
    this.errorTalonarios,
    this.reglas,
  });

  CajaChicaFlujoState copyWith({
    List<CajaChicaEntity>? items,
    bool? cargando,
    bool? cargado,
    Object? errorCarga = _igual,
    bool? guardando,
    bool? cerrandoLote,
    String? mensajeError,
    List<TalonarioCajaChica>? talonarios,
    Object? errorTalonarios = _igual,
    Object? reglas = _igual,
  }) => CajaChicaFlujoState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    cargado: cargado ?? this.cargado,
    errorCarga: identical(errorCarga, _igual) ? this.errorCarga : errorCarga,
    guardando: guardando ?? this.guardando,
    cerrandoLote: cerrandoLote ?? this.cerrandoLote,
    mensajeError: mensajeError,
    talonarios: talonarios ?? this.talonarios,
    errorTalonarios:
        identical(errorTalonarios, _igual)
            ? this.errorTalonarios
            : errorTalonarios,
    reglas:
        identical(reglas, _igual)
            ? this.reglas
            : reglas as ReglasReciboCajaChica?,
  );

  double get saldoActual => items.isEmpty ? 0 : (items.last.saldo ?? 0);

  /// Monto con que abrió el lote: la primera fila, sembrada por
  /// `p_list_tac_CajaChica` ACCION='D' como «Saldo inicial del lote».
  double get saldoInicial => items.isEmpty ? 0 : (items.first.montoIng ?? 0);

  /// Suma de las filas, no `inicial - actual`: una reposición como `montoIng`
  /// a mitad de lote daría un egreso menor al real.
  double get totalEgresos =>
      items.fold<double>(0, (a, f) => a + (f.montoEg ?? 0));

  /// Movimientos reales, sin contar la fila sembrada de saldo inicial.
  int get cantidadEgresos => items.where((f) => (f.montoEg ?? 0) > 0).length;

  /// El talonario del que sale el próximo vale: el activo (archivo SQL 97),
  /// que el SP pone primero. Sin el 97, el primero con vales libres.
  TalonarioCajaChica? get talonarioEnUso {
    for (final t in talonarios) {
      if (t.activo && t.siguienteVale != null) return t;
    }
    for (final t in talonarios) {
      if (t.siguienteVale != null) return t;
    }
    return null;
  }

  /// Entregados que esperan su turno: tienen vales libres y no son el activo.
  int get talonariosEnEspera =>
      talonarios.where((t) => !t.activo && t.siguienteVale != null).length;

  /// Si el número de recibo es obligatorio. Lo dice el SP; sin sus reglas,
  /// lo es cuando hay talonarios.
  bool get reciboObligatorio => reglas?.obligatorio ?? talonarios.isNotEmpty;

  /// Tiene talonarios, pero ya se usó el último recibo de todos.
  bool get sinVales => talonarios.isNotEmpty && talonarioEnUso == null;
}

/// La caja chica de tu sucursal (archivo SQL 96). No hay ocurrencia ni
/// parámetros: el backend saca la sucursal del cargo vigente del token.
class CajaChicaFlujoNotifier extends StateNotifier<CajaChicaFlujoState> {
  final CajaChicaFlujoRepository _repo;

  CajaChicaFlujoNotifier(this._repo)
    // Arranca cargando: en reposo, el primer cuadro se vería como un error.
    : super(const CajaChicaFlujoState(cargando: true)) {
    Future.microtask(() => cargar());
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true);
    await Future.wait([_cargarLibro(), _cargarTalonarios(), _cargarReglas()]);
  }

  Future<void> _cargarReglas() async {
    try {
      final reglas = await _repo.reglasRecibo();
      if (!mounted) return;
      state = state.copyWith(reglas: reglas, mensajeError: state.mensajeError);
    } catch (_) {
      // Sin las reglas el formulario igual sirve: el SP valida al registrar.
    }
  }

  Future<void> _cargarTalonarios() async {
    try {
      final talonarios = await _repo.talonarios();
      if (!mounted) return;
      state = state.copyWith(
        talonarios: talonarios,
        errorTalonarios: null,
        mensajeError: state.mensajeError,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        errorTalonarios: e,
        mensajeError: state.mensajeError,
      );
    }
  }

  Future<void> _cargarLibro() async {
    try {
      final items = await _repo.listarDelLote();
      if (!mounted) return;
      state = state.copyWith(
        cargando: false,
        cargado: true,
        errorCarga: null,
        items: items,
      );
    } catch (e) {
      if (!mounted) return;
      // Con el libro ya en pantalla se queda y se avisa; en la primera
      // lectura la pantalla muestra el error en su lugar.
      state = state.copyWith(
        cargando: false,
        errorCarga: e,
        mensajeError: state.cargado ? mensajeError(e) : null,
      );
    }
  }

  Future<bool> registrarEgreso({
    required double montoEg,
    required String descripcion,
    int? codEmpDestino,
    int? numFactura,
    int? numVale,
    DateTime? fecha,
  }) async {
    state = state.copyWith(guardando: true);
    try {
      await _repo.registrarEgreso(
        montoEg: montoEg,
        descripcion: descripcion,
        codEmpDestino: codEmpDestino,
        numFactura: numFactura,
        numVale: numVale,
        fecha: fecha,
      );
      if (!mounted) return true;
      // `guardando` sigue en true hasta recargar: un segundo toque no graba
      // dos veces. Se conserva el aviso que haya dejado la recarga.
      await cargar();
      if (!mounted) return true;
      state = state.copyWith(
        guardando: false,
        mensajeError: state.mensajeError,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(guardando: false, mensajeError: mensajeError(e));
      return false;
    }
  }

  /// Cierra el lote vigente y abre uno nuevo (con saldo inicial sembrado).
  /// Recarga el lote nuevo.
  /// Devuelve `true` si cerró; el error queda en [CajaChicaFlujoState.mensajeError].
  Future<bool> cerrarLote() async {
    state = state.copyWith(cerrandoLote: true);
    try {
      await _repo.cerrarLote();
      if (!mounted) return true;
      await cargar();
      if (!mounted) return true;
      state = state.copyWith(
        cerrandoLote: false,
        mensajeError: state.mensajeError,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        cerrandoLote: false,
        mensajeError: mensajeError(e),
      );
      return false;
    }
  }
}

/// Público para que las pruebas pongan un repositorio falso.
final cajaChicaFlujoRepoProvider = Provider<CajaChicaFlujoRepository>(
  (ref) => CajaChicaFlujoImpl(),
);

final cajaChicaFlujoProvider = StateNotifierProvider.autoDispose<
  CajaChicaFlujoNotifier,
  CajaChicaFlujoState
>((ref) => CajaChicaFlujoNotifier(ref.read(cajaChicaFlujoRepoProvider)));
