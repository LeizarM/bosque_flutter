// Destino final: lib/core/state/control_cierre_provider.dart
import 'package:bosque_flutter/core/state/cierre_operaciones_provider.dart';
import 'package:bosque_flutter/core/state/verificar_cierre_provider.dart';
import 'package:bosque_flutter/domain/entities/firma_cierre_entity.dart';
import 'package:bosque_flutter/domain/repositories/firma_cierre_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Un día del tablero, con sus celdas.
class DiaDelTablero {
  final DateTime fechaTarea;
  final List<CeldaTablero> celdas;

  const DiaDelTablero(this.fechaTarea, this.celdas);
}

/// El tablero de Verificar Cierre (archivo SQL 81). Solo trae las celdas de
/// quien mira; el completo, solo si la matriz le asigna todas. El estado de
/// cada celda y el resumen por persona los calcula el servidor.
class ControlCierreState {
  /// Cuántos días hacia atrás: 7, 30 o 90.
  final int dias;
  final PanelDatos<ResumenCierrePersona> resumen;
  final PanelDatos<CeldaTablero> celdas;

  const ControlCierreState({
    this.dias = 7,
    this.resumen = const PanelDatos<ResumenCierrePersona>(cargando: true),
    this.celdas = const PanelDatos<CeldaTablero>(cargando: true),
  });

  /// Del día más nuevo al más viejo.
  List<DiaDelTablero> get porDia {
    final mapa = <DateTime, List<CeldaTablero>>{};
    for (final c in celdas.filas) {
      mapa.putIfAbsent(c.fechaTarea, () => []).add(c);
    }
    final fechas = mapa.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final f in fechas) DiaDelTablero(f, mapa[f]!)];
  }

  int cuantas(EstadoCelda e) => celdas.filas.where((c) => c.estado == e).length;

  ControlCierreState copyWith({
    int? dias,
    PanelDatos<ResumenCierrePersona>? resumen,
    PanelDatos<CeldaTablero>? celdas,
  }) => ControlCierreState(
    dias: dias ?? this.dias,
    resumen: resumen ?? this.resumen,
    celdas: celdas ?? this.celdas,
  );
}

class ControlCierreNotifier extends StateNotifier<ControlCierreState> {
  final FirmaCierreRepository _repo;

  /// Hoy, inyectable para las pruebas.
  final DateTime Function() _hoy;

  ControlCierreNotifier(this._repo, {DateTime Function()? hoy})
    : _hoy = hoy ?? DateTime.now,
      super(const ControlCierreState()) {
    Future.microtask(cargar);
  }

  Future<void> cambiarDias(int dias) async {
    if (dias == state.dias) return;
    state = state.copyWith(dias: dias);
    await cargar();
  }

  Future<void> cargar() async {
    final dias = state.dias;
    final ahora = _hoy();
    final hasta = DateTime(ahora.year, ahora.month, ahora.day);
    final desde = hasta.subtract(Duration(days: dias - 1));
    state = state.copyWith(
      resumen: state.resumen.leyendo(limpiar: false),
      celdas: state.celdas.leyendo(limpiar: false),
    );
    // Una respuesta de otro rango que llega tarde se descarta.
    bool vigente() => mounted && state.dias == dias;
    await Future.wait([
      () async {
        try {
          final filas = await _repo.resumen(desde: desde, hasta: hasta);
          if (vigente()) {
            state = state.copyWith(
              resumen: PanelDatos(filas: filas, cargado: true),
            );
          }
        } catch (e) {
          if (vigente()) state = state.copyWith(resumen: PanelDatos(error: e));
        }
      }(),
      () async {
        try {
          final filas = await _repo.tablero(desde: desde, hasta: hasta);
          if (vigente()) {
            state = state.copyWith(
              celdas: PanelDatos(filas: filas, cargado: true),
            );
          }
        } catch (e) {
          if (vigente()) state = state.copyWith(celdas: PanelDatos(error: e));
        }
      }(),
    ]);
  }
}

final controlCierreProvider = StateNotifierProvider.autoDispose<
  ControlCierreNotifier,
  ControlCierreState
>((ref) => ControlCierreNotifier(ref.read(firmaCierreRepoProvider)));
