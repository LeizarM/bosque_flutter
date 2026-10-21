import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/catalogo_parametros_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart'
    show nivelesJerarquicosProvider;
import 'package:bosque_flutter/data/repositories/nivel_jerarquico_impl.dart';
import 'package:bosque_flutter/domain/entities/nivel_jerarquico_entity.dart';
import 'package:bosque_flutter/domain/repositories/nivel_jerarquico_repository.dart';

/// Escalas de niveles jerárquicos (tb_nivelJerarquico, vista 15). Tipado
/// contra la interfaz para que una prueba lo cambie con `overrideWithValue`.
final nivelJerarquicoRepoProvider = Provider<NivelJerarquicoRepository>(
  (ref) => NivelJerarquicoImpl(),
);

/// Todas las escalas; la pantalla filtra por vigencia sin volver a pedir.
final listaEscalasProvider =
    FutureProvider.autoDispose<List<NivelJerarquicoEntity>>(
      (ref) => ref.watch(nivelJerarquicoRepoProvider).listarEscalas(),
    );

/// El filtro «Buscar por estado» del legacy.
enum FiltroVigencia { vigentes, anteriores, todas }

final filtroVigenciaProvider = StateProvider.autoDispose<FiltroVigencia>(
  (ref) => FiltroVigencia.vigentes,
);

/// Alta, nueva vigencia, edición y baja. Al salir bien refresca la lista y el
/// combo de niveles de la pantalla de cargos.
final operacionesNivelJerarquicoProvider = StateNotifierProvider<
  OperacionesCatalogoNotifier,
  EstadoOperacionCatalogo
>(
  (ref) => OperacionesCatalogoNotifier(() {
    ref.invalidate(listaEscalasProvider);
    ref.invalidate(nivelesJerarquicosProvider);
  }),
);
