import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/repositories/verificaciones_impl.dart';
import 'package:bosque_flutter/domain/entities/pendientes_verificacion_filtro_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_filtro_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_registro_entity.dart';

/// El repositorio de «Verificar Cheques» contra el cable: un adaptador de Dio
/// falso devuelve respuestas con la forma del contrato (API_CHEQUES.md) y anota
/// lo que de verdad se mando (ruta y cuerpo JSON ya serializado).
void main() {
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  late _Adaptador cable;
  late VerificacionesImpl repo;

  setUp(() {
    cable = _Adaptador();
    repo = VerificacionesImpl();
    // El cliente es un singleton: se le quitan los interceptores (leen el token
    // del almacen seguro) y se le pone el adaptador falso. Solo vale para esta
    // prueba, que corre en su propio proceso.
    repo.dio.interceptors.clear();
    repo.dio.httpClientAdapter = cable;
  });

  Map<String, dynamic> envelope(
    Object? data, {
    int status = 200,
    String message = 'ok',
  }) => {'message': message, 'data': data, 'status': status};

  Map<String, dynamic> fila(int codvd) => {
    'fila': 1,
    'codvd': codvd,
    'codCheque': 9001,
    'codBanco': 8,
    'fechaBanco': '2026-10-03',
    'observacion': '',
    'estado': 'Y',
    'datoBanco': 'BANCO MERCANTIL',
    'nroCheque': '480123',
    'montoCheque': 100.5,
    'datoBancoCheque': 'BANCO UNION',
    'datoEstadoCheque': 'PENDIENTE',
    'fechaCobrarCheque': '2026-10-03',
    'chequeCerrado': false,
    'datoEstado': 'Valido',
    'moneda': 'BS',
    'descMoneda': 'Bs',
  };

  Map<String, dynamic> pendiente(int cod) => {
    'fila': 1,
    'codCheque': cod,
    'codBanco': 7,
    'nroCheque': '$cod',
    'montoCheque': 2350.0,
    'datoBancoCheque': 'BANCO UNION',
    'datoEstadoCheque': 'PENDIENTE',
    'fechaCobrarCheque': '2026-10-03',
    'chequeCerrado': false,
    'moneda': 'BS',
    'descMoneda': 'Bs',
  };

  test('cada constante es la ruta del contrato, todas bajo /cheque/verificacion', () {
    expect(AppConstants.chqVerificacionListar, '/cheque/verificacion/listar');
    expect(
      AppConstants.chqVerificacionPendientes,
      '/cheque/verificacion/pendientes',
    );
    expect(
      AppConstants.chqVerificacionPreparar,
      '/cheque/verificacion/preparar',
    );
    expect(
      AppConstants.chqVerificacionRegistrar,
      '/cheque/verificacion/registrar',
    );
    expect(AppConstants.chqVerificacionAnular, '/cheque/verificacion/anular');
    // La direccion de la pantalla es la de tb_vista (codVista 77).
    expect(AppConstants.rutaVerificarCheques, 'tchCheque/verificarDepositos');
  });

  group('listar', () {
    test('manda la fecha y la pagina a su ruta y arma la pagina', () async {
      cable.responde(
        200,
        envelope({
          'total': 45,
          'pagina': 2,
          'tamanio': 20,
          'filas': [fila(12), fila(11)],
        }),
      );
      final p = await repo.listar(
        VerificacionFiltroEntity(fechaBanco: DateTime(2026, 10, 3), pagina: 2),
      );

      expect(cable.ultima.ruta, '/cheque/verificacion/listar');
      expect(cable.ultima.cuerpo, {
        'fechaBanco': '2026-10-03',
        'pagina': 2,
        'tamanio': 20,
      });
      expect(p.total, 45);
      expect(p.totalPaginas, 3);
      expect(p.filas.map((f) => f.codvd), [BigInt.from(12), BigInt.from(11)]);
    });

    test('sin fecha no manda la clave (todas)', () async {
      cable.responde(
        200,
        envelope({'total': 0, 'pagina': 1, 'tamanio': 20, 'filas': []}),
      );
      await repo.listar(const VerificacionFiltroEntity());
      expect((cable.ultima.cuerpo as Map).containsKey('fechaBanco'), isFalse);
    });

    test('un 204 es una pagina vacia y no un error', () async {
      cable.responde(204, null);
      final p = await repo.listar(const VerificacionFiltroEntity(pagina: 3));
      expect(p.filas, isEmpty);
      expect(p.total, 0);
      expect(p.pagina, 3);
    });

    test('un 400 llega con el texto del backend', () async {
      cable.responde(
        400,
        envelope(null, status: 400, message: 'No se pudo leer el filtro.'),
      );
      await expectLater(
        repo.listar(const VerificacionFiltroEntity()),
        throwsA(
          predicate((e) => e.toString().contains('No se pudo leer el filtro.')),
        ),
      );
    });
  });

  group('listarPendientes', () {
    test('manda estado, el criterio de fecha y la pagina', () async {
      cable.responde(
        200,
        envelope({
          'total': 1,
          'pagina': 1,
          'tamanio': 20,
          'filas': [pendiente(321)],
        }),
      );
      final p = await repo.listarPendientes(
        const PendientesVerificacionFiltroEntity(),
      );

      expect(cable.ultima.ruta, '/cheque/verificacion/pendientes');
      expect(cable.ultima.cuerpo, {
        'estado': 'PEN',
        'soloCobranzaHoy': true,
        'pagina': 1,
        'tamanio': 20,
      });
      expect(p.filas.single.codCheque, BigInt.from(321));
      expect(p.filas.single.codBancoCheque, 7);
    });

    test('«Todos» los estados no manda estado y «hasta hoy» manda soloCobranzaHoy false', () async {
      cable.responde(
        200,
        envelope({'total': 0, 'pagina': 1, 'tamanio': 1, 'filas': []}),
      );
      await repo.listarPendientes(
        const PendientesVerificacionFiltroEntity(
          estado: null,
          soloCobranzaHoy: false,
          tamanio: 1,
        ),
      );
      final c = cable.ultima.cuerpo as Map;
      expect(c.containsKey('estado'), isFalse);
      expect(c['soloCobranzaHoy'], false);
      expect(c['tamanio'], 1);
    });
  });

  group('preparar', () {
    test('manda {id: codCheque} y devuelve el cheque y la fecha propuesta', () async {
      cable.responde(
        200,
        envelope({'cheque': pendiente(321), 'fechaBanco': '2026-10-03'}),
      );
      final p = await repo.preparar(BigInt.from(321));

      expect(cable.ultima.ruta, '/cheque/verificacion/preparar');
      expect(cable.ultima.cuerpo, {'id': 321});
      expect(p.cheque.codCheque, BigInt.from(321));
      expect(p.fechaBanco, DateTime(2026, 10, 3));
    });

    test('un 400 (ya verificado, cerrado) llega completo y tal cual', () async {
      const motivo =
          'El cheque 321 ya tiene una verificación válida. Un cheque solo puede tener una.';
      cable.responde(400, envelope(null, status: 400, message: motivo));
      await expectLater(
        repo.preparar(BigInt.from(321)),
        throwsA(predicate((e) => e.toString().contains(motivo))),
      );
    });

    test('sin cuerpo es un fallo, no una pantalla vacia', () async {
      cable.responde(204, null);
      await expectLater(
        repo.preparar(BigInt.from(321)),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('registrar', () {
    VerificacionRegistroEntity registro(int codvd) => VerificacionRegistroEntity(
      codvd: BigInt.from(codvd),
      codCheque: BigInt.from(321),
      codBanco: 8,
      fechaBanco: DateTime(2026, 10, 3),
      observacion: 'Cobrado',
    );

    test('un alta manda codvd 0 y devuelve el codvd del 201', () async {
      cable.responde(
        201,
        envelope(77, status: 201, message: 'Verificación registrada.'),
      );
      final id = await repo.registrar(registro(0));

      expect(cable.ultima.ruta, '/cheque/verificacion/registrar');
      expect(cable.ultima.cuerpo, {
        'codvd': 0,
        'codCheque': 321,
        'codBanco': 8,
        'fechaBanco': '2026-10-03',
        'observacion': 'Cobrado',
      });
      expect(id, BigInt.from(77));
    });

    test('nunca manda estado ni usuario de auditoria', () async {
      cable.responde(201, envelope(5, status: 201));
      await repo.registrar(registro(5));
      final c = cable.ultima.cuerpo as Map;
      expect(c.containsKey('estado'), isFalse);
      expect(c.containsKey('audUsuario'), isFalse);
      expect(c['codvd'], 5);
    });

    test('un 400 con varios errores llega con sus saltos de linea', () async {
      cable.responde(
        400,
        envelope(null, status: 400, message: 'Falta la fecha.\nFalta el banco.'),
      );
      await expectLater(
        repo.registrar(registro(0)),
        throwsA(
          predicate(
            (e) => e.toString().contains('Falta la fecha.\nFalta el banco.'),
          ),
        ),
      );
    });
  });

  group('anular', () {
    test('manda {id: codvd} y devuelve el mensaje del servidor', () async {
      cable.responde(
        201,
        envelope(12, status: 201, message: 'Verificación anulada.'),
      );
      final m = await repo.anular(BigInt.from(12));

      expect(cable.ultima.ruta, '/cheque/verificacion/anular');
      expect(cable.ultima.cuerpo, {'id': 12});
      expect(m, 'Verificación anulada.');
    });

    test('si ya estaba anulada, el mensaje lo dice (no se inventa uno)', () async {
      cable.responde(
        201,
        envelope(
          12,
          status: 201,
          message: 'Esta verificación ya estaba anulada: no hay nada que cambiar.',
        ),
      );
      expect(
        await repo.anular(BigInt.from(12)),
        'Esta verificación ya estaba anulada: no hay nada que cambiar.',
      );
    });

    test('un 400 llega como el texto del backend', () async {
      cable.responde(
        400,
        envelope(
          null,
          status: 400,
          message: 'No se encontró la verificación 12.',
        ),
      );
      await expectLater(
        repo.anular(BigInt.from(12)),
        throwsA(
          predicate(
            (e) => e.toString().contains('No se encontró la verificación 12.'),
          ),
        ),
      );
    });
  });

  group('estados de cheque', () {
    test('salen de /cheque/catalogos', () async {
      cable.responde(
        200,
        envelope({
          'estadosCheque': [
            {'codigo': 'PEN', 'nombre': 'PENDIENTE'},
            {'codigo': 'CER', 'nombre': 'CERRADO'},
          ],
        }),
      );
      final e = await repo.obtenerEstadosCheque();
      expect(cable.ultima.ruta, '/cheque/catalogos');
      expect(e.map((o) => o.codigo), ['PEN', 'CER']);
      expect(e.map((o) => o.nombre), ['PENDIENTE', 'CERRADO']);
    });
  });
}

typedef _Peticion = ({String ruta, Object? cuerpo});

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
    Object? cuerpo;
    if (requestStream != null) {
      final bytes = [await for (final b in requestStream) ...b];
      final texto = utf8.decode(bytes);
      cuerpo = texto.isEmpty ? null : jsonDecode(texto);
    }
    peticiones.add((ruta: options.path, cuerpo: cuerpo));

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
