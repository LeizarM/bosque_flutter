import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/models/pdf_cheque_estado_model.dart';
import 'package:bosque_flutter/data/models/pdf_cheque_subida_model.dart';
import 'package:bosque_flutter/data/repositories/cheques_impl.dart';
import 'package:bosque_flutter/domain/entities/pdf_cheque_estado_entity.dart';

/// El documento PDF del cheque contra el cable: un adaptador de Dio falso
/// responde con la forma del contrato y anota lo que de verdad salio (ruta,
/// cuerpo JSON o el multipart armado).
///
/// Cubre lo que el dialogo no puede ver: que cada metodo pegue a su endpoint, que
/// el archivo viaje como multipart con `codCheque` como texto y el PDF en la
/// parte `archivo`, que el 204 sea «sin archivo» y no un error y que el mensaje
/// de un 400 llegue completo. Contra un repositorio falso: nunca contra el
/// servidor.
void main() {
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  late _Adaptador cable;
  late ChequesImpl repo;

  setUp(() {
    cable = _Adaptador();
    repo = ChequesImpl();
    // El cliente es un singleton: sin interceptores (leen el token del almacen
    // seguro) y con el adaptador falso. Solo vale para esta prueba.
    repo.dio.interceptors.clear();
    repo.dio.httpClientAdapter = cable;
  });

  Map<String, dynamic> envelope(Object? data, {int status = 200}) => {
    'message': 'ok',
    'data': data,
    'status': status,
  };

  final pdf = Uint8List.fromList([
    ...utf8.encode('%PDF-1.4\n'),
    for (var i = 0; i < 200; i++) i % 256,
  ]);

  group('endpoints', () {
    test('cada constante es la ruta del contrato', () {
      expect(AppConstants.chqPdfEstado, '/cheque/pdf/estado');
      expect(AppConstants.chqPdfSubir, '/cheque/pdf/subir');
      expect(AppConstants.chqPdfDescargar, '/cheque/pdf/descargar');
    });
  });

  group('estadoPdf', () {
    test('ruta, cuerpo {codCheque} sin usuario y estado leido', () async {
      cable.responde(
        200,
        envelope({
          'existe': true,
          'nombreArchivo': '18129.pdf',
          'tamanoBytes': 120345,
          'fechaModificacion': '2026-10-03T14:22:10',
        }),
      );
      final e = await repo.estadoPdf(BigInt.from(18129));

      expect(cable.ultima.ruta, '/cheque/pdf/estado');
      expect(cable.ultima.cuerpo, {'codCheque': 18129});
      expect(e.existe, isTrue);
      expect(e.nombreArchivo, '18129.pdf');
      expect(e.tamanoBytes, 120345);
      expect(e.fechaModificacion, DateTime(2026, 10, 3, 14, 22, 10));
    });

    test('sin archivo: existe false, tamano y fecha nulos', () async {
      cable.responde(
        200,
        envelope({
          'existe': false,
          'nombreArchivo': '18129.pdf',
          'tamanoBytes': null,
          'fechaModificacion': null,
        }),
      );
      final e = await repo.estadoPdf(BigInt.from(18129));
      expect(e.existe, isFalse);
      expect(e.tamanoBytes, isNull);
      expect(e.fechaModificacion, isNull);
    });

    test('un 204 es «sin archivo», no un error', () async {
      cable.responde(204, null);
      final e = await repo.estadoPdf(BigInt.from(1));
      expect(e.existe, isFalse);
    });

    test('un data nulo tambien es «sin archivo»', () async {
      cable.responde(200, envelope(null));
      expect((await repo.estadoPdf(BigInt.from(1))).existe, isFalse);
    });

    test('la fecha tambien se lee con espacio en vez de T', () async {
      cable.responde(
        200,
        envelope({
          'existe': true,
          'nombreArchivo': '7.pdf',
          'tamanoBytes': 10,
          'fechaModificacion': '2026-10-03 14:22:10',
        }),
      );
      final e = await repo.estadoPdf(BigInt.from(7));
      expect(e.fechaModificacion, DateTime(2026, 10, 3, 14, 22, 10));
    });

    test('un 400 llega con el mensaje del backend', () async {
      cable.responde(400, {
        'message': 'No existe el cheque 18129.',
        'data': null,
        'status': 400,
      });
      await expectLater(
        repo.estadoPdf(BigInt.from(18129)),
        throwsA(
          predicate((e) => e.toString() == 'Exception: No existe el cheque 18129.'),
        ),
      );
    });
  });

  group('subirPdf', () {
    test('multipart: codCheque como texto y el PDF en la parte «archivo»', () async {
      // El servidor responde 200 (no 201) con su mensaje en `message`.
      cable.responde(200, {
        'message': 'PDF del cheque guardado.',
        'data': {
          'nombreArchivo': '18129.pdf',
          'tamanoBytes': pdf.length,
          'reemplazo': false,
        },
        'status': 200,
      });
      final r = await repo.subirPdf(BigInt.from(18129), pdf, 'Factura 7.pdf');

      expect(cable.ultima.ruta, '/cheque/pdf/subir');
      expect(cable.ultima.tipoContenido, startsWith('multipart/form-data'));

      final f = cable.ultima.formulario!;
      // El id es una parte de texto.
      expect(f.fields.map((e) => (e.key, e.value)).toList(), [
        ('codCheque', '18129'),
      ]);
      // Y el archivo, la parte «archivo», con el nombre elegido y tipo PDF.
      expect(f.files, hasLength(1));
      expect(f.files.single.key, 'archivo');
      expect(f.files.single.value.filename, 'Factura 7.pdf');
      expect(f.files.single.value.contentType.toString(), 'application/pdf');
      expect(f.files.single.value.length, pdf.length);

      // Los bytes del PDF viajan enteros, sin transformar.
      expect(_contiene(cable.ultima.cuerpoCrudo, pdf), isTrue);

      expect(r.nombreArchivo, '18129.pdf');
      expect(r.tamanoBytes, pdf.length);
      expect(r.reemplazo, isFalse);
    });

    test('la parte archivo siempre lleva un nombre que termina en .pdf', () async {
      cable.responde(
        200,
        envelope({'nombreArchivo': '1.pdf', 'tamanoBytes': 1, 'reemplazo': false}),
      );
      // Sin nombre de archivo el servidor trata la parte como texto: el nombre
      // viaja recortado y, si llegara vacio, se arma con el codigo del cheque.
      await repo.subirPdf(BigInt.from(18129), pdf, '  SCAN 3.PDF ');
      expect(cable.ultima.formulario!.files.single.value.filename, 'SCAN 3.PDF');
      expect(
        utf8.decode(cable.ultima.cuerpoCrudo, allowMalformed: true),
        contains('filename="SCAN 3.PDF"'),
      );

      await repo.subirPdf(BigInt.from(18129), pdf, '   ');
      expect(cable.ultima.formulario!.files.single.value.filename, '18129.pdf');
    });

    test('ninguna parte lleva el usuario de auditoria', () async {
      cable.responde(
        201,
        envelope({'nombreArchivo': '1.pdf', 'tamanoBytes': 1, 'reemplazo': true}),
      );
      await repo.subirPdf(BigInt.one, pdf, 'a.pdf');
      final texto = utf8.decode(cable.ultima.cuerpoCrudo, allowMalformed: true);
      expect(texto, isNot(contains('audUsuario')));
    });

    test('el servidor dice si reemplazo uno anterior', () async {
      cable.responde(
        200,
        envelope({
          'nombreArchivo': '18129.pdf',
          'tamanoBytes': 5,
          'reemplazo': true,
        }),
      );
      final r = await repo.subirPdf(BigInt.from(18129), pdf, 'a.pdf');
      expect(r.reemplazo, isTrue);
    });

    test('informa el avance de lo enviado', () async {
      cable.responde(
        201,
        envelope({'nombreArchivo': '1.pdf', 'tamanoBytes': 1, 'reemplazo': false}),
      );
      final avances = <(int, int)>[];
      await repo.subirPdf(
        BigInt.one,
        pdf,
        'a.pdf',
        alProgreso: (e, t) => avances.add((e, t)),
      );
      expect(avances, isNotEmpty);
      // El ultimo avance es el total.
      expect(avances.last.$1, avances.last.$2);
    });

    test('un 400 llega con su mensaje completo, varias lineas incluidas', () async {
      cable.responde(400, {
        'message':
            'Solo se permiten archivos PDF.\nElige un archivo con extension .pdf.',
        'data': null,
        'status': 400,
      });
      await expectLater(
        repo.subirPdf(BigInt.one, pdf, 'a.pdf'),
        throwsA(
          predicate(
            (e) =>
                e.toString() ==
                'Exception: Solo se permiten archivos PDF.\n'
                    'Elige un archivo con extension .pdf.',
          ),
        ),
      );
    });

    test('la carpeta sin montar se dice completa, tal cual la redacta el servidor', () async {
      cable.responde(400, {
        'message':
            'La carpeta de los PDF de cheques no está disponible. '
            'Avisa a Sistemas.',
        'data': null,
        'status': 400,
      });
      await expectLater(
        repo.subirPdf(BigInt.one, pdf, 'a.pdf'),
        throwsA(
          predicate(
            (e) =>
                e.toString() ==
                'Exception: La carpeta de los PDF de cheques no está disponible. '
                    'Avisa a Sistemas.',
          ),
        ),
      );
    });

    test('un 403 se avisa con el mensaje del backend', () async {
      cable.responde(403, {
        'message': 'No tiene permiso para esta accion.',
        'data': null,
        'status': 403,
      });
      await expectLater(
        repo.subirPdf(BigInt.one, pdf, 'a.pdf'),
        throwsA(
          predicate(
            (e) => e.toString().contains('No tiene permiso para esta accion.'),
          ),
        ),
      );
    });

    test('un 413 sin cuerpo de negocio dice que el archivo pesa demasiado', () async {
      cable.responde(413, null);
      await expectLater(
        repo.subirPdf(BigInt.one, pdf, 'a.pdf'),
        throwsA(
          predicate((e) => e.toString().contains('pesa demasiado')),
        ),
      );
    });

    test('una respuesta sin data no se toma por exito', () async {
      cable.responde(200, envelope(null));
      await expectLater(
        repo.subirPdf(BigInt.one, pdf, 'a.pdf'),
        throwsA(predicate((e) => e.toString().contains('No se pudo cargar'))),
      );
    });
  });

  group('descargarPdf', () {
    test('ruta, cuerpo {codCheque} y los bytes tal cual', () async {
      cable.responde(200, pdf);
      final bytes = await repo.descargarPdf(BigInt.from(18129));
      expect(cable.ultima.ruta, '/cheque/pdf/descargar');
      expect(cable.ultima.cuerpo, {'codCheque': 18129});
      expect(bytes, pdf);
    });

    test('sin archivo, el mensaje del servidor llega completo', () async {
      // El PDF se pide como bytes: el JSON de error llega sin interpretar y el
      // mensaje se rescata igual.
      cable.responde(400, {
        'message': 'No se encontro el archivo PDF del cheque 18129.',
        'data': null,
        'status': 400,
      });
      await expectLater(
        repo.descargarPdf(BigInt.from(18129)),
        throwsA(
          predicate(
            (e) =>
                e.toString() ==
                'Exception: No se encontro el archivo PDF del cheque 18129.',
          ),
        ),
      );
    });
  });

  group('modelos', () {
    test('estado: tolerante con claves ausentes y con tipos raros', () {
      final m = PdfChequeEstadoModel.fromJson({
        'existe': 'true',
        'tamanoBytes': 12.0,
        'fechaModificacion': 'no es una fecha',
      });
      expect(m.existe, isTrue);
      expect(m.nombreArchivo, '');
      expect(m.tamanoBytes, 12);
      expect(m.fechaModificacion, isNull);
      // Solo un true explicito cuenta como archivo.
      expect(PdfChequeEstadoModel.fromJson({}).existe, isFalse);
      expect(PdfChequeEstadoModel.fromJson({'existe': 1}).existe, isFalse);
    });

    test('estado: ida y vuelta entidad -> modelo -> json -> modelo', () {
      final e = PdfChequeEstadoEntity(
        existe: true,
        nombreArchivo: '9.pdf',
        tamanoBytes: 99,
        fechaModificacion: DateTime(2026, 10, 3, 14, 22, 10),
      );
      final json = PdfChequeEstadoModel.fromEntity(e).toJson();
      final otra = PdfChequeEstadoModel.fromJson(json).toEntity();
      expect(otra.existe, isTrue);
      expect(otra.nombreArchivo, '9.pdf');
      expect(otra.tamanoBytes, 99);
      expect(otra.fechaModificacion, e.fechaModificacion);
    });

    test('subida: lee el contrato y hace ida y vuelta', () {
      final m = PdfChequeSubidaModel.fromJson({
        'nombreArchivo': '5.pdf',
        'tamanoBytes': 1234,
        'reemplazo': true,
      });
      expect(m.toEntity().nombreArchivo, '5.pdf');
      expect(m.toEntity().tamanoBytes, 1234);
      expect(m.toEntity().reemplazo, isTrue);
      expect(PdfChequeSubidaModel.fromEntity(m.toEntity()).toJson(), {
        'nombreArchivo': '5.pdf',
        'tamanoBytes': 1234,
        'reemplazo': true,
      });
    });
  });
}

