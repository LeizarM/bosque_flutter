import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_resultado_examen_entity.dart';

/// Un examen del lote con su estado y nota (`p_list_tcpe_Resultado` L).
class TcpeResultadoExamenModel {
  final BigInt codExamen;
  final BigInt? codRolExamen;
  final BigInt? codUsuario;
  final String? login;
  final BigInt? codEmpleado;
  final String? nombreCompleto;
  final String? ci;
  final String? estado;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final DateTime? fechaLimite;
  final double? resultado;
  final bool aprobado;
  final double? notaAprobacion;
  final int totalPreguntas;
  final int respondidas;
  final int abiertasPendientes;

  const TcpeResultadoExamenModel({
    required this.codExamen,
    this.codRolExamen,
    this.codUsuario,
    this.login,
    this.codEmpleado,
    this.nombreCompleto,
    this.ci,
    this.estado,
    this.fechaInicio,
    this.fechaFin,
    this.fechaLimite,
    this.resultado,
    this.aprobado = false,
    this.notaAprobacion,
    this.totalPreguntas = 0,
    this.respondidas = 0,
    this.abiertasPendientes = 0,
  });

  factory TcpeResultadoExamenModel.fromJson(Map<String, dynamic> json) => TcpeResultadoExamenModel(
    codExamen: tcpeBigInt(json['codExamen']) ?? BigInt.zero,
    codRolExamen: tcpeBigInt(json['codRolExamen']),
    codUsuario: tcpeBigInt(json['codUsuario']),
    login: tcpeTexto(json['login']),
    codEmpleado: tcpeBigInt(json['codEmpleado']),
    nombreCompleto: tcpeTexto(json['nombreCompleto']),
    ci: tcpeTexto(json['ci']),
    estado: tcpeTexto(json['estado']),
    fechaInicio: tcpeFecha(json['fechaInicio']),
    fechaFin: tcpeFecha(json['fechaFin']),
    fechaLimite: tcpeFecha(json['fechaLimite']),
    resultado: tcpeDouble(json['resultado']),
    aprobado: tcpeBool(json['aprobado']) ?? false,
    notaAprobacion: tcpeDouble(json['notaAprobacion']),
    totalPreguntas: tcpeInt(json['totalPreguntas']) ?? 0,
    respondidas: tcpeInt(json['respondidas']) ?? 0,
    abiertasPendientes: tcpeInt(json['abiertasPendientes']) ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'codExamen': codExamen.toInt(),
    'codRolExamen': codRolExamen?.toInt(),
    'codUsuario': codUsuario?.toInt(),
    'login': login,
    'codEmpleado': codEmpleado?.toInt(),
    'nombreCompleto': nombreCompleto,
    'ci': ci,
    'estado': estado,
    'fechaInicio': tcpeFechaHoraJson(fechaInicio),
    'fechaFin': tcpeFechaHoraJson(fechaFin),
    'fechaLimite': tcpeFechaHoraJson(fechaLimite),
    'resultado': resultado,
    'aprobado': aprobado,
    'notaAprobacion': notaAprobacion,
    'totalPreguntas': totalPreguntas,
    'respondidas': respondidas,
    'abiertasPendientes': abiertasPendientes,
  };

  TcpeResultadoExamenEntity toEntity() => TcpeResultadoExamenEntity(
    codExamen: codExamen,
    codRolExamen: codRolExamen,
    codUsuario: codUsuario,
    login: login,
    codEmpleado: codEmpleado,
    nombreCompleto: nombreCompleto,
    ci: ci,
    estado: estado,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    fechaLimite: fechaLimite,
    resultado: resultado,
    aprobado: aprobado,
    notaAprobacion: notaAprobacion,
    totalPreguntas: totalPreguntas,
    respondidas: respondidas,
    abiertasPendientes: abiertasPendientes,
  );

  factory TcpeResultadoExamenModel.fromEntity(TcpeResultadoExamenEntity e) => TcpeResultadoExamenModel(
    codExamen: e.codExamen,
    codRolExamen: e.codRolExamen,
    codUsuario: e.codUsuario,
    login: e.login,
    codEmpleado: e.codEmpleado,
    nombreCompleto: e.nombreCompleto,
    ci: e.ci,
    estado: e.estado,
    fechaInicio: e.fechaInicio,
    fechaFin: e.fechaFin,
    fechaLimite: e.fechaLimite,
    resultado: e.resultado,
    aprobado: e.aprobado,
    notaAprobacion: e.notaAprobacion,
    totalPreguntas: e.totalPreguntas,
    respondidas: e.respondidas,
    abiertasPendientes: e.abiertasPendientes,
  );
}
