// Destino final: lib/core/state/documentacion_provider.dart
import 'package:bosque_flutter/data/repositories/documentacion_impl.dart';
import 'package:bosque_flutter/domain/entities/documentacion_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DocumentacionState {
  final List<DocumentacionEntity> items;
  final bool cargando;
  final String? mensajeError;
  final String? mensajeExito;

  const DocumentacionState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  DocumentacionState copyWith({
    List<DocumentacionEntity>? items,
    bool? cargando,
    String? mensajeError,
    String? mensajeExito,
  }) => DocumentacionState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class DocumentacionNotifier extends StateNotifier<DocumentacionState> {
  final DocumentacionImpl _repo;

  DocumentacionNotifier(this._repo) : super(const DocumentacionState()) {
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

  Future<bool> guardar(DocumentacionEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      state = state.copyWith(
        cargando: false,
        mensajeExito: item.idDoc == 0
            ? 'Documentación agregada.'
            : 'Documentación actualizada.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<bool> eliminar(int idDoc, int audUsuario) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.eliminar(idDoc, audUsuario);
      state = state.copyWith(cargando: false, mensajeExito: 'Documentación eliminada.');
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _documentacionRepoProvider = Provider((ref) => DocumentacionImpl());

final documentacionProvider =
    StateNotifierProvider.autoDispose<DocumentacionNotifier, DocumentacionState>(
  (ref) => DocumentacionNotifier(ref.read(_documentacionRepoProvider)),
);
