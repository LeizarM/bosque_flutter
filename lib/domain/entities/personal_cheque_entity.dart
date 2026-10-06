/// Una persona que puede dejar un cheque o recibirlo en custodia
/// (`/cheque/personal/entregan` y `/cheque/personal/custodia`): jefe de
/// cobranzas, cobradores y, solo para «Entregado por», choferes, con la
/// asignacion activa en la sucursal.
class PersonalChequeEntity {
  final int codEmpleado;
  final String nombreCompleto;

  const PersonalChequeEntity({
    required this.codEmpleado,
    required this.nombreCompleto,
  });
}
