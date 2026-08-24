import 'package:bosque_flutter/domain/entities/tipo_cambio_comision_entity.dart';

class TipoCambioComisionModel {
  const TipoCambioComisionModel({
    this.fecha,
    required this.tipoCambio,
    required this.origen,
    this.diasDeAntiguedad,
  });

  final DateTime? fecha;
  final double tipoCambio;
  final String origen;
  final int? diasDeAntiguedad;

  factory TipoCambioComisionModel.fromJson(Map<String, dynamic> json) {
    return TipoCambioComisionModel(
      fecha: _fecha(json['fecha']),
      tipoCambio: _decimal(json['tipoCambio']) ?? 6.96,
      origen: (json['origen'] ?? 'POR DEFECTO').toString(),
      diasDeAntiguedad:
          json['diasDeAntiguedad'] == null
              ? null
              : int.tryParse(json['diasDeAntiguedad'].toString()),
    );
  }

  TipoCambioComisionEntity toEntity() => TipoCambioComisionEntity(
    fecha: fecha,
    tipoCambio: tipoCambio,
    origen: origen,
    diasDeAntiguedad: diasDeAntiguedad,
  );

  static double? _decimal(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static DateTime? _fecha(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
