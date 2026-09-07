// Destino final: lib/domain/repositories/traspaso_mov_caja_repository.dart
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';

abstract class TraspasoMovCajaRepository {
  Future<List<TraspasoMovCajaEntity>> obtener();
  Future<BigInt> registrar(TraspasoMovCajaEntity item);
  Future<void> eliminar(int idTrasp, int audUsuario);
}
