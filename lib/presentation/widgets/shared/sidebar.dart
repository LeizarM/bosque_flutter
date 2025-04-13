import 'package:bosque_flutter/core/state/menu_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

class AppSidebar extends ConsumerStatefulWidget {
  const AppSidebar({super.key});

  @override
  _AppSidebarState createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  // Mapa para controlar la expansión de cada elemento con submenús
  final Map<int, bool> _expandedItems = {};

  @override
  void initState() {
    super.initState();
    // Cargar el menú cuando se inicia el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProvider);
      if (user != null) {
        ref.read(menuProvider.notifier).loadUserMenu(user.codUsuario);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final menuState = ref.watch(menuProvider);
    final sidebarItems = ref.watch(sidebarMenuProvider);
    
    final isSmallScreen = ResponsiveBreakpoints.of(context).smallerThan(TABLET);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Colores temáticos para el sidebar
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final errorColor = Theme.of(context).colorScheme.error;
    
    // Obtener la ruta actual para resaltar el ítem activo
    final currentRoute = GoRouterState.of(context).uri.toString();
    
    // Widget para construir un ítem del menú (con o sin submenús)
    Widget buildMenuItem(SidebarMenuItem item, bool isActive, {bool isSubmenu = false}) {
      final hasChildren = item.children != null && item.children!.isNotEmpty;
      final isExpanded = _expandedItems[item.id] ?? false;
      
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: isSubmenu ? 16.0 : 8.0,
              right: 8.0,
              top: 2.0,
              bottom: 2.0,
            ),
            child: Material(
              color: isActive ? primaryColor.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: ListTile(
                dense: isSubmenu,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                leading: Icon(
                  hasChildren ? (isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right) : item.icon,
                  color: isActive ? primaryColor : isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  size: isSubmenu ? 18 : 24,
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: isSubmenu ? 13 : 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? primaryColor : onSurfaceColor,
                  ),
                ),
                onTap: () {
                  if (hasChildren) {
                    // Expandir/contraer el ítem si tiene hijos
                    setState(() {
                      _expandedItems[item.id] = !isExpanded;
                    });
                  } else {
                    // Navegar a la ruta correspondiente
                    if (item.route.isNotEmpty) {
                      context.go(item.route);
                      if (isSmallScreen) {
                        Navigator.pop(context); // Cerrar el drawer en móvil
                      }
                    }
                  }
                },
              ),
            ),
          ),
          // Mostrar los elementos hijos si este ítem está expandido
          if (hasChildren && isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                children: item.children!.map<Widget>((child) {
                  // Verificar si la ruta actual coincide con la ruta del hijo
                  final isChildActive = currentRoute == child.route;
                  return buildMenuItem(child, isChildActive, isSubmenu: true);
                }).toList(),
              ),
            ),
        ],
      );
    }
    
    // Construir el sidebar basado en el estado del menú
    Widget buildSidebarContent() {
      if (menuState.status == MenuStatus.loading) {
        return const Center(child: CircularProgressIndicator());
      } else if (menuState.status == MenuStatus.error) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: errorColor, size: 36),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar el menú',
                  style: TextStyle(color: errorColor, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  menuState.errorMessage ?? 'Intente nuevamente',
                  style: TextStyle(color: errorColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    final user = ref.read(userProvider);
                    if (user != null) {
                      ref.read(menuProvider.notifier).loadUserMenu(user.codUsuario);
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      } else if (menuState.status == MenuStatus.loaded) {
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // Dashboard siempre visible
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Material(
                color: currentRoute == '/dashboard' ? primaryColor.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  leading: Icon(
                    Icons.dashboard,
                    color: currentRoute == '/dashboard' ? primaryColor : isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  title: Text(
                    'Dashboard',
                    style: TextStyle(
                      fontWeight: currentRoute == '/dashboard' ? FontWeight.bold : FontWeight.normal,
                      color: currentRoute == '/dashboard' ? primaryColor : onSurfaceColor,
                    ),
                  ),
                  onTap: () {
                    context.go('/dashboard');
                    if (isSmallScreen) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
            const Divider(height: 16),
            // Items dinámicos del menú
            ...sidebarItems.map((item) {
              final isActive = currentRoute == item.route;
              return buildMenuItem(item, isActive);
            }),
          ],
        );
      } else {
        // Estado inicial, mostrar un mensaje de bienvenida o instrucciones
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Bienvenido al sistema',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    }

    // Botón de cerrar sesión para ambos layouts
    Widget logoutButton = Padding(
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
        onTap: () async {
          // Limpiar caché del menú al cerrar sesión
          await ref.read(menuProvider.notifier).clearCache();
          // Limpiar usuario y token
          ref.read(userProvider.notifier).clearUser();
          await SecureStorage().deleteToken();
          // Navegar al login
          context.go('/login');
          if (isSmallScreen) {
            Navigator.pop(context);
          }
        },
      ),
    );

    // Pie de página con versión
    Widget versionFooter = Container(
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(
        'v1.0.0',
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
        ),
      ),
    );

    // Layout móvil (Drawer)
    if (isSmallScreen) {
      return Drawer(
        elevation: 2,
        backgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20), 
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Encabezado del drawer con información del usuario
            UserAccountsDrawerHeader(
              accountName: Text(user?.nombreCompleto ?? 'Usuario'),
              accountEmail: Text(user?.login ?? 'Sin usuario'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  (user?.nombreCompleto.isNotEmpty ?? false) 
                      ? user!.nombreCompleto.substring(0, 1).toUpperCase()
                      : 'U',
                  style: TextStyle(fontSize: 24, color: primaryColor),
                ),
              ),
              decoration: BoxDecoration(color: primaryColor),
            ),
            // Contenido del menú
            Expanded(
              child: buildSidebarContent(),
            ),
            // Divider + Botón de cerrar sesión + Versión
            Divider(height: 1, color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
            logoutButton,
            versionFooter,
          ],
        ),
      );
    } 
    // Layout desktop (Sidebar)
    else {
      return Container(
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
            // Cabecera del sidebar con logo e información de usuario
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Logo o imagen de la empresa
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'BF',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Nombre y rol del usuario
                  Text(
                    user?.nombreCompleto ?? 'Usuario',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user?.tipoUsuario ?? 'Sin rol',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Contenido del menú
            Expanded(
              child: buildSidebarContent(),
            ),
            // Divider + Botón de cerrar sesión + Versión
            Divider(height: 1, color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
            logoutButton,
            versionFooter,
          ],
        ),
      );
    }
  }
}