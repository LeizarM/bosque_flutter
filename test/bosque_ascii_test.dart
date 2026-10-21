// Bosque de papel del login: dibuja y anima sin errores en cualquier tamaño y
// ante cada evento (redimensionar, tema, mouse, pausa, pantalla tapada, entrar
// y salir de sesión), con el costo por cuadro y la memoria medidos y acotados.
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/presentation/screens/login/login_screen.dart';
import 'package:bosque_flutter/presentation/widgets/login/bosque_ascii.dart';

import 'fakes/arnes_cheques.dart';

void main() {
  setUpAll(cargarRoboto);

  Widget escena({
    required Size tam,
    bool quieto = false,
    bool oscuro = false,
    bool pausado = false,
    int semilla = 2,
  }) => MaterialApp(
    theme: AppTheme(isDarkMode: oscuro, selectedColor: semilla).getTheme(),
    home: MediaQuery(
      data: MediaQueryData(size: tam, disableAnimations: quieto),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox.fromSize(
            size: tam,
            child: BosqueAscii(pausado: pausado),
          ),
        ),
      ),
    ),
  );

  dynamic estado(WidgetTester tester) => tester.state(find.byType(BosqueAscii));

  for (final (tam, oscuro) in [
    (const Size(760, 900), false),
    (const Size(760, 900), true),
    (const Size(390, 300), false),
    // Degenerados: la escena no se arma, pero tampoco revienta.
    (const Size(30, 30), false),
    (const Size(800, 0), false),
  ]) {
    testWidgets('anima ${tam.width.toInt()}x${tam.height.toInt()}'
        '${oscuro ? ' en oscuro' : ''} sin errores', (tester) async {
      final errores = await capturandoErrores(() async {
        await tester.pumpWidget(escena(tam: tam, oscuro: oscuro));
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 33));
        }
      });
      expect(errores, isEmpty);
      expect(find.byType(BosqueAscii), findsOneWidget);
    });
  }

  testWidgets('con «reducir movimiento» no pide cuadros', (tester) async {
    await tester.pumpWidget(escena(tam: const Size(760, 900), quieto: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('el mouse espanta a las aves sin romper nada', (tester) async {
    final errores = await capturandoErrores(() async {
      await tester.pumpWidget(escena(tam: const Size(760, 900)));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(200, 200));
      for (var i = 0; i < 30; i++) {
        await mouse.moveTo(Offset(200 + i * 12.0, 180 + i * 4.0));
        await tester.pump(const Duration(milliseconds: 33));
      }
      await mouse.removePointer();
      await tester.pump(const Duration(milliseconds: 33));
    });
    expect(errores, isEmpty);
  });

  testWidgets('«pausado» detiene el reloj y al soltarlo vuelve a correr', (
    tester,
  ) async {
    await tester.pumpWidget(escena(tam: const Size(760, 900), pausado: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(estado(tester).animando, isFalse);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(escena(tam: const Size(760, 900)));
    await tester.pump(const Duration(milliseconds: 33));
    expect(estado(tester).animando, isTrue);
  });

  // Como al iniciar y cerrar sesión: la pantalla con el bosque se va y vuelve.
  testWidgets('entrar y salir varias veces no deja relojes ni errores', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder:
              (_, __) => const Scaffold(
                body: SizedBox(width: 760, height: 900, child: BosqueAscii()),
              ),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const Scaffold(body: Text('DASHBOARD')),
        ),
      ],
    );
    final errores = await capturandoErrores(() async {
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme().getTheme(), routerConfig: router),
      );
      for (var vuelta = 0; vuelta < 5; vuelta++) {
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 33));
        }
        router.go('/dashboard');
        await tester.pump();
        // Se deja terminar la transición de página (~350 ms, igual sin el
        // bosque); después nadie tiene que seguir pidiendo cuadros.
        var espera = 0;
        while (tester.binding.hasScheduledFrame && espera < 1000) {
          await tester.pump(const Duration(milliseconds: 50));
          espera += 50;
        }
        expect(find.byType(BosqueAscii), findsNothing);
        expect(tester.binding.hasScheduledFrame, isFalse);
        router.go('/login');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(BosqueAscii), findsOneWidget);
      }
    });
    expect(errores, isEmpty);
  });

  // Peor caso: pantalla completa de 1920×1080 (en la app ocupa la mitad), con
  // el mouse moviéndose y tres cambios de tema.
  testWidgets('rendimiento: cuadro liviano y caché de letras acotada', (
    tester,
  ) async {
    const tam = Size(1920, 1080);
    tester.view.physicalSize = tam;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(escena(tam: tam));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(300, 300));

    final reloj = Stopwatch();
    var cuadros = 0;
    for (final (oscuro, semilla) in [(false, 2), (true, 2), (false, 4)]) {
      await tester.pumpWidget(
        escena(tam: tam, oscuro: oscuro, semilla: semilla),
      );
      for (var i = 0; i < 100; i++) {
        await mouse.moveTo(
          Offset(300 + (i % 50) * 20.0, 200 + (i % 20) * 10.0),
        );
        reloj.start();
        await tester.pump(const Duration(milliseconds: 33));
        reloj.stop();
        cuadros++;
      }
    }
    await mouse.removePointer();

    final promedio = reloj.elapsedMicroseconds / cuadros / 1000;
    final cache = estado(tester).letrasEnCache as int;
    // ignore: avoid_print
    print(
      'bosque 1920x1080: ${promedio.toStringAsFixed(2)} ms por cuadro '
      '(modo debug), $cache letras en caché',
    );
    // Holgado a propósito (modo debug es varias veces más lento que release).
    expect(promedio, lessThan(25));
    expect(cache, lessThan(300));
  });

  // ── Cada evento que puede pasar con el login abierto ─────────────────────

  /// Corre [cuadros] cuadros de 33 ms y devuelve el promedio en ms.
  Future<double> correr(WidgetTester tester, int cuadros) async {
    final reloj = Stopwatch();
    for (var i = 0; i < cuadros; i++) {
      reloj.start();
      await tester.pump(const Duration(milliseconds: 33));
      reloj.stop();
    }
    return reloj.elapsedMicroseconds / cuadros / 1000;
  }

  testWidgets('tormenta de redimensiones (estirar la ventana)', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    var peor = 0.0;
    final errores = await capturandoErrores(() async {
      for (final tam in const [
        Size(1047, 1000),
        Size(800, 600),
        Size(1920, 1080),
        Size(390, 300),
        Size(1200, 900),
        Size(600, 1000),
        Size(1047, 1000),
      ]) {
        await tester.pumpWidget(escena(tam: tam));
        peor = math.max(peor, await correr(tester, 10));
        expect(estado(tester).hojasEnElAire as int, lessThanOrEqualTo(36));
      }
    });
    // ignore: avoid_print
    print('redimensiones: peor promedio ${peor.toStringAsFixed(2)} ms');
    expect(errores, isEmpty);
    expect(peor, lessThan(25));
    expect(estado(tester).letrasEnCache as int, lessThan(300));
  });

  testWidgets('20 s con ráfagas, hojas y halcón: estable y acotado', (
    tester,
  ) async {
    const tam = Size(1047, 1000);
    tester.view.physicalSize = tam;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    var maxHojas = 0, total = 0.0;
    final errores = await capturandoErrores(() async {
      await tester.pumpWidget(escena(tam: tam));
      expect(estado(tester).hayHalcon as bool, isTrue);
      for (var tramo = 0; tramo < 20; tramo++) {
        total += await correr(tester, 30);
        final hojas = estado(tester).hojasEnElAire as int;
        maxHojas = math.max(maxHojas, hojas);
        expect(hojas, lessThanOrEqualTo(36));
      }
    });
    final promedio = total / 20;
    // ignore: avoid_print
    print(
      '20 s: ${promedio.toStringAsFixed(2)} ms por cuadro, hasta $maxHojas '
      'hojas, ${estado(tester).letrasEnCache} letras en caché',
    );
    expect(errores, isEmpty);
    expect(maxHojas, greaterThan(0), reason: 'las copas sueltan hojas');
    expect(promedio, lessThan(25));
    expect(estado(tester).letrasEnCache as int, lessThan(300));
  });

  testWidgets('mouse frenético: entra, sale y corre por toda la escena', (
    tester,
  ) async {
    final errores = await capturandoErrores(() async {
      await tester.pumpWidget(escena(tam: const Size(760, 900)));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      final r = math.Random(3);
      for (var i = 0; i < 200; i++) {
        if (i % 25 == 0) {
          await mouse.addPointer(location: Offset(r.nextDouble() * 760, 10));
        }
        await mouse.moveTo(
          Offset(r.nextDouble() * 900 - 70, r.nextDouble() * 1000 - 50),
        );
        await tester.pump(const Duration(milliseconds: 16));
        if (i % 25 == 24) await mouse.removePointer();
      }
    });
    expect(errores, isEmpty);
  });

  testWidgets('pausar y reanudar 20 veces (varios intentos de sesión)', (
    tester,
  ) async {
    final errores = await capturandoErrores(() async {
      for (var i = 0; i < 20; i++) {
        final pausa = i.isOdd;
        await tester.pumpWidget(
          escena(tam: const Size(760, 900), pausado: pausa),
        );
        // Una pausa larga no debe hacer que todo «salte» al volver.
        await tester.pump(Duration(milliseconds: pausa ? 3000 : 100));
        expect(estado(tester).animando as bool, !pausa);
      }
    });
    expect(errores, isEmpty);
    expect(estado(tester).hojasEnElAire as int, lessThanOrEqualTo(36));
  });

  testWidgets('tapada por otra pantalla o un diálogo: no pide cuadros', (
    tester,
  ) async {
    Widget tapada(bool activa) =>
        TickerMode(enabled: activa, child: escena(tam: const Size(760, 900)));
    await tester.pumpWidget(tapada(false));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(tapada(true));
    await tester.pump(const Duration(milliseconds: 33));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('nueve semillas en claro y oscuro: caché acotada', (
    tester,
  ) async {
    final errores = await capturandoErrores(() async {
      for (var semilla = 0; semilla < 9; semilla++) {
        for (final oscuro in [false, true]) {
          await tester.pumpWidget(
            escena(tam: const Size(760, 900), oscuro: oscuro, semilla: semilla),
          );
          await correr(tester, 4);
        }
      }
    });
    expect(errores, isEmpty);
    // Cada cambio de tema descarta lo anterior: no se suman 18 temas.
    expect(estado(tester).letrasEnCache as int, lessThan(300));
  });

  testWidgets('en teléfono no hay halcón (franja de cielo angosta)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme().getTheme(),
        home: const Scaffold(
          body: SizedBox(
            width: 390,
            height: 844,
            child: BosqueAscii(
              altoBosque: 0.16,
              techoAves: 0.2,
              densidadAves: 0.5,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(estado(tester).hayHalcon as bool, isFalse);
  });

  testWidgets('login real a 1920×1080: escribir mientras anima no se traba', (
    tester,
  ) async {
    dotenv.testLoad(fileInput: '');
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // El mismo login con la escena animando y quieta: se compara uno contra el
    // otro en la misma corrida, así una máquina cargada no da un falso error.
    Widget login({required bool quieto}) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme(isDarkMode: true, selectedColor: 8).getTheme(),
        builder:
            (c, hijo) => MediaQuery(
              data: MediaQuery.of(c).copyWith(disableAnimations: quieto),
              child: hijo!,
            ),
        home: const LoginScreen(),
      ),
    );

    Future<double> teclear({required bool quieto}) async {
      await tester.pumpWidget(login(quieto: quieto));
      await correr(tester, 10);
      expect(estado(tester).animando as bool, !quieto);
      final campos = find.byType(TextField);
      final reloj = Stopwatch()..start();
      var teclas = 0;
      for (final (i, texto) in [(0, 'mjaimes'), (1, 'clave123')]) {
        for (var n = 1; n <= texto.length; n++) {
          await tester.enterText(campos.at(i), texto.substring(0, n));
          await tester.pump(const Duration(milliseconds: 33));
          teclas++;
        }
      }
      reloj.stop();
      // Fuera de pantalla entre vueltas: cada una arranca con el login nuevo.
      await tester.pumpWidget(const SizedBox());
      return reloj.elapsedMicroseconds / teclas / 1000;
    }

    late double animando, quieto;
    final errores = await capturandoErrores(() async {
      await teclear(quieto: false); // vuelta de calentamiento
      final a = [await teclear(quieto: false), await teclear(quieto: false)];
      final q = [await teclear(quieto: true), await teclear(quieto: true)];
      animando = a.reduce(math.min);
      quieto = q.reduce(math.min);
    });
    // ignore: avoid_print
    print(
      'login escribiendo: ${animando.toStringAsFixed(2)} ms por tecla con '
      'el bosque, ${quieto.toStringAsFixed(2)} ms con el bosque quieto',
    );
    expect(errores, isEmpty);
    expect(animando, lessThan(quieto * 2 + 5));
  });
}
