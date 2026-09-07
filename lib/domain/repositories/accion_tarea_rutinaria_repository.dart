// Destino final: lib/domain/repositories/accion_tarea_rutinaria_repository.dart
import 'package:bosque_flutter/domain/entities/accion_tarea_rutinaria_entity.dart';

abstract class AccionTareaRutinariaRepository {
  Future<List<AccionTareaRutinariaEntity>> obtener();
  Future<BigInt> registrar(AccionTareaRutinariaEntity item);
  Future<void> eliminar(int idATR, int audUsuario);
}
