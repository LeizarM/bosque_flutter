import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bosque_flutter/core/config/router.dart';
import 'package:bosque_flutter/core/state/entregas_provider.dart';
import 'package:bosque_flutter/core/state/theme_mode_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:bosque_flutter/data/repositories/entregas_impl.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final token = await SecureStorage().getToken();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(ProviderScope(
    overrides: [
      entregasRepositoryProvider.overrideWithValue(EntregasImpl()),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MyApp(initialToken: token),
  ));
}

class MyApp extends ConsumerWidget {
  final String? initialToken;

  const MyApp({super.key, this.initialToken});

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
          child: responsiveChild,
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}