import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/catalogo_parametros_provider.dart';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart'
    show ciudadProvider, paisProvider, zonaProvider;
import 'package:bosque_flutter/data/repositories/ubicacion_geografica_impl.dart';
import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/pais_entity.dart';
import 'package:bosque_flutter/domain/entities/zona_entity.dart';
import 'package:bosque_flutter/domain/repositories/ubicacion_geografica_repository.dart';

/// Ubicación geográfica (vista 26). Tipado contra la interfaz para que una
/// prueba lo cambie con `overrideWithValue`.
final ubicacionRepositoryProvider = Provider<UbicacionGeograficaRepository>(
  (ref) => UbicacionGeograficaImpl(),
);

final listaPaisesProvider = FutureProvider.autoDispose<List<PaisEntity>>(
  (ref) => ref.watch(ubicacionRepositoryProvider).listarPaises(),
);

/// Son pocas (decenas): se piden todas y la pantalla filtra por país.
final listaCiudadesProvider = FutureProvider.autoDispose<List<CiudadEntity>>(
  (ref) => ref.watch(ubicacionRepositoryProvider).listarCiudades(),
);

/// Unas cien: se piden todas y la pantalla filtra por ciudad.
final listaZonasProvider = FutureProvider.autoDispose<List<ZonaEntity>>(
  (ref) => ref.watch(ubicacionRepositoryProvider).listarZonas(),
);

/// Qué nivel se está viendo.
enum NivelUbicacion { paises, ciudades, zonas }

final nivelUbicacionProvider = StateProvider.autoDispose<NivelUbicacion>(
  (ref) => NivelUbicacion.paises,
);

/// País elegido en el nivel de ciudades (null = todos).
final paisElegidoProvider = StateProvider.autoDispose<int?>((ref) => null);

/// Ciudad elegida en el nivel de zonas (null = todas).
final ciudadElegidaProvider = StateProvider.autoDispose<int?>((ref) => null);

/// Altas, ediciones y bajas de los tres niveles. Al salir bien refresca las
/// tres listas y los combos de la ficha del trabajador.
final operacionesUbicacionProvider = StateNotifierProvider<
  OperacionesCatalogoNotifier,
  EstadoOperacionCatalogo
>(
  (ref) => OperacionesCatalogoNotifier(() {
    ref.invalidate(listaPaisesProvider);
    ref.invalidate(listaCiudadesProvider);
    ref.invalidate(listaZonasProvider);
    ref.invalidate(paisProvider);
    ref.invalidate(ciudadProvider);
    ref.invalidate(zonaProvider);
  }),
);
