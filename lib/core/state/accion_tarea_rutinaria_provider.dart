import 'package:bosque_flutter/core/ui/mensaje_error_tareas.dart';
import 'package:bosque_flutter/data/repositories/accion_tarea_rutinaria_impl.dart';
import 'package:bosque_flutter/domain/entities/accion_tarea_rutinaria_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccionTareaRutinariaState {
  final List<AccionTareaRutinariaEntity> items;
  final bool cargando;
  final String? mensajeError;
  final String? mensajeExito;

  const AccionTareaRutinariaState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  AccionTareaRutinariaState copyWith({
    List<AccionTareaRutinariaEntity>? items,
    bool? cargando,
    String? mensajeError,
    String? mensajeExito,
  }) => AccionTareaRutinariaState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class AccionTareaRutinariaNotifier
    extends StateNotifier<AccionTareaRutinariaState> {
  final AccionTareaRutinariaImpl _repo;

  AccionTareaRutinariaNotifier(this._repo)
    : super(const AccionTareaRutinariaState()) {
    Future.microtask(() => cargar());
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true);
    try {
      final data = await _repo.obtener();
      if (!mounted) return;
      state = state.copyWith(items: data, cargando: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(cargando: false, mensajeError: mensajeError(e));
    }
  }

  Future<bool> guardar(AccionTareaRutinariaEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      if (!mounted) return true;
      state = state.copyWith(
        cargando: false,
        mensajeExito:
            item.idATR == 0
                ? 'Acción de tarea rutinaria agregada.'
                : 'Acción de tarea rutinaria actualizada.',
      );
      await cargar();
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(cargando: false, mensajeError: mensajeError(e));
      return false;
    }
  }

  Future<bool> eliminar(int idATR, int audUsuario) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.eliminar(idATR, audUsuario);
      if (!mounted) return true;
      state = state.copyWith(
        cargando: false,
        mensajeExito: 'Acción de tarea rutinaria eliminada.',
      );
      await cargar();
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(cargando: false, mensajeError: mensajeError(e));
      return false;
    }
  }
}

final _accionTareaRutinariaRepoProvider = Provider(
  (ref) => AccionTareaRutinariaImpl(),
);

final accionTareaRutinariaProvider = StateNotifierProvider.autoDispose<
  AccionTareaRutinariaNotifier,
  AccionTareaRutinariaState
>(
  (ref) =>
      AccionTareaRutinariaNotifier(ref.read(_accionTareaRutinariaRepoProvider)),
);
