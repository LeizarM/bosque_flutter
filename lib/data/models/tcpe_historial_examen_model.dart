import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_historial_examen_entity.dart';

/// Un examen rendido por una persona, buscada por CI (`p_list_tcpe_Resultado` H).
class TcpeHistorialExamenModel {
  final BigInt codExamen;
  final BigInt? codRolExamen;
  final String? tituloLote;
  final String? nombreClasificacion;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? estado;
  final double? resultado;
  final String? login;
  final String? nombreCompleto;
  final String? ci;
  final double? notaAprobacion;
  final bool? aprobado;

  const TcpeHistorialExamenModel({
    required this.codExamen,
    this.codRolExamen,
    this.tituloLote,
    this.nombreClasificacion,
    this.fechaInicio,
    this.fechaFin,
    this.estado,
    this.resultado,
    this.login,
    this.nombreCompleto,
    this.ci,
    this.notaAprobacion,
    this.aprobado,
  });

  factory TcpeHistorialExamenModel.fromJson(Map<String, dynamic> json) => TcpeHistorialExamenModel(
    codExamen: tcpeBigInt(json['codExamen']) ?? BigInt.zero,
    codRolExamen: tcpeBigInt(json['codRolExamen']),
    tituloLote: tcpeTexto(json['tituloLote']),
    nombreClasificacion: tcpeTexto(json['nombreClasificacion']),
    fechaInicio: tcpeFecha(json['fechaInicio']),
    fechaFin: tcpeFecha(json['fechaFin']),
    estado: tcpeTexto(json['estado']),
    resultado: tcpeDouble(json['resultado']),
    login: tcpeTexto(json['login']),
    nombreCompleto: tcpeTexto(json['nombreCompleto']),
    ci: tcpeTexto(json['ci']),
    notaAprobacion: tcpeDouble(json['notaAprobacion']),
    aprobado: tcpeBool(json['aprobado']),
  );

  Map<String, dynamic> toJson() => {
    'codExamen': codExamen.toInt(),
    'codRolExamen': codRolExamen?.toInt(),
    'tituloLote': tituloLote,
    'nombreClasificacion': nombreClasificacion,
    'fechaInicio': tcpeFechaHoraJson(fechaInicio),
    'fechaFin': tcpeFechaHoraJson(fechaFin),
    'estado': estado,
    'resultado': resultado,
    'login': login,
    'nombreCompleto': nombreCompleto,
    'ci': ci,
    'notaAprobacion': notaAprobacion,
    'aprobado': aprobado,
  };

  TcpeHistorialExamenEntity toEntity() => TcpeHistorialExamenEntity(
    codExamen: codExamen,
    codRolExamen: codRolExamen,
    tituloLote: tituloLote,
    nombreClasificacion: nombreClasificacion,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    estado: estado,
    resultado: resultado,
    login: login,
    nombreCompleto: nombreCompleto,
    ci: ci,
    notaAprobacion: notaAprobacion,
    aprobado: aprobado,
  );

  factory TcpeHistorialExamenModel.fromEntity(TcpeHistorialExamenEntity e) => TcpeHistorialExamenModel(
    codExamen: e.codExamen,
    codRolExamen: e.codRolExamen,
    tituloLote: e.tituloLote,
    nombreClasificacion: e.nombreClasificacion,
    fechaInicio: e.fechaInicio,
    fechaFin: e.fechaFin,
    estado: e.estado,
    resultado: e.resultado,
    login: e.login,
    nombreCompleto: e.nombreCompleto,
    ci: e.ci,
    notaAprobacion: e.notaAprobacion,
    aprobado: e.aprobado,
  );
}
