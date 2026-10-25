import 'dart:io';

import 'package:bosque_flutter/core/state/ttk_bingo_provider.dart';
import 'package:bosque_flutter/core/state/ttk_tickets_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_aviso_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_publico_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_encargado_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_publico_entity.dart';
import 'package:bosque_flutter/presentation/screens/tickets/ttk_bingo_en_vivo_screen.dart';
import 'package:bosque_flutter/presentation/screens/tickets/ttk_bingo_panel_screen.dart';
import 'package:bosque_flutter/presentation/screens/tickets/ttk_mi_carton_screen.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_panel.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/repositorio_depositos.dart' show loginAdminFalso;
import 'fakes/repositorio_ttk.dart';

/// Tormenta de eventos en vivo sobre las pantallas del bingo: el juego avanza,
/// termina, sale ganador, se corta la conexión, llegan versiones viejas y la
/// persona sale en plena animación. Ninguna pantalla debe lanzar errores ni
/// pedirle al backend más de lo necesario por cada evento.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Las fuentes reales: con la de prueba (cuadrados anchos) todo «desborda».
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

  /// Letra del sistema: 1 normal; 1.3 como la usan muchas personas mayores.
  var escala = 1.0;

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
          theme: AppTheme().getTheme(),
          locale: const Locale('es'),
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(escala)),
                child: ResponsiveBreakpoints.builder(
                  child: child!,
                  breakpoints: ResponsiveUtilsBosque.breakpoints,
                ),
              ),
          home: Scaffold(body: _UnFotogramaDespues(child: pantalla)),
        ),
      );

  Future<List<FlutterErrorDetails>> conErrores(
    Future<void> Function() paso,
  ) async {
    final errores = <FlutterErrorDetails>[];
    final previo = FlutterError.onError;
    FlutterError.onError = errores.add;
    try {
      await paso();
    } finally {
      FlutterError.onError = previo;
    }
    return errores;
  }

  Future<void> esperar(WidgetTester tester, [int veces = 6]) async {
    for (var i = 0; i < veces; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> montar(
    WidgetTester tester,
    Widget pantalla,
    double ancho,
    TtkVivoFalso vivo,
    TtkBingoFalso bingo,
  ) async {
    tester.view.physicalSize = Size(ancho, ancho <= 450 ? 844 : 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(pantalla, vivo, bingo));
    await esperar(tester);
  }

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  /// Estado público con lo justo para cada evento del juego.
  TtkEstadoPublicoEntity publico(
    int version, {
    int nroJuego = 3,
    String estadoJuego = 'EN_CURSO',
    String estado = 'EN_JUEGO',
    bool hayGanador = false,
    bool puedeAvisar = true,
    int? ultimo = 28,
    bool sinPublico = false,
  }) => TtkEstadoPublicoEntity(
    version: version,
    publico:
        sinPublico
            ? null
            : TtkBingoPublicoEntity(
              codBingo: BigInt.one,
              nombreEvento: 'Aniversario 2026',
              estado: estado,
              estadoTexto: estado == 'EN_JUEGO' ? 'En juego' : 'Finalizado',
              letras: 'BINGO',
              nroJuegos: 8,
              nroJuego: nroJuego,
              nombreJuego: 'Letra L',
              figura: '1' * 25,
              estadoJuego: estadoJuego,
              totalMarcados: 12,
              ultimoBolillo: ultimo,
              hayGanador: hayGanador,
              puedeAvisar: puedeAvisar,
              mensaje:
                  hayGanador
                      ? '¡Ya salió un ganador del juego $nroJuego!'
                      : 'Juego $nroJuego: Letra L',
            ),
    tablero: tableroFalso(),
  );

  TtkBingoAvisoEntity aviso(int cod, int nro) => TtkBingoAvisoEntity(
    codAviso: BigInt.from(cod),
    codBingo: BigInt.one,
    nroJuego: 3,
    codCarton: BigInt.from(nro),
    nroCarton: nro,
    nombreEmpleado: 'Empleado $nro',
    impreso: nro.isEven,
    fechaAviso: DateTime(2026, 12, 20, 20, 15, cod),
    mensaje: 'El cartón $nro avisó «¡Bingo!».',
  );

  for (final (ancho, letra) in [(390.0, 1.0), (1400.0, 1.0), (390.0, 1.3)]) {
    final caso =
        letra == 1
            ? '$ancho px'
            : '$ancho px con letra al ${(letra * 100).round()} %';
    group(caso, () {
      setUp(() => escala = letra);

      testWidgets('Jugar aguanta el juego completo a $caso', (tester) async {
        final semantica = tester.ensureSemantics();
        final vivo = TtkVivoFalso();
        final bingo =
            TtkBingoFalso()
              ..estadoParticipante = 'EN_JUEGO'
              ..puedeAvisar = true;
        final errores = await conErrores(() async {
          await montar(tester, const TtkMiCartonScreen(), ancho, vivo, bingo);
          await tester.tap(find.text('Jugar con mi cartón'));
          await esperar(tester);
          await tester.ensureVisible(find.bySemanticsLabel('I 21'));
          await tester.tap(find.bySemanticsLabel('I 21'));
          // En pleno sello llega el bolillo siguiente.
          await tester.pump(const Duration(milliseconds: 60));
          vivo.emitirPublico(publico(6, ultimo: 44));
          await esperar(tester, 2);
        });
        expect(errores, isEmpty, reason: detalle(errores));
        expect(find.text('¡Bingo!'), findsOneWidget);

        Future<void> llega(TtkEstadoPublicoEntity e) async {
          errores.addAll(
            await conErrores(() async {
              vivo.emitirPublico(e);
              await esperar(tester, 2);
            }),
          );
          expect(errores, isEmpty, reason: detalle(errores));
        }

        await llega(publico(7, ultimo: 52, puedeAvisar: false));
        expect(
          find.text('¡Bingo!'),
          findsNothing,
          reason: 'el encargado lo apagó',
        );

        await llega(publico(8, hayGanador: true));
        expect(find.textContaining('Ya salió un ganador'), findsOneWidget);

        // Corte y vuelta de la conexión en pleno juego.
        errores.addAll(
          await conErrores(() async {
            vivo.cambiarConexion(false);
            await esperar(tester, 1);
            expect(find.text('Reconectando…'), findsOneWidget);
            vivo.cambiarConexion(true);
            await esperar(tester, 1);
          }),
        );
        expect(errores, isEmpty, reason: detalle(errores));

        await llega(publico(9, estadoJuego: 'FINALIZADO', hayGanador: true));
        expect(
          find.bySemanticsLabel('I 21'),
          findsNothing,
          reason: 'con el juego cerrado ya no se marca',
        );

        await llega(publico(10, nroJuego: 4));
        expect(find.text('Sin casillas para este juego'), findsOneWidget);

        await llega(publico(11));
        expect(
          find.byKey(const ValueKey('tinta')),
          findsOneWidget,
          reason: 'al volver al juego 3 sus marcas siguen ahí',
        );

        await llega(publico(12, sinPublico: true));
        await llega(publico(4, ultimo: 1));
        expect(
          find.text('Mi cartón'),
          findsWidgets,
          reason: 'la versión vieja no pisa',
        );
        await llega(
          publico(13, estado: 'FINALIZADO', estadoJuego: 'FINALIZADO'),
        );

        // Por evento no se le pide nada al backend: llega todo por el canal.
        // Solo al abrir y al reconectarse (para no perder lo que pasó en el corte).
        expect(
          bingo.llamadas['estadoPublico'],
          3,
          reason:
              'al abrir, al conectarse el canal y al reconectarse (sale de la caché del backend)',
        );
        expect(bingo.llamadas['verCarton'], 1);
        expect(bingo.llamadas['misCartones'], 1);

        semantica.dispose();
        errores.addAll(
          await conErrores(() async {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          }),
        );
        expect(errores, isEmpty, reason: detalle(errores));
        expect(
          vivo.cerradas,
          vivo.abiertas,
          reason: 'se cierra la suscripción',
        );
      });

      testWidgets('Salir de Jugar en pleno sello y rebote a $caso', (
        tester,
      ) async {
        final semantica = tester.ensureSemantics();
        final vivo = TtkVivoFalso();
        final bingo = TtkBingoFalso()..estadoParticipante = 'EN_JUEGO';
        final errores = await conErrores(() async {
          await montar(tester, const TtkMiCartonScreen(), ancho, vivo, bingo);
          await tester.tap(find.text('Jugar con mi cartón'));
          await esperar(tester);
          for (final n in ['I 21', 'N 36', 'I 21', 'G 54']) {
            await tester.ensureVisible(find.bySemanticsLabel(n));
            await tester.tap(find.bySemanticsLabel(n));
            await tester.pump(const Duration(milliseconds: 16));
          }
          vivo.emitirPublico(publico(6, ultimo: 70));
          await tester.pump(const Duration(milliseconds: 30));
          await tester.pumpWidget(const SizedBox.shrink());
          await esperar(tester, 3);
        });
        semantica.dispose();
        expect(errores, isEmpty, reason: detalle(errores));
      });

      testWidgets('Panel: avisos que llegan, se atienden y se van a $caso', (
        tester,
      ) async {
        final vivo = TtkVivoFalso();
        final bingo = TtkBingoFalso();
        TtkEstadoEncargadoEntity estado(
          int version, {
          List<TtkBingoAvisoEntity> avisos = const [],
          bool conBingoNuevo = false,
        }) => TtkEstadoEncargadoEntity(
          version: version,
          publico: publicoFalso(),
          tablero: tableroFalso(),
          ranking: rankingFalso(conBingoNuevo: conBingoNuevo),
          avisos: avisos,
        );

        final errores = await conErrores(() async {
          await montar(tester, const TtkBingoPanelScreen(), ancho, vivo, bingo);
          vivo.emitirEncargado(
            estado(6, avisos: [aviso(10, 12), aviso(11, 30)]),
          );
          await esperar(tester, 2);
        });
        expect(errores, isEmpty, reason: detalle(errores));
        expect(find.text('2 participantes avisaron «¡Bingo!»'), findsOneWidget);

        errores.addAll(
          await conErrores(() async {
            vivo.emitirEncargado(estado(7));
            await esperar(tester, 2);
          }),
        );
        expect(find.byType(AvisosBingoTtk), findsNothing);

        errores.addAll(
          await conErrores(() async {
            vivo.emitirEncargado(
              estado(8, avisos: [aviso(12, 7)], conBingoNuevo: true),
            );
            await esperar(tester, 2);
            vivo.cambiarConexion(false);
            await esperar(tester, 1);
            vivo.cambiarConexion(true);
            vivo.emitirEncargado(estado(3));
            await esperar(tester, 1);
          }),
        );
        expect(errores, isEmpty, reason: detalle(errores));
        expect(find.byType(AlertaBingoTtk), findsOneWidget);
        expect(
          find.text('Un participante avisó «¡Bingo!»'),
          findsOneWidget,
          reason: 'la versión vieja no borra el aviso',
        );

        // Validar desde el aviso y darlo por atendido.
        errores.addAll(
          await conErrores(() async {
            final validar = find.descendant(
              of: find.byType(AvisosBingoTtk),
              matching: find.text('Validar'),
            );
            // Con letra grande la franja de avisos se desplaza: se busca el botón.
            await tester.ensureVisible(validar);
            await tester.pump();
            await tester.tap(validar);
            await esperar(tester, 3);
            await tester.tap(find.text('Marcar atendido'));
            await esperar(tester, 3);
          }),
        );
        expect(errores, isEmpty, reason: detalle(errores));
        expect(bingo.atendidos, [BigInt.from(12)]);

        // El panel pide juegos y ganadores una vez por cambio, no por espectador.
        final juegos = bingo.llamadas['listarJuegos'] ?? 0;
        expect(juegos, lessThanOrEqualTo(6));

        errores.addAll(
          await conErrores(() async {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          }),
        );
        expect(errores, isEmpty, reason: detalle(errores));
      });

      testWidgets(
        'Panel: el estado llega antes que la respuesta de «Listo» a $caso',
        (tester) async {
          final vivo = TtkVivoFalso();
          final bingo = TtkBingoFalso();
          TtkEstadoEncargadoEntity estado(
            int version, {
            List<TtkBingoAvisoEntity> avisos = const [],
          }) => TtkEstadoEncargadoEntity(
            version: version,
            publico: publicoFalso(),
            tablero: tableroFalso(),
            ranking: rankingFalso(conBingoNuevo: true),
            avisos: avisos,
          );
          final errores = await conErrores(() async {
            await montar(
              tester,
              const TtkBingoPanelScreen(),
              ancho,
              vivo,
              bingo,
            );
            vivo.emitirEncargado(estado(6, avisos: [aviso(10, 12)]));
            await esperar(tester, 2);
          });
          expect(errores, isEmpty, reason: detalle(errores));

          // Se cierra la alerta: un aviso nuevo no debe reabrirla.
          errores.addAll(
            await conErrores(() async {
              await tester.tap(find.byTooltip('Entendido'));
              await esperar(tester, 1);
              vivo.emitirEncargado(
                estado(7, avisos: [aviso(10, 12), aviso(11, 9)]),
              );
              await esperar(tester, 2);
            }),
          );
          expect(errores, isEmpty, reason: detalle(errores));
          expect(
            find.byType(AlertaBingoTtk),
            findsNothing,
            reason: 'la alerta cerrada no vuelve con cada aviso',
          );

          // Como el backend real: empuja el estado sin avisos antes de responder.
          bingo.alAtender = () => vivo.emitirEncargado(estado(8));
          errores.addAll(
            await conErrores(() async {
              final listo = find.text('Listo').first;
              await tester.ensureVisible(listo);
              await tester.tap(listo);
              await esperar(tester, 3);
            }),
          );
          expect(errores, isEmpty, reason: detalle(errores));
          expect(find.byType(AvisosBingoTtk), findsNothing);
          expect(bingo.atendidos, hasLength(1));
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        },
      );

      testWidgets('Elegir: dos toques seguidos y salir en pleno giro a $caso', (
        tester,
      ) async {
        final vivo = TtkVivoFalso();
        final bingo = TtkBingoFalso();
        final errores = await conErrores(() async {
          await montar(tester, const TtkMiCartonScreen(), ancho, vivo, bingo);
          await tester.tap(find.text('Elegir mi cartón'));
          await esperar(tester);
          if (ancho > 1000) {
            // Mouse que recorre la mesa a toda velocidad.
            final mouse = await tester.createGesture(
              kind: PointerDeviceKind.mouse,
            );
            await mouse.addPointer(location: Offset.zero);
            for (final n in ['0003', '0006', '0009', '0012', '0006']) {
              await mouse.moveTo(tester.getCenter(find.text(n)));
              await tester.pump(const Duration(milliseconds: 16));
            }
            await mouse.removePointer();
          }
          await tester.tap(find.text('0003'));
          await tester.pump(const Duration(milliseconds: 30));
          await tester.tap(find.text('0006'), warnIfMissed: false);
          await esperar(tester, 2);
        });
        expect(errores, isEmpty, reason: detalle(errores));
        expect(find.text('Elegir el cartón N° 0003'), findsOneWidget);
        expect(
          find.text('Elegir el cartón N° 0006'),
          findsNothing,
          reason: 'el segundo toque no abre otra escena',
        );

        errores.addAll(
          await conErrores(() async {
            await tester.tap(find.text('Elegir este cartón'));
            await tester.pump(const Duration(milliseconds: 50));
            await tester.pump(const Duration(milliseconds: 250));
            // «Listo» en pleno giro: la escena se cierra con la animación viva.
            await tester.tap(find.text('Listo'));
            await esperar(tester);
          }),
        );
        expect(errores, isEmpty, reason: detalle(errores));
        expect(bingo.elegidos, [BigInt.one]);
        expect(find.text('Elige tu cartón'), findsNothing);

        errores.addAll(
          await conErrores(() async {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          }),
        );
        expect(errores, isEmpty, reason: detalle(errores));
      });

      testWidgets('En vivo aguanta el juego completo a $caso', (tester) async {
        final vivo = TtkVivoFalso();
        final bingo = TtkBingoFalso();
        final errores = await conErrores(
          () => montar(
            tester,
            TtkBingoEnVivoScreen(codBingo: BigInt.one),
            ancho,
            vivo,
            bingo,
          ),
        );
        expect(errores, isEmpty, reason: detalle(errores));
        final eventos = [
          publico(6, ultimo: 44),
          publico(7, hayGanador: true),
          publico(8, estadoJuego: 'FINALIZADO', hayGanador: true),
          publico(9, nroJuego: 4, ultimo: null),
          publico(10, sinPublico: true),
          publico(2),
          publico(11, estado: 'FINALIZADO', estadoJuego: 'FINALIZADO'),
        ];
        for (final (i, e) in eventos.indexed) {
          errores.addAll(
            await conErrores(() async {
              vivo.emitirPublico(e);
              await esperar(tester, 2);
            }),
          );
          expect(errores, isEmpty, reason: 'evento $i: ${detalle(errores)}');
        }
        errores.addAll(
          await conErrores(() async {
            vivo.cambiarConexion(false);
            await esperar(tester, 1);
            vivo.cambiarConexion(true);
            await esperar(tester, 1);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          }),
        );
        expect(errores, isEmpty, reason: detalle(errores));
        expect(
          bingo.llamadas['estadoPublico'],
          3,
          reason:
              'al abrir, al conectarse el canal y al reconectarse (sale de la caché del backend)',
        );
      });
    });
  }
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
