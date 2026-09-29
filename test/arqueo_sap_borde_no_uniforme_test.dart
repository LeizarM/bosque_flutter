// Regresión del pase visual de Tareas Rutinarias (2026-09-07).
//
// Los bloques "Movimiento de caja SAP" y "Tipo de cambio" de
// arqueo_caja_screen.dart quedaron con el alto reservado pero sin pintar ni un
// píxel. No era color, opacidad ni datos: era un `Border` con lados de
// DISTINTO color combinado con `borderRadius`.
//
// Border.paint (painting/box_border.dart) solo acepta un borde no uniforme con
// radio cuando `_distinctVisibleColors()` devuelve UN color — ahí toma
// paintNonUniformBorder. Con dos colores cae al assert
// "A borderRadius can only be given on borders with uniform colors.".
// Ese throw ocurre dentro de RenderDecoratedBox.paint, que pinta la decoración
// ANTES que el hijo, y RenderObject._paintWithContext lo atrapa y lo reporta
// sin propagarlo. Resultado: layout normal, subárbol nunca pintado.
//
// Es un fallo solo-debug (vive en un `assert`), así que en release la tabla se
// veía bien — lo que hacía parecer que el problema era de caché o de build.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Misma forma que tenían los bloques rotos: tres lados con un color y el
  /// izquierdo con el acento de sección, todo con esquinas redondeadas.
  Widget conBordeNoUniforme() => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: Container(
        decoration: BoxDecoration(
          border: const Border(
            top: BorderSide(color: Color(0xFFCCCCCC)),
            right: BorderSide(color: Color(0xFFCCCCCC)),
            bottom: BorderSide(color: Color(0xFFCCCCCC)),
            left: BorderSide(color: Color(0xFF1A6E8E), width: 3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('CAJA'),
      ),
    ),
  );

  /// La forma actual: borde de color uniforme (legal con radio) y el acento
  /// como barra hija de 3px, estirada por IntrinsicHeight.
  Widget conAcentoComoHijo() => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCCCCCC)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: const Color(0xFF1A6E8E)),
              const Expanded(child: Text('CAJA')),
            ],
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'un Border de lados con distinto color + borderRadius lanza al pintar',
    (tester) async {
      await tester.pumpWidget(conBordeNoUniforme());

      final excepcion = tester.takeException();
      expect(
        excepcion,
        isA<FlutterError>(),
        reason:
            'Si esto deja de lanzar, Flutter relajó la restricción y el fix '
            'de arqueo_caja_screen.dart puede simplificarse.',
      );
      expect(
        excepcion.toString(),
        contains('borderRadius can only be given on borders with uniform'),
      );
    },
  );

  testWidgets('el acento como barra hija pinta sin excepción', (tester) async {
    await tester.pumpWidget(conAcentoComoHijo());

    expect(tester.takeException(), isNull);
    expect(find.text('CAJA'), findsOneWidget);

    // La barra de acento existe y ocupa los 3px a la izquierda, estirada a
    // todo el alto del bloque (que es lo que aportaba el BorderSide roto).
    final barra = tester.getSize(
      find.descendant(
        of: find.byType(IntrinsicHeight),
        matching: find.byType(Container),
      ),
    );
    expect(barra.width, 3);
    expect(barra.height, greaterThan(0));
  });
}
