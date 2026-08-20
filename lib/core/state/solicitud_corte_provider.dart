/// Estado de la pantalla "Solicitud de corte".
///
/// El periodo por defecto es el anio en curso y no el mes, a diferencia de las
/// otras dos pantallas del modulo: se generan pocas solicitudes —unas decenas
/// por anio— y con un mes la pantalla abriria casi siempre vacia.
library;

import 'package:bosque_flutter/data/repositories/solicitud_corte_impl.dart';
import 'package:bosque_flutter/domain/entities/ccr_solicitud_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/ccr_solicitud_entity.dart';
import 'package:bosque_flutter/domain/repositories/solicitud_corte_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final solicitudCorteRepositoryProvider = Provider<SolicitudCorteRepository>(
  (ref) => SolicitudCorteImpl(),
);

/// Cuantos items tiene el catalogo SAP.
///
/// Solo para poder decir "entre 1.522 items" en el buscador. El catalogo en si
/// ya no se descarga: la busqueda la resuelve el servidor.
final totalItemsSapProvider = FutureProvider<int>(
  (ref) => ref.watch(solicitudCorteRepositoryProvider).totalItemsSap(),
);

// ═══════════════════════════════════════════════════════════════════════════
// LISTADO
// ═══════════════════════════════════════════════════════════════════════════

class SolicitudesCorteState {
  final List<CcrSolicitudEntity> solicitudes;
  final bool cargando;
  final String? error;

  /// Texto libre: numero, solicitante u observacion.
  final String busqueda;

  /// null = todos los estados.
  final String? estado;

  final DateTime desde;
  final DateTime hasta;

  SolicitudesCorteState({
    this.solicitudes = const [],
    this.cargando = false,
    this.error,
    this.busqueda = '',
    this.estado,
    DateTime? desde,
    DateTime? hasta,
  }) : desde = desde ?? rangoPorDefecto().desde,
       hasta = hasta ?? rangoPorDefecto().hasta;

  /// Del primer dia del anio en curso hasta hoy.
  static ({DateTime desde, DateTime hasta}) rangoPorDefecto() {
    final hoy = DateTime.now();
    return (desde: DateTime(hoy.year, 1, 1), hasta: hoy);
  }

  List<CcrSolicitudEntity> get visibles {
    final texto = busqueda.trim().toLowerCase();
    return solicitudes.where((s) {
      if (estado != null && s.estado != estado) return false;
      if (texto.isEmpty) return true;
      return s.datoNroSolicitud.toLowerCase().contains(texto) ||
          s.numeracion.toString().contains(texto) ||
          s.datoSolicitante.toLowerCase().contains(texto) ||
          s.observacion.toLowerCase().contains(texto);
    }).toList();
  }

  /// Los kilos pedidos en el periodo, sin contar las canceladas.
  double get totalPeriodo => solicitudes
      .where((s) => !s.estaCancelada)
      .fold(0.0, (t, s) => t + s.totalToneladas);

  int get canceladas => solicitudes.where((s) => s.estaCancelada).length;

  SolicitudesCorteState copyWith({
    List<CcrSolicitudEntity>? solicitudes,
    bool? cargando,
    String? error,
    bool limpiarError = false,
    String? busqueda,
    String? estado,
    bool todosLosEstados = false,
    DateTime? desde,
    DateTime? hasta,
  }) => SolicitudesCorteState(
    solicitudes: solicitudes ?? this.solicitudes,
    cargando: cargando ?? this.cargando,
    error: limpiarError ? null : (error ?? this.error),
    busqueda: busqueda ?? this.busqueda,
    estado: todosLosEstados ? null : (estado ?? this.estado),
    desde: desde ?? this.desde,
    hasta: hasta ?? this.hasta,
  );
}

class SolicitudesCorteNotifier extends StateNotifier<SolicitudesCorteState> {
  SolicitudesCorteNotifier(this._repo) : super(SolicitudesCorteState()) {
    cargar();
  }

  final SolicitudCorteRepository _repo;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, limpiarError: true);
    try {
      final lista = await _repo.obtenerSolicitudes(state.desde, state.hasta);
      state = state.copyWith(solicitudes: lista, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  void setBusqueda(String valor) => state = state.copyWith(busqueda: valor);

  void setEstado(String? valor) => state = valor == null
      ? state.copyWith(todosLosEstados: true)
      : state.copyWith(estado: valor);

  /// Cambiar el rango vuelve a consultar: el recorte lo hace el SP.
  Future<void> setRango(DateTime desde, DateTime hasta) async {
    state = state.copyWith(desde: desde, hasta: hasta);
    await cargar();
  }
}

final solicitudesCorteProvider = StateNotifierProvider.autoDispose<
  SolicitudesCorteNotifier,
  SolicitudesCorteState
>((ref) => SolicitudesCorteNotifier(ref.watch(solicitudCorteRepositoryProvider)));

// ═══════════════════════════════════════════════════════════════════════════
// DETALLE
// ═══════════════════════════════════════════════════════════════════════════

/// Los items de una solicitud. Es solo lectura, asi que alcanza un FutureProvider.
final detalleSolicitudCorteProvider = FutureProvider.autoDispose
    .family<List<CcrSolicitudDetalleEntity>, int>(
      (ref, idSolicitud) => ref
          .watch(solicitudCorteRepositoryProvider)
          .obtenerDetalle(idSolicitud),
    );
