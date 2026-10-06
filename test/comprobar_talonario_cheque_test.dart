import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/utils/comprobar_talonario_cheque.dart';

/// Cuando se le pregunta al servidor por el par talonario / recibo: solo si hay
/// algo que comprobar y los dos ya cumplen el formato que muestra el formulario.
void main() {
  test('la espera desde la ultima tecla es de 600 ms', () {
    expect(esperaComprobarTalonario, const Duration(milliseconds: 600));
  });

  group('debeComprobarTalonario', () {
    // (talonario, recibo, esperado, por que)
    final casos = <(String, String, bool, String)>[
      // Hay un par real.
      ('ER1076', '3752', true, 'el caso real'),
      ('A', '1', true, 'el minimo'),
      ('ER 1076', '37 52', true, 'letras, numeros y espacios'),
      ('ER1076', "3752'", true, 'el recibo admite apostrofe'),
      ('0123', '0456', true, 'ceros a la izquierda no son «0»'),
      ('00', '5', true, '«00» no es «0»: el legacy compara exacto'),
      ('7', '00', true, '«00» no es «0» tampoco en el recibo'),
      ('a' * 25, '9' * 25, true, 'el largo maximo, 25'),

      // Vacios.
      ('', '', false, 'los dos vacios'),
      ('ER1076', '', false, 'recibo vacio'),
      ('', '3752', false, 'talonario vacio'),
      ('   ', '3752', false, 'talonario de solo espacios'),
      ('ER1076', '   ', false, 'recibo de solo espacios'),

      // «0» = no hay nada que mirar en la base.
      ('0', '0', false, 'los dos en 0'),
      ('ER1076', '0', false, 'recibo 0: lo dejo el cliente'),
      ('0', '3752', false, 'talonario 0'),
      (' 0 ', '3752', false, 'el 0 con espacios se recorta antes'),
      ('ER1076', ' 0', false, 'el recibo 0 con espacios tambien'),

      // Formato invalido: el campo ya muestra su propio error.
      ('ER-1076', '3752', false, 'el guion no entra en el talonario'),
      ('ER/1076', '3752', false, 'la barra no entra en el talonario'),
      ('ER1076', '37/52', false, 'la barra no entra en el recibo'),
      ('ER1076', '3752.5', false, 'el punto no entra en el recibo'),
      ('ÑAndu', '3752', false, 'las letras con acento no entran'),
      ('a' * 26, '3752', false, 'talonario de mas de 25'),
      ('ER1076', '9' * 26, false, 'recibo de mas de 25'),
    ];

    for (final (talonario, recibo, esperado, motivo) in casos) {
      test('«$talonario» / «$recibo» -> $esperado ($motivo)', () {
        expect(debeComprobarTalonario(talonario, recibo), esperado);
      });
    }

    test('recorta los espacios de los bordes en los dos textos', () {
      expect(debeComprobarTalonario('  ER1076  ', '  3752  '), isTrue);
    });
  });
}
