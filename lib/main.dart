import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:bosque_flutter/core/config/router.dart';
import 'package:bosque_flutter/core/state/entregas_provider.dart';
import 'package:bosque_flutter/core/state/theme_mode_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/data/repositories/entregas_impl.dart';
import 'package:bosque_flutter/presentation/widgets/shared/connectivity_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(
    ProviderScope(
      overrides: [entregasRepositoryProvider.overrideWithValue(EntregasImpl())],
      child: const MyApp(),
    ),
  );
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
