// Capturas del módulo Tickets / Bingo, para mirarlas. NO es una prueba: no
// afirma nada y `flutter test` no la levanta sola. Se corre a mano:
//   flutter test test/capturas/capturas_ttk.dart --dart-define=CAPTURAS=<carpeta>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bosque_flutter/core/state/ttk_bingo_provider.dart';
import 'package:bosque_flutter/core/state/ttk_tickets_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_encargado_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_publico_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_vale_impresion_entity.dart';
import 'package:bosque_flutter/presentation/screens/tickets/ttk_bingo_cartones_screen.dart';
import 'package:bosque_flutter/presentation/screens/tickets/ttk_bingo_configuracion_screen.dart';
import 'package:bosque_flutter/presentation/screens/tickets/ttk_bingo_en_vivo_screen.dart';
import 'package:bosque_flutter/presentation/screens/tickets/ttk_bingo_panel_screen.dart';
import 'package:bosque_flutter/presentation/screens/tickets/ttk_eventos_screen.dart';
import 'package:bosque_flutter/presentation/screens/tickets/ttk_mi_carton_screen.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_pdf.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/repositorio_depositos.dart' show loginAdminFalso;
import '../fakes/repositorio_ttk.dart';

const _salida = String.fromEnvironment(
  'CAPTURAS',
  defaultValue: 'build/capturas_ttk',
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
  String nombre,
  Widget pantalla, {
  Size tam = const Size(1440, 900),
  TtkVivoFalso? vivo,
  TtkBingoFalso? bingo,
  Future<void> Function(WidgetTester tester)? antes,
}) async {
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
        ttkTicketsRepositoryProvider.overrideWithValue(TtkTicketsFalso()),
        ttkBingoRepositoryProvider.overrideWithValue(bingo ?? TtkBingoFalso()),
        ttkBingoVivoRepositoryProvider.overrideWithValue(
          vivo ?? TtkVivoFalso(),
        ),
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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // La foto del ganador arma su URL con AppConstants.baseUrl, que lee el .env.
    dotenv.testLoad(fileInput: '');
    await _cargarFuentes();
  });

  const telefono = Size(412, 900);
  Future<void> tocar(WidgetTester t, Finder f) async {
    await t.tap(f.first);
    await t.pump(const Duration(milliseconds: 300));
  }

  testWidgets('eventos', (t) async {
    await _capturar(t, 'eventos_escritorio', const TtkEventosScreen());
    await _capturar(
      t,
      'eventos_telefono',
      const TtkEventosScreen(),
      tam: telefono,
    );
    await _capturar(
      t,
      'evento_detalle_escritorio',
      const TtkEventosScreen(),
      antes: (t) => tocar(t, find.text('Aniversario 2026')),
    );
    await _capturar(
      t,
      'evento_detalle_telefono',
      const TtkEventosScreen(),
      tam: telefono,
      antes: (t) => tocar(t, find.text('Aniversario 2026')),
    );
  });

  testWidgets('vales en lote', (t) async {
    Future<void> seleccionar(WidgetTester t) async {
      await tocar(t, find.text('Aniversario 2026'));
      for (var i = 0; i < 6; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await t.pump(const Duration(milliseconds: 200));
      }
      await tocar(t, find.byType(Checkbox).at(1));
      await tocar(t, find.byType(Checkbox).at(3));
    }

    await _capturar(
      t,
      'participantes_seleccion_escritorio',
      const TtkEventosScreen(),
      antes: seleccionar,
    );
    await _capturar(
      t,
      'vales_lote_dialogo',
      const TtkEventosScreen(),
      antes: (t) async {
        await seleccionar(t);
        await tocar(t, find.byKey(const ValueKey('ttk-vales-lote')));
      },
    );
    await _capturar(
      t,
      'participantes_seleccion_telefono',
      const TtkEventosScreen(),
      tam: telefono,
      antes: (t) async {
        await tocar(t, find.text('Aniversario 2026'));
        for (var i = 0; i < 6; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await t.pump(const Duration(milliseconds: 200));
        }
        await tocar(t, find.byType(Checkbox).at(1));
      },
    );
  });

  testWidgets('configuracion', (t) async {
    await _capturar(
      t,
      'config_escritorio',
      const TtkBingoConfiguracionScreen(),
    );
    await _capturar(
      t,
      'config_telefono',
      const TtkBingoConfiguracionScreen(),
      tam: telefono,
    );
    await _capturar(
      t,
      'config_juegos_escritorio',
      const TtkBingoConfiguracionScreen(),
      antes: (t) => tocar(t, find.text('Juegos y figuras (8)')),
    );
    await _capturar(
      t,
      'config_figura_dialogo',
      const TtkBingoConfiguracionScreen(),
      antes: (t) async {
        await tocar(t, find.text('Juegos y figuras (8)'));
        for (var i = 0; i < 6; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await t.pump(const Duration(milliseconds: 200));
        }
        await tocar(t, find.text('Editar figura y premio'));
      },
    );
    await _capturar(
      t,
      'cartones_telefono',
      const TtkBingoCartonesScreen(),
      tam: telefono,
    );
    await _capturar(t, 'cartones_escritorio', const TtkBingoCartonesScreen());
    // Bingo recién creado y pantalla alta, para ver el formulario de parámetros entero.
    await _capturar(
      t,
      'config_parametros_escritorio',
      const TtkBingoConfiguracionScreen(),
      tam: const Size(1440, 1700),
      bingo: TtkBingoFalso()..bingo = bingoEnConfiguracionFalso,
    );
    await _capturar(
      t,
      'config_parametros_telefono',
      const TtkBingoConfiguracionScreen(),
      tam: const Size(412, 2600),
      bingo: TtkBingoFalso()..bingo = bingoEnConfiguracionFalso,
      antes: (t) async {
        final letras = find.widgetWithText(TextField, 'Letras del encabezado');
        await t.ensureVisible(letras);
        await t.enterText(letras, 'BING');
      },
    );
  });

  testWidgets('panel', (t) async {
    final vivo = TtkVivoFalso();
    await _capturar(
      t,
      'panel_escritorio_alerta',
      const TtkBingoPanelScreen(),
      vivo: vivo,
      antes: (t) async {
        vivo.emitirEncargado(
          TtkEstadoEncargadoEntity(
            version: 9,
            publico: publicoFalso(),
            tablero: tableroFalso(),
            ranking: rankingFalso(conBingoNuevo: true),
            aviso: '¡BINGO! El cartón 7 completó la figura con el bolillo 28.',
          ),
        );
      },
    );
    await _capturar(
      t,
      'panel_telefono',
      const TtkBingoPanelScreen(),
      tam: telefono,
    );
  });

  testWidgets('mi carton', (t) async {
    await _capturar(t, 'mi_carton_escritorio', const TtkMiCartonScreen());
    await _capturar(
      t,
      'mi_carton_telefono',
      const TtkMiCartonScreen(),
      tam: telefono,
    );
    await _capturar(
      t,
      'elegir_telefono',
      const TtkMiCartonScreen(),
      tam: telefono,
      antes: (t) => tocar(t, find.text('Elegir mi cartón')),
    );
    await _capturar(
      t,
      'elegir_confirmar_telefono',
      const TtkMiCartonScreen(),
      tam: telefono,
      antes: (t) async {
        await tocar(t, find.text('Elegir mi cartón'));
        await t.pump(const Duration(milliseconds: 400));
        await tocar(t, find.text('0003'));
      },
    );
    await _capturar(
      t,
      'carton_elegido_escritorio',
      const TtkMiCartonScreen(),
      antes: (t) async {
        await tocar(t, find.text('Elegir mi cartón'));
        await t.pump(const Duration(milliseconds: 400));
        await tocar(t, find.text('0003'));
        await t.pump(const Duration(milliseconds: 400));
        await tocar(t, find.text('Elegir este cartón'));
        for (var i = 0; i < 6; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await t.pump(const Duration(milliseconds: 200));
        }
      },
    );
  });

  testWidgets('mesa de cartones', (t) async {
    await _capturar(
      t,
      'mesa_escritorio_hover',
      const TtkMiCartonScreen(),
      antes: (t) async {
        await tocar(t, find.text('Elegir mi cartón'));
        for (var i = 0; i < 12; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await t.pump(const Duration(milliseconds: 200));
        }
        final hoja = t.getRect(find.text('0012'));
        final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(hoja.center + const Offset(30, -60));
        await t.pump(const Duration(milliseconds: 100));
        await mouse.moveTo(hoja.center + const Offset(45, -70));
        await t.pump(const Duration(milliseconds: 300));
      },
    );
    await _capturar(
      t,
      'mesa_telefono',
      const TtkMiCartonScreen(),
      tam: telefono,
      antes: (t) async {
        await tocar(t, find.text('Elegir mi cartón'));
        for (var i = 0; i < 12; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await t.pump(const Duration(milliseconds: 200));
        }
      },
    );
  });

  testWidgets('jugar', (t) async {
    TtkBingoFalso enJuego() =>
        TtkBingoFalso()
          ..estadoParticipante = 'EN_JUEGO'
          ..puedeAvisar = true;
    Future<void> jugar(WidgetTester t) async {
      await tocar(t, find.text('Jugar con mi cartón'));
      for (var i = 0; i < 10; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await t.pump(const Duration(milliseconds: 200));
      }
      final semantica = t.ensureSemantics();
      for (final n in ['I 21', 'N 36', 'G 54']) {
        final f = find.bySemanticsLabel(n);
        if (f.evaluate().isNotEmpty) await tocar(t, f);
      }
      semantica.dispose();
    }

    await _capturar(
      t,
      'jugar_telefono',
      const TtkMiCartonScreen(),
      tam: telefono,
      bingo: enJuego(),
      antes: jugar,
    );
    // Las marcas del teléfono quedaron guardadas: se parte de cero.
    SharedPreferences.setMockInitialValues({});
    await _capturar(
      t,
      'jugar_escritorio',
      const TtkMiCartonScreen(),
      bingo: enJuego(),
      antes: jugar,
    );
  });

  testWidgets('en vivo', (t) async {
    await _capturar(
      t,
      'en_vivo_proyector',
      TtkBingoEnVivoScreen(codBingo: BigInt.one),
      tam: const Size(1920, 1080),
    );
    await _capturar(
      t,
      'en_vivo_telefono',
      TtkBingoEnVivoScreen(codBingo: BigInt.one),
      tam: const Size(390, 844),
    );
    final vivo = TtkVivoFalso();
    await _capturar(
      t,
      'en_vivo_proyector_ganador',
      TtkBingoEnVivoScreen(codBingo: BigInt.one),
      tam: const Size(1920, 1080),
      vivo: vivo,
      antes: (t) async {
        vivo.emitirPublico(
          TtkEstadoPublicoEntity(
            version: 9,
            publico: publicoFalso(hayGanador: true, nroGanadores: 2),
            tablero: tableroFalso(),
            ganadores: ganadoresVivoFalsos(),
          ),
        );
      },
    );
    await _capturar(
      t,
      'en_vivo_laptop',
      TtkBingoEnVivoScreen(codBingo: BigInt.one),
      tam: const Size(1366, 768),
    );
  });

  testWidgets('asignar', (t) async {
    await _capturar(
      t,
      'cartones_asignar_dialogo',
      const TtkBingoCartonesScreen(),
      antes: (t) async {
        for (var i = 0; i < 6; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await t.pump(const Duration(milliseconds: 200));
        }
        await tocar(t, find.byTooltip('Asignar'));
      },
    );
  });

  // Los PDF quedan en la misma carpeta para revisarlos (no son capturas de pantalla).
  testWidgets('pdf de vales y cartones', (t) async {
    final colores = [null, '#7FB3D5', null, '#F8C471'];
    final tipos = ['Almuerzo', 'Bebida', 'Bingo', 'Torta'];
    final personas = [
      'Quispe Mamani Juan Carlos',
      'Rojas Vargas María Fernanda',
      'Ana Gutiérrez',
    ];
    var nro = 1;
    final vales = <TtkValeImpresionEntity>[
      for (var p = 0; p < personas.length; p++)
        for (var k = 0; k < (p == 0 ? 6 : 3); k++)
          TtkValeImpresionEntity(
            codEvento: BigInt.one,
            nombreEvento: 'Aniversario 2026',
            fechaEvento: DateTime(2026, 12, 20),
            lugar: 'Salón Los Pinos',
            codTipoTicket: BigInt.from(k % 4),
            nombreTipo: tipos[k % 4],
            leyenda: 'Válido el día del evento',
            colorHex: colores[k % 4],
            codParticipante: BigInt.from(p),
            nombreParticipante: personas[p],
            categoriaTexto: p == 2 ? 'Invitado' : 'Empleado',
            nroTicket: nro,
            nroTicketTexto: (nro++).toString().padLeft(4, '0'),
          ),
    ];
    await t.runAsync(() async {
      final pdf = await ttkPdfVales(vales);
      File('$_salida/vales.pdf')
        ..createSync(recursive: true)
        ..writeAsBytesSync(pdf);
      final cartones = await ttkPdfCartones(
        celdasFalsas(7, juegos: 8),
        nombreEvento: 'Aniversario 2026',
        letras: 'BINGO',
      );
      File('$_salida/cartones.pdf').writeAsBytesSync(cartones);
    });
  });
}
