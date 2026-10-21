import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/catalogo_parametros_provider.dart';
import 'package:bosque_flutter/data/repositories/cuenta_impl.dart';
import 'package:bosque_flutter/domain/repositories/cuenta_repository.dart';

/// La cuenta del propio usuario. Perezoso y tipado contra la interfaz.
final cuentaRepositoryProvider = Provider<CuentaRepository>(
  (ref) => CuentaImpl(),
);

/// El cambio de contraseña en curso y el último rechazo del servidor.
final operacionCambioClaveProvider = StateNotifierProvider.autoDispose<
  OperacionesCatalogoNotifier,
  EstadoOperacionCatalogo
>((ref) => OperacionesCatalogoNotifier(() {}));
