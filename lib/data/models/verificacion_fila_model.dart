import 'package:bosque_flutter/data/models/datos_cheque_verificacion_model.dart';
import 'package:bosque_flutter/data/models/verificacion_deposito_model.dart';
import 'package:bosque_flutter/domain/entities/verificacion_fila_entity.dart';

/// `VerificacionFila` del backend: las columnas de `tch_verificacionDeposito`
/// mas lo que sale de los JOIN. El JSON es plano; [VerificacionDepositoModel]
/// lee las columnas, [DatosChequeVerificacionModel] los datos del cheque y este
/// modelo el resto.
class VerificacionFilaModel {
  final VerificacionDepositoModel verificacion;
  final DatosChequeVerificacionModel cheque;
  final String datoBanco;
  final String datoEstado;
  final int fila;

  const VerificacionFilaModel({
    required this.verificacion,
    required this.cheque,
    required this.datoBanco,
    required this.datoEstado,
    required this.fila,
  });

  factory VerificacionFilaModel.fromJson(Map<String, dynamic> json) =>
      VerificacionFilaModel(
        verificacion: VerificacionDepositoModel.fromJson(json),
        cheque: DatosChequeVerificacionModel.fromJson(json),
        datoBanco: (json['datoBanco'] ?? '').toString(),
        datoEstado: (json['datoEstado'] ?? '').toString(),
        fila: (json['fila'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
    ...verificacion.toJson(),
    ...cheque.toJson(),
    'datoBanco': datoBanco,
    'datoEstado': datoEstado,
    'fila': fila,
  };

  VerificacionFilaEntity toEntity() => VerificacionFilaEntity(
    verificacion: verificacion.toEntity(),
    cheque: cheque.toEntity(),
    datoBanco: datoBanco,
    datoEstado: datoEstado,
    fila: fila,
  );

  factory VerificacionFilaModel.fromEntity(VerificacionFilaEntity e) =>
      VerificacionFilaModel(
        verificacion: VerificacionDepositoModel.fromEntity(e.verificacion),
        cheque: DatosChequeVerificacionModel.fromEntity(e.cheque),
        datoBanco: e.datoBanco,
        datoEstado: e.datoEstado,
        fila: e.fila,
      );
}
