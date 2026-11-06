import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/data/models/hex_reporte_model.dart';
import 'package:bosque_flutter/data/models/hex_reporte_tramo_model.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_detalle_reporte.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_tramos_reporte.dart';

import 'fakes/arnes_hex.dart';
import 'fakes/repositorio_hex.dart';

/// D36: el reporte por tramos. El modelo, el reparto de la barra y el detalle
/// con el ejemplo del usuario (18:30 → 21:00) en el teléfono y en el ancho.
void main() {
  setUpAll(cargarFuentesHex);

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  final reporte = HexReporteEntity(
    idReporte: BigInt.from(701),
    nombreEmpleado: 'Mamani Quispe Juan Carlos',
    fechaJornada: DateTime(2026, 10, 23),
    tipo: 'DESPUES',
    tipoTexto: 'Después del horario',
    tipoDia: 'HABIL',
    tipoDiaTexto: 'Hábil',
    inicio: DateTime(2026, 10, 23, 18, 30),
    fin: DateTime(2026, 10, 23, 21),
    origenInicio: 'HORARIO',
    origenFin: 'APP',
    horasPagables: 0.5,
    montoHoras: 12.8,
    montoComidas: 30,
    montoTotal: 42.8,
    comidas: 'C,DC',
    estado: 'REPORTADO',
    estadoTexto: 'Reportado',
    resumenTiempo: resumenCenaD36,
    // D38: quien lo abre ve el detalle (encargado, jefe o RRHH).
    puedeVerDetalle: true,
    verMontos: true,
  );
  final sinResumen = HexReporteEntity(
    idReporte: BigInt.from(702),
    nombreEmpleado: 'Mamani Quispe Juan Carlos',
    fechaJornada: DateTime(2026, 10, 23),
    inicio: DateTime(2026, 10, 23, 18, 30),
    fin: DateTime(2026, 10, 23, 21),
    horasPagables: 0.5,
    estado: 'REPORTADO',
    estadoTexto: 'Reportado',
    puedeVerDetalle: true,
  );

  group('modelos', () {
    test('Tramo lee las columnas de T', () {
      final e =
          HexReporteTramoModel.fromJson({
            'orden': 3,
            'desde': '2026-10-23T20:30:00.000',
            'hasta': '2026-10-23T21:00:00.000',
            'horaDesde': '20:30',
            'horaHasta': '21:00',
            'minutos': 30,
            'duracionTexto': '30 min',
            'clase': 'HORA',
            'codigo': 'H50',
            'leyenda': 'Hora con recargo del 50 %',
            'textoPago': 'Se paga como hora: ×1,5 (recargo del 50 %)',
            'resumen': resumenCenaD36,
          }).toEntity();
      expect(e.orden, 3);
      expect(e.desde, DateTime(2026, 10, 23, 20, 30));
      expect(e.hasta, DateTime(2026, 10, 23, 21));
      expect(e.minutos, 30);
      expect(e.clase, 'HORA');
      expect(e.codigo, 'H50');
      expect(e.textoPago, contains('×1,5'));
      expect(e.resumen, resumenCenaD36);
    });

    test('un tramo sin pago puede venir sin código ni leyenda', () {
      final e =
          HexReporteTramoModel.fromJson({
            'clase': 'SIN_PAGO',
            'codigo': null,
            'leyenda': '',
          }).toEntity();
      expect(e.codigo, isNull);
      expect(e.leyenda, isNull);
      expect(e.minutos, 0);
    });

    test('Reporte lee resumenTiempo; si falta o es NULL queda nulo', () {
      expect(
        HexReporteModel.fromJson({
          'resumenTiempo': resumenCenaD36,
        }).toEntity().resumenTiempo,
        resumenCenaD36,
      );
      expect(HexReporteModel.fromJson({}).toEntity().resumenTiempo, isNull);
      expect(
        HexReporteModel.fromJson({
          'resumenTiempo': null,
        }).toEntity().resumenTiempo,
        isNull,
      );
    });
  });

  group('reparto de la barra', () {
    test('proporcional a los minutos y suma el ancho', () {
      final a = anchosTramosHex([60, 60, 30], 300);
      expect(a, [120, 120, 60]);
    });

    test('un tramo muy corto queda con el mínimo y no se pierde', () {
      final a = anchosTramosHex([600, 1, 600], 300);
      expect(a[1], 6);
      expect(a.fold<double>(0, (x, y) => x + y), closeTo(300, 1e-9));
      expect(a[0], closeTo(147, 1e-9));
    });

    test('si no alcanza para el mínimo de todos, van iguales', () {
      expect(anchosTramosHex([1, 1, 500], 12), [4, 4, 4]);
      expect(anchosTramosHex([], 100), isEmpty);
      expect(anchosTramosHex([30], 0), [0]);
    });

    test('las horas que se pisan se ocultan, el inicio y el fin no', () {
      // Bordes en 0, 10, 100 y 300 con etiquetas de 30 px.
      final v = etiquetasVisiblesHex([0, 10, 100, 300], [30, 30, 30, 30], 300);
      expect(v, [true, false, true, true]);
    });
  });

  group('el detalle por tramos', () {
    Widget abridor(BigInt id) => Builder(
      builder:
          (c) => Center(
            child: FilledButton(
              onPressed: () => mostrarDetalleReporteHex(c, id),
              child: const Text('Abrir'),
            ),
          ),
    );

    Future<void> abrir(
      WidgetTester t,
      HexReporteFalso repo,
      HexReporteEntity r, {
      required double ancho,
    }) async {
      await montarHex(
        t,
        abridor(r.idReporte!),
        ancho: ancho,
        overrides: [hexReporteRepositoryProvider.overrideWithValue(repo)],
      );
      await t.tap(find.text('Abrir'));
      await esperar(t);
    }

    // La lista del panel se arma a medida que se desplaza: baja hasta [f].
    Future<void> ver(WidgetTester t, Finder f) => t.scrollUntilVisible(
      f,
      120,
      scrollable:
          find
              .descendant(
                of: find.byType(PanelHex),
                matching: find.byType(Scrollable),
              )
              .first,
    );

    final casos = <(double, double)>[(390, 1.0), (390, 1.5), (1400, 1.0)];
    for (final (ancho, escala) in casos) {
      testWidgets('tres tramos a $ancho px y letra $escala', (t) async {
        t.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final repo =
            HexReporteFalso()
              ..programar('detalle', [reporte])
              ..programar('tramos', [tramosCenaD36]);
        final errores = capturarErrores();
        await abrir(t, repo, reporte, ancho: ancho);

        // La tarjeta Inicio → Fin dice el tiempo en palabras del SP.
        expect(find.text(resumenCenaD36), findsOneWidget);
        expect(find.text('0,50 h'), findsNothing);

        await ver(t, find.text('Por tramos'));
        // «Por tramos» va antes que «Desglose»: aún no llegó o está debajo.
        final desglose = find.text('Desglose');
        if (desglose.evaluate().isNotEmpty) {
          expect(
            t.getTopLeft(find.text('Por tramos')).dy,
            lessThan(t.getTopLeft(desglose).dy),
          );
        }
        await ver(t, find.byType(BarraTramosHex));
        for (final texto in [
          '18:30 → 19:30',
          'Gana la cena: se paga solo con la comida',
          '19:30 → 20:30',
          'La cena pasa a doble cena: se paga solo con la comida',
          '20:30 → 21:00',
          '30 min',
          'Se paga como hora: ×1,5 (recargo del 50 %)',
        ]) {
          await ver(t, find.text(texto));
          expect(find.text(texto), findsOneWidget, reason: texto);
        }
        // Tabla en el ancho, tarjetas en el teléfono.
        expect(
          find.byType(Table),
          ancho >= 1000 ? findsOneWidget : findsNothing,
        );
        expect(repo.argumentosDe('tramos').single, {
          'idReporte': BigInt.from(701),
        });
        await ver(t, find.text('Desglose'));
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('sin resumenTiempo la tarjeta muestra las horas de hoy', (
      t,
    ) async {
      final repo = HexReporteFalso()..programar('detalle', [sinResumen]);
      final errores = capturarErrores();
      await abrir(t, repo, sinResumen, ancho: 390);

      expect(find.text('0,50 h'), findsOneWidget);
      expect(find.text('Todavía no hay tramos calculados.'), findsOneWidget);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('un error al cargar los tramos no tapa el resto', (t) async {
      final repo =
          HexReporteFalso()
            ..programar('detalle', [reporte])
            ..programar('tramos', [
              const NegocioHex('No se pudieron armar los tramos.'),
              tramosCenaD36,
            ]);
      final errores = capturarErrores();
      await abrir(t, repo, reporte, ancho: 390);

      await ver(t, find.text('No se pudieron armar los tramos.'));
      expect(find.text('No se pudieron armar los tramos.'), findsOneWidget);
      await t.tap(find.text('Reintentar'));
      await esperar(t);
      expect(find.text('No se pudieron armar los tramos.'), findsNothing);
      await ver(t, find.text('20:30 → 21:00'));
      expect(find.text('20:30 → 21:00'), findsOneWidget);
      // El resto del detalle sigue ahí (sin historial: D38, no es RRHH).
      await ver(t, find.text('Desglose'));
      expect(find.text('Desglose'), findsOneWidget);
      expect(find.text('Historial'), findsNothing);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });
  });

  group('la lista de reportes', () {
    testWidgets('la tarjeta del teléfono muestra resumenTiempo', (t) async {
      final errores = capturarErrores();
      await montarHex(
        t,
        SingleChildScrollView(child: TarjetaReporteHex(reporte)),
        ancho: 390,
      );
      expect(find.text(resumenCenaD36), findsOneWidget);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('la celda de horas lleva el resumen como segunda línea', (
      t,
    ) async {
      final errores = capturarErrores();
      await montarHex(
        t,
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 90, child: HorasReporteHex(reporte)),
        ),
      );
      expect(find.text('0,50 h'), findsOneWidget);
      expect(find.text(resumenCenaD36), findsOneWidget);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });
  });
}
