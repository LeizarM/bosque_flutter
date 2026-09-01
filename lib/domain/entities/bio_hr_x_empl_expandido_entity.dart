/// Origen: tabla `dbo.tbio_bioHrXEmplExpandido`, via
/// `p_list_BioHrXEmplExpandido`.
///
/// Calendario expandido dia por dia: horario esperado (`hrIngreso`/`hrSalida`)
/// para un empleado (via `idHrEmpleado`) en una `jornada` puntual. Es contra
/// esto que se comparan las marcaciones reales del biometrico.
class BioHrXEmplExpandidoEntity {
  final BigInt idHrEmpleado;
  final BigInt idHrs;
  final DateTime? jornada;
  final int dia;
  final DateTime? hrIngreso;
  final DateTime? hrSalida;
  final int audUsuario;
  final DateTime? audFecha;

  const BioHrXEmplExpandidoEntity({
    required this.idHrEmpleado,
    required this.idHrs,
    this.jornada,
    required this.dia,
    this.hrIngreso,
    this.hrSalida,
    required this.audUsuario,
    this.audFecha,
  });
}
