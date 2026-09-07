// Destino final: lib/domain/repositories/arqueo_caja_sucursales_repository.dart
import 'package:bosque_flutter/domain/entities/arqueo_caja_sucursales_entity.dart';

abstract class ArqueoCajaSucursalesRepository {
  Future<List<ArqueoCajaSucursalesEntity>> obtener();
  Future<BigInt> registrar(ArqueoCajaSucursalesEntity item);
  Future<void> eliminar(int idAC, int audUsuario);
}
