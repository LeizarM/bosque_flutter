// Destino final: lib/core/state/det_arqueo_caja_sucursales_provider.dart
import 'package:bosque_flutter/data/repositories/det_arqueo_caja_sucursales_impl.dart';
import 'package:bosque_flutter/domain/entities/det_arqueo_caja_sucursales_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetArqueoCajaSucursalesState {
  final List<DetArqueoCajaSucursalesEntity> items;
  final bool cargando;
  final String? mensajeError;
  final String? mensajeExito;

  const DetArqueoCajaSucursalesState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  DetArqueoCajaSucursalesState copyWith({
    List<DetArqueoCajaSucursalesEntity>? items,
    bool? cargando,
    String? mensajeError,
    String? mensajeExito,
  }) => DetArqueoCajaSucursalesState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class DetArqueoCajaSucursalesNotifier
    extends StateNotifier<DetArqueoCajaSucursalesState> {
  final DetArqueoCajaSucursalesImpl _repo;

  DetArqueoCajaSucursalesNotifier(this._repo)
    : super(const DetArqueoCajaSucursalesState()) {
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

  Future<bool> guardar(DetArqueoCajaSucursalesEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      state = state.copyWith(
        cargando: false,
        mensajeExito: item.idDetAS == 0
            ? 'Detalle de arqueo de caja de sucursales agregado.'
            : 'Detalle de arqueo de caja de sucursales actualizado.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<bool> eliminar(int idDetAS, int audUsuario) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.eliminar(idDetAS, audUsuario);
      state = state.copyWith(
        cargando: false,
        mensajeExito: 'Detalle de arqueo de caja de sucursales eliminado.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _detArqueoCajaSucursalesRepoProvider = Provider(
  (ref) => DetArqueoCajaSucursalesImpl(),
);

final detArqueoCajaSucursalesProvider = StateNotifierProvider.autoDispose<
  DetArqueoCajaSucursalesNotifier,
  DetArqueoCajaSucursalesState
>((ref) => DetArqueoCajaSucursalesNotifier(
  ref.read(_detArqueoCajaSucursalesRepoProvider),
));
