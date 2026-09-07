// Destino final: lib/core/state/caja_fuerte_provider.dart
import 'package:bosque_flutter/data/repositories/caja_fuerte_impl.dart';
import 'package:bosque_flutter/domain/entities/llegada_caja_fuerte_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CajaFuerteState {
  final List<LlegadaCajaFuerteEntity> filas;
  final bool guardando;
  final String? mensajeError;
  final int? filasGuardadas;

  const CajaFuerteState({
    this.filas = const [],
    this.guardando = false,
    this.mensajeError,
    this.filasGuardadas,
  });

  CajaFuerteState copyWith({
    List<LlegadaCajaFuerteEntity>? filas,
    bool? guardando,
    String? mensajeError,
    int? filasGuardadas,
  }) => CajaFuerteState(
    filas: filas ?? this.filas,
    guardando: guardando ?? this.guardando,
    mensajeError: mensajeError,
    filasGuardadas: filasGuardadas,
  );
}

class CajaFuerteNotifier extends StateNotifier<CajaFuerteState> {
  final CajaFuerteImpl _repo;
  int _contador = 0;

  CajaFuerteNotifier(this._repo)
      : super(CajaFuerteState(filas: [LlegadaCajaFuerteEntity(id: '0')])) {
    _contador = 1;
  }

  void agregarFila() {
    state = state.copyWith(filas: [...state.filas, LlegadaCajaFuerteEntity(id: '${_contador++}')]);
  }

  void quitarFila(String id) {
    if (state.filas.length <= 1) return;
    state = state.copyWith(filas: state.filas.where((f) => f.id != id).toList());
  }

  void actualizarFila(String id, LlegadaCajaFuerteEntity Function(LlegadaCajaFuerteEntity) actualizar) {
    state = state.copyWith(
      filas: state.filas.map((f) => f.id == id ? actualizar(f) : f).toList(),
    );
  }

  Future<bool> registrar({
    required int idTarRuti,
    required int idBitTarea,
  }) async {
    // Antes: se filtraban las filas válidas y se guardaban solo esas, sin
    // avisar si alguna fila con datos parciales (p.ej. cliente escrito pero
    // sin tipo elegido) quedaba afuera en silencio — el usuario veía "N
    // llegada(s) registrada(s)" sin saber que faltó una. Ahora: si hay
    // alguna fila con contenido pero incompleta, se bloquea el guardado en
    // vez de descartarla.
    final conContenido = state.filas
        .where((f) => f.cliente.trim().isNotEmpty || (f.importe ?? 0) > 0 || f.tipo != null)
        .toList();
    if (conContenido.isEmpty) {
      state = state.copyWith(mensajeError: 'Completa al menos una llegada (cliente, importe y tipo).');
      return false;
    }
    final incompletas = conContenido.where((f) => !f.esValida).length;
    if (incompletas > 0) {
      state = state.copyWith(
        mensajeError: incompletas == 1
            ? 'Hay una fila incompleta — revisa que tenga cliente, importe y tipo.'
            : 'Hay $incompletas filas incompletas — revisa que cada una tenga cliente, importe y tipo.',
      );
      return false;
    }
    final validas = conContenido;
    state = state.copyWith(guardando: true);
    try {
      final cantidad = await _repo.registrar(
        idTarRuti: idTarRuti,
        idBitTarea: idBitTarea,
        llegadas: validas,
      );
      state = state.copyWith(guardando: false, filasGuardadas: cantidad);
      return true;
    } catch (e) {
      state = state.copyWith(guardando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _cajaFuerteRepoProvider = Provider((ref) => CajaFuerteImpl());

final cajaFuerteProvider = StateNotifierProvider.autoDispose<CajaFuerteNotifier, CajaFuerteState>(
  (ref) => CajaFuerteNotifier(ref.read(_cajaFuerteRepoProvider)),
);
