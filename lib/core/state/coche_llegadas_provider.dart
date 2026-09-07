// Destino final: lib/core/state/coche_llegadas_provider.dart
import 'package:bosque_flutter/data/repositories/coche_llegadas_impl.dart';
import 'package:bosque_flutter/domain/entities/coche_llegadas_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CocheLlegadasState {
  final List<CocheLlegadasEntity> items;
  final bool cargando;
  final String? mensajeError;
  final String? mensajeExito;

  const CocheLlegadasState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  CocheLlegadasState copyWith({
    List<CocheLlegadasEntity>? items,
    bool? cargando,
    String? mensajeError,
    String? mensajeExito,
  }) => CocheLlegadasState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

class CocheLlegadasNotifier extends StateNotifier<CocheLlegadasState> {
  final CocheLlegadasImpl _repo;

  CocheLlegadasNotifier(this._repo) : super(const CocheLlegadasState()) {
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

  Future<bool> guardar(CocheLlegadasEntity item) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.registrar(item);
      state = state.copyWith(
        cargando: false,
        mensajeExito: item.idCo == 0
            ? 'Llegada de coche agregada.'
            : 'Llegada de coche actualizada.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<bool> eliminar(int idCo, int audUsuario) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.eliminar(idCo, audUsuario);
      state = state.copyWith(
        cargando: false,
        mensajeExito: 'Llegada de coche eliminada.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _cocheLlegadasRepoProvider = Provider((ref) => CocheLlegadasImpl());

final cocheLlegadasProvider = StateNotifierProvider.autoDispose<
  CocheLlegadasNotifier,
  CocheLlegadasState
>((ref) => CocheLlegadasNotifier(ref.read(_cocheLlegadasRepoProvider)));
