// Destino final: lib/domain/repositories/corte_repository.dart
import 'package:bosque_flutter/domain/entities/corte_entity.dart';

abstract class CorteRepository {
  Future<List<CorteEntity>> obtener();
  Future<BigInt> registrar(CorteEntity item);
  Future<void> eliminar(int idCorte, int audUsuario);
}
