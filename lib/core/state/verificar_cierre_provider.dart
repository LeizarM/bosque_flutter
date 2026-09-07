// Destino final: lib/core/state/verificar_cierre_provider.dart
import 'package:bosque_flutter/data/repositories/verificar_cierre_impl.dart';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerificarCierreState {
  final List<Map<String, dynamic>> arqueos;
  final List<Map<String, dynamic>> llegadas;
  final List<TraspasoMovCajaEntity> traspasos;
  final bool todasSucursales;
  final bool cargando;
  final int? guardandoIdAC;
  final int? guardandoIdRp;
  final bool confirmando;
  final String? mensajeError;
  final int? ocurrenciasCerradas;

  const VerificarCierreState({
    this.arqueos = const [],
    this.llegadas = const [],
    this.traspasos = const [],
    this.todasSucursales = false,
    this.cargando = false,
    this.guardandoIdAC,
    this.guardandoIdRp,
    this.confirmando = false,
    this.mensajeError,
    this.ocurrenciasCerradas,
  });

  VerificarCierreState copyWith({
    List<Map<String, dynamic>>? arqueos,
    List<Map<String, dynamic>>? llegadas,
    List<TraspasoMovCajaEntity>? traspasos,
    bool? todasSucursales,
    bool? cargando,
    int? guardandoIdAC,
    bool limpiarGuardandoAC = false,
    int? guardandoIdRp,
    bool limpiarGuardandoRp = false,
    bool? confirmando,
    String? mensajeError,
    int? ocurrenciasCerradas,
  }) => VerificarCierreState(
    arqueos: arqueos ?? this.arqueos,
    llegadas: llegadas ?? this.llegadas,
    traspasos: traspasos ?? this.traspasos,
    todasSucursales: todasSucursales ?? this.todasSucursales,
    cargando: cargando ?? this.cargando,
    guardandoIdAC: limpiarGuardandoAC ? null : (guardandoIdAC ?? this.guardandoIdAC),
    guardandoIdRp: limpiarGuardandoRp ? null : (guardandoIdRp ?? this.guardandoIdRp),
    confirmando: confirmando ?? this.confirmando,
    mensajeError: mensajeError,
    ocurrenciasCerradas: ocurrenciasCerradas,
  );
}

/// Family por idBitTarea: los paneles enriquecidos ('B') resuelven la
/// sucursal del supervisor server-side desde esta ocurrencia puntual, así
/// que el notifier necesita saberlo desde que arranca (antes no hacía
/// falta — el listado genérico no dependía de quién preguntaba).
class VerificarCierreNotifier extends StateNotifier<VerificarCierreState> {
  final VerificarCierreImpl _repo;
  final int idBitTarea;

  VerificarCierreNotifier(this._repo, this.idBitTarea) : super(const VerificarCierreState()) {
    Future.microtask(() => cargar());
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true);
    try {
      final arqueos = await _repo.obtenerArqueosDeHoy(idBitTarea, todasSucursales: state.todasSucursales);
      final llegadas = await _repo.obtenerLlegadasDeHoy(idBitTarea, todasSucursales: state.todasSucursales);
      final traspasos = await _repo.obtenerTraspasosDeHoy();
      state = state.copyWith(cargando: false, arqueos: arqueos, llegadas: llegadas, traspasos: traspasos);
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
    }
  }

  /// El checkbox real "Mostrar otras sucursales" del legacy (gated por
  /// chkSuc) — recarga ambos paneles con el alcance elegido.
  Future<void> alternarTodasSucursales(bool valor) async {
    state = state.copyWith(todasSucursales: valor);
    await cargar();
  }

  Future<void> marcarArqueoRevisado(int idAC) async {
    state = state.copyWith(guardandoIdAC: idAC);
    try {
      await _repo.marcarArqueoRevisado(idAC);
      final nuevos = state.arqueos.map((a) {
        if ((a['idAC'] as num?)?.toInt() != idAC) return a;
        return {...a, 'fueRevisado': 1};
      }).toList();
      state = state.copyWith(arqueos: nuevos, limpiarGuardandoAC: true);
    } catch (e) {
      state = state.copyWith(limpiarGuardandoAC: true, mensajeError: e.toString());
    }
  }

  Future<void> marcarLlegadaVerificada(int idRp, int fueVerificado) async {
    state = state.copyWith(guardandoIdRp: idRp);
    try {
      await _repo.marcarLlegadaVerificada(idRp, fueVerificado);
      final nuevos = state.llegadas.map((l) {
        if ((l['idRp'] as num?)?.toInt() != idRp) return l;
        return {...l, 'fueVerificado': fueVerificado};
      }).toList();
      state = state.copyWith(llegadas: nuevos, limpiarGuardandoRp: true);
    } catch (e) {
      state = state.copyWith(limpiarGuardandoRp: true, mensajeError: e.toString());
    }
  }

  Future<void> confirmar() async {
    state = state.copyWith(confirmando: true);
    try {
      final cantidad = await _repo.confirmar(idBitTarea);
      state = state.copyWith(confirmando: false, ocurrenciasCerradas: cantidad);
    } catch (e) {
      state = state.copyWith(confirmando: false, mensajeError: e.toString());
    }
  }
}

final _verificarCierreRepoProvider = Provider((ref) => VerificarCierreImpl());

final verificarCierreProvider = StateNotifierProvider.autoDispose
    .family<VerificarCierreNotifier, VerificarCierreState, int>((ref, idBitTarea) {
  return VerificarCierreNotifier(ref.read(_verificarCierreRepoProvider), idBitTarea);
});
