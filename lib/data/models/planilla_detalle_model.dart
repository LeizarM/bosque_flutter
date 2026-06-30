import 'package:bosque_flutter/domain/entities/planilla_detalle_entity.dart';

class PlanillaDetalleModel {
  int codPlanilla;
  int codEmpleado;
  String ciNumero;
  String apellidos;
  String nombres;
  String nombreCompleto;
  String nacionalidad;
  DateTime? fechaNacimiento;
  String sexo;
  String cargo;
  DateTime? fechaIngreso;
  DateTime? fechaSalida;
  double diasPagadosMes;
  double horasDiasPagadas;
  double haberBasico;
  double bonoAntiguedad;
  double bonoProduccion;
  double total;
  double afp;
  double saldoPrestamo;
  double cuotasDolares;
  double cuotasBolivianos;
  double multas;
  double anticipo;
  double otros;
  double totalDescuentos;
  double liquido;

  double totalHaberBasico;
  double totalBonoAntiguedad;
  double totalBonoProduccion;
  double sumTotalGanado;
  double totalAFP;
  double totalSaldoPrestamo;
  double totalCuotasDolares;
  double totalCuotasBolivianos;
  double totalMultas;
  double totalAnticipo;
  double totalOtros;
  double totalTotalDescuentos;
  double totalLiquido;

  int fila;
  int totalRegistros;
  int totalPaginas;

  bool tieneError;
  String? mensajeError;

  PlanillaDetalleModel({
    required this.codPlanilla,
    required this.codEmpleado,
    required this.ciNumero,
    required this.apellidos,
    required this.nombres,
    required this.nombreCompleto,
    required this.nacionalidad,
    this.fechaNacimiento,
    required this.sexo,
    required this.cargo,
    this.fechaIngreso,
    this.fechaSalida,
    required this.diasPagadosMes,
    required this.horasDiasPagadas,
    required this.haberBasico,
    required this.bonoAntiguedad,
    required this.bonoProduccion,
    required this.total,
    required this.afp,
    required this.saldoPrestamo,
    required this.cuotasDolares,
    required this.cuotasBolivianos,
    required this.multas,
    required this.anticipo,
    required this.otros,
    required this.totalDescuentos,
    required this.liquido,
    required this.totalHaberBasico,
    required this.totalBonoAntiguedad,
    required this.totalBonoProduccion,
    required this.sumTotalGanado,
    required this.totalAFP,
    required this.totalSaldoPrestamo,
    required this.totalCuotasDolares,
    required this.totalCuotasBolivianos,
    required this.totalMultas,
    required this.totalAnticipo,
    required this.totalOtros,
    required this.totalTotalDescuentos,
    required this.totalLiquido,
    required this.fila,
    required this.totalRegistros,
    required this.totalPaginas,
    this.tieneError = false,
    this.mensajeError,
  });

