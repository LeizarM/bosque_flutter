import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:bosque_flutter/core/config/router.dart';
import 'package:bosque_flutter/core/state/theme_mode_provider.dart';
import 'package:bosque_flutter/core/theme/app_scroll_behavior.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/shared/connectivity_wrapper.dart';

/// Marca de build, para poder confirmar de un vistazo qué código está corriendo.
///
/// Existe porque diagnosticar un bucle de navegación a ciegas cuesta caro: si el
/// navegador sirve un bundle viejo, los logs nuevos simplemente no aparecen y uno
/// termina buscando el problema en código que no se está ejecutando. Con esta
/// línea en la consola se descarta esa posibilidad en dos segundos.
const String kBuildMarker =
    'sesion-fix-17 · rediseno: tipografia propia, cifras mono, pestanas y siluetas';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // debugPrint y no console(): console() se anula en release, asi que el
  // compilador borraba la llamada y con ella la constante. El marcador
  // aparecia solo en debug, o sea nunca en el build que se despliega, que es
  // justo donde hace falta para descartar que el navegador este sirviendo un
  // bundle viejo. debugPrint sigue imprimiendo en release.
  debugPrint('🏷️  BUILD: $kBuildMarker');

  // Solo cargar .env en plataformas móviles y desktop (no web)
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
      if (kDebugMode) {
        console('✅ .env loaded successfully');
        console('BASE_URL_PROD: ${dotenv.env['BASE_URL_PROD']}');
        console('BASE_URL_DEV: ${dotenv.env['BASE_URL_DEV']}');
      }
    } catch (e) {
      if (kDebugMode) {
        console('⚠️ .env not found, using default values: $e');
      }
    }
  } else {
    if (kDebugMode) {
      console('🌐 Web platform detected - using compile-time variables');
    }
  }

  // Pantalla de error amigable en producción.
  //
  // Sin esto, un error al construir CUALQUIER widget (un typo de datos, un
  // null que no debía, etc.) mostraba la pantalla roja y amarilla de
  // Flutter — pensada para que la vea un desarrollador en debug, no un
  // usuario de oficina en producción. Solo se pisa en release: en debug el
  // default sigue siendo útil para diagnosticar mientras se desarrolla.
  if (kReleaseMode) {
    ErrorWidget.builder =
        (FlutterErrorDetails details) => const _FriendlyErrorView();
  }

  // Sin overrides. El de entregasRepositoryProvider que estaba aquí construía EntregasImpl
  // —y con él todo el cliente Dio— antes del primer frame, para TODOS los usuarios, entraran
  // o no al módulo de entregas. Ahora ese provider se fabrica solo y de forma lazy
  // (ver core/state/entregas_provider.dart).
  runApp(const ProviderScope(child: MyApp()));
}

/// Reemplazo de la pantalla roja/amarilla default de Flutter cuando un
/// widget falla al construirse en producción (ver `ErrorWidget.builder` en
/// `main()`).
///
/// Es un [StatelessWidget] con su propio `build(context)` a propósito:
/// `ErrorWidget.builder` no recibe un `BuildContext` — el widget que
/// devuelve sí lo tiene, porque queda insertado en el árbol justo en el
/// lugar donde el widget original falló. `Theme.of(context)` no revienta
/// aunque no haya un Theme arriba: cae al de Material por defecto.
class _FriendlyErrorView extends StatelessWidget {
  const _FriendlyErrorView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ColoredBox(
      color: colorScheme.surface,
      child: Center(
        // FittedBox en vez de un tamaño fijo: este widget puede terminar
        // reemplazando algo tan chico como un ícono dentro de una fila de
        // tabla, así que se achica solo en vez de desbordar ese espacio.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 8),
                Text(
                  'Algo salió mal',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppTheme appTheme = ref.watch(themeNotifierProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Bosque',
      theme: appTheme.getTheme(),
      routerConfig: router,
      // Scrollbar visible en todo widget scrolleable de la app (web/desktop
      // la esperan como wayfinding). Ver doc de AppScrollBehavior.
      scrollBehavior: const AppScrollBehavior(),
      // Sin esto, todo widget de Material que trae texto propio sale en inglés:
      // los calendarios decían «Jan 1, 2019» y «S M T W T F S», y al escribir
      // una fecha a mano el campo pedía mm/dd/yyyy, que en Bolivia se lee al
      // revés y hace ingresar el día equivocado sin que nadie se dé cuenta.
      // Con la locale en español el mismo campo pide dd/mm/aaaa.
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        Widget responsiveChild = ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: ResponsiveUtilsBosque.breakpoints,
        );

        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          // Tope de escala de texto: sin esto, un usuario con la letra del
          // sistema al máximo (accesibilidad, Ajustes de Windows/Android)
          // puede romper el layout de estas pantallas densas en tablas y
          // formularios en grilla. 1.3x deja margen real de accesibilidad
          // sin llegar a desbordar — ver el comentario del parámetro `alto`
          // en presentation/widgets/comisiones/escala_rangos.dart, que ya
          // tuvo que absorber a mano hasta 1.5x en un widget puntual por no
          // existir este tope global (1.3 queda cómodo dentro de ese margen).
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.3),
          ),
          child: MouseRegion(
            opaque: false,
            hitTestBehavior: HitTestBehavior.translucent,
            child: ConnectivityWrapper(child: responsiveChild),
          ),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
