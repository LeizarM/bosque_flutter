/// El boton "Agregar bobina" dentro del detalle de un lote.
///
/// Dos cosas que una prueba del notifier no ve: que el boton entre en la
/// cabecera de la seccion sin desbordar —el titulo, la linea de totales y el
/// boton comparten fila— y que esa linea cambie sola al tocarlo, que es lo que
/// se pidio.
library;

import 'package:bosque_flutter/core/state/ver_lote_produccion_provider.dart';
import 'package:bosque_flutter/presentation/widgets/lote-produccion/detalle_lote_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/repositorio_lote_produccion.dart';

/// El campo Peso de la primera bobina agregada a mano.
///
/// La clave sale de `_claveDeIngreso`: las filas que ya estan en la base se
/// nombran por su `idMi` y las nuevas por su orden entre las nuevas.
/// El boton de agregar.
///
/// Se busca por el rotulo y no por `find.byType(OutlinedButton)`: ese finder
/// compara el tipo exacto y `OutlinedButton.icon` devuelve una subclase
/// privada, asi que no encuentra nada.
final _botonAgregar = find.text('Agregar bobina');

final _pesoDeLaBobinaNueva = find.descendant(
  of: find.byKey(const ValueKey('mi-peso-nueva-1')),
  matching: find.byType(TextField),
);

void main() {
  /// Abre el detalle de un lote con dos bobinas de 100 kg y 99 de balanza.
  ///
  /// El alto es generoso a proposito: el detalle vive en un `ListView` y lo que
  /// queda debajo del borde no se construye, asi que en una ventana corta el
  /// boton no existiria todavia y la prueba mediria otra cosa.
  Future<void> abrir(
    WidgetTester tester, {
    required double ancho,
    bool soloLectura = false,
  }) async {
    tester.view.physicalSize = Size(ancho, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = RepositorioLoteProduccion(
      ingresos: [
        bobina(idMi: 1, pesoKilos: 100, balanza: 99),
        bobina(idMi: 2, pesoKilos: 100, balanza: 99),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [loteProduccionRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: DetalleLoteDialog(
            lote: loteDePrueba(),
            audUsuario: 33,
            soloLectura: soloLectura,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> agregar(WidgetTester tester) async {
    await tester.tap(_botonAgregar);
    await tester.pumpAndSettle();
  }

  testWidgets('el boton esta y la fila nueva llega en blanco', (tester) async {
    await abrir(tester, ancho: 1400);

    expect(find.text('2 bobinas  ·  200.00 kg  ·  balanza 198.00 kg'), findsOne);
    expect(_botonAgregar, findsOne);

    await agregar(tester);

    expect(find.text('Bobina 3'), findsOne);
    // Vacio y no «0.0»: una bobina recien agregada no pesa cero, todavia no
    // pesa nada, y un cero de arranque termina en «0614».
    expect(tester.widget<TextField>(_pesoDeLaBobinaNueva).controller!.text, '');
  });

  testWidgets('la linea de totales se recalcula sola', (tester) async {
    await abrir(tester, ancho: 1400);
    await agregar(tester);

    // La cuenta sube en el acto; los kilos no, porque la bobina no tiene peso.
    // Agregar una fila no inventa material.
    expect(find.text('3 bobinas  ·  200.00 kg  ·  balanza 198.00 kg'), findsOne);

    await tester.enterText(_pesoDeLaBobinaNueva, '150');
    await tester.pumpAndSettle();

    expect(find.text('3 bobinas  ·  350.00 kg  ·  balanza 198.00 kg'), findsOne);
    // Y la barra de balance de arriba mira los mismos kilos.
    expect(find.textContaining('350'), findsWidgets);
  });

  testWidgets('la bobina agregada se puede quitar', (tester) async {
    await abrir(tester, ancho: 1400);
    await agregar(tester);
    await tester.enterText(_pesoDeLaBobinaNueva, '150');
    await tester.pumpAndSettle();
    expect(find.text('3 bobinas  ·  350.00 kg  ·  balanza 198.00 kg'), findsOne);

    // Solo la nueva trae papelera: las dos que ya estan en la base no se pueden
    // borrar porque el backend no tiene baja para el material de ingreso.
    expect(find.byIcon(Icons.delete_outline), findsOne);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('2 bobinas  ·  200.00 kg  ·  balanza 198.00 kg'), findsOne);
    expect(find.text('Bobina 3'), findsNothing);
  });

  testWidgets('en pantalla angosta entra y no desborda', (tester) async {
    // Debajo de 600 el detalle pasa a su armado angosto: cada fila es una
    // tarjeta con sus campos etiquetados, y el titulo de la tarjeta comparte
    // linea con la papelera.
    //
    // 580 y no el ancho de un telefono de verdad porque el dialogo ya desborda
    // por su cuenta ahi abajo, en dos lugares ajenos a esta seccion: la
    // cabecera —el numero de lote junto a la etiqueta de estado, medio pixel a
    // los 400— y la barra de Cancelar/Guardar, a los 420. Si algun dia se
    // arreglan, este numero puede bajar.
    await abrir(tester, ancho: 580);

    expect(_botonAgregar, findsOne);
    await agregar(tester);
    expect(find.text('3 bobinas  ·  200.00 kg  ·  balanza 198.00 kg'), findsOne);
  });

  testWidgets('en solo lectura no hay boton ni papelera', (tester) async {
    await abrir(tester, ancho: 1400, soloLectura: true);

    expect(_botonAgregar, findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });
}
