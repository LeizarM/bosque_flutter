// Arnés de las pruebas de pantalla de Horas Extras: la app de prueba con el
// tema real, el español, los puntos de quiebre y el montaje un fotograma
// después; las fuentes reales y la captura de errores de dibujo.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:bosque_flutter/core/state/button_permissions_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/entities/usuarioBtn_entity.dart';

import 'repositorio_depositos.dart' show loginAdminFalso;

/// Carga Roboto y JetBrainsMono desde `assets/fonts`. Con la fuente de
/// reemplazo de las pruebas el texto se ensancha y aparecen desbordes falsos.
Future<void> cargarFuentesHex() async {
  Future<void> cargar(String familia, List<String> archivos) async {
    final cargador = FontLoader(familia);
    for (final a in archivos) {
      final f = File('assets/fonts/$a.ttf');
      if (f.existsSync()) {
        cargador.addFont(
          Future.value(ByteData.sublistView(f.readAsBytesSync())),
        );
      }
    }
    await cargador.load();
  }

  await cargar('Roboto', ['Roboto-Regular', 'Roboto-Medium', 'Roboto-Bold']);
  await cargar('JetBrainsMono', [
    'JetBrainsMono-400',
    'JetBrainsMono-500',
    'JetBrainsMono-700',
  ]);
}

/// Monta [pantalla] en una ventana de [ancho] px. Sin [botones] entra un
/// administrador (todo permitido); con ellos, un usuario común que solo
/// tiene esos botones de `tb_vistaBtn`.
Future<void> montarHex(
  WidgetTester t,
  Widget pantalla, {
  double ancho = 1400,
  List<Override> overrides = const [],
  Set<String>? botones,
}) async {
  // El cliente HTTP lee el .env al armarse (lo arma el notifier de botones).
  if (!dotenv.isInitialized) dotenv.testLoad(fileInput: '');
  t.view.physicalSize = Size(ancho, ancho <= 450 ? 844 : 900);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);

  final usuario =
      botones == null
          ? loginAdminFalso
          : LoginEntity.fromJson(<String, dynamic>{
            'tipoUsuario': 'ROLE_LIM',
            'codUsuario': 7,
          });

  await t.pumpWidget(
    ProviderScope(
      overrides: [
        userProvider.overrideWith(
          (ref) => UserStateNotifier.sinStorage(usuario),
        ),
        if (botones != null)
          buttonPermissionsProvider.overrideWith(
            (ref) => _BotonesFalsos(ref, botones),
          ),
        ...overrides,
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
    ),
  );
  await t.pump();
}

/// [n] fotogramas de 200 ms. No `pumpAndSettle`: los esqueletos de carga
/// laten en bucle y nunca se asientan.
Future<void> esperar(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 200));
  }
}

/// Verifica que el desplazamiento vertical de [pantalla] use el controlador
/// primario que ella misma provee sobre su `Scaffold`: así, tocar la barra de
/// estado en iOS lleva la página al inicio.
void verificarControlPrimarioHex(WidgetTester t, Type pantalla) {
  final scaffold =
      find
          .descendant(
            of: find.byType(pantalla),
            matching: find.byType(Scaffold),
          )
          .first;
  final primario = PrimaryScrollController.maybeOf(t.element(scaffold));
  expect(primario, isNotNull, reason: 'falta el PrimaryScrollController');
  final pagina =
      find
          .descendant(
            of: find.byType(pantalla),
            matching: find.byType(Scrollable),
          )
          .first;
  expect(t.widget<Scrollable>(pagina).controller, same(primario));
  expect(primario!.hasClients, isTrue);
}

/// Anota las vibraciones que pide la app (`HapticFeedback`) mientras dura la
/// prueba. Devuelve la lista viva de tipos, por ejemplo `selectionClick`.
List<String> capturarVibracionesHex() {
  final tipos = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (llamada) async {
        if (llamada.method == 'HapticFeedback.vibrate') {
          tipos.add(
            '${llamada.arguments}'.replaceFirst('HapticFeedbackType.', ''),
          );
        }
        return null;
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return tipos;
}

/// Desmonta todo para soltar suscripciones, relojes y avisos.
Future<void> cerrar(WidgetTester t) async {
  await t.pumpWidget(const SizedBox.shrink());
  await t.pump();
}

/// Junta los errores de dibujo (desbordes, aserciones de layout) desde ahora.
/// Las fallas de la prueba (`expect`, `tap` sin destino) siguen yendo al
/// binding. Al terminar, si quedan errores la prueba falla: esperarlos = `clear()`.
List<FlutterErrorDetails> capturarErrores() {
  final errores = <FlutterErrorDetails>[];
  final previo = FlutterError.onError;
  FlutterError.onError = (detalles) {
    if (detalles.library == _bibliotecaDePruebas) {
      previo?.call(detalles);
    } else {
      errores.add(detalles);
    }
  };
  // También atrapa lo que se rompe después del último `expect` (al cerrar).
  addTearDown(() {
    FlutterError.onError = previo;
    if (errores.isNotEmpty) {
      fail(
        'Errores de dibujo al terminar la prueba:\n'
        '${errores.map((e) => e.exceptionAsString()).join('\n')}',
      );
    }
  });
  return errores;
}

/// La biblioteca con la que el binding reporta las fallas de la prueba.
const String _bibliotecaDePruebas = 'Flutter test framework';

/// Botones de un usuario común: el ACL que devolvería `tb_vistaBtn`.
class _BotonesFalsos extends ButtonPermissionsNotifier {
  _BotonesFalsos(Ref ref, this._botones)
    : super(ref, UserStateNotifier.sinStorage(null), null) {
    state = AsyncValue.data([
      for (final b in _botones)
        UsuarioBtnEntity(
          codUsuario: 7,
          codBtn: 1,
          nivelAcceso: 1,
          audUsuario: 1,
          boton: b,
          permiso: 1,
          pertenVist: 1,
        ),
    ]);
  }

  final Set<String> _botones;

  @override
  bool tienePermiso(String nombreBtn) => _botones.contains(nombreBtn);
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
