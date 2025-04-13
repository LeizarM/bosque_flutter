import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bosque_flutter/presentation/screens/screens.dart';

class AppRouter {
  static GoRouter getRouter({String? initialToken}) {
    return GoRouter(
      initialLocation: initialToken != null ? '/dashboard' : '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
      ],
      redirect: (BuildContext context, GoRouterState state) async {
        // Usar Riverpod para verificar si hay un usuario logueado
        final container = ProviderContainer();
        final user = container.read(userProvider);
        final token = await SecureStorage().getToken();
        final isLoggedIn = user != null || token != null;

        final isOnLoginPage = state.uri.toString() == '/login';

        if (!isLoggedIn && !isOnLoginPage) {
          return '/login'; // Redirigir al login si no hay sesión
        } else if (isLoggedIn && isOnLoginPage) {
          return '/dashboard'; // Redirigir al dashboard si hay sesión
        }
        return null; // No redirigir si la ruta es correcta
      },
    );
  }
}
