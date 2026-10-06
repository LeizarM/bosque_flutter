import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/verificacion_registro_entity.dart';

/// El cuerpo de `/cheque/verificacion/registrar`. Sin `estado` ni usuario: los
/// pone el servidor.
class VerificacionRegistroModel {
  final BigInt codvd;
  final BigInt codCheque;
  final int codBanco;
  final DateTime fechaBanco;
  final String observacion;

  const VerificacionRegistroModel({
    required this.codvd,
    required this.codCheque,
    required this.codBanco,
    required this.fechaBanco,
    required this.observacion,
  });

  factory VerificacionRegistroModel.fromJson(Map<String, dynamic> json) =>
      VerificacionRegistroModel(
        codvd: BigInt.from((json['codvd'] as num?) ?? 0),
        codCheque: BigInt.from((json['codCheque'] as num?) ?? 0),
        codBanco: (json['codBanco'] as num?)?.toInt() ?? 0,
        fechaBanco: soloFecha(json['fechaBanco']) ?? DateTime(1900),
        observacion: (json['observacion'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
    'codvd': codvd.toInt(),
    'codCheque': codCheque.toInt(),
    'codBanco': codBanco,
    'fechaBanco': fechaParaSql(fechaBanco),
    'observacion': observacion,
  };

  VerificacionRegistroEntity toEntity() => VerificacionRegistroEntity(
    codvd: codvd,
    codCheque: codCheque,
    codBanco: codBanco,
    fechaBanco: fechaBanco,
    observacion: observacion,
  );

  factory VerificacionRegistroModel.fromEntity(VerificacionRegistroEntity e) =>
      VerificacionRegistroModel(
        codvd: e.codvd,
        codCheque: e.codCheque,
        codBanco: e.codBanco,
        fechaBanco: e.fechaBanco,
        observacion: e.observacion.trim(),
      );
}
