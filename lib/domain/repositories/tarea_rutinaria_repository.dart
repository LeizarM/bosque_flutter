// Destino final: lib/domain/repositories/tarea_rutinaria_repository.dart
import 'package:bosque_flutter/domain/entities/tarea_rutinaria_entity.dart';

abstract class TareaRutinariaRepository {
  Future<List<TareaRutinariaEntity>> obtener();
  Future<BigInt> registrar(TareaRutinariaEntity item);
  Future<void> eliminar(int idTarRuti, int audUsuario);
}
