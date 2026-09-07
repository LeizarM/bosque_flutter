// Destino final: lib/core/state/monto_caja_chica_x_suc_provider.dart
import 'package:bosque_flutter/data/repositories/monto_caja_chica_x_suc_impl.dart';
import 'package:bosque_flutter/domain/entities/monto_caja_chica_x_suc_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MontoCajaChicaXSucState {
  final List<MontoCajaChicaXSucEntity> items;
  final bool cargando;
  final String? mensajeError;
  final String? mensajeExito;

  const MontoCajaChicaXSucState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  MontoCajaChicaXSucState copyWith({
    List<MontoCajaChicaXSucEntity>? items,
    bool? cargando,
    String? mensajeError,
    String? mensajeExito,
  }) => MontoCajaChicaXSucState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class MontoCajaChicaXSucNotifier extends StateNotifier<MontoCajaChicaXSucState> {
  final MontoCajaChicaXSucImpl _repo;

  MontoCajaChicaXSucNotifier(this._repo)
    : super(const MontoCajaChicaXSucState()) {
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

  Future<bool> guardar(MontoCajaChicaXSucEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      state = state.copyWith(
        cargando: false,
        mensajeExito: item.idCS == 0
            ? 'Monto de caja chica por sucursal agregado.'
            : 'Monto de caja chica por sucursal actualizado.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<bool> eliminar(int idCS, int audUsuario) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.eliminar(idCS, audUsuario);
      state = state.copyWith(
        cargando: false,
        mensajeExito: 'Monto de caja chica por sucursal eliminado.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _montoCajaChicaXSucRepoProvider = Provider(
  (ref) => MontoCajaChicaXSucImpl(),
);

final montoCajaChicaXSucProvider = StateNotifierProvider.autoDispose<
  MontoCajaChicaXSucNotifier,
  MontoCajaChicaXSucState
>((ref) => MontoCajaChicaXSucNotifier(ref.read(_montoCajaChicaXSucRepoProvider)));
