// La vigencia de la asignación en el alta de tarea por cargo (2026-09-08).
//
// `tac_tarRuXCargo` siempre tuvo fechaInicio, fechaFin y estado, y el generador
// siempre los respetó:
//
//     and trxc.fechaInicio <= CAST(GETDATE() AS DATE)
//     and (trxc.fechaFin IS NULL OR trxc.fechaFin >= CAST(GETDATE() AS DATE))
//     and trxc.estado = 1
//
// El formulario mandaba solo el codCargo, así que el SP les ponía "hoy" y NULL
// y no había forma de asignar una tarea a futuro ni de darle vencimiento.
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/crear_tarea_por_cargo_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // La hoja crea su repositorio al construirse y eso lee `AppConstants.baseUrl`
  // -> `dotenv.env`, que lanza si nadie cargó el archivo. Mismo arranque que ya
  // usan los tests de permisos-rrhh.
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CrearTareaPorCargoSheet(codCargos: const [7]),
            ),
          ),
        ),
      ),
    );
    // pumpAndSettle y no pump: al construirse, la hoja pide las frecuencias al
    // backend. Sin backend, el cliente reintenta leer el token y deja un timer
    // vivo; el test terminaría con "A Timer is still pending".
    await tester.pumpAndSettle();
  }

  testWidgets('una tarea nueva nace permanente', (tester) async {
    await montar(tester);

    // Es el default correcto: una tarea rutinaria se crea para repetirse
    // indefinidamente —sobre todo las diarias— y ponerle vencimiento es la
    // excepción. Si naciera con fecha de fin, cada alta necesitaría un paso
    // más para deshacerla.
    final permanente = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(permanente.value, isTrue);

    // Y mientras sea permanente no se ofrece elegir un fin.
    expect(find.text('Elegir fecha de fin'), findsNothing);
  });

  testWidgets('la fecha de inicio de la asignación se ofrece siempre', (
    tester,
  ) async {
    await montar(tester);

    // Va separada de "Empieza a repetirse desde": esa es de la TAREA
    // (tac_tareaRutinaria.fechaPartida) y dice desde cuándo se calcula la
    // repetición; esta es de la ASIGNACIÓN al cargo. La misma tarea puede
    // estar asignada a un cargo desde marzo y a otro desde julio.
    expect(find.text('Empieza a repetirse desde'), findsOneWidget);
    expect(find.text('Vigencia de la asignación'), findsOneWidget);
    expect(find.textContaining('Rige desde'), findsOneWidget);
  });

  testWidgets('apagar "Permanente" descubre la fecha de fin', (tester) async {
    await montar(tester);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(find.text('Elegir fecha de fin'), findsOneWidget);
    expect(
      find.text('Deja de generarse después de una fecha.'),
      findsOneWidget,
    );
  });

  testWidgets('volver a Permanente oculta el fin otra vez', (tester) async {
    // Lo que NO puede pasar: que el fin quede guardado en el estado mientras
    // el switch dice "permanente". La asignación se crearía con vencimiento
    // sin que se vea en pantalla.
    await montar(tester);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('Elegir fecha de fin'), findsOneWidget);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('Elegir fecha de fin'), findsNothing);
    expect(
      find.text('Se sigue generando hasta que la desactives.'),
      findsOneWidget,
    );
  });
}
