// Escribir en Caja Fuerte reconstruye solo la fila que se edita (2026-10-13).
//
// Antes cada letra reconstruía la pantalla entera, con la tabla "Registrado
// hoy" incluida, y en celulares lentos con la app web el teclado se trababa.
import 'package:bosque_flutter/core/state/caja_fuerte_provider.dart';
import 'package:bosque_flutter/domain/entities/cierre_operaciones_entity.dart';
import 'package:bosque_flutter/presentation/screens/tareas-rutinarias/caja_fuerte_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _existentes = <Element>{};

/// Anota los elementos que ya están en el árbol, antes de escribir.
void _anotarExistentes(WidgetTester t) {
  _existentes.clear();
  void visitar(Element e) {
    _existentes.add(e);
    e.visitChildren(visitar);
  }

  t.binding.rootElement!.visitChildren(visitar);
}

void main() {
  setUpAll(
    () => dotenv.testLoad(fileInput: 'BASE_URL_DEV=http://prueba.local'),
  );

  for (final (nombre, ancho) in [('planilla', 1400.0), ('teléfono', 400.0)]) {
    testWidgets('en $nombre, escribir no reconstruye la pantalla', (t) async {
      t.view.physicalSize = Size(ancho, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);

      final registradas = [
        for (var i = 1; i <= 30; i++)
          LlegadaDelCierre(
            idRp: i,
            cliente: 'Cliente $i',
            moneda: 'BS',
            importe: 100.0 * i,
          ),
      ];
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            llegadasCajaFuerteDeHoyProvider.overrideWith(
              (ref) async => registradas,
            ),
          ],
          child: const MaterialApp(
            home: CajaFuerteScreen(nombreTarea: 'Caja Fuerte'),
          ),
        ),
      );
      await t.pumpAndSettle();

      final reconstruidos = <String>[];
      debugOnRebuildDirtyWidget = (e, _) {
        // Solo lo que ya estaba: montar una fila nueva al desplazar no cuenta.
        if (_existentes.contains(e)) {
          reconstruidos.add(e.widget.runtimeType.toString());
        }
      };
      addTearDown(() => debugOnRebuildDirtyWidget = null);

      _anotarExistentes(t);
      await t.enterText(find.byType(TextFormField).first, 'Ferretería del Sur');
      await t.pump();

      for (final quieto in [
        'CajaFuerteScreen',
        '_RegistradasHoy',
        '_BarraGuardar',
      ]) {
        expect(
          reconstruidos,
          isNot(contains(quieto)),
          reason: '$quieto no cambia al escribir',
        );
      }
      expect(reconstruidos, contains('_FilaCajaFuerte'));
      expect(find.text('Ferretería del Sur'), findsOneWidget);
    });
  }

  testWidgets('agregar un registro sí actualiza el resumen de abajo', (
    t,
  ) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          llegadasCajaFuerteDeHoyProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: CajaFuerteScreen(nombreTarea: 'Caja Fuerte'),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('1 registro para guardar'), findsOneWidget);

    await t.tap(find.text('Agregar registro'));
    await t.pumpAndSettle();
    expect(find.text('2 registros para guardar'), findsOneWidget);
  });

  testWidgets('abrir el teclado no rearma el formulario ni lo registrado', (
    t,
  ) async {
    t.view.physicalSize = const Size(400, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          llegadasCajaFuerteDeHoyProvider.overrideWith(
            (ref) async => [
              for (var i = 1; i <= 30; i++)
                LlegadaDelCierre(
                  idRp: i,
                  cliente: 'Cliente $i',
                  importe: 10.0 * i,
                ),
            ],
          ),
        ],
        child: const MaterialApp(
          home: CajaFuerteScreen(nombreTarea: 'Caja Fuerte'),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.showKeyboard(find.byType(TextFormField).first);
    await t.pumpAndSettle();

    final reconstruidos = <String>[];
    _anotarExistentes(t);
    debugOnRebuildDirtyWidget = (e, _) {
      if (_existentes.contains(e)) {
        reconstruidos.add(e.widget.runtimeType.toString());
      }
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    // El teclado de Android sube en ~10 cuadros: el alto baja en cada uno.
    for (var paso = 1; paso <= 10; paso++) {
      t.view.viewInsets = FakeViewPadding(bottom: 30.0 * paso);
      await t.pump(const Duration(milliseconds: 16));
    }

    for (final quieto in [
      '_FilaCajaFuerte',
      '_RegistradasHoy',
      'TextFormField',
    ]) {
      expect(
        reconstruidos,
        isNot(contains(quieto)),
        reason: '$quieto no cambia porque suba el teclado',
      );
    }
  });
}
