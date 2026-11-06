import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/data/repositories/hex_asignacion_impl.dart';
import 'package:bosque_flutter/domain/entities/hex_asignable_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_asignacion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_asignacion_falta_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_asignacion_repository.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';

/// Repositorio de asignaciones. Las pruebas lo cambian con `overrideWithValue`.
final hexAsignacionRepositoryProvider = Provider<HexAsignacionRepository>(
  (ref) => HexAsignacionImpl(),
);

/// A quién puede asignar el actor en una jornada (el día, sin la hora).
final hexAsignablesProvider = FutureProvider.autoDispose
    .family<List<HexAsignableEntity>, DateTime>(
      (ref, dia) => ref.watch(hexAsignacionRepositoryProvider).asignables(dia),
    );

final hexHistorialAsignacionProvider = FutureProvider.autoDispose
    .family<PaginaHex<HexAsignacionEntity>, FiltroAsignacionesHex>(
      (ref, f) => ref.watch(hexAsignacionRepositoryProvider).historial(f),
    );

/// Adenda D37: faltas de lo que asignó el actor, con el rango por defecto del
/// SP; el aviso de la bandeja de revisión.
final hexFaltasAsignacionProvider =
    FutureProvider.autoDispose<List<HexAsignacionFaltaEntity>>(
      (ref) => ref.watch(hexAsignacionRepositoryProvider).faltas(),
    );
