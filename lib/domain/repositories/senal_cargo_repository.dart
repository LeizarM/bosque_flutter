// Destino final: lib/domain/repositories/senal_cargo_repository.dart
import 'package:bosque_flutter/domain/entities/senal_cargo_entity.dart';

/// Cargos por revisar (archivo SQL 82). Las reglas son del servidor: si no
/// acepta algo, lanza su mensaje tal cual.
abstract class SenalCargoRepository {
  /// Toda la empresa (pantalla de RRHH).
  Future<List<SenalCargo>> lista({bool verCalladas = false});

  /// Las del equipo de quien mira (Mi equipo).
  Future<List<SenalCargo>> deMiEquipo();

  /// Devuelve el mensaje del servidor (hasta cuándo queda callada).
  Future<String> estaBien(SenalCargo senal, {String? obs});

  Future<String> volverAMostrar(SenalCargo senal);
}
