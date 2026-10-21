import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/catalogo_parametros_provider.dart';
import 'package:bosque_flutter/data/repositories/funciones_modulo_impl.dart';
import 'package:bosque_flutter/domain/entities/asignacion_funcion_entity.dart';
import 'package:bosque_flutter/domain/entities/funcion_modulo_entity.dart';
import 'package:bosque_flutter/domain/entities/opcion_entity.dart';
import 'package:bosque_flutter/domain/repositories/funciones_modulo_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
// FUNCIONES POR MÓDULO (vista 57)
// ═══════════════════════════════════════════════════════════════════════════

final funcionesModuloRepositoryProvider = Provider<FuncionesModuloRepository>(
  (ref) => FuncionesModuloImpl(),
);

final listaFuncionesModuloProvider =
    FutureProvider.autoDispose<List<FuncionModuloEntity>>(
      (ref) => ref.watch(funcionesModuloRepositoryProvider).listar(),
    );

/// Los módulos que pueden tener funciones; los decide el SP ('M').
final modulosFuncionesProvider = FutureProvider.autoDispose<List<OpcionEntity>>(
  (ref) => ref.watch(funcionesModuloRepositoryProvider).modulos(),
);

/// Módulo elegido en la pantalla (null = todos).
final moduloElegidoProvider = StateProvider.autoDispose<int?>((ref) => null);

final operacionesFuncionesModuloProvider = StateNotifierProvider<
  OperacionesCatalogoNotifier,
  EstadoOperacionCatalogo
>(
  (ref) => OperacionesCatalogoNotifier(
    () => ref.invalidate(listaFuncionesModuloProvider),
  ),
);

// ═══════════════════════════════════════════════════════════════════════════
// ASIGNACIÓN DE FUNCIONES (vista 56)
// ═══════════════════════════════════════════════════════════════════════════

final asignacionFuncionesRepositoryProvider =
    Provider<AsignacionFuncionesRepository>((ref) => AsignacionFuncionesImpl());

/// Son decenas: se piden todas y la pantalla filtra.
final listaAsignacionesProvider =
    FutureProvider.autoDispose<List<AsignacionFuncionEntity>>(
      (ref) => ref.watch(asignacionFuncionesRepositoryProvider).listar(),
    );

final funcionesParaAsignarProvider =
    FutureProvider.autoDispose<List<FuncionModuloEntity>>(
      (ref) => ref.watch(asignacionFuncionesRepositoryProvider).funciones(),
    );

final sucursalesParaAsignarProvider =
    FutureProvider.autoDispose<List<OpcionEntity>>(
      (ref) => ref.watch(asignacionFuncionesRepositoryProvider).sucursales(),
    );

/// Empleados con relación vigente de una sucursal, para el alta.
final empleadosDeSucursalProvider = FutureProvider.autoDispose
    .family<List<OpcionEntity>, int>(
      (ref, codSucursal) => ref
          .watch(asignacionFuncionesRepositoryProvider)
          .empleados(codSucursal),
    );

/// Filtros de la pantalla: módulo, función, sucursal y estado.
class FiltroAsignaciones {
  const FiltroAsignaciones({
    this.codModulo,
    this.codFuncMod,
    this.codSucursal,
    this.activas = true,
  });

  final int? codModulo;
  final int? codFuncMod;
  final int? codSucursal;

  /// true activas, false inactivas, null todas.
  final bool? activas;

  bool deja(AsignacionFuncionEntity a) =>
      (codModulo == null || a.codModulo == codModulo) &&
      (codFuncMod == null || a.codFuncMod == codFuncMod) &&
      (codSucursal == null || a.codSucursal == codSucursal) &&
      (activas == null || a.activo == activas);
}

final filtroAsignacionesProvider =
    StateProvider.autoDispose<FiltroAsignaciones>(
      (ref) => const FiltroAsignaciones(),
    );

final operacionesAsignacionProvider = StateNotifierProvider<
  OperacionesCatalogoNotifier,
  EstadoOperacionCatalogo
>(
  (ref) => OperacionesCatalogoNotifier(
    () => ref.invalidate(listaAsignacionesProvider),
  ),
);
