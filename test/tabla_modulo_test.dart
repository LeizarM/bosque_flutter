// Las piezas de tabla del módulo Tareas Rutinarias.
//
// Sostienen tres pantallas (el libro de Caja Chica, la planilla de Caja Fuerte
// y la checklist de Revisión de Autos), y las tres dependen de lo mismo: que
// TODAS las filas usen la misma lista de anchos. Ahí está la alineación de las
// columnas, y una discrepancia no rompe nada — solo deja la tabla torcida, que
// es justo el tipo de defecto que nadie reporta y todos sufren.
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tabla_modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const anchos = <AnchoCol>[
    AnchoCol.fijo(96),
    AnchoCol.flexible(),
    AnchoCol.fijo(120),
  ];

  Future<void> montar(WidgetTester tester, Widget hijo, {double ancho = 1200}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: ancho, child: hijo),
          ),
        ),
      );

  testWidgets('una columna fija mide igual en el encabezado y en las filas', (
    tester,
  ) async {
    await montar(
      tester,
      Column(
        children: [
          const EncabezadoTabla(
            anchos: anchos,
            titulos: ['Fecha', 'Detalle', 'Importe'],
            aLaDerecha: {2},
          ),
          FilaTabla(
            anchos: anchos,
            celdas: const [
              Text('01/01/2026'),
              Text('Un movimiento cualquiera'),
              Text('1.234,00'),
            ],
          ),
        ],
      ),
    );

    // La celda "Importe" del encabezado y la del cuerpo tienen que caer en la
    // misma columna: mismo ancho Y mismo borde izquierdo.
    final encabezado = tester.getRect(find.text('Importe'));
    final celda = tester.getRect(find.text('1.234,00'));

    expect(encabezado.left, celda.left);
    expect(encabezado.width, celda.width);
  });

  testWidgets('la columna flexible absorbe el ancho sobrante', (tester) async {
    await montar(
      tester,
      FilaTabla(
        anchos: anchos,
        celdas: const [Text('a'), Text('b'), Text('c')],
      ),
    );

    // Se deriva del ancho REAL de la fila y no de un número escrito a mano: el
    // viewport de los tests mide 800, así que un `SizedBox(width: 1000)` no da
    // 1000 y la cuenta fija mentía.
    final fila = tester.getSize(find.byType(FilaTabla));
    const padding = 12.0 * 2;
    const separadores = 10.0 * 2; // una por cada par de columnas
    const fijas = 96.0 + 120.0;

    final flexible = tester.getSize(
      find.ancestor(of: find.text('b'), matching: find.byType(Expanded)),
    );
    expect(flexible.width, fila.width - fijas - padding - separadores);
  });

  testWidgets('anchos y celdas desparejos se detectan al construir', (
    tester,
  ) async {
    // El assert es la red: sin él, una celda de más se ve como una tabla
    // torcida y no como un error.
    expect(
      () => FilaTabla(
        anchos: anchos,
        celdas: const [Text('a'), Text('b')],
      ),
      throwsAssertionError,
    );
  });

  testWidgets('el marco no recorta el contenido de una fila alta', (
    tester,
  ) async {
    // MarcoTabla usa Clip.antiAlias para redondear las esquinas; si además
    // impusiera una altura, una fila con un campo en error quedaría cortada.
    await montar(
      tester,
      MarcoTabla(
        child: Column(
          children: [
            const EncabezadoTabla(
              anchos: anchos,
              titulos: ['Fecha', 'Detalle', 'Importe'],
            ),
            FilaTabla(
              anchos: anchos,
              celdas: [
                const Text('01/01/2026'),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Renglón uno'),
                    Text('Renglón dos'),
                    Text('Renglón tres'),
                  ],
                ),
                const Text('1.234,00'),
              ],
            ),
          ],
        ),
      ),
    );

    expect(find.text('Renglón tres'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'encabezado y totales fijos con las filas virtualizadas en el medio',
    (tester) async {
      // Es la composición del libro de Caja Chica: encabezado fuera del
      // scroll, filas adentro, totales abajo. Un `Expanded` dentro de un
      // `Column` necesita alto ACOTADO — si esa cadena se rompe, la pantalla
      // no se ve torcida: revienta con "unbounded height".
      //
      // Y de paso prueba lo que arregla el tirón: con 125 movimientos (el
      // máximo real medido en la base) solo se construyen los visibles.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarcoTabla(
              child: Column(
                children: [
                  const EncabezadoTabla(
                    anchos: anchos,
                    titulos: ['Fecha', 'Detalle', 'Importe'],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 125,
                      itemBuilder:
                          (context, i) => FilaTabla(
                            anchos: anchos,
                            celdas: [
                              const Text('01/01/2026'),
                              Text('Movimiento $i'),
                              const Text('10,00'),
                            ],
                          ),
                    ),
                  ),
                  FilaTabla(
                    anchos: anchos,
                    celdas: const [
                      SizedBox.shrink(),
                      Text('Totales'),
                      Text('1.250,00'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      // Encabezado y totales presentes sin haber scrolleado.
      expect(find.text('Detalle'), findsOneWidget);
      expect(find.text('Totales'), findsOneWidget);

      // El primero se ve, el último no: la lista virtualiza en vez de
      // construir los 125 renglones de una.
      expect(find.text('Movimiento 0'), findsOneWidget);
      expect(find.text('Movimiento 124'), findsNothing);
      expect(
        tester.widgetList(find.byType(FilaTabla)).length,
        lessThan(125),
        reason:
            'Si se construyen las 125 filas, volvió el tirón que este cambio '
            'vino a sacar.',
      );
    },
  );
}
