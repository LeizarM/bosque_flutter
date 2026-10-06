import 'package:bosque_flutter/data/repositories/planilla_incapacidad_impl.dart';
import 'package:bosque_flutter/domain/entities/planilla_incapacidad_entity.dart';
import 'package:bosque_flutter/domain/repositories/planilla_incapacidad_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Público para que los tests lo reemplacen con `overrideWithValue`.
final planillaIncapacidadRepoProvider = Provider<PlanillaIncapacidadRepository>(
  (ref) => PlanillaIncapacidadImpl(),
);

final planillaIncapacidadProvider = StateNotifierProvider.autoDispose<
  PlanillaIncapacidadNotifier,
  PlanillaIncapacidadState
>((ref) => PlanillaIncapacidadNotifier(ref.watch(planillaIncapacidadRepoProvider)));

enum FiltroRevision { todas, pendientes, revisadas }

const _igual = Object();

DateTime _soloDia(DateTime f) => DateTime(f.year, f.month, f.day);

class PlanillaIncapacidadState {
  final DateTime desde;
  final DateTime hasta;

  /// Todo el rango. Filtro y búsqueda se aplican encima, sin volver a consultar.
  final List<PlanillaIncapacidadEntity> filas;
  final bool cargando;
  final bool cargado;
  final Object? error;
  final FiltroRevision filtro;
  final String busqueda;

  /// Bajas cuya revisión se está guardando.
  final Set<int> guardando;

  const PlanillaIncapacidadState({
    required this.desde,
    required this.hasta,
    this.filas = const [],
    this.cargando = false,
    this.cargado = false,
    this.error,
    this.filtro = FiltroRevision.todas,
    this.busqueda = '',
    this.guardando = const {},
  });

  /// El año en curso: las bajas aparecen recién con la planilla del mes
  /// ejecutada, así que el mes en curso casi siempre está vacío.
  factory PlanillaIncapacidadState.inicial(DateTime hoy) =>
      PlanillaIncapacidadState(desde: DateTime(hoy.year), hasta: _soloDia(hoy));

  int get total => filas.length;
  int get revisadas => filas.where((f) => f.fueRevisado).length;
  int get pendientes => total - revisadas;
  int get diasSeguro => filas.fold(0, (s, f) => s + f.diasAsumidosCordes);
  double get totalDescuento => filas.fold(0.0, (s, f) => s + f.totalDescuento);
  bool get hayFiltros => filtro != FiltroRevision.todas || busqueda.isNotEmpty;

  List<PlanillaIncapacidadEntity> get visibles {
    final q = busqueda.trim().toLowerCase();
    return filas.where((f) {
      final pasaFiltro = switch (filtro) {
        FiltroRevision.todas => true,
        FiltroRevision.pendientes => !f.fueRevisado,
        FiltroRevision.revisadas => f.fueRevisado,
      };
      if (!pasaFiltro) return false;
      if (q.isEmpty) return true;
      return f.datoEmpleado.toLowerCase().contains(q) ||
          f.motivo.toLowerCase().contains(q) ||
          f.numSeguro.toLowerCase().contains(q) ||
          f.seguro.toLowerCase().contains(q);
    }).toList();
  }

  PlanillaIncapacidadState copyWith({
    DateTime? desde,
    DateTime? hasta,
    List<PlanillaIncapacidadEntity>? filas,
    bool? cargando,
    bool? cargado,
    Object? error = _igual,
    FiltroRevision? filtro,
    String? busqueda,
    Set<int>? guardando,
  }) => PlanillaIncapacidadState(
    desde: desde ?? this.desde,
    hasta: hasta ?? this.hasta,
    filas: filas ?? this.filas,
    cargando: cargando ?? this.cargando,
    cargado: cargado ?? this.cargado,
    error: identical(error, _igual) ? this.error : error,
    filtro: filtro ?? this.filtro,
    busqueda: busqueda ?? this.busqueda,
    guardando: guardando ?? this.guardando,
  );
}

class PlanillaIncapacidadNotifier
    extends StateNotifier<PlanillaIncapacidadState> {
  final PlanillaIncapacidadRepository _repo;

  PlanillaIncapacidadNotifier(this._repo, {DateTime? hoy})
    : super(PlanillaIncapacidadState.inicial(hoy ?? DateTime.now())) {
    Future.microtask(cargar);
  }

  Future<void> cargar() async {
    final desde = state.desde;
    final hasta = state.hasta;
    state = state.copyWith(cargando: true, error: null);
    try {
      final filas = await _repo.listar(desde: desde, hasta: hasta);
      if (!mounted) return;
      // Otro rango elegido mientras tanto: esta respuesta ya no se está mirando.
      if (state.desde != desde || state.hasta != hasta) return;
      filas.sort(_porInicio);
      state = state.copyWith(filas: filas, cargando: false, cargado: true);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(cargando: false, error: e);
    }
  }

  /// Null si se aplicó; si no, el motivo para avisar.
  Future<String?> cambiarRango(DateTime desde, DateTime hasta) async {
    final d = _soloDia(desde);
    final h = _soloDia(hasta);
    if (h.isBefore(d)) return 'La fecha inicial no puede ser posterior a la final.';
    if (d == state.desde && h == state.hasta) return null;
    state = state.copyWith(desde: d, hasta: h, filas: const [], cargado: false);
    await cargar();
    return null;
  }

  void filtrar(FiltroRevision f) => state = state.copyWith(filtro: f);
  void buscar(String texto) => state = state.copyWith(busqueda: texto);
  void limpiarFiltros() =>
      state = state.copyWith(filtro: FiltroRevision.todas, busqueda: '');

  /// Marca al instante y guarda; si el servidor rechaza, vuelve atrás.
  /// Devuelve el error, o null si se guardó.
  Future<Object?> marcar(int idPIT, bool revisado) async {
    if (state.guardando.contains(idPIT)) return null;
    final i = state.filas.indexWhere((f) => f.idPIT == idPIT);
    if (i < 0) return null;
    final antes = state.filas[i];

    _reemplazar(antes.conRevision(revisado));
    state = state.copyWith(guardando: {...state.guardando, idPIT});
    try {
      await _repo.marcarRevisado(idPIT: idPIT, revisado: revisado);
      if (mounted) _soltar(idPIT);
      return null;
    } catch (e) {
      if (!mounted) return e;
      _reemplazar(antes);
      _soltar(idPIT);
      return e;
    }
  }

  void _reemplazar(PlanillaIncapacidadEntity fila) => state = state.copyWith(
    filas: [for (final f in state.filas) f.idPIT == fila.idPIT ? fila : f],
  );

  void _soltar(int idPIT) => state = state.copyWith(
    guardando: {...state.guardando}..remove(idPIT),
  );

  static int _porInicio(PlanillaIncapacidadEntity a, PlanillaIncapacidadEntity b) {
    final porFecha = (a.desde ?? DateTime(0)).compareTo(b.desde ?? DateTime(0));
    return porFecha != 0 ? porFecha : a.datoEmpleado.compareTo(b.datoEmpleado);
  }
}
