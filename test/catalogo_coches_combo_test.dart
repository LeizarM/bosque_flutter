import 'dart:async';
import 'dart:io';

import 'package:bosque_flutter/core/state/coche_provider.dart';
import 'package:bosque_flutter/core/state/control_combustible_maquina_montacarga_provider.dart'
    show sucursalesProvider;
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:bosque_flutter/presentation/screens/catalogo-coches/catalogo_coches_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'fakes/repositorio_coches.dart';
import 'fakes/repositorio_depositos.dart' show loginAdminFalso;

/// El combo de sucursal del filtro, con el catálogo llegando tarde: es lo que
/// pasa en la app (el listado de coches y las sucursales son dos llamadas).
/// Ni al llegar el catálogo ni al elegir una opción debe saltar una excepción.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final cargador = FontLoader('Roboto');
    for (final a in ['Roboto-Regular', 'Roboto-Medium', 'Roboto-Bold']) {
      final f = File('assets/fonts/$a.ttf');
      if (f.existsSync()) {
        cargador.addFont(
          Future.value(ByteData.sublistView(f.readAsBytesSync())),
        );
      }
    }
    await cargador.load();
  });

  late Completer<List<SucursalEntity>> catalogo;

  Widget app() => ProviderScope(
    overrides: [
      userProvider.overrideWith(
        (ref) => UserStateNotifier.sinStorage(loginAdminFalso),
      ),
      cocheRepositoryProvider.overrideWithValue(RepositorioCochesFalso()),
      sucursalesProvider.overrideWith((ref) => catalogo.future),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme().getTheme(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder:
          (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: ResponsiveUtilsBosque.breakpoints,
          ),
      home: const Scaffold(body: CatalogoCochesScreen()),
    ),
  );

  Future<void> pasar(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await pasar(tester);
    await pasar(tester);
  }

  /// La opción del menú abierto: `find.text` también encuentra la celda de la
  /// tabla y la copia oculta con la que el combo mide su ancho.
  Finder opcionDelMenu(String nombre) =>
      find.widgetWithText(MenuItemButton, nombre).hitTestable().first;

  /// Abre el menú del combo tocando su campo de texto y comprueba que quedó
  /// abierto: una opción que solo existe ahí (o la copia oculta de medición)
  /// tiene que aparecer más veces de las que ya estaban en pantalla.
  Future<void> abrirMenu(WidgetTester tester) async {
    final campo = find.descendant(
      of: find.byType(DropdownMenu<int?>),
      matching: find.byType(TextField),
    );
    final antes = find.text('SANTA CRUZ').evaluate().length;
    await tester.tap(campo);
    await pasar(tester);
    expect(
      find.text('SANTA CRUZ').evaluate().length,
      greaterThan(antes),
      reason: 'el menú del combo no se abrió',
    );
  }

  List<SucursalEntity> variasSucursales() => [
    sucursalFalsa(-1, '-- Defina Nueva Sucursal --'),
    for (var i = 1; i <= 12; i++) sucursalFalsa(100 + i, 'SUCURSAL $i'),
    ...sucursalesDeEjemplo(),
  ];

  setUp(() => catalogo = Completer<List<SucursalEntity>>());

  testWidgets('el catálogo llega con el combo cerrado', (tester) async {
    await abrir(tester);

    catalogo.complete(variasSucursales());
    await pasar(tester);
    await pasar(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Gestión de vehículos'), findsOneWidget);
  });

  testWidgets('el catálogo llega con el menú del combo abierto', (
    tester,
  ) async {
    await abrir(tester);

    await abrirMenu(tester);

    catalogo.complete(variasSucursales());
    await pasar(tester);
    await pasar(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('elegir una sucursal con el catálogo ya cargado', (tester) async {
    catalogo.complete(variasSucursales());
    await abrir(tester);

    await abrirMenu(tester);
    await tester.tap(opcionDelMenu('COCHABAMBA'));
    await pasar(tester);
    await pasar(tester);

    expect(tester.takeException(), isNull);
    // El filtro quedó puesto: «N de total», con N los de la sucursal 23.
    final todos = cochesDeEjemplo();
    final deLaSucursal = todos.where((c) => c.codSucursal == 23).length;
    expect(find.text('$deLaSucursal de ${todos.length} vehículos'), findsOneWidget);
  });

  testWidgets('elegir una sucursal antes de que llegue el catálogo', (
    tester,
  ) async {
    await abrir(tester);

    await abrirMenu(tester);
    await tester.tap(opcionDelMenu('COCHABAMBA'));
    await pasar(tester);

    catalogo.complete(variasSucursales());
    await pasar(tester);
    await pasar(tester);

    expect(tester.takeException(), isNull);
  });
}