  factory PlanillaDetalleModel.fromJson(Map<String, dynamic> json) {
    return PlanillaDetalleModel(
      codPlanilla: json['codPlanilla'] ?? 0,
      codEmpleado: json['codEmpleado'] ?? 0,
      ciNumero: json['ciNumero'] ?? '',
      apellidos: json['apellidos'] ?? '',
      nombres: json['nombres'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? '',
      nacionalidad: json['nacionalidad'] ?? '',
      fechaNacimiento:
          json['fechaNacimiento'] != null
              ? DateTime.parse(json['fechaNacimiento'])
              : null,
      sexo: json['sexo'] ?? '',
      cargo: json['cargo'] ?? '',
      fechaIngreso:
          json['fechaIngreso'] != null
              ? DateTime.parse(json['fechaIngreso'])
              : null,
      fechaSalida:
          json['fechaSalida'] != null
              ? DateTime.parse(json['fechaSalida'])
              : null,
      diasPagadosMes: (json['dias_pagados_mes'] ?? 0).toDouble(),
      horasDiasPagadas: (json['horas_dias_pagadas'] ?? 0).toDouble(),
      haberBasico: (json['haberBasico'] ?? 0).toDouble(),
      bonoAntiguedad: (json['bonoAntiguedad'] ?? 0).toDouble(),
      bonoProduccion: (json['bonoProduccion'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      afp: (json['afp'] ?? json['AFP'] ?? 0).toDouble(),
      saldoPrestamo: (json['saldoPrestamo'] ?? 0).toDouble(),
      cuotasDolares: (json['cuotasDolares'] ?? 0).toDouble(),
      cuotasBolivianos: (json['cuotasBolivianos'] ?? 0).toDouble(),
      multas: (json['multas'] ?? 0).toDouble(),
      anticipo: (json['anticipo'] ?? 0).toDouble(),
      otros: (json['otros'] ?? 0).toDouble(),
      totalDescuentos: (json['totalDescuentos'] ?? 0).toDouble(),
      liquido: (json['liquido'] ?? 0).toDouble(),
      totalHaberBasico: (json['totalHaberBasico'] ?? 0).toDouble(),
      totalBonoAntiguedad: (json['totalBonoAntiguedad'] ?? 0).toDouble(),
      totalBonoProduccion: (json['totalBonoProduccion'] ?? 0).toDouble(),
      sumTotalGanado: (json['sumTotalGanado'] ?? 0).toDouble(),
      totalAFP: (json['totalAFP'] ?? json['totalAfp'] ?? 0).toDouble(),
      totalSaldoPrestamo: (json['totalSaldoPrestamo'] ?? 0).toDouble(),
      totalCuotasDolares: (json['totalCuotasDolares'] ?? 0).toDouble(),
      totalCuotasBolivianos: (json['totalCuotasBolivianos'] ?? 0).toDouble(),
      totalMultas: (json['totalMultas'] ?? 0).toDouble(),
      totalAnticipo: (json['totalAnticipo'] ?? 0).toDouble(),
      totalOtros: (json['totalOtros'] ?? 0).toDouble(),
      totalTotalDescuentos: (json['totalTotalDescuentos'] ?? 0).toDouble(),
      totalLiquido: (json['totalLiquido'] ?? 0).toDouble(),
      fila: json['fila'] ?? 0,
      totalRegistros: json['totalRegistros'] ?? 0,
      totalPaginas: json['totalPaginas'] ?? 0,
      tieneError: (json['tieneError'] == 1 || json['tieneError'] == true),
      mensajeError: json['mensajeError'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codPlanilla': codPlanilla,
      'codEmpleado': codEmpleado,
      'ciNumero': ciNumero,
      'apellidos': apellidos,
      'nombres': nombres,
      'nombreCompleto': nombreCompleto,
      'nacionalidad': nacionalidad,
      'fechaNacimiento': fechaNacimiento?.toIso8601String(),
      'sexo': sexo,
      'cargo': cargo,
      'fechaIngreso': fechaIngreso?.toIso8601String(),
      'fechaSalida': fechaSalida?.toIso8601String(),
      'dias_pagados_mes': diasPagadosMes,
      'horas_dias_pagadas': horasDiasPagadas,
      'haberBasico': haberBasico,
      'bonoAntiguedad': bonoAntiguedad,
      'bonoProduccion': bonoProduccion,
      'total': total,
      'AFP': afp,
      'saldoPrestamo': saldoPrestamo,
      'cuotasDolares': cuotasDolares,
      'cuotasBolivianos': cuotasBolivianos,
      'multas': multas,
      'anticipo': anticipo,
      'otros': otros,
      'totalDescuentos': totalDescuentos,
      'liquido': liquido,
      'totalHaberBasico': totalHaberBasico,
      'totalBonoAntiguedad': totalBonoAntiguedad,
      'totalBonoProduccion': totalBonoProduccion,
      'sumTotalGanado': sumTotalGanado,
      'totalAFP': totalAFP,
      'totalSaldoPrestamo': totalSaldoPrestamo,
      'totalCuotasDolares': totalCuotasDolares,
      'totalCuotasBolivianos': totalCuotasBolivianos,
      'totalMultas': totalMultas,
      'totalAnticipo': totalAnticipo,
      'totalOtros': totalOtros,
      'totalTotalDescuentos': totalTotalDescuentos,
      'totalLiquido': totalLiquido,
      'fila': fila,
      'totalRegistros': totalRegistros,
      'totalPaginas': totalPaginas,
      'tieneError': tieneError ? 1 : 0,
      'mensajeError': mensajeError,
    };
  }

  PlanillaDetalleEntity toEntity() => PlanillaDetalleEntity(
    codPlanilla: codPlanilla,
    codEmpleado: codEmpleado,
    ciNumero: ciNumero,
    apellidos: apellidos,
    nombres: nombres,
    nombreCompleto: nombreCompleto,
    nacionalidad: nacionalidad,
    fechaNacimiento: fechaNacimiento,
    sexo: sexo,
    cargo: cargo,
    fechaIngreso: fechaIngreso,
    fechaSalida: fechaSalida,
    diasPagadosMes: diasPagadosMes,
    horasDiasPagadas: horasDiasPagadas,
    haberBasico: haberBasico,
    bonoAntiguedad: bonoAntiguedad,
    bonoProduccion: bonoProduccion,
    total: total,
    afp: afp,
    saldoPrestamo: saldoPrestamo,
    cuotasDolares: cuotasDolares,
    cuotasBolivianos: cuotasBolivianos,
    multas: multas,
    anticipo: anticipo,
    otros: otros,
    totalDescuentos: totalDescuentos,
    liquido: liquido,
    totalHaberBasico: totalHaberBasico,
    totalBonoAntiguedad: totalBonoAntiguedad,
    totalBonoProduccion: totalBonoProduccion,
    sumTotalGanado: sumTotalGanado,
    totalAFP: totalAFP,
    totalSaldoPrestamo: totalSaldoPrestamo,
    totalCuotasDolares: totalCuotasDolares,
    totalCuotasBolivianos: totalCuotasBolivianos,
    totalMultas: totalMultas,
    totalAnticipo: totalAnticipo,
    totalOtros: totalOtros,
    totalTotalDescuentos: totalTotalDescuentos,
    totalLiquido: totalLiquido,
    fila: fila,
    totalRegistros: totalRegistros,
    totalPaginas: totalPaginas,
    tieneError: tieneError,
    mensajeError: mensajeError,
  );
}
