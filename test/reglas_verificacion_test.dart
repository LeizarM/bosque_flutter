import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/utils/reglas_verificacion.dart';

/// La observacion de una verificacion: la clase de caracteres del legacy
/// (`^[a-zA-Z0-9  ' '',''.' ]{0,50}`), interpretada como lo que es. Lo mismo que
/// comprueba el servidor (`ReglasVerificacionTest`); aqui solo avisa antes de
/// enviar.
void main() {
  String? error(String v) => ReglasVerificacion.errorObservacion(v);

  group('observacion', () {
    test('vacia vale (el campo no es obligatorio)', () {
      expect(error(''), isNull);
      expect(ReglasVerificacion.errorObservacion(null), isNull);
    });

    test('letras sin tilde, numeros, espacio, apostrofe, coma y punto valen', () {
      for (final v in [
        'Cobrado',
        'Deposito OK, banco 3.',
        "D'Angelo 15",
        'A  B',
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz 0123456789',
      ].where((x) => x.length <= 50)) {
        expect(error(v), isNull, reason: '«$v»');
      }
    });

    test('50 caracteres valen y 51 no', () {
      expect(error('x' * 50), isNull);
      final m = error('x' * 51);
      expect(m, isNotNull);
      expect(m, contains('demasiado larga (51 caracteres)'));
    });

    test('tilde, ñ, punto y coma, dos puntos, guion, barra, parentesis y salto de linea no valen', () {
      for (final v in [
        'Depósito',
        'año',
        'a;b',
        'a:b',
        'a-b',
        'a/b',
        '(x)',
        'a\nb',
        'a\tb',
        'ÁÉÍÓÚ',
        'a_b',
        'a#b',
        'a%b',
      ]) {
        expect(error(v), isNotNull, reason: '«${v.replaceAll('\n', r'\n')}»');
      }
    });

    test('el mensaje nombra exactamente los caracteres que sobran, sin repetirlos', () {
      final m = error('Depósito del año; ñandú')!;
      expect(m, contains('caracteres que no se aceptan'));
      expect(m, contains('«ó»'));
      expect(m, contains('«ñ»'));
      expect(m, contains('«;»'));
      expect(m, contains('«ú»'));
      // Los que valen no se nombran como sobrantes.
      expect(m, isNot(contains('«D»')));
      expect(m, isNot(contains('«e»')));
      expect(m, contains('Solo acepta letras sin tilde ni ñ'));
      expect('«ó»'.allMatches(m), hasLength(1), reason: 'ó aparece dos veces en el texto y se nombra una');
    });

    test('un espacio y un salto de linea se nombran con palabras, no como un hueco', () {
      final m = error('a\nb\tc')!;
      expect(m, contains('salto de línea'));
      expect(m, contains('tabulación'));
    });

    test('con mas de seis caracteres distintos se resume con puntos suspensivos', () {
      final m = error('ñáéíóúü#%&')!;
      expect(m, contains('…'));
    });

    test('caracter por caracter: se acepta exactamente [a-zA-Z0-9 \',.] y nada mas', () {
      final validos = RegExp(r"^[a-zA-Z0-9 ',.]$");
      for (var cp = 0; cp < 0x250; cp++) {
        final c = String.fromCharCode(cp);
        expect(
          error(c) == null,
          validos.hasMatch(c),
          reason: 'U+${cp.toRadixString(16)} «$c»',
        );
        // El mensaje y la regla coinciden: un caracter sobrante se nombra.
        expect(
          ReglasVerificacion.caracteresNoAceptados(c).isEmpty,
          validos.hasMatch(c),
          reason: 'U+${cp.toRadixString(16)}',
        );
      }
    });

    test('el largo maximo es el de la columna', () {
      expect(ReglasVerificacion.largoMaximoObservacion, 50);
    });
  });
}
