import 'dart:io';

import 'package:bosque_flutter/core/state/asiento_sap_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/asiento_sap_entity.dart';
import 'package:bosque_flutter/presentation/widgets/planillas/planillas_asiento_sap_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// El diálogo del asiento de planilla en SAP con una vista previa del tamaño real
/// (35 líneas), en escritorio y en teléfono. Las empresas salen de la configuración
/// del backend: con una sola, no hay nada que elegir.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // La fuente de reemplazo de flutter test mide todos los glifos igual y ensancha el
  // texto; como en talonarios_seleccion_empresa_test, se registra PlusJakartaSans con
  // el nombre Roboto para medir parecido a la app y que los desbordes sean reales.
  setUpAll(() async {
    final cargador = FontLoader('Roboto');
    for (final peso in ['400', '500', '600', '700']) {
      final f = File('assets/fonts/PlusJakartaSans-$peso.ttf');
      if (f.existsSync()) {
        cargador.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      }
    }
    await cargador.load();
  });

  AsientoSapEntity asiento({bool cuadra = true}) => AsientoSapEntity(
    anio: 2026,
    mes: 10,
    codEmpresa: 5,
    empresa: 'ESPPAPEL',
    baseSap: 'PRUEBA ESPPAPEL 2',
    fecha: '2026-10-30',
    memo: 'Asiento de Planilla - Periodo 10/2026',
    referencia: 'PLANILLA-2026-10',
    lineas: [
      for (var i = 0; i < 34; i++)
        AsientoSapLineaEntity(
          codigo: '61101${i.toString().padLeft(2, '0')}',
          nombre: 'Sueldos Administrativos Of. Central $i',
          cuenta: '61101${i.toString().padLeft(2, '0')}',
          debito: 1000,
          credito: 0,
        ),
      const AsientoSapLineaEntity(
        codigo: 'SU00464',
        nombre: 'SUELDOS Y SALARIOS',
        cuenta: '2120101',
        socio: 'SU00464',
        debito: 0,
        credito: 34000,
      ),
    ],
    totalDebito: 34000,
    totalCredito: cuadra ? 34000 : 33999.93,
    diferencia: cuadra ? 0 : 0.07,
    cuadra: cuadra,
  );

  const esppapel = AsientoSapEmpresaEntity(codEmpresa: 5, empresa: 'ESPPAPEL');
  const impexpap = AsientoSapEmpresaEntity(codEmpresa: 1, empresa: 'IMPEXPAP');

  Future<void> abrir(
    WidgetTester tester, {
    required Size tamano,
    required List<AsientoSapEmpresaEntity> empresas,
    AsientoSapEntity? datos,
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          asientoSapEmpresasProvider.overrideWith((ref) async => empresas),
          asientoSapVistaPreviaProvider.overrideWith(
            (ref, p) async => datos ?? asiento(),
          ),
        ],
        child: MaterialApp(
          builder:
              (context, child) => ResponsiveBreakpoints.builder(
                child: child!,
                breakpoints: ResponsiveUtilsBosque.breakpoints,
              ),
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => TextButton(
                    onPressed:
                        () => showDialog(
                          context: context,
                          builder:
                              (_) => const PlanillasAsientoSapDialog(
                                mes: 10,
                                anio: 2026,
                                nombreMes: 'OCTUBRE',
                              ),
                        ),
                    child: const Text('abrir'),
                  ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  FilledButton botonEnviar(WidgetTester tester) => tester.widget<FilledButton>(
    find.ancestor(
      of: find.text('Enviar a SAP'),
      matching: find.bySubtype<FilledButton>(),
    ),
  );

  for (final caso in <(String, Size)>[
    ('escritorio', const Size(1909, 1025)),
    ('móvil', const Size(390, 844)),
  ]) {
    group(caso.$1, () {
      testWidgets('con una sola empresa muestra la vista previa sin elegir', (
        tester,
      ) async {
        await abrir(tester, tamano: caso.$2, empresas: [esppapel]);

        expect(tester.takeException(), isNull);
        expect(find.text('Cuadra'), findsOneWidget);
        expect(find.text('35 líneas'), findsOneWidget);
        expect(botonEnviar(tester).onPressed, isNotNull);
      });

      testWidgets('un asiento descuadrado no se puede enviar', (tester) async {
        await abrir(
          tester,
          tamano: caso.$2,
          empresas: [esppapel],
          datos: asiento(cuadra: false),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('No cuadra'), findsOneWidget);
        expect(botonEnviar(tester).onPressed, isNull);
      });

      testWidgets('con varias empresas espera a que se elija una', (tester) async {
        await abrir(tester, tamano: caso.$2, empresas: [esppapel, impexpap]);

        expect(find.text('Cuadra'), findsNothing);
        expect(botonEnviar(tester).onPressed, isNull);

        await tester.tap(find.byType(DropdownButtonFormField<int>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ESPPAPEL').last);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Cuadra'), findsOneWidget);
      });

      testWidgets('sin empresas configuradas dice dónde configurarlas', (
        tester,
      ) async {
        await abrir(tester, tamano: caso.$2, empresas: const []);

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Asiento SAP: configuración'), findsOneWidget);
        expect(botonEnviar(tester).onPressed, isNull);
      });
    });
  }
}
