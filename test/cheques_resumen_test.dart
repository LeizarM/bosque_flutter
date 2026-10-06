import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/data/models/cheque_fila_model.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/utils/resumen_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/resumen_cheques.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';

/// El resumen sobre la tabla: lo que cuenta (solo la pagina cargada), como lo
/// rotula cuando hay mas de una pagina, que no mezcle monedas, que no parezca un
/// boton y que no desborde.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarRoboto);

  final hoy = DateTime(2026, 10, 3, 16, 20);

  /// Un cheque con la moneda, el estado y la fecha de cobro a elegir.
  ChequeFilaEntity fila(
    int cod, {
    String estado = 'PEN',
    int? cobraEn,
    double? monto = 100,
    String moneda = 'BS',
    String descMoneda = 'Bs',
  }) {
    final base = chequeFalso(cod, estado: estado);
    final json = ChequeFilaModel.fromEntity(base).toJson();
    json['monto'] = monto;
    json['moneda'] = moneda;
    json['descMoneda'] = descMoneda;
    if (cobraEn == null) {
      json['fechaCobrar'] = null;
    } else {
      final f = DateTime(2026, 10, 3 + cobraEn);
      json['fechaCobrar'] =
          '${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';
    }
    return ChequeFilaModel.fromJson(json).toEntity();
  }

  group('resumirPaginaCheques', () {
    test('una pagina vacia no cuenta nada', () {
      final r = resumirPaginaCheques(const [], hoy);
      expect(r.filas, 0);
      expect(r.pendientes, 0);
      expect(r.atrasados, 0);
      expect(r.cobranHoy, 0);
      expect(r.montos, isEmpty);
    });

    test('cuenta pendientes, atrasados y los que cobran hoy', () {
      final r = resumirPaginaCheques([
        fila(1, cobraEn: -12), // atrasado
        fila(2, cobraEn: -1), // atrasado
        fila(3, cobraEn: 0), // cobra hoy
        fila(4, cobraEn: 3), // por cobrar
        fila(5, cobraEn: 40), // vigente
        fila(6, cobraEn: null), // sin fecha: pendiente, sin plazo
        fila(7, estado: 'CER', cobraEn: -30), // cerrado: no cuenta como atrasado
        fila(8, estado: 'CER', cobraEn: 2),
      ], hoy);
      expect(r.filas, 8);
      expect(r.pendientes, 6);
      expect(r.atrasados, 2);
      expect(r.cobranHoy, 1);
    });

    test('un cheque cerrado nunca cuenta como atrasado', () {
      final r = resumirPaginaCheques([fila(1, estado: 'CER', cobraEn: -90)], hoy);
      expect(r.atrasados, 0);
      expect(r.pendientes, 0);
    });

    test('el monto va por moneda y nunca se suman Bs con \$us', () {
      final r = resumirPaginaCheques([
        fila(1, monto: 1000),
        fila(2, monto: 250.5),
        fila(3, monto: 80, moneda: 'SUS', descMoneda: r'$us'),
        fila(4, monto: 20, moneda: 'SUS', descMoneda: r'$us'),
      ], hoy);
      expect(r.montos, {'Bs': 1250.5, r'$us': 100});
      expect(r.montos.length, 2);
    });

    test('Bs va primero y \$us despues aunque lleguen al reves', () {
      final r = resumirPaginaCheques([
        fila(1, monto: 5, moneda: 'SUS', descMoneda: r'$us'),
        fila(2, monto: 7),
      ], hoy);
      expect(r.montos.keys.toList(), ['Bs', r'$us']);
    });

    test('«BS» y «Bs» son la misma moneda', () {
      final r = resumirPaginaCheques([
        fila(1, monto: 10, descMoneda: 'BS'),
        fila(2, monto: 15, descMoneda: 'Bs'),
        fila(3, monto: 5, descMoneda: '', moneda: 'BS'),
      ], hoy);
      expect(r.montos, {'Bs': 30});
    });

    test('un cheque sin monto no suma ni abre una moneda', () {
      final r = resumirPaginaCheques([fila(1, monto: null)], hoy);
      expect(r.montos, isEmpty);
      expect(r.filas, 1);
    });

    test('una moneda desconocida va aparte, al final', () {
      final r = resumirPaginaCheques([
        fila(1, monto: 3, descMoneda: 'EUR', moneda: 'EUR'),
        fila(2, monto: 9, moneda: 'SUS', descMoneda: r'$us'),
        fila(3, monto: 4),
      ], hoy);
      expect(r.montos.keys.toList(), ['Bs', r'$us', 'EUR']);
    });
  });

  group('el widget', () {
    Future<void> montarResumen(
      WidgetTester tester,
      List<ChequeFilaEntity> filas, {
      int? total,
      int paginas = 1,
      double ancho = 1400,
      double? texto,
    }) async {
      if (texto != null) conTexto(tester, texto);
      tester.view.physicalSize = Size(ancho, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ResumenCheques(
                filas: filas,
                total: total ?? filas.length,
                totalPaginas: paginas,
                hoy: hoy,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    final claves = [
      'resumen-total',
      'resumen-pendientes',
      'resumen-atrasados',
      'resumen-monto',
    ];

    testWidgets('una pagina vacia no dibuja nada', (tester) async {
      await montarResumen(tester, const []);
      expect(find.byKey(const ValueKey('resumen-cheques')), findsNothing);
      for (final c in claves) {
        expect(find.byKey(ValueKey(c)), findsNothing);
      }
    });

    testWidgets('con una sola pagina rotula lo que es y no dice «en esta página»', (
      tester,
    ) async {
      await montarResumen(tester, [
        fila(1, cobraEn: -3),
        fila(2, cobraEn: 0),
        fila(3, estado: 'CER'),
      ]);
      for (final c in claves) {
        expect(find.byKey(ValueKey(c)), findsOneWidget, reason: c);
      }
      expect(find.text('Cheques'), findsOneWidget);
      expect(find.text('Pendientes'), findsOneWidget);
      expect(find.text('Cobro atrasado'), findsOneWidget);
      expect(find.text('Monto'), findsOneWidget);
      expect(find.text('en esta página'), findsNothing);
      expect(find.text('1 cobra hoy'), findsOneWidget);
    });

    testWidgets('con varias paginas rotula «en esta página» donde no es el total', (
      tester,
    ) async {
      await montarResumen(
        tester,
        [for (var i = 1; i <= 20; i++) fila(i, cobraEn: i.isEven ? -2 : 5)],
        total: 135,
        paginas: 7,
      );
      // El total es el del servidor, sin la leyenda de pagina...
      final total = find.byKey(const ValueKey('resumen-total'));
      expect(find.descendant(of: total, matching: find.text('135')), findsOneWidget);
      expect(find.descendant(of: total, matching: find.text('en total')), findsOneWidget);
      expect(
        find.descendant(of: total, matching: find.text('en esta página')),
        findsNothing,
      );
      // ... y los otros tres si la llevan: son de las 20 filas cargadas.
      for (final c in ['resumen-pendientes', 'resumen-atrasados', 'resumen-monto']) {
        expect(
          find.descendant(
            of: find.byKey(ValueKey(c)),
            matching: find.text('en esta página'),
          ),
          findsOneWidget,
          reason: c,
        );
      }
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('resumen-atrasados')),
          matching: find.text('10'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('cero atrasados se dice, y no es una alarma', (tester) async {
      await montarResumen(tester, [fila(1, cobraEn: 4)]);
      final tarjeta = find.byKey(const ValueKey('resumen-atrasados'));
      expect(find.descendant(of: tarjeta, matching: find.text('0')), findsOneWidget);
      expect(find.descendant(of: tarjeta, matching: find.text('ninguno')), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('atrasados se dicen con icono de advertencia y con la cifra', (
      tester,
    ) async {
      await montarResumen(tester, [fila(1, cobraEn: -2), fila(2, cobraEn: -9)]);
      final tarjeta = find.byKey(const ValueKey('resumen-atrasados'));
      expect(find.descendant(of: tarjeta, matching: find.text('2')), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('el monto muestra una linea por moneda, sin sumarlas', (
      tester,
    ) async {
      await montarResumen(tester, [
        fila(1, monto: 12000),
        fila(2, monto: 500, moneda: 'SUS', descMoneda: r'$us'),
      ]);
      final monto = find.byKey(const ValueKey('resumen-monto'));
      expect(find.descendant(of: monto, matching: find.text('12,000.00')), findsOneWidget);
      expect(find.descendant(of: monto, matching: find.text('500.00')), findsOneWidget);
      expect(find.descendant(of: monto, matching: find.text('12,500.00')), findsNothing);
      expect(find.descendant(of: monto, matching: find.text('Bs')), findsOneWidget);
      expect(find.descendant(of: monto, matching: find.text(r'$us')), findsOneWidget);
    });

    testWidgets('no es interactivo: sin botones, sin tinta, sin gestos', (
      tester,
    ) async {
      await montarResumen(tester, [fila(1, cobraEn: -1)]);
      final resumen = find.byKey(const ValueKey('resumen-cheques'));
      expect(find.descendant(of: resumen, matching: find.byType(InkWell)), findsNothing);
      expect(find.descendant(of: resumen, matching: find.byType(GestureDetector)), findsNothing);
      expect(find.descendant(of: resumen, matching: find.byType(ButtonStyleButton)), findsNothing);
      expect(find.descendant(of: resumen, matching: find.byType(IconButton)), findsNothing);
      expect(find.descendant(of: resumen, matching: find.byIcon(Icons.chevron_right)), findsNothing);
    });

    testWidgets('en escritorio van los cuatro en una fila; en movil, de a dos', (
      tester,
    ) async {
      final filas = [fila(1, cobraEn: -1), fila(2)];
      await montarResumen(tester, filas, ancho: 1400);
      var tops = [for (final c in claves) tester.getTopLeft(find.byKey(ValueKey(c))).dy];
      expect(tops.toSet().length, 1, reason: 'una sola fila a 1400: $tops');

      await montarResumen(tester, filas, ancho: 390);
      tops = [for (final c in claves) tester.getTopLeft(find.byKey(ValueKey(c))).dy];
      expect(tops.toSet().length, 2, reason: 'dos filas a 390: $tops');
      expect(tops[0], tops[1]);
      expect(tops[2], tops[3]);
    });

    testWidgets('los recuadros de una fila miden lo mismo', (tester) async {
      await montarResumen(tester, [
        fila(1, cobraEn: 0),
        fila(2, monto: 5, moneda: 'SUS', descMoneda: r'$us'),
      ]);
      final alturas = {
        for (final c in claves) tester.getSize(find.byKey(ValueKey(c))).height,
      };
      expect(alturas.length, 1, reason: 'alturas distintas: $alturas');
    });

    for (final ancho in [390.0, 768.0, 1280.0, 1800.0]) {
      for (final escala in [1.0, 1.5]) {
        testWidgets(
          'no desborda a ${ancho.toInt()} px con texto al ${(escala * 100).toInt()} %',
          (tester) async {
            final errores = await capturandoErrores(() async {
              await montarResumen(
                tester,
                [
                  fila(1, cobraEn: -12, monto: 12345678.9),
                  fila(2, cobraEn: 0, monto: 98765432.1, moneda: 'SUS', descMoneda: r'$us'),
                  fila(3, estado: 'CER'),
                ],
                total: 7066,
                paginas: 354,
                ancho: ancho,
                texto: escala == 1.0 ? null : escala,
              );
            });
            expect(errores, isEmpty);
            // Nunca mas ancho que la pantalla: sin scroll horizontal.
            final r = tester.getRect(find.byKey(const ValueKey('resumen-cheques')));
            expect(r.right, lessThanOrEqualTo(ancho));
          },
        );
      }
    }
  });
}
