import 'dart:async';
import 'dart:typed_data';
import 'package:bosque_flutter/data/repositories/planilla_impl.dart';
import 'package:bosque_flutter/domain/entities/planilla_entity.dart';
import 'package:bosque_flutter/domain/entities/planilla_detalle_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// FILTROS PERSISTIDOS (se mantienen al cambiar de pantalla)
// ═══════════════════════════════════════════════════════════════════════════════

class _FiltrosPersistidos {
  final String mes;
  final String anio;
  final int tamanoPagina;
  const _FiltrosPersistidos({
    required this.mes,
    required this.anio,
    this.tamanoPagina = 15,
  });
}

final _filtrosPersistidosPlanillaProvider = StateProvider<_FiltrosPersistidos>(
  (ref) => _FiltrosPersistidos(
    mes: DateTime.now().month.toString(),
    anio: DateTime.now().year.toString(),
  ),
);

// ═══════════════════════════════════════════════════════════════════════════════
// STATE + NOTIFIER: Cabeceras de Planilla
// ═══════════════════════════════════════════════════════════════════════════════

class PlanillaState {
  final List<PlanillaEntity> items;
  final bool cargando;
  final bool generando;
  final int pagina;
  final int totalPaginas;
  final int tamanoPagina;
  final int totalRegistros;
  final String? mensajeError;
  final String? mensajeExito;
  final String mes;
  final String anio;
  final int? codEmpresa;
  final String? estado;

  const PlanillaState({
    this.items = const [],
    this.cargando = false,
    this.generando = false,
    this.pagina = 1,
    this.totalPaginas = 1,
    this.tamanoPagina = 15,
    this.totalRegistros = 0,
    this.mensajeError,
    this.mensajeExito,
    this.mes = '',
    this.anio = '',
    this.codEmpresa,
    this.estado,
  });

  PlanillaState copyWith({
    List<PlanillaEntity>? items,
    bool? cargando,
    bool? generando,
    int? pagina,
    int? totalPaginas,
    int? tamanoPagina,
    int? totalRegistros,
    String? mensajeError,
    String? mensajeExito,
    String? mes,
    String? anio,
    int? codEmpresa,
    String? estado,
  }) => PlanillaState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    generando: generando ?? this.generando,
    pagina: pagina ?? this.pagina,
    totalPaginas: totalPaginas ?? this.totalPaginas,
    tamanoPagina: tamanoPagina ?? this.tamanoPagina,
    totalRegistros: totalRegistros ?? this.totalRegistros,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
    mes: mes ?? this.mes,
    anio: anio ?? this.anio,
    codEmpresa: codEmpresa ?? this.codEmpresa,
    estado: estado ?? this.estado,
  );
}

class PlanillaNotifier extends StateNotifier<PlanillaState> {
  final PlanillaImpl _repo;
  final Ref _ref;

  PlanillaNotifier(this._repo, this._ref) : super(const PlanillaState()) {
    final f = _ref.read(_filtrosPersistidosPlanillaProvider);
    state = PlanillaState(mes: f.mes, anio: f.anio, tamanoPagina: f.tamanoPagina);
    Future.microtask(() => cargar());
  }

  void _persistir() {
    _ref
        .read(_filtrosPersistidosPlanillaProvider.notifier)
        .state = _FiltrosPersistidos(
      mes: state.mes,
      anio: state.anio,
      tamanoPagina: state.tamanoPagina,
    );
  }

  void setFechaFiltro({String? mes, String? anio}) {
    state = state.copyWith(mes: mes, anio: anio, pagina: 1);
    _persistir();
    cargar();
  }

  void setEmpresaFiltro(int? codEmpresa) {
    state = state.copyWith(codEmpresa: codEmpresa, pagina: 1);
    cargar();
  }

  void setEstadoFiltro(String? estado) {
    state = state.copyWith(estado: estado, pagina: 1);
    cargar();
  }

