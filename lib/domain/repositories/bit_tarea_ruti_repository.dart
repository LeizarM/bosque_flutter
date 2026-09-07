// Destino final: lib/domain/repositories/bit_tarea_ruti_repository.dart
import 'package:bosque_flutter/domain/entities/bit_tarea_ruti_entity.dart';

abstract class BitTareaRutiRepository {
  Future<List<BitTareaRutiEntity>> obtener();
  Future<BigInt> registrar(BitTareaRutiEntity item);
  Future<void> eliminar(int idBitTarea, int audUsuario);
}
