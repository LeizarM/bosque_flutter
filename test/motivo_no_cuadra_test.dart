// El diálogo de "¿Qué no cuadró?" tiene que sobrevivir a su propio cierre.
//
// Marcelo (2026-09-11), marcando un traspaso en la web: pantalla roja entera
// con "A TextEditingController was used after being disposed". El controlador
// se liberaba apenas `showDialog` devolvía, y el campo se vuelve a construir
// mientras el diálogo todavía se está cerrando.
//
// `pumpAndSettle` corre esa animación de salida: sin el arreglo, estas dos
// pruebas fallan con esa misma excepción.
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/motivo_no_cuadra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late String? respuesta;
  late bool respondio;

  Widget app() => MaterialApp(
    home: Scaffold(
      body: Builder(
        builder:
            (context) => TextButton(
              onPressed: () async {
                respuesta = await pedirMotivoNoCuadra(context, null);
                respondio = true;
              },
              child: const Text('abrir'),
            ),
      ),
    ),
  );

  setUp(() {
    respuesta = null;
    respondio = false;
  });

  testWidgets('guardar devuelve la observación y el diálogo se cierra entero', (
    t,
  ) async {
    await t.pumpWidget(app());
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();

    await t.enterText(
      find.byType(TextField),
      'El formulario dice 1.200 y el sistema 1.020.',
    );
    await t.tap(find.text('Guardar'));
    await t.pumpAndSettle();

    expect(respondio, isTrue);
    expect(respuesta, 'El formulario dice 1.200 y el sistema 1.020.');
  });

  // Que no venga vacía lo decide el servidor (error 23 de
  // p_abm_tac_TraspasoMovCaja 'V', archivo SQL 79), no el diálogo: las reglas
  // de registro van en SQL. El diálogo devuelve lo que hay.
  testWidgets('sin escribir nada devuelve vacío y decide el servidor', (
    t,
  ) async {
    await t.pumpWidget(app());
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();

    await t.tap(find.text('Guardar'));
    await t.pumpAndSettle();

    expect(respondio, isTrue);
    expect(respuesta, '');
  });

  testWidgets('cancelar no marca nada', (t) async {
    await t.pumpWidget(app());
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();

    await t.enterText(find.byType(TextField), 'a medio escribir');
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();

    expect(respondio, isTrue);
    expect(respuesta, isNull);
  });
}
