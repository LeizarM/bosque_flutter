// Destino final: lib/core/state/frecuencia_provider.dart
import 'package:bosque_flutter/data/repositories/frecuencia_impl.dart';
import 'package:bosque_flutter/domain/entities/frecuencia_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FrecuenciaState {
  final List<FrecuenciaEntity> items;
  final bool cargando;
  final String? mensajeError;
  final String? mensajeExito;

  const FrecuenciaState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  FrecuenciaState copyWith({
    List<FrecuenciaEntity>? items,
    bool? cargando,
    String? mensajeError,
    String? mensajeExito,
  }) => FrecuenciaState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class FrecuenciaNotifier extends StateNotifier<FrecuenciaState> {
  final FrecuenciaImpl _repo;

  FrecuenciaNotifier(this._repo) : super(const FrecuenciaState()) {
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

  Future<bool> guardar(FrecuenciaEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      state = state.copyWith(
        cargando: false,
        mensajeExito: item.idFrec == 0
            ? 'Frecuencia agregada.'
            : 'Frecuencia actualizada.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<bool> eliminar(int idFrec, int audUsuario) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.eliminar(idFrec, audUsuario);
      state = state.copyWith(cargando: false, mensajeExito: 'Frecuencia eliminada.');
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _frecuenciaRepoProvider = Provider((ref) => FrecuenciaImpl());

final frecuenciaProvider =
    StateNotifierProvider.autoDispose<FrecuenciaNotifier, FrecuenciaState>(
  (ref) => FrecuenciaNotifier(ref.read(_frecuenciaRepoProvider)),
);
