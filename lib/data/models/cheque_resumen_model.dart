import 'package:bosque_flutter/domain/entities/cheque_resumen_entity.dart';

/// ChequeResumenDto del backend: `{ codCheque, datoCheque }`.
class ChequeResumenModel {
  final BigInt codCheque;
  final String datoCheque;

  const ChequeResumenModel({required this.codCheque, required this.datoCheque});

  factory ChequeResumenModel.fromJson(Map<String, dynamic> json) =>
      ChequeResumenModel(
        codCheque: BigInt.from((json['codCheque'] as num?) ?? 0),
        datoCheque: (json['datoCheque'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
    'codCheque': codCheque.toInt(),
    'datoCheque': datoCheque,
  };

  ChequeResumenEntity toEntity() =>
      ChequeResumenEntity(codCheque: codCheque, datoCheque: datoCheque);

  factory ChequeResumenModel.fromEntity(ChequeResumenEntity e) =>
      ChequeResumenModel(codCheque: e.codCheque, datoCheque: e.datoCheque);
}
