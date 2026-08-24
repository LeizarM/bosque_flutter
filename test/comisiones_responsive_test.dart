import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/comision_por_rango_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_comision_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_x_vendedor_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_pendiente_entity.dart';
import 'package:bosque_flutter/domain/entities/pagado_item_entity.dart';
import 'package:bosque_flutter/domain/entities/politica_bond_entity.dart';
import 'package:bosque_flutter/domain/entities/preliminar_comision_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_cambio_comision_entity.dart';
import 'package:bosque_flutter/domain/entities/vendedor_comision_entity.dart';
import 'package:bosque_flutter/domain/repositories/comisiones_repository.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/dialogo_items_pagados.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_asignaciones.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_grupos.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_pendientes.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_politica.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_rangos.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_preliminar.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_vendedores.dart';

/// La barra de reportes hace ref.read(comisionesRepositoryProvider) en su
/// build, asi que sin un doble la pestania ni se dibuja. Solo lo lee: los
/// metodos se llaman al apretar un boton, y el barrido no aprieta ninguno.
class _RepoFalso implements ComisionesRepository {
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError(
        'El barrido de anchos no deberia llamar a ${i.memberName}',
      );
}

/// Barre TODAS las pestanias del modulo por anchos buscando desbordes.
///
/// Nacio de un "RIGHT OVERFLOWED BY 1.2 PIXELS" en Politica. Para que una
/// prueba asi mida lo que mide la aplicacion hacen falta tres cosas, y sin
/// cualquiera de ellas pasa en verde sin probar nada:
///
///   1. La fuente REAL. flutter test usa por defecto una de reemplazo donde
///      todos los glifos miden igual, y estos desbordes son de un pixel.
///   2. El tema del modulo. En la aplicacion las pestanias viven dentro de
///      Theme(data: ComisionesTema.temaModulo(context)), que cambia familia,
///      tamanios y tracking.
///   3. El widget REAL, no una replica. Copiar a mano las filas sospechosas y
///      barrerlas no encontro el bug que si estaba.
///
/// Cada caso ademas confirma que la pestania se dibujo, con un texto que solo
/// aparece si llegaron los datos. Sin ese control una pantalla en blanco
/// tambien "pasa".

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

  // ── Datos de mentira, con los textos LARGOS de verdad ───────────────────
  // Los nombres y rotulos son los mas largos que hay en la base: son los que
  // hacen desbordar. Con datos cortos la prueba no encuentra nada.
  final vendedores = <VendedorComisionEntity>[
    VendedorComisionEntity(
      idVendedor: BigInt.from(39),
      nomVenSap: 'Humberto de la Torre Villavicencio',
      comision: 0,
      esInterno: 1,
      activo: 1,
      audUsuario: BigInt.one,
      codVenImpexpap: 105,
      codVenEsppapel: 71,
      codVenProdpap: 33,
    ),
    VendedorComisionEntity(
      idVendedor: BigInt.from(55),
      nomVenSap: 'Marcela Caceres',
      comision: 0,
      esInterno: 1,
      activo: 1,
      audUsuario: BigInt.one,
      codVenImpexpap: 12,
    ),
  ];

  final grupos = <GrupoComisionEntity>[
    GrupoComisionEntity(
      idGrupo: BigInt.from(17),
      grupo: 'Administracion Comercial',
      porcentaje: 0.025,
      esParaVenta: 0,
      esInterno: 1,
      bd: 1,
      siglaEmpresa: 'IMPEXPAP',
      activo: 1,
      audUsuario: BigInt.one,
    ),
    GrupoComisionEntity(
      idGrupo: BigInt.from(18),
      grupo: 'Supervisor Distribuicion',
      porcentaje: 0.02,
      esParaVenta: 0,
      esInterno: 1,
      bd: 1,
      siglaEmpresa: 'PRODUCTIVA PAPEL',
      activo: 1,
      audUsuario: BigInt.one,
    ),
  ];

  final asignaciones = <GrupoXVendedorEntity>[
    GrupoXVendedorEntity(
      idGrpVen: BigInt.one,
      idVendedor: BigInt.from(39),
      idGrupo: BigInt.from(17),
      estado: 1,
      ignoraComision: 0,
      fechaInicio: DateTime(2020, 1, 1),
      audUsuario: BigInt.one,
      nomVenSap: 'Humberto de la Torre Villavicencio',
      grupo: 'Administracion Comercial',
      porcentaje: 0.025,
      porcenComision: 2.5,
      esParaVenta: 0,
      esInterno: 1,
      vigente: 1,
    ),
  ];

  final pendientes = <NotaPendienteEntity>[
    NotaPendienteEntity(
      fila: 1,
      idNoPagado: 111540,
      codVendedor: 105,
      nombreVen: 'Humberto de la Torre Villavicencio',
      fechaDoc: DateTime(2026, 8, 21),
      mes: 8,
      anio: 2026,
      docNum: 262220421,
      valido: 'V',
      indicador: 'PENDIENTE',
      estado: 'C',
      montoTotalBs: 1234567.89,
      montoCerradoBs: 1234567.89,
      origen: 'PRODUCTIVA PAPEL',
      saldoPendiente: 0,
    ),
  ];

  final rangos = <ComisionPorRangoEntity>[
    ComisionPorRangoEntity(
      idCfr: BigInt.one,
      comision: 0.008,
      comisionVisual: 0.8,
      min: -999999999,
      max: -1,
      tipo: 'Contado',
      esInterno: 1,
      audUsuario: BigInt.one,
    ),
    ComisionPorRangoEntity(
      idCfr: BigInt.two,
      comision: 0.002,
      comisionVisual: 0.2,
      min: 91,
      max: 1000000,
      tipo: 'Credito',
      esInterno: 1,
      audUsuario: BigInt.one,
    ),
  ];

  final preliminar = <PreliminarComisionEntity>[
    const PreliminarComisionEntity(
      ord: 1,
      idVendedor: 39,
      mes: 8,
      anio: 2026,
      etiqueta: 'Administracion Comercial',
      nombreVen: 'Humberto de la Torre Villavicencio',
      comision: 0.0068432640459531778,
      ignoraComision: 0,
      montoBase: 3949639.10,
      bsAPagar: 20437.45,
      usdAPagar: 1777.17,
    ),
    const PreliminarComisionEntity(
      ord: 2,
      etiqueta: 'TOTAL IPX',
      nombreVen: 'TOTAL IPX',
      comision: 0,
      ignoraComision: 0,
      montoBase: 3949639.10,
      bsAPagar: 20437.45,
      usdAPagar: 1777.17,
    ),
  ];

  final descuentos = <DescuentoDetalleEntity>[
    DescuentoDetalleEntity(
      docNum: 262211852,
      empresa: 'IMPEXPAP',
      fechaDoc: DateTime(2026, 8, 21),
      nombreVen: 'Humberto de la Torre Villavicencio',
      cardCode: 'VA00669',
      grupoFamilia: 'Papel Bond Blanco',
      codGrupoSap: 147,
      itemCode: 'PBB075067089ACA',
      itemName: 'PAPEL BOND BLANCO 075G 067X089CM 500HJS  CELULOSA ARGENTINA',
      cantidad: 1,
      montoItemBs: 380,
      porcentajePago: 50,
      porcentajeDescuento: 50,
      descuentoBs: -190,
      montoBaseNotaBs: 0,
      montoNotaAjustadoBs: -190,
      notas: 1,
      items: 1,
    ),
  ];

  // Los items congelados al ejecutar el pago. Las dos primeras filas son la
  // combinacion que desborda: la descripcion mas larga de la base al lado de
  // un importe de siete cifras, y una linea excluida cuyo chip de motivo cae
  // pegado al monto.
  final itemsPagados = <PagadoItemEntity>[
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
  ];

  final resumenItems = <PagadoItemResumenEntity>[
    const PagadoItemResumenEntity(
      motivo: MotivoItemPagado.desconto,
      items: 1,
      montoBs: 1234567.89,
      descuentoBs: 617283.95,
    ),
    const PagadoItemResumenEntity(
      motivo: MotivoItemPagado.fueraDeVigencia,
      items: 1,
      montoBs: 380,
    ),
  ];

  final corteItems = PagadoItemCorteEntity(
    idCorte: 1,
    mesPago: 8,
    anioPago: 2026,
    esInterno: 1,
    items: 2,
    itemsExcluidos: 1,
    notasPagadas: 1,
    notasConItems: 1,
    politicaDesde: DateTime(2026, 1, 1),
    politicasActivas: 2,
    audFecha: DateTime(2026, 8, 23),
    lectura: 'Con detalle',
  );

  final overrides = <Override>[
    comisionesRepositoryProvider.overrideWithValue(_RepoFalso()),
    vendedoresComisionProvider.overrideWith((ref) async => vendedores),
    gruposComisionProvider.overrideWith((ref) async => grupos),
    asignacionesVigentesProvider.overrideWith((ref) async => asignaciones),
    notasPendientesProvider.overrideWith((ref) async => pendientes),
    rangosComisionProvider.overrideWith((ref) async => rangos),
    preliminarProvider.overrideWith((ref, f) async => preliminar),
    descuentoDetalleProvider.overrideWith((ref, f) async => descuentos),
    // Sin estos tres, _RepoFalso lanza UnimplementedError en cuanto el
    // dialogo pide datos y revientan los casos del barrido.
    // El SP filtra por nota (@docNum + @origen). «Solo lo excluido» ya no es
    // parametro: lo resuelve el dialogo sobre lo que tiene en memoria, asi que
    // un override que lo respetara estaria probando algo que no existe.
    itemsPagadosProvider.overrideWith(
      (ref, f) async =>
          f.docNum == null
              ? itemsPagados
              : itemsPagados
                  .where(
                    (i) =>
                        i.docNum == f.docNum &&
                        (f.origen == null || i.origen == f.origen),
                  )
                  .toList(),
    ),
    resumenItemsPagadosProvider.overrideWith((ref, f) async => resumenItems),
    corteItemsPagadosProvider.overrideWith((ref, c) async => corteItems),
    // Dos familias, una activa y una dada de baja: es la unica fila del
    // modulo donde un chip de acento y uno de alerta caen uno al lado del
    // otro. Con la lista vacia esa fila no se dibujaba y el caso pasaba
    // sin haberla medido.
    politicaFamiliasProvider.overrideWith(
      (ref) async => [
        FamiliaPoliticaEntity(
          idFamPolitica: 1,
          idGrpFamiliaSap: 11,
          grpFam: 'Papel Bond Blanco',
          alias: 'Bond',
          porcentajePago: 50,
          vigenteDesde: DateTime(2026, 1, 1),
          activo: 1,
        ),
        FamiliaPoliticaEntity(
          idFamPolitica: 2,
          idGrpFamiliaSap: 12,
          grpFam: 'Cartulina Duplex',
          porcentajePago: 30,
          vigenteDesde: DateTime(2025, 6, 1),
          vigenteHasta: DateTime(2026, 7, 31),
          activo: 0,
        ),
      ],
    ),
    vendedoresExentosProvider.overrideWith((ref) async => const []),
    clientesExcluidosProvider.overrideWith((ref) async => const []),
    familiasSapDisponiblesProvider.overrideWith((ref) async => const []),
    tipoCambioSugeridoProvider.overrideWith(
      (ref) async => TipoCambioComisionEntity(
        fecha: DateTime(2026, 8, 23),
        tipoCambio: 11.5,
        origen: 'SAP',
        diasDeAntiguedad: 0,
      ),
    ),
  ];

  Widget app(Widget pestania) => ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: ThemeData(fontFamily: 'PlusJakartaSans', useMaterial3: true),
      builder:
          (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: ResponsiveUtilsBosque.breakpoints,
          ),
      home: Scaffold(
        body: Builder(
          builder:
              (context) => Theme(
                data: ComisionesTema.temaModulo(context),
                child: pestania,
              ),
        ),
      ),
    ),
  );

  // Un telefono chico, uno grande, tablet vertical y horizontal, portatil y
  // monitor ancho. El 1592 es el ancho util de la ventana del reporte.
  // 451 y 500 no son adorno: entre 412 y 600 esta el rango de tablet que
  // el barrido no tocaba, justo donde el buscador con tope de 360 px
  // cambia de comportamiento.
  const anchos = <double>[
    320,
    360,
    412,
    451,
    500,
    600,
    768,
    1024,
    1280,
    1592,
    1920,
  ];

  /// (widget, texto que prueba que se dibujo, rotulos a tocar antes de medir)
  final pestanias = <String, (Widget, String, List<String>)>{
    'Vendedores': (
      const TabVendedores(),
      'Humberto de la Torre Villavicencio',
      const [],
    ),
    'Grupos': (const TabGrupos(), 'Administracion Comercial', const []),
    'Asignaciones': (
      const TabAsignaciones(),
      'Administracion Comercial',
      const [],
    ),
    'Escala por dias': (const TabRangos(), 'Contado', const []),
    // El Preliminar arranca en el grafico; la tabla es la vista ancha y la
    // que puede desbordar, asi que hay que pasar a ella antes de medir.
    'Preliminar': (
      TabPreliminar(modalidades: ModalidadPreliminar.values),
      'Tipo de cambio',
      const ['Tabla'],
    ),
    'Pendientes': (const TabPendientes(), 'notas sin cobrar', const []),
    // Politica arranca en Familias; la seccion del bug es Descuentos.
    'Politica': (
      const TabPolitica(),
      'Familias',
      const ['Descuentos aplicados', 'Descuentos'],
    ),
    // No es una pestania: es el dialogo del detalle congelado, montado directo
    // porque el barrido no abre dialogos -solo hace tap sobre un find.text y
    // corta en el primer match-, y sin esto pasaria en verde sin haberlo
    // medido nunca. Cambia de forma dos veces en el rango: tarjetas hasta 450,
    // tabla con scroll horizontal desde 451.
    'Detalle congelado': (
      const DialogoItemsPagados(
        filtro: FiltroItemsPagados(mes: 8, anio: 2026, esInterno: 1),
      ),
      'no descontaron',
      const [],
    ),
  };

  pestanias.forEach((nombre, par) {
    final (widget, textoTestigo, aTocar) = par;
    for (final ancho in anchos) {
      testWidgets('$nombre sin desborde a $ancho', (tester) async {
        tester.view.physicalSize = Size(ancho, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(app(widget));

        // pump() y no pumpAndSettle(): el esqueleto de carga anima en bucle y
        // pumpAndSettle nunca terminaria. Los 5 s le dan tiempo al timeout de
        // lectura del almacenamiento seguro que dispara userProvider.
        await tester.pump();
        await tester.pump(const Duration(seconds: 5));
        await tester.pump();

        // Algunas pestanias arrancan en una sub-vista que no es la que
        // interesa medir.
        for (final rotulo in aTocar) {
          final f = find.text(rotulo);
          if (f.evaluate().isNotEmpty) {
            await tester.tap(f.first, warnIfMissed: false);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 500));
            break;
          }
        }

        // Control: si la pestania no llego a dibujarse la prueba no estaria
        // mirando nada y pasaria igual.
        expect(
          find.textContaining(textoTestigo),
          findsWidgets,
          reason: '$nombre no se dibujo a $ancho',
        );
        expect(tester.takeException(), isNull, reason: '$nombre a $ancho');
      });
    }
  });

  // ── Y el ALTO, que es la mitad que faltaba ──────────────────────────────
  //
  // El barrido de arriba clava el alto en 900 y ningun telefono mide 900 de
  // alto: por eso un desborde vertical podia estar y pasar en verde once
  // veces seguidas. El del resumen del detalle congelado estaba: 360x640 se
  // pasaba 29 px con tres motivos y 320x568, 324 px con cinco.
  //
  // Se barre el dialogo y no las siete pestanias porque el dialogo es el que
  // tiene alto acotado por construccion -vive dentro de un Dialog con
  // maxHeight- mientras que las pestanias cuelgan de la pagina, que se
  // desplaza entera.
  const pantallas = <(double, double)>[
    (320, 568), // el telefono chico que todavia se usa en deposito
    (360, 640), // el Android mas comun
    (412, 732),
    (600, 480), // tablet acostada, con el teclado tapando media pantalla
    (768, 600),
    (1280, 620), // portatil con la ventana a media altura
    (1920, 720),
  ];

  final (dialogo, testigoDialogo, _) = pestanias['Detalle congelado']!;

  for (final (ancho, alto) in pantallas) {
    testWidgets('Detalle congelado sin desborde a ${ancho}x$alto', (
      tester,
    ) async {
      tester.view.physicalSize = Size(ancho, alto);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(app(dialogo));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      expect(
        find.textContaining(testigoDialogo),
        findsWidgets,
        reason: 'El dialogo no se dibujo a ${ancho}x$alto',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'Desborde a ${ancho}x$alto',
      );
    });
  }
}
