// Destino final: lib/core/state/mov_caja_provider.dart
import 'package:bosque_flutter/data/repositories/mov_caja_impl.dart';
import 'package:bosque_flutter/domain/entities/mov_caja_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MovCajaState {
  final List<MovCajaEntity> items;
  final bool cargando;
  final String? mensajeError;
  final String? mensajeExito;

  const MovCajaState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  MovCajaState copyWith({
    List<MovCajaEntity>? items,
    bool? cargando,
    String? mensajeError,
    String? mensajeExito,
  }) => MovCajaState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class MovCajaNotifier extends StateNotifier<MovCajaState> {
  final MovCajaImpl _repo;

  MovCajaNotifier(this._repo) : super(const MovCajaState()) {
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

  Future<bool> guardar(MovCajaEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      state = state.copyWith(
        cargando: false,
        mensajeExito: item.idMC == 0
            ? 'Movimiento de caja agregado.'
            : 'Movimiento de caja actualizado.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<bool> eliminar(int idMC, int audUsuario) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.eliminar(idMC, audUsuario);
      state = state.copyWith(cargando: false, mensajeExito: 'Movimiento de caja eliminado.');
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _movCajaRepoProvider = Provider((ref) => MovCajaImpl());

final movCajaProvider =
    StateNotifierProvider.autoDispose<MovCajaNotifier, MovCajaState>(
  (ref) => MovCajaNotifier(ref.read(_movCajaRepoProvider)),
);
