import 'package:bosque_flutter/data/repositories/sesiones_impl.dart';
import 'package:bosque_flutter/domain/entities/sesion_entity.dart';
import 'package:bosque_flutter/domain/repositories/sesiones_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Perezoso y sin override en main.dart; las pruebas lo cambian con overrideWithValue.
final sesionesRepositoryProvider = Provider<SesionesRepository>((ref) => SesionesImpl());

/// Las sesiones abiertas. Se relee al entrar, con «Actualizar» y después de cerrar una.
final sesionesAbiertasProvider = FutureProvider.autoDispose<List<SesionEntity>>(
  (ref) => ref.watch(sesionesRepositoryProvider).abiertas(),
);

/// El rango del historial; arranca en hoy.
final rangoHistorialSesionesProvider = StateProvider.autoDispose<({DateTime desde, DateTime hasta})>((ref) {
  final ahora = DateTime.now();
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  return (desde: hoy, hasta: hoy);
});

final historialSesionesProvider = FutureProvider.autoDispose<List<SesionEntity>>((ref) {
  final rango = ref.watch(rangoHistorialSesionesProvider);
  return ref.watch(sesionesRepositoryProvider).historial(desde: rango.desde, hasta: rango.hasta);
});
