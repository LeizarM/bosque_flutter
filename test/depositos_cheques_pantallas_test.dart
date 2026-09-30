import 'dart:async';
import 'dart:io';

import 'package:bosque_flutter/core/state/depositos_cheques_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/deposito_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_negocio_entity.dart';
import 'package:bosque_flutter/domain/repositories/deposito_cheques_repository.dart';
import 'package:bosque_flutter/presentation/screens/depositos-cheques/deposito_cheque_identificar_register_screen.dart';
import 'package:bosque_flutter/presentation/screens/depositos-cheques/deposito_cheque_identificar_view_screen.dart';
import 'package:bosque_flutter/presentation/screens/depositos-cheques/deposito_cheque_register_screen.dart';
import 'package:bosque_flutter/presentation/screens/depositos-cheques/deposito_cheque_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'fakes/repositorio_depositos.dart';

/// Las cuatro pantallas de depósitos con un repositorio falso.
///
/// Antes de estas pruebas el módulo no tenía ninguna y sus pantallas
/// bloqueaban todo con un spinner, escondían los errores como «sin datos» y
/// pedían datos que no usaban. Aquí se fija lo que se arregló: que abran sin
/// desbordes en móvil, tablet y escritorio, que no pidan de más, y que un fallo
/// se muestre con «Reintentar» en vez de disfrazarse de lista vacía.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepoDepositosFalso repo;

  // La fuente de reemplazo de flutter test mide todos los glifos igual (un
  // cuadrado por letra) y ensancha el texto: «Datos del Depósito» desbordaba una
  // fila que con Roboto sobra. Con la fuente real, los desbordes que aparecen
  // son reales.
  setUpAll(() async {
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

  setUp(() => repo = RepoDepositosFalso());

  Widget app(Widget pantalla, List<Override> overrides) {
    return ProviderScope(
      overrides: [
        userProvider.overrideWith(
          (ref) => UserStateNotifier.sinStorage(loginAdminFalso),
        ),
        ...overrides,
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
        // En la app viven dentro del Scaffold del dashboard (ShellRoute), y se
        // montan cuando los breakpoints ya se resolvieron.
        home: Scaffold(body: _UnFotogramaDespues(child: pantalla)),
      ),
    );
  }

  Override sobreescribir(dynamic provider) =>
      provider.overrideWith((ref) => DepositosChequesNotifier(ref, repo: repo))
          as Override;

  Future<void> abrir(
    WidgetTester tester,
    Widget pantalla,
    List<Override> overrides, {
    double ancho = 1400,
  }) async {
    tester.view.physicalSize = Size(ancho, ancho <= 450 ? 844 : 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(pantalla, overrides));
    // pump() y no pumpAndSettle(): las barras de progreso animan en bucle. Los
    // 5 s le dan tiempo al timeout de lectura del almacenamiento seguro.
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
  }

  Future<void> esperar(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  // ── Sin desbordes en los tres anchos ────────────────────────────────────

  final pantallas = <String, ({Widget Function() pantalla, dynamic provider, String testigo})>{
    'Registro de depósito': (
      pantalla: () => const DepositoChequeRegisterScreen(),
      provider: depositosChequesRegisterProvider,
      testigo: 'Empresa',
    ),
    'Listado de depósitos': (
      pantalla: () => const DepositoChequeViewScreen(),
      provider: depositosChequesViewProvider,
      testigo: 'Empresa',
    ),
    'Registro por identificar': (
      pantalla: () => const DepositoChequeIdentificarScreen(),
      provider: depositosChequesIdentificarRegisterProvider,
      testigo: 'Empresa',
    ),
    'Listado por identificar': (
      pantalla: () => const DepositoChequeIdentificarViewScreen(),
      provider: depositosChequesIdentificarViewProvider,
      testigo: 'Buscar',
    ),
  };

  pantallas.forEach((nombre, def) {
    for (final ancho in [390.0, 800.0, 1400.0]) {
      testWidgets('$nombre sin desborde a ${ancho.toInt()}', (tester) async {
        // `takeException` no dice en qué widget ocurrió el desborde; se captura
        // el error completo para que un fallo se pueda ubicar.
        final errores = <FlutterErrorDetails>[];
        final previo = FlutterError.onError;
        FlutterError.onError = errores.add;

        await abrir(tester, def.pantalla(), [
          sobreescribir(def.provider),
        ], ancho: ancho);
        // Antes de cualquier expect: el binding exige el handler original.
        FlutterError.onError = previo;

        // Control: si no se dibujó, la prueba no estaría midiendo nada.
        expect(find.textContaining(def.testigo), findsWidgets);
        for (final e in errores) {
          debugPrint('DETALLE $nombre a $ancho:\n$e');
        }
        expect(errores, isEmpty, reason: '$nombre a $ancho');
      });
    }
  });

  // ── Lo que ya no se pide ────────────────────────────────────────────────

  testWidgets('el registro solo pide las empresas al abrir', (tester) async {
    await abrir(tester, const DepositoChequeRegisterScreen(), [
      sobreescribir(depositosChequesRegisterProvider),
    ]);

    expect(repo.contar('getEmpresas'), 1);
    expect(repo.llamadas.where((m) => m != 'getEmpresas'), isEmpty);
  });

  testWidgets('el registro por identificar no descarga los clientes', (
    tester,
  ) async {
    await abrir(tester, const DepositoChequeIdentificarScreen(), [
      sobreescribir(depositosChequesIdentificarRegisterProvider),
    ]);

    await tester.tap(find.byType(DropdownButtonFormField<dynamic>).first);
    await esperar(tester);
    await tester.tap(find.text('Empresa 1').last);
    await esperar(tester);

    expect(repo.contar('getSociosNegocio'), 0, reason: 'no los usa');
    expect(repo.contar('getBancos'), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el listado por identificar no pide empresas ni clientes', (
    tester,
  ) async {
    await abrir(tester, const DepositoChequeIdentificarViewScreen(), [
      sobreescribir(depositosChequesIdentificarViewProvider),
    ]);

    expect(repo.llamadas, isEmpty, reason: 'no busca ni carga nada al abrir');
    expect(find.text('Todas las fechas'), findsWidgets);
  });

  testWidgets('el listado de depósitos no busca solo y fija los últimos 30 días', (
    tester,
  ) async {
    await abrir(tester, const DepositoChequeViewScreen(), [
      sobreescribir(depositosChequesViewProvider),
    ]);

    expect(repo.contar('obtenerDepositos'), 0);
    final ahora = DateTime.now();
    final contenedor = ProviderScope.containerOf(
      tester.element(find.byType(DepositoChequeViewScreen)),
    );
    final estado = contenedor.read(depositosChequesViewProvider);
    expect(estado.fechaHasta, DateTime(ahora.year, ahora.month, ahora.day));
    expect(
      estado.fechaDesde,
      DateTime(ahora.year, ahora.month, ahora.day - 30),
    );
  });

  // ── Errores que no se disfrazan de «sin datos» ──────────────────────────

  testWidgets('si fallan las empresas se ofrece Reintentar y se recupera', (
    tester,
  ) async {
    repo.errorEmpresas = const DepositoChequesException(
      'No se pudo conectar con el servidor.',
    );
    await abrir(tester, const DepositoChequeRegisterScreen(), [
      sobreescribir(depositosChequesRegisterProvider),
    ]);

    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('No se pudo conectar'), findsOneWidget);

    repo.errorEmpresas = null;
    await tester.tap(find.text('Reintentar'));
    await esperar(tester);

    expect(find.text('Reintentar'), findsNothing);
    expect(repo.contar('getEmpresas'), 2);
  });

  testWidgets('el listado muestra el fallo con Reintentar, no «sin depósitos»', (
    tester,
  ) async {
    repo.errorListado = const DepositoChequesException('Error en el servidor.');
    await abrir(tester, const DepositoChequeViewScreen(), [
      sobreescribir(depositosChequesViewProvider),
    ]);

    await tester.tap(find.text('Buscar/Actualizar').first);
    await esperar(tester);

    expect(find.text('Reintentar'), findsWidgets);
    expect(find.textContaining('No se encontraron'), findsNothing);

    repo.errorListado = null;
    repo.depositos = [depositoFalso(1), depositoFalso(2)];
    await tester.tap(find.text('Reintentar').first);
    await esperar(tester);

    expect(find.text('Reintentar'), findsNothing);
    expect(find.textContaining('Banco 1'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el listado por identificar reintenta con los mismos filtros', (
    tester,
  ) async {
    repo.errorListado = const DepositoChequesException('Error en el servidor.');
    await abrir(tester, const DepositoChequeIdentificarViewScreen(), [
      sobreescribir(depositosChequesIdentificarViewProvider),
    ]);

    await tester.tap(find.text('Buscar').first);
    await esperar(tester);
    expect(find.text('Reintentar'), findsWidgets);
    expect(find.textContaining('No hay depósitos'), findsNothing);

    repo.errorListado = null;
    repo.depositos = [depositoFalso(1)];
    await tester.tap(find.text('Reintentar').first);
    await esperar(tester);

    expect(find.text('Reintentar'), findsNothing);
    expect(repo.contar('lstDepositxIdentificar'), 2);
  });

  // ── Sin bloqueo global ──────────────────────────────────────────────────

  testWidgets('el registro sigue usable mientras cargan los clientes', (
    tester,
  ) async {
    final lentos = Completer<List<SocioNegocioEntity>>();
    repo.clientesPendientes = lentos;
    await abrir(tester, const DepositoChequeRegisterScreen(), [
      sobreescribir(depositosChequesRegisterProvider),
    ]);

    final contenedor = ProviderScope.containerOf(
      tester.element(find.byType(DepositoChequeRegisterScreen)),
    );
    final notifier = contenedor.read(depositosChequesRegisterProvider.notifier);
    final eleccion = notifier.seleccionarEmpresa(repo.empresas.first);
    await esperar(tester);

    expect(
      contenedor.read(depositosChequesRegisterProvider).cargandoClientes,
      isTrue,
    );
    // El formulario no se reemplazó por un spinner: sigue la etiqueta y aparece
    // una barra de progreso.
    expect(find.textContaining('Empresa'), findsWidgets);
    expect(find.byType(LinearProgressIndicator), findsWidgets);

    lentos.complete([clienteFalso('C1')]);
    await eleccion;
    await esperar(tester);
    expect(tester.takeException(), isNull);
  });

  // ── Listado con datos: tabla o tarjetas según el ancho disponible ───────

  // Los casos que estiran el diseño: textos largos, sin vendedor, sin fecha,
  // un rechazado, un importe enorme y más filas que una página.
  List<DepositoChequeEntity> filasDePrueba() => [
    depositoFalso(1).copyWith(
      codCliente:
          'CLIENTE CON UN NOMBRE MUY LARGO S.R.L. SUCURSAL NORTE - CHIQUITOS',
      nombreBanco: 'Banco Mercantil Santa Cruz - Cuenta corriente 1234567890',
      nombreEmpresa: 'Empresa con razón social larguísima S.A.',
      nombreVendedor: 'Vendedor Con Nombre Y Apellido Largos',
      importe: 12345678.9,
      fechaI: DateTime(2026, 9, 12),
      nroTransaccion: 'TRX-2026-09-000123456789',
      nombreCompleto: 'Empleado Con Nombre Completo Muy Largo',
      esPendiente: 'Verificado',
    ),
    depositoFalso(2).copyWith(esPendiente: 'Rechazado'),
    depositoFalso(3).copyWith(
      fechaI: DateTime(2026, 9, 3),
      nroTransaccion: '998877',
      nombreVendedor: 'Ana',
    ),
    for (var i = 4; i <= 12; i++) depositoFalso(i),
  ];

  /// Abre el listado, busca y devuelve los errores de dibujo que hubo.
  Future<List<FlutterErrorDetails>> buscarConDatos(
    WidgetTester tester,
    double ancho,
  ) async {
    repo.depositos = filasDePrueba();
    final errores = <FlutterErrorDetails>[];
    final previo = FlutterError.onError;
    FlutterError.onError = errores.add;

    await abrir(tester, const DepositoChequeViewScreen(), [
      sobreescribir(depositosChequesViewProvider),
    ], ancho: ancho);
    await tester.ensureVisible(find.text('Buscar/Actualizar').first);
    await tester.tap(find.text('Buscar/Actualizar').first);
    await esperar(tester);
    // Antes de cualquier expect: el binding exige el handler original.
    FlutterError.onError = previo;
    for (final e in errores) {
      debugPrint('DETALLE listado con datos a $ancho:\n$e');
    }
    return errores;
  }

  // Modo de lista que corresponde a cada ancho de ventana (el área de
  // resultados mide la ventana menos el relleno de la página).
  final modoPorAncho = {
    390.0: 'lista-tarjetas',
    700.0: 'lista-tarjetas',
    800.0: 'lista-compacta',
    1000.0: 'lista-compacta',
    1400.0: 'lista-tabla',
  };

  modoPorAncho.forEach((ancho, modo) {
    testWidgets('el listado con datos no desborda a ${ancho.toInt()} ($modo)', (
      tester,
    ) async {
      final errores = await buscarConDatos(tester, ancho);

      expect(errores, isEmpty, reason: 'a $ancho');
      expect(find.textContaining('Banco Mercantil'), findsWidgets);
      expect(find.text('12 registros'), findsOneWidget);
      // Nunca scroll horizontal ni DataTable.
      expect(find.byType(DataTable), findsNothing);
      expect(find.byKey(ValueKey(modo)), findsOneWidget, reason: 'a $ancho');
      expect(
        find.byKey(const ValueKey('lista-tabla')).evaluate().isNotEmpty,
        modo == 'lista-tabla',
      );
    });
  });

  // El texto ampliado es donde primero se rompen los anchos fijos.
  for (final ancho in [390.0, 800.0, 1400.0]) {
    testWidgets('el listado con texto al 150% no desborda a ${ancho.toInt()}', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final errores = await buscarConDatos(tester, ancho);

      expect(errores, isEmpty, reason: 'a $ancho');
      expect(find.textContaining('Banco Mercantil'), findsWidgets);
    });
  }

  testWidgets('a media pantalla se ven muchas más filas que con tarjetas', (
    tester,
  ) async {
    final errores = await buscarConDatos(tester, 900);
    expect(errores, isEmpty);
    expect(find.byKey(const ValueKey('lista-compacta')), findsOneWidget);

    // Dos filas seguidas ocupan poco: con tarjetas de ~290 px serían ~580.
    final arriba = tester.getTopLeft(find.text('#1')).dy;
    final dosFilasDespues = tester.getTopLeft(find.text('#3')).dy;
    expect(dosFilasDespues - arriba, lessThan(200));
  });

  testWidgets('el filtro a media pantalla ocupa dos filas', (tester) async {
    await abrir(tester, const DepositoChequeViewScreen(), [
      sobreescribir(depositosChequesViewProvider),
    ], ancho: 900);

    // Se compara el borde superior del campo, no el de su etiqueta: la
    // etiqueta sube o baja según el campo tenga valor.
    double filaDe(String etiqueta) => tester
        .getTopLeft(
          find
              .ancestor(
                of: find.text(etiqueta),
                matching: find.byType(InputDecorator),
              )
              .first,
        )
        .dy;

    final empresa = filaDe('Empresa');
    expect(filaDe('Banco'), empresa, reason: 'Empresa y Banco, misma fila');
    expect(filaDe('Desde'), empresa, reason: 'Desde en la primera fila');
    expect(filaDe('Hasta'), empresa, reason: 'Hasta en la primera fila');
    final segunda = filaDe('Cliente');
    expect(segunda, greaterThan(empresa), reason: 'Cliente en la segunda');
    expect(filaDe('Estado'), segunda, reason: 'Estado junto a Cliente');
  });

  testWidgets('el rechazado no ofrece acciones y el resto sí', (tester) async {
    final errores = await buscarConDatos(tester, 1400);

    expect(errores, isEmpty);
    // Página de 10 filas, una rechazada.
    expect(find.text('No disponible'), findsOneWidget);
    expect(find.byTooltip('Rechazar'), findsNWidgets(9));
    expect(find.byTooltip('Ver imagen'), findsNWidgets(9));
  });

  testWidgets('la paginación avanza y vuelve', (tester) async {
    final errores = await buscarConDatos(tester, 1400);
    expect(errores, isEmpty);

    expect(find.text('Mostrando 1 a 10 de 12 depósitos'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Página siguiente'));
    await tester.tap(find.byTooltip('Página siguiente'));
    await esperar(tester);
    expect(find.text('Mostrando 11 a 12 de 12 depósitos'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Primera página'));
    await tester.tap(find.byTooltip('Primera página'));
    await esperar(tester);
    expect(find.text('Mostrando 1 a 10 de 12 depósitos'), findsOneWidget);
  });
}

/// Monta [child] un fotograma después. En el arnés de prueba la pantalla
/// nacería en el mismo fotograma que `ResponsiveBreakpoints`, antes de que este
/// resuelva el punto de quiebre, y por un instante se dibujaría el diseño
/// equivocado (desbordes de un fotograma que la app real nunca ve).
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
