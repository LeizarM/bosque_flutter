import 'dart:convert';
import 'dart:io';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/state/postulante_examen_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/importacion_preguntas.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/data/models/tcpe_duplicado_pregunta_model.dart';
import 'package:bosque_flutter/data/models/tcpe_fila_importacion_model.dart';
import 'package:bosque_flutter/data/models/tcpe_pregunta_importar_model.dart';
import 'package:bosque_flutter/data/models/tcpe_resultado_importacion_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_banco_opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_duplicado_pregunta_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_fila_importacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_importar_entity.dart';
import 'package:bosque_flutter/presentation/screens/examenes/banco_preguntas_screen.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/editor_pregunta.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/importar_preguntas.dart';
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

/// Carga de preguntas (contrato 9): la lectura de la plantilla, los models
/// del contrato, el asistente de importación y el aviso de duplicados.
void main() {
  group('Plantilla', () {
    test('la plantilla trae BOM, punto y coma y las columnas del contrato', () {
      final csv = plantillaPreguntasCsv();
      expect(csv.startsWith('﻿'), isTrue);
      final encabezado = csv.substring(1).trim().split(';');
      expect(encabezado, kColumnasPlantilla);
      expect(encabezado.first, 'Pregunta');
      expect(encabezado[1], 'Tipo (Abierta|Cerrada)');
      expect(encabezado.last, 'Correctas (letras, por ejemplo A,C)');
      expect(leerPlantillaPreguntas(csv).vacia, isTrue, reason: 'el encabezado no es una pregunta');
    });

    test('pegado desde Excel: tabulación, cerrada con A,C y abierta que ignora opciones', () {
      const texto =
          'Pregunta\tTipo\tRespuesta modelo\tOpción A\tOpción B\tOpción C\tOpción D\tOpción E\tOpción F\tCorrectas\n'
          '¿Qué protege la vista?\tCerrada\t\tLentes\tGorra\tCareta\t\t\t\tA,C\n'
          'Explica el bloqueo\tAbierta\tCortar energía\tX\tY\t\t\t\t\tA\n';
      final l = leerPlantillaPreguntas(texto);
      expect(l.avisos, isEmpty);
      expect(l.filas, hasLength(2));
      final cerrada = l.filas.first.pregunta;
      expect(cerrada.esCerrada, isTrue);
      expect(cerrada.pregunta, '¿Qué protege la vista?');
      expect([for (final o in cerrada.opciones) o.opcionRspta], ['Lentes', 'Gorra', 'Careta']);
      expect([for (final o in cerrada.opciones) o.esValido], [true, false, true]);
      final abierta = l.filas.last.pregunta;
      expect(abierta.esCerrada, isFalse);
      expect(abierta.respuesta, 'Cortar energía');
      expect(abierta.opciones, isEmpty, reason: 'en las abiertas se ignoran las opciones');
      expect(l.filas.last.linea, 3);
    });

    test('CSV con punto y coma, comillas, saltos de línea dentro de la celda y CRLF', () {
      const texto =
          '﻿Pregunta;Tipo;Respuesta;A;B;C;D;E;F;Correctas\r\n'
          '"¿Cuál es; la ""correcta""?";Cerrada;;"Uno; dos";Tres;;;;;b\r\n'
          '"Describe en dos\r\nrenglones";abierta;"Modelo";;;;;;;\r\n';
      final l = leerPlantillaPreguntas(texto);
      expect(l.avisos, isEmpty);
      expect(l.filas, hasLength(2));
      expect(l.filas[0].pregunta.pregunta, '¿Cuál es; la "correcta"?');
      expect(l.filas[0].pregunta.opciones.map((o) => o.opcionRspta), ['Uno; dos', 'Tres']);
      expect(l.filas[0].pregunta.opciones.map((o) => o.esValido), [false, true]);
      expect(l.filas[1].pregunta.pregunta, 'Describe en dos\r\nrenglones');
      expect(l.filas[1].pregunta.esCerrada, isFalse);
    });

    test('el tipo se reconoce sin importar mayúsculas ni tildes', () {
      final l = leerPlantillaPreguntas('P1;CERRADA;;a;b;;;;;A\nP2;  Abierta ;r\nP3;Cérrada;;a;b;;;;;B\n');
      expect(l.filas.map((f) => f.pregunta.esCerrada), [true, false, true]);
    });

    test('un tipo vacío o desconocido no se incluye y se avisa con su línea', () {
      final l = leerPlantillaPreguntas('P1;Cerrada;;a;b;;;;;A\n\nP2;Múltiple;;a;b\nP3;;;a;b\n');
      expect(l.filas, hasLength(1));
      expect(l.avisos, hasLength(2));
      expect(l.avisos[0], contains('Línea 3'));
      expect(l.avisos[0], contains('Múltiple'));
      expect(l.avisos[1], contains('Línea 4'));
      expect(l.avisos[1], contains('falta el tipo'));
    });

    test('Correctas admite «a; c», «AC», «A C» y avisa letras sin opción o fuera de rango', () {
      List<bool> validas(String correctas) =>
          leerPlantillaPreguntas(
            'P	Cerrada		a	b	c				$correctas',
          ).filas.single.pregunta.opciones.map((o) => o.esValido).toList();
      expect(validas('a; c'), [true, false, true]);
      expect(validas('AC'), [true, false, true]);
      expect(validas('A C'), [true, false, true]);
      expect(validas(''), [false, false, false], reason: 'sin correctas: lo decide el SQL');

      final l = leerPlantillaPreguntas('P;Cerrada;;a;b;;;;;A,E,G');
      expect(l.filas.single.pregunta.opciones.map((o) => o.esValido), [true, false]);
      expect(l.avisos, hasLength(2));
      expect(l.avisos.any((a) => a.contains('«G»')), isTrue);
      expect(l.avisos.any((a) => a.contains('letra E')), isTrue);
    });

    test('la letra apunta a la columna aunque falten opciones antes', () {
      final p = leerPlantillaPreguntas('P;Cerrada;;;b;c;;;;B').filas.single.pregunta;
      expect(p.opciones.map((o) => o.opcionRspta), ['b', 'c']);
      expect(p.opciones.map((o) => o.esValido), [true, false]);
    });

    test('respeta la línea «sep=;» de Excel', () {
      final l = leerPlantillaPreguntas('sep=;\nPregunta;Tipo\nP;Abierta;Modelo\n');
      expect(l.filas.single.pregunta.respuesta, 'Modelo');
    });

    test('un CSV de Excel sin UTF-8 se lee como Latin-1', () {
      final bytes = Uint8List.fromList(latin1.encode('¿Qué?;Abierta;Sí\n'));
      final l = leerPlantillaPreguntas(decodificarCsv(bytes));
      expect(l.filas.single.pregunta.pregunta, '¿Qué?');
      expect(l.filas.single.pregunta.respuesta, 'Sí');
    });
  });

  group('Models del contrato v6', () {
    test('cada pregunta viaja con sus opciones como {opcionRspta, esValido}', () {
      final json =
          TcpePreguntaImportarModel.fromEntity(
            TcpePreguntaImportarEntity(
              pregunta: 'P',
              esCerrada: true,
              opciones: [TcpeBancoOpcionEntity(codRsptaOp: BigInt.zero, opcionRspta: 'a', esValido: true)],
            ),
          ).toJson();
      expect(json.keys, containsAll(['pregunta', 'esCerrada', 'respuesta', 'prioridad', 'opciones']));
      expect(json['opciones'], [
        {'opcionRspta': 'a', 'esValido': true},
      ]);
    });

    test('la fila de la vista previa toma el estado de SQL; uno desconocido es error', () {
      final ok =
          TcpeFilaImportacionModel.fromJson({
            'fila': 1,
            'pregunta': 'P',
            'esCerrada': 1,
            'cantOpciones': 3,
            'cantValidas': 1,
            'estado': 'DUPLICADA_EN_BANCO',
            'mensaje': 'Ya existe.',
            'codPreguntaExistente': 9,
          }).toEntity();
      expect(ok.estado, EstadoFilaImportacion.duplicadaEnBanco);
      expect(ok.esCerrada, isTrue);
      expect(ok.codPreguntaExistente, BigInt.from(9));
      expect(ok.importable, isFalse);
      expect(
        TcpeFilaImportacionModel.fromJson({'fila': 2, 'estado': 'RARO'}).toEntity().estado,
        EstadoFilaImportacion.error,
      );
    });

    test('duplicados con bit 0/1 y resumen de la importación desde el sobre', () {
      final d =
          TcpeDuplicadoPreguntaModel.fromJson({'codPregunta': 4, 'pregunta': 'P', 'activo': 0, 'igual': 1}).toEntity();
      expect(d.igual, isTrue);
      expect(d.activo, isFalse);
      final r =
          TcpeResultadoImportacionModel.fromJson({
            'message': 'Se importaron 3 preguntas.',
            'data': 3,
            'status': 201,
          }).toEntity();
      expect(r.insertadas, 3);
      expect(r.mensaje, 'Se importaron 3 preguntas.');
    });
  });

  group('Pantallas', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    setUp(() => SharedPreferences.setMockInitialValues({}));

    // Con las fuentes reales: con Ahem cada letra es un cuadrado y los anchos no se parecen a la app.
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

    Widget app(Widget home, ExamenesFalso repo) => ProviderScope(
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
        home: Scaffold(body: home),
      ),
    );

    // Los errores de dibujo se juntan solo mientras se bombea: el manejador se
    // restaura antes de cualquier expect, o el binding se cuelga al fallar.
    var errores = <FlutterErrorDetails>[];

    Future<void> esperar(WidgetTester tester, [int veces = 4]) async {
      final previo = FlutterError.onError;
      FlutterError.onError = errores.add;
      try {
        for (var i = 0; i < veces; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
      } finally {
        FlutterError.onError = previo;
      }
    }

    Future<List<FlutterErrorDetails>> montar(WidgetTester tester, Widget home, ExamenesFalso repo, double ancho) async {
      tester.view.physicalSize = Size(ancho, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      errores = <FlutterErrorDetails>[];
      final previo = FlutterError.onError;
      FlutterError.onError = errores.add;
      try {
        await tester.pumpWidget(app(home, repo));
      } finally {
        FlutterError.onError = previo;
      }
      await esperar(tester);
      return errores;
    }

    const filas =
        '¿Qué protege la vista?\tCerrada\t\tLentes\tGorra\tCareta\t\t\t\tA,C\n'
        'Pregunta repetida del banco\tCerrada\t\tSí\tNo\t\t\t\t\tA\n'
        'Una sola opción\tCerrada\t\tSola\t\t\t\t\t\tA\n'
        'Explica el bloqueo\tAbierta\tCortar la energía\n'
        'tipo raro\tMúltiple\n';

    for (final ancho in [360.0, 800.0, 1400.0]) {
      testWidgets('el asistente importa solo las filas OK a $ancho px', (tester) async {
        final repo = ExamenesFalso();
        var importo = false;
        final errores = await montar(
          tester,
          Builder(
            builder:
                (context) => Center(
                  child: FilledButton(
                    onPressed: () async {
                      importo = await abrirImportacionPreguntas(
                        context,
                        codClasificacion: BigInt.from(5),
                        categorias: repo.categorias,
                      );
                    },
                    child: const Text('abrir'),
                  ),
                ),
          ),
          repo,
          ancho,
        );
        await tester.tap(find.text('abrir'));
        await esperar(tester);
        expect(find.text('Importar preguntas'), findsOneWidget);
        expect(
          find.textContaining('Seguridad industrial'),
          findsWidgets,
          reason: 'la categoría del filtro viene elegida',
        );

        await tester.tap(find.text('Siguiente'));
        await esperar(tester);
        expect(find.text('Descargar plantilla CSV'), findsOneWidget);

        await tester.tap(find.text('Ya tengo los datos'));
        await esperar(tester);
        await tester.enterText(find.byKey(const ValueKey('importar-texto')), filas);
        await esperar(tester);
        expect(find.textContaining('4 preguntas leídas'), findsOneWidget);
        expect(
          find.textContaining('Línea 5: el tipo «Múltiple»'),
          findsOneWidget,
          reason: 'aviso de formato con su línea',
        );

        await tester.tap(find.text('Ver vista previa'));
        await esperar(tester, 6);
        expect(repo.validadas, hasLength(4));
        expect(
          find.textContaining('Ya existe una pregunta igual en la categoria.'),
          findsWidgets,
          reason: 'el mensaje del SQL',
        );
        if (ancho >= 600) expect(find.text('Con error (1)'), findsOneWidget, reason: 'chips de estado a la vista');

        // Filtrar por estado deja solo esa fila.
        if (ancho < 600) {
          // En el teléfono el filtro de estado es un combo.
          await tester.tap(find.byKey(const ValueKey('filtro-estado')));
          await esperar(tester);
        }
        await tester.tap(find.text('Con error (1)').last);
        await esperar(tester);
        expect(find.textContaining('Una sola opción'), findsOneWidget);
        expect(find.textContaining('Explica el bloqueo'), findsNothing);

        await tester.tap(find.text('Continuar'));
        await esperar(tester);
        expect(find.text('Importar 2'), findsOneWidget);
        await tester.tap(find.text('Importar 2'));
        await esperar(tester);
        expect(find.text('Importar 2 preguntas'), findsOneWidget, reason: 'confirmación explícita');
        await tester.tap(find.widgetWithText(FilledButton, 'Importar'));
        await esperar(tester, 6);

        expect(repo.importadas, hasLength(4), reason: 'el SP vuelve a validar e inserta solo las OK');
        expect(find.textContaining('Se importaron 2 preguntas; 2 se omitieron'), findsOneWidget);
        expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));

        await tester.tap(find.text('Listo'));
        await esperar(tester);
        expect(importo, isTrue);
      });
    }

    testWidgets('el banco ofrece «Importar preguntas» y el vacío guía a importar', (tester) async {
      final repo = ExamenesFalso()..preguntasBanco.clear();
      final errores = await montar(tester, const BancoPreguntasScreen(), repo, 1400);
      expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
      Finder boton<T>(String texto) =>
          find.ancestor(of: find.text(texto), matching: find.byWidgetPredicate((w) => w is T));
      expect(find.text('El banco está vacío'), findsOneWidget);
      // Tonales los dos: el del membrete y la acción del estado vacío.
      expect(boton<FilledButton>('Importar preguntas'), findsNWidgets(2), reason: 'membrete y estado vacío');
    });

    for (final ancho in [360.0, 1400.0]) {
      testWidgets('el editor avisa de una igual con debounce y enlace a $ancho px', (tester) async {
        final repo =
            ExamenesFalso()
              ..duplicados = [
                TcpeDuplicadoPreguntaEntity(codPregunta: BigInt.from(2), pregunta: '¿Qué elemento...?', igual: true),
              ];
        final errores = await montar(
          tester,
          Builder(
            builder:
                (context) => Center(
                  child: FilledButton(
                    onPressed:
                        () => editarPregunta(context, codClasificacion: BigInt.from(5), categorias: repo.categorias),
                    child: const Text('abrir'),
                  ),
                ),
          ),
          repo,
          ancho,
        );
        await tester.tap(find.text('abrir'));
        await esperar(tester);
        final campo = find.widgetWithText(TextFormField, 'Pregunta');
        await tester.enterText(campo, '¿Qué ele');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.enterText(campo, '¿Qué elemento de protección?');
        await tester.pump(const Duration(milliseconds: 300));
        expect(repo.textosBuscados, isEmpty, reason: 'todavía dentro de los 600 ms');
        await tester.pump(const Duration(milliseconds: 400));
        await esperar(tester, 2);
        expect(repo.textosBuscados, ['¿Qué elemento de protección?'], reason: 'una sola consulta por pausa');
        expect(find.text('Ya existe una pregunta igual en esta categoría'), findsOneWidget);
        expect(find.text('Abrir'), findsOneWidget);
        expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
      });
    }

    testWidgets('el editor muestra las parecidas y no se cuenta a sí misma', (tester) async {
      final repo =
          ExamenesFalso()
            ..duplicados = [
              TcpeDuplicadoPreguntaEntity(codPregunta: BigInt.from(1), pregunta: 'La misma que se edita', igual: true),
              TcpeDuplicadoPreguntaEntity(codPregunta: BigInt.from(3), pregunta: 'Elemento de protección auditiva'),
              TcpeDuplicadoPreguntaEntity(
                codPregunta: BigInt.from(4),
                pregunta: 'Elemento de protección visual',
                activo: false,
              ),
            ];
      await montar(
        tester,
        Builder(
          builder:
              (context) => Center(
                child: FilledButton(
                  onPressed:
                      () => editarPregunta(context, pregunta: repo.preguntasBanco.first, categorias: repo.categorias),
                  child: const Text('abrir'),
                ),
              ),
        ),
        repo,
        1400,
      );
      await tester.tap(find.text('abrir'));
      await esperar(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Pregunta'), 'Elemento de protección');
      await tester.pump(const Duration(milliseconds: 700));
      await esperar(tester, 2);
      expect(find.text('Hay preguntas parecidas'), findsOneWidget);
      expect(find.text('Ya existe una pregunta igual en esta categoría'), findsNothing);
      expect(find.text('Abrir'), findsNWidgets(2));
      expect(find.text('Inactiva'), findsOneWidget, reason: 'la inactiva lleva su pastilla');
    });

    Widget abridor(ExamenesFalso repo, Future<bool> Function(BuildContext context) abrir) => Builder(
      builder: (context) => Center(child: FilledButton(onPressed: () => abrir(context), child: const Text('abrir'))),
    );

    testWidgets('el editor no pide prioridad y la burbuja marca la opción válida', (tester) async {
      final repo = ExamenesFalso();
      final errores = await montar(
        tester,
        abridor(repo, (c) => editarPregunta(c, codClasificacion: BigInt.from(5), categorias: repo.categorias)),
        repo,
        1400,
      );
      await tester.tap(find.text('abrir'));
      await esperar(tester);
      expect(find.text('Prioridad'), findsNothing, reason: 'era un orden del legacy');

      await tester.enterText(find.widgetWithText(TextFormField, 'Pregunta'), '¿Qué gramaje tiene el papel bond?');
      await tester.enterText(find.widgetWithText(TextField, 'Opción a'), '75 g/m²');
      await tester.enterText(find.widgetWithText(TextField, 'Opción b'), '180 g/m²');
      await tester.tap(find.text('a'));
      await tester.pump();
      expect(find.text('1 válida'), findsOneWidget, reason: 'la burbuja rellena cuenta como válida');

      await tester.tap(find.text('Guardar pregunta'));
      await esperar(tester);
      final g = repo.guardada!;
      expect([for (final o in g.opciones) (o.opcionRspta, o.esValido)], [('75 g/m²', true), ('180 g/m²', false)]);
      expect(g.pregunta.prioridad, isNull);
      expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
    });

    testWidgets('editar conserva la prioridad que ya tenía la pregunta', (tester) async {
      final repo = ExamenesFalso();
      // La primera del banco es abierta: guarda sin cargar opciones.
      final p = repo.preguntasBanco.first.copyWith(prioridad: 7, respuesta: 'Cortar la energía y bloquear.');
      await montar(tester, abridor(repo, (c) => editarPregunta(c, pregunta: p, categorias: repo.categorias)), repo, 1400);
      await tester.tap(find.text('abrir'));
      await esperar(tester);
      await tester.tap(find.text('Guardar pregunta'));
      await esperar(tester);
      expect(repo.guardada!.pregunta.prioridad, 7);
    });
  });
}
