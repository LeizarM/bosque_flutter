import 'dart:async';
import 'package:bosque_flutter/data/repositories/indemnizacion_impl.dart';
import 'package:bosque_flutter/domain/entities/indemnizacion_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Filtros persistentes: sobreviven al cambio de empresa ──────────────────
class _FiltrosPersistidos {
  final int? codArea;
  final String fechaActual; // yyyy-MM-dd
  final int tamanoPagina;

  const _FiltrosPersistidos({
    this.codArea,
    required this.fechaActual,
    this.tamanoPagina = 15,
  });

  _FiltrosPersistidos copyWith({
    int? codArea,
    bool clearArea = false,
    String? fechaActual,
    int? tamanoPagina,
  }) => _FiltrosPersistidos(
    codArea: clearArea ? null : (codArea ?? this.codArea),
    fechaActual: fechaActual ?? this.fechaActual,
    tamanoPagina: tamanoPagina ?? this.tamanoPagina,
  );
}

final _filtrosPersistidosProvider = StateProvider<_FiltrosPersistidos>(
  (ref) => _FiltrosPersistidos(
    fechaActual: DateTime.now().toIso8601String().split('T')[0],
  ),
);

// ─────────────────────────────────────────────
class IndemnizacionState {
  final List<IndemnizacionEntity> items;
  final bool cargando;
  final String search;
  final String? mensajeError;
  final String? mensajeExito;

  final int pagina;
  final int totalPaginas;
  final int tamanoPagina;
  final int totalRegistros;
  final String fechaActual;
  final int? codArea;
  final int? codEmpleado;

  const IndemnizacionState({
    this.items = const [],
    this.cargando = false,
    this.search = '',
    this.mensajeError,
    this.mensajeExito,
    this.pagina = 1,
    this.totalPaginas = 1,
    this.tamanoPagina = 15,
    this.totalRegistros = 0,
    this.fechaActual = '',
    this.codArea,
    this.codEmpleado,
  });

  IndemnizacionState copyWith({
    List<IndemnizacionEntity>? items,
    bool? cargando,
    String? search,
    String? mensajeError,
    String? mensajeExito,
    int? pagina,
    int? totalPaginas,
    int? tamanoPagina,
    int? totalRegistros,
    String? fechaActual,
    int? codArea,
    bool clearArea = false,
    int? codEmpleado,
    bool clearCodEmpleado = false,
  }) => IndemnizacionState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    search: search ?? this.search,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
    pagina: pagina ?? this.pagina,
    totalPaginas: totalPaginas ?? this.totalPaginas,
    tamanoPagina: tamanoPagina ?? this.tamanoPagina,
    totalRegistros: totalRegistros ?? this.totalRegistros,
    fechaActual: fechaActual ?? this.fechaActual,
    codArea: clearArea ? null : (codArea ?? this.codArea),
    codEmpleado: clearCodEmpleado ? null : (codEmpleado ?? this.codEmpleado),
  );
}

class IndemnizacionNotifier extends StateNotifier<IndemnizacionState> {
  final IndemnizacionImpl _repo;
  final int codEmpresa;
  final Ref _ref;

  IndemnizacionNotifier(this._repo, this.codEmpresa, this._ref)
    : super(const IndemnizacionState()) {
    final f = _ref.read(_filtrosPersistidosProvider);
    state = state.copyWith(
      fechaActual: f.fechaActual,
      codArea: f.codArea,
      tamanoPagina: f.tamanoPagina,
    );
    Future.microtask(() => cargar());
  }

  void _persistir() {
    _ref.read(_filtrosPersistidosProvider.notifier).state = _FiltrosPersistidos(
      codArea: state.codArea,
      fechaActual: state.fechaActual,
      tamanoPagina: state.tamanoPagina,
    );
  }

  Future<void> cargar({
    String? search,
    int? codEmpleado,
    bool clearCodEmpleado = false,
    int? pagina,
  }) async {
    state = state.copyWith(
      cargando: true,
      mensajeError: null,
      mensajeExito: null,
      search: search,
      codEmpleado: codEmpleado,
      clearCodEmpleado: clearCodEmpleado,
      pagina: pagina,
    );
    try {
      final empFiltro = codEmpresa == 0 ? null : codEmpresa;
      final data = await _repo.listarIndemnizaciones(
        buscar: state.search.isEmpty ? null : state.search,
        codEmpleado: state.codEmpleado,
        fechaActual: state.fechaActual,
        codEmpresa: empFiltro,
        codArea: state.codArea,
        pagina: state.pagina,
        tamanoPagina: state.tamanoPagina,
      );
      if (!mounted) return;
      state = state.copyWith(
        items: data,
        cargando: false,
        totalPaginas: data.isNotEmpty ? (data.first.totalPaginas ?? 1) : 1,
        totalRegistros: data.isNotEmpty ? (data.first.totalRegistros ?? 0) : 0,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(cargando: false, mensajeError: e.toString());
    }
  }

  void cambiarPagina(int p) {
    state = state.copyWith(pagina: p);
    cargar();
  }

  void cambiarTamano(int t) {
    state = state.copyWith(tamanoPagina: t, pagina: 1);
    _persistir();
    cargar();
  }

  void setFecha(String fecha) {
    state = state.copyWith(fechaActual: fecha, pagina: 1);
    _persistir();
    cargar();
  }

  void setArea(int? area) {
    state = state.copyWith(codArea: area, clearArea: area == null, pagina: 1);
    _persistir();
    cargar();
  }

  Timer? _searchDebounce;

  void buscar(String q) {
    if (state.search == q) return;
    state = state.copyWith(search: q, pagina: 1);

    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      cargar();
    });
  }

  Future<void> guardar(
    IndemnizacionEntity indemnizacion,
    int audUsuarioI,
  ) async {
    state = state.copyWith(
      cargando: true,
      mensajeError: null,
      mensajeExito: null,
    );
    try {
      final response = await _repo.abmIndemnizacion(
        indemnizacion: indemnizacion,
        audUsuarioI: audUsuarioI,
      );
      if (!mounted) return;
      state = state.copyWith(
        cargando: false,
        mensajeExito: response['message'] ?? 'Guardado correctamente',
      );
      cargar();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(cargando: false, mensajeError: e.toString());
    }
  }

  Future<void> eliminar(
    IndemnizacionEntity indemnizacion,
    int audUsuarioI,
  ) async {
    final deletedEntity = indemnizacion.copyWith(estado: 0);
    await guardar(deletedEntity, audUsuarioI);
  }
}

