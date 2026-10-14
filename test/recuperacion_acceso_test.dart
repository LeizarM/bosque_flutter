import 'dart:io';

import 'package:bosque_flutter/core/state/recuperacion_acceso_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/presentation/screens/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/repositorio_recuperacion.dart';

/// Recuperación de acceso dentro de la pantalla de login, con un repositorio falso:
/// los dos pasos, los avisos del backend, las validaciones locales y el armado
/// sin desbordes en teléfono, tablet y escritorio con letra al 150 %.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepoRecuperacionFalso repo;

  setUpAll(() async {
    // El login arma AuthRepositoryImpl -> DioClient -> dotenv, que lanza si nadie lo cargó.
    dotenv.testLoad(fileInput: '');
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = RepoRecuperacionFalso();
  });

  Future<void> esperar(
    WidgetTester tester, [
    Duration d = const Duration(milliseconds: 400),
  ]) async {
    await tester.pump();
    await tester.pump(d);
  }

  Future<void> abrir(
    WidgetTester tester, {
    double ancho = 390,
    double escalaTexto = 1,
  }) async {
    tester.view.physicalSize = Size(ancho, ancho <= 450 ? 844 : 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [recuperacionAccesoRepositoryProvider.overrideWithValue(repo)],
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
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(escalaTexto)),
                child: child!,
              ),
          home: const LoginScreen(),
        ),
      ),
    );
    // pump con tiempo y no pumpAndSettle: el halo del logo respira sin parar.
    // Los 4 s cubren el timeout de 3 s con que ThemeNotifier lee el tema guardado.
    await esperar(tester, const Duration(seconds: 4));
  }

  Future<void> tocar(WidgetTester tester, String texto) async {
    final boton = find.text(texto);
    await tester.ensureVisible(boton);
    await tester.pump();
    await tester.tap(boton);
    await esperar(tester);
  }

  Future<void> escribir(WidgetTester tester, String etiqueta, String texto) async {
    final campo = find.widgetWithText(TextField, etiqueta);
    await tester.ensureVisible(campo);
    await tester.enterText(campo, texto);
    await tester.pump();
  }

  Future<void> irAlSegundoPaso(WidgetTester tester) async {
    await tocar(tester, '¿Olvidaste tu contraseña?');
    await escribir(tester, 'Usuario', '  jperez ');
    await tocar(tester, 'Enviar código');
  }

  testWidgets('el enlace abre la recuperación y «Volver» regresa al login', (tester) async {
    await abrir(tester);

    await tocar(tester, '¿Olvidaste tu contraseña?');
    expect(find.text('Recupera tu acceso'), findsOneWidget);
    expect(find.text('Bienvenido'), findsNothing);

    await tocar(tester, 'Volver a iniciar sesión');
    expect(find.text('Bienvenido'), findsOneWidget);
  });

  testWidgets('el gesto de volver del sistema regresa al login y no cierra la app', (tester) async {
    await abrir(tester);
    await tocar(tester, '¿Olvidaste tu contraseña?');

    await tester.binding.handlePopRoute();
    await esperar(tester);

    expect(find.text('Bienvenido'), findsOneWidget);
  });

  testWidgets('pedir el código muestra el correo enmascarado y la espera para reenviar', (tester) async {
    await abrir(tester);
    await irAlSegundoPaso(tester);

    expect(repo.solicitudes, ['jperez']);
    expect(find.text('Revisa tu correo'), findsOneWidget);
    expect(find.textContaining('j****z@esppapel.com'), findsOneWidget);
    expect(find.text('Reenviar en 60 s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 60));
    await tester.pump();
    expect(find.text('Reenviar código'), findsOneWidget);
  });

  testWidgets('el motivo del backend se muestra tal cual', (tester) async {
    repo.errorAlSolicitar =
        'No tienes un correo corporativo registrado. Pide a Recursos Humanos que lo registre o comunícate con un administrador.';
    await abrir(tester);
    await irAlSegundoPaso(tester);

    expect(find.text(repo.errorAlSolicitar as String), findsOneWidget);
    expect(find.text('Recupera tu acceso'), findsOneWidget);
  });

  testWidgets('lo que se valida en la app no gasta intentos del código', (tester) async {
    await abrir(tester);
    await irAlSegundoPaso(tester);

    await escribir(tester, 'Código de 6 dígitos', '12ab3');
    await tocar(tester, 'Cambiar contraseña');
    expect(find.text('Escribe los 6 dígitos del código.'), findsOneWidget);

    await escribir(tester, 'Código de 6 dígitos', '123456');
    await escribir(tester, 'Nueva contraseña', 'clave-nueva');
    await escribir(tester, 'Repite la nueva contraseña', 'clave-otra');
    await tocar(tester, 'Cambiar contraseña');
    expect(find.text('Las dos contraseñas no coinciden.'), findsOneWidget);

    expect(repo.restablecimientos, isEmpty);
  });

  testWidgets('al cambiar la contraseña vuelve al login con el aviso y el usuario puesto', (tester) async {
    await abrir(tester);
    await irAlSegundoPaso(tester);

    await escribir(tester, 'Código de 6 dígitos', '654321');
    await escribir(tester, 'Nueva contraseña', ' clave-nueva ');
    await escribir(tester, 'Repite la nueva contraseña', 'clave-nueva');
    await tocar(tester, 'Cambiar contraseña');

    expect(repo.restablecimientos.single, {
      'login': 'jperez',
      'codigo': '654321',
      'nuevaContrasena': 'clave-nueva',
    });
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text(repo.mensajeListo), findsOneWidget);
    final usuario = tester.widget<TextField>(find.widgetWithText(TextField, 'Usuario'));
    expect(usuario.controller!.text, 'jperez');
  });

  testWidgets('«Ya tengo un código» pasa al segundo paso sin pedir otro', (tester) async {
    await abrir(tester);
    await tocar(tester, '¿Olvidaste tu contraseña?');
    await escribir(tester, 'Usuario', 'jperez');
    await tocar(tester, 'Ya tengo un código');

    expect(find.text('Revisa tu correo'), findsOneWidget);
    expect(find.text('Reenviar código'), findsOneWidget);
    expect(repo.solicitudes, isEmpty);

    await escribir(tester, 'Código de 6 dígitos', '654321');
    await escribir(tester, 'Nueva contraseña', 'clave-nueva');
    await escribir(tester, 'Repite la nueva contraseña', 'clave-nueva');
    await tocar(tester, 'Cambiar contraseña');
    expect(repo.restablecimientos.single['login'], 'jperez');
  });

  testWidgets('en el segundo paso se ve el usuario y se corrige sin salir del flujo', (tester) async {
    await abrir(tester);
    await tocar(tester, '¿Olvidaste tu contraseña?');
    await escribir(tester, 'Usuario', 'jperz');
    await tocar(tester, 'Ya tengo un código');

    expect(find.text('Usuario: jperz'), findsOneWidget);
    await tocar(tester, 'Cambiar usuario');

    expect(find.text('Recupera tu acceso'), findsOneWidget);
    await escribir(tester, 'Usuario', 'jperez');
    await tocar(tester, 'Ya tengo un código');
    expect(find.text('Usuario: jperez'), findsOneWidget);
  });

  testWidgets('la confirmación avisa en vivo cuando no coincide', (tester) async {
    await abrir(tester);
    await irAlSegundoPaso(tester);

    await escribir(tester, 'Nueva contraseña', 'clave-nueva');
    await escribir(tester, 'Repite la nueva contraseña', 'clave-n');
    expect(find.text('No coincide con la nueva contraseña.'), findsOneWidget);

    await escribir(tester, 'Repite la nueva contraseña', 'clave-nueva');
    expect(find.text('No coincide con la nueva contraseña.'), findsNothing);
  });

  testWidgets('sin desbordes a 390 px con letra al 200 %', (tester) async {
    await abrir(tester, escalaTexto: 2);
    await tocar(tester, '¿Olvidaste tu contraseña?');
    await escribir(tester, 'Usuario', 'jperez');
    await tocar(tester, 'Enviar código');
    expect(find.text('Revisa tu correo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final ancho in [390.0, 800.0, 1400.0]) {
    testWidgets('sin desbordes a $ancho px con letra al 150 %', (tester) async {
      await abrir(tester, ancho: ancho, escalaTexto: 1.5);
      await tocar(tester, '¿Olvidaste tu contraseña?');
      expect(tester.takeException(), isNull, reason: 'primer paso');

      await escribir(tester, 'Usuario', 'jperez');
      await tocar(tester, 'Enviar código');
      expect(find.text('Revisa tu correo'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'segundo paso');
    });
  }
}
