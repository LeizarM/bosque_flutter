import 'package:bosque_flutter/domain/entities/entrega_cheque_entity.dart';

/// HoraAccionDto del backend: `{ codAccion, hora }`.
class EntregaChequeModel {
  final BigInt codAccion;
  final String hora;

  const EntregaChequeModel({required this.codAccion, required this.hora});

  factory EntregaChequeModel.fromJson(Map<String, dynamic> json) =>
      EntregaChequeModel(
        codAccion: BigInt.from((json['codAccion'] as num?) ?? 0),
        hora: (json['hora'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
    'codAccion': codAccion.toInt(),
    'hora': hora,
  };

  EntregaChequeEntity toEntity() =>
      EntregaChequeEntity(codAccion: codAccion, hora: hora);

  factory EntregaChequeModel.fromEntity(EntregaChequeEntity e) =>
      EntregaChequeModel(codAccion: e.codAccion, hora: e.hora);
}
