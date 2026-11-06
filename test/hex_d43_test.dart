import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/hex_asignacion_provider.dart';
import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/data/models/hex_jornada_pasada_model.dart';
import 'package:bosque_flutter/domain/entities/hex_jornada_pasada_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_revision_screen.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formatos.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_reporte_pasado.dart';

import 'fakes/arnes_hex.dart';
import 'fakes/repositorio_hex.dart';

/// D43: el encargado crea el reporte de un día pasado sin marca. La lista,
/// el tipo y los textos son del SP; el botón sale solo con filas y con el
/// botón de corregir hora; la app manda empleado, jornada, horas y texto.
void main() {
  setUpAll(cargarFuentesHex);

  const textoReg =
      'Regularización abierta hasta el 10/11/2026: jornadas pasadas desde el '
      '01/11/2026.';
  const sinBiometrico =
      'Sin horario asignado en el biométrico para esa jornada: pida a RRHH '
      'que se lo asigne.';

  final despues = HexJornadaPasadaEntity(
    codEmpleado: BigInt.from(101),
    nombreEmpleado: 'ARANDA VACA LUIS ALBERTO',
    cargo: 'OPERARIO',
    nombreSucursal: 'CENTRAL',
    fechaJornada: DateTime(2026, 11, 3),
    tipoDia: 'HABIL',
    textoTipoDia: 'Hábil',
    textoHorario: 'De 08:00 a 18:00',
    tipoSugerido: 'DESPUES',
    inicioSugerido: DateTime(2026, 11, 3, 18),
    finSugerido: DateTime(2026, 11, 3, 21, 30),
    motivo: 'Descarga de contenedor',
    textoAyuda: 'Las horas del horario no se pagan.',
    puedeCrear: true,
    textoRegularizacion: textoReg,
  );
  final bloqueada = HexJornadaPasadaEntity(
    codEmpleado: BigInt.from(106),
    nombreEmpleado: 'FERNANDEZ CARLOS',
    fechaJornada: DateTime(2026, 11, 2),
    textoTipoDia: 'Hábil',
    textoHorario: 'Sin horario asignado en el biométrico',
    tipoSugerido: 'DESPUES',
    textoAyuda: sinBiometrico,
    textoRegularizacion: textoReg,
  );

  late HexReporteFalso repo;
  late HexAsignacionFalso asignacion;

  setUp(() {
    repo = HexReporteFalso();
    asignacion = HexAsignacionFalso();
  });

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  Future<void> montar(
    WidgetTester t, {
    double ancho = 1400,
    Set<String>? botones,
  }) async {
    await montarHex(
      t,
      const HexRevisionScreen(),
      ancho: ancho,
      botones: botones,
      overrides: [
        hexReporteRepositoryProvider.overrideWithValue(repo),
        hexAsignacionRepositoryProvider.overrideWithValue(asignacion),
      ],
    );
    await esperar(t);
  }

  Finder boton() => find.text(textoCrearPasadoHex);

  Finder enDialogo(String texto) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(texto));

  Future<void> abrir(WidgetTester t) async {
    await t.ensureVisible(boton().first);
    await t.tap(boton().first);
    await esperar(t);
  }

  Future<void> crear(WidgetTester t) async {
    final accion = find.text('Crear reporte');
    await t.ensureVisible(accion);
    await t.tap(accion);
    await esperar(t);
  }

  group('Modelo (D43)', () {
    test('la fila del SP, con las horas sugeridas sin zona', () {
      final j =
          HexJornadaPasadaModel.fromJson({
            'codEmpleado': 101,
            'nombreEmpleado': 'ARANDA',
            'fechaJornada': '2026-11-03',
            'tipoSugerido': 'DESPUES',
            'inicioSugerido': '2026-11-03T18:00:00',
            'finSugerido': null,
            'puedeCrear': 1,
            'textoRegularizacion': textoReg,
          }).toEntity();
      expect(j.codEmpleado, BigInt.from(101));
      expect(j.fechaJornada, DateTime(2026, 11, 3));
      expect(j.inicioSugerido, DateTime(2026, 11, 3, 18));
      expect(j.finSugerido, isNull);
      expect(j.puedeCrear, isTrue);
      expect(j.textoRegularizacion, textoReg);
    });

    test('el cuerpo de crear: solo empleado, jornada, horas y texto', () {
      final cuerpo =
          HexReportePasadoModel.fromEntity(
            HexReportePasadoEntity(
              codEmpleado: BigInt.from(101),
              fechaJornada: DateTime(2026, 11, 1),
              inicio: DateTime(2026, 11, 1, 8),
              fin: DateTime(2026, 11, 1, 12),
              observacion: 'Falla del biométrico',
            ),
          ).toJson();
      expect(cuerpo, {
        'codEmpleado': 101,
        'fechaJornada': '2026-11-01',
        'inicio': '2026-11-01T08:00:00.000',
        'fin': '2026-11-01T12:00:00.000',
        'observacion': 'Falla del biométrico',
      });
    });
  });

  group('Botón «Crear reporte de un día pasado» (D43)', () {
    testWidgets('sin jornadas (204) no aparece', (t) async {
      await montar(t);
      expect(repo.vecesDe('jornadasPasadas'), greaterThan(0));
      expect(boton(), findsNothing);
      await cerrar(t);
    });

    testWidgets('con jornadas y el botón de corregir hora aparece', (t) async {
      repo.programar('jornadasPasadas', [
        [despues],
      ]);
      await montar(t, botones: {BotonHex.editarHora});
      expect(boton(), findsOneWidget);
      expect(find.text(textoReg), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('con jornadas pero sin el botón de corregir hora no aparece', (
      t,
    ) async {
      repo.programar('jornadasPasadas', [
        [despues],
      ]);
      await montar(t, botones: {BotonHex.vistoBueno});
      expect(boton(), findsNothing);
      await cerrar(t);
    });

    testWidgets('si la lista falla, la bandeja sigue y el botón no sale', (
      t,
    ) async {
      repo.programar('jornadasPasadas', [const NegocioHex('Sin servicio')]);
      await montar(t);
      expect(boton(), findsNothing);
      expect(find.text('Revisión de encargado'), findsOneWidget);
      expect(find.text('Sin servicio'), findsNothing);
      await cerrar(t);
    });
  });

  group('Diálogo (D43)', () {
    testWidgets('un 400 del SP se muestra y el diálogo sigue abierto', (
      t,
    ) async {
      const regla =
          'Escriba la justificación: por qué crea el reporte sin la marca del '
          'biométrico.';
      repo.programar('jornadasPasadas', [
        [despues, bloqueada],
      ]);
      repo.programar('crearReportePasado', [const NegocioHex(regla)]);
      await montar(t);
      await abrir(t);
      // Con una sola jornada que se puede crear ya va elegida y con las horas
      // sugeridas; la bloqueada se ve con su razón.
      expect(enDialogo(sinBiometrico), findsOneWidget);
      expect(enDialogo('18:00'), findsOneWidget);
      expect(enDialogo('21:30'), findsOneWidget);
      await crear(t);
      expect(find.text(regla), findsOneWidget);
      expect(find.text('Crear reporte'), findsOneWidget);
      final args = repo.argumentosDe('crearReportePasado').single;
      expect(args['codEmpleado'], BigInt.from(101));
      expect(args['fechaJornada'], DateTime(2026, 11, 3));
      expect(args['inicio'], DateTime(2026, 11, 3, 18));
      expect(args['fin'], DateTime(2026, 11, 3, 21, 30));
      await cerrar(t);
    });

    testWidgets('al crear cierra, avisa y recarga bandeja y lista', (t) async {
      repo.programar('jornadasPasadas', [
        [despues],
        <HexJornadaPasadaEntity>[],
      ]);
      repo.programar('crearReportePasado', [
        (id: BigInt.from(88), mensaje: 'Reporte creado: queda reportado.'),
      ]);
      await montar(t);
      final bandejas = repo.vecesDe('bandejaEncargado');
      final listas = repo.vecesDe('jornadasPasadas');
      await abrir(t);
      await t.enterText(
        find.widgetWithText(TextField, 'Justificación'),
        'No marcó por falla del biométrico',
      );
      await crear(t);
      expect(find.text('Crear reporte'), findsNothing);
      expect(find.text('Reporte creado: queda reportado.'), findsOneWidget);
      expect(repo.vecesDe('bandejaEncargado'), greaterThan(bandejas));
      expect(repo.vecesDe('jornadasPasadas'), greaterThan(listas));
      expect(boton(), findsNothing);
      expect(
        repo.argumentosDe('crearReportePasado').single['observacion'],
        'No marcó por falla del biométrico',
      );
      await cerrar(t);
    });

    testWidgets('sin jornada elegida no se puede crear', (t) async {
      repo.programar('jornadasPasadas', [
        [despues, despues, bloqueada],
      ]);
      await montar(t);
      await abrir(t);
      expect(
        find.text('Elige la jornada del empleado en la lista.'),
        findsOneWidget,
      );
      await crear(t);
      expect(repo.vecesDe('crearReportePasado'), 0);
      await cerrar(t);
    });

    for (final ancho in const [360.0, 1400.0]) {
      testWidgets('a $ancho px, sin desbordes', (t) async {
        final errores = capturarErrores();
        repo.programar('jornadasPasadas', [
          [despues, bloqueada],
        ]);
        await montar(t, ancho: ancho);
        expect(boton(), findsOneWidget);
        await abrir(t);
        expect(find.text(textoReg), findsWidgets);
        expect(find.text(sinBiometrico), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }
  });
}
