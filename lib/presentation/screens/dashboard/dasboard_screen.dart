import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/sidebar_state_provider.dart';
import 'package:bosque_flutter/core/state/theme_mode_provider.dart';

import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/presentation/widgets/shared/auth_gate.dart';
import 'package:bosque_flutter/presentation/widgets/shared/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

class DashboardScreen extends ConsumerWidget {
  /// El contenido hijo que se mostrará en el área principal
  final Widget child;
  
  const DashboardScreen({
    required this.child,
    super.key,
  });

  @override  
  Widget build(BuildContext context, WidgetRef ref) {  
    final isSmallScreen = ResponsiveBreakpoints.of(context).smallerThan(TABLET); 
    final sidebarVisible = ref.watch(sidebarVisibilityProvider);
    final themeMode = ref.watch(themeNotifierProvider);

    // ADVERTENCIA: lógica de bloqueo
    final warningCount = ref.watch(warningCounterProvider);
    final warningLimit = ref.watch(warningLimitProvider);
    final currentRoute = GoRouterState.of(context).uri.toString();
    final isBlocked = warningCount >= warningLimit;
    final isOnRegister = currentRoute == '/dashboard/ted_EmpleadoDependiente/register';

    return AuthGate(
      child: Scaffold(  
        appBar: AppBar(  
          title: const Text('Dashboard'),
          leading: !isSmallScreen ? IconButton(
            icon: Icon(sidebarVisible ? Icons.menu_open : Icons.menu),
            tooltip: sidebarVisible ? 'Ocultar menú' : 'Mostrar menú',
            onPressed: () {
              ref.read(sidebarVisibilityProvider.notifier).toggleSidebar();
            },
          ) : null,  
          actions: [
            IconButton(
              icon: Icon(themeMode.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              tooltip: themeMode.isDarkMode ? 'Modo claro' : 'Modo oscuro',
              onPressed: () {
                final currentRoute = GoRouterState.of(context).uri.toString();
                ref.read(themeNotifierProvider.notifier).toggleDarkMode();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final newRoute = GoRouterState.of(context).uri.toString();
                  if (newRoute != currentRoute && currentRoute.startsWith('/dashboard')) {
                    context.go(currentRoute);
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () async {
                await ref.read(userProvider.notifier).clearUser();  
                context.go('/login');
              },
            ),
          ],
        ),
        drawer: isSmallScreen ? const AppSidebar() : null,  
        body: isBlocked && !isOnRegister
            ? Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          '¡Debes actualizar tus datos personales!',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Actualizar ahora'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          onPressed: () {
                            context.go('/dashboard/ted_EmpleadoDependiente/register');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Row(  
                children: [  
                  if (!isSmallScreen && sidebarVisible) const AppSidebar(),  
                  Expanded(child: child),
                ],  
              ),
      ),
    );
  }
}
