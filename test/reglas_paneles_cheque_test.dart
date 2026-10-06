import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';
import 'package:bosque_flutter/domain/utils/reglas_paneles_cheque.dart';

/// Las reglas de los tres paneles del detalle (notas de remision, transacciones
/// bancarias y postergaciones) y los permisos que las gobiernan. Son las del
/// legacy tal como las aplica el codigo (`NotaRemisionManagedBean`,
/// `WizardCheque.saveNotaRemision`, `saveNroTransaccion`, `savePostePostrgcn`) y
/// las mismas del servidor (`ReglasPanelesCheque.java`).
void main() {
  group('nota de remision: el regex del legacy, literal', () {
    // `^[0-9  ]{5,10}`: digitos y espacios, de 5 a 10.
    test('acepta de 5 a 10 digitos', () {
      for (final n in ['12345', '262211881', '2922800091', '00000']) {
        expect(ReglasPanelesCheque.errorNotaRemision(n), isNull, reason: n);
      }
    });

    test('acepta espacios, como el patron del legacy (hay datos reales asi)', () {
      expect(ReglasPanelesCheque.errorNotaRemision('4386 4420'), isNull);
      expect(ReglasPanelesCheque.errorNotaRemision('1234 5'), isNull);
    });

    test('rechaza menos de 5 y mas de 10', () {
      final corta = ReglasPanelesCheque.errorNotaRemision('1234');
      expect(corta, contains('demasiado corta'));
      expect(corta, contains('«1234»'));
      expect(corta, contains('de 5 a 10'));
      final larga = ReglasPanelesCheque.errorNotaRemision('12345678901');
      expect(larga, contains('demasiado larga'));
      expect(larga, contains('11 caracteres'));
    });

    test('rechaza letras y simbolos y dice cuales sobran', () {
      final e = ReglasPanelesCheque.errorNotaRemision('12A45-7');
      expect(e, contains('caracteres que no se aceptan'));
      expect(e, contains('«A»'));
      expect(e, contains('«-»'));
      expect(e, isNot(contains('«1»')));
    });

    test('vacio dice que falta, con que hacer', () {
      for (final v in [null, '', '   ']) {
        final e = ReglasPanelesCheque.errorNotaRemision(v);
        expect(e, startsWith('Falta la nota de remisión'));
        expect(e, contains('de 5 a 10 dígitos'));
      }
    });

    test('se evalua ya recortada (lo que viaja)', () {
      expect(ReglasPanelesCheque.errorNotaRemision('  262211881  '), isNull);
    });
  });

  group('nro de factura: entero de 1 a 999999', () {
    test('acepta de 1 a 999999', () {
      for (final n in ['1', '1856', '999999', '000012', ' 77 ']) {
        expect(ReglasPanelesCheque.errorNroFactura(n), isNull, reason: n);
      }
    });

    test('cero no es mayor que cero', () {
      final e = ReglasPanelesCheque.errorNroFactura('0');
      expect(e, contains('mayor que 0'));
      expect(e, contains('«0»'));
      expect(ReglasPanelesCheque.errorNroFactura('000'), contains('mayor que 0'));
    });

    test('mas de 6 caracteres: demasiado largo (maxlength 6 del campo)', () {
      final e = ReglasPanelesCheque.errorNroFactura('1234567');
      expect(e, contains('demasiado largo'));
      expect(e, contains('7 dígitos'));
      expect(e, contains('999999'));
    });

    test('letras o signos: dice cuales sobran', () {
      final e = ReglasPanelesCheque.errorNroFactura('12a-4');
      expect(e, contains('caracteres que no se aceptan'));
      expect(e, contains('«a»'));
      expect(e, contains('«-»'));
    });

    test('vacio dice que falta', () {
      expect(
        ReglasPanelesCheque.errorNroFactura(''),
        startsWith('Falta el número de factura'),
      );
    });
  });

  group('transaccion bancaria: mas de 4 caracteres y hasta 30', () {
    test('4 caracteres no alcanzan (length > 4); 5 si', () {
      expect(
        ReglasPanelesCheque.errorNroTransaccion('AB12'),
        contains('demasiado corto'),
      );
      expect(ReglasPanelesCheque.errorNroTransaccion('AB123'), isNull);
    });

    test('30 si, 31 no', () {
      expect(ReglasPanelesCheque.errorNroTransaccion('A' * 30), isNull);
      final e = ReglasPanelesCheque.errorNroTransaccion('A' * 31);
      expect(e, contains('demasiado largo'));
      expect(e, contains('31 caracteres'));
      expect(e, contains('hasta 30'));
    });

    test('sin regex de formato: letras, digitos y signos valen', () {
      for (final n in ['TT26216QW3N3', '14910211612', 'TRANSF-0098/2026']) {
        expect(ReglasPanelesCheque.errorNroTransaccion(n), isNull, reason: n);
      }
    });

    test('el mensaje corto dice el valor y cuantos caracteres tiene', () {
      final e = ReglasPanelesCheque.errorNroTransaccion('AB1');
      expect(e, contains('«AB1»'));
      expect(e, contains('3 caracteres'));
    });

    test('vacio dice que falta', () {
      expect(
        ReglasPanelesCheque.errorNroTransaccion('  '),
        startsWith('Falta el número de transacción'),
      );
    });
  });

  group('postergacion: motivo de mas de 2 y hasta 200 caracteres', () {
    test('2 caracteres no alcanzan (length > 2); 3 si', () {
      expect(
        ReglasPanelesCheque.errorObservacionPostergacion('ok'),
        contains('demasiado corto'),
      );
      expect(ReglasPanelesCheque.errorObservacionPostergacion('Sin'), isNull);
    });

    test('200 si, 201 no', () {
      expect(ReglasPanelesCheque.errorObservacionPostergacion('a' * 200), isNull);
      final e = ReglasPanelesCheque.errorObservacionPostergacion('a' * 201);
      expect(e, contains('demasiado largo'));
      expect(e, contains('201 caracteres'));
    });

    test('texto libre: acentos, signos y saltos de linea (hay datos reales asi)', () {
      expect(
        ReglasPanelesCheque.errorObservacionPostergacion(
          'Cliente envió carta: postergación al 06/03\ny pidió "tiempo".',
        ),
        isNull,
      );
    });

    test('vacio dice que falta el motivo', () {
      expect(
        ReglasPanelesCheque.errorObservacionPostergacion(null),
        startsWith('Falta el motivo'),
      );
    });
  });

  group('fecha obligatoria', () {
    test('sin fecha dice cual falta; con fecha, nada', () {
      expect(
        ReglasPanelesCheque.errorFechaRequerida(null, campo: 'la fecha de la factura'),
        'Falta la fecha de la factura. Elígela en el calendario.',
      );
      expect(
        ReglasPanelesCheque.errorFechaRequerida(
          DateTime(2026, 10, 3),
          campo: 'la fecha de la factura',
        ),
        isNull,
      );
    });
  });

  group('permisos de los paneles', () {
    PermisosCheque con(Set<String> botones, {bool admin = false}) =>
        PermisosCheque(botones: botones, esAdmin: admin);

    test('los nombres de los botones son los de tb_vistaBtn', () {
      expect(PermisosCheque.btnNuevoPanel, 'btnNuevoNRCH');
      expect(PermisosCheque.btnEliminarNota, 'btnEliminarNRCH');
    });

    test('«Nuevo» de los tres paneles es btnNuevoNRCH', () {
      expect(con({'btnNuevoNRCH'}).puedeRegistrarEnPaneles, isTrue);
      expect(con({'btnNuevoCH'}).puedeRegistrarEnPaneles, isFalse);
      expect(PermisosCheque.ninguno.puedeRegistrarEnPaneles, isFalse);
    });

    test('eliminar una nota es btnEliminarNRCH, aparte de «Nuevo»', () {
      expect(con({'btnEliminarNRCH'}).puedeEliminarNotaRemision, isTrue);
      expect(con({'btnEliminarNRCH'}).puedeRegistrarEnPaneles, isFalse);
      expect(con({'btnNuevoNRCH'}).puedeEliminarNotaRemision, isFalse);
    });

    test('el administrador pasa siempre', () {
      final admin = con({}, admin: true);
      expect(admin.puedeRegistrarEnPaneles, isTrue);
      expect(admin.puedeEliminarNotaRemision, isTrue);
    });

    test('no dependen del estado del cheque: no hay parametro de estado', () {
      // En el legacy «Nuevo» se dibuja con el cheque cerrado y el estado de
      // `esAutorizadoB` esta comentado. Son getters, no funciones del estado.
      final p = con({'btnNuevoNRCH', 'btnEliminarNRCH'});
      expect(p.puedeRegistrarEnPaneles, isTrue);
      expect(p.puedeEliminarNotaRemision, isTrue);
    });
  });
}
