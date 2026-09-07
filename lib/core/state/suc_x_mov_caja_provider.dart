// Destino final: lib/core/state/suc_x_mov_caja_provider.dart
import 'package:bosque_flutter/data/repositories/suc_x_mov_caja_impl.dart';
import 'package:bosque_flutter/domain/entities/suc_x_mov_caja_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SucXMovCajaState {
  final List<SucXMovCajaEntity> items;
  final bool cargando;
  final String? mensajeError;
  final String? mensajeExito;

  const SucXMovCajaState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  SucXMovCajaState copyWith({
    List<SucXMovCajaEntity>? items,
    bool? cargando,
    String? mensajeError,
    String? mensajeExito,
  }) => SucXMovCajaState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class SucXMovCajaNotifier extends StateNotifier<SucXMovCajaState> {
  final SucXMovCajaImpl _repo;

  SucXMovCajaNotifier(this._repo) : super(const SucXMovCajaState()) {
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

  Future<bool> guardar(SucXMovCajaEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      state = state.copyWith(
        cargando: false,
        mensajeExito: item.idSxMC == 0
            ? 'Sucursal por movimiento de caja agregada.'
            : 'Sucursal por movimiento de caja actualizada.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<bool> eliminar(int idSxMC, int audUsuario) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.eliminar(idSxMC, audUsuario);
      state = state.copyWith(cargando: false, mensajeExito: 'Sucursal por movimiento de caja eliminada.');
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _sucXMovCajaRepoProvider = Provider((ref) => SucXMovCajaImpl());

final sucXMovCajaProvider =
    StateNotifierProvider.autoDispose<SucXMovCajaNotifier, SucXMovCajaState>(
  (ref) => SucXMovCajaNotifier(ref.read(_sucXMovCajaRepoProvider)),
);
