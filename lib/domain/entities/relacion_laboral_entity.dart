class RelacionLaboralEntity {
  final int codRelEmplEmpr;
  final int codEmpleado;
  final int esActivo;
  final String tipoRel;
  final String nombreFileContrato;
  final DateTime fechaIni;
  final DateTime fechaFin;
  final String motivoFin;
  final int audUsuario;
  final DateTime? fechaInicioBeneficio;
  final DateTime? fechaInicioPlanilla;
  final String? datoFechasBeneficio;
  final String cargo;
  final String sucursal;
  final String empresaFiscal;
  final String empresaInterna;
  RelacionLaboralEntity({
    required this.codRelEmplEmpr,
    required this.codEmpleado,
    required this.esActivo,
    required this.tipoRel,
    required this.nombreFileContrato,
    required this.fechaIni,
    required this.fechaFin,
    required this.motivoFin,
    required this.audUsuario,
    this.fechaInicioBeneficio,
    this.fechaInicioPlanilla,
    this.datoFechasBeneficio,
    required this.cargo,
    required this.sucursal,
    required this.empresaFiscal,
    required this.empresaInterna,
  });
}