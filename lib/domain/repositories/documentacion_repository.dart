// Destino final: lib/domain/repositories/documentacion_repository.dart
import 'package:bosque_flutter/domain/entities/documentacion_entity.dart';

abstract class DocumentacionRepository {
  Future<List<DocumentacionEntity>> obtener();
  Future<BigInt> registrar(DocumentacionEntity item);
  Future<void> eliminar(int idDoc, int audUsuario);
}
