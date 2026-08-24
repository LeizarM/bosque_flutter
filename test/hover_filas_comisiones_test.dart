import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// El hover de fila del módulo, que durante un tiempo midió exactamente cero.
///
/// `DataTable` resuelve el color del `TableRow` con un conjunto de estados que
/// solo contiene `{selected, disabled}` — el `hovered` nunca llega ahí. Lo que
/// pinta el hover es el `overlayColor` del `TableRowInkWell`, y ese InkWell
/// solo queda **habilitado** si el `DataRow` trae un manejador
/// (`onSelectChanged`, `onLongPress` o una celda con `onTap`). Las cinco
/// DataTable del módulo no tenían ninguno: el `dataRowColor` del tema estaba
/// escrito, documentado, y no se veía nunca.
///
/// Por eso este archivo no mira colores del árbol. Un sondeo por color leería
/// el `Material` de la celda, que no cambia jamás, y quedaría verde con el
/// hover roto. Mira las dos cosas que de verdad fallaban: que el InkWell de
/// fila esté habilitado, y que el `overlayColor` que recibe resuelva algo para
/// `hovered`.
///
/// El tercer caso cubre la trampa del arreglo: `onSelectChanged` habilita el
/// InkWell pero además activa `anyRowSelectable`, y Flutter inserta una columna
/// de checkbox salvo que se pase `showCheckboxColumn: false`. Ese olvido no lo
/// detecta la suite de responsive — la tabla ensancha y scrollea en vez de
/// desbordar — así que el módulo usa `onLongPress`, que llega al mismo
/// TableRowInkWell sin tocar `anyRowSelectable`.
void main() {
  Widget conTema(Widget hijo) => MaterialApp(
    // ResponsiveBreakpoints es obligatorio: temaModulo consulta esMovil para la
    // densidad de tabla y sin ancestro lanza dentro del Builder.
    builder:
        (context, child) => ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: ResponsiveUtilsBosque.breakpoints,
        ),
    home: Builder(
      builder:
          (context) => Theme(
            data: ComisionesTema.temaModulo(context),
            child: Scaffold(body: SingleChildScrollView(child: hijo)),
          ),
    ),
  );

  DataTable tablaCon({required bool conManejador}) => DataTable(
    columns: const [
      DataColumn(label: Text('Vendedor')),
      DataColumn(label: Text('Monto')),
    ],
    rows: [
      for (final n in ['Marcela Caceres', 'Julio Buitrago'])
        DataRow(
          onLongPress: conManejador ? () {} : null,
          cells: [DataCell(Text(n)), const DataCell(Text('1,483.30'))],
        ),
    ],
  );

  List<TableRowInkWell> celdasDeFila(WidgetTester tester) =>
      tester.widgetList<TableRowInkWell>(find.byType(TableRowInkWell)).toList();

  testWidgets('con manejador, la fila tiene hover que resolver', (
    tester,
  ) async {
    await tester.pumpWidget(conTema(tablaCon(conManejador: true)));
    await tester.pumpAndSettle();

    final celdas = celdasDeFila(tester);
    expect(celdas, isNotEmpty, reason: 'DataTable no montó TableRowInkWell.');

    // Un InkWell sin manejador no entra en estado hovered, y entonces el
    // overlay no se pinta por más que esté definido.
    for (final celda in celdas) {
      expect(
        celda.onTap != null || celda.onLongPress != null,
        isTrue,
        reason:
            'Hay una celda de fila sin manejador. El hover del módulo vuelve '
            'a ser decorativo: DataTable no resuelve `hovered` sin él.',
      );
      expect(
        celda.overlayColor?.resolve({WidgetState.hovered}),
        isNotNull,
        reason:
            'El overlayColor de la fila no devuelve nada para `hovered`. '
            'Alguien fijó DataRow.color con WidgetStatePropertyAll, que '
            'contesta lo mismo en todos los estados y tapa el del tema.',
      );
    }
  });

  // Control negativo: sin manejador el InkWell queda inerte. Si este caso
  // empezara a fallar, el de arriba dejaría de probar lo que dice.
  testWidgets('sin manejador el InkWell queda inerte (control negativo)', (
    tester,
  ) async {
    await tester.pumpWidget(conTema(tablaCon(conManejador: false)));
    await tester.pumpAndSettle();

    for (final celda in celdasDeFila(tester)) {
      expect(
        celda.onTap == null && celda.onLongPress == null,
        isTrue,
        reason:
            'Una fila sin manejador salió interactiva. Flutter cambió cómo '
            'arma DataTable y el otro caso ya no prueba nada.',
      );
    }
  });

  testWidgets('el manejador no trajo columna de checkbox', (tester) async {
    await tester.pumpWidget(conTema(tablaCon(conManejador: true)));
    await tester.pumpAndSettle();

    expect(
      find.byType(Checkbox),
      findsNothing,
      reason:
          'Apareció una columna de selección. Pasó a usarse onSelectChanged '
          'sin showCheckboxColumn: false — la suite de responsive no lo ve '
          'porque la tabla scrollea en vez de desbordar.',
    );
  });

  testWidgets('el tema separa la marca del hover', (tester) async {
    late ThemeData tema;
    await tester.pumpWidget(
      MaterialApp(
        builder:
            (context, child) => ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: ResponsiveUtilsBosque.breakpoints,
            ),
        home: Builder(
          builder: (context) {
            tema = ComisionesTema.temaModulo(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final color = tema.dataTableTheme.dataRowColor;
    final hover = color?.resolve({WidgetState.hovered});
    final marcada = color?.resolve({WidgetState.selected});
    final ambos = color?.resolve({WidgetState.selected, WidgetState.hovered});

    expect(hover, isNotNull, reason: 'El tema no define hover de fila.');
    expect(marcada, isNotNull, reason: 'El tema no define fila marcada.');
    expect(
      hover,
      isNot(equals(marcada)),
      reason:
          'Marca y hover comparten color. Son dos cosas distintas: una la '
          'eligió el usuario, la otra solo dice qué renglón está leyendo.',
    );

    // Selected tiene que resolverse PRIMERO: al revés, pasar el cursor por una
    // fila marcada la desmarcaba a la vista.
    expect(
      ambos,
      equals(marcada),
      reason:
          'Con el cursor encima, una fila marcada dejó de verse marcada. El '
          'resolver está mirando `hovered` antes que `selected`.',
    );
  });
}
