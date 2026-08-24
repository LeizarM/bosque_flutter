import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/pagado_item_entity.dart';
import 'package:bosque_flutter/domain/repositories/comisiones_repository.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/dialogo_items_pagados.dart';

/// El detalle por ítem de lo que ya se pagó.
///
/// Lo que se prueba acá, y nada de esto es decorativo:
///
///   1. Que el CERO nunca salga pelado. Un período sin ítems congelados puede
///      estar perfecto —ninguna nota cayó dentro de la vigencia de la
///      política— o puede estar roto —el congelado no corrió—, y mirando la
///      tabla se ven igual. Lo único que los separa es el corte, y el SP ya
///      redacta la explicación en `lectura`.
///
///   2. Que un ERROR DE RED no se disfrace de respuesta de la base. Con el
///      corte caído, decir «no quedó registro de que el detalle se haya
///      congelado» es el mismo fallo que este diálogo corrige, dado vuelta.
///
///   3. Que lo EXCLUIDO se vea. Es la mayoría de las líneas —15 de cada 19
///      medidas— y es la información que hasta ahora no existía en ningún
///      lado.
///
///   4. Que el selector de nota arrastre AL RESUMEN. La lista mostrando una
///      línea con el titular contando el mes entero es una contradicción a la
///      vista.
///
///   5. Que tildar y destildar «solo lo excluido» no cueste una descarga.
///
///   6. Que la tabla de escritorio no construya un mes entero de filas para
///      mostrar quince.
///
/// El barrido de tamaños mide ANCHO Y ALTO. Clavar el alto en 900 —que no lo
/// mide ningún teléfono— dejaba pasar los desbordes verticales, que son los
/// que tenía este diálogo. Para que la medición valga hacen falta la fuente
/// REAL —`flutter test` usa una de reemplazo donde todos los glifos miden
/// igual—, el tema del módulo y el widget real.
class _RepoFalso implements ComisionesRepository {
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('Este test no debería llamar a ${i.memberName}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final familia in ['PlusJakartaSans', 'JetBrainsMono']) {
      for (final peso in ['400', '500', '600', '700']) {
        final f = File('assets/fonts/$familia-$peso.ttf');
        if (!f.existsSync()) continue;
        final loader = FontLoader(familia)
          ..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
        await loader.load();
      }
    }
  });

  const filtro = FiltroItemsPagados(mes: 8, anio: 2026, esInterno: 1);

  // Los textos son los más largos de la base real: con datos cortos todo entra
  // y la prueba de desborde no encuentra nada.
  final items = <PagadoItemEntity>[
    PagadoItemEntity(
      idPagadoItem: 1,
      idPagado: 111540,
      mesPago: 8,
      anioPago: 2026,
      esInterno: 1,
      docNum: 262220421,
      origen: 'PRODUCTIVA PAPEL',
      fechaDoc: DateTime(2026, 8, 21),
      idVendedor: 39,
      itemCode: 'PBB075067089ACA',
      itemName: 'PAPEL BOND BLANCO 075G 067X089CM 500HJS  CELULOSA ARGENTINA',
      grpFam: 'Papel Bond Blanco',
      cantidad: 1,
      montoLineaBs: 1234567.89,
      porcentajePago: 50,
      descuentoBs: 617283.95,
    ),
    // La línea excluida por vigencia: es el motivo que más confunde -la
    // política se ve activa en pantalla y la nota igual no descuenta- y la
    // combinación donde el chip de motivo cae al lado del importe.
    PagadoItemEntity(
      idPagadoItem: 2,
      idPagado: 111540,
      mesPago: 8,
      anioPago: 2026,
      esInterno: 1,
      docNum: 262220421,
      origen: 'PRODUCTIVA PAPEL',
      fechaDoc: DateTime(2026, 8, 21),
      itemCode: 'CDX250070100',
      itemName: 'CARTULINA DUPLEX 250G 070X100CM DOBLE FAZ ESTUCADA',
      grpFam: 'Cartulina Duplex',
      cantidad: 12,
      montoLineaBs: 380,
      aplicaDescuento: false,
      motivoExclusion: MotivoItemPagado.fueraDeVigencia,
    ),
    PagadoItemEntity(
      idPagadoItem: 3,
      idPagado: 111541,
      mesPago: 8,
      anioPago: 2026,
      esInterno: 1,
      docNum: 262211852,
      origen: 'IMPEXPAP',
      fechaDoc: DateTime(2026, 8, 20),
      itemCode: 'QUI010000000',
      itemName: 'HIPOCLORITO DE SODIO GRADO INDUSTRIAL 200LT',
      cantidad: 3,
      montoLineaBs: 9800,
      aplicaDescuento: false,
      motivoExclusion: MotivoItemPagado.sinFamilia,
    ),
  ];

  final resumen = <PagadoItemResumenEntity>[
    const PagadoItemResumenEntity(
      motivo: MotivoItemPagado.desconto,
      items: 1,
      montoBs: 1234567.89,
      descuentoBs: 617283.95,
    ),
    const PagadoItemResumenEntity(
      motivo: MotivoItemPagado.sinFamilia,
      items: 1,
      montoBs: 9800,
    ),
    const PagadoItemResumenEntity(
      motivo: MotivoItemPagado.fueraDeVigencia,
      items: 1,
      montoBs: 380,
    ),
  ];

  /// El resumen MÁS ALTO que puede llegar: DESCONTO y los cuatro motivos de
  /// exclusión. Cinco filas es el máximo real, y es la medida con la que el
  /// bloque desbordaba la pantalla de un teléfono.
  final resumenCompleto = <PagadoItemResumenEntity>[
    const PagadoItemResumenEntity(
      motivo: MotivoItemPagado.desconto,
      items: 4,
      montoBs: 1234567.89,
      descuentoBs: 617283.95,
    ),
    const PagadoItemResumenEntity(
      motivo: MotivoItemPagado.fueraDeVigencia,
      items: 9,
      montoBs: 84210.55,
    ),
    const PagadoItemResumenEntity(
      motivo: MotivoItemPagado.familiaSinPolitica,
      items: 3,
      montoBs: 22140,
    ),
    const PagadoItemResumenEntity(
      motivo: MotivoItemPagado.sinFamilia,
      items: 2,
      montoBs: 9800,
    ),
    const PagadoItemResumenEntity(
      motivo: MotivoItemPagado.vendedorExento,
      items: 1,
      montoBs: 380,
    ),
  ];

  /// Un corte con detalle: el período se congeló y quedaron ítems.
  final corteConDetalle = PagadoItemCorteEntity(
    idCorte: 1,
    mesPago: 8,
    anioPago: 2026,
    esInterno: 1,
    items: 3,
    itemsExcluidos: 2,
    notasPagadas: 2,
    notasConItems: 2,
    politicaDesde: DateTime(2026, 1, 1),
    politicasActivas: 2,
    audFecha: DateTime(2026, 8, 23),
    lectura: 'Con detalle',
  );

  /// El caso (a): el congelado corrió y no había nada que congelar. Es lo
  /// normal durante meses —95 períodos ya pagados y ninguno dentro de la
  /// ventana de la primera política— y es el que no se puede mostrar en cero.
  final corteVacio = PagadoItemCorteEntity(
    idCorte: 2,
    mesPago: 8,
    anioPago: 2026,
    esInterno: 1,
    notasPagadas: 690,
    notasSinItems: 690,
    politicaDesde: DateTime(2026, 1, 1),
    politicasActivas: 2,
    audFecha: DateTime(2026, 8, 23),
    lectura: 'Ninguna nota cayo dentro de la vigencia de la politica',
  );

  Future<void> montar(
    WidgetTester tester, {
    required double ancho,
    double alto = 900,
    List<PagadoItemEntity> lista = const [],
    List<PagadoItemResumenEntity> filasResumen = const [],
    PagadoItemCorteEntity? corte,
    bool resumenFalla = false,
    bool corteFalla = false,
    Map<int, List<PagadoItemResumenEntity>> resumenPorNota = const {},
    List<FiltroItemsPagados>? pedidosLista,
    List<FiltroItemsPagados>? pedidosResumen,
  }) async {
    tester.view.physicalSize = Size(ancho, alto);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          comisionesRepositoryProvider.overrideWithValue(_RepoFalso()),
          // El filtro de nota SÍ es del SP (@docNum + @origen) y el override
          // tiene que respetarlo; «solo lo excluido» ya no lo es, así que
          // respetarlo acá sería probar un parámetro que no existe.
          itemsPagadosProvider.overrideWith((ref, f) async {
            pedidosLista?.add(f);
            return f.docNum == null
                ? lista
                : lista
                    .where(
                      (i) =>
                          i.docNum == f.docNum &&
                          (f.origen == null || i.origen == f.origen),
                    )
                    .toList();
          }),
          resumenItemsPagadosProvider.overrideWith((ref, f) async {
            pedidosResumen?.add(f);
            if (resumenFalla) throw Exception('la rama R no respondió');
            if (f.docNum != null) {
              return resumenPorNota[f.docNum] ??
                  const <PagadoItemResumenEntity>[];
            }
            return filasResumen;
          }),
          corteItemsPagadosProvider.overrideWith((ref, c) async {
            if (corteFalla) throw Exception('el corte no respondió');
            return corte;
          }),
        ],
        child: MaterialApp(
          theme: ThemeData(fontFamily: 'PlusJakartaSans', useMaterial3: true),
          builder:
              (context, child) => ResponsiveBreakpoints.builder(
                child: child!,
                breakpoints: ResponsiveUtilsBosque.breakpoints,
              ),
          home: Builder(
            builder:
                (context) => Theme(
                  data: ComisionesTema.temaModulo(context),
                  child: const Scaffold(
                    // El diálogo montado directo: showDialog necesitaría un
                    // tap y acá lo que se mide es el diálogo, no el camino
                    // hasta él. Los dos puntos de entrada reales
                    // -tab_ejecutar y tab_preliminar- lo abren con showDialog.
                    body: DialogoItemsPagados(filtro: filtro),
                  ),
                ),
          ),
        ),
      ),
    );
    // pump() y no pumpAndSettle(): el esqueleto de carga anima en bucle.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  /// Un tap y los dos pump que hacen falta para que se asiente sin quedar
  /// atrapado en la animación del esqueleto.
  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.tap(f);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  // ── Lo excluido, que es el motivo de todo esto ──────────────────────────

  testWidgets('arranca mostrando lo excluido, no lo que descontó', (
    tester,
  ) async {
    await montar(
      tester,
      ancho: 1920,
      lista: items,
      filasResumen: resumen,
      corte: corteConDetalle,
    );

    expect(
      find.textContaining('CARTULINA DUPLEX'),
      findsWidgets,
      reason:
          'La línea excluida por vigencia tiene que estar a la vista al abrir: '
          'es la que no se podía consultar en ningún lado.',
    );
    expect(
      find.textContaining('PAPEL BOND BLANCO'),
      findsNothing,
      reason:
          'Con «Solo lo excluido» puesto, lo que descontó no va: eso ya se veía '
          'en el reporte de pagadas.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('el resumen dice cuánto quedó afuera antes de la lista', (
    tester,
  ) async {
    await montar(
      tester,
      ancho: 1920,
      lista: items,
      filasResumen: resumen,
      corte: corteConDetalle,
    );

    expect(
      find.textContaining('2 de 3 ítems no descontaron'),
      findsOneWidget,
      reason:
          'La pregunta que trae a alguien acá es cuánto quedó afuera. Sin el '
          'titular hay que sumar las filas del resumen para saberlo.',
    );
    // Y el porqué de cada motivo, no solo su nombre: «Fuera de vigencia» sin
    // explicación no le dice nada a quien pregunta por su comisión.
    expect(find.textContaining('fuera de su ventana'), findsWidgets);
    expect(
      find.textContaining('no está mapeado a ninguna familia'),
      findsWidgets,
    );
  });

  testWidgets('el resumen muestra lo descontado, que ya venía en la rama R', (
    tester,
  ) async {
    await montar(
      tester,
      ancho: 1920,
      lista: items,
      filasResumen: resumen,
      corte: corteConDetalle,
    );

    expect(
      find.textContaining('-617,283.95 Bs'),
      findsWidgets,
      reason:
          'El descuento por motivo lo trae el SP y se estaba parseando para '
          'tirarlo. En la fila de DESCONTO es el único número que dice cuánto '
          'se descontó: el otro es la base de la línea.',
    );
  });

  testWidgets('quitar el filtro trae de vuelta lo que sí descontó', (
    tester,
  ) async {
    await montar(
      tester,
      ancho: 1920,
      lista: items,
      filasResumen: resumen,
      corte: corteConDetalle,
    );

    await tocar(tester, find.text('Solo lo excluido'));

    expect(find.textContaining('PAPEL BOND BLANCO'), findsWidgets);
    expect(find.textContaining('CARTULINA DUPLEX'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tildar y destildar el chip no vuelve a pedir el período', (
    tester,
  ) async {
    final pedidos = <FiltroItemsPagados>[];
    await montar(
      tester,
      ancho: 1920,
      lista: items,
      filasResumen: resumen,
      corte: corteConDetalle,
      pedidosLista: pedidos,
    );

    expect(pedidos.length, 1, reason: 'Abrir el diálogo pide el mes una vez.');

    await tocar(tester, find.text('Solo lo excluido'));
    await tocar(tester, find.text('Solo lo excluido'));

    expect(
      pedidos.length,
      1,
      reason:
          'El filtro es un where sobre lo que ya está en memoria. Con él en la '
          'clave del provider —que es autoDispose— la ida y la vuelta del chip '
          'costaban dos descargas del mes entero.',
    );
    expect(tester.takeException(), isNull);
  });

  // ── El selector de nota, que tiene que arrastrar al resumen ─────────────

  testWidgets('elegir una nota mueve la lista Y el titular', (tester) async {
    final pedidosResumen = <FiltroItemsPagados>[];
    await montar(
      tester,
      ancho: 1920,
      lista: items,
      filasResumen: resumen,
      corte: corteConDetalle,
      resumenPorNota: {
        262211852: [
          const PagadoItemResumenEntity(
            motivo: MotivoItemPagado.sinFamilia,
            items: 1,
            montoBs: 9800,
          ),
        ],
      },
      pedidosResumen: pedidosResumen,
    );

    expect(find.textContaining('2 de 3 ítems no descontaron'), findsOneWidget);

    await tocar(tester, find.text('Todas las notas'));
    await tocar(tester, find.text('Nota 262211852').last);

    expect(
      find.textContaining('1 de 1 ítems no descontaron'),
      findsOneWidget,
      reason:
          'El SP acepta @docNum en la rama R. Sin mandárselo, la lista mostraba '
          'una línea y el titular seguía contando el mes entero.',
    );
    expect(find.textContaining('2 de 3 ítems no descontaron'), findsNothing);
    expect(find.textContaining('HIPOCLORITO'), findsWidgets);
    expect(find.textContaining('CARTULINA DUPLEX'), findsNothing);

    expect(
      pedidosResumen.last.docNum,
      262211852,
      reason: 'El resumen tiene que viajar con la nota, no con el período.',
    );
    expect(
      pedidosResumen.last.origen,
      'IMPEXPAP',
      reason:
          'docNum no es único entre empresas: sin @origen, el filtro puede '
          'traer la nota de otra.',
    );
    expect(tester.takeException(), isNull);
  });

  // ── El cero, que es la parte que se rompe sola ──────────────────────────

  testWidgets('período sin ítems: muestra la lectura del corte, no un cero', (
    tester,
  ) async {
    await montar(tester, ancho: 1920, corte: corteVacio);

    expect(
      find.textContaining('Ninguna nota cayo dentro de la vigencia'),
      findsOneWidget,
      reason:
          'La lectura la redacta el SP justamente para que la pantalla no '
          'tenga que deducirla. Si no se muestra, el cero vuelve a no '
          'distinguirse de «el congelado no corrió».',
    );
    expect(
      find.textContaining('línea'),
      findsNothing,
      reason:
          'Un «0 líneas» al lado de la explicación es el cero pelado otra vez, '
          'y contradice al texto que está tratando de explicarlo.',
    );
    // El contexto que hace interpretable al cero: 690 notas pagadas y ninguna
    // con detalle. Ese número es el que delata un congelado que no corrió.
    expect(find.text('690'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'sin corte: lo dice, en vez de hacerlo pasar por «no había nada»',
    (tester) async {
      await montar(tester, ancho: 1920, corte: null);

      expect(
        find.textContaining('no tiene corte'),
        findsOneWidget,
        reason:
            'Sin fila de corte, el período nunca se congeló. Es el caso (b) '
            'del script 23: el histórico está roto y hay que decirlo, no '
            'mostrarlo como un período tranquilo sin descuentos.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('el corte caído se muestra como falla, no como veredicto', (
    tester,
  ) async {
    await montar(tester, ancho: 1920, corteFalla: true);

    expect(
      find.textContaining('no tiene corte'),
      findsNothing,
      reason:
          'Con la llamada fallida no se sabe si el período tiene corte. '
          'Afirmar que no lo tiene es acusar a la base de un error de red, y '
          'es exactamente el fallo que este diálogo dice corregir.',
    );
    expect(find.textContaining('No se pudieron cargar los datos'), findsWidgets);
    expect(
      find.text('Reintentar'),
      findsOneWidget,
      reason: 'El listado ya ofrecía reintentar; el corte no ofrecía nada.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hubo ítems pero ninguno excluido: lo dice y ofrece deshacerlo', (
    tester,
  ) async {
    await montar(
      tester,
      ancho: 1920,
      // Solo la línea que descontó: con el filtro puesto, la lista queda
      // vacía aunque el período sí tenga detalle.
      lista: [items.first],
      filasResumen: [resumen.first],
      corte: corteConDetalle,
    );

    expect(find.textContaining('Ninguna línea quedó excluida'), findsOneWidget);
    expect(
      find.text('Solo lo excluido'),
      findsOneWidget,
      reason:
          'Acá la lista la vacía el filtro, no el período: el interruptor tiene '
          'que seguir a la vista para poder apagarlo.',
    );
  });

  testWidgets('sin exclusiones el titular no anuncia un cero', (tester) async {
    await montar(
      tester,
      ancho: 1920,
      lista: [items.first],
      filasResumen: [resumen.first],
      corte: corteConDetalle,
    );

    expect(
      find.textContaining('0 de 1'),
      findsNothing,
      reason:
          'Un cero al lado de un uno se lee como un problema, y acá es lo '
          'contrario: la única línea del período descontó.',
    );
    expect(
      find.textContaining('0.00 Bs quedaron'),
      findsNothing,
      reason: 'El segundo cero pelado de la misma caja.',
    );
    expect(find.textContaining('descontó'), findsWidgets);
  });

  testWidgets('con ítems y sin corte no se contradice a sí mismo', (
    tester,
  ) async {
    // Alcanzable de verdad: un período congelado por el script 22 antes de
    // aplicar el 23 tiene ítems y no tiene fila de corte.
    await montar(
      tester,
      ancho: 1920,
      lista: [items.first],
      filasResumen: [resumen.first],
      corte: null,
    );

    expect(
      find.textContaining('no tiene corte'),
      findsNothing,
      reason:
          'Con el resumen contando ítems arriba, «este período no tiene corte» '
          'abajo es una contradicción a la vista: el detalle está, lo que '
          'falta es el sello.',
    );
    expect(find.textContaining('Ninguna línea quedó excluida'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // ── El resumen que falla, que no es el resumen que falta ────────────────

  testWidgets('si la rama R falla se dice, y el chip sigue en pantalla', (
    tester,
  ) async {
    await montar(
      tester,
      ancho: 1920,
      lista: [items.first],
      resumenFalla: true,
      corte: corteConDetalle,
    );

    expect(
      find.textContaining('No se pudo leer el reparto por motivo'),
      findsOneWidget,
      reason:
          'Un resumen que no llegó y uno que falló se veían igual: un bloque '
          'que falta.',
    );
    expect(
      find.text('Solo lo excluido'),
      findsOneWidget,
      reason:
          'El vacío de abajo manda a quitar «Solo lo excluido». Antes la barra '
          'dependía de que el resumen hubiera llegado, así que con la rama R '
          'caída el texto mandaba a apagar un control que no estaba dibujado.',
    );
    expect(find.textContaining('Quite «Solo lo excluido»'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // ── Volumen: la tabla de escritorio no puede construir el mes entero ────

  testWidgets('un mes grande no construye una fila por línea', (tester) async {
    // Un mes real anda por las dos mil líneas. Antes eran dos mil DataRow con
    // su ChipEstado, construidas en el frame en que abría el diálogo, para
    // mostrar quince.
    final muchas = <PagadoItemEntity>[
      for (var k = 0; k < 2000; k++)
        PagadoItemEntity(
          idPagadoItem: k,
          idPagado: 111540,
          docNum: 262220421,
          origen: 'PRODUCTIVA PAPEL',
          itemCode: 'CDX2500701$k',
          itemName: 'CARTULINA DUPLEX 250G 070X100CM DOBLE FAZ ESTUCADA $k',
          grpFam: 'Cartulina Duplex',
          cantidad: 12,
          montoLineaBs: 380,
          aplicaDescuento: false,
          motivoExclusion: MotivoItemPagado.fueraDeVigencia,
        ),
    ];

    await montar(
      tester,
      ancho: 1920,
      lista: muchas,
      filasResumen: resumen,
      corte: corteConDetalle,
    );

    // Cada fila lleva exactamente un ChipEstado con su motivo; el encabezado
    // del diálogo aporta dos más. Si la tabla no virtualizara, acá habría más
    // de dos mil.
    final chips = find.byType(ChipEstado).evaluate().length;
    expect(
      chips,
      lessThan(100),
      reason:
          'Se construyeron $chips chips para 2000 líneas: la tabla está '
          'materializando filas que nadie ve.',
    );
    // Y el otro lado del mismo control: si la tabla no dibujara NADA, el
    // conteo tambien seria bajo y la prueba pasaria sin haber medido nada.
    // Dos de los chips son los del encabezado del dialogo.
    expect(
      chips,
      greaterThan(4),
      reason: 'La tabla no dibujó filas: el conteo no está midiendo nada.',
    );
    expect(tester.takeException(), isNull);
  });

  // ── Desborde: ancho Y alto ──────────────────────────────────────────────

  // Ningún teléfono mide 900 de alto, que es lo que clavaban estas pruebas:
  // por eso el desborde vertical del resumen podía estar y pasar en verde.
  // Las dos primeras medidas son las que lo reprodujeron.
  const pantallas = <(double, double)>[
    (320, 568),
    (360, 640),
    (412, 732),
    (600, 480),
    (768, 1024),
    (1280, 720),
    (1920, 1080),
  ];

  for (final (ancho, alto) in pantallas) {
    testWidgets('sin desborde a ${ancho}x$alto con los cinco motivos', (
      tester,
    ) async {
      await montar(
        tester,
        ancho: ancho,
        alto: alto,
        lista: items,
        // El peor caso real: DESCONTO y los cuatro motivos de exclusión.
        filasResumen: resumenCompleto,
        corte: corteConDetalle,
      );

      expect(
        find.textContaining('no descontaron'),
        findsWidgets,
        reason: 'El diálogo no se dibujó a ${ancho}x$alto',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'Desborde a ${ancho}x$alto',
      );
    });

    testWidgets('sin desborde a ${ancho}x$alto en el vacío explicado', (
      tester,
    ) async {
      await montar(tester, ancho: ancho, alto: alto, corte: corteVacio);

      expect(find.textContaining('Sin ítems congelados'), findsWidgets);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Desborde a ${ancho}x$alto',
      );
    });

    testWidgets('sin desborde a ${ancho}x$alto con el corte caído', (
      tester,
    ) async {
      await montar(tester, ancho: ancho, alto: alto, corteFalla: true);

      expect(
        find.textContaining('No se pudieron cargar los datos'),
        findsWidgets,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'Desborde a ${ancho}x$alto',
      );
    });
  }
}
