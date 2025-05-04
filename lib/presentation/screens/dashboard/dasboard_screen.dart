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
            // Botón para cambiar el tema
            IconButton(
              icon: Icon(themeMode.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              tooltip: themeMode.isDarkMode ? 'Modo claro' : 'Modo oscuro',
              onPressed: () {
                // Guardar la ruta actual antes de cambiar el tema
                final currentRoute = GoRouterState.of(context).uri.toString();
                
                // Cambiar el tema
                ref.read(themeNotifierProvider.notifier).toggleDarkMode();
                
                // Si la ruta actual ya no es la misma después de cambiar el tema,
                // restaurar la ruta anterior (esto evita redirecciones no deseadas)
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
        body: Row(  
          children: [  
            // El sidebar siempre visible en pantallas grandes si sidebarVisible es true
            if (!isSmallScreen && sidebarVisible) const AppSidebar(),  
            
            // Área principal que contendrá el contenido hijo proporcionado por el router
            Expanded(
              child: child, // Usar directamente el widget hijo proporcionado por ShellRoute
            ),
          ],  
        ),  
      ),
    );
  }
}
