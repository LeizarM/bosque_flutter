import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/data/models/cheque_model.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';

/// ChequeFilaDto del backend: las columnas de tch_cheque mas lo que sale de los
/// JOIN. El JSON es plano; [ChequeModel] lee las columnas y este los extras.
///
/// Tolera lo que la base de prueba trae de verdad: `descTipo` en null, `tipo`
/// con caracteres raros y `audFecha` en texto no ISO.
class ChequeFilaModel {
  final ChequeModel cheque;
  final DateTime? fechaRecepcion;
  final String datoCliente;
  final String descMoneda;
  final String? descTipo;
  final String descEstado;
  final String nombreBanco;
  final String datoEmpleado;
  final String? observacion;
  final String datoEmpresa;
  final int fila;

  const ChequeFilaModel({
    required this.cheque,
    required this.fechaRecepcion,
    required this.datoCliente,
    required this.descMoneda,
    required this.descTipo,
    required this.descEstado,
    required this.nombreBanco,
    required this.datoEmpleado,
    required this.observacion,
    required this.datoEmpresa,
    required this.fila,
  });

  factory ChequeFilaModel.fromJson(Map<String, dynamic> json) =>
      ChequeFilaModel(
        cheque: ChequeModel.fromJson(json),
        fechaRecepcion: soloFecha(json['fechaRecepcion']),
        datoCliente: (json['datoCliente'] ?? '').toString(),
        descMoneda: (json['descMoneda'] ?? '').toString(),
        descTipo: json['descTipo'] as String?,
        descEstado: (json['descEstado'] ?? '').toString(),
        nombreBanco: (json['nombreBanco'] ?? '').toString(),
        datoEmpleado: (json['datoEmpleado'] ?? '').toString(),
        observacion: json['observacion'] as String?,
        datoEmpresa: (json['datoEmpresa'] ?? '').toString(),
        fila: (json['fila'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
    ...cheque.toJson(),
    'fechaRecepcion':
        fechaRecepcion == null ? null : fechaParaSql(fechaRecepcion!),
    'datoCliente': datoCliente,
    'descMoneda': descMoneda,
    'descTipo': descTipo,
    'descEstado': descEstado,
    'nombreBanco': nombreBanco,
    'datoEmpleado': datoEmpleado,
    'observacion': observacion,
    'datoEmpresa': datoEmpresa,
    'fila': fila,
  };

  ChequeFilaEntity toEntity() => ChequeFilaEntity(
    cheque: cheque.toEntity(),
    fechaRecepcion: fechaRecepcion,
    datoCliente: datoCliente,
    descMoneda: descMoneda,
    descTipo: descTipo,
    descEstado: descEstado,
    nombreBanco: nombreBanco,
    datoEmpleado: datoEmpleado,
    observacion: observacion,
    datoEmpresa: datoEmpresa,
    fila: fila,
  );

  factory ChequeFilaModel.fromEntity(ChequeFilaEntity e) => ChequeFilaModel(
    cheque: ChequeModel.fromEntity(e.cheque),
    fechaRecepcion: e.fechaRecepcion,
    datoCliente: e.datoCliente,
    descMoneda: e.descMoneda,
    descTipo: e.descTipo,
    descEstado: e.descEstado,
    nombreBanco: e.nombreBanco,
    datoEmpleado: e.datoEmpleado,
    observacion: e.observacion,
    datoEmpresa: e.datoEmpresa,
    fila: e.fila,
  );
}
