// Destino final: lib/core/state/llegada_provider.dart
import 'package:bosque_flutter/data/repositories/llegada_impl.dart';
import 'package:bosque_flutter/domain/entities/llegada_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LlegadaState {
  final List<LlegadaEntity> items;
  final bool cargando;
  final String? mensajeError;
  final String? mensajeExito;

  const LlegadaState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  LlegadaState copyWith({
    List<LlegadaEntity>? items,
    bool? cargando,
    String? mensajeError,
    String? mensajeExito,
  }) => LlegadaState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class LlegadaNotifier extends StateNotifier<LlegadaState> {
  final LlegadaImpl _repo;

  LlegadaNotifier(this._repo) : super(const LlegadaState()) {
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

  Future<bool> guardar(LlegadaEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      state = state.copyWith(
        cargando: false,
        mensajeExito: item.idRp == 0
            ? 'Llegada agregada.'
            : 'Llegada actualizada.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<bool> eliminar(int idRp, int audUsuario) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.eliminar(idRp, audUsuario);
      state = state.copyWith(cargando: false, mensajeExito: 'Llegada eliminada.');
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _llegadaRepoProvider = Provider((ref) => LlegadaImpl());

final llegadaProvider =
    StateNotifierProvider.autoDispose<LlegadaNotifier, LlegadaState>(
  (ref) => LlegadaNotifier(ref.read(_llegadaRepoProvider)),
);
