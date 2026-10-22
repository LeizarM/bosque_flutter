// Sidebar: las ramas se despliegan, «Contraer todo» pliega el árbol entero,
// «Mi Ficha» lleva a la ficha propia (y no aparece sin empleado vinculado) y el
// botón de color abre la paleta.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/menu_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/entities/menu_entity.dart';
import 'package:bosque_flutter/domain/repositories/menu_repository.dart';
import 'package:bosque_flutter/presentation/widgets/shared/selector_color_tema.dart';
import 'package:bosque_flutter/presentation/widgets/shared/sidebar.dart';

import 'fakes/arnes_cheques.dart';

MenuItemEntity _vista(
  int cod,
  String titulo, {
  String dir = '',
  List<MenuItemEntity>? hijos,
}) => MenuItemEntity(
  codVista: cod,
  codVistaPadre: 0,
  direccion: dir,
  titulo: titulo,
  esRaiz: hijos == null ? 0 : 1,
  autorizar: 1,
  audUsuarioI: 0,
  fila: cod,
  items: hijos,
  tieneHijo: hijos == null ? 0 : 1,
);

class _RepoMenu implements MenuRepository {
  @override
  Future<List<MenuItemEntity>> getMenuItems(int codUsuario) async => [];
}

/// El menú ya cargado, sin caché ni red.
class _MenuFalso extends MenuNotifier {
  _MenuFalso(List<MenuItemEntity> items) : super(_RepoMenu()) {
    state = MenuState(status: MenuStatus.loaded, menuItems: items);
  }

  @override
  Future<Map<int, bool>> loadExpandedState() async => {};
  @override
  Future<void> loadMenuFromCacheOnly() async {}
  @override
  Future<void> loadUserMenu(int userId) async {}
  @override
  Future<void> saveExpandedState(Map<int, bool> expandedItems) async {}
}

void main() {
  setUpAll(cargarRoboto);
  // El tema lee su semilla del almacenamiento seguro: sin esto la lectura no
  // responde en pruebas y deja su timer colgado.
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  final menu = [
    _vista(
      10,
      'COBRANZAS',
      hijos: [_vista(11, 'Bancos', dir: 'tchBanco/banco')],
    ),
    _vista(
      20,
      'CONTABILIDAD',
      hijos: [_vista(21, 'Activos fijos', dir: 'tcon/activos')],
    ),
  ];

  Widget app({int codEmpleado = 25, String? iniciales}) {
    // Como en la app: el sidebar vive en el ShellRoute y sobrevive al cambio
    // de pantalla, así que sus animaciones corren de verdad al navegar.
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        ShellRoute(
          builder:
              (_, __, hijo) => Scaffold(
                appBar: AppBar(actions: const [BotonColorTema()]),
                body: UnFotogramaDespues(
                  child: Row(
                    children: [const AppSidebar(), Expanded(child: hijo)],
                  ),
                ),
              ),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, __) => const Text('INICIO'),
            ),
            GoRoute(
              path: '/dashboard/${AppConstants.rutaMiFicha}',
              builder: (_, __) => const Text('FICHA PROPIA'),
            ),
          ],
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        menuProvider.overrideWith((ref) => _MenuFalso(menu)),
        userProvider.overrideWith(
          (ref) => UserStateNotifier.sinStorage(
            LoginEntity.fromJson(<String, dynamic>{
              'tipoUsuario': 'ROLE_ADM',
              'codUsuario': 34,
              'codEmpleado': codEmpleado,
              'nombreCompleto': 'JAIMES MARCELO JAVIER',
              'cargo': 'Analista de sistemas',
              if (iniciales != null) 'iniciales': iniciales,
            }),
          ),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme().getTheme(),
        routerConfig: router,
        builder:
            (context, child) => ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: ResponsiveUtilsBosque.breakpoints,
            ),
      ),
    );
  }

  testWidgets('una rama se despliega y «Contraer todo» pliega el árbol', (
    tester,
  ) async {
    await montar(tester, app());
    expect(find.text('Bancos'), findsNothing);

    await tester.tap(find.text('COBRANZAS'));
    await esperar(tester);
    await tester.tap(find.text('CONTABILIDAD'));
    await esperar(tester);
    expect(find.text('Bancos'), findsOneWidget);
    expect(find.text('Activos fijos'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sidebar-contraer-todo')));
    await esperar(tester);
    expect(find.text('Bancos'), findsNothing);
    expect(find.text('Activos fijos'), findsNothing);
  });

  testWidgets('«Mi Ficha» lleva a la ficha de quien inició sesión', (
    tester,
  ) async {
    await montar(tester, app());
    expect(find.text('JAIMES MARCELO JAVIER'), findsOneWidget);
    expect(find.text('Administrador'), findsOneWidget);

    await tester.tap(find.text('Mi Ficha'));
    await esperar(tester);
    expect(find.text('FICHA PROPIA'), findsOneWidget);
    expect(find.byKey(const ValueKey('mi-ficha-activa')), findsOneWidget);
  });

  // Regresión: la barra del ítem activo bajaba a 0 con una curva que se pasa
  // de largo, quedaba con alto negativo y la app mostraba la pantalla roja.
  testWidgets('cambiar de pantalla ida y vuelta no rompe la barra del activo', (
    tester,
  ) async {
    final errores = await capturandoErrores(() async {
      await montar(tester, app());
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Mi Ficha'));
        for (var f = 0; f < 15; f++) {
          await tester.pump(const Duration(milliseconds: 20));
        }
        await tester.tap(find.text('Dashboard'));
        for (var f = 0; f < 15; f++) {
          await tester.pump(const Duration(milliseconds: 20));
        }
      }
    });
    expect(errores, isEmpty);
    expect(find.text('INICIO'), findsOneWidget);
  });

  testWidgets('el avatar usa las iniciales que manda el SP', (tester) async {
    // 172 no tiene paterno: el SP manda primer nombre + materno (MJ).
    await montar(tester, app(iniciales: 'MJ'));
    expect(find.text('MJ'), findsOneWidget);
    expect(find.text('JM'), findsNothing);
  });

  testWidgets('sin iniciales del SP (sesión anterior) salen del nombre', (
    tester,
  ) async {
    await montar(tester, app());
    expect(find.text('JM'), findsOneWidget);
  });

  testWidgets('sin empleado vinculado no hay «Mi Ficha»', (tester) async {
    await montar(tester, app(codEmpleado: 0));
    expect(find.text('Mi Ficha'), findsNothing);
  });

  testWidgets('el texto al 150 % no desborda el sidebar', (tester) async {
    conTexto(tester, 1.5);
    final errores = await capturandoErrores(() async {
      await montar(tester, app());
      await tester.tap(find.text('COBRANZAS'));
      await esperar(tester);
    });
    expect(errores, isEmpty);
  });

  testWidgets('el botón de color abre la paleta con las nueve semillas', (
    tester,
  ) async {
    await montar(tester, app());
    await tester.tap(find.byType(BotonColorTema));
    await esperar(tester);
    expect(find.text('Color del tema'), findsOneWidget);
    expect(find.byType(MuestraDeColor), findsNWidgets(colorList.length));
  });
}
