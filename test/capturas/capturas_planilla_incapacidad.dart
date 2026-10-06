// Capturas de la Planilla de Incapacidad, para mirarlas.
//
// NO es una prueba: no afirma nada y `flutter test` no la levanta solo. A mano:
//
//   flutter test test/capturas/capturas_planilla_incapacidad.dart --dart-define=CAPTURAS=<carpeta>
//
// Usa el repositorio falso de test/fakes y las fuentes reales del proyecto.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bosque_flutter/core/state/planilla_incapacidad_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/presentation/screens/planilla-incapacidad/planilla_incapacidad_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/repositorio_planilla_incapacidad.dart';

const _salida = String.fromEnvironment(
  'CAPTURAS',
  defaultValue: 'build/capturas',
);

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
    await (FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.sublistView(iconos.readAsBytesSync()))))
        .load();
  }
}

Future<void> _capturar(
  WidgetTester tester,
  String nombre, {
  required Size tam,
  bool oscuro = false,
  RepoPlanillaIncapacidadFalso? repo,
}) async {
  tester.view.physicalSize = tam;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final clave = GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        planillaIncapacidadRepoProvider.overrideWithValue(
          repo ?? RepoPlanillaIncapacidadFalso(),
        ),
      ],
      child: RepaintBoundary(
        key: clave,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme(isDarkMode: oscuro).getTheme(),
          locale: const Locale('es'),
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const PlanillaIncapacidadScreen(),
        ),
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }

  await tester.runAsync(() async {
    final boundary =
        clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final imagen = await boundary.toImage(pixelRatio: 1);
    final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
    File('$_salida/$nombre.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _cargarFuentes();
  });

  testWidgets('escritorio claro', (t) => _capturar(t, 'incapacidad_1440_claro', tam: const Size(1440, 900)));
  testWidgets('escritorio oscuro', (t) => _capturar(t, 'incapacidad_1440_oscuro', tam: const Size(1440, 900), oscuro: true));
  testWidgets('laptop', (t) => _capturar(t, 'incapacidad_1100', tam: const Size(1100, 760)));
  testWidgets('tablet', (t) => _capturar(t, 'incapacidad_800', tam: const Size(800, 1000)));
  testWidgets('telefono', (t) => _capturar(t, 'incapacidad_390', tam: const Size(390, 844)));
  testWidgets('vacio', (t) => _capturar(t, 'incapacidad_vacio', tam: const Size(1100, 700), repo: RepoPlanillaIncapacidadFalso(filas: [])));
}
