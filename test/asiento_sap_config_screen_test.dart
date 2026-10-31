import 'dart:io';

import 'package:bosque_flutter/core/state/asiento_sap_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/asiento_sap_entity.dart';
import 'package:bosque_flutter/presentation/screens/planillas/asiento_sap_config_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// La pantalla de configuración del asiento en SAP: una tarjeta por empresa, que dice
/// si está habilitada y si tiene la contraseña, y abre el formulario de edición.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Fuente parecida a la de la app (ver planillas_asiento_sap_dialog_test.dart).
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

  final esppapel = AsientoSapConfigEntity.plantilla(codEmpresa: 5);
  final config = AsientoSapConfigEntity(
    codEmpresa: 5,
    empresa: 'ESPPAPEL',
    baseSap: 'PRUEBA ESPPAPEL 2',
    linkedServer: esppapel.linkedServer,
    sp: esppapel.sp,
    paramAnio: esppapel.paramAnio,
    paramMes: esppapel.paramMes,
    colCodigo: esppapel.colCodigo,
    colNombre: esppapel.colNombre,
    colCuenta: esppapel.colCuenta,
    colDebito: esppapel.colDebito,
    colCredito: esppapel.colCredito,
    prefijosSocio: esppapel.prefijosSocio,
    memo: esppapel.memo,
    referencia: esppapel.referencia,
    campoReferencia: esppapel.campoReferencia,
    slUrl: esppapel.slUrl,
    slUsuario: 'finanzas',
    claveCargada: false,
  );

  Future<void> abrir(WidgetTester tester, Size tamano) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [asientoSapConfigProvider.overrideWith((ref) async => [config])],
        child: MaterialApp(
          builder:
              (context, child) => ResponsiveBreakpoints.builder(
                child: child!,
                breakpoints: ResponsiveUtilsBosque.breakpoints,
              ),
          home: const AsientoSapConfigScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final caso in <(String, Size)>[
    ('escritorio', const Size(1400, 900)),
    ('móvil', const Size(390, 844)),
  ]) {
    group(caso.$1, () {
      testWidgets('la tarjeta dice el estado y avisa que falta la contraseña', (
        tester,
      ) async {
        await abrir(tester, caso.$2);

        expect(tester.takeException(), isNull);
        expect(find.text('ESPPAPEL'), findsOneWidget);
        expect(find.text('Habilitada'), findsOneWidget);
        expect(find.text('Falta la contraseña'), findsOneWidget);
        // Sin contraseña no hay nada que probar.
        final probar = tester.widget<TextButton>(
          find.ancestor(of: find.text('Probar'), matching: find.bySubtype<TextButton>()),
        );
        expect(probar.onPressed, isNull);
      });

      testWidgets('Editar abre el formulario con lo guardado', (tester) async {
        await abrir(tester, caso.$2);

        await tester.tap(find.text('Editar'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Configuración de ESPPAPEL'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'PRUEBA ESPPAPEL 2'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'spAsientoSueldosDraft'), findsOneWidget);
      });
    });
  }
}
