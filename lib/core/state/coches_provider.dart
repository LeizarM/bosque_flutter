// Destino final: lib/core/state/coches_provider.dart
import 'package:bosque_flutter/data/repositories/coches_impl.dart';
import 'package:bosque_flutter/domain/entities/coche_del_dia_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Parámetros de la ocurrencia puntual que identifican qué lista de coches
/// cargar. codSucursal ya NO viaja acá — el proc lo resuelve server-side
/// del cargo vigente del empleado dueño de la ocurrencia, no del login del
/// cliente (un empleado puede tener cargos en más de una sucursal — code-
/// review, 2026-09-03).
typedef CochesParams = ({int idTarRuti, int idBitTarea});

class CochesState {
  final List<CocheDelDiaEntity> items;
  final bool cargando;
  final int? guardandoIdCo;
  final String? mensajeError;
  final bool tareaCerrada;

  const CochesState({
    this.items = const [],
    this.cargando = false,
    this.guardandoIdCo,
    this.mensajeError,
    this.tareaCerrada = false,
  });

  CochesState copyWith({
    List<CocheDelDiaEntity>? items,
    bool? cargando,
    int? guardandoIdCo,
    bool limpiarGuardando = false,
    String? mensajeError,
    bool? tareaCerrada,
  }) => CochesState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    guardandoIdCo: limpiarGuardando ? null : (guardandoIdCo ?? this.guardandoIdCo),
    mensajeError: mensajeError,
    tareaCerrada: tareaCerrada ?? this.tareaCerrada,
  );

  bool get todosMarcados => items.isNotEmpty && items.every((c) => c.yaMarcado);
}

class CochesNotifier extends StateNotifier<CochesState> {
  final CochesImpl _repo;
  final CochesParams _params;

  CochesNotifier(this._repo, this._params) : super(const CochesState()) {
    Future.microtask(() => cargar());
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true);
    try {
      final items = await _repo.listarDelDia(
        idTarRuti: _params.idTarRuti,
        idBitTarea: _params.idBitTarea,
      );
      state = state.copyWith(cargando: false, items: items);
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
    }
  }

  Future<void> marcarLlegada(int idCo, int llego, {String? obs}) async {
    state = state.copyWith(guardandoIdCo: idCo);
    try {
      final cerroLaTarea = await _repo.marcarLlegada(idCo: idCo, llego: llego, obs: obs);
      final nuevos = state.items
          .map((c) => c.idCo == idCo ? c.copyWith(llego: llego, obs: obs) : c)
          .toList();
      state = state.copyWith(
        items: nuevos,
        limpiarGuardando: true,
        tareaCerrada: cerroLaTarea,
      );
    } catch (e) {
      state = state.copyWith(limpiarGuardando: true, mensajeError: e.toString());
    }
  }
}

final _cochesRepoProvider = Provider((ref) => CochesImpl());

final cochesProvider = StateNotifierProvider.autoDispose
    .family<CochesNotifier, CochesState, CochesParams>((ref, params) {
      return CochesNotifier(ref.read(_cochesRepoProvider), params);
    });
