import 'dart:io';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/state/postulante_examen_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/presentation/screens/examen_publico/ingreso_examen_screen.dart';
import 'package:bosque_flutter/presentation/screens/examen_publico/registro_examen_screen.dart';
import 'package:bosque_flutter/presentation/screens/examen_publico/rendir_examen_screen.dart';
import 'package:bosque_flutter/presentation/screens/examen_publico/resultado_examen_screen.dart';
import 'package:bosque_flutter/presentation/screens/examenes/banco_preguntas_screen.dart';
import 'package:bosque_flutter/presentation/screens/examenes/en_vivo_examen_screen.dart';
import 'package:bosque_flutter/presentation/screens/examenes/informes_examen_screen.dart';
import 'package:bosque_flutter/presentation/screens/examenes/lotes_examen_screen.dart';
import 'package:bosque_flutter/presentation/screens/examenes/mis_examenes_screen.dart';
import 'package:bosque_flutter/presentation/screens/examenes/resultados_examen_screen.dart';
import 'package:bosque_flutter/presentation/screens/examenes/usuarios_externos_screen.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/rendicion_examen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'fakes/repositorio_depositos.dart' show loginAdminFalso;
import 'fakes/repositorio_examenes.dart';
import 'fakes/repositorio_rendicion_examen.dart';

