import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:bosque_flutter/core/config/router.dart';
import 'package:bosque_flutter/core/state/theme_mode_provider.dart';
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

  // Sin overrides. El de entregasRepositoryProvider que estaba acá construía EntregasImpl
  // —y con él todo el cliente Dio— antes del primer frame, para TODOS los usuarios, entraran
  // o no al módulo de entregas. Ahora ese provider se fabrica solo y de forma lazy
  // (ver core/state/entregas_provider.dart).
  runApp(const ProviderScope(child: MyApp()));
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
      builder: (context, child) {
        Widget responsiveChild = ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: ResponsiveUtilsBosque.breakpoints,
        );

        return MouseRegion(
          opaque: false,
          hitTestBehavior: HitTestBehavior.translucent,
          child: ConnectivityWrapper(child: responsiveChild),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
