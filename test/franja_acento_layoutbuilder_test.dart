// Regresión 2026-09-07 (Marcelo): las tarjetas de Documentación y Vales del
// Arqueo de Caja aparecían como un recuadro gris vacío, y la consola escupía
//
//   LayoutBuilder does not support returning intrinsic dimensions.
//   Cannot hit test a render box with no size.   (x176)
//   Assertion failed: .../mouse_tracker.dart:203  -> la página se colgaba
//
// Causa: la franja de acento a la izquierda estaba hecha con
// IntrinsicHeight + Row(stretch). IntrinsicHeight consulta dimensiones
// intrínsecas de todo su subárbol, y el contenido de esas tarjetas incluye
// FilaFormularioResponsiva, que es un LayoutBuilder — y LayoutBuilder no las
// puede responder: lanza en layout. Al fallar el layout, el subárbol queda sin
// tamaño, de ahí la cascada de "cannot hit test" y el cuelgue del mouse
// tracker (que recorre el árbol en cada movimiento del puntero).
//
// FranjaAcento resuelve lo mismo con Stack + PositionedDirectional, sin
// consultar intrínsecos de nadie.
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/franja_acento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Un contenido cualquiera que por dentro usa LayoutBuilder — exactamente lo
  /// que hace FilaFormularioResponsiva, el widget de los formularios de Vales
  /// y Documentación.
  Widget contenidoConLayoutBuilder() => LayoutBuilder(
    builder:
        (context, constraints) => SizedBox(
          height: 120,
          child: Text('ancho ${constraints.maxWidth.toStringAsFixed(0)}'),
        ),
  );

  Widget enPantalla(Widget hijo) =>
      MaterialApp(home: Scaffold(body: SingleChildScrollView(child: hijo)));

  testWidgets(
    'IntrinsicHeight sobre un LayoutBuilder revienta el layout (la causa)',
    (tester) async {
      // El fallo original no lanza UNA excepción sino una cascada: primero
      // LayoutBuilder al no poder dar intrínsecos, y después un 'hasSize'
      // (box.dart:2251) por cada ancestro que quedó sin tamaño — exactamente
      // lo que Marcelo vio repetido en la consola del navegador.
      //
      // Se intercepta FlutterError.onError en vez de usar takeException():
      // el binding de test guarda UNA sola excepción pendiente y las demás
      // harían fallar el test aunque sean justo lo que se quiere comprobar.
      final errores = <FlutterErrorDetails>[];
      final anterior = FlutterError.onError;
      FlutterError.onError = errores.add;
      try {
        await tester.pumpWidget(
          enPantalla(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: const Color(0xFF1A6E8E)),
                  Expanded(child: contenidoConLayoutBuilder()),
                ],
              ),
            ),
          ),
        );
      } finally {
        FlutterError.onError = anterior;
      }

      final mensajes = errores
          .map((d) => d.exception.toString())
          .toList(growable: false);

      expect(
        mensajes,
        isNotEmpty,
        reason:
            'Si esto deja de lanzar, Flutter cambió y el motivo de existir de '
            'FranjaAcento hay que revisarlo.',
      );
      expect(
        mensajes.any(
          (m) => m.contains('does not support returning intrinsic dimensions'),
        ),
        isTrue,
        reason: 'la causa raíz debe ser el LayoutBuilder, no otra cosa',
      );
      // Las 'hasSize' que siguen (box.dart:2251) no se afirman aquí: el binding
      // de test guarda UNA excepción pendiente y las demás solo las imprime
      // como "Another exception was thrown" — que es, literalmente, lo que
      // Marcelo vio repetido en la consola del navegador.
    },
  );

  testWidgets('FranjaAcento pinta el mismo contenido sin fallar (el fix)', (
    tester,
  ) async {
    await tester.pumpWidget(
      enPantalla(
        FranjaAcento(
          color: const Color(0xFF1A6E8E),
          child: contenidoConLayoutBuilder(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('ancho '), findsOneWidget);
  });

  testWidgets('la franja se estira a todo el alto del contenido', (
    tester,
  ) async {
    await tester.pumpWidget(
      enPantalla(
        FranjaAcento(
          ancho: 3,
          color: const Color(0xFF1A6E8E),
          child: contenidoConLayoutBuilder(),
        ),
      ),
    );

    final franja = tester.getSize(find.byType(ColoredBox));
    expect(franja.width, 3);
    expect(
      franja.height,
      120,
      reason:
          'debe igualar el alto del contenido, que es lo que aportaba '
          'el crossAxisAlignment.stretch del Row anterior',
    );
  });

  testWidgets('el contenido ocupa el ancho completo, no el de su texto', (
    tester,
  ) async {
    await tester.pumpWidget(
      enPantalla(
        FranjaAcento(
          color: const Color(0xFF1A6E8E),
          child: contenidoConLayoutBuilder(),
        ),
      ),
    );

    // Sin el SizedBox(width: double.infinity) de FranjaAcento, el Stack le da
    // restricciones sueltas al hijo y la tarjeta se encogería al ancho del
    // texto en vez de ocupar la fila — que es lo que hacía el Expanded del
    // Row anterior.
    final anchoPantalla = tester.getSize(find.byType(Scaffold)).width;
    final anchoStack =
        tester
            .getSize(
              find.descendant(
                of: find.byType(FranjaAcento),
                matching: find.byType(Stack),
              ),
            )
            .width;
    expect(anchoStack, anchoPantalla);
  });

  testWidgets('sin color no envuelve nada', (tester) async {
    await tester.pumpWidget(
      enPantalla(const FranjaAcento(child: Text('pelado'))),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('pelado'), findsOneWidget);
    expect(find.byType(ColoredBox), findsNothing);
  });
}
