// Destino final: lib/core/state/caja_chica_provider.dart
import 'package:bosque_flutter/data/repositories/caja_chica_impl.dart';
import 'package:bosque_flutter/domain/entities/caja_chica_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CajaChicaState {
  final List<CajaChicaEntity> items;
  final bool cargando;
  final String? mensajeError;
  final String? mensajeExito;

  const CajaChicaState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  CajaChicaState copyWith({
    List<CajaChicaEntity>? items,
    bool? cargando,
    String? mensajeError,
    String? mensajeExito,
  }) => CajaChicaState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class CajaChicaNotifier extends StateNotifier<CajaChicaState> {
  final CajaChicaImpl _repo;

  CajaChicaNotifier(this._repo) : super(const CajaChicaState()) {
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

  Future<bool> guardar(CajaChicaEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      state = state.copyWith(
        cargando: false,
        mensajeExito: item.idCC == 0
            ? 'Caja chica agregada.'
            : 'Caja chica actualizada.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<bool> eliminar(int idCC, int audUsuario) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.eliminar(idCC, audUsuario);
      state = state.copyWith(cargando: false, mensajeExito: 'Caja chica eliminada.');
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _cajaChicaRepoProvider = Provider((ref) => CajaChicaImpl());

final cajaChicaProvider =
    StateNotifierProvider.autoDispose<CajaChicaNotifier, CajaChicaState>(
  (ref) => CajaChicaNotifier(ref.read(_cajaChicaRepoProvider)),
);
