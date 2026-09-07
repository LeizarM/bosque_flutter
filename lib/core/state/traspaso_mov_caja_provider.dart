// Destino final: lib/core/state/traspaso_mov_caja_provider.dart
import 'package:bosque_flutter/data/repositories/traspaso_mov_caja_impl.dart';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TraspasoMovCajaState {
  final List<TraspasoMovCajaEntity> items;
  final bool cargando;
  final String? mensajeError;
  final String? mensajeExito;

  const TraspasoMovCajaState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  TraspasoMovCajaState copyWith({
    List<TraspasoMovCajaEntity>? items,
    bool? cargando,
    String? mensajeError,
    String? mensajeExito,
  }) => TraspasoMovCajaState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class TraspasoMovCajaNotifier extends StateNotifier<TraspasoMovCajaState> {
  final TraspasoMovCajaImpl _repo;

  TraspasoMovCajaNotifier(this._repo) : super(const TraspasoMovCajaState()) {
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

  Future<bool> guardar(TraspasoMovCajaEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      state = state.copyWith(
        cargando: false,
        mensajeExito: item.idTrasp == 0
            ? 'Traspaso de movimiento de caja agregado.'
            : 'Traspaso de movimiento de caja actualizado.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<bool> eliminar(int idTrasp, int audUsuario) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.eliminar(idTrasp, audUsuario);
      state = state.copyWith(
        cargando: false,
        mensajeExito: 'Traspaso de movimiento de caja eliminado.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _traspasoMovCajaRepoProvider = Provider((ref) => TraspasoMovCajaImpl());

final traspasoMovCajaProvider =
    StateNotifierProvider.autoDispose<TraspasoMovCajaNotifier, TraspasoMovCajaState>(
  (ref) => TraspasoMovCajaNotifier(ref.read(_traspasoMovCajaRepoProvider)),
);
