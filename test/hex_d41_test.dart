import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bosque_flutter/core/state/hex_asignacion_provider.dart';
import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/domain/entities/hex_vista_marcacion_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/domain/repositories/hex_ubicacion_repository.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_asignacion_screen.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_mis_horas_screen.dart';

import 'fakes/arnes_hex.dart';
import 'fakes/repositorio_hex.dart';
import 'fakes/ubicacion_hex_falsa.dart';

/// D41: el motivo lo escribe quien asigna y el operario solo lo lee; «Mis
/// horas extra» más simple (sin leyenda, sin acciones, solo las teclas que
/// valen). Teléfono y escritorio, letra 1.0 y 1.5, sin desbordes.
void main() {
  setUpAll(cargarFuentesHex);
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'hex_como_funciona_plegada': true,
    }),
  );

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  ButtonStyleButton boton(WidgetTester t, String texto) =>
      t.widget<ButtonStyleButton>(
        find
            .ancestor(
              of: find.text(texto),
              matching: find.bySubtype<ButtonStyleButton>(),
            )
            .first,
      );

  Future<void> tocar(WidgetTester t, Finder f, {int fotogramas = 4}) async {
    await t.ensureVisible(f);
    await esperar(t, 1);
    await t.tap(f);
    await esperar(t, fotogramas);
  }

  const casos = <(double, double)>[
    (390, 1.0),
    (390, 1.5),
    (1400, 1.0),
    (1400, 1.5),
  ];

  group('Asignar: el motivo (D41)', () {
    late HexAsignacionFalso repo;

    setUp(() => repo = HexAsignacionFalso());

    Future<void> montar(WidgetTester t, {double ancho = 1400}) async {
      await montarHex(
        t,
        const HexAsignacionScreen(),
        ancho: ancho,
        overrides: [hexAsignacionRepositoryProvider.overrideWithValue(repo)],
      );
      await esperar(t);
    }

    for (final (ancho, escala) in casos) {
      testWidgets('motivo en la barra, en la fila y en el historial a '
          '$ancho px y $escala', (t) async {
        t.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        expect(find.widgetWithText(TextField, 'Motivo'), findsOneWidget);
        expect(find.text('Observación (opcional)'), findsNothing);
        // El asignado muestra el motivo que verá el operario.
        expect(
          find.textContaining('Descarga de contenedor', findRichText: true),
          findsOneWidget,
        );
        expect(errores, isEmpty, reason: detalle(errores));

        await tocar(t, find.text('Historial').first);
        expect(
          find.textContaining(
            'Carga de camión a Santa Cruz',
            findRichText: true,
          ),
          findsOneWidget,
        );
        if (ancho >= 1400) expect(find.text('Motivo'), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('asignar manda el motivo escrito, sin espacios a los lados', (
      t,
    ) async {
      await montar(t);
      await tocar(
        t,
        find.bySemanticsLabel('Elegir a Apaza Mamani Pedro'),
        fotogramas: 1,
      );
      await t.enterText(
        find.widgetWithText(TextField, 'Motivo'),
        '  Inventario de fin de mes  ',
      );
      await tocar(t, find.widgetWithText(FilledButton, 'Asignar horas extra'));
      final envio = repo.argumentosDe('asignar').single;
      expect(envio['motivo'], 'Inventario de fin de mes');
      expect(envio['codEmpleados'], [BigInt.from(191)]);
      // Asignó: el campo se limpia.
      expect(
        t
            .widget<TextField>(find.widgetWithText(TextField, 'Motivo'))
            .controller!
            .text,
        isEmpty,
      );
      await cerrar(t);
    });

    testWidgets('sin motivo el texto es del SP y nada se limpia', (t) async {
      const regla =
          'Escribe el motivo: qué trabajo harán en esas horas extra. Lo verán '
          'tal cual en «Mis horas extra».';
      repo.programar('asignar', [const NegocioHex(regla)]);
      await montar(t);
      await tocar(
        t,
        find.bySemanticsLabel('Elegir a Apaza Mamani Pedro'),
        fotogramas: 1,
      );
      // La app no lo decide: el botón vale y el pedido viaja con el motivo vacío.
      expect(boton(t, 'Asignar horas extra').onPressed, isNotNull);
      await tocar(t, find.widgetWithText(FilledButton, 'Asignar horas extra'));
      expect(repo.argumentosDe('asignar').single['motivo'], '');
      expect(find.text(regla), findsOneWidget);
      expect(find.text('1 persona elegida'), findsOneWidget);
      await cerrar(t);
    });
  });

  group('Mis horas extra más simple (D41)', () {
    late HexReporteFalso repo;
    late UbicacionHexFalsa ubicacion;

    setUp(() {
      repo = HexReporteFalso();
      ubicacion = UbicacionHexFalsa();
    });

    Future<void> montar(WidgetTester t, {double ancho = 1400}) async {
      await montarHex(
        t,
        const HexMisHorasScreen(),
        ancho: ancho,
        overrides: [
          hexReporteRepositoryProvider.overrideWithValue(repo),
          hexUbicacionProvider.overrideWithValue(ubicacion),
        ],
      );
      await esperar(t);
    }

    for (final (ancho, escala) in casos) {
      testWidgets('quién asignó y el motivo, sin campo ni leyenda a $ancho px '
          'y $escala', (t) async {
        t.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        expect(find.text(vistaMarcacionFalsa.textoVista), findsOneWidget);
        expect(find.text('Motivo'), findsOneWidget);
        expect(find.text('Inventario de fin de mes'), findsOneWidget);
        // Solo lectura: no hay dónde escribirlo.
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Motivo (opcional)'), findsNothing);
        expect(find.text('¿Qué significan los códigos?'), findsNothing);
        expect(find.text('Leyenda de códigos'), findsNothing);
        // Todo en orden: una sola línea, y las dos teclas que valen.
        expect(find.text('Todo listo para marcar'), findsOneWidget);
        expect(find.text('Antes de marcar'), findsNothing);
        expect(boton(t, 'Marcar salida').onPressed, isNotNull);
        expect(boton(t, 'Marcar entrada').onPressed, isNotNull);
        expect(errores, isEmpty, reason: detalle(errores));

        await tocar(t, find.text('Todo listo para marcar'));
        expect(find.text('Ubicación activa'), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('solo la tecla que vale; la otra deja su texto sin botón', (
      t,
    ) async {
      const yaMarco = 'Ya registraste tu entrada de hoy.';
      repo.programar('hoy', [
        HexVistaMarcacionEntity(
          vistaHabilitada: true,
          textoVista: vistaMarcacionFalsa.textoVista,
          motivoAsignacion: 'Descarga de contenedor',
          textoMarcarEntrada: yaMarco,
          puedeMarcarSalida: true,
          textoMarcarSalida: vistaMarcacionFalsa.textoMarcarSalida,
        ),
      ]);
      final errores = capturarErrores();
      await montar(t, ancho: 390);
      expect(find.text('Marcar entrada'), findsNothing);
      expect(find.text(yaMarco), findsOneWidget);
      expect(boton(t, 'Marcar salida').onPressed, isNotNull);
      expect(find.text('Descarga de contenedor'), findsOneWidget);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('sin ninguna tecla, los textos del SP y ningún botón', (
      t,
    ) async {
      const salida = 'Tu horario de hoy termina a las 18:00.';
      const entrada = 'Tu horario de hoy empezó a las 08:00.';
      repo.programar('hoy', [
        HexVistaMarcacionEntity(
          vistaHabilitada: true,
          textoVista: vistaMarcacionFalsa.textoVista,
          textoMarcarEntrada: entrada,
          textoMarcarSalida: salida,
        ),
      ]);
      await montar(t, ancho: 390);
      expect(find.text('Marcar entrada'), findsNothing);
      expect(find.text('Marcar salida'), findsNothing);
      expect(find.text(salida), findsOneWidget);
      expect(find.text(entrada), findsOneWidget);
      // Sin motivo (una asignación anterior a D41) no hay rótulo vacío.
      expect(find.text('Motivo'), findsNothing);
      await cerrar(t);
    });

    testWidgets('sin ubicación se ve solo lo que falta, con cómo arreglarlo', (
      t,
    ) async {
      ubicacion.estado = EstadoUbicacionHex.servicioApagado;
      await montar(t, ancho: 390);
      expect(find.text('Antes de marcar'), findsOneWidget);
      expect(find.text('Ubicación apagada'), findsOneWidget);
      expect(find.text('Activar ubicación'), findsOneWidget);
      // Los requisitos que se cumplen quedan en «Ver todo».
      expect(find.text(requisitosFalsos.first.titulo), findsNothing);
      await tocar(t, find.text('Ver todo'));
      expect(find.text(requisitosFalsos.first.titulo), findsOneWidget);
      expect(boton(t, 'Marcar salida').onPressed, isNull);
      await cerrar(t);
    });
  });
}
