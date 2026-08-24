import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/presentation/widgets/comisiones/estado_vista.dart';

/// El esqueleto de carga se dibujaba con un numero fijo de filas que elegia
/// cada pestania. El Preliminar pedia ocho, que necesitan 393px, y su Expanded
/// le daba 340: RenderFlex overflowed by 52 pixels.
///
/// Ahora las filas salen del alto disponible. Estas pruebas fijan que no
/// desborde en ningun hueco, por chico que sea.
void main() {
  Widget enCaja(double alto, {int filas = 8}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 1276,
          height: alto,
          child: EsqueletoTabla(filas: filas, columnas: 7),
        ),
      ),
    ),
  );

  // El caso real del reporte, y los bordes: un hueco mas bajo que una sola
  // fila, y otro mas bajo que el propio encabezado.
  for (final alto in <double>[340.6, 200, 84, 41, 30, 12]) {
    testWidgets('no desborda con $alto de alto', (tester) async {
      await tester.pumpWidget(enCaja(alto));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    });
  }

  /// Solo las barras del esqueleto: el Scaffold aporta Containers propios.
  Finder soloBarras() => find.descendant(
    of: find.byType(EsqueletoTabla),
    matching: find.byType(Container),
  );

  testWidgets('dibuja mas filas cuando hay mas alto', (tester) async {
    int barras() => tester.widgetList<Container>(soloBarras()).length;

    await tester.pumpWidget(enCaja(200));
    await tester.pump(const Duration(milliseconds: 200));
    final pocas = barras();

    await tester.pumpWidget(enCaja(600));
    await tester.pump(const Duration(milliseconds: 200));
    final muchas = barras();

    expect(muchas, greaterThan(pocas));
  });

  testWidgets('con alto ilimitado usa el numero pedido', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 1276,
              child: EsqueletoTabla(filas: 3, columnas: 5),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);

    // Se mide el alto y no la cantidad de Containers: el Divider tambien
    // dibuja uno, asi que contarlos mide el detalle de Material, no el
    // esqueleto. 40 de encabezado + 1 de divisor + 3 filas de 44 = 173.
    expect(tester.getSize(find.byType(EsqueletoTabla)).height, 173);
  });
}
