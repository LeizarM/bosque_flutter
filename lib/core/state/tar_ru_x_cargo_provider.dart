// Destino final: lib/core/state/tar_ru_x_cargo_provider.dart
import 'package:bosque_flutter/data/repositories/tar_ru_x_cargo_impl.dart';
import 'package:bosque_flutter/domain/entities/tar_ru_x_cargo_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TarRuXCargoState {
  final List<TarRuXCargoEntity> items;
  final bool cargando;
  final String? mensajeError;
  final String? mensajeExito;

  const TarRuXCargoState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  TarRuXCargoState copyWith({
    List<TarRuXCargoEntity>? items,
    bool? cargando,
    String? mensajeError,
    String? mensajeExito,
  }) => TarRuXCargoState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class TarRuXCargoNotifier extends StateNotifier<TarRuXCargoState> {
  final TarRuXCargoImpl _repo;

  TarRuXCargoNotifier(this._repo) : super(const TarRuXCargoState()) {
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

  Future<bool> guardar(TarRuXCargoEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      state = state.copyWith(
        cargando: false,
        mensajeExito: item.idTarXCargo == 0
            ? 'Asignación de cargo a tarea rutinaria agregada.'
            : 'Asignación de cargo a tarea rutinaria actualizada.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<bool> eliminar(int idTarXCargo, int audUsuario) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.eliminar(idTarXCargo, audUsuario);
      state = state.copyWith(
        cargando: false,
        mensajeExito: 'Asignación de cargo a tarea rutinaria eliminada.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _tarRuXCargoRepoProvider = Provider((ref) => TarRuXCargoImpl());

final tarRuXCargoProvider =
    StateNotifierProvider.autoDispose<TarRuXCargoNotifier, TarRuXCargoState>(
  (ref) => TarRuXCargoNotifier(ref.read(_tarRuXCargoRepoProvider)),
);
