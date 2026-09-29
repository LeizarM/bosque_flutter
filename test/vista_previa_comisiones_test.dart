import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/vista_previa/comisiones.dart' as vista;

/// La vista previa (tool/vista_previa/comisiones.dart) no entra en la app, así
/// que nada la compila ni la dibuja salvo esta prueba: sin ella se rompe en
/// silencio cuando cambia una entidad o una pestaña. Con la fuente real, porque
/// la de reemplazo de flutter test desborda donde la real no.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final familia in ['PlusJakartaSans', 'JetBrainsMono']) {
      for (final peso in ['400', '500', '600', '700']) {
        final f = File('assets/fonts/$familia-$peso.ttf');
        if (!f.existsSync()) continue;
        final loader = FontLoader(familia)
          ..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
        await loader.load();
      }
    }
  });

  testWidgets('dibuja el módulo con datos en cada ancho, tema y escala', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    vista.main();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // «Humberto…» solo aparece si llegaron los datos: sin este control una
    // pantalla en blanco también «pasa».
    expect(find.text('Comisiones'), findsOneWidget);
    expect(find.textContaining('Humberto de la Torre'), findsWidgets);
    expect(tester.takeException(), isNull);

    for (final control in ['Móvil', 'Tablet', 'Escritorio', 'Oscuro', '1,3×']) {
      await tester.tap(find.text(control));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.takeException(),
        isNull,
        reason: 'desborde o error al elegir «$control»',
      );
      expect(find.text('Comisiones'), findsOneWidget);
      if (control == 'Móvil') {
        // El ancho simulado llega al módulo, no solo al marco.
        expect(
          tester.getSize(find.byType(TabBarView)).width,
          lessThanOrEqualTo(390),
        );
      }
    }
  });
}
