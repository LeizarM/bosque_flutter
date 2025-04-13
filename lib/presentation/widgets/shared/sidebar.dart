import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final isSmallScreen = ResponsiveBreakpoints.of(context).smallerThan(TABLET);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Colores temáticos para el sidebar
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final errorColor = Theme.of(context).colorScheme.error;

    // Lista de opciones del menú (puede ser dinámica según el rol del usuario)
    final menuItems = _buildMenuItems(user?.tipoUsuario ?? '');
    
    
    // Elemento común para crear cada ítem del menú
    Widget buildMenuItem(Map<String, dynamic> item, bool isActive) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Material(
          color: isActive ? primaryColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            leading: Icon(
              item['icon'] as IconData,
              color: isActive ? primaryColor : isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            title: Text(
              item['title'] as String,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? primaryColor : onSurfaceColor,
              ),
            ),
            onTap: () {
              // Navegar a la ruta correspondiente
              context.go(item['route'] as String);
              if (isSmallScreen) {
                Navigator.pop(context); // Cerrar el drawer en móvil
              }
            },
          ),
        ),
      );
    }
    
    // Obtener la ruta actual para resaltar el ítem activo
    final currentRoute = GoRouterState.of(context).uri.toString();

    return isSmallScreen
        ? Drawer(
            elevation: 2,
            backgroundColor: surfaceColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20), 
                bottomRight: Radius.circular(20)
              ),
            ),
            child: Column(
              children: [
                
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      const SizedBox(height: 8),
                      ...menuItems.map(
                        (item) => buildMenuItem(
                          item, 
                          currentRoute == item['route'],
                        ),
                      ),
                      const Divider(height: 32, thickness: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: Icon(
                            Icons.logout,
                            color: errorColor,
                          ),
                          title: Text(
                            'Cerrar Sesión',
                            style: TextStyle(color: errorColor),
                          ),
                          onTap: () {
                            ref.read(userProvider.notifier).clearUser();
                            SecureStorage().deleteToken();
                            context.go('/login');
                            if (isSmallScreen) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Pie de página con info de versión
                Container(
                  padding: const EdgeInsets.all(8),
                  alignment: Alignment.center,
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          )
        : Container(
            width: 280,
            decoration: BoxDecoration(
              color: surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 10,
                  offset: const Offset(0, 0),
                )
              ],
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      ...menuItems.map(
                        (item) => buildMenuItem(
                          item, 
                          currentRoute == item['route'],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                // Botón de cerrar sesión
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    leading: Icon(
                      Icons.logout,
                      color: errorColor,
                    ),
                    title: Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        color: errorColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      ref.read(userProvider.notifier).clearUser();
                      SecureStorage().deleteToken();
                      context.go('/login');
                    },
                  ),
                ),
                // Pie de página con info de versión
                Container(
                  padding: const EdgeInsets.all(8),
                  alignment: Alignment.center,
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  // Método para construir un menú dinámico basado en el tipo de usuario
  List<Map<String, dynamic>> _buildMenuItems(String tipoUsuario) {
    // Menú base para todos los usuarios
    List<Map<String, dynamic>> menuItems = [
      {'title': 'Dashboard', 'icon': Icons.dashboard, 'route': '/dashboard'},
    ];

    // Añadir opciones adicionales según el tipo de usuario
    if (tipoUsuario.toLowerCase().contains('admin')) {
      menuItems.addAll([
        {'title': 'Usuarios', 'icon': Icons.person, 'route': '/users'},
        {'title': 'Configuración', 'icon': Icons.settings, 'route': '/settings'},
      ]);
    } else if (tipoUsuario.toLowerCase().contains('empleado')) {
      menuItems.add(
        {'title': 'Mis Tareas', 'icon': Icons.task, 'route': '/tasks'},
      );
    }

    return menuItems;
  }
}