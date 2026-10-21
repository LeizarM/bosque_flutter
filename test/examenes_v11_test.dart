import 'dart:io';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/state/postulante_examen_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/utils/pegado_personas_examen.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/data/models/tcpe_pregunta_semana_model.dart';
import 'package:bosque_flutter/data/models/tcpe_pregunta_semana_vigente_model.dart';
import 'package:bosque_flutter/data/models/tcpe_ranking_pregunta_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_config_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_persona_examen_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_semana_entity.dart';
import 'package:bosque_flutter/presentation/screens/examen_publico/registro_examen_screen.dart';
import 'package:bosque_flutter/presentation/screens/examenes/preguntas_semana_screen.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/editor_personas.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/pregunta_semana_inicio.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/ranking_preguntas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/repositorio_depositos.dart' show loginAdminFalso;
import 'fakes/repositorio_examenes.dart';
import 'fakes/repositorio_rendicion_examen.dart';

/// v11 (contrato 15): el CI sin documento, el ranking de preguntas más falladas
/// y las preguntas de la semana (gestión y tarjeta del inicio).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  Widget app(Widget pantalla, ExamenesFalso repo, {bool enScroll = false}) => ProviderScope(
    overrides: [
      userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(loginAdminFalso)),
      examenesRepositoryProvider.overrideWithValue(repo),
      postulanteExamenRepositoryProvider.overrideWithValue(PostulanteFalso()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme().getTheme(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder:
          (context, child) =>
              ResponsiveBreakpoints.builder(child: child!, breakpoints: ResponsiveUtilsBosque.breakpoints),
      // El inicio del dashboard es una columna que desplaza: la tarjeta va igual.
      home: Scaffold(
        body: enScroll ? SingleChildScrollView(padding: const EdgeInsets.all(20), child: pantalla) : pantalla,
      ),
    ),
  );

  Future<List<FlutterErrorDetails>> abrir(
    WidgetTester tester,
    Widget pantalla, {
    required double ancho,
    required ExamenesFalso repo,
    bool enScroll = false,
  }) async {
    tester.view.physicalSize = Size(ancho, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final errores = <FlutterErrorDetails>[];
    final previo = FlutterError.onError;
    FlutterError.onError = errores.add;
    try {
      await tester.pumpWidget(app(pantalla, repo, enScroll: enScroll));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    } finally {
      FlutterError.onError = previo;
    }
    return errores;
  }

  Future<void> esperar(WidgetTester tester, [int veces = 5]) async {
    for (var i = 0; i < veces; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  ButtonStyleButton botonDe(WidgetTester tester, String texto) => tester.widget<ButtonStyleButton>(
    find.ancestor(of: find.text(texto), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)).first,
  );

  String detalle(List<FlutterErrorDetails> e) => e.map((x) => x.exceptionAsString()).join('\n');

  // ── CI sin documento ────────────────────────────────────────────────────
  group('CI sin documento (0)', () {
    const ana = TcpePersonaExamenEntity(ci: '0', nombres: 'Ana', apellidoPaterno: 'Paz');
    const luis = TcpePersonaExamenEntity(ci: ' 0 ', nombres: 'Luis', apellidoPaterno: 'Rojas');

    test('dos personas con CI 0 no son un repetido; otro CI igual sí', () {
      expect(cisRepetidos(const [ana, luis], ciSinDocumento: '0'), isEmpty);
      expect(validarPersonasExamen(const [ana, luis], ciSinDocumento: '0'), isNull);
      // Sin la configuración (null) se mantiene la regla de antes.
      expect(cisRepetidos(const [ana, luis]), {'0'});
      expect(validarPersonasExamen(const [ana, luis]), 'Fila 1: el CI 0 está repetido.');
      const eva = TcpePersonaExamenEntity(ci: '123', nombres: 'Eva', apellidoPaterno: 'Luna');
      const eva2 = TcpePersonaExamenEntity(ci: '123', nombres: 'Eva', apellidoPaterno: 'Mar');
      expect(cisRepetidos(const [ana, luis, eva, eva2], ciSinDocumento: '0'), {'123'});
    });

    test('la configuración trae el CI, sus ayudas y el plazo; con respaldo si el servidor no las manda', () {
      const r = TcpeConfiguracion.respaldo;
      expect(r.ciSinDocumento, '0');
      expect(r.ayudaCiRegistro, contains('escribe 0'));
      expect(r.ayudaCiPersonas, contains('cada 0 es una persona distinta'));
      expect(r.preguntaSemanaDias, 7);
      expect(r.tituloPreguntaSemana, 'Pregunta de la semana');
      final s = TcpeConfiguracion.desde(const [
        TcpeConfigEntity(clave: 'ciSinDocumento', valor: 'S/N'),
        TcpeConfigEntity(clave: 'preguntaSemanaDias', valor: '0'),
      ]);
      expect(s.ciSinDocumento, 'S/N');
      expect(s.preguntaSemanaDias, 1, reason: 'un plazo propuesto nunca es de cero días');
    });

    testWidgets('la lista de personas muestra la ayuda y acepta varios 0', (tester) async {
      final c =
          ControladorPersonas()
            ..ciSinDocumento = '0'
            ..ayudaCi = 'Escribe 0 si la persona no tiene carnet o es anónima: cada 0 es una persona distinta.';
      addTearDown(c.dispose);
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: EditorPersonasExamen(controlador: c)))),
      );
      expect(find.textContaining('cada 0 es una persona distinta'), findsOneWidget);
      c.pegar('0\tAna\tPaz\n0\tLuis\tRojas');
      await tester.pump();
      expect(c.validar(), isNull);
      await tester.pump();
      expect(find.text('CI repetido'), findsNothing);
    });

    testWidgets('el registro del postulante explica que se puede escribir 0', (tester) async {
      final errores = await abrir(tester, const RegistroExamenScreen(), ancho: 390, repo: ExamenesFalso());
      expect(errores, isEmpty, reason: detalle(errores));
      expect(find.text(TcpeConfiguracion.respaldo.ayudaCiRegistro), findsOneWidget);
    });
  });

  // ── Modelos ─────────────────────────────────────────────────────────────
  group('modelos v11', () {
    test('la vigente arma sus opciones; esValido null sigue null (antes de responder)', () {
      final v =
          TcpePreguntaSemanaVigenteModel.fromJson({
            'codPreguntaSemana': 4,
            'titulo': 'Pregunta de la semana',
            'pregunta': '¿Cada cuánto se revisa el extintor?',
            'fechaInicio': '2026-10-20',
            'fechaFin': '2026-10-26',
            'diasRestantes': 6,
            'mostrarRespuesta': 1,
            'respondida': 0,
            'codRsptaOpElegida': null,
            'esCorrecta': null,
            'respuestaCorrecta': null,
            'mensaje': null,
            'respuestas': 3,
            'opciones': [
              {
                'codPreguntaSemana': 4,
                'codRsptaOp': 101,
                'opcionRspta': 'Cada año',
                'elegida': false,
                'esValido': null,
              },
              {'codRsptaOp': 102, 'opcionRspta': 'Cada mes', 'elegida': 0},
            ],
          }).toEntity();
      expect(v.codPreguntaSemana, BigInt.from(4));
      expect(v.fechaFin, DateTime(2026, 10, 26));
      expect(v.respondida, isFalse);
      expect(v.esCorrecta, isNull);
      expect(v.opciones, hasLength(2));
      expect(v.opciones.every((o) => o.esValido == null), isTrue);
      expect(v.opciones.last.codRsptaOp, BigInt.from(102));
    });

    test('sin opciones ni datos no revienta', () {
      final v = TcpePreguntaSemanaVigenteModel.fromJson({'codPreguntaSemana': null}).toEntity();
      expect(v.codPreguntaSemana, BigInt.zero);
      expect(v.opciones, isEmpty);
      expect(v.mostrarRespuesta, isTrue);
      final r = TcpeRankingPreguntaModel.fromJson({'puesto': '2', 'codPregunta': 8}).toEntity();
      expect(r.puesto, 2);
      expect(r.porcentajeFallo, 0);
      expect(r.errorComun, isNull);
    });

    test('ranking: los fallos se reparten en sin responder, incompletas y con error', () {
      final r =
          TcpeRankingPreguntaModel.fromJson({
            'puesto': 1,
            'codPregunta': 93,
            'veces': 8,
            'aciertos': 2,
            'fallos': 6,
            'sinResponder': 0,
            'incompletas': 5,
            'porcentajeFallo': 75.0,
            'errorComun': 'Estado de Resultados',
            'vecesErrorComun': 1,
          }).toEntity();
      expect(r.conError, 1);
      expect(porcentajeTexto(87.5), '87,5 %');
      expect(porcentajeTexto(75), '75 %');
    });

    test('guardar: sin PK es alta, el título vacío no viaja y las fechas van como DATE', () {
      final alta = TcpePreguntaSemanaModel.fromEntity(
        TcpePreguntaSemanaEntity(
          codPreguntaSemana: BigInt.zero,
          codPregunta: BigInt.from(26),
          titulo: '  ',
          fechaInicio: DateTime(2026, 10, 20, 15, 30),
          fechaFin: DateTime(2026, 10, 26),
          mostrarRespuesta: false,
          estado: 'VIGENTE',
        ),
      );
      expect(alta.toGuardarJson(), {
        'codPregunta': 26,
        'titulo': null,
        'fechaInicio': '2026-10-20',
        'fechaFin': '2026-10-26',
        'mostrarRespuesta': false,
      });
      final edicion =
          TcpePreguntaSemanaModel.fromEntity(
            TcpePreguntaSemanaEntity(
              codPreguntaSemana: BigInt.from(3),
              codPregunta: BigInt.from(26),
              titulo: 'Seguridad',
            ),
          ).toGuardarJson();
      expect(edicion['codPreguntaSemana'], 3);
      expect(edicion['titulo'], 'Seguridad');
      // El CRUD genérico manda solo las columnas de la tabla, nunca lo de la gestión.
      final json = alta.toJson();
      expect(json.keys, isNot(contains('estado')));
      expect(json.keys, isNot(contains('pregunta')));
      expect(json['fechaInicio'], '2026-10-20');
    });

    test('estado de hoy', () {
      expect(EstadoPreguntaSemana.desde('vigente'), EstadoPreguntaSemana.vigente);
      expect(EstadoPreguntaSemana.desde('PROGRAMADA'), EstadoPreguntaSemana.programada);
      expect(EstadoPreguntaSemana.desde(null), EstadoPreguntaSemana.desconocido);
    });
  });

  // ── Tarjeta del inicio ──────────────────────────────────────────────────
  group('inicio: pregunta de la semana', () {
    for (final ancho in [390.0, 1400.0]) {
      testWidgets('sin elegir no se responde; al responder muestra el resultado del servidor a $ancho px', (
        tester,
      ) async {
        final repo = ExamenesFalso()..ponerVigente();
        final errores = await abrir(tester, const PreguntasSemanaInicio(), ancho: ancho, repo: repo, enScroll: true);
        expect(errores, isEmpty, reason: detalle(errores));
        expect(find.text('¿Cada cuánto se revisa el extintor de la planta?'), findsOneWidget);
        expect(find.text('Puedes responder hasta el ${fechaCorta(DateTime(2026, 10, 26))}.'), findsOneWidget);
        expect(botonDe(tester, 'Responder').onPressed, isNull, reason: 'sin opción elegida');

        await tester.tap(find.text('Cada mes'));
        await tester.pump();
        expect(botonDe(tester, 'Responder').onPressed, isNotNull);

        await tester.tap(find.text('Responder'));
        await esperar(tester);
        expect(repo.respondidas, [(BigInt.one, BigInt.from(102))]);
        expect(find.text('¡Correcto! Elegiste la respuesta correcta.'), findsOneWidget);
        expect(find.text('Tu respuesta · correcta'), findsOneWidget);
        expect(find.text('Responder'), findsNothing, reason: 'una sola vez');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('si la pregunta no muestra la respuesta, no se marca cuál era la correcta', (tester) async {
      final repo = ExamenesFalso()..ponerVigente(mostrarRespuesta: false);
      await abrir(tester, const PreguntasSemanaInicio(), ancho: 390, repo: repo, enScroll: true);
      await tester.tap(find.text('Cada año'));
      await tester.pump();
      await tester.tap(find.text('Responder'));
      await esperar(tester);
      expect(find.text('Gracias: tu respuesta quedó registrada.'), findsOneWidget);
      expect(find.text('Tu respuesta'), findsOneWidget);
      expect(find.text('Correcta'), findsNothing);
      expect(find.textContaining('correcta'), findsNothing);
    });

    testWidgets('sin vigentes no ocupa lugar', (tester) async {
      final repo = ExamenesFalso();
      await abrir(tester, const PreguntasSemanaInicio(), ancho: 390, repo: repo, enScroll: true);
      expect(find.text('Pregunta de la semana'), findsNothing);
      expect(find.text('Reintentar'), findsNothing);
    });

    testWidgets('si falla la carga, una línea con Reintentar (no un error crudo)', (tester) async {
      final repo = ExamenesFalso()..errorVigentes = Exception('DioException [bad response]: 404');
      await abrir(tester, const PreguntasSemanaInicio(), ancho: 390, repo: repo, enScroll: true);
      expect(find.text('No se pudo cargar la pregunta de la semana.'), findsOneWidget);
      expect(find.textContaining('DioException'), findsNothing);
      repo
        ..errorVigentes = null
        ..ponerVigente();
      await tester.tap(find.text('Reintentar'));
      await esperar(tester);
      expect(find.text('¿Cada cuánto se revisa el extintor de la planta?'), findsOneWidget);
    });
  });

  // ── Ranking ─────────────────────────────────────────────────────────────
  group('Informes: preguntas más falladas', () {
    Widget ranking() => const Padding(padding: EdgeInsets.all(24), child: RankingPreguntasExamen(compacto: false));

    testWidgets('tabla por categoría en escritorio', (tester) async {
      final errores = await abrir(tester, ranking(), ancho: 1400, repo: ExamenesFalso());
      expect(errores, isEmpty, reason: detalle(errores));
      expect(find.text('Seguridad industrial'), findsOneWidget);
      expect(find.text('Contabilidad básica'), findsOneWidget);
      expect(find.text('Error más común'), findsNWidgets(2), reason: 'rótulos de cada categoría');
      expect(find.text('87,5 %'), findsOneWidget);
      expect(find.text('7 de 8'), findsOneWidget);
      expect(find.text('«Guantes de látex» · 4 veces'), findsOneWidget);
      expect(find.text('Marcaron solo parte de lo correcto.'), findsOneWidget);
      expect(find.text('Respuesta escrita: la califica el evaluador.'), findsOneWidget);
    });

    testWidgets('tarjetas en el teléfono', (tester) async {
      final errores = await abrir(
        tester,
        const Padding(padding: EdgeInsets.all(16), child: RankingPreguntasExamen(compacto: true)),
        ancho: 390,
        repo: ExamenesFalso(),
      );
      expect(errores, isEmpty, reason: detalle(errores));
      expect(find.text('Error más común'), findsNothing);
      expect(find.text('Error más común: «Guantes de látex» · 4 veces'), findsOneWidget);
      expect(find.text('7 de 8 fallaron · 1 sin responder'), findsOneWidget);
    });

    testWidgets('vacío y error son estados distintos', (tester) async {
      final vacio = ExamenesFalso()..ranking = [];
      await abrir(tester, ranking(), ancho: 1400, repo: vacio);
      expect(find.text('Todavía no hay preguntas falladas'), findsOneWidget);

      final falla = ExamenesFalso()..errorRanking = Exception('Error en p_list_tcpe_Resultado');
      await abrir(tester, ranking(), ancho: 1400, repo: falla);
      expect(find.text('Todavía no hay preguntas falladas'), findsNothing);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  // ── Gestión ─────────────────────────────────────────────────────────────
  group('gestión: preguntas de la semana', () {
    for (final ancho in [390.0, 800.0, 1400.0]) {
      testWidgets('lista con estado, plazo y acierto a $ancho px', (tester) async {
        final errores = await abrir(tester, const PreguntasSemanaScreen(), ancho: ancho, repo: ExamenesFalso());
        expect(errores, isEmpty, reason: detalle(errores));
        expect(find.text('EXÁMENES · PREGUNTAS DE LA SEMANA'), findsOneWidget);
        expect(find.text('Vigente'), findsOneWidget);
        expect(find.text('Programada'), findsOneWidget);
        expect(find.text('Inactiva'), findsOneWidget);
        if (ancho < 760) expect(find.text('Nueva'), findsOneWidget, reason: 'botón flotante en el teléfono');
      });
    }

    testWidgets('ver respuestas: cifras, barra por opción y quién respondió', (tester) async {
      await abrir(tester, const PreguntasSemanaScreen(), ancho: 1400, repo: ExamenesFalso());
      await tester.tap(find.text('¿Cada cuánto se revisa el extintor de la planta?'));
      await esperar(tester);
      expect(find.text('Cómo respondieron'), findsOneWidget);
      expect(find.text('HOWARD ESCOBAR ROGER'), findsOneWidget);
      expect(find.text('Acertó'), findsOneWidget);
      expect(find.text('No acertó'), findsOneWidget);
      expect(find.text('Correcta'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('nueva: se publica recién al elegir una pregunta; las que no se pueden, apagadas con su motivo', (
      tester,
    ) async {
      final repo = ExamenesFalso();
      await abrir(tester, const PreguntasSemanaScreen(), ancho: 1400, repo: repo);
      await tester.tap(find.text('Nueva pregunta'));
      await esperar(tester, 3);
      expect(find.text('Nueva pregunta de la semana'), findsOneWidget);
      final hoy = DateTime.now();
      final hasta = DateTime(hoy.year, hoy.month, hoy.day).add(const Duration(days: 6));
      expect(find.text('Hasta: ${fechaCorta(hasta)}'), findsOneWidget, reason: 'inicio + preguntaSemanaDias − 1');
      expect(botonDe(tester, 'Publicar').onPressed, isNull);

      await tester.enterText(find.widgetWithText(TextField, 'Buscar en el texto'), 'extintor');
      await esperar(tester, 3);
      expect(find.textContaining('Es abierta'), findsOneWidget);
      await tester.tap(find.text('¿Cada cuánto se revisa el extintor de la planta?').last);
      await tester.pump();
      expect(botonDe(tester, 'Publicar').onPressed, isNotNull);
      await tester.tap(find.text('Publicar'));
      await esperar(tester, 3);
      expect(repo.ultimaGuardada, '8');
      expect(find.text('Nueva pregunta de la semana'), findsNothing);
    });
  });
}
