// Destino final: lib/domain/repositories/caja_chica_repository.dart
import 'package:bosque_flutter/domain/entities/caja_chica_entity.dart';

abstract class CajaChicaRepository {
  Future<List<CajaChicaEntity>> obtener();
  Future<BigInt> registrar(CajaChicaEntity item);
  Future<void> eliminar(int idCC, int audUsuario);
}
