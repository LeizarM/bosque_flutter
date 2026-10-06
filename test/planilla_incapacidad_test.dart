import 'dart:io';

import 'package:bosque_flutter/core/state/planilla_incapacidad_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/presentation/screens/planilla-incapacidad/planilla_incapacidad_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'fakes/repositorio_planilla_incapacidad.dart';

/// Planilla de Incapacidad con un repositorio falso: abre sin desbordes en
/// móvil, tablet y escritorio, formatea 12,345.67 y la revisión se guarda o
/// vuelve atrás si el servidor la rechaza.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepoPlanillaIncapacidadFalso repo;

  // Con la fuente de reemplazo el texto se ensancha y aparecen desbordes que la
  // app no tiene (ver depositos_cheques_pantallas_test.dart).
  setUpAll(() async {
    Future<void> cargar(String familia, List<String> archivos) async {
      final cargador = FontLoader(familia);
      for (final archivo in archivos) {
        final f = File('assets/fonts/$archivo.ttf');
        if (f.existsSync()) {
          cargador.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
        }
      }
      await cargador.load();
    }

    await cargar('Roboto', ['Roboto-Regular', 'Roboto-Medium', 'Roboto-Bold']);
    await cargar('PlusJakartaSans', [
      'PlusJakartaSans-400',
      'PlusJakartaSans-500',
      'PlusJakartaSans-600',
      'PlusJakartaSans-700',
    ]);
  });

  setUp(() => repo = RepoPlanillaIncapacidadFalso());

  Widget app({double escalaTexto = 1}) => ProviderScope(
    overrides: [planillaIncapacidadRepoProvider.overrideWithValue(repo)],
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
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(escalaTexto)),
            child: ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: ResponsiveUtilsBosque.breakpoints,
            ),
          ),
      home: const Scaffold(
        body: _UnFotogramaDespues(child: PlanillaIncapacidadScreen()),
      ),
    ),
  );

  Future<void> abrir(
    WidgetTester tester, {
    double ancho = 1400,
    double escalaTexto = 1,
  }) async {
    tester.view.physicalSize = Size(ancho, ancho <= 450 ? 844 : 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(escalaTexto: escalaTexto));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  for (final (ancho, escala) in [
    (390.0, 1.0),
    (800.0, 1.0),
    (1100.0, 1.0),
    (1400.0, 1.0),
    (390.0, 1.5),
    (1400.0, 1.5),
  ]) {
    testWidgets('sin desborde a ${ancho.toInt()} px, texto ×$escala', (
      tester,
    ) async {
      final errores = <FlutterErrorDetails>[];
      final previo = FlutterError.onError;
      FlutterError.onError = errores.add;

      await abrir(tester, ancho: ancho, escalaTexto: escala);
      // En compacto filtros, resumen y tarjetas comparten un scroll: con texto
      // grande la primera tarjeta queda debajo del pliegue.
      final nombre = find.text('Huanca Soto Maria Elizabeth');
      if (ancho < 1060) {
        await tester.scrollUntilVisible(
          nombre,
          300,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
      }
      FlutterError.onError = previo;

      expect(nombre, findsOneWidget);
      for (final e in errores) {
        debugPrint('DETALLE a $ancho ×$escala:\n$e');
      }
      expect(errores, isEmpty);
    });
  }

  testWidgets('periodo con hora, seguro de la afiliación y encabezado genérico', (
    tester,
  ) async {
    await abrir(tester);
    expect(find.text('01/06/2026 08:30'), findsOneWidget);
    expect(find.text('19/06/2026 18:30'), findsOneWidget);
    expect(find.text('CORDES ESPPAPEL - LA PAZ · Nº 9876543210'), findsOneWidget);
    expect(find.text('CORDES ESPPAPEL - LA PAZ · sin Nº'), findsOneWidget);
    expect(find.text('Días seguro'), findsOneWidget);
    expect(find.text('CORDES'), findsNothing);
  });

  testWidgets('importes con coma de miles y punto decimal', (tester) async {
    await abrir(tester);
    expect(find.text('16,100.00'), findsWidgets);
    expect(find.text('7,082.50'), findsWidgets);
  });

  testWidgets('marcar una pendiente la guarda como revisada', (tester) async {
    await abrir(tester);
    expect(find.text('Revisada'), findsOneWidget);

    await tester.tap(find.text('Pendiente').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repo.marcadas, [(1, true)]);
    expect(find.text('Revisada'), findsNWidgets(2));
    expect(find.text('2 de 3 revisadas'), findsOneWidget);
  });

  testWidgets('si el servidor rechaza, vuelve a pendiente y avisa', (
    tester,
  ) async {
    repo.fallarAlMarcar = true;
    await abrir(tester);

    await tester.tap(find.text('Pendiente').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Pendiente'), findsNWidgets(2));
    expect(find.textContaining('Actualiza la lista'), findsOneWidget);
    // Que el aviso termine antes de cerrar la prueba.
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('rango sin bajas explica por qué', (tester) async {
    repo.filas = [];
    await abrir(tester);
    expect(find.text('No hay bajas que empiecen en este rango'), findsOneWidget);
  });
}

/// Monta la pantalla un fotograma después, como el dashboard: antes los
/// breakpoints no están resueltos.
class _UnFotogramaDespues extends StatefulWidget {
  const _UnFotogramaDespues({required this.child});

  final Widget child;

  @override
  State<_UnFotogramaDespues> createState() => _UnFotogramaDespuesState();
}

class _UnFotogramaDespuesState extends State<_UnFotogramaDespues> {
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _listo = true);
    });
  }

  @override
  Widget build(BuildContext context) =>
      _listo ? widget.child : const SizedBox.shrink();
}
