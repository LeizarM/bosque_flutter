// Capturas del modulo de garantias de cobranza, para mirarlas.
//
// NO es una prueba: no afirma nada y `flutter test` no la levanta solo (el
// nombre no termina en _test.dart). Se corre a mano:
//
//   flutter test test/capturas/capturas_garantias.dart --dart-define=CAPTURAS=<carpeta>
//
// Usa el repositorio falso de test/fakes/repositorio_garantias.dart (datos de
// ejemplo coherentes, sin backend ni login) y las fuentes reales del proyecto:
// con la de prueba de Flutter cada letra es un rectangulo y no se puede juzgar
// nada.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bosque_flutter/core/state/garantias_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/presentation/screens/garantias/garantias_screen.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/detalle_garantia.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/formularios_garantia.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/garantias_cliente.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/piezas_garantias.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../fakes/repositorio_garantias.dart';

const _salida = String.fromEnvironment(
  'CAPTURAS',
  defaultValue: 'build/capturas_garantias',
);

final _admin = LoginEntity.fromJson(<String, dynamic>{
  'tipoUsuario': 'ROLE_ADM',
  'codUsuario': 34,
  'nombreCompleto': 'ZEBALLOS ZUE HELEN SCARLET',
});

Future<void> _cargarFuentes() async {
  final dir = Directory('assets/fonts');
  final porFamilia = <String, List<File>>{};
  for (final f in dir.listSync().whereType<File>()) {
    final nombre = f.uri.pathSegments.last;
    if (!nombre.endsWith('.ttf') && !nombre.endsWith('.otf')) continue;
    porFamilia.putIfAbsent(nombre.split('-').first, () => []).add(f);
  }
  for (final e in porFamilia.entries) {
    final loader = FontLoader(e.key);
    for (final f in e.value) {
      loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
    await loader.load();
  }
  final iconos = File(
    '${Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter'}/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  if (iconos.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(
      Future.value(ByteData.sublistView(iconos.readAsBytesSync())),
    )).load();
  }
}

Future<void> _capturar(
  WidgetTester tester,
  String nombre,
  Widget pantalla, {
  Size tam = const Size(1440, 900),
  Future<void> Function(WidgetTester tester)? antes,
  bool oscuro = false,
}) async {
  tester.view.physicalSize = tam;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // En las pruebas Flutter cambia cada sombra por un trazo negro grueso
  // (debugDisableShadows): los menus salian con un marco que la app no tiene.
  // Se vuelve a su valor antes de terminar, porque la prueba lo verifica.
  debugDisableShadows = false;
  try {
    await _dibujarYGuardar(
      tester,
      nombre,
      pantalla,
      antes: antes,
      oscuro: oscuro,
    );
  } finally {
    debugDisableShadows = true;
  }
}

