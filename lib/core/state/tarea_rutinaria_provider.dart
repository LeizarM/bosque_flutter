// Destino final: lib/core/state/tarea_rutinaria_provider.dart
import 'package:bosque_flutter/data/repositories/tarea_rutinaria_impl.dart';
import 'package:bosque_flutter/domain/entities/tarea_rutinaria_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TareaRutinariaState {
  final List<TareaRutinariaEntity> items;
  final bool cargando;
  final String? mensajeError;
  final String? mensajeExito;

  const TareaRutinariaState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  TareaRutinariaState copyWith({
    List<TareaRutinariaEntity>? items,
    bool? cargando,
    String? mensajeError,
    String? mensajeExito,
  }) => TareaRutinariaState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class TareaRutinariaNotifier extends StateNotifier<TareaRutinariaState> {
  final TareaRutinariaImpl _repo;

  TareaRutinariaNotifier(this._repo) : super(const TareaRutinariaState()) {
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

  Future<bool> guardar(TareaRutinariaEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      state = state.copyWith(
        cargando: false,
        mensajeExito: item.idTarRuti == 0
            ? 'Tarea rutinaria agregada.'
            : 'Tarea rutinaria actualizada.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<bool> eliminar(int idTarRuti, int audUsuario) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.eliminar(idTarRuti, audUsuario);
      state = state.copyWith(
        cargando: false,
        mensajeExito: 'Tarea rutinaria eliminada.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _tareaRutinariaRepoProvider = Provider((ref) => TareaRutinariaImpl());

final tareaRutinariaProvider =
    StateNotifierProvider.autoDispose<TareaRutinariaNotifier, TareaRutinariaState>(
  (ref) => TareaRutinariaNotifier(ref.read(_tareaRutinariaRepoProvider)),
);
