import 'package:bosque_flutter/data/repositories/recuperacion_acceso_impl.dart';
import 'package:bosque_flutter/domain/repositories/recuperacion_acceso_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Perezoso y sin override en main.dart; las pruebas lo cambian con overrideWithValue.
final recuperacionAccesoRepositoryProvider =
    Provider<RecuperacionAccesoRepository>((ref) => RecuperacionAccesoImpl());
