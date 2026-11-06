import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/data/repositories/hex_planilla_impl.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_anexo_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_previa_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_planilla_repository.dart';

/// Repositorio de la planilla. Las pruebas lo cambian con `overrideWithValue`.
final hexPlanillaRepositoryProvider = Provider<HexPlanillaRepository>(
  (ref) => HexPlanillaImpl(),
);

/// Planillas ejecutadas, anuladas incluidas.
final hexPlanillasProvider =
    FutureProvider.autoDispose<List<HexPlanillaEntity>>(
      (ref) => ref.watch(hexPlanillaRepositoryProvider).planillas(),
    );

/// Combinaciones con reportes aprobados que aún no tienen planilla.
final hexPendientesProvider =
    FutureProvider.autoDispose<List<HexPendienteEntity>>(
      (ref) => ref.watch(hexPlanillaRepositoryProvider).pendientes(),
    );

final hexVistaPreviaProvider = FutureProvider.autoDispose
    .family<List<HexPrevistaEmpleadoEntity>, CombinacionHex>(
      (ref, c) => ref.watch(hexPlanillaRepositoryProvider).vistaPrevia(c),
    );

final hexVistaPreviaLineasProvider = FutureProvider.autoDispose
    .family<List<HexPrevistaLineaEntity>, CombinacionHex>(
      (ref, c) => ref.watch(hexPlanillaRepositoryProvider).vistaPreviaLineas(c),
    );

final hexAvisosProvider = FutureProvider.autoDispose
    .family<List<HexAvisoEntity>, CombinacionHex>(
      (ref, c) => ref.watch(hexPlanillaRepositoryProvider).avisos(c),
    );

/// Resumen por empleado de una planilla ya ejecutada (lo congelado).
final hexResumenPlanillaProvider = FutureProvider.autoDispose
    .family<List<HexPlanillaEmpleadoEntity>, BigInt>(
      (ref, id) => ref.watch(hexPlanillaRepositoryProvider).empleados(id),
    );

/// D39: lo que falta firmar de una combinación o del lote del mes.
final hexPendientesFirmaProvider = FutureProvider.autoDispose
    .family<List<HexPlanillaFirmaEntity>, CombinacionHex>(
      (ref, c) => ref.watch(hexPlanillaRepositoryProvider).pendientesFirma(c),
    );

/// Anexo con una fila por reporte y el origen de cada hora.
final hexAnexoPlanillaProvider = FutureProvider.autoDispose
    .family<List<HexPlanillaDetalleEntity>, BigInt>(
      (ref, id) => ref.watch(hexPlanillaRepositoryProvider).detalle(id),
    );

/// Leyenda de códigos tal como quedó congelada al ejecutar la planilla.
final hexLeyendaPlanillaProvider = FutureProvider.autoDispose
    .family<List<HexCodigoLeyendaEntity>, BigInt>(
      (ref, id) => ref.watch(hexPlanillaRepositoryProvider).leyenda(id),
    );
