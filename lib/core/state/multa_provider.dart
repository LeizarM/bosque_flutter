import 'dart:math' show max;
import 'package:bosque_flutter/data/repositories/multa_impl.dart';
import 'package:bosque_flutter/domain/entities/multa_entity.dart';
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
  _FiltrosPersistidos copyWith({
    String? mes,
    String? anio,
    int? tamanoPagina,
  }) => _FiltrosPersistidos(
    mes: mes ?? this.mes,
    anio: anio ?? this.anio,
    tamanoPagina: tamanoPagina ?? this.tamanoPagina,
  );
}

final _filtrosPersistidosProvider = StateProvider<_FiltrosPersistidos>(
  (ref) => _FiltrosPersistidos(
    mes: DateTime.now().month.toString(),
    anio: DateTime.now().year.toString(),
  ),
);

class MultaState {
  final List<MultaEntity> items;
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
  final bool soloConMulta;
  const MultaState({
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
    this.soloConMulta = false,
  });
  MultaState copyWith({
    List<MultaEntity>? items,
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
    bool? soloConMulta,
  }) => MultaState(
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
    soloConMulta: soloConMulta ?? this.soloConMulta,
  );
}

class MultaNotifier extends StateNotifier<MultaState> {
  final MultaImpl _repo;
  final int codEmpresa;
  final Ref _ref;
  MultaNotifier(this._repo, this.codEmpresa, this._ref)
    : super(const MultaState()) {
    final f = _ref.read(_filtrosPersistidosProvider);
    state = MultaState(mes: f.mes, anio: f.anio, tamanoPagina: f.tamanoPagina);
    Future.microtask(() => cargar());
  }

  void _persistir() {
    _ref.read(_filtrosPersistidosProvider.notifier).state = _FiltrosPersistidos(
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

  void toggleSoloConMulta() {
    state = state.copyWith(soloConMulta: !state.soloConMulta, pagina: 1);
    cargar();
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true);
    try {
      final empFiltro = codEmpresa == 0 ? null : codEmpresa;
      final data = await _repo.getMultas(
        state.pagina,
        state.tamanoPagina,
        empFiltro,
        state.search.isEmpty ? null : state.search,
        int.tryParse(state.mes),
        int.tryParse(state.anio),
        state.soloConMulta,
      );
      state = state.copyWith(
        items: data,
        cargando: false,
        totalPaginas: data.isNotEmpty ? (data.first.totalPaginas ?? 1) : 1,
        totalRegistros: data.isNotEmpty ? (data.first.totalRegistros ?? 0) : 0,
      );
    } catch (e) {
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

  void cambiarTamano(int t) {
    state = state.copyWith(tamanoPagina: t, pagina: 1);
    _persistir();
    cargar();
  }

  Future<void> generarMultas(int audUsuarioI) async {
    state = state.copyWith(generando: true);
    try {
      final response = await _repo.generarMultas(
        mes: int.parse(state.mes),
        anio: int.parse(state.anio),
        audUsuarioI: audUsuarioI,
      );
      state = state.copyWith(mensajeExito: response.message, generando: false);
      cargar();
    } catch (e) {
      state = state.copyWith(generando: false, mensajeError: e.toString());
    }
  }

  // AGREGAR en MultaNotifier, antes de editarTodasMultas:
  Future<void> editarMulta(MultaEntity multa) async {
    await editarTodasMultas([multa]);
  }

  // NUEVO: guarda múltiples registros y recarga una sola vez al final
  // NUEVO: Guarda múltiples registros construyendo un XML y haciendo 1 sola petición
  Future<void> editarTodasMultas(List<MultaEntity> multas) async {
    if (multas.isEmpty) return;
    state = state.copyWith(cargando: true);

    try {
      // 1. Construir el XML nativo para SQL Server
      final buffer = StringBuffer('<r>');
      for (final m in multas) {
        buffer.write(
          '<i codMulta="${m.codMulta}" diasMulta="${m.diasMulta}" />',
        );
      }
      buffer.write('</r>');

      // 2. Extraemos el usuario auditor del primer registro (todos tienen el mismo)
      final audUsuario = multas.first.audUsuarioI;

      // 3. Ejecutamos la petición atómica masiva
      final response = await _repo.editarTodasMultasMasivo(
        buffer.toString(),
        audUsuario,
        int.parse(state.mes),
        int.parse(state.anio),
      );

      state = state.copyWith(cargando: false, mensajeExito: response.message);
      cargar(); // Refresca la grilla tras guardar
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
    }
  }
}

final _repoProvider = Provider((ref) => MultaImpl());
final multaProvider = StateNotifierProvider.family.autoDispose<
  MultaNotifier,
  MultaState,
  int
>((ref, codEmpresa) => MultaNotifier(ref.read(_repoProvider), codEmpresa, ref));
