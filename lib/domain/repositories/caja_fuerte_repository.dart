// Destino final: lib/domain/repositories/caja_fuerte_repository.dart
import 'package:bosque_flutter/domain/entities/llegada_caja_fuerte_entity.dart';

abstract class CajaFuerteRepository {
  /// Devuelve la cantidad de llegadas registradas (>0 filtra las de
  /// importe<=0, igual que el SP).
  Future<int> registrar({
    required int idTarRuti,
    required int idBitTarea,
    required List<LlegadaCajaFuerteEntity> llegadas,
  });
}
