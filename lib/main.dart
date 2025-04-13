import 'package:bosque_flutter/core/config/router.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Verificar si hay un token almacenado al iniciar la app
  final token = await SecureStorage().getToken();
  runApp(ProviderScope(
    overrides: [
      // Si hay token, podrías cargar datos del usuario aquí (opcional)
      // Por ahora, solo inicializamos como nulo y dejamos la lógica al router
    ],
    child: MyApp(initialToken: token),
  ));
}

class MyApp extends StatelessWidget {
  final String? initialToken;

  const MyApp({super.key, this.initialToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bosque',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
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