/// ¿[x] contiene la secuencia [y]?
bool _contiene(List<int> x, List<int> y) {
  if (y.isEmpty) return true;
  for (var i = 0; i + y.length <= x.length; i++) {
    var igual = true;
    for (var j = 0; j < y.length; j++) {
      if (x[i + j] != y[j]) {
        igual = false;
        break;
      }
    }
    if (igual) return true;
  }
  return false;
}

/// Una peticion tal como salio por el cable.
class _Peticion {
  _Peticion({
    required this.ruta,
    required this.cuerpo,
    required this.cuerpoCrudo,
    required this.formulario,
    required this.tipoContenido,
  });

  final String ruta;

  /// El JSON enviado; null si no era JSON (un multipart).
  final Object? cuerpo;

  /// Los bytes que salieron por el cable.
  final List<int> cuerpoCrudo;

  /// El `FormData` armado, si la peticion era multipart.
  final FormData? formulario;
  final String? tipoContenido;
}

/// Responde siempre con lo ultimo que se le indico con [responde] y anota las
/// peticiones que recibe.
class _Adaptador implements HttpClientAdapter {
  final List<_Peticion> peticiones = [];
  ({int estado, Object? cuerpo}) _respuesta = (estado: 200, cuerpo: null);

  _Peticion get ultima => peticiones.last;

  void responde(int estado, Object? cuerpo) =>
      _respuesta = (estado: estado, cuerpo: cuerpo);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final b in requestStream) {
        bytes.addAll(b);
      }
    }
    final esJson =
        options.data is! FormData && bytes.isNotEmpty;
    peticiones.add(
      _Peticion(
        ruta: options.path,
        cuerpo: esJson ? jsonDecode(utf8.decode(bytes)) : null,
        cuerpoCrudo: bytes,
        formulario: options.data is FormData ? options.data as FormData : null,
        tipoContenido: options.contentType,
      ),
    );

    final r = _respuesta;
    // Bytes = un PDF: se entregan tal cual, con su tipo.
    if (r.cuerpo is Uint8List) {
      return ResponseBody.fromBytes(
        r.cuerpo! as Uint8List,
        r.estado,
        headers: {
          Headers.contentTypeHeader: ['application/pdf'],
        },
      );
    }
    return ResponseBody.fromString(
      r.cuerpo == null ? '' : jsonEncode(r.cuerpo),
      r.estado,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
