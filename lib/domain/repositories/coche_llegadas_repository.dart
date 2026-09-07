// Destino final: lib/domain/repositories/coche_llegadas_repository.dart
import 'package:bosque_flutter/domain/entities/coche_llegadas_entity.dart';

abstract class CocheLlegadasRepository {
  Future<List<CocheLlegadasEntity>> obtener();
  Future<BigInt> registrar(CocheLlegadasEntity item);
  Future<void> eliminar(int idCo, int audUsuario);
}
