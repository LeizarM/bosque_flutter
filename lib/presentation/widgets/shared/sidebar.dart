import 'package:bosque_flutter/core/state/menu_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
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
  Map<int, bool> _expandedItems = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Cargar el menú y el estado de expansión al iniciar
    _initializeMenu();
  }

  Future<void> _initializeMenu() async {
    // Carga inmediata desde caché incluso antes del primer frame
    try {
      final menuNotifier = ref.read(menuProvider.notifier);
      // Primero cargar el estado de expansión
      final savedExpandedState = await menuNotifier.loadExpandedState();
      
      // IMPORTANTE: Cargar menú desde caché inmediatamente
      await menuNotifier.loadMenuFromCacheOnly();
      
      setState(() {
        _expandedItems = savedExpandedState;
        _isInitialized = true;
      });
      
      // Después actualizar desde el servidor
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final user = ref.read(userProvider);
        if (user != null) {
          menuNotifier.loadUserMenu(user.codUsuario);
        }
      });
    } catch (e) {
      debugPrint('Error inicializando menú: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final menuState = ref.watch(menuProvider);
    final sidebarItems = ref.watch(sidebarMenuProvider);
    
    final isSmallScreen = ResponsiveBreakpoints.of(context).smallerThan(TABLET);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Colores temáticos para el sidebar
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = theme.colorScheme.surface;
    final onSurfaceColor = theme.colorScheme.onSurface;
    final errorColor = theme.colorScheme.error;
    
    // Obtener la ruta actual para resaltar el ítem activo
    final currentRoute = GoRouterState.of(context).uri.toString();
    
    // Widget para construir un ítem del menú (con o sin submenús)
    Widget buildMenuItem(SidebarMenuItem item, bool isActive, {bool isSubmenu = false}) {
      final hasChildren = item.children != null && item.children!.isNotEmpty;
      final isExpanded = _expandedItems[item.id] ?? false;
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(
          left: isSubmenu ? 4.0 : 0.0,
          bottom: 2.0,
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Material(
                color: isActive 
                    ? primaryColor.withOpacity(0.15) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () {
                    if (hasChildren) {
                      // Expandir/contraer el ítem si tiene hijos
                      setState(() {
                        _expandedItems[item.id] = !isExpanded;
                        // Guardar el estado de expansión
                        ref.read(menuProvider.notifier).saveExpandedState(_expandedItems);
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
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSubmenu ? 12.0 : 16.0,
                      vertical: isSubmenu ? 8.0 : 12.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasChildren 
                              ? (isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right) 
                              : item.icon,
                          color: isActive 
                              ? primaryColor 
                              : isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                          size: isSubmenu ? 18 : 22,
                        ),
                        SizedBox(width: isSubmenu ? 8 : 12),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: isSubmenu ? 13 : 14,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                              color: isActive ? primaryColor : onSurfaceColor,
                              letterSpacing: isActive ? 0.2 : 0,
                            ),
                          ),
                        ),
                        if (isActive && !isSubmenu && !hasChildren)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Mostrar los elementos hijos si este ítem está expandido
            if (hasChildren && isExpanded)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(left: 16.0, top: 4.0),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: item.children!.map<Widget>((child) {
                    // Verificar si la ruta actual coincide con la ruta del hijo
                    final isChildActive = currentRoute == child.route;
                    return buildMenuItem(child, isChildActive, isSubmenu: true);
                  }).toList(),
                ),
              ),
          ],
        ),
      );
    }
    
    // Construir el sidebar basado en el estado del menú
    Widget buildSidebarContent() {
      if (menuState.status == MenuStatus.loading && !_isInitialized) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cargando menú...',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      } else if (menuState.status == MenuStatus.error) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: errorColor,
                  size: 32
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar el menú',
                  style: TextStyle(
                    color: errorColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  menuState.errorMessage ?? 'Intente nuevamente',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    if (user != null) {
                      ref.read(menuProvider.notifier).loadUserMenu(user.codUsuario);
                    }
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (menuState.status == MenuStatus.loaded || sidebarItems.isNotEmpty) {
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          children: [
            // Dashboard siempre visible
            buildMenuItem(
              SidebarMenuItem(
                id: 0,
                title: 'Dashboard',
                icon: Icons.dashboard_outlined,
                route: '/dashboard',
                children: [],
              ),
              currentRoute == '/dashboard',
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Divider(height: 1),
            ),
            
            // Label para la sección principal
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'PRINCIPAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
            
            // Items dinámicos del menú
            ...sidebarItems.map((item) {
              final isActive = currentRoute == item.route;
              return buildMenuItem(item, isActive);
            }),
          ],
        );
      } else {
        // Estado inicial, mostrar un mensaje de bienvenida o instrucciones
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_open,
                  size: 48,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
                const SizedBox(height: 16),
                Text(
                  'Bienvenido al sistema',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: onSurfaceColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
    }

    // Botón de cerrar sesión para ambos layouts
    Widget logoutButton = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: errorColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            // Limpiar caché del menú al cerrar sesión
            await ref.read(menuProvider.notifier).clearCache();
            // Limpiar usuario y token
            await ref.read(userProvider.notifier).clearUser();
            // Navegar al login
            context.go('/login');
            if (isSmallScreen) {
              Navigator.pop(context);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: errorColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    color: errorColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Pie de página con versión
    Widget versionFooter = Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Text(
        '${user?.versionApp ?? 'v1.0.0'}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
          letterSpacing: 0.5,
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
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    primaryColor.withBlue(primaryColor.blue + 15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Text(
                            (user?.nombreCompleto?.isNotEmpty ?? false) 
                                ? user!.nombreCompleto!.substring(0, 1).toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.nombreCompleto ?? 'Usuario',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  user?.tipoUsuario ?? 'Sin usuario',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: Colors.white.withOpacity(0.8),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Buscar opciones...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Contenido del menú
            Expanded(
              child: buildSidebarContent(),
            ),
            
            // Divider + Botón de cerrar sesión + Versión
            Divider(height: 1, color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 0),
            )
          ],
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            // Cabecera del sidebar con logo e información de usuario
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? theme.colorScheme.primary.withOpacity(0.12)
                    : theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  // Logo o imagen de la empresa
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withBlue(primaryColor.blue + 30),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'BF',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Nombre y rol del usuario
                  Text(
                    user?.nombreCompleto ?? 'Usuario',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: onSurfaceColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? primaryColor.withOpacity(0.15)
                          : primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.tipoUsuario ?? 'Sin rol',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Barra de búsqueda
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey.shade800.withOpacity(0.5)
                          : Colors.grey.shade200.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Buscar opciones...',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
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
            Divider(height: 1, color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
            logoutButton,
            versionFooter,
          ],
        ),
      );
    }
  }
}