final _indemnizacionRepoProvider = Provider((ref) => IndemnizacionImpl());

final codEmpresaIndemnizacionProvider = StateProvider<int>((ref) => 0);

final indemnizacionProvider = StateNotifierProvider.family
    .autoDispose<IndemnizacionNotifier, IndemnizacionState, int>((
      ref,
      codEmpresa,
    ) {
      return IndemnizacionNotifier(
        ref.read(_indemnizacionRepoProvider),
        codEmpresa,
        ref,
      );
    });

class HistorialIndemnizacionNotifier extends StateNotifier<IndemnizacionState> {
  final IndemnizacionImpl _repo;
  final int codEmpresa;

  HistorialIndemnizacionNotifier(this._repo, this.codEmpresa)
    : super(const IndemnizacionState()) {
    Future.microtask(() => cargar());
  }

  Future<void> cargar({
    String? search,
    int? codEmpleado,
    bool clearCodEmpleado = false,
    int? pagina,
  }) async {
    state = state.copyWith(
      cargando: true,
      mensajeError: null,
      mensajeExito: null,
      search: search,
      codEmpleado: codEmpleado,
      clearCodEmpleado: clearCodEmpleado,
      pagina: pagina,
    );
    try {
      final empFiltro = codEmpresa == 0 ? null : codEmpresa;
      final data = await _repo.listarHistorialIndemnizaciones(
        buscar: state.search.isEmpty ? null : state.search,
        codEmpleado: state.codEmpleado,
        fechaActual: state.fechaActual.isEmpty ? null : state.fechaActual,
        codEmpresa: empFiltro,
        codArea: state.codArea,
        pagina: state.pagina,
        tamanoPagina: state.tamanoPagina,
      );
      if (!mounted) return;
      state = state.copyWith(
        items: data,
        cargando: false,
        totalPaginas: data.isNotEmpty ? (data.first.totalPaginas ?? 1) : 1,
        totalRegistros: data.isNotEmpty ? (data.first.totalRegistros ?? 0) : 0,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(cargando: false, mensajeError: e.toString());
    }
  }

  void setFecha(String fecha) {
    state = state.copyWith(fechaActual: fecha, pagina: 1);
    cargar();
  }

  void setArea(int? area) {
    state = state.copyWith(codArea: area, clearArea: area == null, pagina: 1);
    cargar();
  }

  void cambiarPagina(int p) {
    state = state.copyWith(pagina: p);
    cargar();
  }

  void cambiarTamano(int t) {
    state = state.copyWith(tamanoPagina: t, pagina: 1);
    cargar();
  }

  Timer? _searchDebounce;

  void buscar(String q) {
    if (state.search == q) return;
    state = state.copyWith(search: q, pagina: 1);

    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      cargar();
    });
  }

  Future<void> guardar(
    IndemnizacionEntity indemnizacion,
    int audUsuarioI,
  ) async {
    state = state.copyWith(
      cargando: true,
      mensajeError: null,
      mensajeExito: null,
    );
    try {
      final response = await _repo.abmIndemnizacion(
        indemnizacion: indemnizacion,
        audUsuarioI: audUsuarioI,
      );
      if (!mounted) return;
      state = state.copyWith(
        cargando: false,
        mensajeExito: response['message'] ?? 'Guardado correctamente',
      );
      cargar();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(cargando: false, mensajeError: e.toString());
    }
  }

  Future<void> eliminar(
    IndemnizacionEntity indemnizacion,
    int audUsuarioI,
  ) async {
    final deletedEntity = indemnizacion.copyWith(estado: 0);
    await guardar(deletedEntity, audUsuarioI);
  }
}

final historialIndemnizacionProvider = StateNotifierProvider.family
    .autoDispose<HistorialIndemnizacionNotifier, IndemnizacionState, int>((
      ref,
      codEmpresa,
    ) {
      return HistorialIndemnizacionNotifier(
        ref.read(_indemnizacionRepoProvider),
        codEmpresa,
      );
    });
