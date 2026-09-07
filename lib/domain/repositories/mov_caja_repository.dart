// Destino final: lib/domain/repositories/mov_caja_repository.dart
import 'package:bosque_flutter/domain/entities/mov_caja_entity.dart';

abstract class MovCajaRepository {
  Future<List<MovCajaEntity>> obtener();
  Future<BigInt> registrar(MovCajaEntity item);
  Future<void> eliminar(int idMC, int audUsuario);
}
