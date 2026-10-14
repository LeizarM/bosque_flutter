import 'dart:io';

import 'package:bosque_flutter/core/state/configuracion_recuperacion_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/presentation/screens/configuracion-recuperacion/configuracion_recuperacion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/repositorio_configuracion_recuperacion.dart';

/// Pantalla de parámetros de la recuperación de acceso con un repositorio falso: tabla o filas según
/// el ancho, la contraseña que nunca se muestra, el guardado y el correo de prueba.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepoConfiguracionRecuperacionFalso repo;

  setUpAll(() async {
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

  setUp(() => repo = RepoConfiguracionRecuperacionFalso());

  Future<void> esperar(WidgetTester tester, [Duration d = const Duration(milliseconds: 400)]) async {
    await tester.pump();
    await tester.pump(d);
  }

  Future<void> abrir(WidgetTester tester, {double ancho = 1400, double escalaTexto = 1}) async {
    tester.view.physicalSize = Size(ancho, ancho <= 450 ? 844 : 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [configuracionRecuperacionRepositoryProvider.overrideWithValue(repo)],
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
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(escalaTexto)),
                child: child!,
              ),
          home: const ConfiguracionRecuperacionScreen(),
        ),
      ),
    );
    await esperar(tester);
  }

  /// El aviso del kit se cierra solo: se deja correr su tiempo para no dejar timers vivos.
  Future<void> dejarQueSeCierreElAviso(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));
  }

  for (final ancho in [390.0, 800.0, 1400.0]) {
    testWidgets('sin desbordes a $ancho px con letra al 130 %', (tester) async {
      await abrir(tester, ancho: ancho, escalaTexto: 1.3);

      expect(find.text('Vigencia del código'), findsOneWidget);
      // Tabla con columnas cuando hay lugar; en teléfono, filas sin cabecera.
      expect(find.text('Modificado'), ancho >= 600 ? findsWidgets : findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('la contraseña SMTP no se muestra: solo si está cargada', (tester) async {
    await abrir(tester);

    expect(find.text('Configurada'), findsOneWidget);
  });

  testWidgets('editar un número lo guarda y relee la lista', (tester) async {
    await abrir(tester);
    final lecturasAntes = repo.lecturas;

    final fila = find.ancestor(of: find.text('Vigencia del código'), matching: find.byType(Row)).first;
    await tester.tap(find.descendant(of: fila, matching: find.text('Editar')));
    await esperar(tester);
    await tester.enterText(find.byType(TextField).last, '20');
    await tester.tap(find.text('Guardar'));
    await esperar(tester);

    expect(repo.guardados, [('vigenciaMinutos', '20')]);
    expect(find.byType(AlertDialog), findsNothing);
    expect(repo.lecturas, greaterThan(lecturasAntes));
    await dejarQueSeCierreElAviso(tester);
  });

  testWidgets('un número fuera de rango se avisa sin llamar al backend', (tester) async {
    await abrir(tester);

    final fila = find.ancestor(of: find.text('Vigencia del código'), matching: find.byType(Row)).first;
    await tester.tap(find.descendant(of: fila, matching: find.text('Editar')));
    await esperar(tester);
    await tester.enterText(find.byType(TextField).last, '90');
    await tester.tap(find.text('Guardar'));
    await esperar(tester);

    expect(find.text('El valor tiene que estar entre 5 y 60.'), findsOneWidget);
    expect(repo.guardados, isEmpty);
  });

  testWidgets('el motivo del backend queda en el diálogo, que sigue abierto', (tester) async {
    repo.errorAlGuardar = 'Falta configurar CONFIG_CIFRADO_CLAVE en el servidor.';
    await abrir(tester);

    final fila = find.ancestor(of: find.text('Contraseña SMTP'), matching: find.byType(Row)).first;
    await tester.tap(find.descendant(of: fila, matching: find.text('Editar')));
    await esperar(tester);
    await tester.enterText(find.byType(TextField).last, 'clave-smtp');
    await tester.tap(find.text('Guardar'));
    await esperar(tester);

    expect(find.text(repo.errorAlGuardar as String), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('el correo de prueba va al remitente por defecto', (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Enviar correo de prueba'));
    await esperar(tester);
    await tester.tap(find.text('Enviar'));
    await esperar(tester);

    expect(repo.pruebas, ['bosque@esppapel.com']);
    await dejarQueSeCierreElAviso(tester);
  });
}
