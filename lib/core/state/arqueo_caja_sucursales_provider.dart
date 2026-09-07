// Destino final: lib/core/state/arqueo_caja_sucursales_provider.dart
import 'package:bosque_flutter/data/repositories/arqueo_caja_sucursales_impl.dart';
import 'package:bosque_flutter/domain/entities/arqueo_caja_sucursales_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArqueoCajaSucursalesState {
  final List<ArqueoCajaSucursalesEntity> items;
  final bool cargando;
  final String? mensajeError;
  final String? mensajeExito;

  const ArqueoCajaSucursalesState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  ArqueoCajaSucursalesState copyWith({
    List<ArqueoCajaSucursalesEntity>? items,
    bool? cargando,
    String? mensajeError,
    String? mensajeExito,
  }) => ArqueoCajaSucursalesState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class ArqueoCajaSucursalesNotifier
    extends StateNotifier<ArqueoCajaSucursalesState> {
  final ArqueoCajaSucursalesImpl _repo;

  ArqueoCajaSucursalesNotifier(this._repo)
    : super(const ArqueoCajaSucursalesState()) {
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

  Future<bool> guardar(ArqueoCajaSucursalesEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      state = state.copyWith(
        cargando: false,
        mensajeExito: item.idAC == 0
            ? 'Arqueo de caja de sucursales agregado.'
            : 'Arqueo de caja de sucursales actualizado.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<bool> eliminar(int idAC, int audUsuario) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.eliminar(idAC, audUsuario);
      state = state.copyWith(
        cargando: false,
        mensajeExito: 'Arqueo de caja de sucursales eliminado.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _arqueoCajaSucursalesRepoProvider = Provider(
  (ref) => ArqueoCajaSucursalesImpl(),
);

final arqueoCajaSucursalesProvider = StateNotifierProvider.autoDispose<
  ArqueoCajaSucursalesNotifier,
  ArqueoCajaSucursalesState
>((ref) => ArqueoCajaSucursalesNotifier(ref.read(_arqueoCajaSucursalesRepoProvider)));
