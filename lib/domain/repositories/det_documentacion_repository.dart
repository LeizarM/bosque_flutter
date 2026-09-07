// Destino final: lib/domain/repositories/det_documentacion_repository.dart
import 'package:bosque_flutter/domain/entities/det_documentacion_entity.dart';

abstract class DetDocumentacionRepository {
  Future<List<DetDocumentacionEntity>> obtener();
  Future<BigInt> registrar(DetDocumentacionEntity item);
  Future<void> eliminar(int idDetDoc, int audUsuario);
}
