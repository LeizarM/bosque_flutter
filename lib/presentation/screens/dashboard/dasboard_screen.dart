import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/sidebar_state_provider.dart';
import 'package:bosque_flutter/core/state/theme_mode_provider.dart';

import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/presentation/widgets/shared/auth_gate.dart';
import 'package:bosque_flutter/presentation/widgets/shared/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

class DashboardScreen extends ConsumerWidget {
  /// El contenido hijo que se mostrará en el área principal
  final Widget child;

  const DashboardScreen({required this.child, super.key});

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
    final isOnRegister =
        currentRoute == '/dashboard/ted_EmpleadoDependiente/register';

    return AuthGate(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0.5,
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SvgPicture.asset(
                  'assets/icon/bosque_logo.svg',
                  fit: BoxFit.contain,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Bosque',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.3,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          leading:
              !isSmallScreen
                  ? IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        sidebarVisible
                            ? Icons.menu_open_rounded
                            : Icons.menu_rounded,
                        key: ValueKey(sidebarVisible),
                      ),
                    ),
                    tooltip: sidebarVisible ? 'Ocultar menú' : 'Mostrar menú',
                    onPressed: () {
                      ref
                          .read(sidebarVisibilityProvider.notifier)
                          .toggleSidebar();
                    },
                  )
                  : null,
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  themeMode.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  size: 20,
                ),
                tooltip: themeMode.isDarkMode ? 'Modo claro' : 'Modo oscuro',
                onPressed: () {
                  final currentRoute = GoRouterState.of(context).uri.toString();
                  ref.read(themeNotifierProvider.notifier).toggleDarkMode();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final newRoute = GoRouterState.of(context).uri.toString();
                    if (newRoute != currentRoute &&
                        currentRoute.startsWith('/dashboard')) {
                      context.go(currentRoute);
                    }
                  });
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 2, right: 12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.error,
                ),
                tooltip: 'Cerrar sesión',
                onPressed: () async {
                  await ref.read(userProvider.notifier).clearUser();
                  context.go('/login');
                },
              ),
            ),
          ],
        ),
        drawer: isSmallScreen ? const AppSidebar() : null,
        body:
            isBlocked && !isOnRegister
                ? Center(
                  child: Card(
                    margin: const EdgeInsets.all(32),
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '¡Debes actualizar tus datos personales!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Actualizar ahora'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            onPressed: () {
                              context.go(
                                '/dashboard/ted_EmpleadoDependiente/register',
                              );
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
