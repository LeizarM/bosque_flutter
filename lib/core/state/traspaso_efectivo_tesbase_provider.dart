import 'package:bosque_flutter/data/repositories/traspaso_efectivo_tesbase_impl.dart';
import 'package:bosque_flutter/domain/entities/traspaso_efectivo_tesbase_entity.dart';
import 'package:bosque_flutter/domain/repositories/traspaso_efectivo_tesbase_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado de la tarea 289, "Verificar Traspaso de Efectivo Entre Sistemas"
/// (idATR 11, TesBase). La ocurrencia del día D revisa lo registrado el día
/// hábil anterior (SQL 58); la pantalla deja mirar otro día, pero
/// "Sin pendientes" siempre es sobre el de la ocurrencia.
class TraspasoEfectivoTesBaseState {
  /// Qué día revisa la ocurrencia. Nulo hasta la primera lectura.
  final DiaRevisadoTesBase? diaRevisado;

  /// El día que se está mirando. Arranca en el revisado.
  final DateTime? dia;

  /// Las registradas en [dia], en cualquier estado.
  final List<TraspasoEfectivoTesBaseEntity> delDia;

  /// Si [delDia] es de verdad lo de [dia]. En falso mientras se lee otro día o
  /// si esa lectura falló: una lista vacía por un error no es "ese día no se
  /// registró nada".
  final bool diaLeido;
  final bool cargandoDia;

  /// Todas las pendientes, de cualquier fecha.
  final List<TraspasoEfectivoTesBaseEntity> pendientes;

  final bool cargando;

  /// Si alguna lectura completa terminó bien. Sin esto, "no pude leer" y "no
  /// hay pendientes" se ven igual, y lo segundo habilita cerrar el día.
  final bool cargado;

  /// El `codTes` que está viajando, para que dos toques no manden dos cierres.
  final int? cerrando;
  final bool cerrandoDia;

  final String? error;
  final String? aviso;

  const TraspasoEfectivoTesBaseState({
    this.diaRevisado,
    this.dia,
    this.delDia = const [],
    this.diaLeido = false,
    this.cargandoDia = false,
    this.pendientes = const [],
    this.cargando = false,
    this.cargado = false,
    this.cerrando,
    this.cerrandoDia = false,
    this.error,
    this.aviso,
  });

  /// Lo que falta cerrar para dar la ocurrencia por revisada: las pendientes
  /// registradas hasta el día revisado. Las de después le tocan a la
  /// ocurrencia siguiente. Es la misma cuenta que hace el servidor.
  List<TraspasoEfectivoTesBaseEntity> get pendientesHastaElDiaRevisado {
    final hasta = diaRevisado?.fechaRevisada;
    if (hasta == null) return pendientes;
    return [
      for (final p in pendientes)
        if (p.fechaRegistro == null || !p.fechaRegistro!.isAfter(hasta)) p,
    ];
  }

  /// Las pendientes registradas antes del día que se mira. No están en
  /// [delDia] y no pueden quedar fuera de la vista: son las más atrasadas.
  List<TraspasoEfectivoTesBaseEntity> get pendientesAnteriores {
    final d = dia;
    if (d == null) return const [];
    return [
      for (final p in pendientes)
        if (p.fechaRegistro != null && p.fechaRegistro!.isBefore(d)) p,
    ];
  }

  /// Si se está mirando el día que revisa la ocurrencia.
  bool get mirandoElDiaRevisado {
    final d = dia;
    final r = diaRevisado?.fechaRevisada;
    return d != null &&
        r != null &&
        d.year == r.year &&
        d.month == r.month &&
        d.day == r.day;
  }

  /// Lo único que habilita "Sin pendientes": se leyó bien y no queda ninguna
  /// hasta el día revisado.
  bool get puedeCerrarDia => cargado && pendientesHastaElDiaRevisado.isEmpty;

  TraspasoEfectivoTesBaseState copyWith({
    DiaRevisadoTesBase? diaRevisado,
    DateTime? dia,
    List<TraspasoEfectivoTesBaseEntity>? delDia,
    bool? diaLeido,
    bool? cargandoDia,
    List<TraspasoEfectivoTesBaseEntity>? pendientes,
    bool? cargando,
    bool? cargado,
    int? cerrando,
    bool limpiarCerrando = false,
    bool? cerrandoDia,
    String? error,
    String? aviso,
  }) {
    return TraspasoEfectivoTesBaseState(
      diaRevisado: diaRevisado ?? this.diaRevisado,
      dia: dia ?? this.dia,
      delDia: delDia ?? this.delDia,
      diaLeido: diaLeido ?? this.diaLeido,
      cargandoDia: cargandoDia ?? this.cargandoDia,
      pendientes: pendientes ?? this.pendientes,
      cargando: cargando ?? this.cargando,
      cargado: cargado ?? this.cargado,
      cerrando: limpiarCerrando ? null : (cerrando ?? this.cerrando),
      cerrandoDia: cerrandoDia ?? this.cerrandoDia,
      // De un solo uso: si se arrastraran, un error viejo reaparecería en cada
      // recarga.
      error: error,
      aviso: aviso,
    );
  }
}

