import 'dart:async';

import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bosque_flutter/presentation/screens/screens.dart';

// Controlador global para forzar redirecciones
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

// Proveedor para detectar si la sesión está activa
final authStateProvider = StateProvider<bool>((ref) => false);

// Referencia global para el router
GoRouter? _router;

// Proveedor para el router que se crea una sola vez
final routerProvider = Provider<GoRouter>((ref) {
  final shellNavigatorKey = GlobalKey<NavigatorState>();

  // Observar el estado de autenticación sin leer directamente durante redirecciones
  ref.listen(authStateProvider, (_, __) {
    // Solo escuchar cambios, no hacer nada aquí
  });

  // Crear el router si no existe
  if (_router == null) {
    _router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/login',
      debugLogDiagnostics:
          true, // Habilitar logs de diagnóstico para depuración
      refreshListenable: GoRouterRefreshStream(
        ref.read(authStateProvider.notifier).stream,
      ),
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
            // Entregas
            GoRoute(
              path: '/dashboard/Revision',
              name:
                  'revision', // Cambié el nombre para que coincida mejor con la ruta
              builder: (context, state) => const EntregasHomeScreen(),
            ),
            // Nueva ruta para trch_choferEntrega/Revision bajo dashboard
            GoRoute(
              path: '/dashboard/trch_choferEntrega/Revision',
              name: 'trch_chofer_revision',
              builder: (context, state) => const EntregasHomeScreen(),
            ),
            // Ruta para ver las entregas de uno o varios choferes
            GoRoute(
              path: '/dashboard/trch_choferEntrega/Resumen',
              name: 'trch_chofer_resumen',
              builder: (context, state) => const EntregasDashboardScreen(),
            ),
            //Ruta para ver los usuarios del sistema
            GoRoute(
              path: '/dashboard/tbUsuario/usuario',
              name: 'tbUsuario',
              builder: (context, state) => const UsuariosHomeScreen(),
            ),
            //Ruta para el registro de gasolina
            GoRoute(
              path: '/dashboard/tgas_ControlCombustible/Registro',
              name: 'tgas_ControlCombustible',
              builder: (context, state) => const ControlCombustibleScreen(),
            ),
            //ruta para ver el historial de gasolina de los coches
            GoRoute(
              path: '/dashboard/tgas_ControlCombustible/View',
              name: 'tgas_ControlCombustibleView',
              builder: (context, state) => const ControlCombustibleViewScreen(),
            ),

            // Para el registro de bidones
            GoRoute(
              path: '/dashboard/tgas_ControlCombustibleMaqMont/Registro',
              name: 'tgas_ControlCombustibleMaqMont',
              builder:
                  (context, state) =>
                      const ControlCombustibleMaquinaMontacargaScreen(),
            ),
            //Para ver el historial de bidones
            GoRoute(
              path: '/dashboard/tgas_ControlCombustibleMaqMont/View',
              name: 'tgas_ControlCombustibleMaqMontView',
              builder:
                  (context, state) =>
                      const ControlCombustibleMaquinaMontaCargaViewScreen(),
            ),

            //Para registrar los depositos
            GoRoute(
              path: '/dashboard/tdep_Deposito/Registro',
              name: 'tdep_DepositoReg',
              builder: (context, state) => const DepositoChequeRegisterScreen(),
            ),
            //Para ver el registro de depositos
            GoRoute(
              path: '/dashboard/tdep_Deposito/View',
              name: 'tdep_DepositoView',
              builder: (context, state) => const DepositoChequeViewScreen(),
            ),
            //Para el registro de depositos sin identificar
            GoRoute(
              path: '/dashboard/tdep_DepositoIde/Registro',
              name: 'tdep_DepositoIdeReg',
              builder:
                  (context, state) => const DepositoChequeIdentificarScreen(),
            ),
            //para ver depositos sin identificar
            GoRoute(
              path: '/dashboard/tdep_DepositoIde/View',
              name: 'tdep_DepositoIdeView',
              builder:
                  (context, state) =>
                      const DepositoChequeIdentificarViewScreen(),
            ),
            //Para el prestamo de vehiculos
            GoRoute(
              path: '/dashboard/tpre_Solicitud/Solicitud',
              name: 'tpre_Solicitud',
              builder: (context, state) => const PrestamoDashboardScreen(),
            ),
            GoRoute(
              path: '/dashboard/tpre_Solicitud/VerSolicitud',
              name: 'tpre_SolicitudView',
              builder: (context, state) => const PrestamoViewScreen(),
            ),
            GoRoute(
              path: '/dashboard/ted_EmpleadoDependiente/register',
              name: 'ted_EmpleadoDependiente',
              builder: (context, state) => const EmpleadosDependientesView(),
            ),
          ],
        ),

        // En caso de que vengan sin el parámetro
        GoRoute(
          path: '/tven_ventas',
          redirect: (context, state) => '/dashboard/ventas',
        ),
        GoRoute(
          path: '/trch_choferEntrega',
          redirect:
              (context, state) => '/dashboard/trch_choferEntrega/Revision',
        ),
        GoRoute(
          path: '/trch_choferEntrega/Revision',
          redirect:
              (context, state) => '/dashboard/trch_choferEntrega/Revision',
        ),
        GoRoute(
          path: '/trch_choferEntrega/Resumen',
          redirect: (context, state) => '/dashboard/trch_choferEntrega/Resumen',
        ),
        GoRoute(
          path: '/tbUsuario/Usuario',
          redirect: (context, state) => '/dashboard/tbUsuario/usuario',
        ),
        GoRoute(
          path: '/tgas_ControlCombustible/Registro',
          redirect:
              (context, state) => '/dashboard/tgas_ControlCombustible/Registro',
        ),
        GoRoute(
          path: '/tgas_ControlCombustible/View',
          redirect:
              (context, state) => '/dashboard/tgas_ControlCombustible/View',
        ),
        GoRoute(
          path: '/tgas_ControlCombustibleMaqMont/Registro',
          redirect:
              (context, state) =>
                  '/dashboard/tgas_ControlCombustibleMaqMont/Registro',
        ),
        GoRoute(
          path: '/tgas_ControlCombustibleMaqMont/View',
          redirect:
              (context, state) =>
                  '/dashboard/tgas_ControlCombustibleMaqMont/View',
        ),
        GoRoute(
          path: '/tdep_Deposito/Registro',
          redirect: (context, state) => '/dashboard/tdep_Deposito/Registro',
        ),
        GoRoute(
          path: '/tdep_Deposito/View',
          redirect: (context, state) => '/dashboard/tdep_Deposito/View',
        ),
        GoRoute(
          path: '/tdep_DepositoIde/Registro',
          redirect: (context, state) => '/dashboard/tdep_DepositoIde/Registro',
        ),
        GoRoute(
          path: '/tdep_DepositoIde/View',
          redirect: (context, state) => '/dashboard/tdep_DepositoIde/View',
        ),
        // Ruta para prestamo de vehiculos
        GoRoute(
          path: '/tpre_Solicitud/Solicitud/Register',
          redirect: (context, state) => '/dashboard/tpre_Solicitud/Solicitud',
        ),
        //Para ver el prestamo de vehiculos
        GoRoute(
          path: '/tpre_Solicitud/VerSolicitud',
          redirect:
              (context, state) => '/dashboard/tpre_Solicitud/VerSolicitud',
        ),

        GoRoute(
          path: '/ted_EmpleadoDependiente/register',
          redirect:
              (context, state) => '/dashboard/ted_EmpleadoDependiente/register',
        ),

        GoRoute(
          path: '/change-password',
          name: 'change-password',
          builder: (context, state) {
            final user = state.extra as LoginEntity?;
            if (user == null) {
              // Si no hay usuario, redirigir al login
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go('/login');
              });
              return const SizedBox.shrink();
            }
            return ChangePasswordScreen(user: user);
          },
        ),
      ],
      errorBuilder:
          (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Página no encontrada')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48.0,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'No se encontró la página: ${state.uri}',
                    style: const TextStyle(fontSize: 18.0),
                  ),
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
        // Validar usuario y versión usando asyncUserProvider

        final isOnLoginPage = state.uri.toString() == '/login';
        if (state.fullPath == '/') {
          return '/login';
        }
        return null;
      },
    );

    // Configurar el callback de error de autenticación para redireccionar
    // Usando una referencia al router
    DioClient.setAuthErrorCallback(() {
      // Usar un container aislado para evitar conflictos de dependencias
      final container = ProviderContainer();
      try {
        container.read(authStateProvider.notifier).state = false;
      } finally {
        container.dispose();
      }

      // Usar el router para navegar
      _router?.go('/login');
    });

    // Inicializar el estado de autenticación
    //_initAuthState(ref);
  }

  return _router!;
});

