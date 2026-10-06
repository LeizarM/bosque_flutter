import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/utils/situacion_cheque.dart';

/// La situacion de cobro de un cheque: un dato de pantalla derivado del estado y
/// de la fecha de cobro, con el reloj inyectado.
void main() {
  // «Hoy» con hora: la comparacion es por dia y no puede depender de ella.
  final hoy = DateTime(2026, 10, 3, 16, 20);

  SituacionDeCheque de(String? estado, DateTime? cobro, {DateTime? ahora}) =>
      situacionDeCheque(
        estado: estado,
        fechaCobrar: cobro,
        hoy: ahora ?? hoy,
      );

  DateTime enDias(int d) => DateTime(2026, 10, 3 + d);

  group('cerrado', () {
    test('un CER es cerrado, venza cuando venza', () {
      for (final d in [-90, -1, 0, 1, 30]) {
        final s = de('CER', enDias(d));
        expect(s.situacion, SituacionCheque.cerrado, reason: 'dia $d');
        expect(s.dias, isNull);
        expect(s.tienePlazo, isFalse);
        expect(s.esUrgente, isFalse);
      }
    });

    test('un CER sin fecha de cobro tambien es cerrado', () {
      expect(de('CER', null).situacion, SituacionCheque.cerrado);
    });

    test('el estado se compara sin espacios', () {
      expect(de(' CER ', enDias(-5)).situacion, SituacionCheque.cerrado);
    });
  });

  group('pendientes por fecha de cobro', () {
    test('atrasado: la fecha de cobro es anterior a hoy', () {
      final s = de('PEN', enDias(-12));
      expect(s.situacion, SituacionCheque.atrasado);
      expect(s.dias, -12);
      expect(s.texto, 'Atrasado 12 d');
      expect(s.textoLargo, 'Atrasado 12 días');
      expect(s.esUrgente, isTrue);
      expect(s.tienePlazo, isTrue);
    });

    test('atrasado un dia: «1 día» en singular', () {
      final s = de('PEN', enDias(-1));
      expect(s.situacion, SituacionCheque.atrasado);
      expect(s.texto, 'Atrasado 1 d');
      expect(s.textoLargo, 'Atrasado 1 día');
    });

    test('cobra hoy', () {
      final s = de('PEN', enDias(0));
      expect(s.situacion, SituacionCheque.cobraHoy);
      expect(s.dias, 0);
      expect(s.texto, 'Cobra hoy');
      expect(s.textoLargo, 'Cobra hoy');
      expect(s.esUrgente, isTrue);
    });

    test('por cobrar: de 1 a 7 dias', () {
      for (var d = 1; d <= 7; d++) {
        final s = de('PEN', enDias(d));
        expect(s.situacion, SituacionCheque.porCobrar, reason: 'en $d dias');
        expect(s.dias, d);
        expect(s.texto, 'En $d d');
        expect(s.esUrgente, isFalse);
      }
    });

    test('un dia: «Cobra mañana» y no «1 días»', () {
      final s = de('PEN', enDias(1));
      expect(s.textoLargo, 'Cobra mañana');
    });

    test('varios dias: el plural completo en el texto largo', () {
      expect(de('PEN', enDias(3)).textoLargo, 'Cobra en 3 días');
    });

    test('vigente: a partir del dia 8', () {
      final s = de('PEN', enDias(8));
      expect(s.situacion, SituacionCheque.vigente);
      expect(s.dias, 8);
      expect(s.texto, 'En 8 d');
      expect(s.textoLargo, 'Cobra en 8 días');
      expect(s.esUrgente, isFalse);
      expect(de('PEN', enDias(400)).situacion, SituacionCheque.vigente);
    });

    test('el limite de los 7 dias esta en diasPorCobrarCheque', () {
      expect(diasPorCobrarCheque, 7);
    });

    test('sin fecha de cobro: no hay con que comparar', () {
      final s = de('PEN', null);
      expect(s.situacion, SituacionCheque.sinFecha);
      expect(s.dias, isNull);
      expect(s.tienePlazo, isFalse);
      expect(s.texto, 'Sin fecha');
      expect(s.textoLargo, 'Sin fecha de cobro');
    });
  });

  group('solo cuenta el dia', () {
    test('a las 23:59 un cheque que se cobra hoy sigue cobrandose hoy', () {
      final tarde = DateTime(2026, 10, 3, 23, 59, 59);
      expect(de('PEN', DateTime(2026, 10, 3), ahora: tarde).situacion,
          SituacionCheque.cobraHoy);
    });

    test('a las 00:00 tampoco cambia', () {
      final madrugada = DateTime(2026, 10, 3);
      expect(de('PEN', DateTime(2026, 10, 3, 18), ahora: madrugada).situacion,
          SituacionCheque.cobraHoy);
    });

    test('la hora de la fecha de cobro no la vuelve atrasada ni futura', () {
      // Una fecha con hora (si algun dia la columna deja de ser `date`).
      expect(
        de('PEN', DateTime(2026, 10, 3, 8, 15), ahora: DateTime(2026, 10, 3, 22))
            .situacion,
        SituacionCheque.cobraHoy,
      );
      expect(
        de('PEN', DateTime(2026, 10, 4, 0, 1), ahora: DateTime(2026, 10, 3, 23))
            .dias,
        1,
      );
    });

    test('cruza el fin de mes y de año', () {
      expect(
        de('PEN', DateTime(2026, 11, 2), ahora: DateTime(2026, 10, 31, 20)).dias,
        2,
      );
      expect(
        de('PEN', DateTime(2027, 1, 2), ahora: DateTime(2026, 12, 30, 9)).dias,
        3,
      );
      expect(
        de('PEN', DateTime(2026, 12, 30), ahora: DateTime(2027, 1, 2, 9)).dias,
        -3,
      );
    });

    test('un cambio de hora no mueve un dia', () {
      // Domingo 1/11/2026: fin del horario de verano en el hemisferio norte.
      // Se compara en UTC, asi que 24 horas de menos o de mas no cuentan.
      expect(
        de('PEN', DateTime(2026, 11, 2), ahora: DateTime(2026, 10, 31, 23, 30))
            .dias,
        2,
      );
    });
  });

  group('estados que no son PEN ni CER', () {
    test('se tratan como abiertos, igual que el resto del modulo', () {
      expect(de(null, enDias(-2)).situacion, SituacionCheque.atrasado);
      expect(de('XYZ', enDias(2)).situacion, SituacionCheque.porCobrar);
    });
  });

  group('los textos', () {
    test('nunca dicen «vencido»: VEN es una accion de postergacion', () {
      for (final estado in ['PEN', 'CER', null]) {
        for (var d = -60; d <= 60; d++) {
          final s = de(estado, enDias(d));
          expect(s.texto.toLowerCase(), isNot(contains('vencid')));
          expect(s.textoLargo.toLowerCase(), isNot(contains('vencid')));
        }
      }
      expect(de('PEN', null).texto.toLowerCase(), isNot(contains('vencid')));
    });

    test('el texto corto es corto y el largo dice «días» o «día»', () {
      for (var d = -30; d <= 30; d++) {
        final s = de('PEN', enDias(d));
        expect(s.texto.length, lessThanOrEqualTo(16), reason: s.texto);
        if (s.situacion == SituacionCheque.atrasado ||
            s.situacion == SituacionCheque.porCobrar ||
            s.situacion == SituacionCheque.vigente) {
          expect(s.texto, endsWith(' d'));
        }
      }
    });
  });

  test('dos situaciones iguales son iguales', () {
    expect(de('PEN', enDias(3)), de('PEN', enDias(3)));
    expect(de('PEN', enDias(3)).hashCode, de('PEN', enDias(3)).hashCode);
    expect(de('PEN', enDias(3)), isNot(de('PEN', enDias(4))));
  });
}
