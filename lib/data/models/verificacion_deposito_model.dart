import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/verificacion_deposito_entity.dart';

/// Espeja la tabla `tch_verificacionDeposito` y el POJO `ChVerificacionDeposito`
/// del backend, con los mismos nombres de columna (`codvd` en minuscula).
///
/// `fechaBanco` llega como `yyyy-MM-dd` (la columna es `date`); `audFecha`, con
/// hora. El listado no trae `audUsuario` ni `audFecha`: quedan en null.
class VerificacionDepositoModel {
  static final DateFormat _conHora = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  final BigInt codvd;
  final BigInt codCheque;
  final int? codBanco;
  final DateTime? fechaBanco;
  final String? observacion;
  final String estado;
  final int? audUsuario;
  final DateTime? audFecha;

  const VerificacionDepositoModel({
    required this.codvd,
    required this.codCheque,
    required this.codBanco,
    required this.fechaBanco,
    required this.observacion,
    required this.estado,
    required this.audUsuario,
    required this.audFecha,
  });

  factory VerificacionDepositoModel.fromJson(Map<String, dynamic> json) =>
      VerificacionDepositoModel(
        codvd: BigInt.from((json['codvd'] as num?) ?? 0),
        codCheque: BigInt.from((json['codCheque'] as num?) ?? 0),
        codBanco: (json['codBanco'] as num?)?.toInt(),
        fechaBanco: soloFecha(json['fechaBanco']),
        observacion: json['observacion'] as String?,
        estado: (json['estado'] ?? '').toString().trim(),
        audUsuario: (json['audUsuario'] as num?)?.toInt(),
        audFecha: fechaHora(json['audFecha']),
      );

  Map<String, dynamic> toJson() => {
    'codvd': codvd.toInt(),
    'codCheque': codCheque.toInt(),
    'codBanco': codBanco,
    'fechaBanco': fechaBanco == null ? null : fechaParaSql(fechaBanco!),
    'observacion': observacion,
    'estado': estado,
    'audUsuario': audUsuario,
    'audFecha': audFecha == null ? null : _conHora.format(audFecha!),
  };

  VerificacionDepositoEntity toEntity() => VerificacionDepositoEntity(
    codvd: codvd,
    codCheque: codCheque,
    codBanco: codBanco,
    fechaBanco: fechaBanco,
    observacion: observacion,
    estado: estado,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory VerificacionDepositoModel.fromEntity(VerificacionDepositoEntity e) =>
      VerificacionDepositoModel(
        codvd: e.codvd,
        codCheque: e.codCheque,
        codBanco: e.codBanco,
        fechaBanco: e.fechaBanco,
        observacion: e.observacion,
        estado: e.estado,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
      );
}
