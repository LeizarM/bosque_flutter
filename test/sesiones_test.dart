import 'dart:io';

import 'package:bosque_flutter/core/state/sesiones_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/data/models/sesion_model.dart';
import 'package:bosque_flutter/presentation/screens/sesiones/sesiones_screen.dart';
import 'package:bosque_flutter/presentation/widgets/sesiones/piezas_sesiones.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'fakes/repositorio_sesiones.dart';

/// Pantalla Sesiones con un repositorio falso: tabla o tarjetas según el ancho, la sesión propia
/// que no se ofrece cerrar, el cierre con confirmación y el historial con su búsqueda.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepoSesionesFalso repo;

  setUpAll(() async {
    // Con la fuente de reemplazo de flutter test el texto se ensancha y desborda en falso.
    const archivos = ['Roboto-Regular', 'Roboto-Medium', 'Roboto-Bold'];
    final cargador = FontLoader('Roboto');
    for (final archivo in archivos) {
      final f = File('assets/fonts/$archivo.ttf');
      if (f.existsSync()) {
        cargador.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      }
    }
    await cargador.load();
  });

  setUp(() => repo = RepoSesionesFalso());

  Future<void> esperar(WidgetTester tester, [Duration d = const Duration(milliseconds: 400)]) async {
    await tester.pump();
    await tester.pump(d);
  }

  Future<void> abrir(WidgetTester tester, {double ancho = 1400, double escalaTexto = 1}) async {
    tester.view.physicalSize = Size(ancho, ancho <= 450 ? 844 : 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sesionesRepositoryProvider.overrideWithValue(repo)],
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
          // Como en la app: el paginador del kit lee los breakpoints de la raíz.
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(escalaTexto)),
                child: ResponsiveBreakpoints.builder(child: child!, breakpoints: ResponsiveUtilsBosque.breakpoints),
              ),
          home: const SesionesScreen(),
        ),
      ),
    );
    await esperar(tester);
  }

  /// Dos tandas: la página se arma al final de la animación de la pestaña y recién ahí pide los datos.
  Future<void> irAlHistorial(WidgetTester tester) async {
    await tester.tap(find.text('Historial'));
    await esperar(tester);
    await esperar(tester);
  }

  /// El aviso del kit se cierra solo: se deja correr su tiempo para no dejar timers vivos.
  Future<void> dejarQueSeCierreElAviso(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));
  }

  for (final ancho in [390.0, 800.0, 1400.0]) {
    testWidgets('sin desbordes a $ancho px con letra al 150 %, en las dos pestañas', (tester) async {
      await abrir(tester, ancho: ancho, escalaTexto: 1.5);

      expect(find.text('Abiertas (3)'), findsOneWidget);
      // Tabla con columnas cuando hay lugar; en teléfono, tarjetas sin cabecera.
      expect(find.text('Última señal'), ancho >= 600 ? findsOneWidget : findsNothing);
      expect(find.text('IP'), ancho >= 1000 ? findsOneWidget : findsNothing);
      expect(tester.takeException(), isNull, reason: 'abiertas');

      await irAlHistorial(tester);
      expect(find.textContaining('Cerrada por mjaimes'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'historial');
    });
  }

  testWidgets('la sesión propia se rotula y no se ofrece cerrarla', (tester) async {
    await abrir(tester);

    expect(find.text('Esta sesión'), findsOneWidget);
    // Dos ajenas abiertas: una conectada y una sin señal.
    expect(find.text('Cerrar sesión'), findsNWidgets(2));
    expect(find.text('2 con la app a la vista'), findsOneWidget);
    expect(find.text('1 sin señal reciente'), findsOneWidget);
  });

  testWidgets('cerrar una sesión pide confirmación, la cierra y relee la lista', (tester) async {
    await abrir(tester);
    final lecturas = repo.lecturasAbiertas;

    await tester.tap(find.text('Cerrar sesión').first);
    await esperar(tester);
    expect(find.text('¿Cerrar la sesión de Pérez Gómez Juan Carlos?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await esperar(tester);

    expect(repo.cerradas, [BigInt.from(2)]);
    expect(repo.lecturasAbiertas, greaterThan(lecturas));
    expect(find.text(repo.mensajeAlCerrar), findsOneWidget);
    await dejarQueSeCierreElAviso(tester);
  });

  testWidgets('cancelar la confirmación no cierra nada', (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Cerrar sesión').first);
    await esperar(tester);
    await tester.tap(find.text('Cancelar'));
    await esperar(tester);

    expect(repo.cerradas, isEmpty);
  });

  testWidgets('en teléfono cerrar está en el menú de la tarjeta', (tester) async {
    await abrir(tester, ancho: 390);

    await tester.tap(find.byTooltip('Acciones de la sesión').first);
    await esperar(tester);
    await tester.tap(find.text('Cerrar sesión'));
    await esperar(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await esperar(tester);

    expect(repo.cerradas, [BigInt.from(2)]);
    await dejarQueSeCierreElAviso(tester);
  });

  testWidgets('el historial pide el día de hoy y la búsqueda filtra por nombre o usuario', (tester) async {
    await abrir(tester);
    await irAlHistorial(tester);

    final hoy = DateTime.now();
    expect(repo.rangos.single.desde, DateTime(hoy.year, hoy.month, hoy.day));
    expect(find.text('jbalderrama'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Buscar persona o usuario'), 'perez');
    await esperar(tester);
    expect(find.text('jbalderrama'), findsNothing);
    expect(find.text('jperez'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Buscar persona o usuario'), 'zzz');
    await esperar(tester);
    expect(find.text('Nadie coincide con la búsqueda'), findsOneWidget);
  });

  testWidgets('en teléfono la búsqueda del historial se despliega a pedido', (tester) async {
    await abrir(tester, ancho: 390);
    await irAlHistorial(tester);

    final campo = find.widgetWithText(TextField, 'Buscar persona o usuario');
    expect(campo, findsNothing);
    await tester.tap(find.byTooltip('Buscar persona o usuario'));
    await esperar(tester);
    await tester.enterText(campo, 'perez');
    await esperar(tester);
    expect(find.text('jbalderrama'), findsNothing);

    // Ocultarla también quita el filtro: no queda una lista recortada sin explicación.
    await tester.tap(find.byTooltip('Ocultar la búsqueda'));
    await esperar(tester);
    expect(campo, findsNothing);
    expect(find.text('jbalderrama'), findsOneWidget);
  });

  testWidgets('en escritorio las abiertas también se paginan de a 50', (tester) async {
    repo.abiertasDevueltas = [for (var i = 1; i <= 60; i++) sesionDePrueba(id: i, login: 'u$i')];
    await abrir(tester);

    expect(find.byType(BosquePaginator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin sesiones abiertas explica por qué', (tester) async {
    repo.abiertasDevueltas = [];
    await abrir(tester);

    expect(find.text('Nadie tiene la app abierta'), findsOneWidget);
  });

  test('el modelo lee las fechas del backend y el estado', () {
    final s =
        SesionModel.fromJson({
          'idSesion': 33,
          'codUsuario': 5,
          'plataforma': 'android',
          'versionApp': '1.0.2',
          'fechaInicio': '2026-10-13 08:15:00',
          'fechaUltimaSenal': '2026-10-13 09:01:30',
          'fechaCierre': null,
          'login': 'jperez',
          'nombreCompleto': ' Pérez Juan ',
          'estado': 'N',
          'esActual': false,
        }).toEntity();

    expect(s.idSesion, BigInt.from(33));
    expect(s.fechaInicio, DateTime(2026, 10, 13, 8, 15));
    expect(s.nombreCompleto, 'Pérez Juan');
    expect(s.abierta, isTrue);
    expect(s.textoEstado, 'Sin señal');
    expect(s.textoPlataforma, 'Android');
  });

  test('los tiempos se leen de un vistazo', () {
    final ahora = DateTime(2026, 10, 13, 12, 0);

    expect(haceCuanto(ahora.subtract(const Duration(seconds: 20)), ahora: ahora), 'hace un momento');
    expect(haceCuanto(ahora.subtract(const Duration(minutes: 3)), ahora: ahora), 'hace 3 min');
    expect(haceCuanto(ahora.subtract(const Duration(hours: 2)), ahora: ahora), 'hace 2 h');
    expect(haceCuanto(DateTime(2026, 10, 12, 18, 30), ahora: ahora), '12/10 18:30');
    expect(momento(DateTime(2026, 10, 13, 8, 5), ahora: ahora), '08:05');
    expect(haceCuanto(null), '--');
  });
}
