import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/models/actualizar_socios_sap_model.dart';
import 'package:bosque_flutter/data/repositories/actualizar_socios_sap_impl.dart';
import 'package:bosque_flutter/domain/entities/actualizar_socios_sap_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';

import 'fakes/arnes_cheques.dart' show permisosAdmin, permisosCon;

/// «Actualizar datos SAP» sin pantalla: el permiso (regla pura), el modelo que
/// lee la respuesta y el repositorio contra el cable (un adaptador de Dio falso
/// que devuelve respuestas con la forma del contrato de `API_CHEQUES.md`).
///
/// El servidor no dice cuantos clientes trajo (el procedimiento no tiene salidas
/// y no se altera): la respuesta es solo una frase, con `data` nulo.
void main() {
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  group('permiso: btnNuevoCH, el mismo de «Registrar» (reglas puras)', () {
    test('el administrador pasa siempre', () {
      expect(permisosAdmin.puedeActualizarDatosSap, isTrue);
    });

    test('con btnNuevoCH', () {
      expect(permisosCon(['btnNuevoCH']).puedeActualizarDatosSap, isTrue);
      expect(
        permisosCon([PermisosCheque.btnNuevo]).puedeActualizarDatosSap,
        isTrue,
      );
    });

    test('btnNuevo2CH no alcanza: el servidor exige btnNuevoCH', () {
      final p = permisosCon(['btnNuevo2CH']);
      // Ve «Registrar» (alcanza cualquiera de los dos), pero no los datos SAP.
      expect(p.puedeVerRegistrar, isTrue);
      expect(p.puedeActualizarDatosSap, isFalse);
    });

    test('sin el boton, o con otros botones del modulo, no', () {
      expect(PermisosCheque.ninguno.puedeActualizarDatosSap, isFalse);
      expect(
        permisosCon([
          'btnTraspasoCH',
          'btnCustodiaCH',
          'btnRpt1CH',
          'btnEditar1CH',
          'btnDetalleCH',
        ]).puedeActualizarDatosSap,
        isFalse,
      );
    });
  });

  group('modelo: el envelope {message, data, status}', () {
    test('lee la frase del servidor e ignora data (nulo: no hay conteo)', () {
      final m = ActualizarSociosSapModel.fromJson({
        'message': 'Clientes actualizados desde SAP.',
        'data': null,
        'status': 200,
      });
      expect(m.mensaje, 'Clientes actualizados desde SAP.');
      expect(m.toEntity().mensaje, 'Clientes actualizados desde SAP.');
    });

    test('un data con numero tampoco cambia nada: la entidad no tiene conteo', () {
      final e =
          ActualizarSociosSapModel.fromJson({
            'message': 'Hecho.',
            'data': 51,
          }).toEntity();
      expect(e, const ActualizarSociosSapEntity(mensaje: 'Hecho.'));
    });

    test('lectura tolerante: sin message o vacio deja el texto neutro', () {
      for (final json in [
        <String, dynamic>{},
        {'message': null},
        {'message': '   '},
      ]) {
        expect(
          ActualizarSociosSapModel.fromJson(json).mensaje,
          ActualizarSociosSapModel.mensajePorDefecto,
        );
      }
      expect(
        ActualizarSociosSapModel.mensajePorDefecto,
        isNot(matches(RegExp(r'\d'))),
        reason: 'el texto neutro tampoco da un numero de clientes',
      );
    });

    test('ida y vuelta con la entidad', () {
      const e = ActualizarSociosSapEntity(mensaje: 'Hecho.');
      expect(ActualizarSociosSapModel.fromEntity(e).toEntity(), e);
      expect(ActualizarSociosSapModel.fromEntity(e).toJson(), {
        'message': 'Hecho.',
      });
    });
  });

  group('repositorio contra el cable', () {
    late _Adaptador cable;
    late ActualizarSociosSapImpl repo;

    setUp(() {
      cable = _Adaptador();
      repo = ActualizarSociosSapImpl();
      // El cliente es un singleton: se le quitan los interceptores (leen el token
      // del almacen seguro) y se le pone el adaptador falso. Solo vale para esta
      // prueba, que corre en su propio proceso.
      repo.dio.interceptors.clear();
      repo.dio.httpClientAdapter = cable;
    });

    test('la constante es la ruta del contrato', () {
      expect(
        AppConstants.chqActualizarClientesSap,
        '/cheque/clientes/actualizar-sap',
      );
    });

    test('un 200 trae la frase; va a su ruta, con cuerpo vacio y sin usuario', () async {
      const frase =
          'Clientes actualizados desde SAP. Los cheques de los clientes que '
          'antes no estaban cargados ya aparecen en la lista.';
      cable.responde(200, {'message': frase, 'data': null, 'status': 200});

      final r = await repo.actualizar();

      expect(r.mensaje, frase);
      expect(cable.peticiones, hasLength(1));
      expect(cable.ultima.ruta, '/cheque/clientes/actualizar-sap');
      expect(cable.ultima.cuerpo, isEmpty);
      expect(
        jsonEncode(cable.ultima.cuerpo),
        isNot(contains('audUsuario')),
        reason: 'el usuario de auditoria sale del token',
      );
    });

    test('un 400 lanza el texto completo del servidor (SAP sin responder, otra en curso...)', () async {
      const texto =
          'No se pudieron traer los clientes de SAP. Lo más probable es que el '
          'servidor de SAP no esté respondiendo en este momento. Intenta de '
          'nuevo en unos minutos y, si el error se repite, avisa a Sistemas.';
      cable.responde(400, {'message': texto, 'data': null, 'status': 400});

      await expectLater(repo.actualizar(), throwsA(texto));
    });

    test('un 403 trae el motivo del servidor, no el texto generico', () async {
      const texto =
          'No tienes permiso para traer los clientes nuevos de SAP. Esta acción '
          'usa el botón btnNuevoCH de la pantalla de Cheques (el mismo de '
          '«Registrar»), que tu usuario no tiene asignado; pídele al '
          'administrador que te lo asigne.';
      cable.responde(403, {'message': texto, 'data': null, 'status': 403});

      await expectLater(repo.actualizar(), throwsA(texto));
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