Future<void> _dibujarYGuardar(
  WidgetTester tester,
  String nombre,
  Widget pantalla, {
  Future<void> Function(WidgetTester tester)? antes,
  required bool oscuro,
}) async {
  final tema = AppTheme().getTheme();
  final clave = GlobalKey();
  // Arbol nuevo en cada captura: sin capas pintadas por la anterior.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProvider.overrideWith(
          (ref) => UserStateNotifier.sinStorage(_admin),
        ),
        garantiasRepositoryProvider.overrideWithValue(
          RepositorioGarantiasFalso(),
        ),
      ],
      child: RepaintBoundary(
        key: clave,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme:
              oscuro
                  ? ThemeData(
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: tema.colorScheme.primary,
                      brightness: Brightness.dark,
                    ),
                  )
                  : tema,
          home: pantalla,
          builder:
              (context, child) => ResponsiveBreakpoints.builder(
                child: child!,
                breakpoints: ResponsiveUtilsBosque.breakpoints,
              ),
        ),
      ),
    ),
  );

  Future<void> dejarQueCargue() async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  await dejarQueCargue();
  if (antes != null) {
    await antes(tester);
    await dejarQueCargue();
  }

  await tester.runAsync(() async {
    final boundary =
        clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final imagen = await boundary.toImage(pixelRatio: 1);
    final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
    File('$_salida/$nombre.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
  // Deja vencer los temporizadores de la carga real de permisos.
  await tester.pump(const Duration(minutes: 2));
}

/// Pantalla con un boton que abre un panel (showDialog necesita contexto).
Widget _lanzador(Future<void> Function(BuildContext) abrir) => Scaffold(
  body: Builder(
    builder:
        (context) => Center(
          child: FilledButton(
            onPressed: () => abrir(context),
            child: const Text('abrir'),
          ),
        ),
  ),
);

Future<void> _tocarAbrir(WidgetTester t) async {
  await t.tap(find.text('abrir'));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _cargarFuentes();
    dotenv.testLoad(fileInput: 'BASE_URL_DEV=http://capturas.local');
  });

  const tablet = Size(800, 1100);
  const telefono = Size(390, 844);

  testWidgets('principal', (t) async {
    await _capturar(t, 'principal_escritorio', const GarantiasScreen());
    await _capturar(
      t,
      'principal_tablet',
      const GarantiasScreen(),
      tam: tablet,
    );
    await _capturar(
      t,
      'principal_telefono',
      const GarantiasScreen(),
      tam: telefono,
    );
  });

  testWidgets('principal por garantia', (t) async {
    Future<void> alternar(WidgetTester t) async {
      final boton = find.textContaining('Por garantía');
      if (boton.evaluate().isNotEmpty) await t.tap(boton.first);
    }

    await _capturar(
      t,
      'garantias_escritorio',
      const GarantiasScreen(),
      antes: alternar,
    );
    await _capturar(
      t,
      'garantias_tablet',
      const GarantiasScreen(),
      tam: tablet,
      antes: alternar,
    );
    await _capturar(
      t,
      'garantias_telefono',
      const GarantiasScreen(),
      tam: telefono,
      antes: alternar,
    );
    await _capturar(
      t,
      'garantias_filtro_90_dias',
      const GarantiasScreen(),
      antes: (t) async {
        await alternar(t);
        await t.pump(const Duration(milliseconds: 300));
        await t.tap(find.text('Filtrar por fechas'));
        await t.pump(const Duration(milliseconds: 300));
        await t.tap(find.text('Vencen en los próximos 90 días'));
      },
    );
    await _capturar(
      t,
      'garantias_escritorio_oscuro',
      const GarantiasScreen(),
      antes: alternar,
      oscuro: true,
    );
  });

  testWidgets('paneles', (t) async {
    final repo = RepositorioGarantiasFalso();
    final resumen = await t.runAsync(() => repo.obtenerResumenClientes());

    await _capturar(
      t,
      'cliente_escritorio',
      _lanzador((c) => abrirGarantiasCliente(c, resumen!.first)),
      antes: _tocarAbrir,
    );
    Future<void> abrirMenu(WidgetTester t) async {
      await _tocarAbrir(t);
      for (var i = 0; i < 8; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.tap(find.byTooltip('Más acciones').first);
    }

    await _capturar(
      t,
      'cliente_menu_escritorio',
      _lanzador((c) => abrirGarantiasCliente(c, resumen!.first)),
      antes: abrirMenu,
    );
    await _capturar(
      t,
      'cliente_menu_telefono',
      _lanzador((c) => abrirGarantiasCliente(c, resumen!.first)),
      tam: telefono,
      antes: abrirMenu,
    );
    await _capturar(
      t,
      'detalle_escritorio',
      _lanzador((c) => abrirDetalleGarantia(c, BigInt.from(162))),
      antes: _tocarAbrir,
    );
    await _capturar(
      t,
      'detalle_telefono',
      _lanzador((c) => abrirDetalleGarantia(c, BigInt.from(188))),
      tam: telefono,
      antes: _tocarAbrir,
    );
    await _capturar(
      t,
      'alta_escritorio',
      _lanzador((c) => abrirAltaGarantia(c)),
      antes: _tocarAbrir,
    );
    await _capturar(
      t,
      'guia_escritorio',
      _lanzador((c) => mostrarGuiaGarantias(c)),
      antes: _tocarAbrir,
    );
  });
}
