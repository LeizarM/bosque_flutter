import 'dart:io';

import 'package:bosque_flutter/core/state/coche_provider.dart';
import 'package:bosque_flutter/core/state/control_combustible_maquina_montacarga_provider.dart'
    show sucursalesProvider;
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/presentation/screens/catalogo-coches/catalogo_coches_screen.dart';
import 'package:bosque_flutter/presentation/widgets/catalogo-coches/tarjeta_coche.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'fakes/repositorio_coches.dart';
import 'fakes/repositorio_depositos.dart' show loginAdminFalso;

/// La pantalla «Gestión de vehículos» con un repositorio falso: que abra sin
/// desbordes en teléfono, tablet y escritorio, que elija tabla o tarjetas por el
/// ancho del cajón, y que alta, baja y eliminación hagan lo que prometen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorioCochesFalso repo;

  // La fuente de reemplazo de flutter test ensancha el texto y desborda filas
  // que con Roboto sobran: con la real, los desbordes que aparecen son reales.
  setUpAll(() async {
    const archivos = ['Roboto-Regular', 'Roboto-Medium', 'Roboto-Bold'];
    final cargador = FontLoader('Roboto');
    for (final archivo in archivos) {
      final f = File('assets/fonts/$archivo.ttf');
      if (f.existsSync()) {
        cargador.addFont(
          Future.value(ByteData.sublistView(f.readAsBytesSync())),
        );
      }
    }
    await cargador.load();
  });

  setUp(() => repo = RepositorioCochesFalso());

  Widget app() => ProviderScope(
    overrides: [
      userProvider.overrideWith(
        (ref) => UserStateNotifier.sinStorage(loginAdminFalso),
      ),
      cocheRepositoryProvider.overrideWithValue(repo),
      sucursalesProvider.overrideWith((ref) async => sucursalesDeEjemplo()),
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
      // En la app vive dentro del Scaffold del dashboard y se monta cuando los
      // breakpoints ya se resolvieron.
      home: const Scaffold(
        body: _UnFotogramaDespues(child: CatalogoCochesScreen()),
      ),
    ),
  );

  Future<void> esperar(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> abrir(
    WidgetTester tester, {
    double ancho = 1400,
    double alto = 900,
  }) async {
    tester.view.physicalSize = Size(ancho, alto);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    // pump() y no pumpAndSettle(): el esqueleto anima en bucle.
    await esperar(tester);
    await esperar(tester);
  }

  // ── Sin desbordes y con el diseño que corresponde a cada ancho ──────────

  for (final ancho in [390.0, 600.0, 800.0, 1400.0]) {
    testWidgets('abre sin desborde a ${ancho.toInt()} px', (tester) async {
      // `takeException` no dice en qué widget ocurrió el desborde: se captura
      // el error completo para poder ubicarlo.
      final errores = <FlutterErrorDetails>[];
      final previo = FlutterError.onError;
      FlutterError.onError = errores.add;

      await abrir(tester, ancho: ancho, alto: ancho <= 450 ? 844 : 900);
      // Antes de cualquier expect: el binding exige el handler original.
      FlutterError.onError = previo;

      // Control: si no se dibujó, la prueba no estaría midiendo nada.
      expect(find.text('Gestión de vehículos'), findsOneWidget);
      // La primera por placa: en el teléfono la lista es perezosa y la última
      // todavía no se construyó.
      expect(find.text('1053-FKE'), findsWidgets);
      for (final e in errores) {
        debugPrint('DETALLE a $ancho:\n$e');
      }
      expect(errores, isEmpty, reason: 'ancho $ancho');
    });
  }

  testWidgets('desde 720 px dibuja la tabla, con columnas y acciones', (
    tester,
  ) async {
    await abrir(tester, ancho: 800);

    expect(find.text('PLACA'), findsOneWidget);
    expect(find.text('SUCURSAL'), findsOneWidget);
    expect(find.byType(TarjetaCoche), findsNothing);
    expect(find.byTooltip('Editar el vehículo 917-SKP'), findsOneWidget);
    expect(find.text('7 vehículos, 6 activos'), findsOneWidget);
  });

  testWidgets('debajo de 720 px dibuja tarjetas y no hay tabla', (tester) async {
    await abrir(tester, ancho: 390, alto: 844);

    expect(find.byType(TarjetaCoche), findsWidgets);
    expect(find.text('PLACA'), findsNothing);
    // Los filtros quedan plegados y el botón de alta es el flotante.
    expect(find.text('Filtros'), findsOneWidget);
    expect(find.text('Nuevo'), findsOneWidget);
  });

  // ── Estados de la lista ─────────────────────────────────────────────────

  testWidgets('sin vehículos explica qué hacer', (tester) async {
    repo = RepositorioCochesFalso(coches: const []);
    await abrir(tester);

    expect(find.text('Todavía no hay vehículos registrados'), findsOneWidget);
  });

  testWidgets('un fallo de lectura ofrece reintentar y se recupera', (
    tester,
  ) async {
    repo.falloAlObtener = Exception('Sin conexión con el servidor.');
    await abrir(tester);

    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    repo.falloAlObtener = null;
    await tester.tap(find.text('Reintentar'));
    await esperar(tester);

    expect(find.text('917-SKP'), findsWidgets);
    expect(find.text('No se pudo cargar'), findsNothing);
  });

  // ── Filtros ─────────────────────────────────────────────────────────────

  testWidgets('el buscador filtra del lado del cliente', (tester) async {
    await abrir(tester);
    final lecturas = repo.lecturas;

    await tester.enterText(find.byType(TextField).first, 'suzuki');
    await tester.pump();

    expect(find.text('2 de 7 vehículos'), findsOneWidget);
    expect(find.text('2456-YTP'), findsOneWidget);
    expect(find.text('917-SKP'), findsNothing);
    expect(repo.lecturas, lecturas, reason: 'no vuelve a pedir nada');
  });

  testWidgets('sin coincidencias lo dice y deja limpiar', (tester) async {
    await abrir(tester);

    await tester.enterText(find.byType(TextField).first, 'zzzz');
    await tester.pump();

    expect(find.text('Ningún vehículo coincide'), findsOneWidget);
    expect(find.text('Limpiar filtros'), findsOneWidget);

    await tester.tap(find.text('Limpiar filtros'));
    await tester.pump();
    expect(find.text('7 vehículos, 6 activos'), findsOneWidget);
  });

  testWidgets('el estado «Inactivos» deja solo los dados de baja', (
    tester,
  ) async {
    await abrir(tester);

    await tester.tap(find.text('Inactivos'));
    await tester.pump();

    expect(find.text('1 de 7 vehículos'), findsOneWidget);
    expect(find.text('1053-FKE'), findsOneWidget);
    expect(find.text('917-SKP'), findsNothing);
  });

  // ── Alta y edición ──────────────────────────────────────────────────────

  testWidgets('la ficha valida marca, placa y sucursal antes de enviar', (
    tester,
  ) async {
    await abrir(tester);

    await tester.tap(find.text('Nuevo vehículo'));
    await esperar(tester);
    expect(find.text('Placa *'), findsOneWidget);

    await tester.tap(find.text('Crear vehículo'));
    await tester.pump();

    expect(find.text('Escribe la placa.'), findsOneWidget);
    expect(find.text('Escribe la marca.'), findsOneWidget);
    expect(find.text('Elige la sucursal.'), findsOneWidget);
    expect(repo.registrados, isEmpty, reason: 'nada viaja con errores');
  });

  testWidgets('un año fuera de rango se rechaza', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Nuevo vehículo'));
    await esperar(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Año'), '1800');
    await tester.tap(find.text('Crear vehículo'));
    await tester.pump();

    expect(find.textContaining('Un año entre 1950 y'), findsOneWidget);
  });

  testWidgets('crea un vehículo: normaliza la placa, nace activo y recarga', (
    tester,
  ) async {
    await abrir(tester);

    await tester.tap(find.text('Nuevo vehículo'));
    await esperar(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Placa *'),
      ' abc-123 ',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Marca *'),
      'Foton',
    );
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await esperar(tester);
    await tester.tap(find.text('COCHABAMBA').last);
    await esperar(tester);

    await tester.tap(find.text('Crear vehículo'));
    await esperar(tester);

    final enviado = repo.registrados.single;
    expect(enviado.idCoche, 0, reason: 'alta');
    expect(enviado.placa, 'ABC-123');
    expect(enviado.marca, 'Foton');
    expect(enviado.codSucursal, 23);
    expect(enviado.estado, 1);
    expect(enviado.audUsuario, 34, reason: 'el usuario de la sesión');
    expect(enviado.clase, isNull, reason: 'vacío viaja como null');

    // La ficha se cerró y el listado ya trae el vehículo nuevo.
    expect(find.text('Placa *'), findsNothing);
    expect(find.text('ABC-123'), findsOneWidget);
    expect(find.text('8 vehículos, 7 activos'), findsOneWidget);
  });

  testWidgets('si el servidor rechaza, la ficha queda abierta con el motivo', (
    tester,
  ) async {
    repo.falloAlRegistrar = Exception(
      'Ya existe un vehículo registrado con la placa 917-SKP.',
    );
    await abrir(tester);

    await tester.tap(find.byTooltip('Editar el vehículo 917-SKP'));
    await esperar(tester);
    expect(find.text('Editar 917-SKP'), findsOneWidget);

    await tester.tap(find.text('Guardar cambios'));
    await esperar(tester);

    expect(
      find.text('Ya existe un vehículo registrado con la placa 917-SKP.'),
      findsOneWidget,
    );
    expect(find.text('Editar 917-SKP'), findsOneWidget, reason: 'sigue abierta');
  });

  // ── Baja y eliminación ──────────────────────────────────────────────────

  testWidgets('dar de baja manda el mismo vehículo con estado 0', (
    tester,
  ) async {
    await abrir(tester);

    await tester.tap(find.byTooltip('Dar de baja el vehículo 2313-ZZD'));
    await esperar(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Dar de baja'));
    await esperar(tester);

    final enviado = repo.registrados.single;
    expect(enviado.idCoche, 2);
    expect(enviado.estado, 0);
    expect(enviado.placa, '2313-ZZD', reason: 'el resto de la fila intacto');
    expect(find.text('7 vehículos, 5 activos'), findsOneWidget);
  });

  testWidgets('eliminar un vehículo sin movimiento lo quita', (tester) async {
    await abrir(tester);

    await tester.tap(find.byTooltip('Eliminar el vehículo 4744-CEI'));
    await esperar(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await esperar(tester);

    expect(repo.eliminados, [7]);
    expect(find.text('4744-CEI'), findsNothing);
  });

  testWidgets('si tiene kilometraje, ofrece la baja en su lugar', (
    tester,
  ) async {
    repo.falloAlEliminar = Exception(
      'No se puede eliminar el vehículo: tiene kilometraje registrado.',
    );
    await abrir(tester);

    await tester.tap(find.byTooltip('Eliminar el vehículo 2313-ZZD'));
    await esperar(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await esperar(tester);

    expect(
      find.text('No se pudo eliminar el vehículo 2313-ZZD'),
      findsOneWidget,
    );
    expect(find.textContaining('tiene kilometraje registrado'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Dar de baja'));
    await esperar(tester);

    expect(repo.eliminados, isEmpty);
    expect(repo.registrados.single.idCoche, 2);
    expect(repo.registrados.single.estado, 0);
  });

  // ── Teléfono ────────────────────────────────────────────────────────────

  testWidgets('en el teléfono las acciones salen del menú de la tarjeta', (
    tester,
  ) async {
    await abrir(tester, ancho: 390, alto: 844);

    await tester.tap(find.byTooltip('Acciones del vehículo 1053-FKE'));
    await esperar(tester);
    // El vehículo está inactivo: la acción es reactivarlo.
    expect(find.text('Reactivar'), findsOneWidget);
    expect(find.text('Dar de baja'), findsNothing);

    await tester.tap(find.text('Reactivar'));
    await esperar(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Reactivar'));
    await esperar(tester);

    expect(repo.registrados.single.idCoche, 6);
    expect(repo.registrados.single.estado, 1);
  });

  testWidgets('en el teléfono la ficha sube como hoja modal', (tester) async {
    final errores = <FlutterErrorDetails>[];
    final previo = FlutterError.onError;
    FlutterError.onError = errores.add;

    await abrir(tester, ancho: 390, alto: 844);
    await tester.tap(find.text('Nuevo'));
    await esperar(tester);
    FlutterError.onError = previo;

    expect(find.text('Nuevo vehículo'), findsOneWidget);
    expect(find.text('Crear vehículo'), findsOneWidget);
    expect(errores, isEmpty);
  });
}

/// Monta al hijo un fotograma después, como el `ShellRoute` de la app: sin eso
/// aparecen desbordes que la app no tiene.
class _UnFotogramaDespues extends StatefulWidget {
  const _UnFotogramaDespues({required this.child});

  final Widget child;

  @override
  State<_UnFotogramaDespues> createState() => _UnFotogramaDespuesState();
}

class _UnFotogramaDespuesState extends State<_UnFotogramaDespues> {
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _listo = true);
    });
  }

  @override
  Widget build(BuildContext context) =>
      _listo ? widget.child : const SizedBox.shrink();
}
