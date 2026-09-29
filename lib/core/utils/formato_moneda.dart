import 'package:intl/intl.dart';

/// Formatos numericos compartidos para modulos de dinero que no son
/// Comisiones (ese modulo tiene su propio `FormatoComision`, con su propio
/// alcance y doc). Mismo patron 'en_US' que ya usan la mayoria de los
/// formateadores de dinero de la app (prestamos, anticipos, multas, lotes de
/// produccion, comisiones): coma para miles, punto para decimales
/// (1,234.56), fijo sin importar el locale del dispositivo.
///
/// Pensado para Tareas Rutinarias (saldo, montoIng, montoEg, total,
/// diferencia, importe, corte) y cualquier otro modulo fuera de Comisiones
/// que necesite el mismo formato de dinero.
class FormatoMoneda {
  const FormatoMoneda._();

  /// Importes: 1,234.56
  static final monto = NumberFormat('#,##0.00', 'en_US');

  /// Tipo de cambio, 4 decimales: 6.9600
  static final tipoCambio = NumberFormat('#,##0.0000', 'en_US');

  /// Cantidades enteras: 1,234
  static final entero = NumberFormat('#,##0', 'en_US');

  /// "Bs 1,234.56". En Tareas convivían "Bs 1,234.56", "1,234.56 Bs." y
  /// montos sin unidad; la unidad va adelante y siempre con el mismo nombre.
  static String bs(num valor) => 'Bs ${monto.format(valor)}';

  /// "$us 1,234.56". Caja AXA lo escribía con "$" suelto, que en una caja
  /// que maneja dos monedas no dice cuál es.
  static String dolares(num valor) => '\$us ${monto.format(valor)}';

  /// La unidad de una moneda tal como viene de la base ('BS', 'USD', 'Bs').
  static String unidad(String? moneda) =>
      switch ((moneda ?? '').trim().toUpperCase()) {
        'BS' || 'BOB' => 'Bs',
        'USD' || r'$US' || r'$' => r'$us',
        final otra => otra,
      };

  /// Un importe con la unidad de su moneda: "Bs 4,500.00", "$us 800.00".
  static String conUnidad(String? moneda, num valor) {
    final u = unidad(moneda);
    return u.isEmpty ? monto.format(valor) : '$u ${monto.format(valor)}';
  }
}
