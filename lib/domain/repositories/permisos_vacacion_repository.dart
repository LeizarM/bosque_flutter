import 'package:bosque_flutter/domain/entities/permiso_entity.dart';

abstract class PermisosVacacionRepository {
  /// Obtiene los días disponibles y el resumen de vacaciones para un empleado.
  Future<PermisoEntity?> getResumenVacaciones(int codEmpleado);
}
