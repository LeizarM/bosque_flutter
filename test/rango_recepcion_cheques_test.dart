import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/utils/rango_recepcion_cheques.dart';

/// El rango con el que abre la grilla de cheques: de hace tres meses a hoy, con
/// los meses restados en el calendario (no con el desborde de `DateTime`).
void main() {
  test('la constante es de tres meses', () {
    expect(mesesPorDefectoGrillaCheques, 3);
  });

  group('rangoRecepcionPorDefecto', () {
    test('caso comun: 03/10/2026 -> 03/07/2026 a 03/10/2026', () {
      final r = rangoRecepcionPorDefecto(DateTime(2026, 10, 3));
      expect(r.desde, DateTime(2026, 7, 3));
      expect(r.hasta, DateTime(2026, 10, 3));
    });

    test('fin de mes: 31/05/2026 -> 28/02/2026, no 03/03', () {
      final r = rangoRecepcionPorDefecto(DateTime(2026, 5, 31));
      expect(r.desde, DateTime(2026, 2, 28));
      expect(r.hasta, DateTime(2026, 5, 31));
    });

    test('fin de mes en ano bisiesto: 31/05/2028 -> 29/02/2028', () {
      final r = rangoRecepcionPorDefecto(DateTime(2028, 5, 31));
      expect(r.desde, DateTime(2028, 2, 29));
    });

    test('31/12 -> 30/09 (septiembre no tiene 31)', () {
      final r = rangoRecepcionPorDefecto(DateTime(2026, 12, 31));
      expect(r.desde, DateTime(2026, 9, 30));
      expect(r.hasta, DateTime(2026, 12, 31));
    });

    test('1 de enero cruza al ano anterior: 01/01/2026 -> 01/10/2025', () {
      final r = rangoRecepcionPorDefecto(DateTime(2026, 1, 1));
      expect(r.desde, DateTime(2025, 10, 1));
      expect(r.hasta, DateTime(2026, 1, 1));
    });

    test('29/02 bisiesto: 29/02/2028 -> 29/11/2027', () {
      final r = rangoRecepcionPorDefecto(DateTime(2028, 2, 29));
      expect(r.desde, DateTime(2027, 11, 29));
      expect(r.hasta, DateTime(2028, 2, 29));
    });

    test('marzo: 31/03/2026 -> 31/12/2025 y 30/04/2026 -> 30/01/2026', () {
      expect(
        rangoRecepcionPorDefecto(DateTime(2026, 3, 31)).desde,
        DateTime(2025, 12, 31),
      );
      expect(
        rangoRecepcionPorDefecto(DateTime(2026, 4, 30)).desde,
        DateTime(2026, 1, 30),
      );
    });

    test('devuelve fechas sin hora aunque hoy traiga hora', () {
      final r = rangoRecepcionPorDefecto(DateTime(2026, 10, 3, 23, 59, 59, 999));
      expect(r.desde, DateTime(2026, 7, 3));
      expect(r.hasta, DateTime(2026, 10, 3));
      for (final f in [r.desde, r.hasta]) {
        expect(
          (f.hour, f.minute, f.second, f.millisecond, f.microsecond),
          (0, 0, 0, 0, 0),
        );
      }
    });

    test('el rango siempre es valido: desde nunca pasa de hasta', () {
      var dia = DateTime(2024, 1, 1);
      while (dia.isBefore(DateTime(2029, 1, 1))) {
        final r = rangoRecepcionPorDefecto(dia);
        expect(r.desde.isAfter(r.hasta), isFalse, reason: '$dia');
        // Tres meses de calendario: entre 89 y 92 dias.
        final dias = r.hasta.difference(r.desde).inDays;
        expect(dias, inInclusiveRange(89, 92), reason: '$dia');
        dia = dia.add(const Duration(days: 1));
      }
    });
  });

  group('restarMesesCalendario', () {
    test('el dia se recorta al ultimo del mes de destino', () {
      expect(
        restarMesesCalendario(DateTime(2026, 3, 31), 1),
        DateTime(2026, 2, 28),
      );
      expect(
        restarMesesCalendario(DateTime(2028, 3, 31), 1),
        DateTime(2028, 2, 29),
      );
      expect(
        restarMesesCalendario(DateTime(2026, 8, 31), 2),
        DateTime(2026, 6, 30),
      );
    });

    test('cero meses no cambia la fecha y doce son un ano', () {
      expect(
        restarMesesCalendario(DateTime(2026, 10, 3), 0),
        DateTime(2026, 10, 3),
      );
      expect(
        restarMesesCalendario(DateTime(2026, 10, 3), 12),
        DateTime(2025, 10, 3),
      );
      expect(
        restarMesesCalendario(DateTime(2028, 2, 29), 12),
        DateTime(2027, 2, 28),
      );
    });
  });

  group('textoRangoRecepcion', () {
    test('con las dos fechas', () {
      expect(
        textoRangoRecepcion(DateTime(2026, 7, 3), DateTime(2026, 10, 3)),
        'Mostrando cheques recibidos del 03/07/2026 al 03/10/2026',
      );
    });

    test('un solo dia', () {
      expect(
        textoRangoRecepcion(DateTime(2026, 10, 3), DateTime(2026, 10, 3)),
        'Mostrando cheques recibidos el 03/10/2026',
      );
    });

    test('solo desde', () {
      expect(
        textoRangoRecepcion(DateTime(2026, 7, 3), null),
        'Mostrando cheques recibidos desde el 03/07/2026',
      );
    });

    test('solo hasta', () {
      expect(
        textoRangoRecepcion(null, DateTime(2026, 10, 3)),
        'Mostrando cheques recibidos hasta el 03/10/2026',
      );
    });

    test('sin fechas', () {
      expect(
        textoRangoRecepcion(null, null),
        'Mostrando todos los cheques recibidos',
      );
    });
  });
}
