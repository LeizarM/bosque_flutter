import 'dart:convert';
import 'package:bosque_flutter/domain/entities/indemnizacion_entity.dart';

List<IndemnizacionModel> indemnizacionModelFromJson(String str) =>
    List<IndemnizacionModel>.from(
      json.decode(str).map((x) => IndemnizacionModel.fromJson(x)),
    );

String indemnizacionModelToJson(List<IndemnizacionModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class IndemnizacionModel {
  final int? codIndemnizacion;
  final int? codEmpleado;
  final double? montoIndemnizacion;
  final DateTime? fechaIndemnizacion;
  final String? descripcion;
  final int? estado;
  final String? empleadoNombres;
  final String? empleadoApellidos;
  final String? empresa;

  final int? nro;
  final String? apellidos;
  final String? fechaIngreso;
  final String? periodo;
  final String? fechaSalida;
  final int? diasactual;
  final String? antiguedad;
  final double? totalGanadoFecha;
  final double? tercerMesAnterior;
  final double? segundoMesAnterior;
  final double? primerMesAnterior;
  final double? promedioMeses;
  final double? indemnizacionMesAnterior;
  final int? dias30;
  final double? indemnizacionCalculada;
  final double? indemnizacionActual;
  final int? diasAguinaldo;
  final double? aguinaldo;
  final double? diasVacacion;
  final double? pagoFiniquitoQuinq;
  final double? indemnizacionFinal;
  final String? caja;
  final String? sucursal;
  final String? area;
  final String? cargo;

  // Metadata Paginacion
  final int? pagina;
  final int? tamanoPagina;
  final int? totalPaginas;
  final int? totalRegistros;

  IndemnizacionModel({
    this.codIndemnizacion,
    this.codEmpleado,
    this.montoIndemnizacion,
    this.fechaIndemnizacion,
    this.descripcion,
    this.estado,
    this.empleadoNombres,
    this.empleadoApellidos,
    this.empresa,
    this.nro,
    this.apellidos,
    this.fechaIngreso,
    this.periodo,
    this.fechaSalida,
    this.diasactual,
    this.antiguedad,
    this.totalGanadoFecha,
    this.tercerMesAnterior,
    this.segundoMesAnterior,
    this.primerMesAnterior,
    this.promedioMeses,
    this.indemnizacionMesAnterior,
    this.dias30,
    this.indemnizacionCalculada,
    this.indemnizacionActual,
    this.diasAguinaldo,
    this.aguinaldo,
    this.diasVacacion,
    this.pagoFiniquitoQuinq,
    this.indemnizacionFinal,
    this.caja,
    this.sucursal,
    this.area,
    this.cargo,
    this.pagina,
    this.tamanoPagina,
    this.totalPaginas,
    this.totalRegistros,
  });

  factory IndemnizacionModel.fromJson(Map<String, dynamic> json) {
    String? nombres =
        json['empleado']?['nombres'] ??
        json['empleado.nombres'] ??
        json['nombreCompleto'];
    String? apells =
        json['empleado']?['apellidos'] ?? json['empleado.apellidos'];

    return IndemnizacionModel(
      codIndemnizacion: json['codIndemnizacion'] as int?,
      codEmpleado: json['codEmpleado'] as int?,
      montoIndemnizacion:
          json['montoIndemnizacion'] != null
              ? (json['montoIndemnizacion'] as num).toDouble()
              : null,
      fechaIndemnizacion:
          json['fechaIndemnizacion'] != null
              ? DateTime.tryParse(json['fechaIndemnizacion'])
              : null,
      descripcion: json['descripcion'] as String?,
      estado: json['estado'] as int?,
      empleadoNombres: nombres,
      empleadoApellidos: apells,
      empresa: json['empresa'] as String?,
      nro: (json['nro'] ?? json['fila']) as int?,
      apellidos: json['apellidos'] as String?,
      fechaIngreso: json['fechaIngreso'] as String?,
      periodo: json['periodo'] as String?,
      fechaSalida: json['fechaSalida'] as String?,
      diasactual: json['diasactual'] as int?,
      antiguedad: json['antiguedad'] as String?,
      totalGanadoFecha:
          json['totalGanadoFecha'] != null
              ? (json['totalGanadoFecha'] as num).toDouble()
              : null,
      tercerMesAnterior:
          json['tercerMesAnterior'] != null
              ? (json['tercerMesAnterior'] as num).toDouble()
              : null,
      segundoMesAnterior:
          json['segundoMesAnterior'] != null
              ? (json['segundoMesAnterior'] as num).toDouble()
              : null,
      primerMesAnterior:
          json['primerMesAnterior'] != null
              ? (json['primerMesAnterior'] as num).toDouble()
              : null,
      promedioMeses:
          json['promedioMeses'] != null
              ? (json['promedioMeses'] as num).toDouble()
              : null,
      indemnizacionMesAnterior:
          json['indemnizacionMesAnterior'] != null
              ? (json['indemnizacionMesAnterior'] as num).toDouble()
              : null,
      dias30: json['dias30'] as int?,
      indemnizacionCalculada:
          json['indemnizacion'] != null
              ? (json['indemnizacion'] as num).toDouble()
              : null,
      indemnizacionActual:
          json['indemnizacionActual'] != null
              ? (json['indemnizacionActual'] as num).toDouble()
              : null,
      diasAguinaldo: json['diasAguinaldo'] as int?,
      aguinaldo:
          json['aguinaldo'] != null
              ? (json['aguinaldo'] as num).toDouble()
              : null,
      diasVacacion:
          json['diasVacacion'] != null
              ? (json['diasVacacion'] as num).toDouble()
              : (json['DiasVacacion'] != null
                  ? (json['DiasVacacion'] as num).toDouble()
                  : null),
      pagoFiniquitoQuinq:
          json['pagoFiniquitoQuinq'] != null
              ? (json['pagoFiniquitoQuinq'] as num).toDouble()
              : null,
      indemnizacionFinal:
          json['indemnizacionFinal'] != null
              ? (json['indemnizacionFinal'] as num).toDouble()
              : null,
      caja: json['caja'] as String?,
      sucursal: json['sucursal'] as String?,
      area: json['area'] as String?,
      cargo: json['cargo'] as String?,
      pagina: json['pagina'] as int?,
      tamanoPagina: json['tamanoPagina'] as int?,
      totalPaginas: json['totalPaginas'] as int?,
      totalRegistros: json['totalRegistros'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codIndemnizacion': codIndemnizacion,
      'codEmpleado': codEmpleado,
      'montoIndemnizacion': montoIndemnizacion,
      'fechaIndemnizacion': fechaIndemnizacion?.toIso8601String(),
      'descripcion': descripcion,
      'estado': estado,
    };
  }

  IndemnizacionEntity toEntity() => IndemnizacionEntity(
    codIndemnizacion: codIndemnizacion,
    codEmpleado: codEmpleado,
    montoIndemnizacion: montoIndemnizacion,
    fechaIndemnizacion: fechaIndemnizacion,
    descripcion: descripcion,
    estado: estado,
    empleadoNombres: empleadoNombres,
    empleadoApellidos: empleadoApellidos,
    empresa: empresa,
    nro: nro,
    apellidos: apellidos,
    fechaIngreso: fechaIngreso,
    periodo: periodo,
    fechaSalida: fechaSalida,
    diasactual: diasactual,
    antiguedad: antiguedad,
    totalGanadoFecha: totalGanadoFecha,
    tercerMesAnterior: tercerMesAnterior,
    segundoMesAnterior: segundoMesAnterior,
    primerMesAnterior: primerMesAnterior,
    promedioMeses: promedioMeses,
    indemnizacionMesAnterior: indemnizacionMesAnterior,
    dias30: dias30,
    indemnizacionCalculada: indemnizacionCalculada,
    indemnizacionActual: indemnizacionActual,
    diasAguinaldo: diasAguinaldo,
    aguinaldo: aguinaldo,
    diasVacacion: diasVacacion,
    pagoFiniquitoQuinq: pagoFiniquitoQuinq,
    indemnizacionFinal: indemnizacionFinal,
    caja: caja,
    sucursal: sucursal,
    area: area,
    cargo: cargo,
    pagina: pagina,
    tamanoPagina: tamanoPagina,
    totalPaginas: totalPaginas,
    totalRegistros: totalRegistros,
  );

  factory IndemnizacionModel.fromEntity(IndemnizacionEntity entity) =>
      IndemnizacionModel(
        codIndemnizacion: entity.codIndemnizacion,
        codEmpleado: entity.codEmpleado,
        montoIndemnizacion: entity.montoIndemnizacion,
        fechaIndemnizacion: entity.fechaIndemnizacion,
        descripcion: entity.descripcion,
        estado: entity.estado,
        empleadoNombres: entity.empleadoNombres,
        empleadoApellidos: entity.empleadoApellidos,
        empresa: entity.empresa,
        nro: entity.nro,
        apellidos: entity.apellidos,
        fechaIngreso: entity.fechaIngreso,
        periodo: entity.periodo,
        fechaSalida: entity.fechaSalida,
        diasactual: entity.diasactual,
        antiguedad: entity.antiguedad,
        totalGanadoFecha: entity.totalGanadoFecha,
        tercerMesAnterior: entity.tercerMesAnterior,
        segundoMesAnterior: entity.segundoMesAnterior,
        primerMesAnterior: entity.primerMesAnterior,
        promedioMeses: entity.promedioMeses,
        indemnizacionMesAnterior: entity.indemnizacionMesAnterior,
        dias30: entity.dias30,
        indemnizacionCalculada: entity.indemnizacionCalculada,
        indemnizacionActual: entity.indemnizacionActual,
        diasAguinaldo: entity.diasAguinaldo,
        aguinaldo: entity.aguinaldo,
        diasVacacion: entity.diasVacacion,
        pagoFiniquitoQuinq: entity.pagoFiniquitoQuinq,
        indemnizacionFinal: entity.indemnizacionFinal,
        caja: entity.caja,
        sucursal: entity.sucursal,
        area: entity.area,
        cargo: entity.cargo,
        pagina: entity.pagina,
        tamanoPagina: entity.tamanoPagina,
        totalPaginas: entity.totalPaginas,
        totalRegistros: entity.totalRegistros,
      );
}
