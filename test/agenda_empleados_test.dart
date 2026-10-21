// Agenda de la empresa (Dashboard): la tarjeta abre el popup sin desbordes a
// 390/800/1400 px, los filtros por texto, sucursal y número corporativo, y el
// botón de la ficha solo con la pantalla en el menú y el permiso por empleado.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/agenda_provider.dart';
import 'package:bosque_flutter/data/models/agenda_empleado_model.dart';
import 'package:bosque_flutter/domain/entities/agenda_empleado_entity.dart';
import 'package:bosque_flutter/domain/repositories/agenda_repository.dart';
import 'package:bosque_flutter/presentation/widgets/agenda/agenda_empleados.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';

class _Repo implements AgendaRepository {
  @override
  Future<List<AgendaEmpleadoEntity>> empleados() async => [
    AgendaEmpleadoEntity(
      codEmpleado: BigInt.from(172),
      nombreCompleto: 'MARCELO JAVIER JAIMES',
      cargo: 'SUPERVISOR DE SISTEMAS',
      codSucursal: 20,
      sucursal: 'CENTRAL',
      telefonos: const ['+59178888274'],
      puedeVerFicha: true,
    ),
    AgendaEmpleadoEntity(
      codEmpleado: BigInt.from(243),
      nombreCompleto: 'LUIS FERNANDO MUÑOZ',
      cargo: 'ESTIBADOR SCZ',
      codSucursal: 24,
      sucursal: 'SANTA CRUZ',
      puedeVerFicha: true,
    ),
    AgendaEmpleadoEntity(
      codEmpleado: BigInt.from(32),
      nombreCompleto: 'ERICK ALBERTO ALMENDRAS ROCHA JEMIO',
      cargo: 'JEFE DE SISTEMAS Y OPERACIONES CON UN NOMBRE DE CARGO MUY LARGO',
      codSucursal: 20,
      sucursal: 'CENTRAL',
      telefonos: const ['+59178888275', '+59178888276'],
    ),
  ];
}

void main() {
  setUpAll(cargarRoboto);

  Widget app({bool ficha = false}) => appCheques(
    hijo: const AccesoAgendaEmpleados(),
    repo: RepositorioChequesFalso(total: 0),
    extra: [
      agendaRepositoryProvider.overrideWithValue(_Repo()),
      puedeVerFichaProvider.overrideWithValue(ficha),
    ],
  );

  Future<void> abrir(WidgetTester tester, double ancho) async {
    await montar(tester, app(), ancho: ancho);
    await tester.tap(find.byKey(const ValueKey('abrir-agenda')));
    await esperar(tester);
  }

  for (final ancho in [390.0, 800.0, 1400.0]) {
    for (final escala in [1.0, 1.5]) {
      testWidgets(
        'la tarjeta y el popup no desbordan a ${ancho.toInt()} px al ${(escala * 100).toInt()} %',
        (tester) async {
          if (escala != 1.0) conTexto(tester, escala);
          final errores = await capturandoErrores(() => abrir(tester, ancho));
          expect(errores, isEmpty, reason: 'a $ancho');
          expect(find.text('MARCELO JAVIER JAIMES'), findsOneWidget);
          expect(find.textContaining('3 empleados vigentes'), findsOneWidget);
        },
      );
    }
  }

  testWidgets('el buscador encuentra por número y por cargo sin acentos', (
    tester,
  ) async {
    await abrir(tester, 1400);
    await tester.enterText(find.byKey(const ValueKey('buscar-agenda')), '8276');
    await esperar(tester);
    expect(find.textContaining('ALMENDRAS'), findsOneWidget);
    expect(find.text('MARCELO JAVIER JAIMES'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('buscar-agenda')),
      'munoz',
    );
    await esperar(tester);
    expect(find.text('LUIS FERNANDO MUÑOZ'), findsOneWidget);
  });

  testWidgets('«Con número corporativo» deja fuera a quien no tiene', (
    tester,
  ) async {
    await abrir(tester, 1400);
    expect(find.text('Sin número corporativo'), findsOneWidget);
    await tester.tap(find.text('Con número corporativo'));
    await esperar(tester);
    expect(find.text('LUIS FERNANDO MUÑOZ'), findsNothing);
  });

  testWidgets('sin la pantalla de empleados no se ofrece la ficha', (
    tester,
  ) async {
    await abrir(tester, 1400);
    expect(find.byTooltip('Ver ficha'), findsNothing);
  });

  testWidgets(
    'con la pantalla, solo se ofrecen las fichas que la regla de la ficha deja',
    (tester) async {
      await montar(tester, app(ficha: true), ancho: 1400);
      await tester.tap(find.byKey(const ValueKey('abrir-agenda')));
      await esperar(tester);
      // El 32 está fuera del organigrama de quien mira: aparece en la agenda,
      // pero sin botón de ficha.
      expect(find.byTooltip('Ver ficha'), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('agenda-32')),
          matching: find.byTooltip('Ver ficha'),
        ),
        findsNothing,
      );
      expect(find.textContaining('ALMENDRAS'), findsOneWidget);
    },
  );

  test('sin el dato del servidor no se ofrece la ficha', () {
    final con = AgendaEmpleadoModel.fromJson({
      'codEmpleado': 7,
      'nombreCompleto': 'A',
      'puedeVerFicha': true,
    });
    final sin = AgendaEmpleadoModel.fromJson({
      'codEmpleado': 8,
      'nombreCompleto': 'B',
    });
    expect(con.toEntity().puedeVerFicha, isTrue);
    expect(sin.toEntity().puedeVerFicha, isFalse);
  });
}
