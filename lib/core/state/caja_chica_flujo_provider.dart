// Destino final: lib/core/state/caja_chica_flujo_provider.dart
import 'package:bosque_flutter/data/repositories/caja_chica_flujo_impl.dart';
import 'package:bosque_flutter/domain/entities/caja_chica_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// codSucursal ya NO viaja acá — el proc lo resuelve server-side del cargo
// vigente del empleado dueño de la ocurrencia (code-review, 2026-09-03).
typedef CajaChicaParams = ({int idBitTarea});

class CajaChicaFlujoState {
  final List<CajaChicaEntity> items;
  final bool cargando;
  final bool guardando;
  final bool finalizando;
  final String? mensajeError;
  final bool finalizado;

  const CajaChicaFlujoState({
    this.items = const [],
    this.cargando = false,
    this.guardando = false,
    this.finalizando = false,
    this.mensajeError,
    this.finalizado = false,
  });

  CajaChicaFlujoState copyWith({
    List<CajaChicaEntity>? items,
    bool? cargando,
    bool? guardando,
    bool? finalizando,
    String? mensajeError,
    bool? finalizado,
  }) => CajaChicaFlujoState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    guardando: guardando ?? this.guardando,
    finalizando: finalizando ?? this.finalizando,
    mensajeError: mensajeError,
    finalizado: finalizado ?? this.finalizado,
  );

  double get saldoActual => items.isEmpty ? 0 : (items.last.saldo ?? 0);
}

class CajaChicaFlujoNotifier extends StateNotifier<CajaChicaFlujoState> {
  final CajaChicaFlujoImpl _repo;
  final CajaChicaParams _params;

  CajaChicaFlujoNotifier(this._repo, this._params) : super(const CajaChicaFlujoState()) {
    Future.microtask(() => cargar());
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true);
    try {
      final items = await _repo.listarDelLote(
        idBitTarea: _params.idBitTarea,
      );
      state = state.copyWith(cargando: false, items: items);
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
    }
  }

  Future<bool> registrarEgreso({
    required double montoEg,
    required String descripcion,
    required int codEmpDestino,
    int? numFactura,
    int? numVale,
  }) async {
    state = state.copyWith(guardando: true);
    try {
      await _repo.registrarEgreso(
        idBitTarea: _params.idBitTarea,
        montoEg: montoEg,
        descripcion: descripcion,
        codEmpDestino: codEmpDestino,
        numFactura: numFactura,
        numVale: numVale,
      );
      state = state.copyWith(guardando: false);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(guardando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<void> finalizar() async {
    state = state.copyWith(finalizando: true);
    try {
      await _repo.finalizar(_params.idBitTarea);
      state = state.copyWith(finalizando: false, finalizado: true);
    } catch (e) {
      state = state.copyWith(finalizando: false, mensajeError: e.toString());
    }
  }
}

final _cajaChicaFlujoRepoProvider = Provider((ref) => CajaChicaFlujoImpl());

final cajaChicaFlujoProvider = StateNotifierProvider.autoDispose
    .family<CajaChicaFlujoNotifier, CajaChicaFlujoState, CajaChicaParams>((ref, params) {
      return CajaChicaFlujoNotifier(ref.read(_cajaChicaFlujoRepoProvider), params);
    });
