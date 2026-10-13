import 'dart:async';
import 'dart:io';

import 'package:bosque_flutter/core/state/coche_provider.dart';
import 'package:bosque_flutter/core/state/control_combustible_maquina_montacarga_provider.dart'
    show sucursalesProvider;
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/coche_entity.dart';
import 'package:bosque_flutter/presentation/screens/catalogo-coches/catalogo_coches_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'fakes/repositorio_coches.dart';
import 'fakes/repositorio_depositos.dart' show loginAdminFalso;

/// Ciclo de vida de «Gestión de vehículos»: lo que pasa cuando la respuesta del
/// servidor llega con la pantalla ya desmontada, con la ficha cerrada, o después
/// de un hot reload. Ninguno debe dejar una excepción ni perder un error sin
/// mostrarlo.
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

  late _RepoConPuertas repo;
  late ValueNotifier<bool> pantallaPuesta;
  var llamadasCatalogo = 0;
  var catalogoFalla = false;

  setUp(() {
    repo = _RepoConPuertas();
    pantallaPuesta = ValueNotifier<bool>(true);
    llamadasCatalogo = 0;
    catalogoFalla = false;
  });

  Widget app() => ProviderScope(
    overrides: [
      userProvider.overrideWith(
        (ref) => UserStateNotifier.sinStorage(loginAdminFalso),
      ),
      cocheRepositoryProvider.overrideWithValue(repo),
      sucursalesProvider.overrideWith((ref) async {
        llamadasCatalogo++;
        if (catalogoFalla) throw Exception('sin red');
        return sucursalesDeEjemplo();
      }),
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
      home: Scaffold(
        // La pantalla se quita y se pone sin tocar el ProviderScope: es lo que
        // hace el router al cambiar de página con el servidor todavía respondiendo.
        body: ValueListenableBuilder<bool>(
          valueListenable: pantallaPuesta,
          builder:
              (_, puesta, __) =>
                  puesta ? const CatalogoCochesScreen() : const SizedBox(),
        ),
      ),
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

  /// Lo que hace un hot reload: reensambla todo el árbol. El futuro solo
  /// completa cuando se dibuja el cuadro, de ahí el `pump` antes del `await`.
  Future<void> recargarEnCaliente(WidgetTester tester) async {
    final listo = tester.binding.reassembleApplication();
    await tester.pump();
    await listo;
    await pasar(tester);
  }

  /// Abre la ficha de alta y la llena con datos válidos.
  Future<void> llenarFichaDeAlta(WidgetTester tester) async {
    await tester.tap(find.text('Nuevo vehículo'));
    await pasar(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Placa *'),
      'ZZZ-001',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Marca *'),
      'Foton',
    );
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await pasar(tester);
    await tester.tap(find.text('COCHABAMBA').last);
    await pasar(tester);
  }

  testWidgets('la lectura inicial llega con la pantalla ya quitada', (
    tester,
  ) async {
    repo.puertaObtener = Completer<void>();
    await abrir(tester);

    pantallaPuesta.value = false;
    await pasar(tester);

    repo.puertaObtener!.complete();
    await pasar(tester);
    await pasar(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('un error de lectura llega con la pantalla ya quitada', (
    tester,
  ) async {
    repo.puertaObtener = Completer<void>();
    await abrir(tester);

    pantallaPuesta.value = false;
    await pasar(tester);

    repo.puertaObtener!.completeError(Exception('sin red'));
    await pasar(tester);
    await pasar(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('el guardado termina con la pantalla ya quitada', (tester) async {
    await abrir(tester);
    await llenarFichaDeAlta(tester);

    repo.puertaRegistrar = Completer<void>();
    await tester.tap(find.text('Crear vehículo'));
    await pasar(tester);

    pantallaPuesta.value = false;
    await pasar(tester);

    repo.puertaRegistrar!.complete();
    await pasar(tester);
    await pasar(tester);

    expect(tester.takeException(), isNull);
    expect(repo.registrados, hasLength(1), reason: 'el guardado no se pierde');
  });

  testWidgets('recargar dos veces seguidas no pisa la respuesta nueva', (
    tester,
  ) async {
    await abrir(tester);
    expect(find.text('7 vehículos, 6 activos'), findsOneWidget);

    // La 1.ª recarga se queda esperando; la 2.ª sale rápido con un coche más.
    final lenta = Completer<void>();
    repo.puertaObtener = lenta;
    await tester.tap(find.byTooltip('Volver a traer el listado'));
    await tester.pump();

    repo.puertaObtener = null;
    repo.coches.add(
      cocheFalso(
        99,
        sucursal: 20,
        nombreSucursal: 'CENTRAL',
      ).copyWith(placa: 'NNN-999'),
    );
    // El botón queda apagado mientras carga: se pide por el notificador, que es
    // lo que hace «Reintentar».
    final contenedor = ProviderScope.containerOf(
      tester.element(find.byType(CatalogoCochesScreen)),
    );
    await contenedor.read(cocheProvider.notifier).cargar();
    await pasar(tester);
    expect(find.text('8 vehículos, 7 activos'), findsOneWidget);

    // Ahora llega la vieja: no debe pisar a la nueva.
    lenta.complete();
    await pasar(tester);
    await pasar(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('8 vehículos, 7 activos'), findsOneWidget);
  });

  testWidgets('el botón de recargar reintenta un catálogo que falló', (
    tester,
  ) async {
    catalogoFalla = true;
    await abrir(tester);
    expect(find.text('No se pudo cargar el catálogo completo'), findsOneWidget);
    expect(llamadasCatalogo, 1);

    // El servidor vuelve: sin reintento, el error se quedaría toda la sesión.
    catalogoFalla = false;
    await tester.tap(find.byTooltip('Volver a traer el listado'));
    await pasar(tester);
    await pasar(tester);

    expect(llamadasCatalogo, 2);
    expect(find.text('No se pudo cargar el catálogo completo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hot reload con la ficha abierta no lanza', (tester) async {
    await abrir(tester);
    await llenarFichaDeAlta(tester);

    await recargarEnCaliente(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Placa *'), findsOneWidget);
  });

  testWidgets('hot reload con el menú de sucursal abierto no lanza', (
    tester,
  ) async {
    await abrir(tester);

    final campo = find.descendant(
      of: find.byType(DropdownMenu<int?>),
      matching: find.byType(TextField),
    );
    await tester.tap(campo);
    await pasar(tester);

    await recargarEnCaliente(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('no se puede cerrar la ficha con el guardado en curso', (
    tester,
  ) async {
    await abrir(tester);
    await llenarFichaDeAlta(tester);

    repo.puertaRegistrar = Completer<void>();
    await tester.tap(find.text('Crear vehículo'));
    await pasar(tester);

    // Un toque fuera de la ficha (el velo) la cerraría.
    await tester.tapAt(const Offset(8, 8));
    await pasar(tester);
    expect(
      find.text('Placa *'),
      findsOneWidget,
      reason: 'cerrarla ahora perdería el motivo si el servidor rechaza',
    );

    repo.puertaRegistrar!.complete();
    await pasar(tester);
    await pasar(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Placa *'), findsNothing, reason: 'cerró al guardar');
  });
}

/// El repositorio falso, con «puertas»: la operación espera a que la prueba la
/// abra, para simular la respuesta lenta del servidor.
class _RepoConPuertas extends RepositorioCochesFalso {
  Completer<void>? puertaObtener;
  Completer<void>? puertaRegistrar;

  @override
  Future<List<CocheEntity>> obtener({int? codSucursal, int? estado}) async {
    final p = puertaObtener;
    if (p != null) await p.future;
    return super.obtener(codSucursal: codSucursal, estado: estado);
  }

  @override
  Future<BigInt> registrar(CocheEntity item) async {
    final p = puertaRegistrar;
    if (p != null) await p.future;
    return super.registrar(item);
  }
}
