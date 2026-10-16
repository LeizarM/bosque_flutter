import 'dart:io';

import 'package:bosque_flutter/core/state/archivo_documental_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/contenido_caja_entity.dart';
import 'package:bosque_flutter/domain/entities/entrega_documento_entity.dart';
import 'package:bosque_flutter/domain/entities/foto_caja_entity.dart';
import 'package:bosque_flutter/domain/entities/prestamo_documento_entity.dart';
import 'package:bosque_flutter/domain/repositories/archivo_documental_repository.dart';
import 'package:bosque_flutter/presentation/screens/archivo-documental/archivo_documental_screen.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/comun_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/detalle_caja.dart';
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

  /// El detalle de la caja es una lista perezosa: lo de abajo no existe hasta acercarse.
  Future<void> bajarHasta(WidgetTester tester, Finder buscado) async {
    await tester.scrollUntilVisible(buscado, 300, scrollable: find.byType(Scrollable).first);
    await esperar(tester);
  }

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
      try {
        await abrirCaja2(tester);
        expect(find.text('Caja 2'), findsOneWidget);
        expect(find.text('Fotos y PDF'), findsWidgets);
        expect(find.text('Agregar foto o PDF'), findsOneWidget);
        expect(find.text('Sucursal: Sucursal 15 Achocalla · LA PAZ'), findsOneWidget);
        // Hasta el fondo: el contenido y la sección de préstamos también se miden.
        await bajarHasta(tester, find.text('Facturas emisores septiembre 2016'));
        await bajarHasta(tester, find.text('Préstamos y destrucciones'));
      } finally {
        FlutterError.onError = previo;
      }
      expect(find.text('Todavía no se prestó ni se destruyó nada de esta caja.'), findsOneWidget);
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
    await tester.tap(find.text('Agregar foto o PDF'));
    await esperar(tester);
    // Sin cámara (escritorio) se elige entre una foto y un PDF.
    expect(find.text('Elegir un PDF'), findsOneWidget);
    await tester.tap(find.text('Elegir una foto'));
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
      // En el teléfono los catálogos van en el menú «Más acciones».
      if (find.byTooltip('Más acciones').evaluate().isNotEmpty) {
        await tester.tap(find.byTooltip('Más acciones'));
        await esperar(tester);
      }
      await tester.tap(find.text('Catálogos'));
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
      expect(find.text('Contenido de la caja'), findsNothing, reason: 'el de una caja se pide desde la caja');
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
    try {
      await abrirCaja2(tester);
      await bajarHasta(tester, find.text('Prestar'));
      await tester.tap(find.text('Prestar'));
      await esperar(tester);
    } finally {
      FlutterError.onError = previo;
    }
    for (final e in errores) {
      debugPrint('DETALLE letra grande: $e');
    }
    expect(find.text('Prestar de la caja 2'), findsOneWidget);
    expect(errores, isEmpty);
  });

  // ── Responsable, préstamos, destrucción, PDF y reporte de la caja ───────

  /// Elige una opción de un ComboBuscable (un DropdownMenu) por su etiqueta.
  Future<void> elegir(WidgetTester tester, String etiqueta, String opcion) async {
    await tester.tap(find.widgetWithText(DropdownMenu<int>, etiqueta));
    await esperar(tester);
    await tester.tap(find.widgetWithText(MenuItemButton, opcion).hitTestable().first);
    await esperar(tester);
  }

  const lineaPrestada = ContenidoCajaEntity(
    codContenido: 2,
    codCaja: 2,
    codTipoDocumento: 10,
    codEmpresa: 1,
    nombreTipoDocumento: 'Facturas',
    nombreEmpresa: 'IMPEXPAP',
    detalle: 'Facturas emisores septiembre 2016',
    gestion: '2016',
    anioDesde: 2016,
    anioHasta: 2016,
    situacion: ContenidoCajaEntity.prestada,
    codPrestamo: 50,
    prestadoA: 'LLANQUE VICTOR',
    fechaPrestamo: '16/10/2026 09:30',
  );
  const prestamoDeLinea = PrestamoDocumentoEntity(
    codPrestamo: 50,
    codEntrega: 7,
    codCaja: 2,
    codContenido: 2,
    codEmpleado: 23,
    fechaEntrega: '16/10/2026 09:30',
    observacionEntrega: 'Auditoría',
    numeroCaja: 2,
    codArchivo: 1,
    nombreArchivo: 'ACHOCALLA',
    nombreTipoDocumento: 'Facturas',
    detalle: 'Facturas emisores septiembre 2016',
    nombreEmpleado: 'LLANQUE VICTOR',
  );

  for (final ancho in [390.0, 1400.0]) {
    testWidgets('prestar documentos a un empleado activo, sin desborde a ${ancho.toInt()} px', (tester) async {
      await abrir(tester, ancho: ancho, alto: ancho <= 450 ? 844 : 900);
      await abrirCaja2(tester);
      final errores = <FlutterErrorDetails>[];
      final previo = FlutterError.onError;
      FlutterError.onError = errores.add;
      try {
        await bajarHasta(tester, find.text('Prestar'));
        await tester.tap(find.text('Prestar'));
        await esperar(tester);
      } finally {
        FlutterError.onError = previo;
      }
      for (final e in errores) {
        debugPrint('DETALLE a $ancho:\n$e');
      }
      expect(errores, isEmpty, reason: 'ancho $ancho');
      expect(find.text('Prestar de la caja 2'), findsOneWidget);

      // Sin empleado ni documento no se manda nada.
      final registrar = find.descendant(of: find.byType(PieFicha), matching: find.text('Registrar préstamo'));
      await tester.tap(registrar);
      await esperar(tester);
      expect(find.text('Elige a quién se le entrega.'), findsOneWidget);
      expect(find.text('Elige al menos un documento.'), findsOneWidget);
      expect(repo.escrituras, isEmpty);

      await tester.tap(find.widgetWithText(DropdownMenu<int>, 'Se le entrega a *'));
      await esperar(tester);
      expect(find.widgetWithText(MenuItemButton, 'VINO VINO VICTOR · ESTIBADOR · ya no está activo'), findsNothing);
      await tester.tap(find.widgetWithText(MenuItemButton, 'LLANQUE VICTOR · CHOFER B').hitTestable().first);
      await esperar(tester);
      final linea = find.widgetWithText(CheckboxListTile, 'Facturas emisores septiembre 2016');
      await tester.ensureVisible(linea);
      await tester.tap(linea);
      await esperar(tester);
      await tester.tap(registrar);
      await esperar(tester);
      expect(
        repo.escrituras.single,
        'entregar cajas [] lineas [2] a 23 obs null',
        reason: 'prestar desde la caja es una entrega de esa sola caja',
      );
      await dejarVencerAvisos(tester);
    });
  }

  testWidgets('con un documento afuera la caja completa no se presta, y se explica por qué', (tester) async {
    repo.contenido[1] = lineaPrestada;
    repo.cajas[1] = const CajaArchivoEntity(
      codCaja: 2,
      codArchivo: 1,
      numero: 2,
      nombreArchivo: 'ACHOCALLA',
      lineas: 2,
      anioDesde: 2015,
      anioHasta: 2017,
      prestados: 1,
    );
    await abrir(tester);
    expect(find.textContaining('1 prestado'), findsOneWidget, reason: 'la fila de la caja dice que algo salió');
    await abrirCaja2(tester);
    expect(find.text('Prestado a LLANQUE VICTOR'), findsOneWidget);
    await tester.tap(find.text('Prestar'));
    await esperar(tester);
    expect(find.textContaining('la caja completa se registra cuando vuelvan'), findsOneWidget);
    final radio = tester.widget<RadioListTile<bool>>(find.widgetWithText(RadioListTile<bool>, 'La caja completa'));
    expect(radio.onChanged, isNull);
    final prestada = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Facturas emisores septiembre 2016'),
    );
    expect(prestada.onChanged, isNull, reason: 'lo que está afuera no se vuelve a prestar');
  });

  testWidgets('un documento prestado solo se devuelve desde su menú, con su propia nota', (tester) async {
    repo.contenido[1] = lineaPrestada;
    repo.prestamos.add(prestamoDeLinea);
    await abrir(tester);
    await abrirCaja2(tester);
    await tester.tap(find.byTooltip('Más acciones del documento').first);
    await esperar(tester);
    expect(find.descendant(of: find.byType(PopupMenuItem<AccionLinea>), matching: find.text('Prestar')), findsNothing);
    await tester.tap(
      find.descendant(of: find.byType(PopupMenuItem<AccionLinea>), matching: find.text('Registrar devolución')),
    );
    await esperar(tester);
    expect(find.text('Registrar la devolución'), findsOneWidget);
    expect(find.text('Facturas emisores septiembre 2016'), findsWidgets);
    final nota = find.widgetWithText(TextField, 'Observación');
    expect(tester.widget<TextField>(nota).controller!.text, isEmpty, reason: 'la nota de la entrega no se pisa');
    await tester.enterText(nota, 'Volvió completo');
    await tester.tap(find.descendant(of: find.byType(PieFicha), matching: find.text('Registrar devolución')));
    await esperar(tester);
    expect(repo.escrituras.single, 'devolver 50 obs Volvió completo');
    await dejarVencerAvisos(tester);
  });

  testWidgets('destruir la caja completa la registra con su motivo', (tester) async {
    await abrir(tester);
    await abrirCaja2(tester);
    await tester.ensureVisible(find.text('Destrucción'));
    await tester.tap(find.text('Destrucción'));
    await esperar(tester);
    expect(find.textContaining('Queda en la bitácora de destrucción'), findsOneWidget);
    await tester.tap(find.text('La caja completa'));
    await esperar(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Motivo u observación'), 'Plazo de guarda cumplido');
    await tester.tap(find.descendant(of: find.byType(PieFicha), matching: find.text('Registrar destrucción')));
    await esperar(tester);
    expect(repo.escrituras.single, 'destruir caja 2 lineas [] obs Plazo de guarda cumplido');
    await dejarVencerAvisos(tester);
  });

  testWidgets('una caja prestada completa lo dice en la lista y en la caja, con su devolución', (tester) async {
    repo.cajas[1] = const CajaArchivoEntity(
      codCaja: 2,
      codArchivo: 1,
      numero: 2,
      nombreArchivo: 'ACHOCALLA',
      lineas: 2,
      anioDesde: 2015,
      anioHasta: 2017,
      codPrestamoCaja: 60,
      prestadaA: 'CÁRDENAS RIVEROS VICTOR HUMBERTO',
      fechaPrestamo: '16/10/2026 10:00',
      prestados: 2,
    );
    repo.entregas.add(
      const EntregaDocumentoEntity(
        codEntrega: 8,
        codEmpleado: 240,
        fechaEntrega: '16/10/2026 10:00',
        nombreEmpleado: 'CÁRDENAS RIVEROS VICTOR HUMBERTO',
        cajas: 1,
        pendientes: 1,
      ),
    );
    repo.prestamos.add(
      const PrestamoDocumentoEntity(
        codPrestamo: 60,
        codEntrega: 8,
        codCaja: 2,
        codEmpleado: 240,
        fechaEntrega: '16/10/2026 10:00',
        numeroCaja: 2,
        codArchivo: 1,
        nombreArchivo: 'ACHOCALLA',
        nombreEmpleado: 'CÁRDENAS RIVEROS VICTOR HUMBERTO',
      ),
    );
    await abrir(tester);
    expect(find.textContaining('Prestada completa'), findsOneWidget);
    expect(find.text('Préstamos (1)'), findsOneWidget);
    await abrirCaja2(tester);
    expect(
      find.text('La caja completa está prestada a CÁRDENAS RIVEROS VICTOR HUMBERTO desde 16/10/2026 10:00.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Registrar devolución').first);
    await esperar(tester);
    expect(find.text('La caja 2 completa'), findsWidgets);
    await tester.tap(find.descendant(of: find.byType(PieFicha), matching: find.text('Registrar devolución')));
    await esperar(tester);
    expect(repo.escrituras.single, 'devolver 60 obs null');
    await dejarVencerAvisos(tester);
  });

  /// Una entrega abierta (la caja 1 de OFICINA CENTRAL completa y un documento
  /// de la caja 2 de ACHOCALLA) y otra que ya volvió.
  void sembrarEntregas() {
    repo.entregas.addAll(const [
      EntregaDocumentoEntity(
        codEntrega: 9,
        codEmpleado: 240,
        fechaEntrega: '16/10/2026 10:00',
        observacion: 'Auditoría externa',
        nombreEmpleado: 'CÁRDENAS RIVEROS VICTOR HUMBERTO',
        cajas: 1,
        documentos: 1,
        pendientes: 2,
        nombreUsuario: 'JAIMES MARCELO',
      ),
      EntregaDocumentoEntity(
        codEntrega: 10,
        codEmpleado: 23,
        fechaEntrega: '14/10/2026 08:00',
        nombreEmpleado: 'LLANQUE VICTOR',
        documentos: 1,
        fechaDevolucion: '15/10/2026 17:00',
      ),
    ]);
    repo.prestamos.addAll(const [
      PrestamoDocumentoEntity(
        codPrestamo: 60,
        codEntrega: 9,
        codCaja: 3,
        codEmpleado: 240,
        fechaEntrega: '16/10/2026 10:00',
        numeroCaja: 1,
        codArchivo: 2,
        nombreArchivo: 'OFICINA CENTRAL',
        nombreEmpleado: 'CÁRDENAS RIVEROS VICTOR HUMBERTO',
      ),
      PrestamoDocumentoEntity(
        codPrestamo: 62,
        codEntrega: 9,
        codCaja: 2,
        codContenido: 3,
        codEmpleado: 240,
        fechaEntrega: '16/10/2026 10:00',
        numeroCaja: 2,
        codArchivo: 1,
        nombreArchivo: 'ACHOCALLA',
        nombreTipoDocumento: 'Facturas',
        detalle: 'Facturas Papirus talonarios 1 - 6',
        nombreEmpleado: 'CÁRDENAS RIVEROS VICTOR HUMBERTO',
      ),
      PrestamoDocumentoEntity(
        codPrestamo: 61,
        codEntrega: 10,
        codCaja: 2,
        codContenido: 2,
        codEmpleado: 23,
        fechaEntrega: '14/10/2026 08:00',
        fechaDevolucion: '15/10/2026 17:00',
        observacionDevolucion: 'Completo',
        numeroCaja: 2,
        codArchivo: 1,
        nombreArchivo: 'ACHOCALLA',
        detalle: 'Facturas emisores septiembre 2016',
        nombreEmpleado: 'LLANQUE VICTOR',
      ),
    ]);
  }

  for (final ancho in [390.0, 1400.0]) {
    testWidgets('la ficha de préstamos agrupa por entrega sin desborde a ${ancho.toInt()} px y lleva a la caja', (
      tester,
    ) async {
      sembrarEntregas();
      final errores = await abrir(tester, ancho: ancho, alto: ancho <= 450 ? 844 : 900);
      final previo = FlutterError.onError;
      FlutterError.onError = errores.add;
      try {
        await tester.tap(find.byTooltip('Préstamos y destrucciones: 1 préstamo afuera').hitTestable().first);
        await esperar(tester);
      } finally {
        FlutterError.onError = previo;
      }
      for (final e in errores) {
        debugPrint('DETALLE a $ancho:\n$e');
      }
      expect(errores, isEmpty, reason: 'ancho $ancho');
      expect(find.text('Afuera (1)'), findsOneWidget);
      expect(find.text('Devueltas (1)'), findsOneWidget);
      expect(find.text('Entrega N.º 9 · 1 caja y 1 documento'), findsOneWidget);
      expect(find.text('Caja 1 completa'), findsOneWidget);
      expect(find.text('Facturas Papirus talonarios 1 - 6'), findsOneWidget);
      expect(find.text('Devolver todo (2)'), findsOneWidget);

      // La búsqueda mira a la persona y también lo que se llevó.
      final buscar = find.widgetWithText(TextField, 'Busca por persona, caja o documento');
      await tester.enterText(buscar, 'llanque');
      await esperar(tester);
      expect(find.text('Afuera (0)'), findsOneWidget);
      expect(find.text('Devueltas (1)'), findsOneWidget);
      await tester.enterText(buscar, 'papirus');
      await esperar(tester);
      expect(find.text('Afuera (1)'), findsOneWidget);
      await tester.enterText(buscar, '');
      await esperar(tester);

      await tester.tap(find.byTooltip('Acciones de Caja 1 completa'));
      await esperar(tester);
      await tester.tap(find.text('Ver la caja 1'));
      await esperar(tester);
      expect(find.text('Sucursal: Central · LA PAZ'), findsOneWidget, reason: 'abrió la caja 1 de OFICINA CENTRAL');
    });
  }

  testWidgets('una entrega se devuelve toda junta, y un renglón o la entrega entera se anulan', (tester) async {
    sembrarEntregas();
    await abrir(tester);
    await tester.tap(find.byTooltip('Préstamos y destrucciones: 1 préstamo afuera').hitTestable().first);
    await esperar(tester);

    await tester.tap(find.text('Devolver todo (2)'));
    await esperar(tester);
    expect(find.text('Toda la entrega N.º 9: 1 caja y 1 documento'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(PieFicha), matching: find.text('Registrar devolución')));
    await esperar(tester);
    expect(repo.escrituras.single, 'devolver entrega 9 obs null');
    await dejarVencerAvisos(tester);

    await tester.tap(find.byTooltip('Acciones de Facturas Papirus talonarios 1 - 6'));
    await esperar(tester);
    await tester.tap(find.text('Anular este renglón'));
    await esperar(tester);
    await tester.tap(find.text('Anular préstamo'));
    await esperar(tester);
    expect(repo.escrituras.last, 'anular prestamo 62');
    await dejarVencerAvisos(tester);

    await tester.tap(find.text('Anular entrega'));
    await esperar(tester);
    expect(find.text('Anular la entrega N.º 9'), findsOneWidget);
    await tester.tap(find.text('Anular entrega').last);
    await esperar(tester);
    expect(repo.escrituras.last, 'anular entrega 9');
    await dejarVencerAvisos(tester);
  });

  for (final (ancho, escala) in [(390.0, 1.0), (390.0, 1.6), (1400.0, 1.0)]) {
    testWidgets(
      'nuevo préstamo: una caja completa y un documento de otra caja en un solo paso, '
      'a ${ancho.toInt()} px y letra al ${(escala * 100).round()} %',
      (tester) async {
        if (escala != 1.0) {
          tester.platformDispatcher.textScaleFactorTestValue = escala;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        }
        final errores = await abrir(tester, ancho: ancho, alto: ancho <= 450 ? 844 : 900);
        final previo = FlutterError.onError;
        FlutterError.onError = errores.add;
        try {
          await tester.tap(find.byTooltip('Préstamos y destrucciones: no hay nada prestado').hitTestable().first);
          await esperar(tester);
          await tester.tap(find.text('Nuevo préstamo'));
          await esperar(tester);

          // Sin empleado ni nada elegido no se manda nada.
          final registrar = find.descendant(of: find.byType(PieFicha), matching: find.text('Registrar préstamo'));
          await tester.tap(registrar);
          await esperar(tester);
          expect(find.text('Elige a quién se le entrega.'), findsOneWidget);
          expect(find.text('Agrega al menos una caja o un documento.'), findsOneWidget);
          expect(repo.escrituras, isEmpty);

          await elegir(tester, 'Se le entrega a *', 'LLANQUE VICTOR · CHOFER B');
          final buscar = find.widgetWithText(TextField, 'Busca una caja o un documento');
          await tester.enterText(buscar, 'oficina 1');
          await esperar(tester);
          expect(find.text('Cajas completas (1)'), findsOneWidget);
          expect(find.text('Documentos (2)'), findsOneWidget);
          final caja = find.text('Caja 1 completa').first;
          await tester.ensureVisible(caja);
          await tester.tap(caja);
          await esperar(tester);
          expect(find.text('Va con su caja completa.'), findsNWidgets(2), reason: 'sus documentos ya salen con ella');

          await tester.enterText(buscar, 'facturas 2016');
          await esperar(tester);
          final documento = find.text('Facturas emisores septiembre 2016').first;
          await tester.ensureVisible(documento);
          await tester.tap(documento);
          await esperar(tester);
          expect(find.text('1 caja y 1 documento'), findsOneWidget);
          await tester.ensureVisible(registrar);
          await tester.tap(registrar);
          await esperar(tester);
        } finally {
          FlutterError.onError = previo;
        }
        for (final e in errores) {
          debugPrint('DETALLE a $ancho, letra $escala:\n$e');
        }
        expect(errores, isEmpty, reason: 'ancho $ancho, letra $escala');
        expect(repo.escrituras.single, 'entregar cajas [3] lineas [2] a 23 obs null');
        await dejarVencerAvisos(tester);
      },
    );
  }

  testWidgets('en el nuevo préstamo, lo prestado no se agrega y dice a quién', (tester) async {
    repo.contenido[1] = lineaPrestada;
    await abrir(tester);
    await tester.tap(find.byTooltip('Préstamos y destrucciones: no hay nada prestado').hitTestable().first);
    await esperar(tester);
    await tester.tap(find.text('Nuevo préstamo'));
    await esperar(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Busca una caja o un documento'), 'septiembre');
    await esperar(tester);
    expect(find.text('Prestado a LLANQUE VICTOR.'), findsOneWidget);
    final fila = tester.widget<ListTile>(find.widgetWithText(ListTile, 'Facturas emisores septiembre 2016'));
    expect(fila.enabled, isFalse);
    expect(find.byTooltip('Agregar'), findsNothing);
  });

  testWidgets('un archivo nuevo no se guarda sin responsable; con él, la fecha la pone el servidor', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Catálogos'));
    await esperar(tester);
    await tester.tap(find.text('Nuevo archivo'));
    await esperar(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre *'), 'CALIRI');
    await tester.tap(find.text('Guardar'));
    await esperar(tester);
    expect(find.text('Elige al responsable del archivo.'), findsOneWidget);
    expect(repo.escrituras, isEmpty);

    await elegir(tester, 'Responsable *', 'CÁRDENAS RIVEROS VICTOR HUMBERTO · AUXILIAR CONTABLE');
    expect(find.text('Se registra con la fecha y hora en que guardes.'), findsOneWidget);
    await tester.tap(find.text('Guardar'));
    await esperar(tester);
    expect(repo.escrituras.single, 'archivo 0 CALIRI responsable 240');
  });

  testWidgets('el responsable de un archivo se ve con la fecha en que se le asignó', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Catálogos'));
    await esperar(tester);
    expect(
      find.textContaining('Responsable: CÁRDENAS RIVEROS VICTOR HUMBERTO (desde 13/10/2026 10:30)'),
      findsNWidgets(2),
    );
    await tester.tap(find.text('ACHOCALLA').hitTestable().first);
    await esperar(tester);
    expect(find.text('Responsable desde el 13/10/2026 10:30.'), findsOneWidget);
  });

  testWidgets('un PDF de la caja se ve como PDF y se abre en el visor', (tester) async {
    repo.fotos.add(const FotoCajaEntity(codFoto: 8, codCaja: 2, orden: 1, ruta: 'archivo-cajas/caja-2-x.pdf'));
    await abrir(tester);
    await abrirCaja2(tester);
    expect(find.text('Tócalo para abrirlo'), findsOneWidget);
    await tester.tap(find.text('Tócalo para abrirlo'));
    await esperar(tester);
    expect(pdfsVistos, ['PDF 1 · Caja 2']);
  });

  testWidgets('el reporte de la caja sale con su caja y se ve en el visor', (tester) async {
    await abrir(tester);
    await abrirCaja2(tester);
    await tester.ensureVisible(find.text('Reporte PDF'));
    await tester.tap(find.text('Reporte PDF'));
    await esperar(tester);
    final p = repo.pedidos.single;
    expect(p.reporte, ReporteArchivo.porCaja);
    expect(p.codCaja, 2);
    expect(pdfsVistos.single, 'Contenido de la caja 2 · ACHOCALLA');
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
