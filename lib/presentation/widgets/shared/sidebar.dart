import 'package:bosque_flutter/core/state/menu_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

class AppSidebar extends ConsumerStatefulWidget {
  const AppSidebar({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AppSidebarState createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  Map<int, bool> _expandedItems = {};
  bool _isInitialized = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeMenu();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SidebarMenuItem> _filterMenuItems(
    List<SidebarMenuItem> items,
    String query,
  ) {
    final List<SidebarMenuItem> results = [];
    for (final item in items) {
      final matchesTitle = item.title.toLowerCase().contains(
        query.toLowerCase(),
      );
      final filteredChildren =
          item.children != null
              ? _filterMenuItems(item.children!, query)
              : <SidebarMenuItem>[];

      if (matchesTitle || filteredChildren.isNotEmpty) {
        if (filteredChildren.isNotEmpty) {
          results.add(
            SidebarMenuItem(
              id: item.id,
              title: item.title,
              icon: item.icon,
              route: item.route,
              children: filteredChildren,
            ),
          );
        } else {
          results.add(item);
        }
      }
    }
    return results;
  }

  Future<void> _initializeMenu() async {
    try {
      final menuNotifier = ref.read(menuProvider.notifier);
      final savedExpandedState = await menuNotifier.loadExpandedState();
      await menuNotifier.loadMenuFromCacheOnly();

      setState(() {
        _expandedItems = savedExpandedState;
        _isInitialized = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final user = ref.read(userProvider);
        if (user != null) {
          menuNotifier.loadUserMenu(user.codUsuario);
        }
      });
    } catch (e) {
      console('Error inicializando menú: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final menuState = ref.watch(menuProvider);
    final sidebarItems = ref.watch(sidebarMenuProvider);

    final isSmallScreen = ResponsiveBreakpoints.of(context).smallerThan(TABLET);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final primary = cs.primary;
    final surface = cs.surface;
    final onSurface = cs.onSurface;
    final error = cs.error;
    final currentRoute = GoRouterState.of(context).uri.toString();

    // ─── Colores del sidebar ───
    final sidebarBg =
        isDark
            ? Color.lerp(surface, Colors.black, 0.15)!
            : Color.lerp(surface, Colors.grey.shade50, 0.5)!;
    final headerBg =
        isDark
            ? primary.withValues(alpha: 0.08)
            : primary.withValues(alpha: 0.04);
    final subtleText = isDark ? Colors.grey.shade500 : Colors.grey.shade500;
    final dividerColor =
        isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06);

    // ─── Build menu item ───
    Widget buildMenuItem(
      SidebarMenuItem item,
      bool isActive, {
      bool isSubmenu = false,
    }) {
      final hasChildren = item.children != null && item.children!.isNotEmpty;
      final isExpanded = _expandedItems[item.id] ?? false;

      return Padding(
        padding: EdgeInsets.only(left: isSubmenu ? 8.0 : 0, bottom: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (hasChildren) {
                    setState(() {
                      _expandedItems[item.id] = !isExpanded;
                      ref
                          .read(menuProvider.notifier)
                          .saveExpandedState(_expandedItems);
                    });
                  } else if (item.route.isNotEmpty) {
                    context.go(item.route);
                    if (isSmallScreen) Navigator.pop(context);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                hoverColor: primary.withValues(alpha: 0.06),
                splashColor: primary.withValues(alpha: 0.1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSubmenu ? 10 : 14,
                    vertical: isSubmenu ? 9 : 11,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color:
                        isActive
                            ? primary.withValues(alpha: isDark ? 0.14 : 0.08)
                            : null,
                  ),
                  child: Row(
                    children: [
                      // Indicador activo (barra lateral)
                      if (!isSubmenu)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 3,
                          height: isActive ? 20 : 0,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isActive ? primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      // Ícono
                      Icon(
                        hasChildren
                            ? (isExpanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_right_rounded)
                            : item.icon,
                        color:
                            isActive
                                ? primary
                                : isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                        size: isSubmenu ? 17 : 20,
                      ),
                      SizedBox(width: isSubmenu ? 8 : 10),
                      // Título
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: isSubmenu ? 12.5 : 13.5,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                            color:
                                isActive
                                    ? primary
                                    : onSurface.withValues(alpha: 0.85),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Hijos expandidos
            if (hasChildren && isExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 18, top: 2),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: primary.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Column(
                    children:
                        item.children!.map<Widget>((child) {
                          return buildMenuItem(
                            child,
                            currentRoute == child.route,
                            isSubmenu: true,
                          );
                        }).toList(),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // ─── Search bar ───
    Widget buildSearchBar() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(fontSize: 13, color: onSurface),
          decoration: InputDecoration(
            hintText: 'Buscar...',
            hintStyle: TextStyle(fontSize: 13, color: subtleText),
            prefixIcon: Icon(Icons.search_rounded, size: 18, color: subtleText),
            suffixIcon:
                _searchQuery.isNotEmpty
                    ? GestureDetector(
                      onTap:
                          () => setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          }),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: subtleText,
                      ),
                    )
                    : null,
            filled: true,
            fillColor:
                isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: primary.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
          ),
        ),
      );
    }

    // ─── Menu content ───
    Widget buildSidebarContent() {
      if (menuState.status == MenuStatus.loading && !_isInitialized) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Cargando...',
                  style: TextStyle(fontSize: 13, color: subtleText),
                ),
              ],
            ),
          ),
        );
      } else if (menuState.status == MenuStatus.error) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  color: error.withValues(alpha: 0.6),
                  size: 28,
                ),
                const SizedBox(height: 12),
                Text(
                  'Error al cargar',
                  style: TextStyle(
                    color: error,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  menuState.errorMessage ?? 'Intente nuevamente',
                  style: TextStyle(color: subtleText, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: () {
                    if (user != null) {
                      ref
                          .read(menuProvider.notifier)
                          .loadUserMenu(user.codUsuario);
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text(
                    'Reintentar',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (menuState.status == MenuStatus.loaded ||
          sidebarItems.isNotEmpty) {
        final isSearching = _searchQuery.isNotEmpty;
        final filteredItems =
            isSearching
                ? _filterMenuItems(sidebarItems, _searchQuery)
                : sidebarItems;

        return Column(
          children: [
            buildSearchBar(),
            Expanded(
              child:
                  filteredItems.isEmpty && isSearching
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 32,
                                color: subtleText,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sin resultados',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subtleText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      : ListView(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 10,
                        ),
                        children: [
                          if (!isSearching) ...[
                            // Dashboard
                            buildMenuItem(
                              SidebarMenuItem(
                                id: 0,
                                title: 'Dashboard',
                                icon: Icons.space_dashboard_rounded,
                                route: '/dashboard',
                                children: [],
                              ),
                              currentRoute == '/dashboard',
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              child: Divider(height: 1, color: dividerColor),
                            ),
                            // Sección principal label
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                              child: Text(
                                'MÓDULOS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: subtleText,
                                ),
                              ),
                            ),
                          ],
                          ...filteredItems.map((item) {
                            final isActive = currentRoute == item.route;
                            if (isSearching &&
                                item.children != null &&
                                item.children!.isNotEmpty) {
                              _expandedItems[item.id] = true;
                            }
                            return buildMenuItem(item, isActive);
                          }),
                        ],
                      ),
            ),
          ],
        );
      } else {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_rounded, size: 36, color: subtleText),
              const SizedBox(height: 10),
              Text(
                'Sin menú disponible',
                style: TextStyle(fontSize: 13, color: subtleText),
              ),
            ],
          ),
        );
      }
    }

    // ─── Header con logo + user ───
    Widget buildHeader() {
      return Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
        decoration: BoxDecoration(color: headerBg),
        child: Column(
          children: [
            // Logo
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primary.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: SvgPicture.asset(
                  'assets/icon/bosque_logo.svg',
                  fit: BoxFit.contain,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Nombre
            Text(
              user?.nombreCompleto ?? 'Usuario',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: onSurface,
                height: 1.3,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            const SizedBox(height: 6),
            // Rol badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user?.tipoUsuario ?? 'Sin rol',
                style: TextStyle(
                  color: primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ─── Mobile header ───
    Widget buildMobileHeader() {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary, primary.withValues(alpha: 0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(topRight: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SvgPicture.asset(
                    'assets/icon/bosque_logo.svg',
                    fit: BoxFit.contain,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nombreCompleto ?? 'Usuario',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        user?.tipoUsuario ?? 'Sin usuario',
                        style: const TextStyle(
                          fontSize: 11,
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
        ),
      );
    }

    // ─── Footer: logout + version ───
    Widget buildFooter() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, color: dividerColor),
          // Logout
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  await ref.read(menuProvider.notifier).clearCache();
                  await ref.read(userProvider.notifier).clearUser();
                  context.go('/login');
                  if (isSmallScreen) Navigator.pop(context);
                },
                hoverColor: error.withValues(alpha: 0.06),
                splashColor: error.withValues(alpha: 0.12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: error.withValues(alpha: 0.7),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          color: error.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Versión
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 2),
            child: Text(
              user?.versionApp ?? 'v1.0.0',
              style: TextStyle(
                fontSize: 11,
                color: subtleText,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      );
    }

    // ─── Layout móvil (Drawer) ───
    if (isSmallScreen) {
      return Drawer(
        elevation: 0,
        backgroundColor: sidebarBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            buildMobileHeader(),
            Expanded(child: buildSidebarContent()),
            buildFooter(),
          ],
        ),
      );
    }

    // ─── Layout desktop (Sidebar fijo) ───
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: dividerColor, width: 1)),
      ),
      child: Column(
        children: [
          buildHeader(),
          Expanded(child: buildSidebarContent()),
          buildFooter(),
        ],
      ),
    );
  }
}
