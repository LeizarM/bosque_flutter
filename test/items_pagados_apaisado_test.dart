import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/pagado_item_entity.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/dialogo_items_pagados.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// El diálogo del detalle congelado en un teléfono **acostado**.
///
/// Este archivo existe porque las dos matrices que ya había —la del diálogo y
/// la del módulo— barren el ANCHO y clavan el ALTO en 900. Ningún teléfono mide
/// 900 de alto, y un 360×640 girado es **640×360**. Ese eje no se medía, y ahí
/// vivía un desborde que sobrevivió a dos arreglos:
///
/// * 640×360 y 800×360 → `RenderFlex overflowed by 9.6 pixels`
/// * 568×320 → 66 px, y **42 px incluso con el resumen vacío**
///
/// Esa última fila es la que descarta la explicación fácil: no era cuánto se
/// llevaba el resumen. `_BarraFiltros` era hijo rígido del mismo `Column` y el
/// único `Flexible` era la lista, así que al no entrar la lista se encogía a
/// cero y el `Column` desbordaba igual.
///
/// Los casos van con el **resumen de cinco motivos**, que es el máximo real que
/// puede devolver la rama `R`: `DESCONTO` más los cuatro motivos de exclusión.
void main() {
  PagadoItemEntity item(int i) => PagadoItemEntity(
    idPagadoItem: i,
    idPagado: 1,
    mesPago: 8,
    anioPago: 2026,
    esInterno: 1,
    docNum: 262211852,
    origen: 'IMPEXPAP',
    itemCode: 'PBB0560670870AS$i',
    itemName: 'PAPEL BOND BLANCO 056G 067X087CM 500HJS PRISME',
    idGrpFamiliaSap: 10,
    grpFam: 'Papel Bond Blanco',
    cantidad: 50,
    montoLineaBs: 12435,
    aplicaDescuento: false,
    descuentoBs: 0,
    motivoExclusion: 'FAMILIA_SIN_POLITICA',
  );

  /// Los cinco motivos posibles. Es el peor caso del panel de arriba.
  final resumenCompleto = <PagadoItemResumenEntity>[
    const PagadoItemResumenEntity(
      motivo: 'DESCONTO',
      items: 1,
      montoBs: 12435,
      descuentoBs: 6217.5,
    ),
    for (final m in [
      'VENDEDOR_EXENTO',
      'SIN_FAMILIA',
      'FAMILIA_SIN_POLITICA',
      'FUERA_DE_VIGENCIA',
    ])
      PagadoItemResumenEntity(
        motivo: m,
        items: 3,
        montoBs: 1231,
        descuentoBs: 0,
      ),
  ];

  Future<void> montar(
    WidgetTester tester,
    Size medida, {
    required List<PagadoItemResumenEntity> resumen,
  }) async {
    tester.view.physicalSize = medida;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemsPagadosProvider.overrideWith(
            (ref, f) async => [for (var i = 1; i <= 12; i++) item(i)],
          ),
          resumenItemsPagadosProvider.overrideWith((ref, f) async => resumen),
          corteItemsPagadosProvider.overrideWith((ref, f) async => null),
        ],
        child: MaterialApp(
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
                    body: DialogoItemsPagados(
                      filtro: FiltroItemsPagados(
                        mes: 8,
                        anio: 2026,
                        esInterno: 1,
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Los tres que rompían. 732×412, 851×393 y 915×412 ya pasaban: se dejan
  // igual, porque un caso que nunca falló también avisa si algo los rompe.
  const apaisados = <Size>[
    Size(568, 320), // iPhone SE acostado
    Size(640, 360), // 360×640 acostado, el más común
    Size(800, 360), // 360×800 acostado
    Size(732, 412),
    Size(851, 393),
    Size(915, 412),
  ];

  for (final medida in apaisados) {
    testWidgets(
      'sin desborde a ${medida.width.toInt()}x${medida.height.toInt()} '
      'con los cinco motivos',
      (tester) async {
        await montar(tester, medida, resumen: resumenCompleto);
        expect(
          tester.takeException(),
          isNull,
          reason:
              'Desbordó a ${medida.width.toInt()}x${medida.height.toInt()}. '
              'El cuerpo tiene que poder desplazarse cuando el alto no '
              'alcanza, en vez de encoger la lista a cero.',
        );
      },
    );
  }

  // El control que descarta «es culpa del resumen». Con el panel de arriba
  // vacío el desborde igual aparecía: la causa estaba en la barra de filtros,
  // que era hija rígida del mismo Column.
  testWidgets('sin desborde a 568x320 con el resumen VACÍO', (tester) async {
    await montar(tester, const Size(568, 320), resumen: const []);
    expect(
      tester.takeException(),
      isNull,
      reason:
          'Desbordó con el resumen vacío. Si esto falla, el arreglo volvió a '
          'apostar a que el problema era cuánto espacio se lleva el resumen.',
    );
  });
}
