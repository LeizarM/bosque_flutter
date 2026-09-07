// Destino final: lib/domain/repositories/frecuencia_repository.dart
import 'package:bosque_flutter/domain/entities/frecuencia_entity.dart';

abstract class FrecuenciaRepository {
  Future<List<FrecuenciaEntity>> obtener();
  Future<BigInt> registrar(FrecuenciaEntity item);
  Future<void> eliminar(int idFrec, int audUsuario);
}
