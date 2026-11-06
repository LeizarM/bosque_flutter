import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/entities/hex_tramo_mapa_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_mapa_tramos.dart';

import 'fakes/arnes_hex.dart';
import 'fakes/repositorio_hex.dart';

/// El mapa del día de los tramos: una barra por tipo de día, los huecos y
/// cruces con el texto del SP, la leyenda y que entre en un diálogo.
void main() {
  setUpAll(cargarFuentesHex);

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  Future<void> montar(WidgetTester t, Widget hijo, {double ancho = 1000}) =>
      montarHex(
        t,
        SingleChildScrollView(padding: const EdgeInsets.all(16), child: hijo),
        ancho: ancho,
      );

  const cruce = HexTramoMapaEntity(
    tipoDia: 'DOMINGO',
    textoTipoDia: 'Domingos',
    orden: 2,
    desdeMin: 1080,
    hastaMin: 1200,
    horaDesde: '18:00',
    horaHasta: '20:00',
    clase: 'CRUCE',
    codigo: 'HD y HX',
    texto: 'De 18:00 a 20:00 pagan «HD» y «HX» a la vez: acorta uno.',
  );

  for (final ancho in [320.0, 360.0, 1000.0]) {
    testWidgets('a $ancho px: una barra por día y el texto del hueco', (
      t,
    ) async {
      final errores = capturarErrores();
      await montar(t, MapaTramosHex(mapaTramosFalso), ancho: ancho);
      await esperar(t, 2);
      expect(find.byType(BarraDiaHex), findsNWidgets(3));
      expect(find.text('Días hábiles'), findsOneWidget);
      expect(find.text('Domingos'), findsOneWidget);
      expect(find.text('Feriados'), findsOneWidget);
      expect(find.text(textoHuecoFalso), findsOneWidget);
      // Cada comida va una vez en la leyenda, con el texto del SP.
      expect(
        find.text('C $textoCenaFalso', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('en «Comidas»'), findsOneWidget);
      // La leyenda nombra cada código con su factor, una vez.
      expect(
        find.text(
          'H50 Hora extra con recargo del 50 % · ×1,5',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text('Sin tramo o con dos tramos'), findsOneWidget);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });
  }

  testWidgets('el lector de pantalla oye el hueco de cada día', (t) async {
    final semantica = t.ensureSemantics();
    await montar(t, MapaTramosHex(mapaTramosFalso));
    await esperar(t, 2);
    expect(
      find.bySemanticsLabel(RegExp('20:00 a 20:01: sin tramo')),
      findsOneWidget,
    );
    semantica.dispose();
    await cerrar(t);
  });

  testWidgets('bajo cada barra, la franja «Comidas» con sus ventanas', (
    t,
  ) async {
    final semantica = t.ensureSemantics();
    await montar(t, MapaTramosHex(mapaTramosFalso));
    await esperar(t, 2);
    expect(
      find.bySemanticsLabel(
        RegExp(r'Comidas: D 06:00 a 07:00; A 12:00 a 12:30; C 18:00 a 20:00$'),
      ),
      findsNWidgets(3),
    );
    // Las comidas no se leen como piezas de la barra de tramos.
    expect(find.bySemanticsLabel(RegExp(r'18:00 a 20:00: C')), findsNothing);
    semantica.dispose();
    await cerrar(t);
  });

  testWidgets('sin comidas no hay franja ni frase que la explique', (t) async {
    final semantica = t.ensureSemantics();
    final soloTramos = [
      for (final m in mapaTramosFalso)
        if (!m.esComida) m,
    ];
    await montar(t, MapaTramosHex(soloTramos));
    await esperar(t, 2);
    final sinComidas = t.getSize(find.byType(BarraDiaHex).first).height;
    expect(find.bySemanticsLabel(RegExp('Comidas')), findsNothing);
    expect(find.textContaining('en «Comidas»'), findsNothing);
    await montar(t, MapaTramosHex(mapaTramosFalso));
    await esperar(t, 2);
    final conComidas = t.getSize(find.byType(BarraDiaHex).first).height;
    expect(conComidas, greaterThan(sinComidas));
    semantica.dispose();
    await cerrar(t);
  });

  testWidgets('los problemas solo muestran huecos y cruces', (t) async {
    final errores = capturarErrores();
    final habil = [
      for (final m in mapaTramosPropuestoFalso)
        if (m.tipoDia == 'HABIL') m,
    ];
    await montar(t, ProblemasMapaHex(habil));
    await esperar(t, 1);
    // La propuesta no deja hueco y la cena trae texto: no es un problema.
    expect(find.text(textoCenaFalso), findsNothing);
    expect(find.byIcon(Icons.report_problem_outlined), findsNothing);
    await montar(t, MapaTramosHex(mapaTramosFalso));
    await esperar(t, 2);
    expect(find.text(textoCenaFalso), findsNothing);
    expect(find.byIcon(Icons.report_problem_outlined), findsOneWidget);
    expect(errores, isEmpty, reason: detalle(errores));
    await cerrar(t);
  });

  testWidgets('un cruce va en rojo con su texto', (t) async {
    final errores = capturarErrores();
    await montar(
      t,
      MapaTramosHex([
        ...mapaTramosFalso.where((m) => m.tipoDia == 'DOMINGO'),
        cruce,
      ]),
    );
    await esperar(t, 2);
    expect(find.byType(BarraDiaHex), findsOneWidget);
    expect(find.text(cruce.texto!), findsOneWidget);
    expect(errores, isEmpty, reason: detalle(errores));
    await cerrar(t);
  });

  testWidgets('sin filas no dibuja nada', (t) async {
    await montar(t, const MapaTramosHex([]));
    expect(find.byType(BarraDiaHex), findsNothing);
    await cerrar(t);
  });

  testWidgets('la barra entra en un diálogo (sin LayoutBuilder)', (t) async {
    final errores = capturarErrores();
    final habil = mapaTramosFalso.where((m) => m.tipoDia == 'HABIL').toList();
    await montarHex(
      t,
      Builder(
        builder:
            (context) => TextButton(
              onPressed:
                  () => showDialog<void>(
                    context: context,
                    builder:
                        (_) => AlertDialog(
                          scrollable: true,
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              BarraDiaHex(
                                habil,
                                tonos: tonosMapaHex(habil),
                                alto: 28,
                              ),
                              ProblemasMapaHex(habil),
                            ],
                          ),
                        ),
                  ),
              child: const Text('Abrir'),
            ),
      ),
      ancho: 390,
    );
    await t.tap(find.text('Abrir'));
    await esperar(t, 2);
    expect(find.byType(BarraDiaHex), findsOneWidget);
    expect(find.text(textoHuecoFalso), findsOneWidget);
    expect(errores, isEmpty, reason: detalle(errores));
    await cerrar(t);
  });

  test('cada código conserva su tono entre barras', () {
    final tonos = tonosMapaHex([
      ...mapaTramosFalso,
      ...mapaTramosPropuestoFalso,
    ]);
    expect(tonos.keys, ['H100', 'HS', 'H50', 'HD', 'HF']);
    expect(tonos['H50'], 2);
  });
}
