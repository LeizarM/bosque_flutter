import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/estado_periodo_entity.dart';
import 'package:bosque_flutter/domain/entities/preliminar_comision_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_cambio_comision_entity.dart';
import 'package:bosque_flutter/domain/repositories/comisiones_repository.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/tab_preliminar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Qué muestra el Preliminar de un período que ya se pagó.
///
/// El síntoma real: en 07/2026 —690 filas en `tcom_pagado`— la pantalla decía
/// «Bs 0.00», «0 vendedores», «0 líneas de detalle» y dibujaba un gráfico en
/// blanco. Eso se lee como «no hay datos» o como «se rompió algo», cuando la
/// verdad es lo contrario: el preliminar lista notas **cerradas y sin pagar**,
/// y al ejecutar el período esas notas pasan a `tcom_pagado`. Quedar en cero es
/// el comportamiento correcto; lo que faltaba era decirlo.
///
/// Ojo con la causa de que el estado vacío no se disparara: el SP devuelve la
/// fila de TOTAL aunque no haya un solo vendedor, así que `filas.isEmpty` era
/// `false` y la pantalla se iba por la rama del resumen. La condición correcta
/// mira el detalle, no las filas.
class _RepoFalso implements ComisionesRepository {
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('Este test no debería llamar a ${i.memberName}');
}

void main() {
  // La fila de total que el SP manda siempre. Es la que hacía que
  // `filas.isEmpty` fuera false con la pantalla vacía a la vista.
  //
  // `esTotal` no es un campo: la entidad lo deriva de `ord >= 2`. Por eso el
  // total lleva ord 999 y el detalle ord 1.
  const filaTotal = PreliminarComisionEntity(
    ord: 999,
    idVendedor: 0,
    mes: 7,
    anio: 2026,
    etiqueta: 'TOTAL',
    nombreVen: 'TOTAL',
    comision: 0,
    ignoraComision: 0,
    montoBase: 0,
    bsAPagar: 0,
    usdAPagar: 0,
  );

  const unVendedor = PreliminarComisionEntity(
    ord: 1,
    idVendedor: 39,
    mes: 7,
    anio: 2026,
    etiqueta: 'Administracion Comercial',
    nombreVen: 'Humberto de la Torre Villavicencio',
    comision: 0.0068,
    ignoraComision: 0,
    montoBase: 3949639.10,
    bsAPagar: 20437.45,
    usdAPagar: 1777.17,
  );

  EstadoPeriodoEntity estado({required bool ejecutado}) => EstadoPeriodoEntity(
    mes: 7,
    anio: 2026,
    esInterno: 1,
    ejecutado: ejecutado ? 1 : 0,
    cantidadPagados: ejecutado ? 690 : 0,
    fechaEjecucion: ejecutado ? DateTime(2026, 8, 12) : null,
    totalComision: ejecutado ? 24999.28 : 0,
  );

  Future<void> montar(
    WidgetTester tester, {
    required List<PreliminarComisionEntity> filas,
    required bool ejecutado,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          comisionesRepositoryProvider.overrideWithValue(_RepoFalso()),
          preliminarProvider.overrideWith((ref, f) async => filas),
          estadoPeriodoProvider.overrideWith(
            (ref, clave) async => estado(ejecutado: ejecutado),
          ),
          filtroPreliminarProvider.overrideWith(
            (ref) => FiltroPreliminar(
              modalidad: ModalidadPreliminar.dinamicaVigente,
              mes: 7,
              anio: 2026,
              tc: 11.5,
            ),
          ),
          tipoCambioSugeridoProvider.overrideWith(
            (ref) async => TipoCambioComisionEntity(
              fecha: DateTime(2026, 8, 23),
              tipoCambio: 11.5,
              origen: 'SAP',
              diasDeAntiguedad: 0,
            ),
          ),
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
                    body: TabPreliminar(
                      modalidades: ModalidadPreliminar.values,
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('período ejecutado y sin detalle: lo dice y manda al reporte', (
    tester,
  ) async {
    await montar(tester, filas: const [filaTotal], ejecutado: true);

    expect(
      find.textContaining('ya fue ejecutado'),
      findsOneWidget,
      reason:
          'Un período pagado sigue mostrándose como si no hubiera datos. Es '
          'el caso de 07/2026: 690 filas en tcom_pagado y la pantalla en cero.',
    );
    expect(
      find.textContaining('Pagadas internas'),
      findsWidgets,
      reason:
          'El mensaje tiene que nombrar el botón del reporte; si no, dice qué '
          'pasa pero no a dónde ir.',
    );
    expect(
      find.textContaining('12/08/2026'),
      findsOneWidget,
      reason: 'Cuando se conoce la fecha del pago, se muestra.',
    );

    // Y NO el resumen en cero, que es lo que confundía.
    expect(
      find.textContaining('líneas de detalle'),
      findsNothing,
      reason:
          'Volvió a pintarse el resumen en cero: la condición de vacío está '
          'mirando `filas` otra vez, y el SP siempre manda la fila de total.',
    );
  });

  testWidgets('período NO ejecutado y sin detalle: el mensaje de siempre', (
    tester,
  ) async {
    await montar(tester, filas: const [filaTotal], ejecutado: false);

    expect(
      find.textContaining('Sin comisiones para este período'),
      findsOneWidget,
    );
    expect(
      find.textContaining('ya fue ejecutado'),
      findsNothing,
      reason:
          'Un mes sin notas no está pagado: mandarlo al reporte de pagadas es '
          'mandarlo a un PDF vacío.',
    );
  });

  testWidgets('período ejecutado CON notas: avisa, pero muestra el detalle', (
    tester,
  ) async {
    await montar(tester, filas: const [unVendedor, filaTotal], ejecutado: true);

    expect(
      find.textContaining('Humberto de la Torre Villavicencio'),
      findsWidgets,
      reason: 'Hay notas posteriores al pago: tienen que verse.',
    );
    expect(
      find.textContaining('entraron después del pago'),
      findsOneWidget,
      reason:
          'Sin el aviso, estas pocas notas se leen como el mes completo y el '
          'número no cuadra contra la planilla ya firmada.',
    );
  });

  testWidgets('período NO ejecutado con notas: sin avisos de más', (
    tester,
  ) async {
    await montar(
      tester,
      filas: const [unVendedor, filaTotal],
      ejecutado: false,
    );

    expect(
      find.textContaining('Humberto de la Torre Villavicencio'),
      findsWidgets,
    );
    expect(
      find.textContaining('ya fue ejecutado'),
      findsNothing,
      reason: 'El caso normal no lleva ningún aviso.',
    );
  });
}
