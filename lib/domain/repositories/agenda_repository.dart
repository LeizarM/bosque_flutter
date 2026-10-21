import 'package:bosque_flutter/domain/entities/agenda_empleado_entity.dart';

/// La agenda de empleados del Dashboard.
abstract class AgendaRepository {
  /// Empleados con relación laboral vigente, ordenados por apellido.
  Future<List<AgendaEmpleadoEntity>> empleados();
}
