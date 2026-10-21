import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/catalogo_parametros_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart'
    show empresasProvider;
import 'package:bosque_flutter/data/repositories/empresas_sucursales_impl.dart';
import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:bosque_flutter/domain/repositories/empresas_sucursales_repository.dart';

/// ABM de empresas y sucursales (vista 12). Tipado contra la interfaz para
/// que una prueba lo cambie con `overrideWithValue`.
final empresasSucursalesRepositoryProvider =
    Provider<EmpresasSucursalesRepository>((ref) => EmpresasSucursalesImpl());

final listaEmpresasProvider = FutureProvider.autoDispose<List<EmpresaEntity>>(
  (ref) => ref.watch(empresasSucursalesRepositoryProvider).listarEmpresas(),
);

/// Son decenas: se piden todas y la pantalla filtra por empresa.
final listaSucursalesProvider =
    FutureProvider.autoDispose<List<SucursalEntity>>(
      (ref) =>
          ref.watch(empresasSucursalesRepositoryProvider).listarSucursales(),
    );

final ciudadesParaSucursalProvider =
    FutureProvider.autoDispose<List<CiudadEntity>>(
      (ref) => ref.watch(empresasSucursalesRepositoryProvider).ciudades(),
    );

enum NivelEstructura { empresas, sucursales }

final nivelEstructuraProvider = StateProvider.autoDispose<NivelEstructura>(
  (ref) => NivelEstructura.empresas,
);

/// Empresa elegida en el nivel de sucursales (null = todas).
final empresaElegidaProvider = StateProvider.autoDispose<int?>((ref) => null);

/// Al salir bien refresca las dos listas y la de la pantalla de estructura.
final operacionesEmpresasSucursalesProvider = StateNotifierProvider<
  OperacionesCatalogoNotifier,
  EstadoOperacionCatalogo
>(
  (ref) => OperacionesCatalogoNotifier(() {
    ref.invalidate(listaEmpresasProvider);
    ref.invalidate(listaSucursalesProvider);
    ref.invalidate(empresasProvider);
  }),
);
