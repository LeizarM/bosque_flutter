// Capturas del archivo de documentos, para mirarlas. NO es una prueba: no afirma
// nada y `flutter test` no la levanta solo. Se corre a mano:
//   flutter test test/capturas/capturas_archivo_documental.dart --dart-define=CAPTURAS=<carpeta>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bosque_flutter/core/state/archivo_documental_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/foto_caja_entity.dart';
import 'package:bosque_flutter/presentation/screens/archivo-documental/archivo_documental_screen.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/fotos_caja.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../fakes/repositorio_archivo_documental.dart';
import '../fakes/repositorio_depositos.dart' show loginAdminFalso;

const _salida = String.fromEnvironment('CAPTURAS', defaultValue: 'build/capturas_archivo');

/// Una foto dibujada (cartón, estante y la etiqueta de la caja) para ver la
/// miniatura y el visor con algo parecido a una foto real.
late Uint8List _foto;

Future<Uint8List> _fotoDeCarton() async {
  const w = 1200.0, h = 900.0;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(const Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFC49A6C));
  c.drawRect(const Rect.fromLTWH(0, h * 0.68, w, h * 0.32), Paint()..color = const Color(0xFF7A5C40));
  c.drawRRect(
    RRect.fromRectAndRadius(const Rect.fromLTWH(w * 0.28, h * 0.16, w * 0.44, h * 0.34), const Radius.circular(14)),
    Paint()..color = const Color(0xFFF7F3E8),
  );
  final tp = TextPainter(
    text: const TextSpan(
      text: 'CAJA 2 ACHOCALLA',
      style: TextStyle(color: Color(0xFF263238), fontSize: 72, fontWeight: FontWeight.w700, fontFamily: 'Roboto'),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: w * 0.44);
  tp.paint(c, Offset(w / 2 - tp.width / 2, h * 0.33 - tp.height / 2));
  final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

/// La caja 2 con dos fotos y la primera como portada del listado.
RepositorioArchivoFalso _repo() {
  final r = RepositorioArchivoFalso()..bytesFoto = _foto;
  r.fotos.addAll(const [
    FotoCajaEntity(codFoto: 7, codCaja: 2, orden: 1, ruta: 'archivo-cajas/7.png'),
    FotoCajaEntity(codFoto: 8, codCaja: 2, orden: 2, ruta: 'archivo-cajas/8.png'),
  ]);
  r.cajas[1] = const CajaArchivoEntity(
    codCaja: 2,
    codArchivo: 1,
    numero: 2,
    nombreArchivo: 'ACHOCALLA',
    lineas: 2,
    fotos: 2,
    anioDesde: 2015,
    anioHasta: 2017,
    codFotoPortada: 7,
    rutaPortada: 'archivo-cajas/7.png',
  );
  return r;
}

Future<void> _cargarFuentes() async {
  final porFamilia = <String, List<File>>{};
  for (final f in Directory('assets/fonts').listSync().whereType<File>()) {
    final nombre = f.uri.pathSegments.last;
    if (!nombre.endsWith('.ttf') && !nombre.endsWith('.otf')) continue;
    porFamilia.putIfAbsent(nombre.split('-').first, () => []).add(f);
  }
  for (final e in porFamilia.entries) {
    final loader = FontLoader(e.key);
    for (final f in e.value) {
      loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
    await loader.load();
  }
  final iconos = File(
    '${Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter'}/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  if (iconos.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(iconos.readAsBytesSync())))).load();
  }
}

Future<void> _capturar(
  WidgetTester tester,
  String nombre, {
  Size tam = const Size(1440, 900),
  Future<void> Function(WidgetTester t)? antes,
  bool oscuro = false,
}) async {
  tester.view.physicalSize = tam;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  debugDisableShadows = false;
  try {
    final clave = GlobalKey();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      RepaintBoundary(
        key: clave,
        child: ProviderScope(
          overrides: [
            userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(loginAdminFalso)),
            archivoDocumentalRepositoryProvider.overrideWithValue(_repo()),
            camaraDisponibleProvider.overrideWithValue(true),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: oscuro ? AppTheme(isDarkMode: true).getTheme() : AppTheme().getTheme(),
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
            home: const Scaffold(body: ArchivoDocumentalScreen()),
          ),
        ),
      ),
    );
    Future<void> cargar() async {
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await cargar();
    if (antes != null) {
      await antes(tester);
      await cargar();
    }
    await tester.runAsync(() async {
      final b = clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 1);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$_salida/$nombre.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  } finally {
    debugDisableShadows = true;
  }
}

Future<void> _abrirCaja2(WidgetTester t) => t.tap(find.text('Facturas').hitTestable().first);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _cargarFuentes();
    _foto = await _fotoDeCarton();
  });

  const telefono = Size(390, 844);

  testWidgets('listado', (t) async {
    await _capturar(t, 'listado_escritorio');
    await _capturar(t, 'listado_telefono', tam: telefono);
    await _capturar(t, 'listado_oscuro', oscuro: true);
    await _capturar(
      t,
      'busqueda_escritorio',
      antes: (t) => t.enterText(find.byType(TextField).first, 'facturas 2016'),
    );
  });

  testWidgets('detalle', (t) async {
    await _capturar(t, 'detalle_escritorio', antes: _abrirCaja2);
    await _capturar(t, 'detalle_telefono', tam: telefono, antes: _abrirCaja2);
    await _capturar(t, 'detalle_oscuro', oscuro: true, antes: _abrirCaja2);
  });

  Future<void> abrirVisor(WidgetTester t) async {
    await _abrirCaja2(t);
    for (var i = 0; i < 6; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.tap(find.descendant(of: find.byType(FotosCaja), matching: find.byType(Image)).first);
  }

  testWidgets('visor de fotos', (t) async {
    await _capturar(t, 'visor_escritorio', antes: abrirVisor);
    await _capturar(t, 'visor_telefono', tam: telefono, antes: abrirVisor);
  });

  testWidgets('reportes', (t) async {
    await _capturar(t, 'reportes_escritorio', antes: (t) => t.tap(find.text('Reportes')));
    await _capturar(t, 'reportes_telefono', tam: telefono, antes: (t) => t.tap(find.byTooltip('Reportes en PDF')));
  });

  testWidgets('fichas', (t) async {
    await _capturar(
      t,
      'ficha_documento_escritorio',
      antes: (t) async {
        await _abrirCaja2(t);
        await t.pump(const Duration(milliseconds: 300));
        await t.tap(find.text('Agregar documento'));
      },
    );
    await _capturar(t, 'catalogos_escritorio', antes: (t) => t.tap(find.text('Catálogos')));
    await _capturar(t, 'ficha_caja_telefono', tam: telefono, antes: (t) => t.tap(find.text('Nueva caja')));
  });
}
