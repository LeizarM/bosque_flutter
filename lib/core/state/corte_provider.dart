// Destino final: lib/core/state/corte_provider.dart
import 'package:bosque_flutter/data/repositories/corte_impl.dart';
import 'package:bosque_flutter/domain/entities/corte_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CorteState {
  final List<CorteEntity> items;
  final bool cargando;
  final String? mensajeError;
  final String? mensajeExito;

  const CorteState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  CorteState copyWith({
    List<CorteEntity>? items,
    bool? cargando,
    String? mensajeError,
    String? mensajeExito,
  }) => CorteState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class CorteNotifier extends StateNotifier<CorteState> {
  final CorteImpl _repo;

  CorteNotifier(this._repo) : super(const CorteState()) {
    Future.microtask(() => cargar());
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true);
    try {
      final data = await _repo.obtener();
      state = state.copyWith(items: data, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
    }
  }

  Future<bool> guardar(CorteEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      state = state.copyWith(
        cargando: false,
        mensajeExito: item.idCorte == 0
            ? 'Corte agregado.'
            : 'Corte actualizado.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<bool> eliminar(int idCorte, int audUsuario) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.eliminar(idCorte, audUsuario);
      state = state.copyWith(cargando: false, mensajeExito: 'Corte eliminado.');
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _corteRepoProvider = Provider((ref) => CorteImpl());

final corteProvider =
    StateNotifierProvider.autoDispose<CorteNotifier, CorteState>(
  (ref) => CorteNotifier(ref.read(_corteRepoProvider)),
);
