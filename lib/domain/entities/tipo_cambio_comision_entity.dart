import 'package:flutter/foundation.dart';

/// Tipo de cambio con el que el preliminar convierte bolivianos a dolares.
@immutable
class TipoCambioComisionEntity {
  const TipoCambioComisionEntity({
    required this.fecha,
    required this.tipoCambio,
    required this.origen,
    required this.diasDeAntiguedad,
  });

  /// Fecha de la cotizacion. Nula cuando se devolvio el valor de respaldo.
  final DateTime? fecha;
  final double tipoCambio;

  /// SAP, HISTORICO o POR DEFECTO.
  final String origen;

  /// Dias entre la cotizacion y la fecha consultada.
  final int? diasDeAntiguedad;

  bool get esDeSap => origen == 'SAP';

  /// Conviene avisar cuando el numero no viene de SAP: en ese caso es un
  /// respaldo y puede no reflejar la cotizacion de hoy.
  bool get esRespaldo => !esDeSap;
}
