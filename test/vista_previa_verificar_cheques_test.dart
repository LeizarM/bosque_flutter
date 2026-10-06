import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/vista_previa/verificar_cheques.dart' as vista;

/// La vista previa (tool/vista_previa/verificar_cheques.dart) no entra en la app,
/// asi que nada la compila ni la dibuja salvo esta prueba: sin ella se rompe en
/// silencio cuando cambia una entidad, una pieza o el repositorio falso. Con las
/// fuentes reales, porque la de reemplazo de flutter test desborda donde la real
/// no.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final familias = <String, List<String>>{
      'Roboto': ['Regular', 'Medium', 'Bold'],
      'PlusJakartaSans': ['400', '500', '600', '700'],
      'JetBrainsMono': ['400', '500', '700'],
    };
    for (final e in familias.entries) {
      final loader = FontLoader(e.key);
      for (final peso in e.value) {
        final f = File('assets/fonts/${e.key}-$peso.ttf');
        if (f.existsSync()) {
          loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
        }
      }
      await loader.load();
    }
  });

  Future<void> dejarPasar(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  testWidgets('dibuja la pantalla con datos en cada ancho, tema y escala', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    vista.main();
    await dejarPasar(tester);

    // Estos textos solo aparecen si llegaron los datos: sin este control una
    // pantalla en blanco tambien «pasa».
    expect(find.text('Verificar cheques'), findsOneWidget);
    expect(find.text('Válida'), findsWidgets);
    expect(find.text('Anulada'), findsWidgets);
    expect(find.text('4801918'), findsOneWidget);
    // El reloj de la vista es fijo (3/10/2026): la lista abre en ese dia.
    expect(find.text('Mostrando las verificaciones del 03/10/2026.'), findsOneWidget);
    expect(find.text('8 cheques pendientes sin verificar'), findsOneWidget);
    expect(find.byKey(const ValueKey('resumen-verificaciones')), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (final control in [
      'Móvil',
      'Tablet',
      'Escritorio',
      'Oscuro',
      '1,5×',
      '45 (3 págs.)',
    ]) {
      await tester.tap(find.text(control));
      await dejarPasar(tester);
      expect(
        tester.takeException(),
        isNull,
        reason: 'desborde o error al elegir «$control»',
      );
      expect(find.byKey(const ValueKey('resumen-verificaciones')), findsOneWidget);
    }

    // Con 45 verificaciones hay mas de una pagina: el resumen lo dice.
    expect(find.text('en esta página'), findsWidgets);

    // El ancho simulado llega a la pantalla, no solo al marco.
    await tester.tap(find.text('Móvil'));
    await dejarPasar(tester);
    expect(find.byKey(const ValueKey('lista-tarjetas')), findsOneWidget);
    expect(find.byKey(const ValueKey('lista-tabla')), findsNothing);
  });

  testWidgets('las vistas con dialogo abren el modal de pendientes, el formulario de alta y el de edicion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    vista.main();
    await dejarPasar(tester);

    // El control «Nuevo» del panel va antes que el boton «Nuevo» de la pantalla.
    await tester.tap(find.text('Nuevo').first);
    await dejarPasar(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Cheques pendientes sin regularizar'), findsOneWidget);
    expect(find.text('Seleccionar'), findsWidgets);
    await tester.tap(find.text('Cerrar'));
    await dejarPasar(tester);

    await tester.tap(find.text('Regularizar'));
    await dejarPasar(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Cheque a regularizar'), findsOneWidget);
    expect(find.text('Guardar verificación'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await dejarPasar(tester);

    await tester.tap(find.text('Editar').first);
    await dejarPasar(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Editar verificación'), findsOneWidget);
    expect(find.text('Guardar cambios'), findsOneWidget);
  });
}
