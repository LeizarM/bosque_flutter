/// Origen: tabla `dbo.tbio_bioHrEmpleado`, via `p_list_BioHrEmpleado`.
///
/// Asigna un horario semanal (`idHrSemanal`) a un empleado desde `inicio`.
/// Sin fecha de fin: una fila nueva con `inicio` posterior reemplaza a la
/// anterior desde esa fecha — un empleado puede tener N horarios distintos
/// dentro del mismo mes.
class BioHrEmpleadoEntity {
  final BigInt idHrEmpleado;
  final BigInt idHrSemanal;
  final BigInt idEmplead;
  final DateTime? inicio;
  final int audUsuario;
  final DateTime? audFecha;

  const BioHrEmpleadoEntity({
    required this.idHrEmpleado,
    required this.idHrSemanal,
    required this.idEmplead,
    this.inicio,
    required this.audUsuario,
    this.audFecha,
  });
}