/// Las pantallas del módulo de exámenes con datos falsos: sin desbordes en
/// teléfono, tablet y escritorio; tabla con columnas en el ancho y tarjetas
/// con menú en el angosto.
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

  Widget app(Widget pantalla, ExamenesFalso repo, PostulanteFalso postulante, {double escala = 1}) => ProviderScope(
    overrides: [
      userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(loginAdminFalso)),
      examenesRepositoryProvider.overrideWithValue(repo),
      postulanteExamenRepositoryProvider.overrideWithValue(postulante),
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
          (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(escala)),
            child: ResponsiveBreakpoints.builder(child: child!, breakpoints: ResponsiveUtilsBosque.breakpoints),
          ),
      home: Scaffold(body: pantalla),
    ),
  );

  /// Monta, espera los datos y devuelve los errores de dibujo (desbordes).
  Future<List<FlutterErrorDetails>> abrir(
    WidgetTester tester,
    Widget pantalla, {
    required double ancho,
    ExamenesFalso? repo,
    PostulanteFalso? postulante,
    double escala = 1,
  }) async {
    tester.view.physicalSize = Size(ancho, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final errores = <FlutterErrorDetails>[];
    final previo = FlutterError.onError;
    FlutterError.onError = errores.add;
    try {
      await tester.pumpWidget(app(pantalla, repo ?? ExamenesFalso(), postulante ?? PostulanteFalso(), escala: escala));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    } finally {
      // Se restaura antes de cualquier expect: si no, el binding se cuelga.
      FlutterError.onError = previo;
    }
    return errores;
  }

  /// Desmonta todo para que el reloj de la rendición no quede corriendo.
  Future<void> cerrar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  for (final ancho in [360.0, 390.0, 800.0, 1400.0]) {
    final escritorio = ancho >= 1000;

    testWidgets('Banco de preguntas a $ancho px', (tester) async {
      final errores = await abrir(tester, const BancoPreguntasScreen(), ancho: ancho);
      expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
      expect(find.text('Banco de preguntas'), findsOneWidget);
      if (escritorio) {
        expect(find.text('PREGUNTA'), findsOneWidget, reason: 'tabla con columnas');
        expect(find.text('Áreas y categorías'), findsOneWidget, reason: 'panel lateral visible');
      }
      if (ancho < 760) {
        expect(find.text('PREGUNTA'), findsNothing, reason: 'en el teléfono son tarjetas');
        expect(find.byIcon(Icons.more_vert), findsWidgets, reason: 'acciones en menú');
        expect(find.text('Filtros (0)'), findsNothing);
        expect(find.text('Filtros'), findsOneWidget, reason: 'filtros plegados');
      }
      await cerrar(tester);
    });

    testWidgets('Lotes a $ancho px', (tester) async {
      final errores = await abrir(tester, const LotesExamenScreen(), ancho: ancho);
      expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
      expect(find.textContaining('Convocatoria operadores'), findsOneWidget);
      expect(find.textContaining('1 vencidos'), findsOneWidget);

      // El detalle de un lote escrito no ofrece credenciales.
      await tester.tap(find.textContaining('Examen escrito de contabilidad'));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
      expect(find.byType(TiraEstados), findsOneWidget, reason: 'el panel del lote es la tira de estados');
      if (ancho < 760) {
        // En el teléfono las salidas en papel van en el menú del lote.
        await tester.tap(find.byTooltip('Más acciones del lote'));
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
      }
      expect(find.text('Solucionario'), findsOneWidget);
      expect(find.text('Credenciales'), findsNothing);
      await cerrar(tester);
    });

    testWidgets('Resultados a $ancho px', (tester) async {
      final errores = await abrir(tester, ResultadosExamenScreen(loteInicial: BigInt.from(40)), ancho: ancho);
      expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
      expect(find.text('Ana María Quispe Mamani'), findsOneWidget);
      expect(find.textContaining('Por revisar'), findsWidgets);
      await cerrar(tester);
    });

    testWidgets('Usuarios externos a $ancho px', (tester) async {
      final errores = await abrir(tester, const UsuariosExternosScreen(), ancho: ancho);
      expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
      expect(find.text('IPX-56'), findsOneWidget);
      expect(find.text('IPX-57'), findsNothing, reason: 'inactivo: el filtro arranca en activos');
      expect(find.text('Proteger claves antiguas'), findsOneWidget, reason: 'el admin puede migrar');
      await cerrar(tester);
    });

    testWidgets('Mis exámenes a $ancho px', (tester) async {
      final errores = await abrir(tester, const MisExamenesScreen(), ancho: ancho);
      expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
      expect(find.text('Continuar'), findsOneWidget);
      await cerrar(tester);
    });

    testWidgets('Rendición en curso a $ancho px', (tester) async {
      final repo = ExamenesFalso();
      final errores = await abrir(
        tester,
        RendicionExamen(clave: ClaveRendicion(OrigenRendicion.empleado, BigInt.from(10))),
        ancho: ancho,
        repo: repo,
      );
      expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
      expect(find.text('PREGUNTA 1 DE 3'), findsOneWidget);
      expect(find.byType(RelojExamen), findsOneWidget);
      expect(find.text('Guantes anticorte'), findsOneWidget);
      // Nunca aparece cuál es la válida: las opciones no traen esValido.
      expect(find.textContaining('válida'), findsNothing);
      expect(find.text('Hoja de respuestas'), ancho >= 900 ? findsOneWidget : findsNothing);

      await tester.tap(find.text('Guantes anticorte'));
      await tester.pump();
      expect(repo.respuestas.single.opciones, [BigInt.from(101)]);
      await cerrar(tester);
    });

    testWidgets('Rendición sin iniciar a $ancho px', (tester) async {
      final errores = await abrir(
        tester,
        RendicionExamen(clave: ClaveRendicion(OrigenRendicion.empleado, BigInt.from(10))),
        ancho: ancho,
        repo: ExamenesFalso(estado: 'SIN_INICIAR'),
      );
      expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
      expect(find.text('Comenzar examen'), findsOneWidget);
      await cerrar(tester);
    });

    testWidgets('Ingreso del postulante a $ancho px', (tester) async {
      final postulante = PostulanteFalso();
      final errores = await abrir(tester, const IngresoExamenScreen(), ancho: ancho, postulante: postulante);
      expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
      expect(find.text('Ingresa a tu examen'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'Usuario'), 'IPX-56');
      await tester.enterText(find.widgetWithText(TextFormField, 'Clave'), 'Kq7mZt9wHp');
      await tester.tap(find.text('Ingresar'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.text('Hola, Ana'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
      await cerrar(tester);
    });

    testWidgets('En vivo a $ancho px', (tester) async {
      final repo = ExamenesFalso();
      final errores = await abrir(tester, EnVivoExamenScreen(loteInicial: BigInt.from(40)), ancho: ancho, repo: repo);
      expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
      expect(find.text('Ana María Quispe Mamani'), findsOneWidget);
      expect(find.text('Conectado'), findsOneWidget);
      expect(find.text('Desconectado'), findsOneWidget);
      if (escritorio) {
        expect(find.text('CONEXIÓN'), findsOneWidget, reason: 'tabla con columnas');
        expect(find.text('Pregunta 8 de 20'), findsOneWidget);
      } else if (ancho < 760) {
        expect(find.text('CONEXIÓN'), findsNothing, reason: 'en el teléfono son tarjetas');
        expect(find.textContaining('2 salidas de la pestaña'), findsOneWidget);
      }
      await cerrar(tester);
    });

    testWidgets('Informes a $ancho px', (tester) async {
      final errores = await abrir(tester, const InformesExamenScreen(), ancho: ancho);
      expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
      expect(find.text('EXÁMENES · INFORMES'), findsOneWidget, reason: 'membrete con folio');
      expect(find.text('Elige el periodo y consulta'), findsOneWidget, reason: 'estado vacío con guía');
      await cerrar(tester);
    });

    testWidgets('Detalle de un lote en línea a $ancho px', (tester) async {
      final errores = await abrir(tester, const LotesExamenScreen(), ancho: ancho);
      await tester.tap(find.textContaining('Convocatoria operadores'));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
      expect(find.text('LOTE N° 40 · EN LÍNEA'), findsOneWidget);
      expect(find.textContaining('2 por revisar'), findsWidgets, reason: 'leyenda de la tira');
      expect(find.text('Agregar exámenes'), findsOneWidget);
      if (ancho >= 760) expect(find.text('Credenciales'), findsOneWidget, reason: 'acciones en línea en escritorio');
      await cerrar(tester);
    });

    testWidgets('Registro del postulante a $ancho px', (tester) async {
      final errores = await abrir(tester, const RegistroExamenScreen(), ancho: ancho);
      expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
      expect(find.text('Tus datos'), findsOneWidget);
      expect(find.text('Guardar y continuar'), findsOneWidget);
      await cerrar(tester);
    });

    testWidgets('Resultado del postulante a $ancho px', (tester) async {
      final errores = await abrir(
        tester,
        const ResultadoExamenScreen(codExamen: '10'),
        ancho: ancho,
        postulante: PostulanteFalso(estado: 'CALIFICADO'),
      );
      expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
      expect(find.text('Examen calificado'), findsOneWidget);
      expect(find.text('Tus respuestas'), findsOneWidget);
      await cerrar(tester);
    });

    testWidgets('Rendición del postulante a $ancho px', (tester) async {
      final errores = await abrir(
        tester,
        const RendirExamenScreen(codExamen: '10'),
        ancho: ancho,
        postulante: PostulanteFalso(),
      );
      expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
      expect(find.text('Evaluaciones'), findsOneWidget);
      expect(find.text('PREGUNTA 1 DE 3'), findsOneWidget);
      await cerrar(tester);
    });
  }
  // Accesibilidad: con la letra del sistema al 130 % ninguna pantalla rediseñada se desborda.
  for (final ancho in [360.0, 1400.0]) {
    final pantallas = <String, Widget>{
      'Banco': const BancoPreguntasScreen(),
      'Lotes': const LotesExamenScreen(),
      'Resultados': ResultadosExamenScreen(loteInicial: BigInt.from(40)),
      'Informes': const InformesExamenScreen(),
      'Usuarios externos': const UsuariosExternosScreen(),
      'Mis exámenes': const MisExamenesScreen(),
      'En vivo': EnVivoExamenScreen(loteInicial: BigInt.from(40)),
      'Ingreso': const IngresoExamenScreen(),
      'Registro': const RegistroExamenScreen(),
    };
    for (final MapEntry(key: nombre, value: pantalla) in pantallas.entries) {
      testWidgets('$nombre con letra al 130 % a $ancho px', (tester) async {
        final errores = await abrir(tester, pantalla, ancho: ancho, escala: 1.3);
        expect(errores, isEmpty, reason: errores.map((e) => e.exceptionAsString()).join('\n'));
        await cerrar(tester);
      });
    }
  }

  testWidgets('registro: basta un apellido, paterno o materno', (tester) async {
    final postulante = PostulanteFalso();
    await abrir(tester, const RegistroExamenScreen(), ancho: 390, postulante: postulante);
    const aviso = 'Escribe al menos un apellido: paterno o materno';
    await tester.enterText(find.widgetWithText(TextFormField, 'Carnet de identidad'), '84369585');
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombres'), 'Marcelo');
    await tester.tap(find.text('Guardar y continuar'));
    await tester.pump();
    expect(find.text(aviso), findsOneWidget, reason: 'sin ningún apellido');
    expect(postulante.registros, 0);
    await tester.enterText(find.widgetWithText(TextFormField, 'Apellido materno'), 'Jaimes');
    await tester.tap(find.text('Guardar y continuar'));
    await tester.pump();
    expect(find.text(aviso), findsNothing, reason: 'solo el materno basta');
    expect(postulante.registros, 1);
    await cerrar(tester);
  });

  testWidgets('teléfono: la hoja de respuestas también tiene «Revisar y entregar»', (tester) async {
    final repo = ExamenesFalso();
    final errores = await abrir(
      tester,
      RendicionExamen(clave: ClaveRendicion(OrigenRendicion.empleado, BigInt.from(10))),
      ancho: 390,
      repo: repo,
    );
    expect(errores, isEmpty);
    expect(find.text('Revisar y entregar'), findsNothing, reason: 'pregunta 1 de 3: el pie dice «Siguiente»');
    await tester.tap(find.byTooltip('Hoja de respuestas'));
    await tester.pumpAndSettle();
    expect(find.text('Revisar y entregar'), findsOneWidget);
    await tester.tap(find.text('Revisar y entregar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Entregar el examen?'), findsOneWidget);
    expect(find.textContaining('Respondiste 0 de 3'), findsOneWidget);
    await cerrar(tester);
  });

  testWidgets('En vivo: el panel se refresca solo y se pausa si la app no se ve', (tester) async {
    final repo = ExamenesFalso();
    await abrir(tester, EnVivoExamenScreen(loteInicial: BigInt.from(40)), ancho: 1400, repo: repo);
    final inicial = repo.consultasMonitor;
    expect(inicial, greaterThanOrEqualTo(1));
    await tester.pump(const Duration(seconds: 5));
    expect(repo.consultasMonitor, inicial + 1, reason: 'segundosRefrescoPanel = 5 por defecto');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump(const Duration(seconds: 20));
    expect(repo.consultasMonitor, inicial + 1, reason: 'sin consultar mientras no se ve');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(repo.consultasMonitor, inicial + 2, reason: 'al volver, consulta enseguida');
    await cerrar(tester);
  });
}
