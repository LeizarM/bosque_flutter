import 'package:intl/intl.dart';

/// Formatos numericos del modulo de Comisiones.
///
/// Se usa coma para miles y punto para decimales (1,234.56). Es la convencion
/// que pidio el area; el locale 'es' hace lo contrario, asi que se fija 'en_US'
/// de forma explicita en vez de depender del locale del dispositivo, que
/// cambiaria el formato segun el telefono de cada usuario.
class FormatoComision {
  const FormatoComision._();

  /// Importes: 1,234.56
  static final monto = NumberFormat('#,##0.00', 'en_US');

  /// Cantidades enteras: 1,234
  static final entero = NumberFormat('#,##0', 'en_US');

  /// Fecha corta.
  static final fecha = DateFormat('dd/MM/yyyy');

  /// Fecha con hora, para sellos de ejecucion.
  static final fechaHora = DateFormat('dd/MM/yyyy HH:mm');

  /// Porcentaje ya expresado en puntos: 0.80 %
  static String porcentaje(double puntos) =>
      '${NumberFormat('#,##0.00', 'en_US').format(puntos)} %';
}
