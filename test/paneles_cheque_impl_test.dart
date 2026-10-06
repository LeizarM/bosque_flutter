import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/models/nota_remision_cheque_model.dart';
import 'package:bosque_flutter/data/models/postergacion_model.dart';
import 'package:bosque_flutter/data/models/transaccion_bancaria_model.dart';
import 'package:bosque_flutter/data/repositories/cheques_impl.dart';
import 'package:bosque_flutter/domain/entities/nota_remision_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/postergacion_entity.dart';
import 'package:bosque_flutter/domain/entities/transaccion_bancaria_entity.dart';

/// Los tres paneles del detalle (notas de remision, transacciones bancarias y
/// postergaciones, con el PDF de la postergacion) contra el cable: un adaptador de
/// Dio falso responde con la forma del contrato (`API_CHEQUES.md`, «Paneles del
/// detalle») y anota lo que de verdad salio (ruta, cuerpo JSON o el multipart
/// armado).
///
/// Cubre lo que los dialogos no pueden ver: que cada metodo pegue a su endpoint,
/// que el 204 sea lista vacia y no error, que ningun cuerpo lleve el usuario de
/// auditoria, que el PDF viaje como multipart con `codPostergacion` como texto y
/// que el mensaje de un 400 llegue completo.
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

  final cheque = BigInt.from(18129);
  final pdf = Uint8List.fromList([
    ...utf8.encode('%PDF-1.4\n'),
    for (var i = 0; i < 200; i++) i % 256,
  ]);

  group('endpoints: cada constante es la ruta del contrato', () {
    test('notas, transacciones y postergaciones', () {
      expect(AppConstants.chqNotaRemisionListar, '/cheque/nota-remision/listar');
      expect(
        AppConstants.chqNotaRemisionRegistrar,
        '/cheque/nota-remision/registrar',
      );
      expect(
        AppConstants.chqNotaRemisionEliminar,
        '/cheque/nota-remision/eliminar',
      );
      expect(AppConstants.chqTransaccionListar, '/cheque/transaccion/listar');
      expect(
        AppConstants.chqTransaccionRegistrar,
        '/cheque/transaccion/registrar',
      );
      expect(
        AppConstants.chqTransaccionEliminar,
        '/cheque/transaccion/eliminar',
      );
      expect(AppConstants.chqPostergacionListar, '/cheque/postergacion/listar');
      expect(
        AppConstants.chqPostergacionRegistrar,
        '/cheque/postergacion/registrar',
      );
      expect(
        AppConstants.chqPostergacionEliminar,
        '/cheque/postergacion/eliminar',
      );
    });

    test('el PDF de la postergacion', () {
      expect(
        AppConstants.chqPostergacionPdfEstado,
        '/cheque/postergacion/pdf/estado',
      );
      expect(
        AppConstants.chqPostergacionPdfSubir,
        '/cheque/postergacion/pdf/subir',
      );
      expect(
        AppConstants.chqPostergacionPdfDescargar,
        '/cheque/postergacion/pdf/descargar',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // NOTAS DE REMISION
  // ═══════════════════════════════════════════════════════════════════════

  group('notas de remision', () {
    test('listar: ruta, cuerpo {codCheque} y filas leidas', () async {
      cable.responde(
        200,
        envelope([
          {
            'fila': 1,
            'codCheque': 18129,
            'notaRemision': '262211881',
            'nroFactura': 1856,
            'fechaFactura': '2026-08-31',
            'audUsuario': 66,
            'audFecha': '2026-09-01T09:05:17',
          },
          {
            'fila': 2,
            'codCheque': 18129,
            'notaRemision': '262211820',
            'nroFactura': 1795,
            'fechaFactura': '2026-08-19',
            'audUsuario': null,
            'audFecha': null,
          },
        ]),
      );
      final notas = await repo.listarNotasRemision(cheque);

      expect(cable.ultima.ruta, '/cheque/nota-remision/listar');
      expect(cable.ultima.cuerpo, {'codCheque': 18129});
      expect(notas, hasLength(2));
      expect(notas.first.fila, 1);
      expect(notas.first.codCheque, cheque);
      expect(notas.first.notaRemision, '262211881');
      expect(notas.first.nroFactura, 1856);
      expect(notas.first.fechaFactura, DateTime(2026, 8, 31));
      expect(notas.first.audUsuario, 66);
      expect(notas.first.audFecha, DateTime(2026, 9, 1, 9, 5, 17));
      expect(notas.last.audUsuario, isNull);
      expect(notas.last.audFecha, isNull);
    });

    test('listar: un 204 es lista vacia, no un error', () async {
      cable.responde(204, null);
      expect(await repo.listarNotasRemision(cheque), isEmpty);
    });

    test('registrar: cuerpo exacto, sin usuario ni fila', () async {
      cable.responde(201, envelope(1, status: 201));
      await repo.registrarNotaRemision(
        NotaRemisionChequeEntity(
          codCheque: cheque,
          notaRemision: '262211881',
          nroFactura: 1856,
          fechaFactura: DateTime(2026, 8, 31, 10, 30),
          audUsuario: 99,
          fila: 7,
        ),
      );

      expect(cable.ultima.ruta, '/cheque/nota-remision/registrar');
      expect(cable.ultima.cuerpo, {
        'codCheque': 18129,
        'notaRemision': '262211881',
        'nroFactura': 1856,
        'fechaFactura': '2026-08-31',
      });
      expect(jsonEncode(cable.ultima.cuerpo), isNot(contains('audUsuario')));
    });

    test('eliminar: cuerpo {codCheque, notaRemision} y cuantas filas elimino', () async {
      cable.responde(201, envelope(2, status: 201));
      final n = await repo.eliminarNotaRemision(
        codCheque: cheque,
        notaRemision: '262211820',
      );

      expect(cable.ultima.ruta, '/cheque/nota-remision/eliminar');
      expect(cable.ultima.cuerpo, {
        'codCheque': 18129,
        'notaRemision': '262211820',
      });
      expect(n, 2);
    });

    test('un 400 llega con su mensaje completo, varias lineas incluidas', () async {
      cable.responde(400, {
        'message':
            'La nota de remisión «12A» no es válida: tiene caracteres que no se aceptan («A»).\n'
            'Falta el número de factura.',
        'data': null,
        'status': 400,
      });
      await expectLater(
        repo.registrarNotaRemision(
          NotaRemisionChequeEntity(
            codCheque: cheque,
            notaRemision: '12A',
            nroFactura: 0,
            fechaFactura: DateTime(2026, 8, 31),
          ),
        ),
        throwsA(
          predicate(
            (e) =>
                e.toString() ==
                'Exception: La nota de remisión «12A» no es válida: tiene '
                    'caracteres que no se aceptan («A»).\n'
                    'Falta el número de factura.',
          ),
        ),
      );
    });

    test('un 403 trae el motivo del permiso, completo', () async {
      cable.responde(403, {
        'message':
            'No tienes permiso para eliminar notas de remisión de un cheque. '
            'Tu usuario no tiene asignado el botón btnEliminarNRCH; pídele al '
            'administrador que te lo asigne.',
        'data': null,
        'status': 403,
      });
      await expectLater(
        repo.eliminarNotaRemision(codCheque: cheque, notaRemision: '262211881'),
        throwsA(
          predicate((e) => e.toString().contains('btnEliminarNRCH')),
        ),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // TRANSACCIONES BANCARIAS
  // ═══════════════════════════════════════════════════════════════════════

  group('transacciones bancarias', () {
    test('listar: ruta, cuerpo y filas con el nombre del banco', () async {
      cable.responde(
        200,
        envelope([
          {
            'fila': 1,
            'codCheque': 18129,
            'nroTransaccion': 'TT26216QW3N3',
            'codBanco': 2,
            'fechaTransaccion': '2026-08-04',
            'datoBanco': 'BANCO MERCANTIL SANTA CRUZ',
          },
        ]),
      );
      final lista = await repo.listarTransacciones(cheque);

      expect(cable.ultima.ruta, '/cheque/transaccion/listar');
      expect(cable.ultima.cuerpo, {'codCheque': 18129});
      expect(lista.single.fila, 1);
      expect(lista.single.nroTransaccion, 'TT26216QW3N3');
      expect(lista.single.codBanco, 2);
      expect(lista.single.fechaTransaccion, DateTime(2026, 8, 4));
      expect(lista.single.datoBanco, 'BANCO MERCANTIL SANTA CRUZ');
      // El listado no trae al usuario ni cuando se registro.
      expect(lista.single.audUsuario, isNull);
      expect(lista.single.audFecha, isNull);
    });

    test('listar: un 204 es lista vacia', () async {
      cable.responde(204, null);
      expect(await repo.listarTransacciones(cheque), isEmpty);
    });

    test('registrar: cuerpo exacto, sin usuario, sin fila y sin el nombre del banco', () async {
      cable.responde(201, envelope(1, status: 201));
      await repo.registrarTransaccion(
        TransaccionBancariaEntity(
          codCheque: cheque,
          nroTransaccion: 'TT26216QW3N3',
          codBanco: 2,
          fechaTransaccion: DateTime(2026, 8, 4),
          datoBanco: 'BANCO MERCANTIL SANTA CRUZ',
          audUsuario: 99,
          fila: 4,
        ),
      );

      expect(cable.ultima.ruta, '/cheque/transaccion/registrar');
      expect(cable.ultima.cuerpo, {
        'codCheque': 18129,
        'nroTransaccion': 'TT26216QW3N3',
        'codBanco': 2,
        'fechaTransaccion': '2026-08-04',
      });
    });

    test('eliminar: cuerpo {codCheque, nroTransaccion} y filas eliminadas', () async {
      cable.responde(201, envelope(1, status: 201));
      final n = await repo.eliminarTransaccion(
        codCheque: cheque,
        nroTransaccion: 'TT26216QW3N3',
      );
      expect(cable.ultima.ruta, '/cheque/transaccion/eliminar');
      expect(cable.ultima.cuerpo, {
        'codCheque': 18129,
        'nroTransaccion': 'TT26216QW3N3',
      });
      expect(n, 1);
    });

    test('un 400 llega con su mensaje', () async {
      cable.responde(400, {
        'message':
            'El número de transacción «AB1» es demasiado corto (3 caracteres).',
        'data': null,
        'status': 400,
      });
      await expectLater(
        repo.registrarTransaccion(
          TransaccionBancariaEntity(
            codCheque: cheque,
            nroTransaccion: 'AB1',
            codBanco: 2,
            fechaTransaccion: DateTime(2026, 8, 4),
          ),
        ),
        throwsA(predicate((e) => e.toString().contains('demasiado corto'))),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // POSTERGACIONES
  // ═══════════════════════════════════════════════════════════════════════

  group('postergaciones', () {
    test('listar: ruta, cuerpo y filas con tienePdf true, false y null', () async {
      cable.responde(
        200,
        envelope([
          {
            'fila': 1,
            'codPostergacion': 40,
            'codCheque': 18129,
            'fecha': '2025-10-30',
            'observacion': 'cambio de cheque 277',
            'nombreArchivo': '',
            'audUsuario': 30,
            'audFecha': '2025-10-30T16:52:19',
            'tienePdf': true,
          },
          {
            'fila': 2,
            'codPostergacion': 41,
            'codCheque': 18129,
            'fecha': '2025-11-02',
            'observacion': 'otra',
            'nombreArchivo': '',
            'tienePdf': false,
          },
          {
            'fila': 3,
            'codPostergacion': 42,
            'codCheque': 18129,
            'fecha': '2025-11-03',
            'observacion': 'sin carpeta',
            'nombreArchivo': '',
            'tienePdf': null,
          },
        ]),
      );
      final lista = await repo.listarPostergaciones(cheque);

      expect(cable.ultima.ruta, '/cheque/postergacion/listar');
      expect(cable.ultima.cuerpo, {'codCheque': 18129});
      expect(lista.map((p) => p.tienePdf).toList(), [true, false, null]);
      expect(lista.first.codPostergacion, BigInt.from(40));
      expect(lista.first.fecha, DateTime(2025, 10, 30));
      expect(lista.first.observacion, 'cambio de cheque 277');
      expect(lista.first.audFecha, DateTime(2025, 10, 30, 16, 52, 19));
    });

    test('listar: un 204 es lista vacia', () async {
      cable.responde(204, null);
      expect(await repo.listarPostergaciones(cheque), isEmpty);
    });

    test('registrar: cuerpo exacto y devuelve el codPostergacion', () async {
      cable.responde(201, envelope(8001, status: 201));
      final cod = await repo.registrarPostergacion(
        PostergacionEntity(
          codPostergacion: BigInt.zero,
          codCheque: cheque,
          fecha: DateTime(2026, 10, 3),
          observacion: 'Cliente envió carta\ny pidió tiempo.',
          audUsuario: 99,
        ),
      );

      expect(cable.ultima.ruta, '/cheque/postergacion/registrar');
      // Ni codPostergacion (lo genera el servidor), ni usuario, ni archivo.
      expect(cable.ultima.cuerpo, {
        'codCheque': 18129,
        'fecha': '2026-10-03',
        'observacion': 'Cliente envió carta\ny pidió tiempo.',
      });
      expect(cod, BigInt.from(8001));
    });

    test('eliminar: cuerpo {codCheque, codPostergacion}', () async {
      cable.responde(201, envelope(40, status: 201));
      final cod = await repo.eliminarPostergacion(
        codCheque: cheque,
        codPostergacion: BigInt.from(40),
      );
      expect(cable.ultima.ruta, '/cheque/postergacion/eliminar');
      expect(cable.ultima.cuerpo, {'codCheque': 18129, 'codPostergacion': 40});
      expect(cod, BigInt.from(40));
    });

    test('un 400: la postergacion de otro cheque llega con su motivo', () async {
      cable.responde(400, {
        'message': 'La postergación 40 no pertenece al cheque 18129.',
        'data': null,
        'status': 400,
      });
      await expectLater(
        repo.eliminarPostergacion(
          codCheque: cheque,
          codPostergacion: BigInt.from(40),
        ),
        throwsA(predicate((e) => e.toString().contains('no pertenece'))),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // PDF DE LA POSTERGACION
  // ═══════════════════════════════════════════════════════════════════════

  group('PDF de la postergacion', () {
    test('estado: ruta, cuerpo {codPostergacion} y estado leido', () async {
      cable.responde(
        200,
        envelope({
          'existe': true,
          'nombreArchivo': '40.pdf',
          'tamanoBytes': 96256,
          'fechaModificacion': '2026-10-03T14:22:10',
        }),
      );
      final e = await repo.estadoPdfPostergacion(BigInt.from(40));

      expect(cable.ultima.ruta, '/cheque/postergacion/pdf/estado');
      expect(cable.ultima.cuerpo, {'codPostergacion': 40});
      expect(e.existe, isTrue);
      expect(e.nombreArchivo, '40.pdf');
      expect(e.tamanoBytes, 96256);
      expect(e.fechaModificacion, DateTime(2026, 10, 3, 14, 22, 10));
    });

    test('estado: un 204 o un data nulo es «sin archivo»', () async {
      cable.responde(204, null);
      expect((await repo.estadoPdfPostergacion(BigInt.one)).existe, isFalse);
      cable.responde(200, envelope(null));
      expect((await repo.estadoPdfPostergacion(BigInt.one)).existe, isFalse);
    });

    test('estado: la carpeta sin montar llega con su aviso completo', () async {
      cable.responde(400, {
        'message':
            'La carpeta de los PDF de postergaciones no está configurada en el '
            'servidor (propiedad cheques.postergacion.pdf.dir, variable de '
            'entorno POSTERGACIONES_PDF_DIR). Avisa a sistemas.',
        'data': null,
        'status': 400,
      });
      await expectLater(
        repo.estadoPdfPostergacion(BigInt.from(40)),
        throwsA(
          predicate((e) => e.toString().contains('POSTERGACIONES_PDF_DIR')),
        ),
      );
    });

    test('subir: multipart con codPostergacion como texto y el PDF en «archivo»', () async {
      cable.responde(200, {
        'message': 'PDF de la postergación guardado.',
        'data': {
          'nombreArchivo': '40.pdf',
          'tamanoBytes': pdf.length,
          'reemplazo': false,
        },
        'status': 200,
      });
      final r = await repo.subirPdfPostergacion(
        BigInt.from(40),
        pdf,
        'Carta del cliente.pdf',
      );

      expect(cable.ultima.ruta, '/cheque/postergacion/pdf/subir');
      expect(cable.ultima.tipoContenido, startsWith('multipart/form-data'));

      final f = cable.ultima.formulario!;
      expect(f.fields.map((e) => (e.key, e.value)).toList(), [
        ('codPostergacion', '40'),
      ]);
      expect(f.files, hasLength(1));
      expect(f.files.single.key, 'archivo');
      expect(f.files.single.value.filename, 'Carta del cliente.pdf');
      expect(f.files.single.value.contentType.toString(), 'application/pdf');
      expect(f.files.single.value.length, pdf.length);
      expect(_contiene(cable.ultima.cuerpoCrudo, pdf), isTrue);

      expect(r.nombreArchivo, '40.pdf');
      expect(r.tamanoBytes, pdf.length);
      expect(r.reemplazo, isFalse);
    });

    test('subir: sin nombre de archivo se arma con el codigo; nunca lleva usuario', () async {
      cable.responde(
        200,
        envelope({'nombreArchivo': '40.pdf', 'tamanoBytes': 1, 'reemplazo': true}),
      );
      final r = await repo.subirPdfPostergacion(BigInt.from(40), pdf, '   ');
      expect(cable.ultima.formulario!.files.single.value.filename, '40.pdf');
      expect(r.reemplazo, isTrue);
      expect(
        utf8.decode(cable.ultima.cuerpoCrudo, allowMalformed: true),
        isNot(contains('audUsuario')),
      );
    });

    test('subir: informa el avance de lo enviado', () async {
      cable.responde(
        200,
        envelope({'nombreArchivo': '1.pdf', 'tamanoBytes': 1, 'reemplazo': false}),
      );
      final avances = <(int, int)>[];
      await repo.subirPdfPostergacion(
        BigInt.one,
        pdf,
        'a.pdf',
        alProgreso: (e, t) => avances.add((e, t)),
      );
      expect(avances, isNotEmpty);
      expect(avances.last.$1, avances.last.$2);
    });

    test('subir: un 400 llega completo y tal cual', () async {
      cable.responde(400, {
        'message':
            'El archivo pesa 2.350.000 bytes (2,35 MB) y debe ser de menos de '
            '2 MegaBytes.\nElige un PDF más liviano.',
        'data': null,
        'status': 400,
      });
      await expectLater(
        repo.subirPdfPostergacion(BigInt.from(40), pdf, 'a.pdf'),
        throwsA(
          predicate(
            (e) =>
                e.toString() ==
                'Exception: El archivo pesa 2.350.000 bytes (2,35 MB) y debe ser '
                    'de menos de 2 MegaBytes.\nElige un PDF más liviano.',
          ),
        ),
      );
    });

    test('subir: una respuesta sin data no se toma por exito', () async {
      cable.responde(200, envelope(null));
      await expectLater(
        repo.subirPdfPostergacion(BigInt.from(40), pdf, 'a.pdf'),
        throwsA(
          predicate(
            (e) => e.toString().contains('No se pudo cargar el PDF de la postergación'),
          ),
        ),
      );
    });

    test('descargar: ruta, cuerpo {codPostergacion} y los bytes tal cual', () async {
      cable.responde(200, pdf);
      final bytes = await repo.descargarPdfPostergacion(BigInt.from(40));
      expect(cable.ultima.ruta, '/cheque/postergacion/pdf/descargar');
      expect(cable.ultima.cuerpo, {'codPostergacion': 40});
      expect(bytes, pdf);
    });

    test('descargar: sin archivo, el mensaje del servidor llega completo', () async {
      cable.responde(400, {
        'message': 'No se encontró el archivo PDF de la postergación 40.',
        'data': null,
        'status': 400,
      });
      await expectLater(
        repo.descargarPdfPostergacion(BigInt.from(40)),
        throwsA(
          predicate(
            (e) =>
                e.toString() ==
                'Exception: No se encontró el archivo PDF de la postergación 40.',
          ),
        ),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // MODELOS
  // ═══════════════════════════════════════════════════════════════════════

  group('modelos', () {
    test('nota: tolerante con claves ausentes y ida y vuelta', () {
      final vacia = NotaRemisionChequeModel.fromJson({});
      expect(vacia.codCheque, BigInt.zero);
      expect(vacia.notaRemision, '');
      expect(vacia.nroFactura, 0);
      expect(vacia.fechaFactura, isNull);
      expect(vacia.fila, 0);

      final e = NotaRemisionChequeModel.fromJson({
        'fila': 3,
        'codCheque': 9,
        'notaRemision': '123456',
        'nroFactura': 77,
        'fechaFactura': '2026-10-03',
        'audUsuario': 5,
        'audFecha': '2026-10-03T08:00:00',
      }).toEntity();
      final json = NotaRemisionChequeModel.fromEntity(e).toJson();
      final otra = NotaRemisionChequeModel.fromJson(json).toEntity();
      expect(otra.notaRemision, '123456');
      expect(otra.nroFactura, 77);
      expect(otra.fechaFactura, DateTime(2026, 10, 3));
      expect(otra.fila, 3);
      expect(otra.audFecha, DateTime(2026, 10, 3, 8));
    });

    test('transaccion: tolerante con claves ausentes y ida y vuelta', () {
      final vacia = TransaccionBancariaModel.fromJson({});
      expect(vacia.nroTransaccion, '');
      expect(vacia.codBanco, 0);
      expect(vacia.fechaTransaccion, isNull);
      expect(vacia.datoBanco, '');

      final e = TransaccionBancariaModel.fromJson({
        'fila': 2,
        'codCheque': 9,
        'nroTransaccion': 'ABCDE',
        'codBanco': 7,
        'fechaTransaccion': '2026-10-03',
        'datoBanco': 'BANCO UNION',
      }).toEntity();
      final otra =
          TransaccionBancariaModel.fromJson(
            TransaccionBancariaModel.fromEntity(e).toJson(),
          ).toEntity();
      expect(otra.nroTransaccion, 'ABCDE');
      expect(otra.codBanco, 7);
      expect(otra.datoBanco, 'BANCO UNION');
      expect(otra.fila, 2);
    });

    test('postergacion: tienePdf distingue true, false y «no se sabe»', () {
      expect(PostergacionModel.fromJson({'tienePdf': true}).tienePdf, isTrue);
      expect(PostergacionModel.fromJson({'tienePdf': false}).tienePdf, isFalse);
      expect(PostergacionModel.fromJson({'tienePdf': 'true'}).tienePdf, isTrue);
      expect(PostergacionModel.fromJson({'tienePdf': 'false'}).tienePdf, isFalse);
      // Un null (o una clave ausente o rara) NO se vuelve «sin PDF».
      expect(PostergacionModel.fromJson({'tienePdf': null}).tienePdf, isNull);
      expect(PostergacionModel.fromJson({}).tienePdf, isNull);
      expect(PostergacionModel.fromJson({'tienePdf': 1}).tienePdf, isNull);
    });

    test('postergacion: ida y vuelta conserva el null de tienePdf', () {
      final e = PostergacionModel.fromJson({
        'fila': 1,
        'codPostergacion': 40,
        'codCheque': 9,
        'fecha': '2026-10-03',
        'observacion': 'motivo',
        'nombreArchivo': '',
        'tienePdf': null,
      }).toEntity();
      final json = PostergacionModel.fromEntity(e).toJson();
      expect(json['tienePdf'], isNull);
      final otra = PostergacionModel.fromJson(json).toEntity();
      expect(otra.tienePdf, isNull);
      expect(otra.codPostergacion, BigInt.from(40));
      expect(otra.fecha, DateTime(2026, 10, 3));
    });

    test('el cuerpo de un alta nunca lleva usuario ni codigos generados', () {
      final cuerpo =
          PostergacionModel.fromEntity(
            PostergacionEntity(
              codPostergacion: BigInt.from(5),
              codCheque: BigInt.from(9),
              fecha: DateTime(2026, 10, 3),
              observacion: 'x' * 10,
              nombreArchivo: 'no-se-manda.pdf',
              audUsuario: 3,
              tienePdf: true,
              fila: 2,
            ),
          ).toCuerpoRegistro();
      expect(cuerpo.keys.toSet(), {'codCheque', 'fecha', 'observacion'});
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
    final esJson = options.data is! FormData && bytes.isNotEmpty;
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
