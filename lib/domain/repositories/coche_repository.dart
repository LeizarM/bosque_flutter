// Destino final: lib/domain/repositories/coche_repository.dart
import 'package:bosque_flutter/domain/entities/coche_entity.dart';

abstract class CocheRepository {
  Future<List<CocheEntity>> obtener();
  Future<BigInt> registrar(CocheEntity item);
  Future<void> eliminar(int idCoche, int audUsuario);
}
