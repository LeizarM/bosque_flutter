import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/data/models/cheque_fila_model.dart';
import 'package:bosque_flutter/domain/entities/accion_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/presentation/screens/cheques/cheques_screen.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_visuales_cheques.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';

/// El aspecto del modulo de cheques: que lo importante resalte (franja, estado,
/// plazo de cobro, moneda, tipo, banco), que cada resaltado lleve texto o icono y
/// no solo color, que la tipografia sea la del modulo tambien en los dialogos, y
/// que nada desborde de 390 a 1800 px ni con el texto al 150 %.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarRoboto);

  late RepositorioChequesFalso repo;
  setUp(() => repo = RepositorioChequesFalso());

  Widget pantalla() => appCheques(hijo: const ChequesScreen(), repo: repo);

  /// Un cheque con la fecha de cobro a [cobraEn] dias de «hoy» del reloj de las
  /// pruebas (3/10/2026), la moneda y el empleado a elegir.
  ChequeFilaEntity cheque(
    int cod, {
    String estado = 'PEN',
    int? cobraEn,
    String cliente = 'EDITORA MENDEZ',
    String banco = 'BANCO UNION',
    String? descTipo = 'PAGO',
    String tipo = 'PAG',
    bool dolares = false,
    String? empleado,
    double monto = 1500.5,
    String aOrdenDe = 'BOSQUE S.A.',
  }) {
    final base = chequeFalso(
      cod,
      estado: estado,
      cliente: cliente,
      banco: banco,
      descTipo: descTipo,
      tipo: tipo,
      monto: monto,
      aOrdenDe: aOrdenDe,
      codEmpleado: empleado == null ? 0 : 12,
      datoEmpleado:
          empleado == null ? ' - Entregado por el Cliente -' : ' - $empleado -',
    );
    final json = ChequeFilaModel.fromEntity(base).toJson();
    if (cobraEn == null) {
      json['fechaCobrar'] = null;
    } else {
      final f = DateTime(2026, 10, 3 + cobraEn);
      json['fechaCobrar'] =
          '${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';
    }
    if (dolares) {
      json['moneda'] = 'SUS';
      json['descMoneda'] = r'$us';
    }
    return ChequeFilaModel.fromJson(json).toEntity();
  }

  /// Un cheque de cada situacion de cobro y los casos que estiran el diseno.
  List<ChequeFilaEntity> variados() => [
    cheque(14, cobraEn: -12, banco: 'BANCO UNION'),
    cheque(
      13,
      cobraEn: 0,
      banco: 'BANCO MERCANTIL SANTA CRUZ',
      empleado: 'Rolando Quispe Mamani',
    ),
    cheque(12, cobraEn: 3, banco: 'BANCO NACIONAL DE BOLIVIA', dolares: true),
    cheque(11, cobraEn: 25, banco: 'BANCO UNION'),
    cheque(10, estado: 'CER', cobraEn: -10),
    cheque(9, cobraEn: null),
    cheque(8, cobraEn: -40, dolares: true, descTipo: 'RESPALDO', tipo: 'RES'),
    cheque(7, cobraEn: 1),
    cheque(
      6,
      cobraEn: -1,
      cliente: 'CLIENTE CON UN NOMBRE MUY LARGO S.R.L. SUCURSAL NORTE - CHIQUITOS',
      banco: 'Banco Mercantil Santa Cruz - Cuenta corriente 1234567890',
      aOrdenDe: 'BOSQUE INDUSTRIAL DE PAPELES Y AFINES SA',
      empleado: 'Juan Carlos Perez de la Fuente Rodriguez',
      monto: 12345678.9,
    ),
  ];

  Finder fila(int cod) => find.byKey(ValueKey('fila-$cod'));

  Color colorDe(WidgetTester tester, Finder pastilla) {
    final caja = tester.widget<DecoratedBox>(
      find.descendant(of: pastilla, matching: find.byType(DecoratedBox)).first,
    );
    return (caja.decoration as BoxDecoration).color!;
  }

  BuildContext contextoDe(WidgetTester tester, Finder f) => tester.element(f);

  /// El fondo de la fila: el del primer `Container` de la fila (el de las celdas).
  Color fondoDeFila(WidgetTester tester, int cod) {
    final c = tester.widget<Container>(
      find.descendant(of: fila(cod), matching: find.byType(Container)).first,
    );
    return c.color ?? (c.decoration as BoxDecoration).color!;
  }

  /// El detalle del repositorio falso, pero del [cheque] dado.
  void detalleDe(ChequeFilaEntity cheque) {
    final porDefecto = RepositorioChequesFalso();
    repo.alObtenerDetalle = (cod) async {
      final d = (await porDefecto.obtenerDetalle(cod))!;
      return ChequeDetalleEntity(
        cheque: cheque,
        acciones: d.acciones,
        botones: d.botones,
      );
    };
  }

  // ── Sin desbordes, con el diseno nuevo y datos que lo estiran ─────────────

  final anchos = [390.0, 600.0, 700.0, 768.0, 800.0, 900.0, 1000.0, 1280.0, 1400.0, 1800.0];
  for (final escala in [1.0, 1.5]) {
    for (final ancho in anchos) {
      testWidgets(
        'no desborda a ${ancho.toInt()} px con texto al ${(escala * 100).toInt()} %',
        (tester) async {
          repo.cheques = variados();
          if (escala != 1.0) conTexto(tester, escala);

          final errores = await capturandoErrores(() async {
            await montar(tester, pantalla(), ancho: ancho);
          });

          expect(errores, isEmpty, reason: 'a $ancho');
          expect(
            find.byKey(
              ValueKey(ancho >= 720 ? 'lista-tabla' : 'lista-tarjetas'),
            ),
            findsOneWidget,
          );
          expect(find.byKey(const ValueKey('resumen-cheques')), findsOneWidget);
          // Ningun scroll horizontal en movil.
          if (ancho < 720) {
            expect(
              find.byWidgetPredicate(
                (w) =>
                    w is SingleChildScrollView &&
                    w.scrollDirection == Axis.horizontal,
              ),
              findsNothing,
            );
          }
        },
      );
    }
  }

  // ── La tabla ──────────────────────────────────────────────────────────────

  group('tabla', () {
    testWidgets('cada fila lleva una franja del color de su situacion', (
      tester,
    ) async {
      repo.cheques = variados();
      await montar(tester, pantalla(), ancho: 1800);

      Color franja(int cod) =>
          tester
              .widget<FranjaCheque>(
                find.descendant(of: fila(cod), matching: find.byType(FranjaCheque)),
              )
              .color;
      final ctx = contextoDe(tester, fila(14));
      final cs = Theme.of(ctx).colorScheme;

      expect(franja(14), ChequesColores.pleno(ctx, SemanticaCheque.peligro)); // atrasado
      expect(franja(13), ChequesColores.pleno(ctx, SemanticaCheque.aviso)); // hoy
      expect(franja(12), ChequesColores.pleno(ctx, SemanticaCheque.info)); // en 3 d
      expect(franja(7), ChequesColores.pleno(ctx, SemanticaCheque.info)); // en 1 d
      expect(franja(10), ChequesColores.pleno(ctx, SemanticaCheque.exito)); // cerrado
      // Lo comun no se pinta: vigente y sin fecha, con el trazo tenue.
      expect(franja(11), cs.outlineVariant);
      expect(franja(9), cs.outlineVariant);

      for (final cod in [14, 13, 12, 11, 10, 9, 8, 7, 6]) {
        expect(
          tester.getSize(find.descendant(of: fila(cod), matching: find.byType(FranjaCheque))).width,
          4,
          reason: 'la franja de la fila $cod mide 4 px',
        );
      }
    });

    testWidgets('F. cobro: la fecha y debajo el plazo, con texto y no solo color', (
      tester,
    ) async {
      repo.cheques = variados();
      await montar(tester, pantalla(), ancho: 1800);

      Finder en(int cod, String t) =>
          find.descendant(of: fila(cod), matching: find.text(t));

      expect(en(14, 'Atrasado 12 d'), findsOneWidget);
      expect(en(13, 'Cobra hoy'), findsOneWidget);
      expect(en(12, 'En 3 d'), findsOneWidget);
      expect(en(7, 'En 1 d'), findsOneWidget);
      expect(en(11, 'En 25 d'), findsOneWidget);
      expect(en(6, 'Atrasado 1 d'), findsOneWidget);
      // Un cerrado no lleva plazo: el estado ya lo dice.
      expect(
        find.descendant(
          of: fila(10),
          matching: find.byWidgetPredicate(
            (w) => w is Text && (w.data ?? '').startsWith('Atrasado'),
          ),
        ),
        findsNothing,
      );
      expect(find.descendant(of: fila(10), matching: find.byType(TextoSituacionCheque)), findsOneWidget);
      // Sin fecha: un guion y nada debajo.
      expect(
        find.descendant(
          of: fila(9),
          matching: find.byWidgetPredicate(
            (w) => w is Text && ((w.data ?? '').startsWith('En ') || (w.data ?? '').startsWith('Atrasado')),
          ),
        ),
        findsNothing,
      );
      // Y nunca la palabra «vencido»: en este modulo VEN es una postergacion.
      expect(find.textContaining('encid'), findsNothing);

      // Lo urgente lleva icono ademas de color.
      expect(
        find.descendant(of: fila(14), matching: find.byIcon(Icons.warning_amber_rounded)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: fila(13), matching: find.byIcon(Icons.today_outlined)),
        findsOneWidget,
      );
    });

    testWidgets('el estado: PENDIENTE en aviso con punto, CERRADO en exito con check', (
      tester,
    ) async {
      repo.cheques = variados();
      await montar(tester, pantalla(), ancho: 1800);

      final pendiente = find.descendant(
        of: fila(14),
        matching: find.ancestor(
          of: find.text('PENDIENTE'),
          matching: find.byType(PastillaCheque),
        ),
      );
      final cerrado = find.descendant(
        of: fila(10),
        matching: find.ancestor(
          of: find.text('CERRADO'),
          matching: find.byType(PastillaCheque),
        ),
      );
      final ctx = contextoDe(tester, fila(14));

      expect(colorDe(tester, pendiente), ChequesColores.fondo(ctx, SemanticaCheque.aviso));
      expect(colorDe(tester, cerrado), ChequesColores.fondo(ctx, SemanticaCheque.exito));
      // Ya no es una pastilla gris.
      expect(
        colorDe(tester, cerrado),
        isNot(Theme.of(ctx).colorScheme.surfaceContainerHighest),
      );
      expect(tester.widget<PastillaCheque>(pendiente).punto, isTrue);
      expect(tester.widget<PastillaCheque>(cerrado).icono, Icons.check_circle_rounded);
      expect(find.descendant(of: cerrado, matching: find.byIcon(Icons.check_circle_rounded)), findsOneWidget);
    });

    testWidgets('el monto: cifra en mono, negrita, y la moneda en una pastilla', (
      tester,
    ) async {
      repo.cheques = variados();
      await montar(tester, pantalla(), ancho: 1800);

      final cifra = tester.widget<Text>(
        find.descendant(of: fila(14), matching: find.text('1,500.50')),
      );
      expect(cifra.style?.fontFamily, ChequesTema.fuenteCifras);
      expect(cifra.style?.fontWeight, FontWeight.w700);

      final bs = find.descendant(of: fila(14), matching: find.byType(PastillaMonedaCheque));
      final us = find.descendant(of: fila(12), matching: find.byType(PastillaMonedaCheque));
      expect(find.descendant(of: bs, matching: find.text('Bs')), findsOneWidget);
      expect(find.descendant(of: us, matching: find.text(r'$us')), findsOneWidget);
      final cs = Theme.of(contextoDe(tester, fila(14))).colorScheme;
      expect(colorDe(tester, bs), cs.primaryContainer);
      expect(colorDe(tester, us), cs.tertiaryContainer);
      expect(colorDe(tester, bs), isNot(colorDe(tester, us)));

      // El monto va a la derecha de su columna.
      final celda = tester.getRect(find.descendant(of: fila(14), matching: find.byType(ImporteCheque)));
      final cabecera = tester.getRect(
        find.descendant(
          of: find.byKey(const ValueKey('lista-tabla')),
          matching: find.text('Monto'),
        ),
      );
      expect(celda.right, closeTo(cabecera.right, 1.5));
    });

    testWidgets('el banco lleva su monograma, con un color estable por nombre', (
      tester,
    ) async {
      repo.cheques = variados();
      await montar(tester, pantalla(), ancho: 1800);

      expect(find.descendant(of: fila(14), matching: find.text('UN')), findsOneWidget);
      expect(find.descendant(of: fila(13), matching: find.text('MS')), findsOneWidget);
      expect(find.descendant(of: fila(12), matching: find.text('NB')), findsOneWidget);

      // Dos cheques del mismo banco, el mismo color.
      final union14 = colorDe(tester, find.descendant(of: fila(14), matching: find.byType(MonogramaBanco)));
      final union11 = colorDe(tester, find.descendant(of: fila(11), matching: find.byType(MonogramaBanco)));
      expect(union14, union11);
      // Y el nombre sigue ahi: el monograma no lo reemplaza.
      expect(find.descendant(of: fila(14), matching: find.text('BANCO UNION')), findsOneWidget);
    });

    testWidgets('el tipo: PAGO callado, RESPALDO resaltado como excepcion', (
      tester,
    ) async {
      repo.cheques = variados();
      await montar(tester, pantalla(), ancho: 1800);

      final respaldo = find.ancestor(
        of: find.text('RESPALDO'),
        matching: find.byType(PastillaCheque),
      );
      expect(respaldo, findsOneWidget);
      expect(
        colorDe(tester, respaldo),
        ChequesColores.fondo(contextoDe(tester, fila(8)), SemanticaCheque.info),
      );
      expect(tester.widget<PastillaCheque>(respaldo).icono, Icons.shield_outlined);

      // PAGO es texto a secas: ninguna pastilla lo envuelve.
      expect(
        find.ancestor(of: find.text('PAGO').first, matching: find.byType(PastillaCheque)),
        findsNothing,
      );
    });

    testWidgets('entregado por: el cliente atenuado, un empleado normal, cada uno con su icono', (
      tester,
    ) async {
      repo.cheques = variados();
      await montar(tester, pantalla(), ancho: 1800);

      expect(find.descendant(of: fila(14), matching: find.byIcon(Icons.person_outline)), findsOneWidget);
      expect(find.descendant(of: fila(14), matching: find.byIcon(Icons.badge_outlined)), findsNothing);
      expect(find.descendant(of: fila(13), matching: find.byIcon(Icons.badge_outlined)), findsOneWidget);
      expect(find.descendant(of: fila(13), matching: find.byIcon(Icons.person_outline)), findsNothing);

      final cs = Theme.of(contextoDe(tester, fila(14))).colorScheme;
      final cliente = tester.widget<Text>(
        find.descendant(of: fila(14), matching: find.text('Entregado por el Cliente')),
      );
      final empleado = tester.widget<Text>(
        find.descendant(of: fila(13), matching: find.text('Rolando Quispe Mamani')),
      );
      expect(cliente.style?.color, cs.onSurfaceVariant);
      expect(empleado.style?.color, isNot(cs.onSurfaceVariant));
    });

    testWidgets('la cabecera de la tabla lleva el tinte del color principal', (
      tester,
    ) async {
      repo.cheques = variados();
      await montar(tester, pantalla(), ancho: 1800);
      final cs = Theme.of(contextoDe(tester, fila(14))).colorScheme;

      final titulo = find.descendant(
        of: find.byKey(const ValueKey('lista-tabla')),
        matching: find.text('Cliente'),
      );
      final cabecera = tester.widget<DecoratedBox>(
        find.ancestor(of: titulo, matching: find.byType(DecoratedBox)).first,
      );
      final color = (cabecera.decoration as BoxDecoration).color!;
      expect(color, Color.alphaBlend(cs.primary.withValues(alpha: 0.10), cs.surfaceContainerLow));
      expect(color, isNot(cs.surfaceContainerLow));
    });

    testWidgets('con el mouse encima la fila se resalta y sus iconos se tinen del primario', (
      tester,
    ) async {
      repo.cheques = [cheque(2, cobraEn: 3), cheque(1, cobraEn: 4)];
      await montar(tester, pantalla(), ancho: 1400);
      final cs = Theme.of(contextoDe(tester, fila(2))).colorScheme;

      Color? icono(int cod) =>
          tester
              .widget<IconButton>(
                find.descendant(
                  of: fila(cod),
                  matching: find.widgetWithIcon(IconButton, Icons.fact_check_outlined),
                ),
              )
              .style
              ?.foregroundColor
              ?.resolve({});

      Color fondoDe(int cod) => fondoDeFila(tester, cod);

      expect(icono(2), cs.onSurfaceVariant);
      final reposo = fondoDe(2);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(fila(2)));
      await tester.pump();

      expect(icono(2), cs.primary);
      expect(fondoDe(2), isNot(reposo));
      // La otra fila no se entera.
      expect(icono(1), cs.onSurfaceVariant);

      await mouse.moveTo(const Offset(2, 2));
      await tester.pump();
      expect(icono(2), cs.onSurfaceVariant);
      expect(fondoDe(2), reposo);
    });

    testWidgets('las filas pares e impares difieren apenas (cebrado muy tenue)', (
      tester,
    ) async {
      repo.cheques = [cheque(3), cheque(2), cheque(1)];
      await montar(tester, pantalla(), ancho: 1400);
      Color fondoDe(int cod) => fondoDeFila(tester, cod);
      // La pagina ordena por recepcion desc: 3, 2, 1.
      expect(fondoDe(3), fondoDe(1));
      expect(fondoDe(2), isNot(fondoDe(3)));
      expect(
        ChequesColores.contraste(fondoDe(2), fondoDe(3)),
        lessThan(1.1),
        reason: 'el cebrado no puede notarse como una franja',
      );
    });
  });

  // ── Las tarjetas (movil) ──────────────────────────────────────────────────

  group('tarjetas', () {
    testWidgets('cada tarjeta lleva franja, monograma, importe y plazo', (
      tester,
    ) async {
      repo.cheques = variados();
      await montar(tester, pantalla(), ancho: 390);

      for (final cod in [14, 13, 12]) {
        await tester.ensureVisible(fila(cod));
        await tester.pump();
        expect(
          find.descendant(of: fila(cod), matching: find.byType(FranjaCheque)),
          findsOneWidget,
          reason: 'franja de la tarjeta $cod',
        );
        expect(
          find.descendant(of: fila(cod), matching: find.byType(MonogramaBanco)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: fila(cod), matching: find.byType(ImporteCheque)),
          findsOneWidget,
        );
      }

      final ctx = contextoDe(tester, fila(14));
      expect(
        tester
            .widget<FranjaCheque>(find.descendant(of: fila(14), matching: find.byType(FranjaCheque)))
            .color,
        ChequesColores.pleno(ctx, SemanticaCheque.peligro),
      );

      // El plazo es una pastilla en la cabecera, una sola vez.
      expect(find.descendant(of: fila(14), matching: find.text('Atrasado 12 d')), findsOneWidget);
      await tester.ensureVisible(fila(13));
      expect(find.descendant(of: fila(13), matching: find.text('Cobra hoy')), findsOneWidget);
      // Lo urgente va lleno; lo que se acerca, suave.
      final atrasado = find.descendant(
        of: fila(14),
        matching: find.ancestor(
          of: find.text('Atrasado 12 d'),
          matching: find.byType(PastillaCheque),
        ),
      );
      expect(tester.widget<PastillaCheque>(atrasado).fuerte, isTrue);
      await tester.ensureVisible(fila(12));
      final porCobrar = find.descendant(
        of: fila(12),
        matching: find.ancestor(
          of: find.text('En 3 d'),
          matching: find.byType(PastillaCheque),
        ),
      );
      expect(tester.widget<PastillaCheque>(porCobrar).fuerte, isFalse);
    });

    testWidgets('no pierde ningun dato de la tarjeta', (tester) async {
      repo.cheques = [
        cheque(1, cobraEn: -2, empleado: 'Marisol Choque Flores', descTipo: 'RESPALDO', tipo: 'RES'),
      ];
      await montar(tester, pantalla(), ancho: 390);
      final tarjeta = fila(1);

      for (final t in [
        'EDITORA MENDEZ',
        'BANCO UNION',
        'Cheque 100001',
        '1,500.50',
        'A la orden de',
        'BOSQUE S.A.',
        'Recepción',
        'Fecha cheque',
        'Fecha cobro',
        'Tipo',
        'RESPALDO',
        'Entregado por',
        'Marisol Choque Flores',
        'PENDIENTE',
        'Atrasado 2 d',
      ]) {
        expect(
          find.descendant(of: tarjeta, matching: find.text(t)),
          findsOneWidget,
          reason: t,
        );
      }
      expect(find.descendant(of: tarjeta, matching: find.byTooltip('Acciones')), findsOneWidget);
    });

    testWidgets('el importe de la tarjeta es grande y en mono', (tester) async {
      repo.cheques = [cheque(1)];
      await montar(tester, pantalla(), ancho: 390);
      final cifra = tester.widget<Text>(
        find.descendant(of: fila(1), matching: find.text('1,500.50')),
      );
      expect(cifra.style?.fontFamily, ChequesTema.fuenteCifras);
      expect(cifra.style?.fontSize, 22);
    });
  });

  // ── Cabecera, filtros y rango ─────────────────────────────────────────────

  group('cabecera y filtros', () {
    testWidgets('la cabecera lleva una insignia con el icono del modulo', (
      tester,
    ) async {
      repo.cheques = variados();
      await montar(tester, pantalla(), ancho: 1400);
      final cs = Theme.of(contextoDe(tester, find.text('Cheques').first)).colorScheme;

      // El primero es el de la cabecera; el segundo, el del recuadro «Monto».
      final icono = find.byIcon(Icons.payments_outlined).first;
      expect(find.byIcon(Icons.payments_outlined), findsNWidgets(2));
      final circulo = tester.widget<DecoratedBox>(
        find.ancestor(of: icono, matching: find.byType(DecoratedBox)).first,
      );
      final deco = circulo.decoration as BoxDecoration;
      expect(deco.shape, BoxShape.circle);
      expect(deco.color, cs.primaryContainer);
      expect(find.text('Cheques recibidos de los clientes'), findsOneWidget);
    });

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('los filtros llevan el rotulo «Filtros» a ${ancho.toInt()} px', (
        tester,
      ) async {
        repo.cheques = variados();
        await montar(tester, pantalla(), ancho: ancho);
        expect(find.text('Filtros'), findsOneWidget);
        // Con el rango por defecto no hay filtros del usuario que contar.
        expect(find.byKey(const ValueKey('filtros-activos')), findsNothing);
      });
    }

    testWidgets('el contador de filtros activos solo informa y sigue lo aplicado', (
      tester,
    ) async {
      repo.cheques = variados();
      await montar(tester, pantalla(), ancho: 1400);

      await tester.enterText(find.byKey(const ValueKey('filtro-nro')), '1000');
      await tester.tap(find.text('Buscar'));
      await esperar(tester);

      final contador = find.byKey(const ValueKey('filtros-activos'));
      expect(contador, findsOneWidget);
      expect(find.descendant(of: contador, matching: find.text('1 filtro activo')), findsOneWidget);
      // No es un boton: tocarlo no hace nada.
      expect(find.ancestor(of: contador, matching: find.byType(InkWell)), findsNothing);

      await tester.enterText(find.byKey(const ValueKey('filtro-cliente')), 'EDITORA');
      await tester.tap(find.text('Buscar'));
      await esperar(tester);
      expect(find.text('2 filtros activos'), findsOneWidget);

      await tester.tap(find.text('Limpiar'));
      await esperar(tester);
      expect(find.byKey(const ValueKey('filtros-activos')), findsNothing);
    });

    testWidgets('el rango activo es una pastilla informativa con icono de calendario', (
      tester,
    ) async {
      repo.cheques = variados();
      await montar(tester, pantalla(), ancho: 1400);

      final pastilla = find.byKey(const ValueKey('rango-activo'));
      expect(pastilla, findsOneWidget);
      expect(
        find.descendant(of: pastilla, matching: find.byIcon(Icons.date_range_outlined)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: pastilla,
          matching: find.text('Mostrando cheques recibidos del 03/07/2026 al 03/10/2026'),
        ),
        findsOneWidget,
      );
      final ctx = contextoDe(tester, pastilla);
      final deco = tester.widget<DecoratedBox>(pastilla).decoration as BoxDecoration;
      expect(deco.color, ChequesColores.fondo(ctx, SemanticaCheque.info));
    });
  });

  // ── Resumen dentro de la pantalla ─────────────────────────────────────────

  group('resumen en la pantalla', () {
    testWidgets('va sobre la tabla y cuenta lo que hay', (tester) async {
      repo.cheques = variados();
      await montar(tester, pantalla(), ancho: 1400);

      final resumen = find.byKey(const ValueKey('resumen-cheques'));
      expect(resumen, findsOneWidget);
      expect(
        tester.getBottomLeft(resumen).dy,
        lessThan(tester.getTopLeft(find.byKey(const ValueKey('lista-tabla'))).dy),
      );
      // 9 cheques, 8 pendientes (uno cerrado), 4 atrasados (14, 8, 6 y... el 10 esta cerrado).
      final total = find.byKey(const ValueKey('resumen-total'));
      final pend = find.byKey(const ValueKey('resumen-pendientes'));
      final atr = find.byKey(const ValueKey('resumen-atrasados'));
      expect(find.descendant(of: total, matching: find.text('9')), findsOneWidget);
      expect(find.descendant(of: pend, matching: find.text('8')), findsOneWidget);
      expect(find.descendant(of: atr, matching: find.text('3')), findsOneWidget);
      expect(find.descendant(of: pend, matching: find.text('1 cobra hoy')), findsOneWidget);
    });

    testWidgets('sin cheques no se dibuja', (tester) async {
      repo.cheques = [];
      await montar(tester, pantalla(), ancho: 1400);
      expect(find.byKey(const ValueKey('resumen-cheques')), findsNothing);
      expect(find.text('Todavía no hay cheques en esta sucursal'), findsNothing);
    });

    testWidgets('con tres paginas, rotula «en esta página»', (tester) async {
      repo = RepositorioChequesFalso(total: 45);
      await montar(tester, pantalla(), ancho: 1400);
      expect(find.text('en esta página'), findsNWidgets(3));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('resumen-total')),
          matching: find.text('45'),
        ),
        findsOneWidget,
      );
    });
  });

  // ── Tipografia del modulo, tambien en los dialogos ────────────────────────

  group('tipografia', () {
    testWidgets('la pantalla usa Plus Jakarta Sans y las cifras JetBrains Mono', (
      tester,
    ) async {
      repo.cheques = variados();
      await montar(tester, pantalla(), ancho: 1400);

      final tema = Theme.of(contextoDe(tester, find.text('Cliente').first));
      expect(tema.textTheme.bodyMedium?.fontFamily, ChequesTema.fuenteUI);
      expect(tema.textTheme.titleLarge?.fontFamily, ChequesTema.fuenteUI);

      for (final t in ['1,500.50', '14/08/2026']) {
        expect(
          tester.widget<Text>(find.text(t).first).style?.fontFamily,
          ChequesTema.fuenteCifras,
          reason: t,
        );
      }
      expect(
        tester.widget<Text>(find.text('100014').first).style?.fontFamily,
        ChequesTema.fuenteCifras,
        reason: 'el numero de cheque va en mono',
      );
    });

    testWidgets('el dialogo del formulario hereda la tipografia aunque cuelgue del Navigator raiz', (
      tester,
    ) async {
      repo.cheques = variados();
      await montar(tester, pantalla(), ancho: 1400);

      await tester.tap(find.text('Registrar'));
      await esperar(tester);

      final panel = find.byType(MarcoPanelCheque);
      expect(panel, findsOneWidget);
      final tema = Theme.of(contextoDe(tester, panel));
      expect(tema.textTheme.bodyMedium?.fontFamily, ChequesTema.fuenteUI);
      expect(tema.textTheme.titleLarge?.fontFamily, ChequesTema.fuenteUI);
      final titulo = tester.widget<Text>(find.text('Registrar cheque (administrador)'));
      expect(
        (titulo.style?.fontFamily ?? tema.textTheme.titleLarge?.fontFamily),
        ChequesTema.fuenteUI,
      );
    });

    for (final conTema in [true, false]) {
      testWidgets(
        'abrirPanelCheque ${conTema ? 'pone' : 'no pone'} el tema del modulo (Bancos reusa el contenedor)',
        (tester) async {
          late BuildContext dentro;
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (ctx) => Scaffold(
                  body: TextButton(
                    onPressed: () => abrirPanelCheque<void>(
                      ctx,
                      temaDelModulo: conTema,
                      contenido: (_) => Builder(
                        builder: (c) {
                          dentro = c;
                          return const SizedBox(width: 100, height: 100);
                        },
                      ),
                    ),
                    child: const Text('abrir'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('abrir'));
          await tester.pumpAndSettle();
          final familia = Theme.of(dentro).textTheme.bodyMedium?.fontFamily;
          if (conTema) {
            expect(familia, ChequesTema.fuenteUI);
          } else {
            expect(familia, isNot(ChequesTema.fuenteUI));
          }
        },
      );
    }

    testWidgets('el dialogo tambien lo hereda a pantalla completa en movil', (
      tester,
    ) async {
      repo.cheques = variados();
      await montar(tester, pantalla(), ancho: 390);
      await tester.tap(find.byTooltip('Registrar cheque'));
      await esperar(tester);
      final tema = Theme.of(contextoDe(tester, find.byType(MarcoPanelCheque)));
      expect(tema.textTheme.bodyMedium?.fontFamily, ChequesTema.fuenteUI);
    });
  });

  // ── Detalle ───────────────────────────────────────────────────────────────

  group('detalle', () {
    testWidgets('la cabecera lleva monograma, estado, plazo y el monto grande', (
      tester,
    ) async {
      final c = cheque(5, cobraEn: -3, banco: 'BANCO BISA');
      repo.cheques = [c];
      detalleDe(c);
      await montar(tester, pantalla(), ancho: 1400);
      await tester.tap(find.byTooltip('Completar'));
      await esperar(tester);

      expect(find.text('Cheque 100005'), findsOneWidget);
      expect(find.text('PENDIENTE'), findsOneWidget);
      expect(find.widgetWithText(PastillaCheque, 'Atrasado 3 d'), findsOneWidget);
      expect(find.byType(MonogramaBanco), findsOneWidget);
      expect(find.text('BI'), findsOneWidget);
      final monto = tester.widget<Text>(find.text('1,500.50'));
      expect(monto.style?.fontSize, 28);
      expect(monto.style?.fontFamily, ChequesTema.fuenteCifras);
    });
  });

  // ── Colores de las acciones del historial ─────────────────────────────────

  group('mapeo de colores de las acciones', () {
    test('cada estado de accion tiene el significado documentado', () {
      const esperado = {
        'REC': SemanticaCheque.info,
        'TRASP': SemanticaCheque.info,
        'DPB': SemanticaCheque.info,
        'CUS': SemanticaCheque.aviso,
        'VEN': SemanticaCheque.aviso,
        'ADE': SemanticaCheque.aviso,
        'PAP': SemanticaCheque.aviso,
        'DEV': SemanticaCheque.peligro,
        'DPR': SemanticaCheque.peligro,
        'COB': SemanticaCheque.exito,
        'CEF': SemanticaCheque.exito,
        'CCH': SemanticaCheque.exito,
        'VER': SemanticaCheque.exito,
      };
      esperado.forEach((estado, tono) {
        expect(semanticaDeAccion(estado), tono, reason: estado);
      });
      expect(semanticaDeAccion('XYZ'), SemanticaCheque.neutro);
      expect(semanticaDeAccion(''), SemanticaCheque.neutro);
    });

    test('cada estado de la maquina tiene su propio icono', () {
      const estados = [
        AccionChequeEntity.recibido,
        AccionChequeEntity.traspaso,
        AccionChequeEntity.custodia,
        AccionChequeEntity.devuelto,
        AccionChequeEntity.vencido,
        AccionChequeEntity.adelantado,
        AccionChequeEntity.cobrado,
        AccionChequeEntity.canjeadoEfectivo,
        AccionChequeEntity.canjeadoCheque,
        AccionChequeEntity.pagoParcial,
        AccionChequeEntity.depositadoRechazado,
      ];
      final iconos = {for (final e in estados) iconoDeAccion(e)};
      expect(iconos.length, estados.length);
      expect(iconos, isNot(contains(Icons.circle_outlined)));
      expect(iconoDeAccion('XYZ'), Icons.circle_outlined);
    });

    testWidgets('en el historial cada accion lleva su franja y su pastilla', (
      tester,
    ) async {
      final c = cheque(5, cobraEn: -3);
      repo.cheques = [c];
      detalleDe(c);
      await montar(tester, pantalla(), ancho: 1400);
      await tester.tap(find.byTooltip('Completar'));
      await esperar(tester);

      // El detalle del repositorio falso trae REC, TRASP y CUS.
      final ctx = contextoDe(tester, find.text('Historial (3)'));
      final franjas = tester.widgetList<FranjaCheque>(find.byType(FranjaCheque)).toList();
      expect(franjas.length, 3);
      expect(franjas[0].color, ChequesColores.pleno(ctx, SemanticaCheque.info));
      expect(franjas[1].color, ChequesColores.pleno(ctx, SemanticaCheque.info));
      expect(franjas[2].color, ChequesColores.pleno(ctx, SemanticaCheque.aviso));
      expect(franjas.every((f) => f.ancho == 3), isTrue);
      expect(find.byType(PastillaAccionCheque), findsNWidgets(3));
    });
  });

  // ── Piezas sueltas ────────────────────────────────────────────────────────

  group('monograma del banco', () {
    test('toma las iniciales de las palabras con significado', () {
      const casos = {
        'BANCO UNION': 'UN',
        'BANCO MERCANTIL SANTA CRUZ': 'MS',
        'BANCO NACIONAL DE BOLIVIA': 'NB',
        'BANCO BISA': 'BI',
        'Banco Mercantil Santa Cruz - Cuenta corriente 1234567890': 'MS',
        'BANCO GANADERO S.A.': 'GA',
        'BCO. FIE': 'FI',
        'BANCO': 'BA',
        '': '?',
        '   ': '?',
        'X': 'X',
      };
      casos.forEach((nombre, esperado) {
        expect(monogramaDeBanco(nombre), esperado, reason: '«$nombre»');
      });
    });

    test('el color es estable: no depende de mayusculas, espacios ni de la plataforma', () {
      expect(indiceDeBanco('BANCO UNION'), indiceDeBanco('  banco   union '));
      // Valores fijos: si cambia el algoritmo, el color de cada banco cambia en
      // todas las pantallas de todos los usuarios.
      expect(indiceDeBanco('BANCO UNION'), 179937411);
      expect(indiceDeBanco('BANCO MERCANTIL SANTA CRUZ'), 195198354);
      expect(indiceDeBanco('BANCO BISA'), 975065217);
      for (final n in ['BANCO UNION', 'BANCO FIE', 'X', 'BANCO ' * 40]) {
        expect(indiceDeBanco(n), inInclusiveRange(0, 0x7FFFFFFF));
      }
    });
  });

  // ── Nada de colores escritos a mano en los widgets ────────────────────────

  test('los widgets del modulo no escriben colores a mano', () {
    final archivos = [
      'lib/presentation/screens/cheques/cheques_screen.dart',
      'lib/presentation/widgets/cheques/lista_cheques.dart',
      'lib/presentation/widgets/cheques/piezas_cheques.dart',
      'lib/presentation/widgets/cheques/piezas_visuales_cheques.dart',
      'lib/presentation/widgets/cheques/resumen_cheques.dart',
      'lib/presentation/widgets/cheques/filtros_cheques.dart',
      'lib/presentation/widgets/cheques/detalle_cheque.dart',
    ];
    final prohibido = RegExp(
      r'Color\(\s*0x|Color\.fromARGB|Color\.fromRGBO|Colors\.(?!black\b|white\b|transparent\b)\w+',
    );
    for (final a in archivos) {
      final fuente = File(a).readAsStringSync();
      final sinComentarios = fuente
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      expect(
        prohibido.hasMatch(sinComentarios),
        isFalse,
        reason: '$a escribe un color a mano: ${prohibido.firstMatch(sinComentarios)?.group(0)}',
      );
    }
  });

  // ── El reloj es el de la pantalla ─────────────────────────────────────────

  testWidgets('el plazo de cobro se mide con el reloj inyectado', (tester) async {
    repo.cheques = [cheque(1, cobraEn: -12)];
    // Un dia despues: el mismo cheque lleva 13 dias de atraso.
    await tester.pumpWidget(
      appCheques(
        hijo: const ChequesScreen(),
        repo: repo,
        extra: [
          relojChequesProvider.overrideWithValue(() => DateTime(2026, 10, 4, 7, 0)),
        ],
      ),
    );
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await esperar(tester);
    expect(find.text('Atrasado 13 d'), findsOneWidget);
    expect(find.text('Atrasado 12 d'), findsNothing);
  });
}
