// Capturas de la parte 2 del rediseño de Horas Extras para mirarlas; no
// afirma nada. A mano:
//   flutter test test/capturas/capturas_hex2.dart --dart-define=CAPTURAS=<dir>
// OSCURO=true y SEMILLA=<0..8> (también con --dart-define) cambian el tema.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bosque_flutter/core/state/hex_configuracion_provider.dart';
import 'package:bosque_flutter/core/state/hex_planilla_provider.dart';
import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_previa_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_aprobacion_screen.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_aprobadores_screen.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_parametros_screen.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_planilla_screen.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_revision_screen.dart';

import '../fakes/repositorio_depositos.dart' show loginAdminFalso;
import '../fakes/repositorio_hex.dart';

const _salida = String.fromEnvironment(
  'CAPTURAS',
  defaultValue: 'build/capturas_hex',
);
const _semilla = int.fromEnvironment('SEMILLA', defaultValue: 2);
const _oscuro = bool.fromEnvironment('OSCURO');

Future<void> _cargarFuentes() async {
  final porFamilia = <String, List<File>>{};
  for (final f in Directory('assets/fonts').listSync().whereType<File>()) {
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
  String nombre, {
  required Widget pantalla,
  required List<Override> overrides,
  Size tam = const Size(1400, 1000),
  Future<void> Function(WidgetTester tester)? antes,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = tam;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final clave = GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      key: ValueKey(nombre),
      overrides: [
        userProvider.overrideWith(
          (ref) => UserStateNotifier.sinStorage(loginAdminFalso),
        ),
        ...overrides,
      ],
      child: RepaintBoundary(
        key: clave,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme:
              AppTheme(selectedColor: _semilla, isDarkMode: _oscuro).getTheme(),
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
          home: Scaffold(body: pantalla),
        ),
      ),
    ),
  );
  Future<void> dejarQueCargue() async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  await dejarQueCargue();
  if (antes != null) {
    await antes(tester);
    await dejarQueCargue();
  }
  await tester.pump(const Duration(seconds: 1));
  await tester.runAsync(() async {
    final boundary =
        clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final imagen = await boundary.toImage(pixelRatio: 1);
    final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
    File('$_salida/$nombre.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

HexReporteEntity _conVistoBueno({
  int id = 301,
  String nombre = 'Mamani Quispe Juan Carlos',
  String estado = 'VISTO_BUENO',
}) => HexReporteEntity(
  idReporte: BigInt.from(id),
  codEmpleado: BigInt.from(20),
  nombreEmpleado: nombre,
  fechaJornada: DateTime(2026, 10, 23),
  tipo: 'DESPUES',
  tipoTexto: 'Después del horario',
  tipoDia: 'HABIL',
  tipoDiaTexto: 'Hábil',
  codSucursal: BigInt.one,
  nombreSucursal: 'Planta El Alto',
  inicio: DateTime(2026, 10, 23, 18),
  fin: DateTime(2026, 10, 23, 23),
  origenInicio: 'HORARIO',
  origenFin: 'BIOMETRICO',
  horasPagables: 5,
  montoTotal: 130,
  comidas: 'C',
  costoHora: 20,
  estado: estado,
  estadoTexto: estado == 'VISTO_BUENO' ? 'Con visto bueno' : 'Reportado',
  textoPendiente:
      estado == 'VISTO_BUENO'
          ? 'Espera la aprobación de Paredes Limachi Rosa'
          : 'Espera el visto bueno de Rojas Vargas Luis',
  puedeAprobar: estado == 'VISTO_BUENO',
  puedeVistoBueno: estado == 'REPORTADO',
  puedeRechazar: true,
  puedeEditarHora: true,
  codEncargado: BigInt.from(7),
  nombreEncargado: 'Rojas Vargas Luis',
  totalFilas: 40,
);

final _pendientes = [
  HexPendienteEntity(
    codEmpresa: BigInt.two,
    codSucursal: BigInt.from(3),
    nombreSucursal: 'Planta El Alto',
    anio: 2026,
    mes: 10,
    cantidadReportes: 5,
  ),
  HexPendienteEntity(
    codEmpresa: BigInt.two,
    codSucursal: BigInt.from(4),
    nombreSucursal: 'Almacén Central',
    anio: 2026,
    mes: 9,
    cantidadReportes: 2,
  ),
];

final _previa = [
  HexPrevistaEmpleadoEntity(
    codEmpleado: BigInt.from(41),
    nombreEmpleado: 'Choque Flores Pedro',
    nombreArea: 'Producción',
    montoComidas: 15,
    total: 15,
    esProvisional: true,
    cantidadReportes: 1,
  ),
  HexPrevistaEmpleadoEntity(
    codEmpleado: BigInt.from(40),
    nombreEmpleado: 'Mamani Quispe Juan',
    nombreArea: 'Producción',
    montoHoras: 245.5,
    montoComidas: 30,
    total: 275.5,
    cantidadReportes: 2,
    tieneAvisoBiometrico: true,
    tienePeriodoAnterior: true,
  ),
];

final _avisos = [
  HexAvisoEntity(
    idReporte: BigInt.from(101),
    codEmpleado: BigInt.from(40),
    nombreEmpleado: 'Mamani Quispe Juan',
    fechaJornada: DateTime(2026, 10, 5),
    tipoAviso: 'BIOMETRICO',
    detalle:
        'El biométrico registra la salida a las 22:05; el reporte dice 21:30.',
  ),
  HexAvisoEntity(
    idReporte: BigInt.from(102),
    codEmpleado: BigInt.from(41),
    nombreEmpleado: 'Choque Flores Pedro',
    fechaJornada: DateTime(2026, 10, 12),
    tipoAviso: 'PROVISIONAL',
    detalle: 'El haber básico aún no está confirmado: el monto puede cambiar.',
  ),
  HexAvisoEntity(
    idReporte: BigInt.from(104),
    codEmpleado: BigInt.from(43),
    nombreEmpleado: 'Quispe Limachi Rosa',
    fechaJornada: DateTime(2026, 10, 20),
    tipoAviso: 'SIN_HABER',
    detalle: 'No figura en la planilla de sueldos: el reporte no se liquida.',
  ),
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.testLoad(fileInput: '');
    await _cargarFuentes();
  });

  testWidgets('revisión y aprobación', (t) async {
    final revision =
        HexReporteFalso()..programar('bandejaEncargado', [
          (
            filas: [
              _conVistoBueno(
                id: 201,
                nombre: 'Mamani Quispe Juan Carlos',
                estado: 'REPORTADO',
              ),
              _conVistoBueno(
                id: 202,
                nombre: 'Condori Huanca María',
                estado: 'REPORTADO',
              ),
            ],
            total: 47,
          ),
        ]);
    List<Override> sobre(HexReporteFalso r) => [
      hexReporteRepositoryProvider.overrideWithValue(r),
    ];
    await _capturar(
      t,
      'revision_telefono',
      pantalla: const HexRevisionScreen(),
      overrides: sobre(revision),
      tam: const Size(390, 1500),
    );
    await _capturar(
      t,
      'revision_escritorio',
      pantalla: const HexRevisionScreen(),
      overrides: sobre(revision),
      tam: const Size(1500, 700),
    );
    final jefe =
        HexReporteFalso()..programar('bandejaJefe', [
          (filas: [_conVistoBueno()], total: 40),
        ]);
    await _capturar(
      t,
      'aprobacion_telefono',
      pantalla: const HexAprobacionScreen(),
      overrides: sobre(jefe),
      tam: const Size(390, 1300),
    );
    await _capturar(
      t,
      'aprobacion_escritorio',
      pantalla: const HexAprobacionScreen(),
      overrides: sobre(jefe),
      tam: const Size(1500, 700),
    );
    await _capturar(
      t,
      'dialogo_rechazo',
      pantalla: const HexRevisionScreen(),
      overrides: sobre(revision),
      tam: const Size(390, 844),
      antes: (t) async {
        Future<void> esperar() async {
          for (var i = 0; i < 5; i++) {
            await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 20)),
            );
            await t.pump(const Duration(milliseconds: 150));
          }
        }

        await t.tap(find.byIcon(Icons.more_vert).first);
        await esperar();
        await t.tap(find.text('Rechazar').last);
        await esperar();
      },
    );
  });

  testWidgets('planilla', (t) async {
    final repo =
        HexPlanillaFalso()
          ..programar('pendientes', [_pendientes])
          ..programar('vistaPrevia', [_previa])
          ..programar('avisos', [_avisos]);
    final sobre = [hexPlanillaRepositoryProvider.overrideWithValue(repo)];
    await _capturar(
      t,
      'planilla_lista_telefono',
      pantalla: const HexPlanillaScreen(),
      overrides: sobre,
      tam: const Size(390, 760),
    );
    await _capturar(
      t,
      'planilla_previa_telefono',
      pantalla: const HexPlanillaScreen(),
      overrides: sobre,
      tam: const Size(390, 1900),
      antes: (t) async => t.tap(find.text('Planta El Alto').first),
    );
    await _capturar(
      t,
      'planilla_previa_escritorio',
      pantalla: const HexPlanillaScreen(),
      overrides: sobre,
      tam: const Size(1400, 1300),
      antes: (t) async => t.tap(find.text('Planta El Alto').first),
    );
    await _capturar(
      t,
      'planilla_ejecutar_telefono',
      pantalla: const HexPlanillaScreen(),
      overrides: sobre,
      tam: const Size(390, 1000),
      antes: (t) async {
        Future<void> esperar() async {
          for (var i = 0; i < 8; i++) {
            await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 20)),
            );
            await t.pump(const Duration(milliseconds: 150));
          }
        }

        await t.tap(find.text('Planta El Alto').first);
        await esperar();
        await t.tap(find.text('Ejecutar planilla').first);
        await esperar();
      },
    );
    await _capturar(
      t,
      'planilla_ejecutadas_telefono',
      pantalla: const HexPlanillaScreen(),
      overrides: sobre,
      tam: const Size(390, 1000),
      antes: (t) async => t.tap(find.text('Ejecutadas')),
    );
  });

  testWidgets('configuración', (t) async {
    final parametros = [
      HexParametroEntity(
        idParametro: BigInt.one,
        clave: 'DIVISOR_COSTO_HORA',
        valorNumero: 240,
        leyenda: 'Divisor del costo hora (30 días × 8 h)',
        vigenteDesde: DateTime(2026, 1, 1),
        esVigente: true,
        estadoVigencia: 'VIGENTE',
        textoVigencia: 'Rige desde el 01/01/2026',
      ),
      HexParametroEntity(
        idParametro: BigInt.two,
        clave: 'DIVISOR_COSTO_HORA',
        valorNumero: 250,
        leyenda: 'Divisor del costo hora (nuevo año)',
        vigenteDesde: DateTime(2027, 3, 1),
        estadoVigencia: 'PROGRAMADA',
        textoVigencia: 'Empieza a regir el 01/03/2027',
      ),
      HexParametroEntity(
        idParametro: BigInt.from(4),
        clave: 'DIVISOR_COSTO_HORA',
        valorNumero: 230,
        leyenda: 'Divisor anterior',
        vigenteDesde: DateTime(2025, 1, 1),
        vigenteHasta: DateTime(2025, 12, 31),
        estadoVigencia: 'VENCIDA',
        textoVigencia: 'Rigió hasta el 31/12/2025',
      ),
    ];
    final repo = HexConfiguracionFalso()..programar('parametros', [parametros]);
    final sobre = [hexConfiguracionRepositoryProvider.overrideWithValue(repo)];
    await _capturar(
      t,
      'config_escritorio',
      pantalla: const HexParametrosScreen(),
      overrides: sobre,
      tam: const Size(1400, 1100),
    );
    await _capturar(
      t,
      'config_telefono',
      pantalla: const HexParametrosScreen(),
      overrides: sobre,
      tam: const Size(390, 1500),
    );
    await _capturar(
      t,
      'config_comidas_telefono',
      pantalla: const HexParametrosScreen(),
      overrides: sobre,
      tam: const Size(390, 1300),
      antes: (t) async => t.tap(find.text('Comidas').first),
    );
    await _capturar(
      t,
      'aprobadores_telefono',
      pantalla: const HexAprobadoresScreen(),
      overrides: sobre,
      tam: const Size(390, 1000),
    );
    await _capturar(
      t,
      'aprobadores_escritorio',
      pantalla: const HexAprobadoresScreen(),
      overrides: sobre,
      tam: const Size(1400, 700),
    );
  });
}
