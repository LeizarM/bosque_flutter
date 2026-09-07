// Destino final: lib/core/state/det_documentacion_provider.dart
import 'package:bosque_flutter/data/repositories/det_documentacion_impl.dart';
import 'package:bosque_flutter/domain/entities/det_documentacion_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetDocumentacionState {
  final List<DetDocumentacionEntity> items;
  final bool cargando;
  final String? mensajeError;
  final String? mensajeExito;

  const DetDocumentacionState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  DetDocumentacionState copyWith({
    List<DetDocumentacionEntity>? items,
    bool? cargando,
    String? mensajeError,
    String? mensajeExito,
  }) => DetDocumentacionState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class DetDocumentacionNotifier extends StateNotifier<DetDocumentacionState> {
  final DetDocumentacionImpl _repo;

  DetDocumentacionNotifier(this._repo) : super(const DetDocumentacionState()) {
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

  Future<bool> guardar(DetDocumentacionEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      state = state.copyWith(
        cargando: false,
        mensajeExito: item.idDetDoc == 0
            ? 'Detalle de documentación agregado.'
            : 'Detalle de documentación actualizado.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<bool> eliminar(int idDetDoc, int audUsuario) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.eliminar(idDetDoc, audUsuario);
      state = state.copyWith(
        cargando: false,
        mensajeExito: 'Detalle de documentación eliminado.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _detDocumentacionRepoProvider = Provider((ref) => DetDocumentacionImpl());

final detDocumentacionProvider = StateNotifierProvider.autoDispose<
  DetDocumentacionNotifier,
  DetDocumentacionState
>((ref) => DetDocumentacionNotifier(ref.read(_detDocumentacionRepoProvider)));
