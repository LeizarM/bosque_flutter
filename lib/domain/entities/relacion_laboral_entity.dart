class RelacionLaboralEntity {
  final int codRelEmplEmpr;
  final int codEmpleado;
  final int esActivo;
  final String tipoRel;
  final String nombreFileContrato;
  final DateTime? fechaIni;
  final DateTime? fechaFin;
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
    this.fechaFin,
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
  //metodo to json
  Map<String, dynamic> toJson() {
    return {
      'codRelEmplEmpr': codRelEmplEmpr,
      'codEmpleado': codEmpleado,
      'esActivo': esActivo,
      'tipoRel': tipoRel,
      'nombreFileContrato': nombreFileContrato,
      'fechaIni': fechaIni?.toIso8601String(),
      'fechaFin': fechaFin?.toIso8601String(),
      'motivoFin': motivoFin,
      'audUsuario': audUsuario,
      'fechaInicioBeneficio': fechaInicioBeneficio?.toIso8601String(),
      'fechaInicioPlanilla': fechaInicioPlanilla?.toIso8601String(),
      'datoFechasBeneficio': datoFechasBeneficio,
      'cargo': cargo,
      'sucursal': sucursal,
      'empresaFiscal': empresaFiscal,
      'empresaInterna': empresaInterna,
    };
  }
  RelacionLaboralEntity copyWith({
    int? codRelEmplEmpr,
    int? codEmpleado,
    int? esActivo,
    String? tipoRel,
    String? nombreFileContrato,
    DateTime? fechaIni,
    DateTime? fechaFin,
    String? motivoFin,
    int? audUsuario,
    DateTime? fechaInicioBeneficio,
    DateTime? fechaInicioPlanilla,
    String? datoFechasBeneficio,
    String? cargo,
    String? sucursal,
    String? empresaFiscal,
    String? empresaInterna,
  }) {
    return RelacionLaboralEntity(
      codRelEmplEmpr: codRelEmplEmpr ?? this.codRelEmplEmpr,
      codEmpleado: codEmpleado ?? this.codEmpleado,
      esActivo: esActivo ?? this.esActivo,
      tipoRel: tipoRel ?? this.tipoRel,
      nombreFileContrato: nombreFileContrato ?? this.nombreFileContrato,
      fechaIni: fechaIni ?? this.fechaIni,
      fechaFin: fechaFin ?? this.fechaFin,
      motivoFin: motivoFin ?? this.motivoFin,
      audUsuario: audUsuario ?? this.audUsuario,
      fechaInicioBeneficio: fechaInicioBeneficio ?? this.fechaInicioBeneficio,
      fechaInicioPlanilla: fechaInicioPlanilla ?? this.fechaInicioPlanilla,
      datoFechasBeneficio: datoFechasBeneficio ?? this.datoFechasBeneficio,
      cargo: cargo ?? this.cargo,
      sucursal: sucursal ?? this.sucursal,
      empresaFiscal: empresaFiscal ?? this.empresaFiscal,
      empresaInterna: empresaInterna ?? this.empresaInterna,
    );
  }
}