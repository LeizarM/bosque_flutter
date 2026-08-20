import 'package:bosque_flutter/domain/entities/ccr_solicitud_entity.dart';
import 'package:intl/intl.dart';

class CcrSolicitudModel {
  final int idSolicitud;
  final int codEmpresa;
  final int numeracion;
  final String tipoSolicitud;
  final DateTime? fechaSistema;
  final DateTime fechaSolicitud;
  final int idSolicitante;
  final String datoSolicitante;
  final String estado;
  final String observacion;
  final double totalToneladas;
  final String sapObservacion;
  final double sapToneladas;
  final int audUsuario;
  final String datoNroSolicitud;
  final String datoEmpresa;
  final String datoEstado;
  final String datoTipoSolicitud;
  final String fechaSolicitudString;

  CcrSolicitudModel({
    required this.idSolicitud,
    required this.codEmpresa,
    required this.numeracion,
    required this.tipoSolicitud,
    this.fechaSistema,
    required this.fechaSolicitud,
    required this.idSolicitante,
    required this.datoSolicitante,
    required this.estado,
    required this.observacion,
    required this.totalToneladas,
    this.sapObservacion = '',
    this.sapToneladas = 0,
    required this.audUsuario,
    this.datoNroSolicitud = '',
    this.datoEmpresa = '',
    this.datoEstado = '',
    this.datoTipoSolicitud = '',
    this.fechaSolicitudString = '',
  });

  static DateTime? _fecha(dynamic v) {
    if (v == null || v == '') return null;
    return DateTime.tryParse(v.toString());
  }

  factory CcrSolicitudModel.fromJson(Map<String, dynamic> json) =>
      CcrSolicitudModel(
        idSolicitud: (json['idSolicitud'] ?? 0).toInt(),
        codEmpresa: (json['codEmpresa'] ?? 0).toInt(),
        numeracion: (json['numeracion'] ?? 0).toInt(),
        tipoSolicitud: json['tipoSolicitud'] ?? '',
        fechaSistema: _fecha(json['fechaSistema']),
        fechaSolicitud: _fecha(json['fechaSolicitud']) ?? DateTime(2000),
        idSolicitante: (json['idSolicitante'] ?? 0).toInt(),
        datoSolicitante: json['datoSolicitante'] ?? '',
        estado: json['estado'] ?? '',
        observacion: json['observacion'] ?? '',
        totalToneladas: (json['totalToneladas'] ?? 0).toDouble(),
        sapObservacion: json['sapObservacion'] ?? '',
        sapToneladas: (json['sapToneladas'] ?? 0).toDouble(),
        audUsuario: (json['audUsuario'] ?? 0).toInt(),
        datoNroSolicitud: json['datoNroSolicitud'] ?? '',
        datoEmpresa: json['datoEmpresa'] ?? '',
        datoEstado: json['datoEstado'] ?? '',
        datoTipoSolicitud: json['datoTipoSolicitud'] ?? '',
        fechaSolicitudString: json['fechaSolicitudString'] ?? '',
      );

  /// Solo lo que el SP escribe. Los `dato*` son de lectura y no viajan de vuelta.
  Map<String, dynamic> toJson() {
    final fmt = DateFormat("yyyy-MM-dd'T'00:00:00.000");
    return {
      'idSolicitud': idSolicitud,
      'codEmpresa': codEmpresa,
      'numeracion': numeracion,
      'tipoSolicitud': tipoSolicitud,
      'fechaSolicitud': fmt.format(fechaSolicitud),
      'idSolicitante': idSolicitante,
      'datoSolicitante': datoSolicitante,
      'estado': estado,
      'observacion': observacion,
      'totalToneladas': totalToneladas,
      'audUsuario': audUsuario,
    };
  }

  CcrSolicitudEntity toEntity() => CcrSolicitudEntity(
    idSolicitud: idSolicitud,
    codEmpresa: codEmpresa,
    numeracion: numeracion,
    tipoSolicitud: tipoSolicitud,
    fechaSistema: fechaSistema,
    fechaSolicitud: fechaSolicitud,
    idSolicitante: idSolicitante,
    datoSolicitante: datoSolicitante,
    estado: estado,
    observacion: observacion,
    totalToneladas: totalToneladas,
    sapObservacion: sapObservacion,
    sapToneladas: sapToneladas,
    audUsuario: audUsuario,
    datoNroSolicitud: datoNroSolicitud,
    datoEmpresa: datoEmpresa,
    datoEstado: datoEstado,
    datoTipoSolicitud: datoTipoSolicitud,
    fechaSolicitudString: fechaSolicitudString,
  );

  factory CcrSolicitudModel.fromEntity(CcrSolicitudEntity e) =>
      CcrSolicitudModel(
        idSolicitud: e.idSolicitud,
        codEmpresa: e.codEmpresa,
        numeracion: e.numeracion,
        tipoSolicitud: e.tipoSolicitud,
        fechaSistema: e.fechaSistema,
        fechaSolicitud: e.fechaSolicitud,
        idSolicitante: e.idSolicitante,
        datoSolicitante: e.datoSolicitante,
        estado: e.estado,
        observacion: e.observacion,
        totalToneladas: e.totalToneladas,
        sapObservacion: e.sapObservacion,
        sapToneladas: e.sapToneladas,
        audUsuario: e.audUsuario,
        datoNroSolicitud: e.datoNroSolicitud,
        datoEmpresa: e.datoEmpresa,
        datoEstado: e.datoEstado,
        datoTipoSolicitud: e.datoTipoSolicitud,
        fechaSolicitudString: e.fechaSolicitudString,
      );
}
