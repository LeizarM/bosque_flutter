// Destino final: lib/domain/repositories/suc_x_mov_caja_repository.dart
import 'package:bosque_flutter/domain/entities/suc_x_mov_caja_entity.dart';

abstract class SucXMovCajaRepository {
  Future<List<SucXMovCajaEntity>> obtener();
  Future<BigInt> registrar(SucXMovCajaEntity item);
  Future<void> eliminar(int idSxMC, int audUsuario);
}
