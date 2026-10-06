import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/utils/reglas_cheque.dart';

/// Las reglas de formulario del modulo de cheques. Reproducen `ReglasCheque.java`
/// (y su `ReglasChequeTest`): cada caso fija un comportamiento del legacy que se
/// conserva a proposito, aunque sorprenda.
void main() {
  group('Nro de cheque', () {
    test('digitos y guion medio', () {
      expect(ReglasCheque.errorNroCheque('123-45'), isNull);
      expect(ReglasCheque.errorNroCheque('0012'), isNull);
    });

    test('letras y espacios se rechazan', () {
      expect(ReglasCheque.errorNroCheque('abc'), isNotNull);
      expect(ReglasCheque.errorNroCheque('12 3'), isNotNull);
      expect(ReglasCheque.errorNroCheque(null), isNotNull);
    });

    test('el {2,25} del legacy no limita el largo, y se conserva', () {
      // El mensaje dice «entre 2 y 25», pero el regex del legacy no lo hace
      // cumplir: lo limita el campo (45) y lo exige `required`.
      expect(ReglasCheque.errorNroCheque('1' * 40), isNull);
      expect(ReglasCheque.errorNroCheque('1'), isNull);
      expect(ReglasCheque.errorNroCheque(''), isNull);
      expect(ReglasCheque.errorNroCheque('12?3'), isNull);
    });
  });

  group('A la orden de', () {
    test('letras, acentos, enie, apostrofe y espacios', () {
      expect(ReglasCheque.errorAOrdenDe("José Ñandú O'Brien"), isNull);
      expect(ReglasCheque.errorAOrdenDe(''), isNull);
      expect(ReglasCheque.errorAOrdenDe('Juan123'), isNotNull);
      // Tambien «S.R.L.»: el legacy no admite puntos y el servidor tampoco.
      expect(ReglasCheque.errorAOrdenDe('S.R.L.'), isNotNull);
      expect(ReglasCheque.errorAOrdenDe('a' * 101), isNotNull);
      expect(ReglasCheque.errorAOrdenDe('a' * 100), isNull);
    });
  });

  group('Recibo y talonario manual', () {
    test('recibo: 1 a 25, letras, numeros, espacios y apostrofe', () {
      expect(ReglasCheque.errorReciboManual('0'), isNull);
      expect(ReglasCheque.errorReciboManual('AB 12'), isNull);
      expect(ReglasCheque.errorReciboManual(''), isNotNull);
      expect(ReglasCheque.errorReciboManual('a-b'), isNotNull);
      expect(ReglasCheque.errorReciboManual('1' * 26), isNotNull);
    });

    test('talonario: 1 a 25, letras, numeros y espacios (sin apostrofe)', () {
      expect(ReglasCheque.errorNroTalonario('0'), isNull);
      expect(ReglasCheque.errorNroTalonario('T 100'), isNull);
      expect(ReglasCheque.errorNroTalonario("T'100"), isNotNull);
      expect(ReglasCheque.errorNroTalonario(''), isNotNull);
    });

    test('el cliente dejo el cheque (empleado 0): el recibo debe ser 0', () {
      expect(
        ReglasCheque.erroresReciboTalonario(
          codEmpleado: 0,
          reciboManual: '0',
          nroTalonario: '0',
        ),
        isEmpty,
      );
      final e = ReglasCheque.erroresReciboTalonario(
        codEmpleado: 0,
        reciboManual: '55',
        nroTalonario: '1',
      );
      expect(e, hasLength(1));
      expect(e.single, contains('lo dejó el cliente'));
    });

    test('un empleado lo trajo: el recibo no puede ser 0', () {
      final e = ReglasCheque.erroresReciboTalonario(
        codEmpleado: 7,
        reciboManual: '0',
        nroTalonario: '0',
      );
      expect(e, hasLength(1));
      expect(e.single, contains('lo trajo un empleado'));
    });

    test('con recibo hay que indicar talonario', () {
      final e = ReglasCheque.erroresReciboTalonario(
        codEmpleado: 7,
        reciboManual: '55',
        nroTalonario: '0',
      );
      expect(e, hasLength(1));
      expect(e.single, contains('talonario manual debe ser distinto de 0'));
    });

    test('los mensajes se acumulan, como en el legacy', () {
      // Cliente con recibo (regla 1) y recibo sin talonario (regla 3).
      expect(
        ReglasCheque.erroresReciboTalonario(
          codEmpleado: 0,
          reciboManual: '55',
          nroTalonario: '0',
        ),
        hasLength(2),
      );
    });

    test('el cero se compara exacto: «00» y « 0» no son el cero', () {
      expect(
        ReglasCheque.erroresReciboTalonario(
          codEmpleado: 0,
          reciboManual: '00',
          nroTalonario: '0',
        ),
        hasLength(2),
      );
    });
  });

  group('Observacion y Nro de SAP', () {
    test('la observacion vacia es valida', () {
      expect(ReglasCheque.errorObservacion(null), isNull);
      expect(ReglasCheque.errorObservacion(''), isNull);
    });

    test('observacion: 2 a 200, sin guion ni barra', () {
      expect(ReglasCheque.errorObservacion('Entregado en Para Cobranza'), isNull);
      expect(ReglasCheque.errorObservacion('ok, ok; ok: ok.'), isNull);
      expect(ReglasCheque.errorObservacion('a'), isNotNull);
      expect(ReglasCheque.errorObservacion('con - guion'), isNotNull);
      expect(ReglasCheque.errorObservacion('12/10/2026'), isNotNull);
      expect(ReglasCheque.errorObservacion('a' * 201), isNotNull);
      expect(ReglasCheque.errorObservacion('a' * 200), isNull);
    });

    test('Nro de SAP: 2 a 40, sin guion', () {
      expect(ReglasCheque.errorNroSap('12345'), isNull);
      expect(ReglasCheque.errorNroSap('SAP 12345'), isNull);
      expect(ReglasCheque.errorNroSap('1'), isNotNull);
      expect(ReglasCheque.errorNroSap('123-45'), isNotNull);
      expect(ReglasCheque.errorNroSap(null), isNotNull);
      expect(ReglasCheque.errorNroSap('1' * 41), isNotNull);
    });
  });

  group('Nombre de banco: el regex del legacy, tal cual', () {
    test('letras sin acento, numeros, espacio, apostrofe y barra', () {
      expect(ReglasCheque.errorNombreBanco('BANCO UNION'), isNull);
      expect(ReglasCheque.errorNombreBanco('Banco 2000'), isNull);
      expect(ReglasCheque.errorNombreBanco("BANCO D'ORO"), isNull);
      expect(ReglasCheque.errorNombreBanco('BANCO A/B'), isNull);
    });

    test('3 a 50 caracteres', () {
      expect(ReglasCheque.errorNombreBanco('ABC'), isNull);
      expect(ReglasCheque.errorNombreBanco('A' * 50), isNull);
      expect(ReglasCheque.errorNombreBanco('AB'), isNotNull);
      expect(ReglasCheque.errorNombreBanco(''), isNotNull);
      expect(ReglasCheque.errorNombreBanco('A' * 51), isNotNull);
      expect(ReglasCheque.errorNombreBanco(null), isNotNull);
    });

    test('el punto y los acentos se rechazan, como en el legacy', () {
      expect(ReglasCheque.errorNombreBanco('BANCO S.A.'), isNotNull);
      expect(ReglasCheque.errorNombreBanco('BANCÓ UNION'), isNotNull);
      expect(ReglasCheque.errorNombreBanco('BANCO DEL PIÑO'), isNotNull);
      expect(ReglasCheque.errorNombreBanco('BANCO, UNION'), isNotNull);
    });

    test('se valida lo que se envia: sin espacios en los bordes', () {
      expect(ReglasCheque.errorNombreBanco('  BANCO UNION  '), isNull);
      // Dos letras con espacios alrededor son dos caracteres al enviarse.
      expect(ReglasCheque.errorNombreBanco('  AB  '), isNotNull);
    });

    test('las rarezas del regex del legacy se conservan', () {
      // `A-z` incluye `[ \ ] ^ _ \``; la `S` suelta es la letra S y el `'-'`
      // es el rango de un solo caracter (el apostrofe), asi que **el guion
      // medio no entra**, aunque el mensaje del servidor diga que si.
      expect(ReglasCheque.errorNombreBanco('BANCO_X'), isNull);
      expect(ReglasCheque.errorNombreBanco('BANCO [1]'), isNull);
      expect(ReglasCheque.errorNombreBanco('BANCO-X'), isNotNull);
    });

    test('el mensaje no promete lo que el regex no admite', () {
      final m = ReglasCheque.errorNombreBanco('BANCO S.A.')!;
      expect(m, contains('De 3 a 50 caracteres'));
      expect(m, contains('Sin punto ni acentos'));
      expect(m.contains('guion'), isFalse);
    });
  });

  group('Fecha de cobro: +-28 dias de la fecha del cheque', () {
    final cheque = DateTime(2026, 10, 1);

    test('los extremos estan incluidos', () {
      expect(ReglasCheque.cobroEnRango(DateTime(2026, 10, 1), cheque), isTrue);
      expect(ReglasCheque.cobroEnRango(DateTime(2026, 10, 29), cheque), isTrue);
      expect(ReglasCheque.cobroEnRango(DateTime(2026, 10, 30), cheque), isFalse);
      expect(ReglasCheque.cobroEnRango(DateTime(2026, 9, 3), cheque), isTrue);
      expect(ReglasCheque.cobroEnRango(DateTime(2026, 9, 2), cheque), isFalse);
    });

    test('compara dias, no instantes', () {
      expect(
        ReglasCheque.cobroEnRango(DateTime(2026, 10, 29, 23, 59), cheque),
        isTrue,
      );
      expect(
        ReglasCheque.cobroEnRango(
          DateTime(2026, 10, 29, 23, 59),
          DateTime(2026, 10, 1, 18, 30),
        ),
        isTrue,
      );
    });

    test('el rango cruza el cambio de mes y de anio', () {
      final r = ReglasCheque.rangoCobro(DateTime(2026, 12, 20));
      expect(r.desde, DateTime(2026, 11, 22));
      expect(r.hasta, DateTime(2027, 1, 17));
    });
  });

  group('leerMonto', () {
    test('acepta coma de miles y punto decimal', () {
      expect(ReglasCheque.leerMonto('12,345.67'), 12345.67);
      expect(ReglasCheque.leerMonto(' 1500 '), 1500);
    });

    test('vacio o no numerico es null', () {
      expect(ReglasCheque.leerMonto(null), isNull);
      expect(ReglasCheque.leerMonto('  '), isNull);
      expect(ReglasCheque.leerMonto('abc'), isNull);
      expect(ReglasCheque.leerMonto('1.2.3'), isNull);
    });
  });
}
