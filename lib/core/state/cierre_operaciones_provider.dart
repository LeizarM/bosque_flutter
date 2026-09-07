// Destino final: lib/core/state/cierre_operaciones_provider.dart
import 'package:bosque_flutter/data/repositories/cierre_operaciones_impl.dart';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CierreOperacionesState {
  final List<TraspasoMovCajaEntity> traspasos;
  final DateTime? fecha; // null = hoy
  final Map<int, int> fueVerificadoPorFila; // idTrasp -> 0/1, default 0 (no preseleccionado, igual que el legacy)
  final bool cargando;
  final bool confirmando;
  final String? mensajeError;
  final int? traspasosConfirmados;

  const CierreOperacionesState({
    this.traspasos = const [],
    this.fecha,
    this.fueVerificadoPorFila = const {},
    this.cargando = false,
    this.confirmando = false,
    this.mensajeError,
    this.traspasosConfirmados,
  });

  DateTime get fechaEfectiva => fecha ?? DateTime.now();

  CierreOperacionesState copyWith({
    List<TraspasoMovCajaEntity>? traspasos,
    DateTime? fecha,
    Map<int, int>? fueVerificadoPorFila,
    bool? cargando,
    bool? confirmando,
    String? mensajeError,
    int? traspasosConfirmados,
  }) => CierreOperacionesState(
    traspasos: traspasos ?? this.traspasos,
    fecha: fecha ?? this.fecha,
    fueVerificadoPorFila: fueVerificadoPorFila ?? this.fueVerificadoPorFila,
    cargando: cargando ?? this.cargando,
    confirmando: confirmando ?? this.confirmando,
    mensajeError: mensajeError,
    traspasosConfirmados: traspasosConfirmados,
  );
}

class CierreOperacionesNotifier extends StateNotifier<CierreOperacionesState> {
  final CierreOperacionesImpl _repo;

  CierreOperacionesNotifier(this._repo) : super(const CierreOperacionesState()) {
    Future.microtask(() => cargar());
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true);
    try {
      final traspasos = await _repo.obtenerTraspasos(fecha: state.fecha);
      // Al recargar (nueva fecha o refresh) el mapa de verificación arranca
      // limpio — el legacy tampoco preselecciona nada al desplegar de nuevo.
      state = state.copyWith(cargando: false, traspasos: traspasos, fueVerificadoPorFila: const {});
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
    }
  }

  /// Cambia la fecha en revisión (el `<p:calendar>` + "Desplegar" real del
  /// legacy) y recarga los traspasos de esa fecha.
  Future<void> cambiarFecha(DateTime nuevaFecha) async {
    state = state.copyWith(fecha: nuevaFecha);
    await cargar();
  }

  void toggleVerificado(int idTrasp) {
    final actual = state.fueVerificadoPorFila[idTrasp] ?? 0;
    state = state.copyWith(
      fueVerificadoPorFila: {...state.fueVerificadoPorFila, idTrasp: actual == 1 ? 0 : 1},
    );
  }

  Future<void> confirmar(int idBitTarea) async {
    state = state.copyWith(confirmando: true);
    try {
      // El legacy re-guarda CADA fila en cada submit (guardarTraspasos()
      // hace un loop sobre lstTraspaso completo) — se manda el estado de
      // fueVerificado de todas las filas mostradas, no solo las tocadas.
      final filas = state.traspasos
          .map(
            (t) => {
              'idTrasp': t.idTrasp,
              'fueVerificado': state.fueVerificadoPorFila[t.idTrasp] ?? 0,
            },
          )
          .toList();
      final cantidad = await _repo.confirmar(idBitTarea, fecha: state.fecha, traspasos: filas);
      state = state.copyWith(confirmando: false, traspasosConfirmados: cantidad);
    } catch (e) {
      state = state.copyWith(confirmando: false, mensajeError: e.toString());
    }
  }
}

final _cierreOperacionesRepoProvider = Provider((ref) => CierreOperacionesImpl());

final cierreOperacionesProvider =
    StateNotifierProvider.autoDispose<CierreOperacionesNotifier, CierreOperacionesState>(
  (ref) => CierreOperacionesNotifier(ref.read(_cierreOperacionesRepoProvider)),
);
