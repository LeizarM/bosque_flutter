import 'dart:async';
import 'package:bosque_flutter/data/repositories/bono_impl.dart';
import 'package:bosque_flutter/domain/entities/bono_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/bono_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final _filtrosPersistidosBonoProvider = StateProvider<_FiltrosPersistidos>(
  (ref) => _FiltrosPersistidos(
    mes: DateTime.now().month.toString(),
    anio: DateTime.now().year.toString(),
  ),
);

class BonoState {
  final List<BonoEntity> items;
  final bool cargando;
  final bool generando;
  final int pagina;
  final int totalPaginas;
  final int tamanoPagina;
  final String search;
  final int totalRegistros;
  final String? mensajeError;
  final String? mensajeExito;
  final String mes;
  final String anio;

  const BonoState({
    this.items = const [],
    this.cargando = false,
    this.generando = false,
    this.pagina = 1,
    this.totalPaginas = 1,
    this.tamanoPagina = 15,
    this.search = '',
    this.totalRegistros = 0,
    this.mensajeError,
    this.mensajeExito,
    this.mes = '',
    this.anio = '',
  });

  BonoState copyWith({
    List<BonoEntity>? items,
    bool? cargando,
    bool? generando,
    int? pagina,
    int? totalPaginas,
    int? tamanoPagina,
    String? search,
    int? totalRegistros,
    String? mensajeError,
    String? mensajeExito,
    String? mes,
    String? anio,
  }) => BonoState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    generando: generando ?? this.generando,
    pagina: pagina ?? this.pagina,
    totalPaginas: totalPaginas ?? this.totalPaginas,
    tamanoPagina: tamanoPagina ?? this.tamanoPagina,
    search: search ?? this.search,
    totalRegistros: totalRegistros ?? this.totalRegistros,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
    mes: mes ?? this.mes,
    anio: anio ?? this.anio,
  );
}

class BonoNotifier extends StateNotifier<BonoState> {
  final BonoImpl _repo;
  final Ref _ref;

  BonoNotifier(this._repo, this._ref) : super(const BonoState()) {
    final f = _ref.read(_filtrosPersistidosBonoProvider);
    state = BonoState(mes: f.mes, anio: f.anio, tamanoPagina: f.tamanoPagina);
    Future.microtask(() => cargar());
  }

  void _persistir() {
    _ref
        .read(_filtrosPersistidosBonoProvider.notifier)
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

  Future<void> cargar() async {
    state = state.copyWith(
      cargando: true,
      mensajeError: null,
      mensajeExito: null,
    );
    try {
      final data = await _repo.listarBono(
        pagina: state.pagina,
        tamanoPagina: state.tamanoPagina,
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

  Future<void> generarBono(int audUsuarioI) async {
    state = state.copyWith(
      generando: true,
      mensajeError: null,
      mensajeExito: null,
    );
    try {
      final response = await _repo.abmBono(audUsuarioI: audUsuarioI);
      if (!mounted) return;
      state = state.copyWith(mensajeExito: response.errormsg, generando: false);
      cargar();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(generando: false, mensajeError: e.toString());
    }
  }
}

final _bonoRepoProvider = Provider((ref) => BonoImpl());

final bonoProvider = StateNotifierProvider.autoDispose<BonoNotifier, BonoState>(
  (ref) {
    return BonoNotifier(ref.read(_bonoRepoProvider), ref);
  },
);

class BonoEmpleadoState {
  final List<BonoEmpleadoEntity> items;
  final bool cargando;
  final String? mensajeError;
  final int pagina;
  final int totalPaginas;
  final int totalRegistros;
  final int tamanoPagina;
  final String search;
  final int soloBono;

  const BonoEmpleadoState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.pagina = 1,
    this.totalPaginas = 1,
    this.totalRegistros = 0,
    this.tamanoPagina = 15,
    this.search = '',
    this.soloBono = 0,
  });

  BonoEmpleadoState copyWith({
    List<BonoEmpleadoEntity>? items,
    bool? cargando,
    String? mensajeError,
    int? pagina,
    int? totalPaginas,
    int? totalRegistros,
    int? tamanoPagina,
    String? search,
    int? soloBono,
  }) => BonoEmpleadoState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    pagina: pagina ?? this.pagina,
    totalPaginas: totalPaginas ?? this.totalPaginas,
    totalRegistros: totalRegistros ?? this.totalRegistros,
    tamanoPagina: tamanoPagina ?? this.tamanoPagina,
    search: search ?? this.search,
    soloBono: soloBono ?? this.soloBono,
  );
}

class BonoEmpleadoNotifier extends StateNotifier<BonoEmpleadoState> {
  final BonoImpl _repo;
  final int codBono;

  BonoEmpleadoNotifier(this._repo, this.codBono)
    : super(const BonoEmpleadoState()) {
    Future.microtask(() => cargar());
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, mensajeError: null);
    try {
      final data = await _repo.listarBonoEmpleado(
        pagina: state.pagina,
        tamanoPagina: state.tamanoPagina,
        codBono: codBono,
        search: state.search.isEmpty ? null : state.search,
        soloBono: state.soloBono,
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

  void buscar(String q) {
    state = state.copyWith(search: q, pagina: 1);
    cargar();
  }

  void toggleSoloBono() {
    state = state.copyWith(soloBono: state.soloBono == 1 ? 0 : 1, pagina: 1);
    cargar();
  }
}

final bonoEmpleadoProvider = StateNotifierProvider.family
    .autoDispose<BonoEmpleadoNotifier, BonoEmpleadoState, int>((ref, codBono) {
      return BonoEmpleadoNotifier(ref.read(_bonoRepoProvider), codBono);
    });
