import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/catalogo_parametros_provider.dart';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart'
    show tipoTelefonoProvider;
import 'package:bosque_flutter/data/repositories/tipo_telefono_impl.dart';
import 'package:bosque_flutter/domain/entities/tipo_telefono_entity.dart';
import 'package:bosque_flutter/domain/repositories/tipo_telefono_repository.dart';

/// Tipos de teléfono (trh_tipoTelefono, vista 28). Perezoso: una prueba lo
/// cambia con `tipoTelefonoRepositoryProvider.overrideWithValue(falso)`.
final tipoTelefonoRepositoryProvider = Provider<TipoTelefonoRepository>(
  (ref) => TipoTelefonoImpl(),
);

/// La lista de la pantalla. Un fallo llega como error para ofrecer reintentar.
final listaTiposTelefonoProvider =
    FutureProvider.autoDispose<List<TipoTelefonoEntity>>(
      (ref) => ref.watch(tipoTelefonoRepositoryProvider).listar(),
    );

/// Alta, edición y baja. Al salir bien refresca la lista y el combo de la
/// ficha del trabajador (`tipoTelefonoProvider`).
final operacionesTipoTelefonoProvider = StateNotifierProvider<
  OperacionesCatalogoNotifier,
  EstadoOperacionCatalogo
>(
  (ref) => OperacionesCatalogoNotifier(() {
    ref.invalidate(listaTiposTelefonoProvider);
    ref.invalidate(tipoTelefonoProvider);
  }),
);
