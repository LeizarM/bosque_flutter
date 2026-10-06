import 'package:bosque_flutter/data/models/datos_cheque_verificacion_model.dart';
import 'package:bosque_flutter/domain/entities/cheque_pendiente_verificacion_entity.dart';

/// `ChequePendienteFila` del backend. Aqui `codBanco` es el banco del cheque (no
/// el de una verificacion, que todavia no existe).
class ChequePendienteVerificacionModel {
  final DatosChequeVerificacionModel cheque;
  final int? codBancoCheque;
  final int fila;

  const ChequePendienteVerificacionModel({
    required this.cheque,
    required this.codBancoCheque,
    required this.fila,
  });

  factory ChequePendienteVerificacionModel.fromJson(
    Map<String, dynamic> json,
  ) => ChequePendienteVerificacionModel(
    cheque: DatosChequeVerificacionModel.fromJson(json),
    codBancoCheque: (json['codBanco'] as num?)?.toInt(),
    fila: (json['fila'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    ...cheque.toJson(),
    'codBanco': codBancoCheque,
    'fila': fila,
  };

  ChequePendienteVerificacionEntity toEntity() =>
      ChequePendienteVerificacionEntity(
        cheque: cheque.toEntity(),
        codBancoCheque: codBancoCheque,
        fila: fila,
      );

  factory ChequePendienteVerificacionModel.fromEntity(
    ChequePendienteVerificacionEntity e,
  ) => ChequePendienteVerificacionModel(
    cheque: DatosChequeVerificacionModel.fromEntity(e.cheque),
    codBancoCheque: e.codBancoCheque,
    fila: e.fila,
  );
}
