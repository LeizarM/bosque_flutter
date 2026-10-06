import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/utils/reglas_pdf_cheque.dart';

/// Lo que la pantalla comprueba del PDF antes de enviarlo: las reglas del legacy
/// (solo .pdf, menos de 2 MB) y los textos que dicen que paso y que hacer.
void main() {
  group('errorDeArchivoPdfCheque', () {
    String? error(String nombre, int tamano) =>
        errorDeArchivoPdfCheque(nombre: nombre, tamanoBytes: tamano);

    test('un PDF dentro del limite sirve', () {
      expect(error('factura.pdf', 120000), isNull);
      expect(error('factura.pdf', 1), isNull);
    });

    test('el limite es el del legacy: 2.010.000 bytes, inclusive', () {
      expect(maxBytesPdfCheque, 2010000);
      expect(error('a.pdf', 2010000), isNull);
      expect(error('a.pdf', 2010001), isNotNull);
    });

    test('la extension no distingue mayusculas', () {
      for (final n in ['A.PDF', 'a.Pdf', 'a.pDF', '  a.pdf  ']) {
        expect(error(n, 100), isNull, reason: n);
      }
    });

    test('lo que no es .pdf dice cual es el archivo y que hacer', () {
      final m = error('contrato.docx', 100)!;
      expect(m, contains('«contrato.docx»'));
      expect(m, contains('no es un PDF'));
      expect(m, contains('.pdf'));
      // Un nombre que solo contiene «pdf» o lo tiene en medio tampoco sirve.
      expect(error('pdf', 100), isNotNull);
      expect(error('a.pdf.exe', 100), isNotNull);
      expect(error('a.pdf.txt', 100), isNotNull);
      expect(error('sin_extension', 100), isNotNull);
    });

    test('un archivo vacio no se envia: borraria el anterior', () {
      final m = error('vacio.pdf', 0)!;
      expect(m, contains('«vacio.pdf»'));
      expect(m, contains('vacío'));
      expect(m, contains('0 bytes'));
    });

    test('lo muy pesado dice cuanto pesa, el limite en MB y que hacer', () {
      final m = error('escaneo.pdf', 3400000)!;
      expect(m, contains('«escaneo.pdf»'));
      expect(m, contains('3,4 MB'));
      expect(m, contains('el límite es 2,0 MB'));
      expect(m, contains('Comprímelo'));
    });

    test('con un decimal el archivo y el limite no se ven iguales', () {
      // 2.044.000 y el tope de 2.010.000 son «2,0 MB» con un decimal: el mensaje
      // «pesa 2,0 MB y el limite es 2,0 MB» no explicaria nada.
      final m = error('a.pdf', 2044000)!;
      expect(m, contains('2,04 MB'));
      expect(m, contains('2,01 MB'));
      expect(m, isNot(contains('2,0 MB')));

      // Y si ni con dos decimales: tres.
      final n = error('a.pdf', 2011000)!;
      expect(n, contains('2,011 MB'));
      expect(n, contains('2,010 MB'));

      // Y si ni con tres, bytes.
      final b = error('a.pdf', 2010001)!;
      expect(b, contains('2010001 bytes'));
      expect(b, contains('2010000 bytes'));
    });

    test('el orden es el del legacy: primero que sea PDF y despues su peso', () {
      // Un .docx enorme se rechaza por no ser PDF, no por su peso.
      expect(error('a.docx', 9000000), contains('no es un PDF'));
      // Y uno vacio que no es PDF, por no ser PDF.
      expect(error('a.txt', 0), contains('no es un PDF'));
    });

    test('un nombre vacio no deja el mensaje con comillas vacias', () {
      expect(error('   ', 100), contains('«sin nombre»'));
    });
  });

  group('textoTamanoPdf', () {
    test('bytes, KB y MB, con coma decimal', () {
      expect(textoTamanoPdf(0), '0 bytes');
      expect(textoTamanoPdf(1), '1 byte');
      expect(textoTamanoPdf(850), '850 bytes');
      expect(textoTamanoPdf(1000), '1 KB');
      expect(textoTamanoPdf(120345), '120 KB');
      expect(textoTamanoPdf(999400), '999 KB');
      expect(textoTamanoPdf(1000000), '1,0 MB');
      expect(textoTamanoPdf(1460000), '1,5 MB');
      expect(textoTamanoPdf(2010000), '2,0 MB');
    });

    test('lo que redondea a 1000 KB se lee en megabytes', () {
      expect(textoTamanoPdf(999600), '1,0 MB');
    });
  });

  group('tamanosParaExceso', () {
    test('siempre distingue al archivo del limite', () {
      for (final bytes in [2010001, 2011000, 2044000, 2500000, 9999999]) {
        final t = tamanosParaExceso(bytes);
        expect(t.archivo, isNot(t.limite), reason: '$bytes');
      }
    });
  });
}
