import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bosque_flutter/core/state/hex_asignacion_provider.dart';
import 'package:bosque_flutter/data/models/hex_asignable_model.dart';
import 'package:bosque_flutter/data/models/hex_asignacion_model.dart';
import 'package:bosque_flutter/domain/entities/hex_asignable_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_asignacion_entity.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_asignacion_screen.dart';

import 'fakes/arnes_hex.dart';
import 'fakes/repositorio_hex.dart';

/// D42: regularización de días pasados. El SP manda la primera jornada
/// asignable (el calendario empieza ahí), el aviso de la regularización y
/// si una asignación fue atrasada; la app solo los muestra.
void main() {
  setUpAll(cargarFuentesHex);
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'hex_como_funciona_plegada': true,
    }),
  );

  const textoReg =
      'Regularización abierta hasta el 10/11/2026: puedes asignar jornadas '
      'pasadas desde el 01/11/2026.';
  const textoAtrasada =
      'Asignada el 05/11/2026, con fecha atrasada (regularización)';

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  group('Modelos (D42)', () {
    test('asignable: atrasada, primera jornada y aviso, del JSON', () {
      final a =
          HexAsignableModel.fromJson({
            'codEmpleado': 191,
            'nombreEmpleado': 'APAZA',
            'fechaJornada': '2026-11-03',
            'textoAtrasada': textoAtrasada,
            'fechaMinimaAsignable': '2026-11-01',
            'textoRegularizacion': textoReg,
          }).toEntity();
      expect(a.textoAtrasada, textoAtrasada);
      expect(a.fechaMinimaAsignable, DateTime(2026, 11, 1));
      expect(a.textoRegularizacion, textoReg);
    });

    test('sin las columnas nuevas quedan nulas', () {
      final a = HexAsignableModel.fromJson({'codEmpleado': 191}).toEntity();
      expect(a.textoAtrasada, isNull);
      expect(a.fechaMinimaAsignable, isNull);
      expect(a.textoRegularizacion, isNull);
      final h = HexAsignacionModel.fromJson({'idAsignacion': 1}).toEntity();
      expect(h.textoAtrasada, isNull);
    });

    test('historial: textoAtrasada del JSON', () {
      final h =
          HexAsignacionModel.fromJson({
            'idAsignacion': 12,
            'estado': 'ACTIVA',
            'textoAtrasada': textoAtrasada,
          }).toEntity();
      expect(h.textoAtrasada, textoAtrasada);
    });
  });

  group('Asignar con la regularización (D42)', () {
    late HexAsignacionFalso repo;

    setUp(() => repo = HexAsignacionFalso());

    List<HexAsignableEntity> conRegularizacion() => [
      HexAsignableEntity(
        codEmpleado: BigInt.from(191),
        nombreEmpleado: 'Apaza Mamani Pedro',
        fechaJornada: DateTime(2026, 11, 3),
        puedeAsignar: true,
        textoEstado:
            'Sin asignar: jornada pasada; se puede asignar hasta el '
            '10/11/2026 (regularización)',
        fechaMinimaAsignable: DateTime(2026, 11, 1),
        textoRegularizacion: textoReg,
      ),
      HexAsignableEntity(
        codEmpleado: BigInt.from(204),
        nombreEmpleado: 'Quispe Limachi Juan',
        fechaJornada: DateTime(2026, 11, 3),
        idAsignacion: BigInt.from(30),
        estaAsignado: true,
        textoEstado: 'Asignado por Rojas Vargas Luis',
        textoAtrasada: textoAtrasada,
        fechaMinimaAsignable: DateTime(2026, 11, 1),
        textoRegularizacion: textoReg,
      ),
    ];

    Future<void> montar(WidgetTester t, {double ancho = 1400}) async {
      await montarHex(
        t,
        const HexAsignacionScreen(),
        ancho: ancho,
        overrides: [hexAsignacionRepositoryProvider.overrideWithValue(repo)],
      );
      await esperar(t);
    }

    for (final ancho in const [390.0, 1400.0]) {
      testWidgets('aviso de la regularización y fila atrasada a $ancho px', (
        t,
      ) async {
        final errores = capturarErrores();
        repo.programar('asignables', [conRegularizacion()]);
        await montar(t, ancho: ancho);
        expect(find.text(textoReg), findsOneWidget);
        expect(find.text(textoAtrasada), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('sin regularización no hay aviso', (t) async {
      await montar(t);
      expect(find.textContaining('Regularización abierta'), findsNothing);
      expect(find.textContaining('fecha atrasada'), findsNothing);
      await cerrar(t);
    });

    testWidgets('el calendario empieza en la primera jornada del SP', (
      t,
    ) async {
      repo.programar('asignables', [conRegularizacion()]);
      await montar(t);
      await t.tap(find.byIcon(Icons.event_outlined).first);
      await esperar(t);
      final dialogo = t.widget<DatePickerDialog>(find.byType(DatePickerDialog));
      expect(dialogo.firstDate, DateTime(2026, 11, 1));
      await t.tap(find.text('Cancelar'));
      await esperar(t);
      await cerrar(t);
    });

    testWidgets('el historial dice cuál fue atrasada', (t) async {
      final errores = capturarErrores();
      repo.programar('historial', [
        (
          filas: [
            HexAsignacionEntity(
              idAsignacion: BigInt.from(40),
              codEmpleado: BigInt.from(191),
              nombreEmpleado: 'Apaza Mamani Pedro',
              fechaJornada: DateTime(2026, 11, 3),
              estado: 'ACTIVA',
              estadoTexto: 'Asignada',
              nombreAsignador: 'Rojas Vargas Luis',
              fechaAsignacion: DateTime(2026, 11, 5, 10),
              totalFilas: 1,
              textoAtrasada: textoAtrasada,
            ),
          ],
          total: 1,
        ),
      ]);
      await montar(t);
      await t.tap(find.text('Historial').first);
      await esperar(t);
      expect(find.text(textoAtrasada), findsOneWidget);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });
  });
}
