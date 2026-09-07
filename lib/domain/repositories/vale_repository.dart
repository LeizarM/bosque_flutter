// Destino final: lib/domain/repositories/vale_repository.dart
import 'package:bosque_flutter/domain/entities/vale_entity.dart';

abstract class ValeRepository {
  Future<List<ValeEntity>> obtener();
  Future<BigInt> registrar(ValeEntity item);
  Future<void> eliminar(int idVale, int audUsuario);
}
