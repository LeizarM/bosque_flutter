import 'dart:io';

import 'package:bosque_flutter/core/state/ttk_bingo_provider.dart';
import 'package:bosque_flutter/core/state/ttk_tickets_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_encargado_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_publico_entity.dart';
import 'package:bosque_flutter/presentation/screens/tickets/ttk_bingo_configuracion_screen.dart';
import 'package:bosque_flutter/presentation/screens/tickets/ttk_bingo_en_vivo_screen.dart';
import 'package:bosque_flutter/presentation/screens/tickets/ttk_bingo_panel_screen.dart';
import 'package:bosque_flutter/presentation/screens/tickets/ttk_eventos_screen.dart';
import 'package:bosque_flutter/presentation/screens/tickets/ttk_mi_carton_screen.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/repositorio_depositos.dart' show loginAdminFalso;
import 'fakes/repositorio_ttk.dart';

/// Las cinco pantallas de Tickets / Bingo con datos falsos: sin desbordes en
/// teléfono, tablet y escritorio; tabla en el ancho, tarjetas en el angosto;
/// el panel avisa el bingo nuevo y el en vivo solo dice que hubo ganador.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  setUpAll(() async {
    Future<void> cargar(String familia, List<String> archivos) async {
      final c = FontLoader(familia);
      for (final a in archivos) {
        final f = File('assets/fonts/$a.ttf');
        if (f.existsSync()) {
          c.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
        }
      }
      await c.load();
    }

    await cargar('Roboto', ['Roboto-Regular', 'Roboto-Medium', 'Roboto-Bold']);
    await cargar('JetBrainsMono', [
      'JetBrainsMono-400',
      'JetBrainsMono-500',
      'JetBrainsMono-700',
    ]);
  });

  Widget app(Widget pantalla, TtkVivoFalso vivo, TtkBingoFalso bingo) =>
      ProviderScope(
        overrides: [
          userProvider.overrideWith(
            (ref) => UserStateNotifier.sinStorage(loginAdminFalso),
          ),
          ttkTicketsRepositoryProvider.overrideWithValue(TtkTicketsFalso()),
          ttkBingoRepositoryProvider.overrideWithValue(bingo),
          ttkBingoVivoRepositoryProvider.overrideWithValue(vivo),
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
          home: Scaffold(body: _UnFotogramaDespues(child: pantalla)),
        ),
      );

  /// Corre [paso] juntando los errores de dibujo (desbordes) que produzca.
  Future<List<FlutterErrorDetails>> conErrores(
    Future<void> Function() paso,
  ) async {
    final errores = <FlutterErrorDetails>[];
    final previo = FlutterError.onError;
    FlutterError.onError = errores.add;
    try {
      await paso();
    } finally {
      // Se restaura antes de cualquier expect: si no, el binding se cuelga.
      FlutterError.onError = previo;
    }
    return errores;
  }

  Future<void> esperar(WidgetTester tester, [int veces = 6]) async {
    for (var i = 0; i < veces; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// Monta, espera los datos y devuelve los errores de dibujo.
  Future<List<FlutterErrorDetails>> abrir(
    WidgetTester tester,
    Widget pantalla, {
    required double ancho,
    TtkVivoFalso? vivo,
    TtkBingoFalso? bingo,
  }) async {
    tester.view.physicalSize = Size(ancho, ancho <= 450 ? 844 : 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    return conErrores(() async {
      await tester.pumpWidget(
        app(pantalla, vivo ?? TtkVivoFalso(), bingo ?? TtkBingoFalso()),
      );
      await esperar(tester);
    });
  }

  /// Desmonta todo: así se cierran la suscripción y el sondeo del en vivo.
  Future<void> cerrar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  for (final ancho in [390.0, 800.0, 1400.0]) {
    final escritorio = ancho >= 1000;
    final tabla = ancho >= 720;

    testWidgets('Eventos a $ancho px', (tester) async {
      final errores = await abrir(
        tester,
        const TtkEventosScreen(),
        ancho: ancho,
      );
      expect(errores, isEmpty, reason: detalle(errores));
      expect(find.text('Eventos y vales'), findsOneWidget);
      expect(find.text('Aniversario 2026'), findsWidgets);
      if (tabla) {
        expect(
          find.text('Evento'),
          findsOneWidget,
          reason: 'tabla con columnas',
        );
      } else {
        expect(
          find.byIcon(Icons.more_vert),
          findsWidgets,
          reason: 'tarjetas con menú',
        );
      }

      // Detalle: participantes y, en la otra pestaña, el tipo que da cartón.
      errores.addAll(
        await conErrores(() async {
          await tester.tap(find.text('Aniversario 2026').first);
          await esperar(tester);
        }),
      );
      expect(errores, isEmpty, reason: detalle(errores));
      expect(find.text('Participantes (4)'), findsOneWidget);
      expect(find.text('Quispe Mamani Juan Carlos'), findsWidgets);
      errores.addAll(
        await conErrores(() async {
          await tester.tap(find.text('Tipos de vale (2)'));
          await esperar(tester);
        }),
      );
      expect(errores, isEmpty, reason: detalle(errores));
      expect(find.text('Da cartón de bingo'), findsOneWidget);
      await cerrar(tester);
    });

    testWidgets('Configuración del bingo a $ancho px', (tester) async {
      final errores = await abrir(
        tester,
        const TtkBingoConfiguracionScreen(),
        ancho: ancho,
      );
      expect(errores, isEmpty, reason: detalle(errores));
      expect(find.text('Configuración del bingo'), findsOneWidget);
      expect(
        find.textContaining('12 vales sin cartón'),
        findsOneWidget,
        reason: 'mensaje del SP',
      );
      expect(find.text('Vale que da cartón'), findsOneWidget);
      expect(
        find.text('312'),
        findsWidgets,
        reason: 'cartones según los vales, solo lectura',
      );

      // Pestaña de cartones: tabla o tarjetas, con los dueños invitados marcados.
      errores.addAll(
        await conErrores(() async {
          await tester.tap(find.text('Cartones (300)'));
          await esperar(tester);
        }),
      );
      expect(errores, isEmpty, reason: detalle(errores));
      expect(find.text('0002'), findsWidgets);
      // La lista es perezosa: en el escritorio la fila del invitado ya está dibujada.
      if (escritorio) expect(find.text('Invitado'), findsWidgets);
      await cerrar(tester);
    });

    testWidgets('Panel en vivo a $ancho px', (tester) async {
      final vivo = TtkVivoFalso();
      final errores = await abrir(
        tester,
        const TtkBingoPanelScreen(),
        ancho: ancho,
        vivo: vivo,
      );
      expect(errores, isEmpty, reason: detalle(errores));
      expect(find.text('Panel en vivo'), findsOneWidget);
      final bolillo = find.byKey(const ValueKey('ttk-bolillo-70'));
      expect(bolillo, findsOneWidget, reason: 'tablero con los 75 bolillos');
      expect(
        tester.getSize(bolillo).width,
        greaterThanOrEqualTo(escritorio ? 40 : 26),
        reason: 'el tablero se agranda con el alto disponible',
      );
      expect(find.text('En vivo'), findsOneWidget);
      expect(
        vivo.abiertas,
        1,
        reason: 'una sola suscripción al tópico del encargado',
      );

      // Llega por el canal un estado más nuevo con un cartón que completó la figura.
      errores.addAll(
        await conErrores(() async {
          vivo.emitirEncargado(
            TtkEstadoEncargadoEntity(
              version: 6,
              publico: publicoFalso(),
              tablero: tableroFalso(),
              ranking: rankingFalso(conBingoNuevo: true),
              aviso:
                  '¡BINGO! El cartón 7 completó la figura con el bolillo 28.',
            ),
          );
          await esperar(tester, 4);
        }),
      );
      expect(errores, isEmpty, reason: detalle(errores));
      expect(
        find.byType(AlertaBingoTtk),
        findsOneWidget,
        reason: 'el aviso de bingo queda a la vista',
      );

      // Un estado con versión vieja no reemplaza al actual.
      vivo.emitirEncargado(
        TtkEstadoEncargadoEntity(
          version: 2,
          publico: publicoFalso(),
          tablero: const [],
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const ValueKey('ttk-bolillo-70')), findsOneWidget);
      await cerrar(tester);
      expect(vivo.cerradas, 1, reason: 'al salir se libera la conexión');
    });

    testWidgets('Mi cartón a $ancho px', (tester) async {
      final bingo = TtkBingoFalso();
      final errores = await abrir(
        tester,
        const TtkMiCartonScreen(),
        ancho: ancho,
        bingo: bingo,
      );
      expect(errores, isEmpty, reason: detalle(errores));
      expect(
        find.text('Elija su cartón: quedan 40 disponibles.'),
        findsOneWidget,
      );
      expect(find.text('0077'), findsOneWidget);
      expect(
        find.text('Soltar este cartón'),
        findsNothing,
        reason: 'el elegido no se devuelve',
      );

      // Elegir por número: confirmación, sin vista previa, y después se ve el cartón.
      errores.addAll(
        await conErrores(() async {
          await tester.tap(find.text('Elegir mi cartón'));
          await esperar(tester, 4);
        }),
      );
      expect(errores, isEmpty, reason: detalle(errores));
      expect(find.text('Elige tu cartón'), findsOneWidget);
      errores.addAll(
        await conErrores(() async {
          await tester.tap(find.text('0003'));
          await esperar(tester, 3);
        }),
      );
      expect(find.text('Una vez elegido no se puede cambiar.'), findsOneWidget);
      expect(
        find.text('Juego 1 · Cartón lleno'),
        findsNothing,
        reason: 'sin vista previa',
      );
      errores.addAll(
        await conErrores(() async {
          await tester.tap(find.text('Elegir este cartón'));
          await esperar(tester);
        }),
      );
      expect(errores, isEmpty, reason: detalle(errores));
      expect(bingo.elegidos, [BigInt.one]);
      expect(
        find.text('Cartón N° 0003'),
        findsOneWidget,
        reason: 'recién elegido, se muestra',
      );
      await cerrar(tester);
    });

    testWidgets('Jugar con mi cartón a $ancho px', (tester) async {
      final semantica = tester.ensureSemantics();
      final bingo =
          TtkBingoFalso()
            ..estadoParticipante = 'EN_JUEGO'
            ..puedeAvisar = true;
      final errores = await abrir(
        tester,
        const TtkMiCartonScreen(),
        ancho: ancho,
        bingo: bingo,
      );
      errores.addAll(
        await conErrores(() async {
          await tester.tap(find.text('Jugar con mi cartón'));
          await esperar(tester);
        }),
      );
      expect(errores, isEmpty, reason: detalle(errores));
      expect(find.text('Juego 3 · Letra L'), findsOneWidget);
      expect(find.textContaining('no te avisa si ganaste'), findsOneWidget);

      // Marcar a mano: queda solo en el equipo, por cartón y juego.
      errores.addAll(
        await conErrores(() async {
          await tester.ensureVisible(find.bySemanticsLabel('I 21'));
          await tester.tap(find.bySemanticsLabel('I 21'));
          await esperar(tester, 2);
        }),
      );
      expect(errores, isEmpty, reason: detalle(errores));
      final contenedor = ProviderScope.containerOf(
        tester.element(find.byType(TtkMiCartonScreen)),
      );
      expect(
        contenedor.read(
          ttkMarcasProvider((codCarton: BigInt.from(77), nroJuego: 3)),
        ),
        {1},
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('ttk_marcas_77_3'), ['1']);
      expect(
        find.byKey(const ValueKey('tinta')),
        findsOneWidget,
        reason: 'el sello de tinta queda en la casilla tocada',
      );

      // «¡Bingo!» solo avisa al encargado, con confirmación.
      errores.addAll(
        await conErrores(() async {
          await tester.ensureVisible(find.text('¡Bingo!'));
          await tester.tap(find.text('¡Bingo!'));
          await esperar(tester, 3);
          await tester.tap(find.text('Avisar «¡Bingo!»'));
          await esperar(tester, 3);
        }),
      );
      expect(errores, isEmpty, reason: detalle(errores));
      expect(bingo.cantados, [BigInt.from(77)]);
      semantica.dispose();
      await cerrar(tester);
    });

    testWidgets('Jugar sin el botón «¡Bingo!» a $ancho px', (tester) async {
      final bingo = TtkBingoFalso()..estadoParticipante = 'EN_JUEGO';
      final errores = await abrir(
        tester,
        const TtkMiCartonScreen(),
        ancho: ancho,
        bingo: bingo,
      );
      errores.addAll(
        await conErrores(() async {
          await tester.tap(find.text('Jugar con mi cartón'));
          await esperar(tester);
        }),
      );
      expect(errores, isEmpty, reason: detalle(errores));
      expect(
        find.text('¡Bingo!'),
        findsNothing,
        reason: 'el encargado lo apagó',
      );
      expect(find.textContaining('grita «¡Bingo!».'), findsOneWidget);
      await cerrar(tester);
    });

    testWidgets('En vivo a $ancho px', (tester) async {
      final vivo = TtkVivoFalso();
      final errores = await abrir(
        tester,
        TtkBingoEnVivoScreen(codBingo: BigInt.one),
        ancho: ancho,
        vivo: vivo,
      );
      expect(errores, isEmpty, reason: detalle(errores));
      expect(find.text('Letra L'), findsOneWidget);
      expect(find.text('Juego 3 de 8'), findsOneWidget);
      expect(find.text('12 de 75 bolillos'), findsOneWidget);
      // El último cantado manda y lo anterior queda en la historia.
      expect(find.bySemanticsLabel('Último bolillo: I 28'), findsOneWidget);
      final bolillo = find.byKey(const ValueKey('ttk-bolillo-1'));
      expect(bolillo, findsOneWidget);
      expect(
        tester.getSize(bolillo).width,
        greaterThanOrEqualTo(escritorio ? 60 : 26),
        reason: 'el tablero llena el área disponible',
      );
      expect(
        find.textContaining('Empleado número'),
        findsNothing,
        reason: 'nunca muestra ganadores ni ranking',
      );
      expect(find.byKey(const ValueKey('ttk-aviso-ganador')), findsNothing);

      // El tópico público avisa que hubo ganador: aviso destacado y genérico.
      errores.addAll(
        await conErrores(() async {
          vivo.emitirPublico(
            TtkEstadoPublicoEntity(
              version: 6,
              publico: publicoFalso(hayGanador: true),
              tablero: tableroFalso(),
            ),
          );
          await esperar(tester, 4);
        }),
      );
      expect(errores, isEmpty, reason: detalle(errores));
      expect(find.byKey(const ValueKey('ttk-aviso-ganador')), findsOneWidget);
      expect(find.text('¡Ya salió un ganador del juego 3!'), findsOneWidget);
      expect(find.textContaining('Empleado número'), findsNothing);
      await cerrar(tester);
      expect(vivo.cerradas, 1);
    });
  }

  for (final ancho in [390.0, 1400.0]) {
    testWidgets('Vales en lote a $ancho px', (tester) async {
      final tickets = TtkTicketsFalso();
      tester.view.physicalSize = Size(ancho, ancho <= 450 ? 844 : 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final errores = await conErrores(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              userProvider.overrideWith(
                (ref) => UserStateNotifier.sinStorage(loginAdminFalso),
              ),
              ttkTicketsRepositoryProvider.overrideWithValue(tickets),
              ttkBingoRepositoryProvider.overrideWithValue(TtkBingoFalso()),
              ttkBingoVivoRepositoryProvider.overrideWithValue(TtkVivoFalso()),
            ],
            child: MaterialApp(
              theme: AppTheme().getTheme(),
              builder:
                  (context, child) => ResponsiveBreakpoints.builder(
                    child: child!,
                    breakpoints: ResponsiveUtilsBosque.breakpoints,
                  ),
              home: const Scaffold(
                body: _UnFotogramaDespues(child: TtkEventosScreen()),
              ),
            ),
          ),
        );
        await esperar(tester);
        await tester.tap(find.text('Aniversario 2026').first);
        await esperar(tester);
        // Casilla del encabezado (escritorio) o «Seleccionar todo» (teléfono).
        await tester.tap(
          ancho >= 720
              ? find.byType(Checkbox).first
              : find.text('Seleccionar todo (3)'),
        );
        await esperar(tester, 2);
      });
      expect(errores, isEmpty, reason: detalle(errores));
      expect(find.text('Vales en lote (3)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ttk-vales-lote')));
      await esperar(tester, 3);
      expect(find.text('Los seleccionados (3)'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();
      await tester.tap(find.text('Aplicar'));
      await esperar(tester, 3);
      final (tipo, cantidad, participantes, categoria) = tickets.lotes.single;
      expect(tipo, BigInt.one);
      expect(cantidad, 2);
      expect(
        participantes,
        unorderedEquals([BigInt.one, BigInt.two, BigInt.from(3)]),
      );
      expect(categoria, isNull);
      expect(
        find.text('Vales en lote'),
        findsOneWidget,
        reason: 'se limpia la selección',
      );
      await cerrar(tester);
    });
  }

  testWidgets('Asignar un cartón a un invitado manda codParticipante', (
    tester,
  ) async {
    final bingo = TtkBingoFalso();
    final errores = await abrir(
      tester,
      const TtkBingoConfiguracionScreen(),
      ancho: 1400,
      bingo: bingo,
    );
    errores.addAll(
      await conErrores(() async {
        await tester.tap(find.text('Cartones (300)'));
        await esperar(tester);
        await tester.tap(find.byTooltip('Asignar').first);
        await esperar(tester, 4);
      }),
    );
    expect(errores, isEmpty, reason: detalle(errores));
    expect(find.text('Asignar el cartón N° 1'), findsOneWidget);
    expect(
      find.text('Invitado'),
      findsWidgets,
      reason: 'el invitado aparece con su categoría',
    );
    await tester.tap(find.text('Ana Gutiérrez'));
    await esperar(tester, 3);
    expect(bingo.asignaciones.single, (BigInt.one, BigInt.from(3), null));
    expect(
      bingo.impresosAlAsignar.single,
      isTrue,
      reason: 'con «ambos», lo que asigna el encargado se imprime',
    );
    await cerrar(tester);
  });

  testWidgets('Configuración: forma de juego y botón «¡Bingo!» se guardan', (
    tester,
  ) async {
    final bingo = TtkBingoFalso();
    final errores = await abrir(
      tester,
      const TtkBingoConfiguracionScreen(),
      ancho: 1400,
      bingo: bingo,
    );
    expect(errores, isEmpty, reason: detalle(errores));
    expect(find.text('Cómo se juega'), findsOneWidget);
    expect(
      find.textContaining('Con el bingo en juego ya no cambian'),
      findsOneWidget,
      reason: 'en juego, se explica por qué el cartón no se edita',
    );
    await tester.ensureVisible(find.text('En pantalla'));
    await tester.tap(find.text('En pantalla'));
    await tester.pump();
    await tester.ensureVisible(
      find.text('Botón «¡Bingo!» para avisar al encargado'),
    );
    await tester.tap(find.text('Botón «¡Bingo!» para avisar al encargado'));
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar parámetros'));
    await tester.tap(find.text('Guardar parámetros'));
    await esperar(tester, 3);
    expect(bingo.guardados.last.modalidad, 'P');
    expect(bingo.guardados.last.conAviso, isTrue);
    await cerrar(tester);
  });

  for (final ancho in [390.0, 1400.0]) {
    testWidgets(
      'Configuración: las letras se ven sobre cada columna a $ancho',
      (tester) async {
        final bingo = TtkBingoFalso()..bingo = bingoEnConfiguracionFalso;
        final errores = await abrir(
          tester,
          const TtkBingoConfiguracionScreen(),
          ancho: ancho,
          bingo: bingo,
        );
        expect(errores, isEmpty, reason: detalle(errores));
        expect(
          find.text('Así queda el encabezado del cartón:'),
          findsOneWidget,
        );
        expect(find.text('Col. 5'), findsOneWidget);
        expect(find.text('1. Parámetros y figuras'), findsOneWidget);

        final letras = find.widgetWithText(TextField, 'Letras del encabezado');
        await tester.ensureVisible(letras);
        await tester.enterText(letras, 'BING');
        await tester.pump();
        expect(
          find.text('?'),
          findsOneWidget,
          reason: 'falta la de la columna 5',
        );
        await tester.enterText(letras, 'BINGOS');
        await tester.pump();
        expect(find.text('Sin columna'), findsOneWidget, reason: 'sobra una');
        await tester.enterText(letras, '');
        await tester.pump();
        expect(
          find.text('Encabezado del cartón: sin letras, solo números.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await cerrar(tester);
      },
    );
  }

  testWidgets('Panel: los «¡Bingo!» avisados se ven y «Listo» los atiende', (
    tester,
  ) async {
    final bingo = TtkBingoFalso();
    final errores = await abrir(
      tester,
      const TtkBingoPanelScreen(),
      ancho: 1400,
      bingo: bingo,
    );
    expect(errores, isEmpty, reason: detalle(errores));
    expect(find.text('Un participante avisó «¡Bingo!»'), findsOneWidget);
    expect(find.text('N° 0012'), findsWidgets);
    await tester.tap(find.text('Listo'));
    await esperar(tester, 3);
    expect(bingo.atendidos, [BigInt.from(9)]);
    await cerrar(tester);
  });
}

/// Monta la pantalla un fotograma después de `ResponsiveBreakpoints`, como en
/// la app; si nace en el mismo, lee un punto de quiebre que aún no existe.
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
