import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/data/repositories/hex_api_base.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';

/// La base de Horas Extras contra el cable: cada status del contrato llega a la
/// pantalla como su excepción del módulo, con el texto del SP sin tocar.
void main() {
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  late _Adaptador cable;
  late _Base repo;

  setUp(() {
    cable = _Adaptador();
    repo = _Base();
    // El cliente es un singleton: sin interceptores (leen el token) y con el
    // adaptador falso. Solo vale para esta prueba.
    repo.dio.interceptors.clear();
    repo.dio.httpClientAdapter = cable;
  });

  Map<String, dynamic> fila(Map<String, dynamic> j) => j;

  Matcher error<T extends ErrorHex>(String mensaje) =>
      throwsA(isA<T>().having((e) => e.mensaje, 'mensaje', mensaje));

  test('listar manda el cuerpo y lee las filas de data', () async {
    cable.responde(200, {
      'message': 'Operación realizada exitosamente',
      'status': 200,
      'data': [
        {'idReporte': 1},
        {'idReporte': 2},
      ],
    });
    final filas = await repo.listar('/horas-extras/x', {'pagina': 1}, fila);

    expect(cable.ruta, '/horas-extras/x');
    expect(cable.cuerpo, {'pagina': 1});
    expect(filas, [
      {'idReporte': 1},
      {'idReporte': 2},
    ]);
  });

  test('403 lanza SinPermisoHex con el mensaje del backend', () async {
    cable.responde(403, {'message': _sinPermiso, 'data': null, 'status': 403});
    await expectLater(
      repo.listar('/x', {}, fila),
      error<SinPermisoHex>(_sinPermiso),
    );
  });

  test('400 con confirmable lanza ConfirmacionHex', () async {
    const texto =
        'Estás marcando la salida lejos de donde marcaste la entrada.';
    cable.responde(400, {
      'message': texto,
      'data': null,
      'status': 400,
      'confirmable': true,
    });
    await expectLater(
      repo.escribir('/x', {'tipoMarca': 'SALIDA'}),
      error<ConfirmacionHex>(texto),
    );
  });

  test(
    '400 sin confirmable lanza NegocioHex con el texto del SP tal cual',
    () async {
      const texto =
          'La observación es obligatoria: escribe el motivo del rechazo.';
      cable.responde(400, {'message': texto, 'data': null, 'status': 400});
      await expectLater(
        repo.escribir('/x', {'idReporte': 3}),
        error<NegocioHex>(texto),
      );
    },
  );

  test('409 lanza ConflictoHex', () async {
    const texto = 'El reporte cambió de estado: recarga la lista.';
    cable.responde(409, {'message': texto, 'data': null, 'status': 409});
    await expectLater(
      repo.escribir('/x', {'idReporte': 3}),
      error<ConflictoHex>(texto),
    );
  });

  test('204 en listar da lista vacía y en escribir id 0', () async {
    cable.responde(204, null);
    expect(await repo.listar('/x', {}, fila), isEmpty);
    expect(await repo.escribir('/x', {}), (id: BigInt.zero, mensaje: ''));
  });

  test('escribir devuelve id y mensaje del 201', () async {
    cable.responde(201, {
      'message': 'Reporte anulado.',
      'data': 12,
      'status': 201,
    });
    expect(await repo.escribir('/x', {'idReporte': 12}), (
      id: BigInt.from(12),
      mensaje: 'Reporte anulado.',
    ));
  });

  test('leerUno toma el objeto o la primera fila; 204 da null', () async {
    cable.responde(200, {
      'message': 'ok',
      'status': 200,
      'data': {'idReporte': 5},
    });
    expect(await repo.leerUno('/x', {}, fila), {'idReporte': 5});

    cable.responde(200, {
      'message': 'ok',
      'status': 200,
      'data': [
        {'idReporte': 6},
        {'idReporte': 7},
      ],
    });
    expect(await repo.leerUno('/x', {}, fila), {'idReporte': 6});

    cable.responde(204, null);
    expect(await repo.leerUno('/x', {}, fila), isNull);
  });

  test('descargarPdf: 200 da los bytes y espera hasta 2 minutos', () async {
    cable.responde(200, '%PDF-1.7', tipo: 'application/pdf');
    final pdf = await repo.descargarPdf('/x/pdf', {'idPlanilla': 4});

    expect(utf8.decode(pdf!), '%PDF-1.7');
    expect(cable.cuerpo, {'idPlanilla': 4});
    expect(cable.opciones?.responseType, ResponseType.bytes);
    expect(cable.opciones?.receiveTimeout, const Duration(minutes: 2));
  });

  test('descargarPdf: 204 da null y 403 en bytes da SinPermisoHex', () async {
    cable.responde(204, null);
    expect(await repo.descargarPdf('/x/pdf', {'idPlanilla': 4}), isNull);

    cable.responde(403, {'message': _sinPermiso, 'data': null, 'status': 403});
    await expectLater(
      repo.descargarPdf('/x/pdf', {'idPlanilla': 4}),
      error<SinPermisoHex>(_sinPermiso),
    );
  });

  test('500 lanza Exception que no es ErrorHex', () async {
    cable.responde(500, {
      'message': 'Error interno del servidor.',
      'data': null,
      'status': 500,
    });
    await expectLater(
      repo.listar('/x', {}, fila),
      throwsA(allOf(isA<Exception>(), isNot(isA<ErrorHex>()))),
    );
  });
}

const _sinPermiso =
    'No tienes los permisos necesarios para realizar esta acción.';

class _Base extends HexApiBase {}

/// Responde con lo último indicado en [responde] y guarda lo que recibió.
class _Adaptador implements HttpClientAdapter {
  ({int estado, Object? cuerpo, String tipo}) _respuesta = (
    estado: 200,
    cuerpo: null,
    tipo: Headers.jsonContentType,
  );
  String? ruta;
  Object? cuerpo;
  RequestOptions? opciones;

  /// Un [cuerpo] de texto viaja tal cual; cualquier otro, como JSON.
  void responde(
    int estado,
    Object? cuerpo, {
    String tipo = Headers.jsonContentType,
  }) => _respuesta = (estado: estado, cuerpo: cuerpo, tipo: tipo);

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
    ruta = options.path;
    opciones = options;
    cuerpo = bytes.isEmpty ? null : jsonDecode(utf8.decode(bytes));
    final r = _respuesta;
    final texto = switch (r.cuerpo) {
      null => '',
      final String s => s,
      final otro => jsonEncode(otro),
    };
    return ResponseBody.fromString(
      texto,
      r.estado,
      headers: {
        Headers.contentTypeHeader: [r.tipo],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
