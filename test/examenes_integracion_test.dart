import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_postulante.dart';
import 'package:bosque_flutter/data/models/tcpe_examen_model.dart';
import 'package:bosque_flutter/data/models/tcpe_historial_examen_model.dart';
import 'package:bosque_flutter/data/models/tcpe_informe_categoria_model.dart';
import 'package:bosque_flutter/data/models/tcpe_lote_generado_model.dart';
import 'package:bosque_flutter/data/models/tcpe_rol_examen_model.dart';
import 'package:bosque_flutter/data/repositories/examenes_impl.dart';

/// Integración con el backend (contrato v3 a v5) contra un adaptador de Dio
/// falso: rutas, cuerpos y la forma de cada respuesta (PDF en bytes, 204,
/// mensajes del SP y campos de los DTO).
void main() {
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  late _Adaptador cable;
  late ExamenesImpl repo;

  setUp(() {
    cable = _Adaptador();
    repo = ExamenesImpl();
    // Singleton de DioClient: sin interceptores (leen el almacén seguro) y con el cable falso.
    repo.dio.interceptors.clear();
    repo.dio.httpClientAdapter = cable;
  });

  Map<String, dynamic> sobre(Object? data, {String message = 'Operación realizada exitosamente', int status = 200}) =>
      {'message': message, 'data': data, 'status': status};

  group('PDF de escritos', () {
    final pdf = Uint8List.fromList([...utf8.encode('%PDF-1.4\n'), for (var i = 0; i < 64; i++) i]);

    test('examen escrito: ruta, cuerpo {codRolExamen, codExamen} y bytes', () async {
      cable.responde(200, pdf);
      final bytes = await repo.pdfEscrito(codRolExamen: BigInt.from(40), codExamen: BigInt.from(7));
      expect(cable.ultima.ruta, AppConstants.tcpeLotesExamenEscritoPdf);
      expect(cable.ultima.cuerpo, {'codRolExamen': 40, 'codExamen': 7});
      expect(cable.ultima.tipoRespuesta, ResponseType.bytes);
      expect(bytes, pdf);
    });

    test('solucionario de todo el lote: sin codExamen', () async {
      cable.responde(200, pdf);
      await repo.pdfEscrito(codRolExamen: BigInt.from(40), solucionario: true);
      expect(cable.ultima.ruta, AppConstants.tcpeLotesSolucionarioPdf);
      expect(cable.ultima.cuerpo, {'codRolExamen': 40});
    });

    test('204 es éxito sin PDF: null, no un error', () async {
      cable.responde(204, null);
      expect(await repo.pdfEscrito(codRolExamen: BigInt.from(40)), isNull);
    });

    test('400: el mensaje del backend aunque llegue como bytes', () async {
      cable.responde(400, {'message': 'El lote no existe.', 'data': null, 'status': 400});
      await expectLater(
        repo.pdfEscrito(codRolExamen: BigInt.from(99)),
        throwsA(predicate((e) => '$e'.contains('El lote no existe.'))),
      );
    });
  });

  group('calificación: el mensaje del SP llega a la UI', () {
    test('nota manual: cuerpo {codExamen, resultado} y errormsg del SP', () async {
      cable.responde(201, sobre(55, message: 'Nota guardada.', status: 201));
      final msg = await repo.notaManual(BigInt.from(55), 72.5);
      expect(cable.ultima.ruta, AppConstants.tcpeCalificacionNota);
      expect(cable.ultima.cuerpo, {'codExamen': 55, 'resultado': 72.5});
      expect(msg, 'Nota guardada.');
    });

    test('nota fuera de rango: el 400 del SP tal cual (el front no la valida)', () async {
      cable.responde(400, {'message': 'La nota va de 0 a 100.', 'data': null, 'status': 400});
      await expectLater(
        repo.notaManual(BigInt.from(55), 150),
        throwsA(predicate((e) => '$e'.contains('La nota va de 0 a 100.'))),
      );
    });

    test('cerrar: devuelve "Calificacion cerrada: x de y correctas."', () async {
      cable.responde(201, sobre(55, message: 'Calificacion cerrada: 3 de 5 correctas.', status: 201));
      expect(await repo.cerrarCalificacion(BigInt.from(55)), 'Calificacion cerrada: 3 de 5 correctas.');
      expect(cable.ultima.cuerpo, {'codExamen': 55});
    });
  });

  group('rendición del empleado', () {
    test('latido: {codExamen, codPreguntaH, salioPestana} y data = segundos', () async {
      cable.responde(201, sobre(1234, message: 'Latido registrado.', status: 201));
      final s = await repo.latido(codExamen: BigInt.from(10), codPreguntaH: BigInt.from(3), salioPestana: true);
      expect(cable.ultima.ruta, AppConstants.tcpeMisExamenesLatido);
      expect(cable.ultima.cuerpo, {'codExamen': 10, 'codPreguntaH': 3, 'salioPestana': true});
      expect(s, 1234);
    });

    test('config: lista de {clave, valor, descripcion}', () async {
      cable.responde(200, sobre([
        {'clave': 'segundosLatido', 'valor': '20', 'descripcion': 'Cada cuanto'},
        {'clave': 'maxExamenesPorLote', 'valor': '150', 'descripcion': null},
      ]));
      final filas = await repo.configuracion();
      expect(cable.ultima.ruta, AppConstants.tcpeConfig);
      expect(filas.map((f) => f.clave), ['segundosLatido', 'maxExamenesPorLote']);
      expect(filas.first.valor, '20');
    });

    test('mis exámenes sin filas (204): lista vacía', () async {
      cable.responde(204, null);
      expect(await repo.listarExamenes(), isEmpty);
    });
  });

  group('rutas públicas del postulante', () {
    test('auth/** y config van sin token; el resto con el del postulante', () {
      expect(DioPostulante.esPublica(AppConstants.tcpePublicoLogin), isTrue);
      expect(DioPostulante.esPublica('${AppConstants.tcpePublicoAuthPrefijo}renovar'), isTrue);
      expect(DioPostulante.esPublica(AppConstants.tcpePublicoConfig), isTrue);
      expect(DioPostulante.esPublica(AppConstants.tcpePublicoListar), isFalse);
      expect(DioPostulante.esPublica(AppConstants.tcpePublicoLatido), isFalse);
    });
  });

  group('campos de los DTO', () {
    test('informe (Resultado C): notaAprobacion y ausentes', () {
      final json = {
        'codRolExamen': 40,
        'titulo': 'Lote',
        'nombreArea': null,
        'nombreClasificacion': null,
        'modalidad': 'O',
        'fecha': '2026-10-20',
        'examenes': 10,
        'rendidos': 6,
        'calificados': 5,
        'promedio': 61.5,
        'aprobados': 3,
        'reprobados': 4,
        'notaAprobacion': 51.0,
        'ausentes': 2,
      };
      final e = TcpeInformeCategoriaModel.fromJson(json).toEntity();
      expect(e.ausentes, 2);
      expect(e.notaAprobacion, 51);
      expect(TcpeInformeCategoriaModel.fromEntity(e).toJson(), json);
    });

    test('historial (Resultado H): notaAprobacion y aprobado de SQL', () {
      final e = TcpeHistorialExamenModel.fromJson({'codExamen': 1, 'resultado': 70, 'notaAprobacion': 60, 'aprobado': 1}).toEntity();
      expect(e.aprobado, isTrue);
      expect(e.notaAprobacion, 60);
      expect(TcpeHistorialExamenModel.fromJson({'codExamen': 2}).toEntity().aprobado, isNull);
    });

    test('rolExamen (CRUD): notaAprobacion y mostrarRespuestas de ida y vuelta', () {
      final m = TcpeRolExamenModel.fromJson({'codRolExamen': 40, 'notaAprobacion': 60.5, 'mostrarRespuestas': 0});
      expect(m.toEntity().notaAprobacion, 60.5);
      expect(m.toEntity().mostrarRespuestas, isFalse);
      final json = TcpeRolExamenModel.fromEntity(m.toEntity()).toJson();
      expect(json['notaAprobacion'], 60.5);
      expect(json['mostrarRespuestas'], isFalse);
    });

    test('examen (CRUD): las columnas v5 viajan y no se pierden al guardar', () {
      final m = TcpeExamenModel.fromJson({
        'codExamen': 80,
        'preguntaActual': 501,
        'ultimaActividad': '2026-10-20 09:05:00',
        'salidasPestana': 3,
        'ultimaSalida': '2026-10-20 09:02:00',
      });
      final json = TcpeExamenModel.fromEntity(m.toEntity()).toJson();
      expect(json['preguntaActual'], 501);
      expect(json['salidasPestana'], 3);
      expect(json['ultimaActividad'], '2026-10-20T09:05:00.000');
    });

    test('credencial: codEmpleado del TcpeCredencialDto', () {
      final g = TcpeLoteGeneradoModel.fromJson({
        'codRolExamen': 40,
        'credenciales': [
          {'codExamen': 1, 'login': null, 'password': null, 'codEmpleado': 77, 'nombreCompleto': 'Rojas Luis', 'ci': '1'},
        ],
      }).toEntity();
      expect(g.credenciales.single.codEmpleado, BigInt.from(77));
      expect(g.credenciales.single.tieneClave, isFalse);
    });
  });
}

class _Peticion {
  _Peticion({required this.ruta, this.cuerpo, this.tipoRespuesta});
  final String ruta;
  final Object? cuerpo;
  final ResponseType? tipoRespuesta;
}

class _Adaptador implements HttpClientAdapter {
  final List<_Peticion> peticiones = [];
  ({int estado, Object? cuerpo}) _respuesta = (estado: 200, cuerpo: null);

  _Peticion get ultima => peticiones.last;

  void responde(int estado, Object? cuerpo) => _respuesta = (estado: estado, cuerpo: cuerpo);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final b in requestStream) {
        bytes.addAll(b);
      }
    }
    peticiones.add(
      _Peticion(
        ruta: options.path,
        cuerpo: bytes.isEmpty ? null : jsonDecode(utf8.decode(bytes)),
        tipoRespuesta: options.responseType,
      ),
    );
    final r = _respuesta;
    if (r.cuerpo is Uint8List) {
      return ResponseBody.fromBytes(r.cuerpo! as Uint8List, r.estado, headers: {
        Headers.contentTypeHeader: ['application/pdf'],
      });
    }
    return ResponseBody.fromString(r.cuerpo == null ? '' : jsonEncode(r.cuerpo), r.estado, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}
