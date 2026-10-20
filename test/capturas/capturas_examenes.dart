// Capturas de las pantallas del módulo de exámenes, para mirarlas.
//
// NO es una prueba: no afirma nada y `flutter test` no la levanta solo (el
// nombre no termina en _test.dart). Se corre a mano:
//
//   flutter test test/capturas/capturas_examenes.dart --dart-define=CAPTURAS=<carpeta>
//
// Opcionales: --dart-define=SEMILLA=<0..8> (color del tema) y OSCURO=true.
// Usa los repositorios falsos de las pruebas y las fuentes reales del proyecto.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/state/postulante_examen_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_duplicado_pregunta_entity.dart';
import 'package:bosque_flutter/presentation/screens/screens.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/destinatarios_lote.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/repositorio_depositos.dart' show loginAdminFalso;
import '../fakes/repositorio_examenes.dart';
import '../fakes/repositorio_rendicion_examen.dart';

const _salida = String.fromEnvironment('CAPTURAS', defaultValue: 'build/capturas');
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
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(iconos.readAsBytesSync())))).load();
  }
}

Future<void> _capturar(
  WidgetTester tester,
  String nombre,
  Widget pantalla, {
  Size tam = const Size(1440, 900),
  Future<void> Function(WidgetTester tester)? antes,
  PostulanteFalso? postulante,
  ExamenesFalso? repo,
}) async {
  tester.view.physicalSize = tam;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final clave = GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      key: ValueKey(nombre),
      overrides: [
        userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(loginAdminFalso)),
        examenesRepositoryProvider.overrideWithValue(repo ?? ExamenesFalso()),
        postulanteExamenRepositoryProvider.overrideWithValue(postulante ?? PostulanteFalso()),
      ],
      child: RepaintBoundary(
        key: clave,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme(selectedColor: _semilla, isDarkMode: _oscuro).getTheme(),
          locale: const Locale('es'),
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder:
              (context, child) =>
                  ResponsiveBreakpoints.builder(child: child!, breakpoints: ResponsiveUtilsBosque.breakpoints),
          home: Scaffold(body: pantalla),
        ),
      ),
    ),
  );
  Future<void> dejarQueCargue() async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  await dejarQueCargue();
  if (antes != null) {
    await antes(tester);
    await dejarQueCargue();
  }
  await tester.runAsync(() async {
    final boundary = clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final imagen = await boundary.toImage(pixelRatio: 1);
    final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
    File('$_salida/$nombre.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
  // Desmonta: el reloj de la rendición no queda corriendo.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _cargarFuentes();
  });

  const telefono = Size(412, 900);

  Future<void> tocar(WidgetTester t, Finder f) async {
    await t.tap(f.first);
    await t.pump(const Duration(milliseconds: 300));
  }

  testWidgets('banco', (t) async {
    await _capturar(t, 'banco_escritorio', const BancoPreguntasScreen());
    await _capturar(t, 'banco_telefono', const BancoPreguntasScreen(), tam: telefono);
    await _capturar(
      t,
      'banco_nueva_pregunta',
      const BancoPreguntasScreen(),
      antes: (t) => tocar(t, find.text('Nueva pregunta')),
    );
    await _capturar(
      t,
      'banco_opcion_valida',
      const BancoPreguntasScreen(),
      antes: (t) async {
        await tocar(t, find.text('Nueva pregunta'));
        await t.enterText(find.widgetWithText(TextField, 'Opción a'), 'Guantes anticorte');
        await t.enterText(find.widgetWithText(TextField, 'Opción b'), 'Gorra');
        await tocar(t, find.text('a'));
      },
    );
    // El aviso mientras se escribe: con la categoría elegida en el panel, para que la pregunta nueva la traiga.
    Future<void> escribirEnCategoria(WidgetTester t) async {
      await tocar(t, find.text('Seguridad industrial'));
      await tocar(t, find.text('Nueva pregunta'));
      await t.enterText(find.widgetWithText(TextFormField, 'Pregunta'), 'Qué es el trabajo neto');
    }

    await _capturar(
      t,
      'banco_parecidas',
      const BancoPreguntasScreen(),
      repo:
          ExamenesFalso()
            ..duplicados = [
              TcpeDuplicadoPreguntaEntity(codPregunta: BigInt.from(3), pregunta: '¿Qué representa el capital de trabajo neto?'),
              TcpeDuplicadoPreguntaEntity(
                codPregunta: BigInt.from(4),
                pregunta: '¿Cómo se calcula el capital de trabajo neto de una empresa industrial?',
                activo: false,
              ),
            ],
      antes: escribirEnCategoria,
    );
    await _capturar(
      t,
      'banco_igual',
      const BancoPreguntasScreen(),
      repo:
          ExamenesFalso()
            ..duplicados = [
              TcpeDuplicadoPreguntaEntity(codPregunta: BigInt.from(3), pregunta: '¿Qué es el trabajo neto?', igual: true),
            ],
      antes: escribirEnCategoria,
    );
    await _capturar(
      t,
      'banco_nueva_abierta',
      const BancoPreguntasScreen(),
      antes: (t) async {
        await tocar(t, find.text('Nueva pregunta'));
        await tocar(t, find.descendant(of: find.byType(AlertDialog), matching: find.text('Abierta')));
      },
    );
  });

  testWidgets('lotes', (t) async {
    await _capturar(t, 'lotes_escritorio', const LotesExamenScreen());
    await _capturar(t, 'lotes_telefono', const LotesExamenScreen(), tam: telefono);
    await _capturar(
      t,
      'lote_detalle',
      const LotesExamenScreen(),
      antes: (t) => tocar(t, find.textContaining('Convocatoria operadores')),
    );
    await _capturar(
      t,
      'lote_detalle_telefono',
      const LotesExamenScreen(),
      tam: telefono,
      antes: (t) => tocar(t, find.textContaining('Convocatoria operadores')),
    );
  });

  testWidgets('seguimiento', (t) async {
    await _capturar(t, 'en_vivo', EnVivoExamenScreen(loteInicial: BigInt.from(40)));
    await _capturar(t, 'en_vivo_telefono', EnVivoExamenScreen(loteInicial: BigInt.from(40)), tam: telefono);
    await _capturar(t, 'resultados', ResultadosExamenScreen(loteInicial: BigInt.from(40)));
    await _capturar(t, 'informes', const InformesExamenScreen());
    await _capturar(t, 'usuarios_externos', const UsuariosExternosScreen());
    await _capturar(t, 'mis_examenes', const MisExamenesScreen());
  });

  testWidgets('empleados', (t) async {
    final abrir = Builder(
      builder:
          (context) => Center(
            child: FilledButton(
              onPressed: () => elegirEmpleados(context, {BigInt.from(181)}),
              child: const Text('abrir'),
            ),
          ),
    );
    await _capturar(t, 'elegir_empleados', abrir, antes: (t) => tocar(t, find.text('abrir')));
    await _capturar(t, 'elegir_empleados_telefono', abrir, tam: telefono, antes: (t) => tocar(t, find.text('abrir')));
  });

  testWidgets('publico', (t) async {
    await _capturar(t, 'ingreso', const IngresoExamenScreen());
    await _capturar(t, 'registro', const RegistroExamenScreen());
    await _capturar(t, 'rendir', const RendirExamenScreen(codExamen: '10'));
    await _capturar(t, 'rendir_telefono', const RendirExamenScreen(codExamen: '10'), tam: telefono);
    await _capturar(
      t,
      'resultado',
      const ResultadoExamenScreen(codExamen: '10'),
      postulante: PostulanteFalso(estado: 'CALIFICADO'),
    );
  });
}
