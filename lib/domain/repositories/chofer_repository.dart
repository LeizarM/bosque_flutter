import 'package:bosque_flutter/domain/entities/chofer_entity.dart';

abstract class ChoferRepository {
  /// Obtiene la lista completa de choferes
  Future<List<ChoferEntity>> getChoferes();
  
  /// Obtiene un chofer específico por su código de empleado
  Future<ChoferEntity?> getChoferById(int codEmpleado);
}