// Destino final: lib/domain/repositories/det_arqueo_caja_sucursales_repository.dart
import 'package:bosque_flutter/domain/entities/det_arqueo_caja_sucursales_entity.dart';

abstract class DetArqueoCajaSucursalesRepository {
  Future<List<DetArqueoCajaSucursalesEntity>> obtener();
  Future<BigInt> registrar(DetArqueoCajaSucursalesEntity item);
  Future<void> eliminar(int idDetAS, int audUsuario);
}
