import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/vista_previa/cheques.dart' as vista;

/// Lo que la vista previa muestra de los tres paneles del detalle (notas de
/// remision, transacciones bancarias y postergaciones): los datos de mentira que
/// llenan el cheque 14 y los cinco dialogos que se abren desde su propio grupo de
/// controles. Sin esta prueba la vista se rompe en silencio cuando cambia una
/// entidad o una pieza, como pasa con `vista_previa_cheques_test.dart`.
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
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Future<void> tocar(WidgetTester tester, String texto) async {
    await tester.ensureVisible(find.text(texto));
    await tester.tap(find.text(texto));
    await dejarPasar(tester);
  }

  void ventana(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('el detalle trae los tres paneles llenos con datos de mentira', (
    tester,
  ) async {
    ventana(tester);
    vista.main();
    await dejarPasar(tester);
    await tocar(tester, 'Detalle');

    expect(find.text('Notas de remisión'), findsOneWidget);
    expect(find.text('Transacciones bancarias'), findsOneWidget);
    expect(find.text('Postergaciones'), findsOneWidget);
    // Datos que solo aparecen si llegaron de los paneles.
    expect(find.text('Nota 262211881'), findsOneWidget);
    expect(find.text('TT26216QW3N3'), findsOneWidget);
    final postergaciones = find.byKey(const ValueKey('panel-postergaciones'));
    expect(
      find.descendant(of: postergaciones, matching: find.text('PDF cargado')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: postergaciones, matching: find.text('Sin PDF')),
      findsNWidgets(2),
    );
    // Una nota repetida (dos filas con el mismo numero).
    expect(find.text('Repetida ×2'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cada control del grupo de paneles abre su dialogo', (
    tester,
  ) async {
    ventana(tester);
    vista.main();
    await dejarPasar(tester);

    const casos = <(String control, String titulo, String cierre)>[
      ('Nueva nota', 'Nueva nota de remisión', 'Cancelar'),
      ('Nueva transacción', 'Nueva transacción bancaria', 'Cancelar'),
      ('Nueva postergación', 'Nueva postergación', 'Cancelar'),
      ('PDF postergación', 'PDF de la postergación', 'Cerrar'),
      ('Eliminar', '¿Eliminar la nota de remisión?', 'Cancelar'),
    ];
    for (final (control, titulo, cierre) in casos) {
      await tocar(tester, control);
      // El titulo del dialogo, no el rotulo del control que lo abrio.
      expect(
        find.descendant(of: find.byType(Dialog), matching: find.text(titulo)),
        findsOneWidget,
        reason: control,
      );
      expect(tester.takeException(), isNull, reason: control);
      await tester.tap(find.text(cierre).last);
      await dejarPasar(tester);
    }
  });

  testWidgets('el dialogo de eliminar avisa de la nota repetida', (tester) async {
    ventana(tester);
    vista.main();
    await dejarPasar(tester);
    await tocar(tester, 'Eliminar');
    expect(
      find.textContaining('Está registrada 2 veces en este cheque'),
      findsOneWidget,
    );
  });
}
