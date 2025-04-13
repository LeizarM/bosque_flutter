import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bosque_flutter/presentation/screens/screens.dart';

// Proveedor para el router que se crea una sola vez
final routerProvider = Provider<GoRouter>((ref) {
  final shellNavigatorKey = GlobalKey<NavigatorState>();
  
  return GoRouter(
    initialLocation: '/dashboard',
    debugLogDiagnostics: true, // Habilitar logs de diagnóstico para depuración
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      // Shell route for dashboard
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return DashboardScreen(child: child);
        },
        routes: [
          // Dashboard home
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardHomeContent(),
          ),
          // Ventas module
          GoRoute(
            path: '/dashboard/ventas',
            name: 'ventas',
            builder: (context, state) => const VentasHomeScreen(),
          ),
          // Add more module routes here as needed
        ],
      ),
      
      // En caso de que vengan sin el parámetro
      GoRoute(
        path: '/tven_ventas',
        redirect: (context, state) => '/dashboard/ventas',
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Página no encontrada'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48.0, color: Colors.red),
            const SizedBox(height: 16.0),
            Text('No se encontró la página: ${state.uri}', 
                 style: const TextStyle(fontSize: 18.0)),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Volver al dashboard'),
            ),
          ],
        ),
      ),
    ),
    redirect: (BuildContext context, GoRouterState state) async {
      // Usar Riverpod para verificar si hay un usuario logueado
      final user = ref.read(userProvider);
      final token = await SecureStorage().getToken();
      final isLoggedIn = user != null || token != null;

      final isOnLoginPage = state.uri.toString() == '/login';

      // Si no está logueado y no está en login, redirigir a login
      if (!isLoggedIn && !isOnLoginPage) {
        return '/login';
      } 
      
      // Si está logueado y está en login, redirigir a dashboard
      if (isLoggedIn && isOnLoginPage) {
        return '/dashboard';
      }
      
      // En otros casos, mantener la ruta actual
      return null;
    },
  );
});

// Mantenemos la clase AppRouter para compatibilidad con código existente
class AppRouter {
  // Este método ahora es solo por compatibilidad
  static GoRouter getRouter({String? initialToken}) {
    // Create the shell branch
    final shellNavigatorKey = GlobalKey<NavigatorState>();
    
    return GoRouter(
      initialLocation: initialToken != null ? '/dashboard' : '/login',
      debugLogDiagnostics: true, // Habilitar logs de diagnóstico para depuración
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        // Shell route for dashboard
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) {
            return DashboardScreen(child: child);
          },
          routes: [
            // Dashboard home
            GoRoute(
              path: '/dashboard',
              name: 'dashboard',
              builder: (context, state) => const DashboardHomeContent(),
            ),
            // Ventas module
            GoRoute(
              path: '/dashboard/ventas',
              name: 'ventas',
              builder: (context, state) => const VentasHomeScreen(),
            ),
            // Add more module routes here as needed
          ],
        ),
        
        // En caso de que vengan sin el parámetro
        GoRoute(
          path: '/tven_ventas',
          redirect: (context, state) => '/dashboard/ventas',
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Página no encontrada'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48.0, color: Colors.red),
              const SizedBox(height: 16.0),
              Text('No se encontró la página: ${state.uri}', 
                   style: const TextStyle(fontSize: 18.0)),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Volver al dashboard'),
              ),
            ],
          ),
        ),
      ),
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
