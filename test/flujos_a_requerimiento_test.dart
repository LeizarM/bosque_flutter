// Los flujos que se abren desde el menú, a demanda (archivos SQL 40, 41 y 63).
//
// Eran cuatro. Desde el 2026-09-11 son tres: Cierre de Operaciones salió del
// menú (archivo SQL 63) y su pantalla —la revisión del día— se abre desde "Mis
// tareas rutinarias" con la ocurrencia de "Verificar Cierre de Operaciones",
// que genera el Job.
//
// Hay dos cosas aquí que, si se rompen, se rompen EN SILENCIO — nadie ve un
// error, simplemente el sistema hace algo distinto de lo acordado:
//
//  1. El corte va por `idTarRuti` y NO por `idATR`. El idATR 3 tiene DOS tareas
//     ("Cierre de Operaciones" y "Verficar Arqueo de Caja") y hoy ninguna de
//     las dos se abre a demanda. Si alguien "simplifica" esto a idATR, se
//     llevaría puestas tareas de otro tipo sin que nadie se entere.
//
//  2. `AperturaFlujo` no puede construir la pantalla con un idBitTarea en 0: el
//     flujo guardaría contra una ocurrencia que no existe. Tiene que decirlo.
import 'package:bosque_flutter/core/constants/tareas_a_requerimiento.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/apertura_flujo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('qué salió y qué se quedó', () {
    test('los tres flujos que se abren desde el menú están, y son tres', () {
      expect(TareasARequerimiento.todas, hasLength(3));
      expect(
        TareasARequerimiento.todas,
        containsAll(<int>[
          TareasARequerimiento.cajaFuerte,
          TareasARequerimiento.coches,
          TareasARequerimiento.cajaChica,
        ]),
      );
    });

    test('los ids son los que marca el archivo SQL 40', () {
      // Si estos números cambian sin cambiar el UPDATE de la Parte B del 40, el
      // Job sigue generando la tarea Y además aparece el submódulo: el trabajo
      // se haría dos veces.
      expect(TareasARequerimiento.cajaFuerte, 40);
      expect(TareasARequerimiento.coches, 41);
      expect(TareasARequerimiento.cajaChica, 42);
      // Se queda como registro: es el id que el archivo SQL 41 le dio a la hoja
      // del menú que borró el 63.
      expect(TareasARequerimiento.cierreOperaciones, 2);
    });

    test('las dos tareas de idATR 3 se abren desde "Mis tareas", no a demanda', () {
      // "Verficar Arqueo de Caja" (3) porque nunca salió del generador, y
      // "Cierre de Operaciones" (2) porque el archivo SQL 63 le sacó el ítem
      // del menú: su pantalla ahora se abre con la ocurrencia de la tarea.
      expect(TareasARequerimiento.contiene(3), isFalse);
      expect(TareasARequerimiento.contiene(2), isFalse);
    });

    test('el arqueo de caja y verificar cierre siguen siendo rutinarias', () {
      // Arqueo: idTarRuti 1 y 38 (97% y 88% de cumplimiento medido).
      expect(TareasARequerimiento.contiene(1), isFalse);
      expect(TareasARequerimiento.contiene(38), isFalse);
      // Verificar Cierre de Operaciones: idTarRuti 39.
      expect(TareasARequerimiento.contiene(39), isFalse);
    });

    test('un idTarRuti nulo o desconocido no se toma por movido', () {
      expect(TareasARequerimiento.contiene(null), isFalse);
      expect(TareasARequerimiento.contiene(9999), isFalse);
    });
  });

  group('AperturaFlujo', () {
    Future<void> montar(WidgetTester tester, Widget hijo) => tester.pumpWidget(
      ProviderScope(child: MaterialApp(home: hijo)),
    );

    testWidgets(
      'con un idBitTarea que ya existe no pregunta nada al backend',
      (tester) async {
        // Es el caso de "Verificar cierre", que apunta a una ocurrencia concreta
        // de otra persona: abrir una nueva sería trabajar sobre el registro
        // equivocado.
        var construidoCon = -1;
        await montar(
          tester,
          AperturaFlujo(
            idTarRuti: TareasARequerimiento.cajaFuerte,
            nombreFlujo: 'Caja Fuerte',
            idBitTareaExistente: 777,
            construir: (id) {
              construidoCon = id;
              return const Scaffold(body: Text('pantalla del flujo'));
            },
          ),
        );

        expect(find.text('pantalla del flujo'), findsOneWidget);
        expect(construidoCon, 777);
        // Sin pumpAndSettle: si hubiera salido a la red habría un spinner.
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets('sin ocurrencia resuelta NUNCA construye la pantalla', (
      tester,
    ) async {
      // El invariante que importa: mientras no haya un idBitTarea real, la
      // pantalla del flujo no se construye. Si se construyera, escribiría contra
      // una ocurrencia inexistente y el trabajo se perdería sin error visible.
      //
      // Se verifica en los dos momentos —primer frame y después de que la
      // apertura resuelve— porque el estado intermedio depende de cuánto tarda
      // la red y aquí no hay backend.
      final idsConstruidos = <int>[];
      await montar(
        tester,
        AperturaFlujo(
          idTarRuti: TareasARequerimiento.cajaChica,
          nombreFlujo: 'Caja Chica',
          construir: (id) {
            idsConstruidos.add(id);
            return const Scaffold(body: Text('no se debe ver'));
          },
        ),
      );

      expect(idsConstruidos, isEmpty);
      expect(find.text('no se debe ver'), findsNothing);
      expect(find.text('Caja Chica'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(idsConstruidos, isEmpty);
    });

    testWidgets('si no se puede abrir, ofrece reintentar y no entra igual', (
      tester,
    ) async {
      await montar(
        tester,
        AperturaFlujo(
          idTarRuti: TareasARequerimiento.coches,
          nombreFlujo: 'Revisión de Autos',
          construir: (_) => const Scaffold(body: Text('no se debe ver')),
        ),
      );
      // Sin backend, la llamada falla; se deja resolver el future.
      await tester.pumpAndSettle();

      expect(find.text('no se debe ver'), findsNothing);
      expect(find.text('No se pudo abrir Revisión de Autos'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });
}
