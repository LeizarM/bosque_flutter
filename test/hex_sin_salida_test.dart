import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bosque_flutter/core/state/hex_asignacion_provider.dart';
import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/data/models/hex_asignable_model.dart';
import 'package:bosque_flutter/data/models/hex_asignacion_falta_model.dart';
import 'package:bosque_flutter/data/models/hex_asignacion_model.dart';
import 'package:bosque_flutter/data/models/hex_reporte_model.dart';
import 'package:bosque_flutter/domain/entities/hex_asignable_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_asignacion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_asignacion_falta_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_asignacion_screen.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_revision_screen.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_detalle_reporte.dart';

import 'fakes/arnes_hex.dart';
import 'fakes/repositorio_hex.dart';

/// Textos del SP (adenda D37): la app los muestra tal cual.
const String _avisoSalida =
    'ARANDA VACA no marcó salida: el reporte termina a las 08:00 del 22/09, '
    'su hora de entrada. Verifícalo antes de dar el visto bueno.';
const String _confirmarVisto =
    'Este reporte no tiene salida marcada (termina en su entrada del 22/09 '
    '08:00). ¿Confirmas el visto bueno sin corregir la hora?';
const String _falta1 =
    'ARANDA VACA no marcó salida el 13/10 ni entrada el 14/10: se tomó como '
    'falta y esas horas extra no se pagan.';
const String _falta2 =
    'MAMANI SOSSA no marcó salida el 12/10 ni entrada el 13/10: se tomó como '
    'falta y esas horas extra no se pagan.';

