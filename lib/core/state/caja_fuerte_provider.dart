import 'package:bosque_flutter/data/repositories/caja_fuerte_impl.dart';
import 'package:bosque_flutter/domain/entities/cierre_operaciones_entity.dart';
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
    state = state.copyWith(
      filas: [...state.filas, LlegadaCajaFuerteEntity(id: '${_contador++}')],
    );
  }

  /// Deja el formulario como recién abierto, con una fila vacía.
  ///
  /// Se llama después de guardar: lo registrado pasa a verse en la lista del
  /// día, y si las filas se quedaran en el formulario, volver a tocar
  /// "Guardar" registraría lo mismo una segunda vez.
  void limpiarFormulario() {
    state = state.copyWith(
      filas: [LlegadaCajaFuerteEntity(id: '${_contador++}')],
    );
  }

  void quitarFila(String id) {
    if (state.filas.length <= 1) return;
    state = state.copyWith(
      filas: state.filas.where((f) => f.id != id).toList(),
    );
  }

  void actualizarFila(
    String id,
    LlegadaCajaFuerteEntity Function(LlegadaCajaFuerteEntity) actualizar,
  ) {
    state = state.copyWith(
      filas: state.filas.map((f) => f.id == id ? actualizar(f) : f).toList(),
    );
  }

  Future<bool> registrar({
    required int idTarRuti,
    required int idBitTarea,
  }) async {
    // Se mandan todas las filas, tal como están. Qué fila está vacía (se
    // ignora), cuál está incompleta (rechaza) y que haya al menos una lo
    // decide p_abm_tac_Llegada 'R' (archivo SQL 79, errores 10, 11, 12 y 14):
    // las reglas de registro van en SQL, para cambiarlas sin recompilar.
    state = state.copyWith(guardando: true);
    try {
      final cantidad = await _repo.registrar(
        idTarRuti: idTarRuti,
        idBitTarea: idBitTarea,
        llegadas: state.filas,
      );
      state = state.copyWith(guardando: false, filasGuardadas: cantidad);
      return true;
    } catch (e) {
      state = state.copyWith(
        guardando: false,
        mensajeError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final _cajaFuerteRepoProvider = Provider((ref) => CajaFuerteImpl());

/// Lo que ya quedó registrado hoy, por ocurrencia.
///
/// Va como `FutureProvider` aparte y no dentro de [CajaFuerteState] porque son
/// dos cosas distintas: el estado tiene el formulario que se está llenando
/// —filas que todavía no existen en la base— y esto es lo que la base ya
/// guardó. Mezclarlos obligaría a recargar el servidor cada vez que alguien
/// escribe una letra en el formulario.
///
/// Se refresca con `ref.invalidate` después de guardar.
final llegadasCajaFuerteDeHoyProvider = FutureProvider.autoDispose
    .family<List<LlegadaDelCierre>, int>(
      (ref, idBitTarea) =>
          ref.read(_cajaFuerteRepoProvider).registradasHoy(idBitTarea),
    );

final cajaFuerteProvider =
    StateNotifierProvider.autoDispose<CajaFuerteNotifier, CajaFuerteState>(
      (ref) => CajaFuerteNotifier(ref.read(_cajaFuerteRepoProvider)),
    );
