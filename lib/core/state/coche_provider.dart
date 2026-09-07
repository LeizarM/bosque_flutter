// Destino final: lib/core/state/coche_provider.dart
import 'package:bosque_flutter/data/repositories/coche_impl.dart';
import 'package:bosque_flutter/domain/entities/coche_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CocheState {
  final List<CocheEntity> items;
  final bool cargando;
  final String? mensajeError;
  final String? mensajeExito;

  const CocheState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  CocheState copyWith({
    List<CocheEntity>? items,
    bool? cargando,
    String? mensajeError,
    String? mensajeExito,
  }) => CocheState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class CocheNotifier extends StateNotifier<CocheState> {
  final CocheImpl _repo;

  CocheNotifier(this._repo) : super(const CocheState()) {
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

  Future<bool> guardar(CocheEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      state = state.copyWith(
        cargando: false,
        mensajeExito: item.idCoche == 0
            ? 'Coche agregado.'
            : 'Coche actualizado.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<bool> eliminar(int idCoche, int audUsuario) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.eliminar(idCoche, audUsuario);
      state = state.copyWith(cargando: false, mensajeExito: 'Coche eliminado.');
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _cocheRepoProvider = Provider((ref) => CocheImpl());

final cocheProvider =
    StateNotifierProvider.autoDispose<CocheNotifier, CocheState>(
  (ref) => CocheNotifier(ref.read(_cocheRepoProvider)),
);
