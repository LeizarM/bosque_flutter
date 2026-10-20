import 'dart:convert';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/utils/sesion_postulante_storage.dart';
import 'package:bosque_flutter/data/models/tcpe_area_model.dart';
import 'package:bosque_flutter/data/models/tcpe_banco_pregunta_model.dart';
import 'package:bosque_flutter/data/models/tcpe_catalogo_codec.dart';
import 'package:bosque_flutter/data/models/tcpe_estado_rendicion_model.dart';
import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/data/models/tcpe_lote_generado_model.dart';
import 'package:bosque_flutter/data/models/tcpe_rol_examen_model.dart';
import 'package:bosque_flutter/data/models/tcpe_usuario_model.dart';
import 'package:bosque_flutter/data/repositories/rendicion_endpoints.dart';
import 'package:bosque_flutter/domain/entities/tcpe_catalogo.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_examen.dart';
import 'package:bosque_flutter/domain/entities/tcpe_usuario_entity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los models del módulo de exámenes: JSON → Model → Entity → Model → JSON
/// vuelve al mismo JSON, con los PK como BigInt y serializados con `.toInt()`.
void main() {
  group('ida y vuelta', () {
    test('TcpeAreaModel: PK BigInt, bit y fecha de auditoría', () {
      final json = {
        'codArea': 9007199254740,
        'nombreArea': 'Producción',
        'descripArea': 'Máquinas y bobinas',
        'activo': true,
        'audUsuario': 15,
        'audFecha': '2026-10-19T08:30:00.000',
        'nombreUsuario': 'mjaimes',
      };
      final entidad = TcpeAreaModel.fromJson(json).toEntity();
      expect(entidad.codArea, BigInt.from(9007199254740));
      expect(entidad.audUsuario, BigInt.from(15));
      expect(entidad.audFecha, DateTime(2026, 10, 19, 8, 30));
      expect(TcpeAreaModel.fromEntity(entidad).toJson(), json);
    });

    test('TcpeUsuarioModel: nunca trae password2 y acepta el bit como 0/1', () {
      final json = {
        'codUsuario': 321,
        'codEmpleado': null,
        'codTipoUsuario': 2,
        'ci': '7654321 LP',
        'codArea': 4,
        'nombres': 'Ana',
        'apellidoPaterno': 'Quispe',
        'apellidoMaterno': null,
        'login': 'IPX45',
        'activo': 0,
        'audUsuario': null,
        'audFecha': '2026-10-01 09:15:00',
        'nombreUsuario': null,
        'password2': r'$2a$14$noDebeLlegar',
      };
      final m = TcpeUsuarioModel.fromJson(json);
      expect(m.activo, isFalse);
      expect(m.codEmpleado, isNull);
      final vuelta = TcpeUsuarioModel.fromEntity(m.toEntity()).toJson();
      expect(vuelta.containsKey('password2'), isFalse);
      expect(vuelta['codUsuario'], 321);
      expect(vuelta['activo'], false);
      expect(vuelta['audFecha'], '2026-10-01T09:15:00.000');
      expect(TcpeUsuarioModel.fromJson(vuelta).toJson(), vuelta);
    });

    test('TcpeRolExamenModel: DATE va como yyyy-MM-dd y TIME como HH:mm:ss', () {
      final json = {
        'codRolExamen': 77,
        'codCapacitacion': null,
        'codConvocatoria': null,
        'codArea': 3,
        'ponderacion': null,
        'puntos': null,
        'duracionMinutos': 90,
        'cantidadPreg': 20,
        'cantExamenGenerar': 12,
        'ubicacion': 'Sala 2',
        'modalidad': 'O',
        'esRolCapacitacion': null,
        'fecha': '2026-11-03',
        'horaInicio': '08:30:00',
        'horaFin': '10:00:00',
        'codClasificacion': 5,
        'titulo': 'Operadores de bobinadora',
        'observaciones': null,
        'notaAprobacion': 51.0,
        'mostrarRespuestas': true,
        'audUsuario': 15,
        'audFecha': null,
        'nombreUsuario': null,
      };
      final e = TcpeRolExamenModel.fromJson(json).toEntity();
      expect(e.fecha, DateTime(2026, 11, 3));
      expect(e.codRolExamen, BigInt.from(77));
      expect(TcpeRolExamenModel.fromEntity(e).toJson(), json);
    });

    test('TcpeEstadoRendicionModel: los números que faltan quedan en 0', () {
      final m = TcpeEstadoRendicionModel.fromJson({
        'codExamen': 10,
        'estado': 'EN_CURSO',
        'segundosRestantes': 1799,
        'fechaLimite': '2026-10-19 11:00:00',
      });
      final e = m.toEntity();
      expect(e.codExamen, BigInt.from(10));
      expect(e.totalPreguntas, 0);
      expect(e.segundosRestantes, 1799);
      expect(EstadoExamenTcpe.desde(e.estado), EstadoExamenTcpe.enCurso);
      expect(TcpeEstadoRendicionModel.fromJson(TcpeEstadoRendicionModel.fromEntity(e).toJson()).toJson(),
          TcpeEstadoRendicionModel.fromEntity(e).toJson());
    });

    test('TcpeLoteGeneradoModel: credenciales anidadas', () {
      final json = {
        'codRolExamen': 8,
        'credenciales': [
          {
            'codExamen': 100,
            'codUsuario': 50,
            'login': 'IPX1',
            'password': 'Kq7mZt9wHp',
            'ci': null,
            'nombreCompleto': null,
            'codEmpleado': null,
          },
          {
            'codExamen': 101,
            'codUsuario': null,
            'login': null,
            'password': null,
            'ci': null,
            'nombreCompleto': 'Rojas Luis',
            'codEmpleado': 77,
          },
        ],
      };
      final e = TcpeLoteGeneradoModel.fromJson(json).toEntity();
      expect(e.codRolExamen, BigInt.from(8));
      expect(e.credenciales.first.tieneClave, isTrue);
      expect(e.credenciales.last.tieneClave, isFalse);
      expect(TcpeLoteGeneradoModel.fromEntity(e).toJson(), json);
    });
  });

  group('cuerpos de escritura', () {
    test('banco/guardar manda solo los campos de la pregunta', () {
      final m = TcpeBancoPreguntaModel.fromJson({
        'codPregunta': 4,
        'codClasificacion': 2,
        'pregunta': '¿Qué es un gramaje?',
        'prioridad': 1,
        'activo': 1,
        'esCerrada': true,
        'respuesta': null,
        'cantOpciones': 3,
        'usadaEnExamenes': 2,
        'nombreUsuario': 'x',
      });
      expect(m.toGuardarJson(), {
        'codPregunta': 4,
        'codClasificacion': 2,
        'pregunta': '¿Qué es un gramaje?',
        'prioridad': 1,
        'activo': true,
        'esCerrada': true,
        'respuesta': null,
      });
    });

    test('el codec del CRUD genérico pasa por el model', () {
      final codec = codecTcpe(TcpeCatalogo.usuario);
      final u = codec.desdeJson({'codUsuario': 5, 'login': 'IPX5', 'activo': true});
      expect(u, isA<TcpeUsuarioEntity>());
      expect(codec.idDe(u), BigInt.from(5));
      expect(codec.aJson(u.copyWith(activo: false))['activo'], false);
    });

    test('hay un codec y un descriptor por cada una de las 38 tablas', () {
      expect(TcpeCatalogo.todos, hasLength(38));
      expect({for (final c in TcpeCatalogo.todos) c.entidad}, hasLength(38));
      for (final c in TcpeCatalogo.todos) {
        expect(() => codecTcpe(c), returnsNormally, reason: c.entidad);
        expect(c.filtros.first, c.pk);
      }
    });

    test('{entidad} es exactamente el del regex ENTIDADES de los 3 controladores', () {
      // Copia de TcpeCatalogoBancoController, TcpeCatalogoExamenController y
      // TcpeCatalogoPostulacionController: el segmento distingue mayúsculas y
      // con 'RsptaOpcionH' la ruta no existe (404).
      const banco = 'area|clasificacion|pregunta|respuesta|rsptaOpcion';
      const examen = 'rolExamen|examen|seleccionPreguntas|preguntaH|respuestaH|rsptaOpcionH'
          '|rsptaOpcionU|registroExamen|usuario|tipoUsuario|empleado';
      const postulacion = 'areaPost|capacitacion|capacitador|conocimientosPost|conocimientos'
          '|convocatoria|curso|dpto|experienciaLab|fases|formacion|historialPost|inscripcion'
          '|otrosConocimientos|personaPost|postulacion|reqAcademico|reqAcademicoPost|reqExpLabPost'
          '|seleccionFase|temario|tipo';
      final backend = {...banco.split('|'), ...examen.split('|'), ...postulacion.split('|')};
      expect(backend, hasLength(38));
      expect({for (final c in TcpeCatalogo.todos) c.entidad}, backend);
      expect(
        AppConstants.tcpeCatalogoListar.replaceFirst(AppConstants.tcpeEntidad, TcpeCatalogo.rsptaOpcionH.entidad),
        '/examenes/catalogo/rsptaOpcionH/listar',
      );
    });

    test('responder manda opciones como lista de números (List<Long>), no como texto', () {
      final cerrada = RendicionPorEndpoints.cuerpoResponder(
        codExamen: BigInt.from(10),
        codPreguntaH: BigInt.from(55),
        opciones: [BigInt.from(101), BigInt.from(103)],
      );
      expect(cerrada, {'codExamen': 10, 'codPreguntaH': 55, 'opciones': [101, 103]});
      expect(cerrada['opciones'], isA<List<int>>());
      expect(jsonEncode(cerrada), '{"codExamen":10,"codPreguntaH":55,"opciones":[101,103]}');

      // Desmarcar todo: lista vacía (el SP deja la pregunta sin responder).
      final vacia = RendicionPorEndpoints.cuerpoResponder(
        codExamen: BigInt.from(10),
        codPreguntaH: BigInt.from(55),
        opciones: const [],
      );
      expect(vacia['opciones'], isEmpty);

      // Abierta: solo el texto; la clave opciones no viaja.
      final abierta = RendicionPorEndpoints.cuerpoResponder(
        codExamen: BigInt.from(10),
        codPreguntaH: BigInt.from(56),
        respuestaU: 'Gramos por metro cuadrado',
      );
      expect(abierta.containsKey('opciones'), isFalse);
      expect(abierta['respuestaU'], 'Gramos por metro cuadrado');
    });

    test('fechas del body: DATE como yyyy-MM-dd y DATETIME con milisegundos', () {
      final f = DateTime(2026, 11, 3, 8, 5, 9, 7);
      expect(tcpeFechaJson(f), '2026-11-03');
      expect(tcpeFechaHoraJson(f), '2026-11-03T08:05:09.007');
      // Lo que serializa el backend (yyyy-MM-dd HH:mm:ss y el LocalDate) se lee igual.
      expect(tcpeFecha('2026-11-03 08:05:09'), DateTime(2026, 11, 3, 8, 5, 9));
      expect(tcpeFecha('2026-11-03'), DateTime(2026, 11, 3));
    });
  });

  group('sesión del postulante', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    String jwtQueVence(DateTime exp) {
      String b64(Map<String, Object> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
      return '${b64({'alg': 'HS512'})}.${b64({'exp': exp.millisecondsSinceEpoch ~/ 1000})}.firma';
    }

    tearDown(() => SesionPostulanteStorage().limpiar());

    test('manda el exp del JWT: un expiracion corrido por zona horaria no corta la sesión', () async {
      final storage = SesionPostulanteStorage();
      final token = jwtQueVence(DateTime.now().add(const Duration(hours: 2)));
      // El backend manda la hora de La Paz sin desfase: en otra zona se lee horas antes.
      await storage.guardar(token, vence: DateTime.now().subtract(const Duration(hours: 1)));
      expect(await storage.tokenVigente(), token);
    });

    test('un JWT vencido no vale aunque expiracion diga otra cosa', () async {
      final storage = SesionPostulanteStorage();
      final token = jwtQueVence(DateTime.now().subtract(const Duration(minutes: 1)));
      await storage.guardar(token, vence: DateTime.now().add(const Duration(hours: 5)));
      expect(await storage.tokenVigente(), isNull);
    });
  });

  group('lectura tolerante', () {
    test('epoch en segundos o en milisegundos', () {
      final ms = DateTime(2026, 10, 19, 12).millisecondsSinceEpoch;
      expect(tcpeFecha(ms), DateTime(2026, 10, 19, 12));
      expect(tcpeFecha(ms ~/ 1000), DateTime(2026, 10, 19, 12));
    });

    test('hora y bit en sus formas raras', () {
      expect(tcpeHora('8:5'), '08:05:00');
      expect(tcpeHora('08:30:00.0000000'), '08:30:00');
      expect(tcpeBool('1'), isTrue);
      expect(tcpeBool(0), isFalse);
      expect(tcpeBigInt('12'), BigInt.from(12));
    });
  });
}
