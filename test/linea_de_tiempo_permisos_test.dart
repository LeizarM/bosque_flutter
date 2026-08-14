/// Las piezas de la línea de tiempo de permisos, que ahora comparten la consola
/// de RR.HH. (`nomina_permisos_tab.dart`) y la ficha del trabajador
/// (`ver_solicitud_individual.dart`).
///
/// Eran privadas de la primera; al pasar a ser de las dos, un cambio en
/// cualquiera de ellas mueve dos pantallas y ya no alcanza con mirar una.
library;

import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cuandoCompacto / cuandoLargo', () {
    test('el permiso de un día dice la fecha UNA vez', () {
      final d = DateTime(2026, 3, 31, 9);
      final h = DateTime(2026, 3, 31, 17, 30);
      expect(cuandoCompacto(d, h), '31 mar');
      expect(cuandoLargo(d, h), '31/03/2026');
    });

    test('el de varios días muestra el tramo', () {
      final d = DateTime(2026, 8, 3);
      final h = DateTime(2026, 8, 10);
      expect(cuandoCompacto(d, h), '03 ago → 10 ago');
      expect(cuandoLargo(d, h), '03/08/2026 → 10/08/2026');
    });

    test('mismo día del mes pero distinto mes o año NO es el mismo día', () {
      expect(mismoDia(DateTime(2026, 3, 5), DateTime(2026, 4, 5)), isFalse);
      expect(mismoDia(DateTime(2025, 3, 5), DateTime(2026, 3, 5)), isFalse);
      expect(cuandoCompacto(DateTime(2026, 3, 5), DateTime(2026, 4, 5)),
          '05 mar → 05 abr');
    });

    test('sin fecha no inventa nada', () {
      expect(cuandoCompacto(null, DateTime(2026, 1, 1)), 'Sin fecha');
      expect(cuandoLargo(null, null), 'Sin fecha');
    });
  });

  group('agruparPorAnio', () {
    test('corta en tramos y conserva el orden recibido', () {
      final fechas = [
        DateTime(2026, 7, 13),
        DateTime(2026, 1, 7),
        DateTime(2025, 12, 2),
        DateTime(2025, 3, 1),
      ];
      final grupos = agruparPorAnio(fechas, (f) => f);

      expect(grupos.map((g) => g.$1).toList(), ['2026', '2025']);
      expect(grupos[0].$2, [fechas[0], fechas[1]]);
      expect(grupos[1].$2, [fechas[2], fechas[3]]);
    });

    test('lista desordenada parte el mismo año en dos tramos', () {
      // No es un capricho del test: es el contrato. Agrupar respetando el orden
      // recibido es lo que hace visible que alguien no ordenó la lista, en vez
      // de taparlo reordenando por atrás.
      final fechas = [
        DateTime(2026, 7, 1),
        DateTime(2025, 5, 1),
        DateTime(2026, 2, 1),
      ];
      expect(
        agruparPorAnio(fechas, (f) => f).map((g) => g.$1).toList(),
        ['2026', '2025', '2026'],
      );
    });

    test('las filas sin fecha caen en su propio tramo', () {
      final grupos = agruparPorAnio<DateTime?>(
        [DateTime(2026, 1, 1), null, null],
        (f) => f,
      );
      expect(grupos.map((g) => g.$1).toList(), ['2026', 'Sin fecha']);
      expect(grupos[1].$2.length, 2);
    });

    test('lista vacía, ningún tramo', () {
      expect(agruparPorAnio<DateTime>([], (f) => f), isEmpty);
    });
  });

  group('enOracion', () {
    test('baja el grito del sistema anterior', () {
      expect(enOracion('PUENTE POR 1RO DE MAYO'), 'Puente por 1ro de mayo');
    });

    test('respeta lo que ya está bien escrito', () {
      expect(enOracion('Vacaciones Normales Una semana.'),
          'Vacaciones Normales Una semana.');
    });

    test('el vacío sigue vacío', () {
      expect(enOracion('   '), '');
    });

    test('un texto sin letras no revienta', () {
      expect(enOracion(' 123 '), '123');
    });
  });

  group('numeroDeDias', () {
    test('media jornada con coma, día entero sin decimales', () {
      expect(numeroDeDias(0.5), '0,5');
      expect(numeroDeDias(6), '6');
      expect(numeroDeDias(2.5), '2,5');
    });
  });

  group('horaCorta', () {
    test('rellena con cero y no depende del locale', () {
      expect(horaCorta(DateTime(2026, 5, 2, 8, 30)), '08:30');
      expect(horaCorta(DateTime(2026, 5, 2, 17, 0)), '17:00');
      expect(horaCorta(null), '--');
    });
  });
}
