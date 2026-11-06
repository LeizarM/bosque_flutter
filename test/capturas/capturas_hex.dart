// Capturas del módulo Horas Extras para mirarlas; no afirma nada. A mano:
//   flutter test test/capturas/capturas_hex.dart --dart-define=CAPTURAS=<dir>
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

import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_requisito_marca_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_mis_horas_screen.dart';

import '../fakes/repositorio_depositos.dart' show loginAdminFalso;
import '../fakes/repositorio_hex.dart';
import '../fakes/ubicacion_hex_falsa.dart';

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
  required HexReporteFalso repo,
  Size tam = const Size(1400, 1300),
  Future<void> Function(WidgetTester tester)? antes,
}) async {
  // Cada captura es la primera visita: «¿Cómo funciona?» abierta.
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
        hexReporteRepositoryProvider.overrideWithValue(repo),
        hexUbicacionProvider.overrideWithValue(UbicacionHexFalsa()),
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
          home: const Scaffold(body: HexMisHorasScreen()),
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

/// Un reporte rechazado con su motivo, para ver el aviso en la tarjeta.
final _rechazado = HexReporteEntity(
  idReporte: BigInt.from(105),
  fechaJornada: DateTime(2026, 10, 20),
  tipo: 'DESPUES',
  tipoTexto: 'Después del horario',
  tipoDia: 'HABIL',
  tipoDiaTexto: 'Hábil',
  inicio: DateTime(2026, 10, 20, 18),
  fin: DateTime(2026, 10, 20, 21),
  origenInicio: 'HORARIO',
  origenFin: 'APP',
  montoTotal: 60,
  estado: 'RECHAZADO',
  estadoTexto: 'Rechazado',
  textoPendiente: 'Rechazado por Rojas Vargas Luis',
  motivoRechazo: 'Ese día no hubo descarga; la salida real fue a las 18:05.',
  totalFilas: 5,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.testLoad(fileInput: '');
    await _cargarFuentes();
  });

  testWidgets('mis horas', (t) async {
    HexReporteFalso repo() =>
        HexReporteFalso()..programar('misReportes', [
          (filas: [...reportesFalsos, _rechazado], total: 5),
        ]);
    await _capturar(t, 'mis_horas_escritorio', repo: repo());
    await _capturar(
      t,
      'mis_horas_telefono',
      repo: repo(),
      tam: const Size(390, 2600),
    );
    final trabado =
        repo()..programar('requisitosMarca', [
          [
            ...requisitosFalsos.take(3),
            const HexRequisitoMarcaEntity(
              requisito: 'HORARIO',
              cumple: false,
              bloquea: true,
              titulo: 'Horario asignado en el biométrico',
              detalle: 'Pide a RRHH que te asigne un horario en el biométrico.',
              orden: 4,
            ),
          ],
        ]);
    await _capturar(
      t,
      'marcacion_trabada_telefono',
      repo: trabado,
      tam: const Size(390, 1100),
    );
    final error =
        repo()..programar('marcar', [
          const NegocioHex('No tienes horario asignado para hoy (error 23).'),
        ]);
    await _capturar(
      t,
      'marcacion_resultado_telefono',
      repo: error,
      tam: const Size(390, 1300),
      antes: (t) async => t.tap(find.text('Marcar salida')),
    );
    await _capturar(
      t,
      'detalle_telefono',
      repo: repo(),
      tam: const Size(390, 1500),
      antes: (t) async {
        await t.scrollUntilVisible(
          find.text('Jornada 23/10/2026'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await t.tap(find.text('Jornada 23/10/2026'));
      },
    );
  });
}