class TraspasoEfectivoTesBaseNotifier
    extends StateNotifier<TraspasoEfectivoTesBaseState> {
  final TraspasoEfectivoTesBaseRepository _repo;

  /// La ocurrencia de la tarea: de ella sale el día que se revisa.
  final int idBitTarea;

  TraspasoEfectivoTesBaseNotifier(this._repo, this.idBitTarea)
    : super(const TraspasoEfectivoTesBaseState(cargando: true)) {
    Future.microtask(cargar);
  }

  /// Lee qué día revisa la ocurrencia (una sola vez), las transferencias del
  /// día que se mira y todas las pendientes.
  Future<void> cargar() async {
    state = state.copyWith(cargando: true);
    try {
      final revisado =
          state.diaRevisado ??
          await _repo.diaRevisado(idBitTarRuti: idBitTarea);
      final dia = state.dia ?? revisado.fechaRevisada;
      final lecturas = await Future.wait([
        _repo.delDia(dia),
        _repo.pendientes(),
      ]);
      if (!mounted) return;
      state = state.copyWith(
        diaRevisado: revisado,
        dia: dia,
        delDia: lecturas[0],
        diaLeido: true,
        cargandoDia: false,
        pendientes: lecturas[1],
        cargando: false,
        cargado: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        cargando: false,
        error: 'No se pudo leer las transferencias. ${_texto(e)}',
      );
    }
  }

  /// Mira las transferencias de otro día. La ocurrencia sigue revisando el
  /// suyo: "Sin pendientes" no cambia con esto.
  Future<void> verDia(DateTime dia) async {
    final elegido = DateTime(dia.year, dia.month, dia.day);
    state = state.copyWith(
      dia: elegido,
      delDia: const [],
      diaLeido: false,
      cargandoDia: true,
    );
    try {
      final filas = await _repo.delDia(elegido);
      // Si mientras tanto se eligió otro día, esta respuesta ya no sirve.
      if (!mounted || state.dia != elegido) return;
      state = state.copyWith(delDia: filas, diaLeido: true, cargandoDia: false);
    } catch (e) {
      if (!mounted || state.dia != elegido) return;
      state = state.copyWith(
        cargandoDia: false,
        error: 'No se pudo leer las transferencias de ese día. ${_texto(e)}',
      );
    }
  }

  Future<bool> cerrar({required TraspasoEfectivoTesBaseEntity fila}) async {
    if (state.cerrando != null) return false;
    state = state.copyWith(cerrando: fila.codTes);
    try {
      await _repo.cerrar(codTes: fila.codTes, idBitTarRuti: idBitTarea);
      // Se recarga en vez de tocar la lista en memoria: otra persona pudo
      // cerrar o registrar otras mientras tanto.
      await cargar();
      if (!mounted) return true;
      state = state.copyWith(
        limpiarCerrando: true,
        aviso: 'Transferencia cerrada.',
      );
      return true;
    } catch (e) {
      // Incluye el caso de que otra persona la haya cerrado primero: recargar
      // deja la lista como está de verdad.
      await cargar();
      if (!mounted) return false;
      state = state.copyWith(limpiarCerrando: true, error: _texto(e));
      return false;
    }
  }

  Future<bool> sinPendientes() async {
    state = state.copyWith(cerrandoDia: true);
    try {
      await _repo.sinPendientes(idBitTarRuti: idBitTarea);
      if (!mounted) return true;
      state = state.copyWith(
        cerrandoDia: false,
        aviso: 'Día revisado: no quedaban transferencias pendientes.',
      );
      return true;
    } catch (e) {
      // El servidor rechaza si apareció una pendiente desde la última lectura.
      await cargar();
      if (!mounted) return false;
      state = state.copyWith(cerrandoDia: false, error: _texto(e));
      return false;
    }
  }

  static String _texto(Object e) =>
      e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
}

final _traspasoEfectivoTesBaseRepoProvider =
    Provider<TraspasoEfectivoTesBaseRepository>(
      (ref) => TraspasoEfectivoTesBaseImpl(),
    );

/// Uno por ocurrencia (`idBitTarea`): el día que se revisa sale de ella.
final traspasoEfectivoTesBaseProvider = StateNotifierProvider.autoDispose
    .family<TraspasoEfectivoTesBaseNotifier, TraspasoEfectivoTesBaseState, int>(
      (ref, idBitTarea) => TraspasoEfectivoTesBaseNotifier(
        ref.watch(_traspasoEfectivoTesBaseRepoProvider),
        idBitTarea,
      ),
    );
