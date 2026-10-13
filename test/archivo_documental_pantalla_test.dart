import 'dart:io';

import 'package:bosque_flutter/core/state/archivo_documental_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/foto_caja_entity.dart';
import 'package:bosque_flutter/domain/repositories/archivo_documental_repository.dart';
import 'package:bosque_flutter/presentation/screens/archivo-documental/archivo_documental_screen.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/fotos_caja.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/tabla_cajas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'fakes/repositorio_archivo_documental.dart';
import 'fakes/repositorio_depositos.dart' show loginAdminFalso;

/// «Almacenaje de documentos» con un repositorio falso: sin desbordes en teléfono,
/// tablet y escritorio, tabla o tarjetas según el ancho del cajón, y que
/// buscar, abrir una caja, registrar contenido y subir una foto funcionen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorioArchivoFalso repo;

  /// Lo que se mandó al visor de PDF (en las pruebas no se monta PdfPreview).
  late List<String> pdfsVistos;

  // Con la fuente real los desbordes que aparecen son reales.
  setUpAll(() async {
    final cargador = FontLoader('Roboto');
    for (final archivo in ['Roboto-Regular', 'Roboto-Medium', 'Roboto-Bold']) {
      final f = File('assets/fonts/$archivo.ttf');
      if (f.existsSync()) cargador.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
    await cargador.load();
  });

  setUp(() {
    repo = RepositorioArchivoFalso();
    pdfsVistos = [];
  });

  Widget app() => ProviderScope(
    overrides: [
      userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(loginAdminFalso)),
      archivoDocumentalRepositoryProvider.overrideWithValue(repo),
      elegirFotoProvider.overrideWithValue((_) async => FotoElegida(pngDePrueba, 'caja.png')),
      camaraDisponibleProvider.overrideWithValue(false),
      visorPdfArchivoProvider.overrideWithValue((
        BuildContext context, {
        required Uint8List bytes,
        required String titulo,
        required String nombreArchivo,
      }) async {
        pdfsVistos.add(titulo);
      }),
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
      home: const Scaffold(body: _UnFotogramaDespues(child: ArchivoDocumentalScreen())),
    ),
  );

  Future<void> esperar(WidgetTester tester) async {
    // pump() y no pumpAndSettle(): el esqueleto anima en bucle.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<List<FlutterErrorDetails>> abrir(WidgetTester tester, {double ancho = 1400, double alto = 900}) async {
    tester.view.physicalSize = Size(ancho, alto);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final errores = <FlutterErrorDetails>[];
    final previo = FlutterError.onError;
    FlutterError.onError = errores.add;
    await tester.pumpWidget(app());
    await esperar(tester);
    FlutterError.onError = previo;
    return errores;
  }

  Future<void> abrirCaja2(WidgetTester tester) async {
    // hitTestable: el combo de tipos guarda copias ocultas del texto para medirse.
    await tester.tap(find.text('Facturas').hitTestable().first);
    await esperar(tester);
  }

  /// Los avisos se cierran solos con un temporizador: se deja que venza.
  Future<void> dejarVencerAvisos(WidgetTester tester) => tester.pump(const Duration(seconds: 15));

  // ── Sin desbordes y con el diseño de cada ancho ─────────────────────────

  for (final ancho in [390.0, 600.0, 800.0, 1400.0]) {
    testWidgets('el listado abre sin desborde a ${ancho.toInt()} px', (tester) async {
      final errores = await abrir(tester, ancho: ancho, alto: ancho <= 450 ? 844 : 900);
      expect(find.text('Almacenaje de documentos'), findsOneWidget);
      for (final e in errores) {
        debugPrint('DETALLE a $ancho:\n$e');
      }
      expect(errores, isEmpty, reason: 'ancho $ancho');
    });
  }

  testWidgets('desde 720 px: tabla con columnas y ubicación explícita', (tester) async {
    await abrir(tester, ancho: 1400);
    expect(find.text('UBICACIÓN'), findsOneWidget);
    expect(find.byType(TarjetaCaja), findsNothing);
    expect(find.text('3 cajas · 5 documentos'), findsOneWidget);
    expect(find.text('Sin ubicación'), findsNWidgets(2));
    expect(find.text('Estante 1 · Fila 1'), findsOneWidget);
  });

  testWidgets('debajo de 720 px: tarjetas, filtros plegados y alta flotante', (tester) async {
    await abrir(tester, ancho: 390, alto: 844);
    expect(find.byType(TarjetaCaja), findsNWidgets(3));
    expect(find.text('UBICACIÓN'), findsNothing);
    expect(find.text('Filtros'), findsOneWidget);
    expect(find.text('Nueva caja'), findsOneWidget);
  });

  testWidgets('sin cajas explica qué hacer', (tester) async {
    repo = RepositorioArchivoFalso(vacio: true);
    await abrir(tester);
    expect(find.text('Todavía no hay cajas registradas'), findsOneWidget);
  });

  testWidgets('si la lectura falla ofrece reintentar', (tester) async {
    repo = RepositorioArchivoFalso(fallaLectura: true);
    await abrir(tester);
    expect(find.textContaining('No se pudo conectar'), findsOneWidget);
  });

  // ── Búsqueda ────────────────────────────────────────────────────────────

  testWidgets('buscar sin tilde encuentra el documento y cuenta las coincidencias', (tester) async {
    await abrir(tester);
    await tester.enterText(find.byType(TextField).first, 'remision');
    await esperar(tester);
    expect(find.text('1 de 3 cajas · 1 documento coinciden'), findsOneWidget);
    expect(find.text('Notas de remisión Suc. 8 enero 2010'), findsOneWidget);
  });

  // ── Detalle de una caja ─────────────────────────────────────────────────

  for (final ancho in [390.0, 1400.0]) {
    testWidgets('la caja abierta se ve sin desborde a ${ancho.toInt()} px', (tester) async {
      await abrir(tester, ancho: ancho, alto: ancho <= 450 ? 844 : 900);
      final errores = <FlutterErrorDetails>[];
      final previo = FlutterError.onError;
      FlutterError.onError = errores.add;
      await abrirCaja2(tester);
      FlutterError.onError = previo;

      expect(find.text('Caja 2'), findsOneWidget);
      expect(find.text('Fotos'), findsWidgets);
      expect(find.text('Agregar foto'), findsOneWidget);
      expect(find.text('Sucursal: Sucursal 15 Achocalla · LA PAZ'), findsOneWidget);
      expect(find.text('Facturas emisores septiembre 2016'), findsOneWidget);
      for (final e in errores) {
        debugPrint('DETALLE a $ancho:\n$e');
      }
      expect(errores, isEmpty, reason: 'ancho $ancho');
    });
  }

  testWidgets('volver cierra la caja y deja el listado como estaba', (tester) async {
    await abrir(tester);
    await abrirCaja2(tester);
    await tester.tap(find.byTooltip('Volver a las cajas'));
    await esperar(tester);
    expect(find.text('3 cajas · 5 documentos'), findsOneWidget);
  });

  testWidgets('una gestión sin año se marca en el campo y no se envía', (tester) async {
    await abrir(tester);
    await abrirCaja2(tester);
    await tester.tap(find.text('Agregar documento'));
    await esperar(tester);

    await tester.tap(find.byType(DropdownMenu<int>).first);
    await esperar(tester);
    await tester.tap(find.widgetWithText(MenuItemButton, 'Facturas').hitTestable().first);
    await esperar(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Detalle *'), 'Facturas de prueba');
    await tester.enterText(find.widgetWithText(TextFormField, 'Gestión'), 'sin anio');
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Agregar documento')));
    await esperar(tester);

    expect(find.textContaining('Incluye al menos un año'), findsOneWidget);
    expect(repo.escrituras, isEmpty);

    await tester.enterText(find.widgetWithText(TextFormField, 'Gestión'), '2018 - 2019');
    await esperar(tester);
    expect(find.text('Años que cubre: 2018 – 2019'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Agregar documento')));
    await esperar(tester);
    expect(repo.escrituras.single, 'contenido 0 caja 2 tipo 10 "Facturas de prueba" gestion 2018 - 2019');
    await dejarVencerAvisos(tester);
  });

  testWidgets('agregar una foto la sube a la caja abierta (las fotos son opcionales)', (tester) async {
    await abrir(tester);
    await abrirCaja2(tester);
    await tester.tap(find.text('Agregar foto'));
    await esperar(tester);
    expect(repo.escrituras.single, 'subir foto caja 2 caja.png');
    await dejarVencerAvisos(tester);
  });

  testWidgets('nueva caja propone el número que sigue en el archivo elegido', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Nueva caja'));
    await esperar(tester);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await esperar(tester);
    await tester.tap(find.text('ACHOCALLA').hitTestable().last);
    await esperar(tester);
    expect(find.widgetWithText(TextFormField, '3'), findsOneWidget);
  });

  for (final ancho in [390.0, 1400.0]) {
    testWidgets('los catálogos abren sin desborde a ${ancho.toInt()} px', (tester) async {
      await abrir(tester, ancho: ancho, alto: ancho <= 450 ? 844 : 900);
      final errores = <FlutterErrorDetails>[];
      final previo = FlutterError.onError;
      FlutterError.onError = errores.add;
      await tester.tap(find.byTooltip('Catálogos: archivos y tipos de documento').evaluate().isEmpty
          ? find.text('Catálogos')
          : find.byTooltip('Catálogos: archivos y tipos de documento'));
      await esperar(tester);
      FlutterError.onError = previo;

      expect(find.text('Tipos de documento'), findsOneWidget);
      expect(find.text('OFICINA CENTRAL').hitTestable(), findsOneWidget);
      expect(errores, isEmpty, reason: 'ancho $ancho');
    });
  }

  testWidgets('una caja con contenido no se intenta eliminar: se explica por qué', (tester) async {
    await abrir(tester);
    await tester.tap(find.byTooltip('Eliminar la caja 2').first);
    await esperar(tester);
    expect(find.textContaining('elimínalos o muévelos'), findsOneWidget);
    expect(repo.escrituras, isEmpty);
    await dejarVencerAvisos(tester);
  });

  // ── Archivos, reportes, visor y letra grande ────────────────────────────

  testWidgets('el chip de un archivo filtra sus cajas y muestra su sucursal', (tester) async {
    await abrir(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'OFICINA CENTRAL  1'));
    await esperar(tester);
    expect(find.text('1 de 3 cajas · 2 documentos coinciden'), findsOneWidget);
    expect(find.byTooltip('Sucursal: Central · LA PAZ'), findsOneWidget);
  });

  testWidgets('un reporte sale con la sucursal del archivo elegido y se ve en el visor', (tester) async {
    await abrir(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'ACHOCALLA  2'));
    await esperar(tester);
    await tester.tap(find.text('Reportes'));
    await esperar(tester);
    await tester.tap(find.text('Dónde está cada tipo de documento'));
    await esperar(tester);
    await tester.tap(find.text('Ver PDF'));
    await esperar(tester);

    final p = repo.pedidos.single;
    expect(p.reporte, ReporteArchivo.porTipo);
    expect(p.codSucursal, 15, reason: 'ACHOCALLA está en la sucursal 15');
    expect(pdfsVistos, ['Dónde está cada tipo de documento']);
  });

  testWidgets('un reporte sin documentos dice por qué y no abre el visor', (tester) async {
    await abrir(tester);
    repo.rechazo = 'No hay documentos que cumplan esos filtros. Prueba quitando alguno.';
    await tester.tap(find.text('Reportes'));
    await esperar(tester);
    await tester.tap(find.text('Ver PDF'));
    await esperar(tester);
    expect(find.textContaining('No hay documentos que cumplan'), findsOneWidget);
    expect(pdfsVistos, isEmpty);
  });

  testWidgets('años al revés no llegan a pedir el reporte', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Reportes'));
    await esperar(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Gestión desde'), '2020');
    await tester.enterText(find.widgetWithText(TextField, 'Gestión hasta'), '2010');
    await tester.tap(find.text('Ver PDF'));
    await esperar(tester);
    expect(find.textContaining('no puede ser mayor'), findsOneWidget);
    expect(repo.pedidos, isEmpty);
  });

  for (final ancho in [390.0, 1400.0]) {
    testWidgets('los reportes abren sin desborde a ${ancho.toInt()} px', (tester) async {
      await abrir(tester, ancho: ancho, alto: ancho <= 450 ? 844 : 900);
      final errores = <FlutterErrorDetails>[];
      final previo = FlutterError.onError;
      FlutterError.onError = errores.add;
      await tester.tap(
        find.byTooltip('Reportes en PDF').evaluate().isEmpty ? find.text('Reportes') : find.byTooltip('Reportes en PDF'),
      );
      await esperar(tester);
      FlutterError.onError = previo;
      expect(find.text('Reportes del archivo'), findsOneWidget);
      expect(errores, isEmpty, reason: 'ancho $ancho');
    });
  }

  testWidgets('la caja con foto la muestra en la lista y en grande, y desde ahí se elimina', (tester) async {
    repo.fotos.add(const FotoCajaEntity(codFoto: 7, codCaja: 2, orden: 1, ruta: 'archivo-cajas/7.png'));
    repo.cajas[1] = const CajaArchivoEntity(
      codCaja: 2,
      codArchivo: 1,
      numero: 2,
      nombreArchivo: 'ACHOCALLA',
      lineas: 2,
      fotos: 1,
      anioDesde: 2015,
      anioHasta: 2017,
      codFotoPortada: 7,
      rutaPortada: 'archivo-cajas/7.png',
    );
    final semantica = tester.ensureSemantics();
    await abrir(tester);
    // La fila es un botón: el lector de pantalla une su etiqueta con la de sus celdas.
    expect(find.bySemanticsLabel(RegExp('Caja 2, con foto')), findsOneWidget);
    semantica.dispose();

    await abrirCaja2(tester);
    await tester.tap(find.descendant(of: find.byType(FotosCaja), matching: find.byType(Image)).first);
    await esperar(tester);
    expect(find.text('Foto 1 de 1'), findsOneWidget);

    await tester.tap(find.text('Eliminar').hitTestable());
    await esperar(tester);
    await tester.tap(find.text('Eliminar foto'));
    await esperar(tester);
    expect(repo.escrituras.single, 'eliminar foto 7');
    await dejarVencerAvisos(tester);
  });

  testWidgets('con letra grande (160 %) el listado y la caja no desbordan a 390 px', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final errores = await abrir(tester, ancho: 390, alto: 844);
    final previo = FlutterError.onError;
    FlutterError.onError = errores.add;
    await abrirCaja2(tester);
    FlutterError.onError = previo;
    for (final e in errores) {
      debugPrint('DETALLE letra grande: $e');
    }
    expect(errores, isEmpty);
  });
}

/// En la app la pantalla se monta cuando los breakpoints ya se resolvieron.
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
  Widget build(BuildContext context) => _listo ? widget.child : const SizedBox.shrink();
}
