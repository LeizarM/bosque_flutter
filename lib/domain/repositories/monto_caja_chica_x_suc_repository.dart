// Destino final: lib/domain/repositories/monto_caja_chica_x_suc_repository.dart
import 'package:bosque_flutter/domain/entities/monto_caja_chica_x_suc_entity.dart';

abstract class MontoCajaChicaXSucRepository {
  Future<List<MontoCajaChicaXSucEntity>> obtener();
  Future<BigInt> registrar(MontoCajaChicaXSucEntity item);
  Future<void> eliminar(int idCS, int audUsuario);
}
