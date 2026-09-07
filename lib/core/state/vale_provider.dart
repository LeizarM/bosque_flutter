// Destino final: lib/core/state/vale_provider.dart
import 'package:bosque_flutter/data/repositories/vale_impl.dart';
import 'package:bosque_flutter/domain/entities/vale_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ValeState {
  final List<ValeEntity> items;
  final bool cargando;
  final String? mensajeError;
  final String? mensajeExito;

  const ValeState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  ValeState copyWith({
    List<ValeEntity>? items,
    bool? cargando,
    String? mensajeError,
    String? mensajeExito,
  }) => ValeState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class ValeNotifier extends StateNotifier<ValeState> {
  final ValeImpl _repo;

  ValeNotifier(this._repo) : super(const ValeState()) {
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

  Future<bool> guardar(ValeEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      state = state.copyWith(
        cargando: false,
        mensajeExito: item.idVale == 0
            ? 'Vale agregado.'
            : 'Vale actualizado.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<bool> eliminar(int idVale, int audUsuario) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.eliminar(idVale, audUsuario);
      state = state.copyWith(cargando: false, mensajeExito: 'Vale eliminado.');
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _valeRepoProvider = Provider((ref) => ValeImpl());

final valeProvider =
    StateNotifierProvider.autoDispose<ValeNotifier, ValeState>(
  (ref) => ValeNotifier(ref.read(_valeRepoProvider)),
);
