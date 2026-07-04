import 'dart:convert';

class FeriadoModel {
  final DateTime fecha;
  final String motivo;

  FeriadoModel({
    required this.fecha,
    required this.motivo,
  });

  factory FeriadoModel.fromJson(Map<String, dynamic> json) => FeriadoModel(
        fecha: DateTime.parse(json["fecha"]),
        motivo: json["motivo"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "fecha": fecha.toIso8601String(),
        "motivo": motivo,
      };
}
