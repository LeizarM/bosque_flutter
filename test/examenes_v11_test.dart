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
import 'package:bosque_flutter/presentation/widgets/examenes/editor_pregunta_semana.dart';
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

/// v11 a v13 (contratos 15 a 17): el CI sin documento, el ranking de preguntas
/// más falladas y las preguntas de la semana, abiertas o de escala.
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
        'tipo': 'A',
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
      expect(repo.ultimaGuardadaEntidad?.esEscala, isFalse, reason: 'sin tocar el tipo, es abierta');
      expect(find.text('Nueva pregunta de la semana'), findsNothing);
    });
  });

  // ── v13: preguntas de escala ────────────────────────────────────────────
  group('v13: pregunta de la semana de escala', () {
    test('modelos: la vigente trae la escala y el valor; guardar manda la escala solo si es de escala', () {
      final v =
          TcpePreguntaSemanaVigenteModel.fromJson({
            'codPreguntaSemana': 5,
            'tipo': 'e',
            'escalaMin': 0,
            'escalaMax': 10,
            'etiquetaMax': 'Excelente',
            'respondida': true,
            'valor': 0,
          }).toEntity();
      expect(v.esEscala, isTrue);
      expect(v.escalaMin, 0);
      expect(v.valor, 0, reason: 'el 0 es un valor, no un vacío');
      expect(TcpePreguntaSemanaVigenteModel.fromJson({'tipo': 'X'}).toEntity().esEscala, isFalse);

      final escala =
          TcpePreguntaSemanaModel.fromEntity(
            TcpePreguntaSemanaEntity(
              codPreguntaSemana: BigInt.from(4),
              pregunta: '¿Cómo ves el ambiente laboral?',
              tipo: 'E',
              escalaMin: 0,
              escalaMax: 10,
              etiquetaMin: '  ',
              etiquetaMax: ' Excelente ',
              fechaInicio: DateTime(2026, 10, 20),
              fechaFin: DateTime(2026, 10, 26),
            ),
          ).toGuardarJson();
      expect(escala['tipo'], 'E');
      expect(escala['escalaMin'], 0);
      expect(escala['escalaMax'], 10);
      expect(escala['etiquetaMin'], isNull);
      expect(escala['etiquetaMax'], 'Excelente');

      final abierta =
          TcpePreguntaSemanaModel.fromEntity(
            TcpePreguntaSemanaEntity(codPreguntaSemana: BigInt.zero, pregunta: 'Hola', escalaMin: 1, escalaMax: 5),
          ).toGuardarJson();
      expect(abierta['tipo'], 'A');
      expect(abierta.containsKey('escalaMin'), isFalse, reason: 'una abierta no manda escala');

      final l =
          TcpePreguntaSemanaModel.fromJson({
            'codPreguntaSemana': 4,
            'tipo': 'E',
            'tipoMostrado': 'Escala del 1 al 5',
            'promedio': 3.7,
          }).toEntity();
      expect(l.esEscala, isTrue);
      expect(l.promedio, 3.7);
      expect(l.tipoMostrado, 'Escala del 1 al 5');
    });

    test('configuración: escala propuesta 1 a 5 y tope 10; el fin siempre queda después del inicio', () {
      const r = TcpeConfiguracion.respaldo;
      expect((r.escalaMinSemana, r.escalaMaxSemana, r.escalaTopeSemana), (1, 5, 10));
      final s = TcpeConfiguracion.desde(const [
        TcpeConfigEntity(clave: 'escalaMinSemana', valor: '7'),
        TcpeConfigEntity(clave: 'escalaMaxSemana', valor: '3'),
        TcpeConfigEntity(clave: 'escalaTopeSemana', valor: '20'),
      ]);
      expect((s.escalaMinSemana, s.escalaMaxSemana, s.escalaTopeSemana), (7, 8, 10));
    });

    test('el valor elegido en palabras', () {
      expect(valorEscalaTexto(4, min: 1, max: 5, etiquetaMin: 'Muy mal', etiquetaMax: 'Excelente'), '4 de 5');
      expect(valorEscalaTexto(5, min: 1, max: 5, etiquetaMax: 'Excelente'), '5 de 5 · Excelente');
      expect(valorEscalaTexto(0, min: 0, max: 10, etiquetaMin: 'Nada'), '0 de 10 · Nada');
      expect(valorEscalaTexto(null, max: 5), '--');
    });

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('inicio: se elige un número y se envía; sin elegir no a $ancho px', (tester) async {
        final repo = ExamenesFalso()..ponerVigenteEscala();
        final errores = await abrir(tester, const PreguntasSemanaInicio(), ancho: ancho, repo: repo, enScroll: true);
        expect(errores, isEmpty, reason: detalle(errores));
        expect(find.text('Del 1 al 5, ¿cómo ves el ambiente laboral?'), findsOneWidget);
        expect(find.byType(TextField), findsNothing, reason: 'de escala no se escribe');
        for (final n in ['1', '2', '3', '4', '5']) {
          expect(find.text(n), findsOneWidget);
        }
        expect(find.text('Muy mal'), findsOneWidget);
        expect(find.text('Excelente'), findsOneWidget);
        expect(botonDe(tester, 'Enviar').onPressed, isNull, reason: 'sin un número elegido');

        await tester.tap(find.text('4'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(botonDe(tester, 'Enviar').onPressed, isNotNull);
        await tester.tap(find.text('Enviar'));
        await esperar(tester);
        expect(repo.elegidos, [(BigInt.two, 4)]);
        expect(repo.respondidas, isEmpty);
        expect(find.text('4 de 5'), findsOneWidget, reason: 'su respuesta, en su globo');
        expect(find.text('¡Gracias! Tu respuesta quedó registrada.'), findsOneWidget);
        expect(find.text('Enviar'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('inicio: una escala del 0 al 10 entra en un teléfono sin desbordar', (tester) async {
      final repo = ExamenesFalso()..ponerVigenteEscala(min: 0, max: 10);
      final errores = await abrir(tester, const PreguntasSemanaInicio(), ancho: 360, repo: repo, enScroll: true);
      expect(errores, isEmpty, reason: detalle(errores));
      for (var n = 0; n <= 10; n++) {
        expect(find.text('$n'), findsOneWidget);
      }
      final lado = tester.getSize(find.ancestor(of: find.text('10'), matching: find.byType(InkWell)).first);
      expect(lado.width, greaterThanOrEqualTo(44), reason: 'cómodo de tocar');
      await tester.tap(find.text('0'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Enviar'));
      await esperar(tester);
      expect(repo.elegidos, [(BigInt.two, 0)]);
    });

    testWidgets('gestión: la de escala muestra su tipo y su promedio', (tester) async {
      final errores = await abrir(tester, const PreguntasSemanaScreen(), ancho: 1400, repo: ExamenesFalso());
      expect(errores, isEmpty, reason: detalle(errores));
      expect(find.text('Escala del 1 al 5'), findsOneWidget);
      expect(find.text('Promedio 3,7'), findsOneWidget);
      expect(find.text('Abierta'), findsNWidgets(3));
    });

    testWidgets('gestión en el teléfono: el tipo y el promedio van en la tarjeta', (tester) async {
      final errores = await abrir(tester, const PreguntasSemanaScreen(), ancho: 390, repo: ExamenesFalso());
      expect(errores, isEmpty, reason: detalle(errores));
      await tester.scrollUntilVisible(find.text('Escala del 1 al 5'), 200, scrollable: find.byType(Scrollable).last);
      expect(find.textContaining('promedio 3,7'), findsOneWidget);
    });

    testWidgets('respuestas de escala: promedio, una barra por número y lo que eligió cada uno', (tester) async {
      final repo = ExamenesFalso();
      await abrir(tester, const PreguntasSemanaScreen(), ancho: 1400, repo: repo);
      await tester.tap(find.text('Del 1 al 5, ¿cómo ves el ambiente laboral?'));
      await esperar(tester);
      expect(find.text('Cómo respondieron'), findsOneWidget);
      expect(find.text('3,7'), findsOneWidget, reason: 'el promedio');
      expect(find.text('1 · 33,3 %'), findsNWidgets(3));
      expect(find.text('0 · 0 %'), findsNWidgets(2));
      expect(find.text('Lo que eligió cada uno'), findsOneWidget);
      expect(find.text('de 5 · Excelente'), findsOneWidget, reason: 'HOWARD eligió 5');
      expect(find.text('HOWARD ESCOBAR ROGER'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('editor: de escala con el rango propuesto, etiquetas y vista previa', (tester) async {
      final repo = ExamenesFalso();
      await abrir(tester, const PreguntasSemanaScreen(), ancho: 1400, repo: repo);
      await tester.tap(find.text('Nueva pregunta'));
      await esperar(tester, 3);
      expect(find.byType(SelectorEscalaSemana), findsNothing, reason: 'abierta por defecto');

      await tester.tap(find.text('Escala'));
      await tester.pump();
      expect(find.text('Cada uno elige un número de la escala.'), findsOneWidget);
      expect(find.byType(SelectorEscalaSemana), findsOneWidget, reason: 'la vista previa con los botones');
      await tester.enterText(find.widgetWithText(TextField, 'Qué quieres preguntar'), '¿Cómo ves el ambiente laboral?');
      await tester.enterText(find.widgetWithText(TextField, 'Qué significa el 5 (opcional)'), 'Excelente');
      await tester.pump();
      expect(find.text('Excelente'), findsNWidgets(2), reason: 'en el campo y bajo el 5 de la vista previa');

      await tester.tap(find.text('Publicar'));
      await esperar(tester, 3);
      final g = repo.ultimaGuardadaEntidad!;
      expect(g.esEscala, isTrue);
      expect((g.escalaMin, g.escalaMax), (1, 5));
      expect(g.etiquetaMin, isEmpty);
      expect(g.etiquetaMax, 'Excelente');
    });

    testWidgets('editor: con respuestas no deja cambiar el tipo ni la escala', (tester) async {
      final repo = ExamenesFalso();
      final errores = await abrir(
        tester,
        EditorPreguntaSemana(completa: true, pregunta: repo.preguntasSemana.last),
        ancho: 390,
        repo: repo,
      );
      expect(errores, isEmpty, reason: detalle(errores));
      expect(find.text('Ya tiene respuestas: el tipo y la escala no cambian.'), findsOneWidget);
      final tipo = tester.widget<SegmentedButton<String>>(find.byType(SegmentedButton<String>));
      expect(tipo.onSelectionChanged, isNull);
      expect(tipo.selected, {'E'});
    });
  });
}