  Future<void> cargar() async {
    state = state.copyWith(
      cargando: true,
      mensajeError: null,
      mensajeExito: null,
    );
    try {
      final data = await _repo.listarPlanilla(
        pagina: state.pagina,
        tamanoPagina: state.tamanoPagina,
        codEmpresa: state.codEmpresa,
        estado: state.estado,
        filtroMes: int.tryParse(state.mes),
        filtroAnio: int.tryParse(state.anio),
      );
      if (!mounted) return;
      state = state.copyWith(
        items: data,
        cargando: false,
        totalPaginas: data.isNotEmpty ? (data.first.totalPaginas) : 1,
        totalRegistros: data.isNotEmpty ? (data.first.totalRegistros) : 0,
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

  Future<void> generarPlanilla(int audUsuarioI) async {
    state = state.copyWith(
      generando: true,
      mensajeError: null,
      mensajeExito: null,
    );
    try {
      final response = await _repo.generarPlanilla(audUsuarioI: audUsuarioI);
      if (!mounted) return;
      state = state.copyWith(mensajeExito: response.errormsg, generando: false);
      cargar();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(generando: false, mensajeError: e.toString());
    }
  }

  Future<void> ejecutarPlanilla() async {
    state = state.copyWith(
      generando: true,
      mensajeError: null,
      mensajeExito: null,
    );
    try {
      final response = await _repo.ejecutarPlanilla();
      if (!mounted) return;
      state = state.copyWith(mensajeExito: response.errormsg, generando: false);
      cargar();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(generando: false, mensajeError: e.toString());
    }
  }
}

final _planillaRepoProvider = Provider((ref) => PlanillaImpl());

final planillaProvider = StateNotifierProvider.autoDispose<PlanillaNotifier, PlanillaState>(
  (ref) {
    return PlanillaNotifier(ref.read(_planillaRepoProvider), ref);
  },
);

// ═══════════════════════════════════════════════════════════════════════════════
// STATE + NOTIFIER: Detalle de Planilla (empleados de una planilla)
// ═══════════════════════════════════════════════════════════════════════════════

class PlanillaDetalleState {
  final List<PlanillaDetalleEntity> items;
  final bool cargando;
  final String? mensajeError;
  final int pagina;
  final int totalPaginas;
  final int totalRegistros;
  final int tamanoPagina;
  final String search;

  const PlanillaDetalleState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.pagina = 1,
    this.totalPaginas = 1,
    this.totalRegistros = 0,
    this.tamanoPagina = 15,
    this.search = '',
  });

  PlanillaDetalleState copyWith({
    List<PlanillaDetalleEntity>? items,
    bool? cargando,
    String? mensajeError,
    int? pagina,
    int? totalPaginas,
    int? totalRegistros,
    int? tamanoPagina,
    String? search,
  }) => PlanillaDetalleState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    pagina: pagina ?? this.pagina,
    totalPaginas: totalPaginas ?? this.totalPaginas,
    totalRegistros: totalRegistros ?? this.totalRegistros,
    tamanoPagina: tamanoPagina ?? this.tamanoPagina,
    search: search ?? this.search,
  );
}

class PlanillaDetalleNotifier extends StateNotifier<PlanillaDetalleState> {
  final PlanillaImpl _repo;
  final int codPlanilla;

  PlanillaDetalleNotifier(this._repo, this.codPlanilla)
    : super(const PlanillaDetalleState()) {
    Future.microtask(() => cargar());
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, mensajeError: null);
    try {
      final data = await _repo.listarPlanillaDetalle(
        pagina: state.pagina,
        tamanoPagina: state.tamanoPagina,
        codPlanilla: codPlanilla,
        search: state.search.isEmpty ? null : state.search,
      );
      if (!mounted) return;
      state = state.copyWith(
        items: data,
        cargando: false,
        totalPaginas: data.isNotEmpty ? (data.first.totalPaginas) : 1,
        totalRegistros: data.isNotEmpty ? (data.first.totalRegistros) : 0,
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

  void cambiarTamanoPagina(int t) {
    state = state.copyWith(tamanoPagina: t, pagina: 1);
    cargar();
  }

  void buscar(String q) {
    state = state.copyWith(search: q, pagina: 1);
    cargar();
  }
}

final planillaDetalleProvider = StateNotifierProvider.family
    .autoDispose<PlanillaDetalleNotifier, PlanillaDetalleState, int>((ref, codPlanilla) {
      return PlanillaDetalleNotifier(ref.read(_planillaRepoProvider), codPlanilla);
    });

// ═══════════════════════════════════════════════════════════════════════════════
// PDF PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

final pdfEstimadoPagoBancoProvider = FutureProvider<Uint8List>((ref) async {
  final repo = PlanillaImpl();
  return await repo.descargarEstimadoPagoBanco();
});

final pdfPlanillaCompactaProvider = FutureProvider.family<Uint8List, int>((ref, codPlanilla) async {
  final repo = PlanillaImpl();
  return await repo.descargarPlanillaCompacta(codPlanilla);
});

final pdfPlanillaExtendidaProvider = FutureProvider.family<Uint8List, int>((ref, codPlanilla) async {
  final repo = PlanillaImpl();
  return await repo.descargarPlanillaExtendida(codPlanilla);
});
