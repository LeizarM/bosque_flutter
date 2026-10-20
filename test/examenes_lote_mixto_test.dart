import 'dart:io';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/data/models/tcpe_pedido_examenes_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_credencial_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pedido_examenes_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_persona_examen_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/destinatarios_lote.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/dialogos_lote.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/repositorio_examenes.dart';

/// Lote mixto (contrato 10): bloques «Externos» y «Empleados» activables a la
/// vez, el total a generar, el body con los tres modos y las credenciales solo
/// de los externos. Teléfono (360) y escritorio (1400) con layouts distintos.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Future<void> cargar(String familia, List<String> archivos) async {
      final c = FontLoader(familia);
      for (final a in archivos) {
        final f = File('assets/fonts/$a.ttf');
        if (f.existsSync()) c.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      }
      await c.load();
    }

    await cargar('Roboto', ['Roboto-Regular', 'Roboto-Medium', 'Roboto-Bold']);
    await cargar('JetBrainsMono', ['JetBrainsMono-400', 'JetBrainsMono-500', 'JetBrainsMono-700']);
  });

  Future<void> montar(WidgetTester tester, double ancho, Widget hijo) async {
    tester.view.physicalSize = Size(ancho, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme().getTheme(),
        home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Form(child: hijo))),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  for (final ancho in [360.0, 1400.0]) {
    final escritorio = ancho >= 1000;

    testWidgets('a $ancho px: externos y empleados a la vez, con el total y sin desbordes', (tester) async {
      final d = ControladorDestinatarios();
      addTearDown(d.dispose);
      await montar(tester, ancho, SelectorDestinatarios(controlador: d));

      // Por defecto: externos por cantidad (1) y empleados apagado.
      expect(find.text('examen a generar'), findsOneWidget);
      expect(find.text('1 externo con credencial'), findsOneWidget);
      expect(find.text('Elegir empleados'), findsNothing);

      // Layout distinto: en escritorio los bloques van lado a lado; en el teléfono, apilados.
      final yExt = tester.getTopLeft(find.text('Externos').first).dy;
      final yEmp = tester.getTopLeft(find.text('Empleados').first).dy;
      expect(escritorio ? yExt == yEmp : yEmp > yExt, isTrue, reason: 'externos $yExt, empleados $yEmp');

      await tocar(tester, find.text('Empleados').first);
      expect(d.conEmpleados, isTrue);
      expect(find.text('Elegir empleados'), findsOneWidget);
      // En escritorio el detalle va en su panel, con su propio título.
      expect(find.text('Empleados'), escritorio ? findsNWidgets(2) : findsOneWidget);

      d.empleados = {BigInt.from(55), BigInt.from(56)};
      await tester.enterText(find.byType(TextFormField), '3');
      await tester.pumpAndSettle();
      expect(find.text('5'), findsOneWidget, reason: 'la burbuja del total');
      expect(find.text('exámenes a generar'), findsOneWidget);
      expect(find.text('3 externos con credencial · 2 empleados sin clave'), findsOneWidget);
      expect(find.text('2 empleados elegidos · Cambiar'), findsOneWidget);

      expect(d.validar(), isNull);
      final p = d.pedido;
      expect(p.cantidad, 3);
      expect(p.codEmpleados, [BigInt.from(55), BigInt.from(56)]);
      expect(TcpePedidoExamenesModel.fromEntity(p).toJson(), {
        'cantidad': 3,
        'codEmpleados': [55, 56],
      });
      expect(tester.takeException(), isNull);
    });

    testWidgets('a $ancho px: lista de personas más empleados y validaciones del pedido', (tester) async {
      final d = ControladorDestinatarios();
      addTearDown(d.dispose);
      await montar(tester, ancho, SelectorDestinatarios(controlador: d, yaTiene: 190));

      await tocar(tester, find.text(escritorio ? 'Lista de personas' : 'Personas'));
      expect(d.conPersonas, isTrue);
      expect(find.text('Pegar desde Excel'), findsOneWidget);
      expect(d.personas.pegar('1234567\tAna\tPaz\tMena\n7654321\tLuis\tRojas\t'), (2, 0));
      await tocar(tester, find.text('Empleados').first);

      expect(d.validar(), 'Elige al menos un empleado o desactiva «Empleados».');
      d.empleados = {BigInt.from(9)};
      await tester.pumpAndSettle();
      expect(d.validar(), isNull);
      expect(find.text('2 externos con credencial · 1 empleado sin clave'), findsOneWidget);
      expect(find.text('El lote queda con 193 de 200.'), findsOneWidget);
      final json = TcpePedidoExamenesModel.fromEntity(d.pedido).toJson();
      expect(json.containsKey('cantidad'), isFalse, reason: 'con la lista, la cantidad no viaja');
      expect((json['personas'] as List).length, 2);
      expect(json['codEmpleados'], [9]);

      // Sin ningún bloque activo no hay pedido.
      await tocar(tester, find.text('Externos').first);
      await tocar(tester, find.text('Empleados').first);
      expect(d.validar(), 'Elige quiénes rinden: externos, empleados o ambos.');
      expect(find.text('Activa «Externos», «Empleados» o ambos.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a $ancho px: en un escrito nadie lleva credencial', (tester) async {
      final d = ControladorDestinatarios()..conEmpleados = true;
      addTearDown(d.dispose);
      d.empleados = {BigInt.one};
      await montar(tester, ancho, SelectorDestinatarios(controlador: d, escrito: true));

      expect(find.text('1 externo · 1 empleado'), findsOneWidget);
      expect(find.textContaining('con credencial'), findsNothing);
      expect(find.textContaining('No llevan usuario ni clave'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a $ancho px: las credenciales son solo de los externos', (tester) async {
      await montar(
        tester,
        ancho,
        Builder(
          builder:
              (context) => FilledButton(
                onPressed:
                    () => mostrarCredenciales(
                      context,
                      tituloLote: 'Mixto',
                      empleados: 2,
                      credenciales: const [
                        TcpeCredencialEntity(login: 'IPX-7', password: 'Kq7mZt9wHp', nombreCompleto: 'Paz Ana', ci: '1'),
                      ],
                    ),
                child: const Text('Ver'),
              ),
        ),
      );
      await tocar(tester, find.text('Ver'));
      expect(find.text('IPX-7'), findsOneWidget);
      expect(find.text('Kq7mZt9wHp'), findsOneWidget);
      expect(find.textContaining('Los 2 empleados del lote entran con su usuario de Bosque'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('pedido mixto: los tres modos viajan juntos y los vacíos no', () {
    final e = TcpePedidoExamenesEntity(
      cantidad: 2,
      personas: const [TcpePersonaExamenEntity(ci: '1', nombres: 'Ana', apellidoPaterno: 'Paz')],
      codEmpleados: [BigInt.from(77)],
    );
    expect(e.externos, 3);
    expect(e.total, 4);
    final json = TcpePedidoExamenesModel.fromEntity(e).toJson();
    expect(json['cantidad'], 2);
    expect((json['personas'] as List).single['ci'], '1');
    expect(json['codEmpleados'], [77]);
    final vuelta = TcpePedidoExamenesModel.fromJson(json).toEntity();
    expect(vuelta.total, 4);
    expect(TcpePedidoExamenesModel.fromEntity(const TcpePedidoExamenesEntity()).toJson(), isEmpty);
  });

  for (final ancho in [360.0, 1400.0]) {
    testWidgets('a $ancho px: el selector de empleados muestra CI y cargo, y bloquea al que no puede', (tester) async {
      final repo = ExamenesFalso();
      Set<BigInt>? elegidos;
      tester.view.physicalSize = Size(ancho, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [examenesRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: AppTheme().getTheme(),
            home: Scaffold(
              body: Builder(
                builder:
                    (context) => Center(
                      child: FilledButton(
                        onPressed: () async => elegidos = await elegirEmpleados(context, {}, codRolExamen: BigInt.from(40)),
                        child: const Text('abrir'),
                      ),
                    ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(repo.loteDeElegibles, BigInt.from(40), reason: 'al agregar, el lote viaja para marcar a los que ya están');
      expect(find.text('CI 4899241 LP'), findsOneWidget);
      expect(find.text('OPERADOR DE BOBINADORA'), findsOneWidget, reason: 'cargo actual');
      expect(find.textContaining('No tiene usuario en BOSQUE'), findsOneWidget, reason: 'el motivo del SQL');

      // El que no puede no se marca; los otros sí. La búsqueda también encuentra por cargo.
      await tester.tap(find.text('Rojas Vargas Luis'));
      await tester.tap(find.text('Aguilar Cuenca Omar'));
      await tester.pumpAndSettle();
      expect(find.text('1 elegido'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'cajero');
      await tester.pumpAndSettle();
      expect(find.text('Quispe Mamani Ronaldo'), findsOneWidget);
      expect(find.text('Aguilar Cuenca Omar'), findsNothing);
      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();
      expect(elegidos, {BigInt.from(180)});
      expect(tester.takeException(), isNull);
    });
  }
}
