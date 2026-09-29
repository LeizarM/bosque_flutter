import 'package:bosque_flutter/data/repositories/tarea_rutinaria_impl.dart';
import 'package:bosque_flutter/domain/entities/tarea_rutinaria_entity.dart';
import 'package:bosque_flutter/domain/repositories/tarea_rutinaria_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TareaRutinariaState {
  final List<TareaRutinariaEntity> items;
  final bool cargando;

  /// Si alguna carga terminó bien: distingue "aún no se cargó" de "se cargó
  /// y vino vacío".
  final bool cargado;
  final String? mensajeError;
  final String? mensajeExito;

  const TareaRutinariaState({
    this.items = const [],
    this.cargando = false,
    this.cargado = false,
    this.mensajeError,
    this.mensajeExito,
  });

  TareaRutinariaState copyWith({
    List<TareaRutinariaEntity>? items,
    bool? cargando,
    bool? cargado,
    String? mensajeError,
    String? mensajeExito,
  }) => TareaRutinariaState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    cargado: cargado ?? this.cargado,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class TareaRutinariaNotifier extends StateNotifier<TareaRutinariaState> {
  // Interfaz y no implementación: la implementación arma Dio (lee la URL de
  // dotenv) y eso impedía probar pantallas con un catálogo falso.
  final TareaRutinariaRepository _repo;

  TareaRutinariaNotifier(this._repo) : super(const TareaRutinariaState()) {
    Future.microtask(() => cargar());
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true);
    try {
      final data = await _repo.obtener();
      state = state.copyWith(items: data, cargando: false, cargado: true);
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
        mensajeExito:
            item.idTarRuti == 0
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

final tareaRutinariaProvider = StateNotifierProvider.autoDispose<
  TareaRutinariaNotifier,
  TareaRutinariaState
>((ref) => TareaRutinariaNotifier(ref.read(_tareaRutinariaRepoProvider)));
