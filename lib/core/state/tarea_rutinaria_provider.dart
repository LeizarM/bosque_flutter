// Destino final: lib/core/state/tarea_rutinaria_provider.dart
import 'package:bosque_flutter/data/repositories/tarea_rutinaria_impl.dart';
import 'package:bosque_flutter/domain/entities/tarea_rutinaria_entity.dart';
import 'package:bosque_flutter/domain/repositories/tarea_rutinaria_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TareaRutinariaState {
  final List<TareaRutinariaEntity> items;
  final bool cargando;

  /// Si alguna carga terminó bien.
  ///
  /// Sin esto, "todavía no se cargó" y "se cargó y vino vacío" son el mismo
  /// estado: el provider arranca con la lista vacía y `cargando` en false, y
  /// hasta que corre su primera carga cualquier pantalla que lo mire cree que
  /// el catálogo no tiene nada.
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
  // La interfaz y no la implementación: la implementación arma Dio, que lee
  // la URL de dotenv, y eso impedía probar con un catálogo falso cualquier
  // pantalla que use este provider.
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
