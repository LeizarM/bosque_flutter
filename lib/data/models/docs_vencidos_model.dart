import 'package:bosque_flutter/domain/entities/docs_vencidos_entity.dart';

class DocsVencidosModel {
  final int fila;
  final int codEmpleado;
  final String nombreCompleto;
  final String ciNumero;
  final String ciFechaVencimiento;
  final String licenciaVencimiento;
  // final String estadoCI;
  // final String estadoLicencia;
  final String estadoDocumentos;

  const DocsVencidosModel({
    required this.fila,
    required this.codEmpleado,
    required this.nombreCompleto,
    required this.ciNumero,
    required this.ciFechaVencimiento,
    required this.licenciaVencimiento,
    // required this.estadoCI,
    // required this.estadoLicencia,
    required this.estadoDocumentos,
  });

  factory DocsVencidosModel.fromJson(Map<String, dynamic> json) =>
      DocsVencidosModel(
        fila: json['fila'] ?? 0,
        codEmpleado: json['codEmpleado'] ?? 0,
        nombreCompleto: json['nombreCompleto'] ?? '',
        ciNumero: json['ciNumero'] ?? '',
        ciFechaVencimiento: json['ciFechaVencimiento'] ?? 'SIN FECHA',
        licenciaVencimiento:
            json['licenciaVencimiento'] ?? 'SIN LICENCIA REGISTRADA',
        //estadoCI: json['estadoCI'] ?? '',
        //estadoLicencia: json['estadoLicencia'] ?? '',
        estadoDocumentos: json['estadoDocumentos'] ?? '',
      );

  DocsVencidosEntity toEntity() => DocsVencidosEntity(
    fila: fila,
    codEmpleado: codEmpleado,
    nombreCompleto: nombreCompleto,
    ciNumero: ciNumero,
    ciFechaVencimiento: ciFechaVencimiento,
    licenciaVencimiento: licenciaVencimiento,
    //estadoCI: estadoCI,
    //estadoLicencia: estadoLicencia,
    estadoDocumentos: estadoDocumentos,
  );
}