// Función para inicializar el estado de autenticación
/*void _initAuthState(Ref ref) async {
  final secureStorage = SecureStorage();
  final isTokenExpired = await secureStorage.isTokenExpired();

  if (!isTokenExpired) {
    // Solo marcar como autenticado si el token es válido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authStateProvider.notifier).state = true;
    });
  } else {
    // Limpiar la sesión si el token expiró
    await secureStorage.clearSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).clearUser();
    });
  }
}
*/
// Clase para notificar cambios de estado de autenticación al router
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<bool> stream) {
    notifyListeners();
    _subscription = stream.listen((dynamic _) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Mantenemos la clase AppRouter para compatibilidad con código existente
class AppRouter {
  // Este método ahora es solo por compatibilidad
  static GoRouter getRouter({String? initialToken}) {
    // Create the shell branch
    final shellNavigatorKey = GlobalKey<NavigatorState>();

    // Si ya tenemos un router global, usarlo
    if (_router != null) {
      return _router!;
    }

    final router = GoRouter(
      initialLocation: initialToken != null ? '/dashboard' : '/login',
      debugLogDiagnostics:
          true, // Habilitar logs de diagnóstico para depuración
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
            // Disponibilidad detallada
            GoRoute(
              path: '/dashboard/disponibilidad/:codArticulo',
              name: 'disponibilidad',
              redirect: (context, state) {
                // Si no hay extra, significa que se recargó la página
                // o se accedió directamente por URL
                if (state.extra == null) {
                  // Redireccionar a ventas porque necesitamos el objeto completo
                  return '/dashboard/ventas';
                }
                return null; // No redireccionar si tenemos el objeto
              },
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
      errorBuilder:
          (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Página no encontrada')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48.0,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'No se encontró la página: ${state.uri}',
                    style: const TextStyle(fontSize: 18.0),
                  ),
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
        // Verificar si el token está expirado
        final secureStorage = SecureStorage();
        final isTokenExpired = await secureStorage.isTokenExpired();

        // Si el token expiró, limpiar datos y redirigir al login
        if (isTokenExpired) {
          debugPrint('🔑 Token expirado detectado en AppRouter.getRouter');
          // Limpiar datos de sesión
          await secureStorage.clearSession();

          // Solo redirigir si no estamos ya en el login
          if (state.uri.toString() != '/login') {
            return '/login';
          }
        }

        // Usar Riverpod para verificar si hay un usuario logueado
        // Con un container propio para evitar dependencias
        final container = ProviderContainer();
        bool isLoggedIn;

        try {
          final user = container.read(userProvider);
          final token = await SecureStorage().getToken();
          isLoggedIn = (user != null || token != null) && !isTokenExpired;
        } finally {
          container.dispose();
        }

        final isOnLoginPage = state.uri.toString() == '/login';

        if (!isLoggedIn && !isOnLoginPage) {
          return '/login'; // Redirigir al login si no hay sesión
        } else if (isLoggedIn && isOnLoginPage) {
          return '/dashboard'; // Redirigir al dashboard si hay sesión
        }
        return null; // No redirigir si la ruta es correcta
      },
    );

    // Guardar referencia global
    _router = router;

    return router;
  }
}
