import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/vista_previa/cheques.dart' as vista;

/// La vista previa (tool/vista_previa/cheques.dart) no entra en la app, asi que
/// nada la compila ni la dibuja salvo esta prueba: sin ella se rompe en silencio
/// cuando cambia una entidad, una pieza o el repositorio falso. Con las fuentes
/// reales, porque la de reemplazo de flutter test desborda donde la real no.
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

  testWidgets('dibuja el modulo con datos en cada ancho, tema, escala y vista', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    vista.main();
    await dejarPasar(tester);

    // Estos textos solo aparecen si llegaron los datos: sin este control una
    // pantalla en blanco tambien «pasa».
    expect(find.text('Cheques'), findsWidgets);
    expect(find.text('EDITORA MENDEZ LTDA.'), findsWidgets);
    // El reloj de la vista es fijo (3/10/2026): el atraso no cambia con el dia.
    expect(find.text('Atrasado 12 d'), findsWidgets);
    expect(find.text('Cobra hoy'), findsWidgets);
    expect(find.byKey(const ValueKey('resumen-cheques')), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (final control in [
      'Móvil',
      'Tablet',
      'Escritorio',
      'Oscuro',
      '1,5×',
      '45 (3 págs.)',
    ]) {
      // El panel de controles se desplaza de lado: se trae a la vista antes de
      // tocarlo (con cada vista nueva el final del panel queda mas lejos).
      await tester.ensureVisible(find.text(control));
      await tester.tap(find.text(control));
      await dejarPasar(tester);
      expect(
        tester.takeException(),
        isNull,
        reason: 'desborde o error al elegir «$control»',
      );
      expect(find.byKey(const ValueKey('resumen-cheques')), findsOneWidget);
    }

    // Con 45 cheques hay mas de una pagina: el resumen lo dice.
    expect(find.text('en esta página'), findsWidgets);

    // El ancho simulado llega a la pantalla, no solo al marco.
    await tester.tap(find.text('Móvil'));
    await dejarPasar(tester);
    expect(find.byKey(const ValueKey('lista-tarjetas')), findsOneWidget);
    expect(find.byKey(const ValueKey('lista-tabla')), findsNothing);

    await tester.tap(find.text('Detalle'));
    await dejarPasar(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Datos del cheque'), findsOneWidget);
    expect(find.text('Historial (6)'), findsOneWidget);

    await tester.tap(find.text('Formulario'));
    await dejarPasar(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Registrar cheque (administrador)'), findsOneWidget);
  });

  testWidgets('la vista del documento PDF abre el dialogo con y sin PDF', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    vista.main();
    await dejarPasar(tester);

    // Sin PDF cargado. El panel de controles se desplaza de lado y este control
    // queda al final: se trae a la vista antes de tocarlo.
    await tester.ensureVisible(find.text('Sin PDF'));
    await tester.tap(find.text('Sin PDF'));
    await dejarPasar(tester);
    await tester.tap(find.text('PDF'));
    await dejarPasar(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Este cheque no tiene PDF todavía'), findsOneWidget);
    expect(find.text('Cargar PDF'), findsOneWidget);
    await tester.tap(find.text('Cerrar'));
    await dejarPasar(tester);

    // Con PDF cargado: el estado de ejemplo de la vista.
    await tester.ensureVisible(find.text('Con PDF'));
    // La vista sigue siendo la del PDF: al cambiar los datos se arma de nuevo y
    // vuelve a abrir el dialogo sola.
    await tester.tap(find.text('Con PDF'));
    await dejarPasar(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Hay un PDF cargado'), findsOneWidget);
    expect(find.text('184 KB · 03/10/2026 09:22'), findsOneWidget);
    expect(find.text('Ver / Descargar'), findsOneWidget);
    expect(find.text('Reemplazar PDF'), findsOneWidget);
  });
}
