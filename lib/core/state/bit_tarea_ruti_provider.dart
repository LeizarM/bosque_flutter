// Destino final: lib/core/state/bit_tarea_ruti_provider.dart
import 'package:bosque_flutter/data/repositories/bit_tarea_ruti_impl.dart';
import 'package:bosque_flutter/domain/entities/bit_tarea_ruti_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BitTareaRutiState {
  final List<BitTareaRutiEntity> items;
  final bool cargando;
  final String? mensajeError;
  final String? mensajeExito;

  const BitTareaRutiState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  BitTareaRutiState copyWith({
    List<BitTareaRutiEntity>? items,
    bool? cargando,
    String? mensajeError,
    String? mensajeExito,
  }) => BitTareaRutiState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class BitTareaRutiNotifier extends StateNotifier<BitTareaRutiState> {
  final BitTareaRutiImpl _repo;

  BitTareaRutiNotifier(this._repo) : super(const BitTareaRutiState()) {
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

  Future<bool> guardar(BitTareaRutiEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      state = state.copyWith(
        cargando: false,
        mensajeExito: item.idBitTarea == 0
            ? 'Bitácora de tarea rutinaria agregada.'
            : 'Bitácora de tarea rutinaria actualizada.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<bool> eliminar(int idBitTarea, int audUsuario) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.eliminar(idBitTarea, audUsuario);
      state = state.copyWith(cargando: false, mensajeExito: 'Bitácora de tarea rutinaria eliminada.');
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _bitTareaRutiRepoProvider = Provider((ref) => BitTareaRutiImpl());

final bitTareaRutiProvider =
    StateNotifierProvider.autoDispose<BitTareaRutiNotifier, BitTareaRutiState>(
  (ref) => BitTareaRutiNotifier(ref.read(_bitTareaRutiRepoProvider)),
);