/// Adenda D37 «sin salida marcada»: el aviso del SP en las bandejas y el
/// detalle, el visto bueno confirmable, las faltas en la revisión y el
/// resultado de cada asignación. Sin decisiones de rol en la app.
void main() {
  setUpAll(cargarFuentesHex);
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'hex_como_funciona_plegada': true,
    }),
  );

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  Finder enDialogo(String texto) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(texto));

  const casos = <(double, double)>[
    (390, 1.0),
    (390, 1.5),
    (1400, 1.0),
    (1400, 1.5),
  ];

  // ═════════════════════════════════════════════════════════════════════════
  // MODELOS
  // ═════════════════════════════════════════════════════════════════════════

  group('modelos', () {
    test('Reporte lee sinSalidaMarcada y avisoSalida; sin ellos, falso', () {
      final r =
          HexReporteModel.fromJson({
            'idReporte': 9,
            'sinSalidaMarcada': true,
            'avisoSalida': _avisoSalida,
          }).toEntity();
      expect(r.sinSalidaMarcada, isTrue);
      expect(r.avisoSalida, _avisoSalida);

      final viejo = HexReporteModel.fromJson({'idReporte': 9}).toEntity();
      expect(viejo.sinSalidaMarcada, isFalse);
      expect(viejo.avisoSalida, isNull);
    });

    test('Asignable y Asignacion leen resultado y avisoResultado', () {
      final a =
          HexAsignableModel.fromJson({
            'codEmpleado': 191,
            'resultado': 'FALTA',
            'avisoResultado': _falta1,
          }).toEntity();
      expect(a.resultado, 'FALTA');
      expect(a.avisoResultado, _falta1);

      final h =
          HexAsignacionModel.fromJson({
            'idAsignacion': 7,
            'resultado': 'CON_REPORTE',
          }).toEntity();
      expect(h.resultado, 'CON_REPORTE');
      expect(h.avisoResultado, isNull);
    });

    test('AsignacionFalta lee las seis columnas de F', () {
      final f =
          HexAsignacionFaltaModel.fromJson({
            'idAsignacion': 7,
            'codEmpleado': 191,
            'nombreEmpleado': 'Aranda Vaca Luis',
            'fechaJornada': '2026-10-13',
            'resultado': 'FALTA',
            'avisoResultado': _falta1,
          }).toEntity();
      expect(f.idAsignacion, BigInt.from(7));
      expect(f.codEmpleado, BigInt.from(191));
      expect(f.fechaJornada, DateTime(2026, 10, 13));
      expect(f.resultado, 'FALTA');
      expect(f.avisoResultado, _falta1);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // REVISIÓN DEL ENCARGADO
  // ═════════════════════════════════════════════════════════════════════════

  group('Revisión: sin salida marcada y faltas', () {
    late HexReporteFalso repo;
    late HexAsignacionFalso asignacion;

    setUp(() {
      repo = HexReporteFalso();
      asignacion = HexAsignacionFalso();
      repo.programar('bandejaEncargado', [
        (filas: [_sinSalida], total: 1),
      ]);
    });

    Future<void> montar(WidgetTester t, {double ancho = 1400}) async {
      await montarHex(
        t,
        const HexRevisionScreen(),
        ancho: ancho,
        overrides: [
          hexReporteRepositoryProvider.overrideWithValue(repo),
          hexAsignacionRepositoryProvider.overrideWithValue(asignacion),
        ],
      );
      await esperar(t);
    }

    for (final (ancho, escala) in casos) {
      testWidgets('aviso de salida y faltas a $ancho px y $escala', (t) async {
        t.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        asignacion.programar('faltas', [_faltas]);
        final errores = capturarErrores();
        await montar(t, ancho: ancho);

        expect(find.text('2 asignaciones terminaron en falta'), findsOneWidget);
        expect(find.text(_falta1), findsOneWidget);
        expect(find.text(_falta2), findsOneWidget);
        expect(find.text('Sin salida marcada'), findsOneWidget);
        // En el teléfono, la tarjeta trae el aviso entero; en la tabla va
        // como ayuda de la ficha.
        if (ancho < 1000) {
          expect(find.text(_avisoSalida), findsOneWidget);
        } else {
          expect(find.byTooltip(_avisoSalida), findsOneWidget);
        }
        expect(asignacion.vecesDe('faltas'), 1);
        expect(asignacion.argumentosDe('faltas').single, {'desde': null});
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('sin faltas (204) o sin permiso (403) no hay aviso', (t) async {
      await montar(t);
      expect(find.textContaining('terminó en falta'), findsNothing);
      expect(find.textContaining('terminaron en falta'), findsNothing);
      await cerrar(t);

      asignacion.programar('faltas', [const SinPermisoHex('No')]);
      await montar(t);
      expect(find.textContaining('en falta'), findsNothing);
      expect(find.text('Aranda Vaca Luis'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('más de tres faltas: se ven tres y el resto a pedido', (
      t,
    ) async {
      asignacion.programar('faltas', [
        [
          for (var i = 1; i <= 5; i++)
            HexAsignacionFaltaEntity(
              idAsignacion: BigInt.from(i),
              nombreEmpleado: 'Empleado $i',
              resultado: 'FALTA',
              avisoResultado: 'Falta número $i.',
            ),
        ],
      ]);
      await montar(t);
      expect(find.text('Falta número 3.'), findsOneWidget);
      expect(find.text('Falta número 4.'), findsNothing);
      await t.tap(find.text('Ver las 2 restantes'));
      await esperar(t, 2);
      expect(find.text('Falta número 5.'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('visto bueno: el aviso en el diálogo, el 100 se confirma y '
        'se reenvía con confirmado', (t) async {
      repo.programar('vistoBueno', [
        const ConfirmacionHex(_confirmarVisto),
        (id: BigInt.from(601), mensaje: 'Visto bueno registrado.'),
      ]);
      final errores = capturarErrores();
      await montar(t);
      await t.tap(find.byTooltip('Visto bueno').first);
      await esperar(t, 2);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(_avisoSalida),
        ),
        findsOneWidget,
      );
      await t.tap(enDialogo('Dar visto bueno'));
      await esperar(t, 3);
      expect(find.text(_confirmarVisto), findsOneWidget);
      await t.tap(find.text('Confirmar'));
      await esperar(t, 3);

      expect(repo.argumentosDe('vistoBueno'), [
        {'idReporte': BigInt.from(601), 'observacion': null},
        {
          'idReporte': BigInt.from(601),
          'observacion': null,
          'confirmado': true,
        },
      ]);
      expect(find.text('Visto bueno registrado.'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('visto bueno: cancelar la confirmación no reenvía', (t) async {
      repo.programar('vistoBueno', [const ConfirmacionHex(_confirmarVisto)]);
      await montar(t);
      await t.tap(find.byTooltip('Visto bueno').first);
      await esperar(t, 2);
      await t.tap(enDialogo('Dar visto bueno'));
      await esperar(t, 3);
      await t.tap(find.text('Cancelar').last);
      await esperar(t, 3);
      expect(repo.vecesDe('vistoBueno'), 1);
      await cerrar(t);
    });

    testWidgets('el 35 (falta la hora de salida) solo muestra el mensaje', (
      t,
    ) async {
      const falta35 =
          'Falta la hora de salida: entró el 27/09 a las 08:00 y no marcó '
          'salida. Registre su hora de salida real (corregir la hora) antes '
          'del visto bueno.';
      repo.programar('vistoBueno', [const NegocioHex(falta35)]);
      await montar(t);
      await t.tap(find.byTooltip('Visto bueno').first);
      await esperar(t, 2);
      await t.tap(enDialogo('Dar visto bueno'));
      await esperar(t, 3);
      expect(find.text(falta35), findsOneWidget);
      expect(find.text('Confirma antes de seguir'), findsNothing);
      expect(repo.vecesDe('vistoBueno'), 1);
      await cerrar(t);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // DETALLE
  // ═════════════════════════════════════════════════════════════════════════

  testWidgets('el detalle muestra el aviso de salida del SP', (t) async {
    final repo = HexReporteFalso()..programar('detalle', [_sinSalida]);
    final errores = capturarErrores();
    await montarHex(
      t,
      Builder(
        builder:
            (c) => Center(
              child: FilledButton(
                onPressed: () => mostrarDetalleReporteHex(c, BigInt.from(601)),
                child: const Text('Abrir'),
              ),
            ),
      ),
      ancho: 390,
      overrides: [hexReporteRepositoryProvider.overrideWithValue(repo)],
    );
    await t.tap(find.text('Abrir'));
    await esperar(t);
    expect(find.text(_avisoSalida), findsOneWidget);
    expect(errores, isEmpty, reason: detalle(errores));
    await cerrar(t);
  });

  // ═════════════════════════════════════════════════════════════════════════
  // ASIGNACIÓN: RESULTADO
  // ═════════════════════════════════════════════════════════════════════════

  group('Asignación: resultado de cada asignación', () {
    late HexAsignacionFalso repo;

    setUp(() {
      repo = HexAsignacionFalso();
      repo.programar('asignables', [_asignablesConResultado]);
      repo.programar('historial', [
        (filas: _historialConResultado, total: _historialConResultado.length),
      ]);
    });

    for (final (ancho, escala) in casos) {
      testWidgets('resultado y aviso a $ancho px y $escala', (t) async {
        t.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final errores = capturarErrores();
        await montarHex(
          t,
          const HexAsignacionScreen(),
          ancho: ancho,
          overrides: [hexAsignacionRepositoryProvider.overrideWithValue(repo)],
        );
        await esperar(t);
        expect(find.text('Falta'), findsOneWidget);
        expect(find.text(_falta1), findsOneWidget);
        expect(find.text('Con reporte'), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));

        await t.tap(find.text('Historial').first);
        await esperar(t);
        expect(find.text('Pendiente'), findsOneWidget);
        expect(find.text(_falta2), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }
  });
}

final HexReporteEntity _sinSalida = HexReporteEntity(
  idReporte: BigInt.from(601),
  codEmpleado: BigInt.from(191),
  nombreEmpleado: 'Aranda Vaca Luis',
  fechaJornada: DateTime(2026, 9, 21),
  tipo: 'DESPUES',
  tipoTexto: 'Después del horario',
  tipoDia: 'HABIL',
  tipoDiaTexto: 'Hábil',
  codSucursal: BigInt.one,
  nombreSucursal: 'Planta El Alto',
  inicio: DateTime(2026, 9, 21, 18),
  fin: DateTime(2026, 9, 22, 8),
  origenInicio: 'HORARIO',
  origenFin: 'HORARIO',
  horasPagables: 12,
  estado: 'REPORTADO',
  estadoTexto: 'Reportado',
  puedeEditarHora: true,
  puedeVistoBueno: true,
  puedeRechazar: true,
  totalFilas: 1,
  sinSalidaMarcada: true,
  avisoSalida: _avisoSalida,
);

final List<HexAsignacionFaltaEntity> _faltas = [
  HexAsignacionFaltaEntity(
    idAsignacion: BigInt.from(41),
    codEmpleado: BigInt.from(191),
    nombreEmpleado: 'Aranda Vaca Luis',
    fechaJornada: DateTime(2026, 10, 13),
    resultado: 'FALTA',
    avisoResultado: _falta1,
  ),
  HexAsignacionFaltaEntity(
    idAsignacion: BigInt.from(40),
    codEmpleado: BigInt.from(203),
    nombreEmpleado: 'Mamani Sossa Rosa',
    fechaJornada: DateTime(2026, 10, 12),
    resultado: 'FALTA',
    avisoResultado: _falta2,
  ),
];

final List<HexAsignableEntity> _asignablesConResultado = [
  HexAsignableEntity(
    codEmpleado: BigInt.from(191),
    nombreEmpleado: 'Aranda Vaca Luis',
    cargo: 'Operario de planta',
    nombreSucursal: 'Planta El Alto',
    fechaJornada: DateTime(2026, 10, 13),
    idAsignacion: BigInt.from(41),
    estaAsignado: true,
    nombreAsignador: 'Rojas Vargas Luis',
    textoEstado: 'Asignado por Rojas Vargas Luis',
    resultado: 'FALTA',
    avisoResultado: _falta1,
  ),
  HexAsignableEntity(
    codEmpleado: BigInt.from(204),
    nombreEmpleado: 'Quispe Limachi Juan',
    cargo: 'Montacarguista',
    nombreSucursal: 'Planta El Alto',
    fechaJornada: DateTime(2026, 10, 13),
    idAsignacion: BigInt.from(42),
    estaAsignado: true,
    nombreAsignador: 'Rojas Vargas Luis',
    cantidadReportes: 1,
    idReporte: BigInt.from(101),
    estadoReporte: 'REPORTADO',
    estadoReporteTexto: 'Reportado',
    textoEstado: 'Asignado por Rojas Vargas Luis',
    resultado: 'CON_REPORTE',
  ),
];

final List<HexAsignacionEntity> _historialConResultado = [
  HexAsignacionEntity(
    idAsignacion: BigInt.from(43),
    codEmpleado: BigInt.from(203),
    nombreEmpleado: 'Mamani Sossa Rosa',
    fechaJornada: DateTime(2026, 10, 12),
    estado: 'ACTIVA',
    estadoTexto: 'Asignada',
    nombreAsignador: 'Rojas Vargas Luis',
    fechaAsignacion: DateTime(2026, 10, 12, 9),
    resultado: 'FALTA',
    avisoResultado: _falta2,
    totalFilas: 2,
  ),
  HexAsignacionEntity(
    idAsignacion: BigInt.from(44),
    codEmpleado: BigInt.from(191),
    nombreEmpleado: 'Aranda Vaca Luis',
    fechaJornada: DateTime(2026, 11, 5),
    estado: 'ACTIVA',
    estadoTexto: 'Asignada',
    nombreAsignador: 'Rojas Vargas Luis',
    fechaAsignacion: DateTime(2026, 11, 4, 17),
    resultado: 'PENDIENTE',
    totalFilas: 2,
  ),
];
