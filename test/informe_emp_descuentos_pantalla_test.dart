import 'dart:io';

import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/data/models/empleado_model.dart';
import 'package:bosque_flutter/domain/entities/descuento_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/presentation/screens/informe-emp-descuentos/InformeEmpDescuentosScreen.dart';
import 'package:bosque_flutter/presentation/screens/informe-emp-descuentos/descuento_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// El selector de empleados de «Descuentos por Empleado» pide solo activos
/// (`esActivo = 1`) y, con el check «Incluir empleados inactivos», pide todos
/// (`esActivo = null`: `p_list_Empleado 'Y'` los devuelve con los activos
/// primero). `0` devolvería únicamente los inactivos, por eso no se usa.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Roboto real: con la fuente de reemplazo el texto se ensancha y aparecen
  // desbordes que la app no tiene.
  setUpAll(() async {
    final cargador = FontLoader('Roboto');
    for (final a in ['Roboto-Regular', 'Roboto-Medium', 'Roboto-Bold']) {
      final f = File('assets/fonts/$a.ttf');
      if (f.existsSync()) {
        cargador.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      }
    }
    await cargador.load();
  });

  // Como lo manda /rrhh/obtenerLstEmpleados: los objetos anidados vienen
  // vacíos y solo se llenan el nombre y la relación laboral.
  EmpleadoEntity empleado(int cod, String nombre, {required int esActivo}) {
    final json = <String, dynamic>{
      'codEmpleado': cod,
      'zona': <String, dynamic>{},
      'pais': <String, dynamic>{},
      'ciudad': <String, dynamic>{},
      'persona': {
        'datoPersona': nombre,
        'zona': <String, dynamic>{},
        'pais': <String, dynamic>{},
        'ciudad': <String, dynamic>{},
      },
      'empleadoCargo': {
        'cargoSucursal': {
          'sucursal': {'empresa': <String, dynamic>{}},
          'cargo': <String, dynamic>{},
        },
      },
      'relEmpEmpr': {'esActivo': esActivo},
      'dependiente': <String, dynamic>{},
      'telefono': <String, dynamic>{},
      'empresa': <String, dynamic>{},
      'sucursal': {'empresa': <String, dynamic>{}},
      'email': <String, dynamic>{},
      'formacion': <String, dynamic>{},
      'experienciaLaboral': <String, dynamic>{},
      'garanteReferencia': <String, dynamic>{},
    };
    return EmpleadoModel.fromJson(json).toEntity();
  }

  final activo = empleado(1, 'PEREZ ACTIVO JUAN', esActivo: 1);
  final inactivo = empleado(2, 'GOMEZ INACTIVO LUIS', esActivo: 0);

  late List<(String?, int?, int, int, int?)> pedidos;
  late List<DescuentoEmpleadoEntity> descuentos;
  Object? fallaDescuentos;

  Widget app() {
    return ProviderScope(
      overrides: [
        getListaEmpleados.overrideWith((ref, params) {
          pedidos.add(params);
          // Imita el filtro del SP: 1 = activos, 0 = inactivos, null = todos.
          final texto = params.$1?.toLowerCase();
          return [activo, inactivo]
              .where((e) => params.$2 == null || e.relEmpEmpr.esActivo == params.$2)
              .where(
                (e) =>
                    texto == null ||
                    e.persona.datoPersona!.toLowerCase().contains(texto),
              )
              .toList();
        }),
        descuentosEmpleadoProvider.overrideWith((ref, params) {
          final falla = fallaDescuentos;
          if (falla != null) throw falla;
          return descuentos;
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
        // En la app vive dentro del Scaffold del dashboard (ShellRoute).
        home: const Scaffold(
          body: _UnFotogramaDespues(child: InformeEmpDescuentosScreen()),
        ),
      ),
    );
  }

  Future<void> abrirPantalla(WidgetTester tester, {double ancho = 1000}) async {
    tester.view.physicalSize = Size(ancho, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> abrirSelector(WidgetTester tester) async {
    await tester.tap(find.text('Empleado'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> cerrarSelector(WidgetTester tester) async {
    // Toque fuera del popup: lo cierra sin elegir a nadie.
    await tester.tapAt(const Offset(5, 5));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  setUp(() {
    pedidos = [];
    descuentos = [];
    fallaDescuentos = null;
  });

  testWidgets('por defecto pide solo activos (esActivo = 1)', (tester) async {
    await abrirPantalla(tester);
    expect(find.text('Incluir empleados inactivos'), findsOneWidget);

    await abrirSelector(tester);

    expect(pedidos, isNotEmpty);
    expect(pedidos.last.$2, 1, reason: 'solo activos');
    expect(find.text('PEREZ ACTIVO JUAN'), findsOneWidget);
    expect(find.text('GOMEZ INACTIVO LUIS'), findsNothing);
    expect(find.text('Inactivo'), findsNothing);
  });

  testWidgets('con el check pide todos (esActivo = null) y marca a los inactivos', (
    tester,
  ) async {
    await abrirPantalla(tester);

    await tester.tap(find.text('Incluir empleados inactivos'));
    await tester.pump();
    await abrirSelector(tester);

    expect(pedidos.last.$2, isNull, reason: 'null = todos; 0 dejaría fuera a los activos');
    expect(find.text('PEREZ ACTIVO JUAN'), findsOneWidget);
    expect(find.text('GOMEZ INACTIVO LUIS'), findsOneWidget);
    expect(find.text('Inactivo'), findsOneWidget, reason: 'solo el inactivo lleva marca');
  });

  testWidgets('al desmarcar vuelve a pedir solo activos', (tester) async {
    await abrirPantalla(tester);

    await tester.tap(find.text('Incluir empleados inactivos'));
    await tester.pump();
    await abrirSelector(tester);
    expect(pedidos.last.$2, isNull);
    await cerrarSelector(tester);

    await tester.tap(find.text('Incluir empleados inactivos'));
    await tester.pump();
    await abrirSelector(tester);

    expect(pedidos.last.$2, 1);
    expect(find.text('GOMEZ INACTIVO LUIS'), findsNothing);
  });

  testWidgets('escribir busca en el servidor y conserva el filtro de inactivos', (
    tester,
  ) async {
    await abrirPantalla(tester);

    await tester.tap(find.text('Incluir empleados inactivos'));
    await tester.pump();
    await abrirSelector(tester);
    pedidos.clear();

    await tester.enterText(find.byType(TextField).last, 'gomez');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(pedidos, isNotEmpty, reason: 'la búsqueda va al servidor');
    expect(pedidos.last.$1, 'gomez');
    expect(pedidos.last.$2, isNull, reason: 'sigue incluyendo inactivos');
    expect(find.text('GOMEZ INACTIVO LUIS'), findsOneWidget);
    expect(find.text('PEREZ ACTIVO JUAN'), findsNothing);
  });

  for (final ancho in [390.0, 1000.0]) {
    testWidgets('el check no desborda a ${ancho.toInt()}', (tester) async {
      final errores = <FlutterErrorDetails>[];
      final previo = FlutterError.onError;
      FlutterError.onError = errores.add;

      await abrirPantalla(tester, ancho: ancho);
      await tester.tap(find.text('Incluir empleados inactivos'));
      await tester.pump();
      FlutterError.onError = previo;

      for (final e in errores) {
        debugPrint('DETALLE a $ancho:\n$e');
      }
      expect(errores, isEmpty, reason: 'a $ancho');
    });
  }

  // ── Resultados: resumen y tarjetas ──────────────────────────────────────

  DescuentoEmpleadoEntity desc(
    String tipo,
    String descripcion, {
    String moneda = 'BS',
    double monto = 100,
    double total = 1000,
    double saldo = 900,
    int cuotas = 0,
    int primera = 0,
    int ultima = 0,
    String estado = 'Ejecutado',
  }) => DescuentoEmpleadoEntity(
    codEmpleado: 1,
    descripcion: descripcion,
    moneda: moneda,
    montoTotal: total,
    totalCuotas: cuotas,
    periodo: '',
    tipoDescuento: tipo,
    estadoDescuento: estado,
    primeraCuotaMes: primera,
    ultimaCuotaMes: ultima,
    montoDescuento: monto,
    saldoRestante: saldo,
  );

  // Los casos que estiran el diseño: descripción larguísima, sin cuotas, una
  // sola cuota, varias cuotas en el mes y una segunda moneda.
  List<DescuentoEmpleadoEntity> descuentosDePrueba() => [
    desc(
      'Prestamo - Planilla',
      'Préstamo para vivienda con una descripción muy larga que ocupa varias líneas dentro de la tarjeta del descuento',
      monto: 1500.5,
      total: 18000,
      saldo: 12000.25,
      cuotas: 12,
      primera: 3,
      ultima: 3,
    ),
    desc(
      'Anticipo',
      'Anticipo de sueldo',
      monto: 500,
      total: 500,
      saldo: 0,
      estado: 'Pendiente',
    ),
    desc('Atrasos', 'Atrasos de septiembre', monto: 35.5, total: 35.5, saldo: 0),
    desc(
      'Multa',
      'Multa por inasistencia',
      monto: 120,
      total: 120,
      saldo: 0,
      cuotas: 4,
      primera: 1,
      ultima: 2,
    ),
    desc(
      'Multa',
      'Multa en dólares',
      moneda: 'USD',
      monto: 10,
      total: 10,
      saldo: 0,
    ),
  ];

  Future<void> elegirEmpleado(WidgetTester tester, {String? nombre}) async {
    await abrirSelector(tester);
    await tester.tap(find.text(nombre ?? 'PEREZ ACTIVO JUAN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Abre la pantalla, elige al empleado y devuelve los errores de dibujo.
  Future<List<FlutterErrorDetails>> verResultados(
    WidgetTester tester,
    double ancho,
  ) async {
    final errores = <FlutterErrorDetails>[];
    final previo = FlutterError.onError;
    FlutterError.onError = errores.add;
    await abrirPantalla(tester, ancho: ancho);
    await elegirEmpleado(tester);
    // Antes de cualquier expect: el binding exige el handler original.
    FlutterError.onError = previo;
    for (final e in errores) {
      debugPrint('DETALLE resultados a $ancho:\n$e');
    }
    return errores;
  }

  double arribaDe(WidgetTester tester, Finder texto) =>
      tester
          .getTopLeft(
            find.ancestor(of: texto, matching: find.byType(Card)).first,
          )
          .dy;

  double izquierdaDe(WidgetTester tester, Finder texto) =>
      tester
          .getTopLeft(
            find.ancestor(of: texto, matching: find.byType(Card)).first,
          )
          .dx;

  testWidgets('con descuentos muestra el resumen por moneda y una tarjeta cada uno', (
    tester,
  ) async {
    descuentos = descuentosDePrueba();
    final errores = await verResultados(tester, 1440);
    expect(errores, isEmpty);

    expect(find.textContaining('Resumen — '), findsOneWidget);
    expect(find.text('5 descuentos'), findsOneWidget);

    // Dos monedas: cada grupo se rotula y no se mezclan en un solo total.
    expect(find.text('Bs'), findsOneWidget);
    expect(find.text(r'$us'), findsOneWidget);
    expect(find.text('Bs 2,156.00'), findsOneWidget, reason: 'descontado en Bs');
    expect(
      find.text('Bs 18,655.50'),
      findsOneWidget,
      reason: 'monto total en Bs',
    );
    expect(
      find.text('Bs 12,000.25'),
      findsNWidgets(2),
      reason: 'saldo: el resumen y la tarjeta del préstamo',
    );

    // Las tres cifras en el resumen (por moneda) y en cada una de las 5 tarjetas.
    expect(find.text('Monto descontado'), findsNWidgets(2 + 5));
    expect(find.text('Monto total'), findsNWidgets(2 + 5));
    expect(find.text('Saldo pendiente'), findsNWidgets(2));
    expect(find.text('Saldo restante'), findsNWidgets(5));

    // El tipo en el encabezado de la tarjeta, y el estado.
    expect(find.text('Prestamo - Planilla'), findsOneWidget);
    expect(find.text('Anticipo'), findsOneWidget);
    expect(find.text('Atrasos'), findsOneWidget);
    expect(find.text('Multa'), findsNWidgets(2));
    expect(find.text('Pendiente'), findsOneWidget, reason: 'estado del anticipo');
    expect(find.text('Ejecutado'), findsWidgets);

    // Cuotas: una sola y varias en el mes, con su porcentaje.
    expect(find.text('Cuota 3 de 12'), findsOneWidget);
    expect(find.text('Cuotas 1–2 de 4'), findsOneWidget);
    expect(find.text('25 %'), findsOneWidget, reason: '3 de 12');
    expect(find.text('50 %'), findsOneWidget, reason: '2 de 4');
  });

  testWidgets('con una sola moneda no se rotula el grupo', (tester) async {
    descuentos = [desc('Anticipo', 'Anticipo de sueldo')];
    await verResultados(tester, 1440);

    expect(find.text('1 descuento'), findsOneWidget);
    expect(find.text('Bs'), findsNothing);
  });

  for (final ancho in [390.0, 1440.0]) {
    testWidgets('a ${ancho.toInt()} px las tarjetas van una debajo de otra', (
      tester,
    ) async {
      descuentos = descuentosDePrueba();
      await verResultados(tester, ancho);

      final primera = find.textContaining('Préstamo para vivienda');
      final segunda = find.text('Anticipo de sueldo');
      expect(
        arribaDe(tester, segunda),
        greaterThan(arribaDe(tester, primera)),
        reason: 'la segunda va debajo',
      );
      expect(
        izquierdaDe(tester, segunda),
        izquierdaDe(tester, primera),
        reason: 'y a todo el ancho: mismo borde izquierdo',
      );
    });
  }

  for (final ancho in [390.0, 800.0, 900.0, 1000.0, 1440.0]) {
    testWidgets('los resultados no desbordan a ${ancho.toInt()}', (
      tester,
    ) async {
      descuentos = descuentosDePrueba();
      final errores = await verResultados(tester, ancho);

      expect(errores, isEmpty, reason: 'a $ancho');
      expect(find.text('Cuota 3 de 12'), findsOneWidget);
    });

    testWidgets(
      'los resultados con texto al 150% no desbordan a ${ancho.toInt()}',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        descuentos = descuentosDePrueba();

        final errores = await verResultados(tester, ancho);

        expect(errores, isEmpty, reason: 'a $ancho');
        expect(find.text('Cuota 3 de 12'), findsOneWidget);
      },
    );
  }

  // ── Color ───────────────────────────────────────────────────────────────

  double contraste(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final alto = la > lb ? la : lb;
    final bajo = la > lb ? lb : la;
    return (alto + 0.05) / (bajo + 0.05);
  }

  // Fondos parecidos a las superficies reales del tema claro y del oscuro.
  const fondos = {
    Brightness.light: Color(0xFFF1F3EA),
    Brightness.dark: Color(0xFF1A1C18),
  };

  test('cada tipo tiene su matiz, distinto de los demás y legible', () {
    const tipos = ['Prestamo - Planilla', 'Anticipo', 'Atrasos', 'Multa', 'Otro'];
    for (final e in fondos.entries) {
      final usados = <Color>{};
      for (final tipo in tipos) {
        final c = estiloDeTipoDescuento(e.key, tipo).color;
        expect(
          contraste(c, e.value),
          greaterThanOrEqualTo(4.5),
          reason: '$tipo en ${e.key.name}',
        );
        usados.add(c);
      }
      expect(usados.length, tipos.length, reason: 'un matiz por tipo en ${e.key.name}');
    }
  });

  test('descontado, saldo y estados son legibles en claro y oscuro', () {
    for (final e in fondos.entries) {
      final colores = {
        'descontado': colorDescontado(e.key),
        'saldo': colorSaldo(e.key),
        'ejecutado': colorDeEstadoDescuento(e.key, 'Ejecutado'),
        'pendiente': colorDeEstadoDescuento(e.key, 'Pendiente'),
      };
      colores.forEach((nombre, c) {
        expect(
          contraste(c, e.value),
          greaterThanOrEqualTo(4.5),
          reason: '$nombre en ${e.key.name}',
        );
      });
    }
  });

  testWidgets('sin descuentos lo dice con el período', (tester) async {
    descuentos = [];
    await verResultados(tester, 1000);

    expect(find.text('Sin descuentos registrados'), findsOneWidget);
    expect(find.textContaining('No hay descuentos para'), findsOneWidget);
  });

  testWidgets('un fallo se muestra con Reintentar y se recupera', (
    tester,
  ) async {
    fallaDescuentos = Exception('sin conexión');
    await verResultados(tester, 1000);

    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Sin descuentos registrados'), findsNothing);

    fallaDescuentos = null;
    descuentos = [desc('Anticipo', 'Anticipo de sueldo')];
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Reintentar'), findsNothing);
    expect(find.text('Anticipo de sueldo'), findsOneWidget);
  });

  testWidgets('sin elegir empleado pide que se elija uno', (tester) async {
    await abrirPantalla(tester);

    expect(find.text('Selecciona un empleado'), findsOneWidget);
    expect(find.textContaining('Resumen'), findsNothing);
  });

  testWidgets('un empleado inactivo elegido queda marcado junto a su nombre', (
    tester,
  ) async {
    descuentos = [desc('Anticipo', 'Anticipo de sueldo')];
    await abrirPantalla(tester);
    await tester.tap(find.text('Incluir empleados inactivos'));
    await tester.pump();

    await elegirEmpleado(tester, nombre: 'GOMEZ INACTIVO LUIS');

    expect(find.text('Anticipo de sueldo'), findsOneWidget);
    // La etiqueta del encabezado de resultados.
    expect(find.text('Inactivo'), findsWidgets);
  });
}

/// Monta [child] un fotograma después de `ResponsiveBreakpoints`, como en la
/// app (ver depositos_cheques_pantallas_test.dart).
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
