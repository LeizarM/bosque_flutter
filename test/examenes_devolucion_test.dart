import 'dart:io';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/data/models/tcpe_config_model.dart';
import 'package:bosque_flutter/data/models/tcpe_devolucion_item_model.dart';
import 'package:bosque_flutter/data/models/tcpe_espejo_item_model.dart';
import 'package:bosque_flutter/data/models/tcpe_estado_rendicion_model.dart';
import 'package:bosque_flutter/data/models/tcpe_lote_model.dart';
import 'package:bosque_flutter/data/models/tcpe_monitor_examen_model.dart';
import 'package:bosque_flutter/data/models/tcpe_monitor_lote_model.dart';
import 'package:bosque_flutter/data/models/tcpe_resultado_examen_model.dart';
import 'package:bosque_flutter/data/repositories/postulante_examen_impl.dart';
import 'package:bosque_flutter/domain/entities/tcpe_config_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_devolucion_item_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_espejo_item_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_examen.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_rendicion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/espejo_examen.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/resultado_examen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/repositorio_examenes.dart';
import 'fakes/repositorio_rendicion_examen.dart';

/// v3 a v5: la devolución al terminar (con y sin `esValido`), la nota mínima,
/// la configuración, el monitor "En vivo", el espejo y el 401 del ingreso.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Future<void> cargar(String familia, List<String> archivos) async {
      final c = FontLoader(familia);
      for (final a in archivos) {
        final f = File('assets/fonts/$a.ttf');
        if (f.existsSync()) c.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      }
      await c.load();
    }

    await cargar('Roboto', ['Roboto-Regular', 'Roboto-Medium', 'Roboto-Bold']);
    await cargar('JetBrainsMono', ['JetBrainsMono-400', 'JetBrainsMono-500', 'JetBrainsMono-700']);
  });

  /// Monta [hijo] a [ancho] px y devuelve los errores de dibujo (desbordes).
  Future<List<FlutterErrorDetails>> montar(WidgetTester tester, double ancho, Widget hijo, {List<Override> overrides = const []}) async {
    tester.view.physicalSize = Size(ancho, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final errores = <FlutterErrorDetails>[];
    final previo = FlutterError.onError;
    FlutterError.onError = errores.add;
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp(theme: AppTheme().getTheme(), home: Scaffold(body: hijo)),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    } finally {
      FlutterError.onError = previo;
    }
    return errores;
  }

  Future<List<TcpeDevolucionPreguntaEntity>> devolucion({required bool mostrarRespuestas}) async =>
      TcpeDevolucionPreguntaEntity.agrupar(
        await (RendicionFalsa()..mostrarRespuestas = mostrarRespuestas).devolucionExamen(BigInt.from(10)),
      );

  group('devolución', () {
    test('agrupa por pregunta, en orden, con las opciones de las cerradas', () async {
      final p = await devolucion(mostrarRespuestas: true);
      expect(p.map((e) => e.orden), [1, 2, 3]);
      expect(p[0].opciones, hasLength(2));
      expect(p[2].opciones, isEmpty, reason: 'la abierta trae la opción en null');
      expect(p[0].muestraCorrectas, isTrue);
      expect(p[2].pendiente, isTrue);
      expect(p[1].respondida, isTrue);
    });

    test('sin esValido no se pueden mostrar las correctas', () async {
      final p = await devolucion(mostrarRespuestas: false);
      expect(p.any((e) => e.muestraCorrectas), isFalse);
    });

    test('model: JSON → Model → Entity → Model → JSON', () {
      final json = {
        'codPreguntaH': 9007199254740,
        'orden': 4,
        'pregunta': '¿Cuál?',
        'esCerrada': true,
        'esCorrecta': false,
        'respuestaU': null,
        'codRsptaOpH': 77,
        'opcionRspta': 'La b',
        'marcada': true,
        'esValido': null,
      };
      final e = TcpeDevolucionItemModel.fromJson(json).toEntity();
      expect(e.codPreguntaH, BigInt.from(9007199254740));
      expect(e.esValido, isNull);
      expect(TcpeDevolucionItemModel.fromEntity(e).toJson(), json);
      // bit como 0/1, como llega a veces del SP.
      final bit = TcpeDevolucionItemModel.fromJson({...json, 'marcada': 1, 'esValido': 0}).toEntity();
      expect(bit.marcada, isTrue);
      expect(bit.esValido, isFalse);
    });

    for (final ancho in [390.0, 1200.0]) {
      testWidgets('con esValido a $ancho px: acertó, falló, pendiente y las correctas resaltadas', (tester) async {
        final preguntas = await devolucion(mostrarRespuestas: true);
        final errores = await montar(
          tester,
          ancho,
          SingleChildScrollView(child: DevolucionExamen(preguntas: preguntas, compacto: ancho < 760)),
        );
        expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
        expect(find.text('Acertaste'), findsOneWidget);
        expect(find.text('Fallaste'), findsOneWidget);
        expect(find.text('Pendiente de revisión'), findsOneWidget);
        expect(find.text('Correcta'), findsNWidgets(2), reason: 'una válida por cada cerrada');
        expect(find.text('No era correcta'), findsOneWidget, reason: 'marcó 180 g/m², que no era válida');
        expect(find.text('Cortar la energía y colocar el candado.'), findsOneWidget);
        expect(find.byIcon(Icons.check_box), findsNWidgets(2), reason: 'sus dos marcas');
        expect(find.text(ancho < 760 ? 'PREGUNTA 1' : 'PREGUNTA Y TU RESPUESTA'), findsOneWidget);
      });

      testWidgets('sin esValido a $ancho px: solo acertó o falló, sin las correctas', (tester) async {
        final preguntas = await devolucion(mostrarRespuestas: false);
        final errores = await montar(
          tester,
          ancho,
          SingleChildScrollView(child: DevolucionExamen(preguntas: preguntas, compacto: ancho < 760)),
        );
        expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
        expect(find.text('Acertaste'), findsOneWidget);
        expect(find.text('Fallaste'), findsOneWidget);
        expect(find.text('Correcta'), findsNothing);
        expect(find.text('No era correcta'), findsNothing);
        expect(find.byIcon(Icons.check_box), findsNWidgets(2), reason: 'sus marcas se ven igual');
      });
    }

    testWidgets('cabecera calificada: nota sobre 100, aprobado y nota mínima', (tester) async {
      final errores = await montar(
        tester,
        1200,
        CabeceraResultado(
          compacto: false,
          estado: TcpeEstadoRendicionEntity(
            codExamen: BigInt.from(10),
            titulo: 'Operadores',
            estado: 'CALIFICADO',
            resultado: 72.5,
            notaAprobacion: 60,
            aprobado: true,
            totalPreguntas: 3,
            respondidas: 3,
          ),
        ),
      );
      expect(errores, isEmpty);
      expect(find.text('Aprobado'), findsOneWidget, reason: 'el aprobado de SQL');
      expect(find.text('Nota mínima 60'), findsOneWidget);
      expect(find.textContaining('72.5'), findsOneWidget);
    });

    testWidgets('POR_REVISAR: el mensaje de SQL, sin nota ni devolución', (tester) async {
      final repo = ExamenesFalso();
      final errores = await montar(
        tester,
        390,
        ResultadoExamen(
          clave: ClaveRendicion(OrigenRendicion.empleado, BigInt.from(10)),
          estado: TcpeEstadoRendicionEntity(
            codExamen: BigInt.from(10),
            estado: 'POR_REVISAR',
            resultado: 40,
            mensajeEstado: 'Espera la corrección del evaluador.',
          ),
        ),
        overrides: [examenesRepositoryProvider.overrideWithValue(repo)],
      );
      expect(errores, isEmpty);
      expect(find.text('Espera la corrección del evaluador.'), findsOneWidget);
      expect(find.text('Tus respuestas'), findsNothing);
      expect(find.textContaining('/ 100'), findsNothing);
      expect(find.text('Aprobado'), findsNothing);
    });
  });

  group('nota mínima y estados', () {
    test('lote: campos nuevos de ida y vuelta; guardar manda nota y mostrar', () {
      final json = {
        'codRolExamen': 40,
        'notaAprobacion': 60.5,
        'mostrarRespuestas': false,
        'aprobados': 3,
        'reprobados': 2,
        'ausentes': 1,
        'inicioVentana': '2026-10-20 08:30:00',
        'finVentana': '2026-10-20 10:00:00',
      };
      final e = TcpeLoteModel.fromJson(json).toEntity();
      expect(e.notaAprobacion, 60.5);
      expect(e.mostrarRespuestas, isFalse);
      expect(e.aprobados, 3);
      expect(e.ausentes, 1);
      expect(e.finVentana, DateTime(2026, 10, 20, 10));
      final guardar = TcpeLoteModel.fromEntity(e).toGuardarJson();
      expect(guardar['notaAprobacion'], 60.5);
      expect(guardar['mostrarRespuestas'], isFalse);
      final sinNota = TcpeLoteModel.fromJson({'codRolExamen': 1}).toGuardarJson();
      expect(sinNota.containsKey('notaAprobacion'), isFalse, reason: 'null = el backend pone 51');
    });

    test('estado de rendición: el aprobado de SQL, la ventana y nunca nota en POR_REVISAR', () {
      final e =
          TcpeEstadoRendicionModel.fromJson({
            'codExamen': 10,
            'estado': 'CALIFICADO',
            'resultado': 50,
            'notaAprobacion': 51,
            'aprobado': false,
            'mostrarRespuestas': 1,
            'mensajeEstado': 'Reprobaste.',
            'inicioVentana': '2026-10-20 08:30:00',
            'finVentana': '2026-10-20 10:00:00',
          }).toEntity();
      expect(e.aprobacion, isFalse);
      expect(e.mostrarRespuestas, isTrue);
      expect(e.inicioVentana, DateTime(2026, 10, 20, 8, 30));
      expect(e.finVentana, DateTime(2026, 10, 20, 10));
      expect(e.copyWith(aprobado: true).aprobacion, isTrue, reason: 'manda el aprobado del servidor');
      final sinAprobado = TcpeEstadoRendicionModel.fromJson({'codExamen': 11, 'estado': 'CALIFICADO', 'resultado': 50, 'notaAprobacion': 51});
      expect(sinAprobado.toEntity().aprobacion, isNull, reason: 'la regla vive en SQL: el front no la recalcula');
      final espera = e.copyWith(estado: 'POR_REVISAR');
      expect(espera.notaVisible, isNull);
      expect(espera.aprobacion, isNull);
      expect(
        TcpeEstadoRendicionModel.fromJson(TcpeEstadoRendicionModel.fromEntity(e).toJson()).toJson(),
        TcpeEstadoRendicionModel.fromEntity(e).toJson(),
      );
    });

    test('resultado del lote: notaAprobacion y aprobación solo con nota', () {
      final r = TcpeResultadoExamenModel.fromJson({'codExamen': 1, 'aprobado': 1, 'resultado': 80, 'notaAprobacion': 70}).toEntity();
      expect(r.notaAprobacion, 70);
      expect(r.aprobacion, isTrue);
      expect(TcpeResultadoExamenModel.fromJson({'codExamen': 2}).toEntity().aprobacion, isNull);
    });

    test('AUSENTE es un estado cerrado', () {
      expect(EstadoExamenTcpe.desde('AUSENTE'), EstadoExamenTcpe.ausente);
      expect(EstadoExamenTcpe.ausente.cerrado, isTrue);
    });
  });

  group('configuración', () {
    test('toma los valores del servidor y el respaldo para lo que falta', () {
      final filas = [
        for (final j in [
          {'clave': 'maxExamenesPorLote', 'valor': '150', 'descripcion': 'Tope'},
          {'clave': 'notaAprobacionDefecto', 'valor': '60,5'},
          {'clave': 'avisoSalidaExamen', 'valor': 'Entrega para salir.'},
          {'clave': 'segundosLatido', 'valor': 'no es número'},
        ])
          TcpeConfigModel.fromJson(j).toEntity(),
      ];
      final c = TcpeConfiguracion.desde(filas);
      expect(c.maxExamenesPorLote, 150);
      expect(c.notaAprobacionDefecto, 60.5);
      expect(c.avisoSalidaExamen, 'Entrega para salir.');
      expect(c.segundosLatido, 15, reason: 'valor inválido: respaldo');
      expect(c.duracionMaxMinutos, 1440);
      expect(TcpeConfiguracion.respaldo.deRespaldo, isTrue);
      expect(TcpeConfigModel.fromEntity(filas.first).toJson(), {'clave': 'maxExamenesPorLote', 'valor': '150', 'descripcion': 'Tope'});
    });
  });

  group('en vivo', () {
    test('monitor: models de ida y vuelta', () {
      final examen = {
        'codExamen': 100,
        'login': 'IPX-56',
        'nombreCompleto': 'Ana',
        'ci': '1',
        'estado': 'EN_CURSO',
        'fechaInicio': '2026-10-20T08:31:00.000',
        'fechaLimite': '2026-10-20T10:01:00.000',
        'segundosRestantes': 1500,
        'totalPreguntas': 20,
        'respondidas': 7,
        'ordenActual': 8,
        'ultimaActividad': '2026-10-20T09:05:00.000',
        'segundosSinActividad': 12,
        'conexion': 'CONECTADO',
        'salidasPestana': 2,
        'ultimaSalida': null,
        'resultado': null,
      };
      final e = TcpeMonitorExamenModel.fromJson(examen).toEntity();
      expect(e.ordenActual, 8);
      expect(e.conexion, 'CONECTADO');
      expect(TcpeMonitorExamenModel.fromEntity(e).toJson(), examen);
      final lote = TcpeMonitorLoteModel.fromJson({'codRolExamen': 40, 'enCurso': 2, 'entregados': 5}).toEntity();
      expect(lote.enCurso, 2);
      expect(lote.entregados, 5);
    });

    test('espejo: la pregunta actual armada desde sus filas', () {
      final filas = ExamenesFalso.espejoDe(BigInt.from(100));
      final p = TcpeEspejoItemEntity.preguntaActualDe(filas)!;
      expect(p.opciones, hasLength(3));
      expect(p.muestraCorrectas, isTrue);
      expect(TcpeEspejoItemEntity.preguntaActualDe(const []), isNull);
      final json = TcpeEspejoItemModel.fromEntity(filas.first).toJson();
      expect(TcpeEspejoItemModel.fromJson(json).toJson(), json);
    });

    for (final ancho in [390.0, 1000.0]) {
      testWidgets('espejo a $ancho px: estado, pregunta n de N, marcas y válidas', (tester) async {
        final errores = await montar(
          tester,
          ancho,
          SingleChildScrollView(child: VistaEspejo(filas: ExamenesFalso.espejoDe(BigInt.from(100)), leido: DateTime.now())),
        );
        expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
        expect(find.text('Conectado'), findsOneWidget);
        expect(find.text('Pregunta 8 de 20'), findsOneWidget);
        expect(find.textContaining('Qué elementos de protección'), findsOneWidget);
        expect(find.text('Correcta'), findsNWidgets(2));
        expect(find.byIcon(Icons.check_box), findsNWidgets(2));
        expect(find.textContaining('Quedan'), findsOneWidget);
      });
    }

    testWidgets('espejo sin pregunta abierta y fuera de curso', (tester) async {
      await montar(tester, 390, const VistaEspejo(filas: []));
      expect(find.textContaining('no está en curso'), findsOneWidget);
    });
  });

  group('ingreso del postulante', () {
    DioException con401(Object? cuerpo) {
      final pedido = RequestOptions(path: '/examen-publico/auth/login');
      return DioException(
        requestOptions: pedido,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: pedido, statusCode: 401, data: cuerpo),
      );
    }

    test('credencial vencida: el mensaje del backend tal cual', () {
      const msg = 'Tu examen ya fue entregado: estas credenciales ya no son válidas.';
      expect(PostulanteExamenImpl.mensajeIngresoFallido(con401({'message': msg, 'status': 401})), msg);
      expect(PostulanteExamenImpl.mensajeIngresoFallido(con401('{"message":"$msg"}')), msg, reason: 'cuerpo como texto');
    });

    test('401 sin motivo: usuario o clave incorrectos', () {
      expect(PostulanteExamenImpl.mensajeIngresoFallido(con401(null)), 'Usuario o clave incorrectos.');
    });
  });
}
