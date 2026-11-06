import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/hex_mapa_provider.dart';
import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_detalle_reporte.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_donde_marco.dart';

import 'fakes/arnes_hex.dart';
import 'fakes/repositorio_hex.dart';

/// Un PNG de 1×1 transparente: las teselas del mapa no piden la red.
final _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _TeselasFalsas extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_pixel);
}

/// Las direcciones que la app pidió abrir, y si el dispositivo pudo.
class _Abridor {
  _Abridor({this.resultado = true, this.lanza = false});

  final bool resultado;
  final bool lanza;
  final List<Uri> abiertas = [];

  Future<bool> abrir(Uri url) async {
    abiertas.add(url);
    if (lanza) throw StateError('sin navegador');
    return resultado;
  }
}

void main() {
  setUpAll(cargarFuentesHex);

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  /// Entrada 07:02 (±12 m) y salida 22:05 (±8 m), las dos de la app.
  final conAmbas = HexReporteEntity(
    idReporte: BigInt.from(501),
    nombreEmpleado: 'Mamani Quispe Juan Carlos',
    fechaJornada: DateTime(2026, 10, 23),
    tipo: 'DESPUES',
    tipoTexto: 'Después del horario',
    estado: 'REPORTADO',
    estadoTexto: 'Reportado',
    inicio: DateTime(2026, 10, 23, 7, 2),
    fin: DateTime(2026, 10, 23, 22, 5),
    origenInicio: 'APP',
    origenFin: 'APP',
    latInicio: -16.500123,
    lonInicio: -68.150456,
    precisionInicio: 12,
    latFin: -16.51,
    lonFin: -68.16,
    precisionFin: 8,
  );

  final soloEntrada = HexReporteEntity(
    idReporte: BigInt.from(502),
    nombreEmpleado: 'Rojas Vargas Luis',
    fechaJornada: DateTime(2026, 10, 23),
    estado: 'REPORTADO',
    estadoTexto: 'Reportado',
    inicio: DateTime(2026, 10, 23, 7, 2),
    origenInicio: 'APP',
    latInicio: -16.500123,
    lonInicio: -68.150456,
    precisionInicio: 12,
  );

  final sinUbicacion = HexReporteEntity(
    idReporte: BigInt.from(503),
    nombreEmpleado: 'Quispe Rojas Ana',
    fechaJornada: DateTime(2026, 10, 23),
    estado: 'REPORTADO',
    estadoTexto: 'Reportado',
    inicio: DateTime(2026, 10, 23, 18),
    fin: DateTime(2026, 10, 23, 20),
    origenInicio: 'HORARIO',
    origenFin: 'BIOMETRICO',
  );

  List<Override> sinRed({HexReporteFalso? repo, _Abridor? abridor}) => [
    hexTeselasProvider.overrideWithValue(() => _TeselasFalsas()),
    if (repo != null) hexReporteRepositoryProvider.overrideWithValue(repo),
    if (abridor != null) hexAbrirUrlProvider.overrideWithValue(abridor.abrir),
  ];

  Widget seccion(HexReporteEntity r) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: DondeMarcoHex(r),
  );

  group('la sección DondeMarcoHex', () {
    testWidgets('sin coordenadas no dibuja nada', (t) async {
      final errores = capturarErrores();
      await montarHex(t, seccion(sinUbicacion), overrides: sinRed());
      expect(find.text('Dónde marcó'), findsNothing);
      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text('Abrir en Google Maps'), findsNothing);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('con solo la latitud tampoco hay ubicación', (t) async {
      final media = HexReporteEntity(
        idReporte: BigInt.from(504),
        latInicio: -16.5,
        lonFin: -68.1,
      );
      await montarHex(t, seccion(media), overrides: sinRed());
      expect(find.byType(FlutterMap), findsNothing);
      await cerrar(t);
    });

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('con entrada y salida muestra el mapa y las dos leyendas a '
          '$ancho px', (t) async {
        final errores = capturarErrores();
        await montarHex(
          t,
          seccion(conAmbas),
          ancho: ancho,
          overrides: sinRed(),
        );
        await esperar(t, 2);

        expect(find.text('Dónde marcó'), findsOneWidget);
        expect(find.byType(FlutterMap), findsOneWidget);
        expect(find.text('Entrada · 07:02 · ±12 m'), findsOneWidget);
        expect(find.text('Salida · 22:05 · ±8 m'), findsOneWidget);
        expect(find.text('Abrir en Google Maps'), findsNWidgets(2));
        // Un marcador y un renglón de leyenda por cada punto.
        expect(find.byIcon(Icons.login), findsNWidgets(2));
        expect(find.byIcon(Icons.logout), findsNWidgets(2));

        final mapa = t.getRect(find.byType(FlutterMap));
        final leyenda = t.getTopLeft(find.text('Entrada · 07:02 · ±12 m'));
        if (ancho < 560) {
          // En el teléfono: el mapa a lo ancho y la leyenda debajo.
          expect(mapa.height, closeTo(220, 2));
          expect(mapa.width, greaterThan(ancho - 40));
          expect(leyenda.dy, greaterThan(mapa.bottom));
        } else {
          // En ancho: el mapa al costado de la leyenda.
          expect(leyenda.dx, greaterThan(mapa.right));
          expect(leyenda.dy, lessThan(mapa.bottom));
        }
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('con solo la entrada hay un marcador y una leyenda', (t) async {
      final errores = capturarErrores();
      await montarHex(t, seccion(soloEntrada), overrides: sinRed());
      await esperar(t, 2);

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('Entrada · 07:02 · ±12 m'), findsOneWidget);
      expect(find.textContaining('Salida'), findsNothing);
      expect(find.byIcon(Icons.logout), findsNothing);
      expect(find.byIcon(Icons.login), findsNWidgets(2));
      expect(find.text('Abrir en Google Maps'), findsOneWidget);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('con solo la salida (entrada del biométrico) un marcador', (
      t,
    ) async {
      final soloSalida = HexReporteEntity(
        idReporte: BigInt.from(505),
        fin: DateTime(2026, 10, 23, 22, 5),
        origenFin: 'APP',
        latFin: -16.51,
        lonFin: -68.16,
        precisionFin: 8,
      );
      final errores = capturarErrores();
      await montarHex(t, seccion(soloSalida), overrides: sinRed());
      await esperar(t, 2);

      expect(find.text('Salida · 22:05 · ±8 m'), findsOneWidget);
      expect(find.textContaining('Entrada'), findsNothing);
      expect(find.text('Abrir en Google Maps'), findsOneWidget);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('la hora solo sale si la hora del reporte es la de la app', (
      t,
    ) async {
      // El biométrico ganó: su hora no es la de la marca de la app.
      final r = HexReporteEntity(
        idReporte: BigInt.from(506),
        inicio: DateTime(2026, 10, 23, 7, 2),
        origenInicio: 'BIOMETRICO',
        latInicio: -16.500123,
        lonInicio: -68.150456,
        precisionInicio: 12,
      );
      await montarHex(t, seccion(r), overrides: sinRed());
      await esperar(t, 2);
      expect(find.text('Entrada · ±12 m'), findsOneWidget);
      expect(find.textContaining('07:02'), findsNothing);
      await cerrar(t);
    });

    testWidgets('la hora de la marca por app sale aunque el origen sea el '
        'biométrico', (t) async {
      // D31: el biométrico ganó la hora del reporte, pero la leyenda es de la app.
      final r = HexReporteEntity(
        idReporte: BigInt.from(509),
        inicio: DateTime(2026, 10, 23, 7, 2),
        fin: DateTime(2026, 10, 23, 22),
        origenInicio: 'BIOMETRICO',
        origenFin: 'BIOMETRICO',
        inicioApp: DateTime(2026, 10, 23, 7, 5),
        finApp: DateTime(2026, 10, 23, 22, 10),
        latInicio: -16.500123,
        lonInicio: -68.150456,
        precisionInicio: 12,
        latFin: -16.51,
        lonFin: -68.16,
        precisionFin: 8,
      );
      await montarHex(t, seccion(r), overrides: sinRed());
      await esperar(t, 2);
      expect(find.text('Entrada · 07:05 · ±12 m'), findsOneWidget);
      expect(find.text('Salida · 22:10 · ±8 m'), findsOneWidget);
      expect(find.textContaining('07:02'), findsNothing);
      expect(find.textContaining('22:00'), findsNothing);
      await cerrar(t);
    });

    testWidgets(
      'con solo la hora de la salida por app la entrada va sin hora',
      (t) async {
        final r = HexReporteEntity(
          idReporte: BigInt.from(510),
          inicio: DateTime(2026, 10, 23, 7, 2),
          origenInicio: 'BIOMETRICO',
          finApp: DateTime(2026, 10, 23, 22, 10),
          latInicio: -16.500123,
          lonInicio: -68.150456,
          precisionInicio: 12,
          latFin: -16.51,
          lonFin: -68.16,
          precisionFin: 8,
        );
        await montarHex(t, seccion(r), overrides: sinRed());
        await esperar(t, 2);
        expect(find.text('Entrada · ±12 m'), findsOneWidget);
        expect(find.text('Salida · 22:10 · ±8 m'), findsOneWidget);
        await cerrar(t);
      },
    );

    testWidgets('sin hora ni precisión la leyenda es solo el rótulo', (
      t,
    ) async {
      final r = HexReporteEntity(
        idReporte: BigInt.from(507),
        latInicio: -16.500123,
        lonInicio: -68.150456,
      );
      await montarHex(t, seccion(r), overrides: sinRed());
      await esperar(t, 2);
      expect(find.text('Entrada'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('la precisión se dibuja como círculo en metros', (t) async {
      await montarHex(t, seccion(conAmbas), overrides: sinRed());
      await esperar(t, 2);
      final capa = t.widget<CircleLayer>(find.byType(CircleLayer));
      expect(capa.circles, hasLength(2));
      expect(capa.circles.every((c) => c.useRadiusInMeter), isTrue);
      expect(capa.circles.map((c) => c.radius), [12.0, 8.0]);
      await cerrar(t);
    });

    testWidgets('sin precisión no hay círculo, pero sí marcador', (t) async {
      final r = HexReporteEntity(
        idReporte: BigInt.from(508),
        latInicio: -16.500123,
        lonInicio: -68.150456,
      );
      await montarHex(t, seccion(r), overrides: sinRed());
      await esperar(t, 2);
      expect(t.widget<CircleLayer>(find.byType(CircleLayer)).circles, isEmpty);
      expect(find.byType(MarkerLayer), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('dos puntos casi iguales no rompen el encuadre', (t) async {
      final r = HexReporteEntity(
        idReporte: BigInt.from(509),
        latInicio: -16.500123,
        lonInicio: -68.150456,
        latFin: -16.500123,
        lonFin: -68.150456,
      );
      final errores = capturarErrores();
      await montarHex(t, seccion(r), overrides: sinRed());
      await esperar(t, 2);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('«Abrir en Google Maps» manda el punto de cada marca', (
      t,
    ) async {
      final abridor = _Abridor();
      await montarHex(
        t,
        seccion(conAmbas),
        overrides: sinRed(abridor: abridor),
      );
      await esperar(t, 2);

      final botones = find.text('Abrir en Google Maps');
      await t.ensureVisible(botones.first);
      await t.tap(botones.first);
      await t.pump();
      await t.ensureVisible(botones.last);
      await t.tap(botones.last);
      await t.pump();

      expect(abridor.abiertas.map((u) => u.toString()), [
        'https://www.google.com/maps/search/?api=1&query=-16.500123,-68.150456',
        'https://www.google.com/maps/search/?api=1&query=-16.510000,-68.160000',
      ]);
      expect(find.textContaining('No se pudo abrir'), findsNothing);
      await cerrar(t);
    });

    for (final lanza in [false, true]) {
      testWidgets('si no se puede abrir Google Maps lo avisa'
          '${lanza ? ' (también si falla con una excepción)' : ''}', (t) async {
        final abridor = _Abridor(resultado: false, lanza: lanza);
        await montarHex(
          t,
          seccion(soloEntrada),
          overrides: sinRed(abridor: abridor),
        );
        await esperar(t, 2);

        await t.ensureVisible(find.text('Abrir en Google Maps'));
        await t.tap(find.text('Abrir en Google Maps'));
        await esperar(t, 2);

        expect(abridor.abiertas, hasLength(1));
        expect(
          find.text('No se pudo abrir Google Maps en este dispositivo.'),
          findsOneWidget,
        );
        await t.pump(const Duration(seconds: 8));
        await cerrar(t);
      });
    }

    test('la dirección de Google Maps lleva latitud y longitud con punto', () {
      expect(
        urlGoogleMapsHex(-16.5, -68.15).toString(),
        'https://www.google.com/maps/search/?api=1&query=-16.500000,-68.150000',
      );
    });
  });

  group('el detalle del reporte', () {
    Widget abridor(BigInt id) => Builder(
      builder:
          (c) => Center(
            child: FilledButton(
              onPressed: () => mostrarDetalleReporteHex(c, id),
              child: const Text('Abrir'),
            ),
          ),
    );

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('muestra «Dónde marcó» si el detalle trae ubicación a '
          '$ancho px', (t) async {
        final repo = HexReporteFalso()..programar('detalle', [conAmbas]);
        final errores = capturarErrores();
        await montarHex(
          t,
          abridor(conAmbas.idReporte!),
          ancho: ancho,
          overrides: sinRed(repo: repo),
        );
        await t.tap(find.text('Abrir'));
        await esperar(t);

        expect(find.text('Detalle del reporte'), findsOneWidget);
        expect(find.text('Dónde marcó'), findsOneWidget);
        expect(find.byType(FlutterMap), findsOneWidget);
        expect(find.text('Entrada · 07:02 · ±12 m'), findsOneWidget);
        expect(find.text('Salida · 22:05 · ±8 m'), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('no muestra la sección si el detalle no trae ubicación', (
      t,
    ) async {
      final repo = HexReporteFalso()..programar('detalle', [sinUbicacion]);
      final errores = capturarErrores();
      await montarHex(
        t,
        abridor(sinUbicacion.idReporte!),
        ancho: 390,
        overrides: sinRed(repo: repo),
      );
      await t.tap(find.text('Abrir'));
      await esperar(t);

      expect(find.text('Detalle del reporte'), findsOneWidget);
      expect(find.text('Dónde marcó'), findsNothing);
      expect(find.byType(FlutterMap), findsNothing);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });
  });

  group('la ficha «App · con ubicación»', () {
    Widget tarjeta(HexReporteEntity r) => SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: TarjetaReporteHex(
        r,
        acciones: [AccionHex('Ver detalle', Icons.visibility_outlined, () {})],
      ),
    );

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('al tocarla en la tarjeta abre la hoja «Dónde marcó» a '
          '$ancho px', (t) async {
        final repo = HexReporteFalso()..programar('detalle', [conAmbas]);
        final errores = capturarErrores();
        await montarHex(
          t,
          tarjeta(conAmbas),
          ancho: ancho,
          overrides: sinRed(repo: repo),
        );

        expect(find.byTooltip('Ver dónde marcó'), findsNWidgets(2));
        await t.tap(find.text('App · con ubicación').first);
        await esperar(t);

        expect(repo.vecesDe('detalle'), 1);
        expect(
          repo.argumentosDe('detalle').single['idReporte'],
          conAmbas.idReporte,
        );
        expect(find.text('Dónde marcó'), findsOneWidget);
        expect(find.text('Mamani Quispe Juan Carlos'), findsWidgets);
        expect(find.byType(FlutterMap), findsOneWidget);
        expect(find.text('Entrada · 07:02 · ±12 m'), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('en la tabla también se puede tocar', (t) async {
      final repo = HexReporteFalso()..programar('detalle', [soloEntrada]);
      final errores = capturarErrores();
      await montarHex(
        t,
        Builder(
          builder:
              (c) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 240,
                  child: columnasDatosReporteHex(
                    c,
                  ).first.cellBuilder(soloEntrada),
                ),
              ),
        ),
        overrides: sinRed(repo: repo),
      );
      await t.tap(find.text('App · con ubicación'));
      await esperar(t);

      expect(repo.vecesDe('detalle'), 1);
      expect(find.text('Dónde marcó'), findsOneWidget);
      expect(find.text('Entrada · 07:02 · ±12 m'), findsOneWidget);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('si el reporte ya no tiene ubicación, la hoja lo dice', (
      t,
    ) async {
      final repo = HexReporteFalso()..programar('detalle', [sinUbicacion]);
      await montarHex(
        t,
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: HoraOrigenHex(
            DateTime(2026, 10, 23, 7, 2),
            'APP',
            idReporte: sinUbicacion.idReporte,
          ),
        ),
        ancho: 390,
        overrides: sinRed(repo: repo),
      );
      await t.tap(find.text('App · con ubicación'));
      await esperar(t);

      expect(find.text('Sin ubicación guardada'), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);
      await cerrar(t);
    });

    testWidgets('solo la ficha de la app responde; las demás no', (t) async {
      final repo = HexReporteFalso();
      await montarHex(
        t,
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (final origen in ['HORARIO', 'BIOMETRICO', 'EDITADO', null])
                HoraOrigenHex(
                  DateTime(2026, 10, 23, 7, 2),
                  origen,
                  idReporte: BigInt.from(501),
                ),
            ],
          ),
        ),
        ancho: 390,
        overrides: sinRed(repo: repo),
      );
      expect(find.byTooltip('Ver dónde marcó'), findsNothing);
      await t.tap(find.text('Biométrico'));
      await esperar(t, 2);
      expect(repo.vecesDe('detalle'), 0);
      await cerrar(t);
    });

    testWidgets('sin el id del reporte la ficha de la app no responde', (
      t,
    ) async {
      final repo = HexReporteFalso();
      await montarHex(
        t,
        Center(child: HoraOrigenHex(DateTime(2026, 10, 23, 7, 2), 'APP')),
        ancho: 390,
        overrides: sinRed(repo: repo),
      );
      expect(find.byTooltip('Ver dónde marcó'), findsNothing);
      await t.tap(find.text('App · con ubicación'));
      await esperar(t, 2);
      expect(repo.vecesDe('detalle'), 0);
      await cerrar(t);
    });
  });
}
