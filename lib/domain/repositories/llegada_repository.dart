// Destino final: lib/domain/repositories/llegada_repository.dart
import 'package:bosque_flutter/domain/entities/llegada_entity.dart';

abstract class LlegadaRepository {
  Future<List<LlegadaEntity>> obtener();
  Future<BigInt> registrar(LlegadaEntity item);
  Future<void> eliminar(int idRp, int audUsuario);
}
