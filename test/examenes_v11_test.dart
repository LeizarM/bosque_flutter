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

/// v11/v12 (contrato 15): el CI sin documento, el ranking de preguntas más
/// falladas y las preguntas de la semana libres (gestión y tarjeta del inicio).
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
    test('la vigente trae lo que respondió, el agradecimiento y el largo máximo', () {
      final v =
          TcpePreguntaSemanaVigenteModel.fromJson({
            'codPreguntaSemana': 4,
            'titulo': 'Pregunta de la semana',
            'pregunta': '¿Qué tal tu día?',
            'fechaInicio': '2026-10-20',
            'fechaFin': '2026-10-26',
            'diasRestantes': 6,
            'respondida': 1,
            'respuesta': 'Muy bien \u{1F60A}',
            'fechaRespuesta': '2026-10-20T09:15:00.000',
            'mensaje': '¡Gracias! Tu respuesta quedó registrada.',
            'ayuda': 'Responder es opcional.',
            'maxRespuesta': 300,
          }).toEntity();
      expect(v.codPreguntaSemana, BigInt.from(4));
      expect(v.fechaFin, DateTime(2026, 10, 26));
      expect(v.respondida, isTrue);
      expect(v.respuesta, 'Muy bien \u{1F60A}');
      expect(v.fechaRespuesta, isNotNull);
      expect(v.mensaje, '¡Gracias! Tu respuesta quedó registrada.');
      expect(v.maxRespuesta, 300);
    });

    test('sin datos no revienta y el largo inválido vuelve a 500', () {
      final v = TcpePreguntaSemanaVigenteModel.fromJson({'codPreguntaSemana': null, 'maxRespuesta': 0}).toEntity();
      expect(v.codPreguntaSemana, BigInt.zero);
      expect(v.respondida, isFalse);
      expect(v.respuesta, isNull);
      expect(v.maxRespuesta, 500);
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

    test('guardar: sin PK es alta, el título vacío no viaja, el texto va recortado y las fechas como DATE', () {
      final alta = TcpePreguntaSemanaModel.fromEntity(
        TcpePreguntaSemanaEntity(
          codPreguntaSemana: BigInt.zero,
          pregunta: '  ¿Qué tal tu día?  ',
          titulo: '  ',
          fechaInicio: DateTime(2026, 10, 20, 15, 30),
          fechaFin: DateTime(2026, 10, 26),
          estado: 'VIGENTE',
        ),
      );
      expect(alta.toGuardarJson(), {
        'titulo': null,
        'pregunta': '¿Qué tal tu día?',
        'fechaInicio': '2026-10-20',
        'fechaFin': '2026-10-26',
      });
      final edicion =
          TcpePreguntaSemanaModel.fromEntity(
            TcpePreguntaSemanaEntity(codPreguntaSemana: BigInt.from(3), pregunta: '¿Qué tal?', titulo: 'Hola'),
          ).toGuardarJson();
      expect(edicion['codPreguntaSemana'], 3);
      expect(edicion['titulo'], 'Hola');
      // El CRUD genérico manda solo las columnas de la tabla, nunca lo de la gestión.
      final json = alta.toJson();
      expect(json.keys, isNot(contains('estado')));
      expect(json.keys, isNot(contains('respuestas')));
      expect(json.keys, contains('pregunta'));
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
      testWidgets('sin texto no se envía; al enviar muestra su respuesta y el agradecimiento a $ancho px', (
        tester,
      ) async {
        final repo = ExamenesFalso()..ponerVigente();
        final errores = await abrir(tester, const PreguntasSemanaInicio(), ancho: ancho, repo: repo, enScroll: true);
        expect(errores, isEmpty, reason: detalle(errores));
        expect(find.text('¿Qué tal tu día?'), findsOneWidget);
        expect(find.text('Puedes responder hasta el ${fechaCorta(DateTime(2026, 10, 26))}.'), findsOneWidget);
        expect(find.textContaining('Responder es opcional'), findsOneWidget);
        expect(botonDe(tester, 'Enviar').onPressed, isNull, reason: 'sin texto');

        await tester.enterText(find.byType(TextField), '   ');
        await tester.pump();
        expect(botonDe(tester, 'Enviar').onPressed, isNull, reason: 'solo espacios');

        await tester.enterText(find.byType(TextField), 'Muy bien, gracias');
        await tester.pump();
        expect(botonDe(tester, 'Enviar').onPressed, isNotNull);

        await tester.tap(find.text('Enviar'));
        await esperar(tester);
        expect(repo.respondidas, [(BigInt.one, 'Muy bien, gracias')]);
        expect(find.text('Muy bien, gracias'), findsOneWidget, reason: 'su respuesta, en su globo');
        expect(find.text('¡Gracias! Tu respuesta quedó registrada.'), findsOneWidget);
        expect(find.byType(TextField), findsNothing, reason: 'una sola vez');
        expect(find.text('Enviar'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('«Ahora no» la oculta sin responder', (tester) async {
      final repo = ExamenesFalso()..ponerVigente();
      await abrir(tester, const PreguntasSemanaInicio(), ancho: 390, repo: repo, enScroll: true);
      await tester.tap(find.text('Ahora no'));
      await tester.pump();
      expect(find.text('¿Qué tal tu día?'), findsNothing);
      expect(repo.respondidas, isEmpty);
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
      expect(find.text('¿Qué tal tu día?'), findsOneWidget);
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
      testWidgets('lista con estado y plazo a $ancho px', (tester) async {
        final errores = await abrir(tester, const PreguntasSemanaScreen(), ancho: ancho, repo: ExamenesFalso());
        expect(errores, isEmpty, reason: detalle(errores));
        expect(find.text('EXÁMENES · PREGUNTAS DE LA SEMANA'), findsOneWidget);
        expect(find.text('Vigente'), findsOneWidget);
        expect(find.text('Programada'), findsOneWidget);
        expect(find.text('Inactiva'), findsOneWidget);
        if (ancho < 760) expect(find.text('Nueva'), findsOneWidget, reason: 'botón flotante en el teléfono');
      });
    }

    testWidgets('ver respuestas: quién respondió y qué escribió; se puede quitar una', (tester) async {
      final repo = ExamenesFalso();
      await abrir(tester, const PreguntasSemanaScreen(), ancho: 1400, repo: repo);
      await tester.tap(find.text('¿Qué tal tu día?'));
      await esperar(tester);
      expect(find.text('Lo que respondieron'), findsOneWidget);
      expect(find.text('HOWARD ESCOBAR ROGER'), findsOneWidget);
      expect(find.text('Muy bien, con mucho trabajo pero tranquilo.'), findsOneWidget);
      expect(find.text('Cansado, pero contento.'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Quitar respuesta').first);
      await esperar(tester, 2);
      await tester.tap(find.text('Quitar'));
      await esperar(tester);
      expect(repo.quitadas, [BigInt.one]);
    });

    testWidgets('nueva: se publica recién con texto, con la vista previa del inicio', (tester) async {
      final repo = ExamenesFalso();
      await abrir(tester, const PreguntasSemanaScreen(), ancho: 1400, repo: repo);
      await tester.tap(find.text('Nueva pregunta'));
      await esperar(tester, 3);
      expect(find.text('Nueva pregunta de la semana'), findsOneWidget);
      final hoy = DateTime.now();
      final hasta = DateTime(hoy.year, hoy.month, hoy.day).add(const Duration(days: 6));
      expect(find.text('Hasta: ${fechaCorta(hasta)}'), findsOneWidget, reason: 'inicio + preguntaSemanaDias − 1');
      expect(find.text('Escribe la pregunta arriba.'), findsOneWidget);
      expect(botonDe(tester, 'Publicar').onPressed, isNull);

      await tester.enterText(find.widgetWithText(TextField, 'Qué quieres preguntar'), '¿Qué tal tu día?');
      await tester.pump();
      expect(find.text('Escribe la pregunta arriba.'), findsNothing, reason: 'la vista previa muestra el texto');
      expect(botonDe(tester, 'Publicar').onPressed, isNotNull);
      await tester.tap(find.text('Publicar'));
      await esperar(tester, 3);
      expect(repo.ultimaGuardada, '¿Qué tal tu día?');
      expect(find.text('Nueva pregunta de la semana'), findsNothing);
    });
  });
}
