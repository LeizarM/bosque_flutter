import 'package:bosque_flutter/core/config/router.dart';
import 'package:bosque_flutter/core/state/theme_mode_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Verificar si hay un token almacenado al iniciar la app
  final token = await SecureStorage().getToken();
  
  // Pre-cargar preferencias para evitar parpadeo de tema
  final prefs = await SharedPreferences.getInstance();
  final themeIndex = prefs.getInt('theme_mode') ?? 1; // Por defecto ThemeMode.light
  final initialThemeMode = ThemeMode.values[themeIndex];
  
  runApp(ProviderScope(
    overrides: [
      // Si hay token, podrías cargar datos del usuario aquí (opcional)
      // Por ahora, solo inicializamos como nulo y dejamos la lógica al router
    ],
    child: MyApp(initialToken: token, initialThemeMode: initialThemeMode),
  ));
}

class MyApp extends ConsumerWidget {
  final String? initialToken;
  final ThemeMode initialThemeMode;

  const MyApp({super.key, this.initialToken, required this.initialThemeMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observamos cambios en el tema
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'Bosque',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.getRouter(initialToken: initialToken),
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: double.infinity, name: DESKTOP),
        ],
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}