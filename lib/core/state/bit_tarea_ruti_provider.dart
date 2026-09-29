// Destino final: lib/core/state/bit_tarea_ruti_provider.dart
import 'package:bosque_flutter/data/repositories/bit_tarea_ruti_impl.dart';
import 'package:bosque_flutter/domain/entities/bit_tarea_ruti_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Marca de "no cambiar" para poder limpiar `errorCarga` pasándole null.
const _igual = Object();

class BitTareaRutiState {
  final List<BitTareaRutiEntity> items;
  final bool cargando;

  /// Si alguna lectura terminó bien.
  ///
  /// Sin esto, una lectura fallida dejaba la lista vacía y "Mis tareas" decía
  /// "Todavía no tienes tareas rutinarias": un error de red contado como una
  /// buena noticia (auditoría del 2026-09-11).
  final bool cargado;

  /// Por qué falló la última lectura; queda hasta la próxima buena.
  final Object? errorCarga;

  final String? mensajeError;
  final String? mensajeExito;

  const BitTareaRutiState({
    this.items = const [],
    this.cargando = false,
    this.cargado = false,
    this.errorCarga,
    this.mensajeError,
    this.mensajeExito,
  });

  BitTareaRutiState copyWith({
    List<BitTareaRutiEntity>? items,
    bool? cargando,
    bool? cargado,
    Object? errorCarga = _igual,
    String? mensajeError,
    String? mensajeExito,
  }) => BitTareaRutiState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    cargado: cargado ?? this.cargado,
    errorCarga: identical(errorCarga, _igual) ? this.errorCarga : errorCarga,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class BitTareaRutiNotifier extends StateNotifier<BitTareaRutiState> {
  final BitTareaRutiImpl _repo;

  BitTareaRutiNotifier(this._repo)
    // Arranca cargando: en reposo, el primer cuadro se vería como un error.
    : super(const BitTareaRutiState(cargando: true)) {
    Future.microtask(() => cargar());
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true);
    try {
      final data = await _repo.obtener();
      if (!mounted) return;
      state = state.copyWith(
        items: data,
        cargando: false,
        cargado: true,
        errorCarga: null,
      );
    } catch (e) {
      if (!mounted) return;
      // Si ya había una lista en pantalla, se queda y se avisa; si es la
      // primera lectura, la pantalla muestra el error en su lugar.
      state = state.copyWith(
        cargando: false,
        errorCarga: e,
        mensajeError: state.cargado ? e.toString() : null,
      );
    }
  }

  Future<bool> guardar(BitTareaRutiEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      state = state.copyWith(
        cargando: false,
        mensajeExito:
            item.idBitTarea == 0
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
      state = state.copyWith(
        cargando: false,
        mensajeExito: 'Bitácora de tarea rutinaria eliminada.',
      );
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
