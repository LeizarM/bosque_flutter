import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/ui/mensajes_usuario.dart';
import 'package:bosque_flutter/data/repositories/archivo_documental_impl.dart';

/// Los listados del Almacenaje de documentos contra el cable. Pasó de verdad:
/// el servidor se reinició mientras se volvía a abrir una caja y la sección de
/// fotos dijo «problema del sistema, avisa a Sistemas» por un simple corte.
void main() {
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  late _Adaptador cable;
  late ArchivoDocumentalImpl repo;

  setUp(() {
    cable = _Adaptador();
    repo = ArchivoDocumentalImpl();
    // El cliente es un singleton: sin interceptores (leen el token) y con el
    // adaptador falso. Solo vale para esta prueba.
    repo.dio.interceptors.clear();
    repo.dio.httpClientAdapter = cable;
  });

  test('fotos: ruta, cuerpo {codCaja} y filas leídas', () async {
    cable.responde(200, {
      'message': 'ok',
      'status': 200,
      'data': [
        {
          'codFoto': 6,
          'codCaja': 5,
          'orden': 1,
          'ruta': 'archivo-cajas/caja-5-1a15.png',
          'audUsuario': 34,
          'audFecha': '2026-10-13T08:52:45.013+00:00',
        },
      ],
    });
    final fotos = await repo.listarFotos(5);

    expect(cable.ruta, '/archivo-documental/fotos/listar');
    expect(cable.cuerpo, {'codCaja': 5});
    expect(fotos.single.codFoto, 6);
    expect(fotos.single.orden, 1);
    expect(fotos.single.ruta, 'archivo-cajas/caja-5-1a15.png');
  });

  test('fotos: un 204 es «sin fotos», no un error', () async {
    cable.responde(204, null);
    expect(await repo.listarFotos(5), isEmpty);
  });

  test('un corte (servidor reiniciando) dice que no hubo conexión', () async {
    cable.sinConexion = true;
    Object? error;
    try {
      await repo.listarFotos(5);
    } catch (e) {
      error = e;
    }
    final m = humanizar(error);
    expect(m.texto, startsWith('No se pudo conectar con el servidor'));
    expect(m.texto, isNot(contains('Sistemas')));
  });

  test('un 500 sigue siendo falla del sistema', () async {
    cable.responde(500, {'message': 'Error interno del servidor.', 'data': null, 'status': 500});
    Object? error;
    try {
      await repo.listarCajas();
    } catch (e) {
      error = e;
    }
    expect(humanizar(error).esFalloTecnico, isTrue);
  });

  test('un 400 llega con el motivo del servidor', () async {
    cable.responde(400, {'message': 'La caja indicada no existe.', 'data': null, 'status': 400});
    await expectLater(
      repo.listarContenido(),
      throwsA(predicate((e) => e.toString() == 'Exception: La caja indicada no existe.')),
    );
  });
}

/// Responde con lo último indicado en [responde], o corta si [sinConexion].
class _Adaptador implements HttpClientAdapter {
  ({int estado, Object? cuerpo}) _respuesta = (estado: 200, cuerpo: null);
  bool sinConexion = false;
  String? ruta;
  Object? cuerpo;

  void responde(int estado, Object? cuerpo) => _respuesta = (estado: estado, cuerpo: cuerpo);

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
    cuerpo = bytes.isEmpty ? null : jsonDecode(utf8.decode(bytes));
    if (sinConexion) {
      throw DioException.connectionError(requestOptions: options, reason: 'Connection refused');
    }
    final r = _respuesta;
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
