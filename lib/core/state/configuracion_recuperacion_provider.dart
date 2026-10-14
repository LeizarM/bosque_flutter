import 'package:bosque_flutter/data/repositories/configuracion_recuperacion_impl.dart';
import 'package:bosque_flutter/domain/entities/configuracion_recuperacion_entity.dart';
import 'package:bosque_flutter/domain/repositories/configuracion_recuperacion_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Perezoso y sin override en main.dart; las pruebas lo cambian con overrideWithValue.
final configuracionRecuperacionRepositoryProvider =
    Provider<ConfiguracionRecuperacionRepository>(
      (ref) => ConfiguracionRecuperacionImpl(),
    );

/// Los parámetros en el orden de la pantalla. Se relee al entrar y después de cada guardado.
final configuracionRecuperacionProvider =
    FutureProvider.autoDispose<List<ConfiguracionRecuperacionEntity>>(
      (ref) => ref.watch(configuracionRecuperacionRepositoryProvider).listar(),
    );
