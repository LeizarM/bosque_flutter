import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/menu_provider.dart';
import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Ancho del sidebar fijo de escritorio; el dashboard lo anima de 0 a esto.
const double anchoSidebar = 268;

/// La duración de una animación, o cero si el sistema pide menos movimiento.
Duration _dur(BuildContext context, int ms) =>
    (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
        ? Duration.zero
        : Duration(milliseconds: ms);

/// La ruta de [item] o la de alguno de sus descendientes es [ruta].
bool _contieneRuta(SidebarMenuItem item, String ruta) =>
    item.route == ruta ||
    (item.children ?? const []).any((c) => _contieneRuta(c, ruta));

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

      // El sidebar se puede desmontar mientras lee el caché (cambio de ancho,
      // sesión que cierra): sin esto, `setState` y `ref` lanzan.
      if (!mounted) return;
      setState(() {
        _expandedItems = savedExpandedState;
        _isInitialized = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final user = ref.read(userProvider);
        if (user != null) {
          menuNotifier.loadUserMenu(user.codUsuario);
        }
      });
    } catch (e) {
      console('Error inicializando menú: $e');
    }
  }

  void _alternar(int id) {
    setState(() {
      _expandedItems[id] = !(_expandedItems[id] ?? false);
    });
    ref.read(menuProvider.notifier).saveExpandedState(_expandedItems);
  }

  /// Pliega todo el árbol de una vez y lo recuerda.
  void _contraerTodo() {
    setState(() => _expandedItems = {});
    ref.read(menuProvider.notifier).saveExpandedState(_expandedItems);
  }

  bool get _hayAbiertos => _expandedItems.values.any((v) => v);

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final menuState = ref.watch(menuProvider);
    final sidebarItems = ref.watch(sidebarMenuProvider);

    final isSmallScreen = ResponsiveBreakpoints.of(context).smallerThan(TABLET);
    final cs = Theme.of(context).colorScheme;
    final currentRoute = GoRouterState.of(context).uri.toString();
    final subtleText = cs.onSurfaceVariant;
    final dividerColor = cs.outlineVariant.withValues(alpha: 0.6);

    void navegar(String ruta) {
      context.go(ruta);
      if (isSmallScreen) Navigator.pop(context);
    }

    // ─── Un ítem y, si tiene, su rama ───
    Widget buildMenuItem(
      SidebarMenuItem item, {
      int nivel = 0,
      bool forzarAbierto = false,
    }) {
      final hasChildren = item.children != null && item.children!.isNotEmpty;
      final abierto = forzarAbierto || (_expandedItems[item.id] ?? false);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ItemMenu(
            item: item,
            nivel: nivel,
            activo: currentRoute == item.route,
            enRama: hasChildren && _contieneRuta(item, currentRoute),
            esRama: hasChildren,
            abierto: abierto,
            onTap: () {
              if (hasChildren) {
                _alternar(item.id);
              } else if (item.route.isNotEmpty) {
                navegar(item.route);
              }
            },
          ),
          if (hasChildren)
            _Desplegable(
              abierto: abierto,
              child: Padding(
                padding: EdgeInsets.only(left: nivel == 0 ? 22 : 14, top: 2),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: cs.primary.withValues(alpha: 0.18),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final child in item.children!)
                          buildMenuItem(
                            child,
                            nivel: nivel + 1,
                            forzarAbierto: forzarAbierto,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // ─── Search bar ───
    Widget buildSearchBar() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(fontSize: 13, color: cs.onSurface),
          decoration: InputDecoration(
            hintText: 'Buscar en el menú',
            hintStyle: TextStyle(fontSize: 13, color: subtleText),
            prefixIcon: Icon(Icons.search_rounded, size: 18, color: subtleText),
            suffixIcon:
                _searchQuery.isNotEmpty
                    ? IconButton(
                      tooltip: 'Limpiar',
                      onPressed:
                          () => setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          }),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: subtleText,
                      ),
                    )
                    : null,
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary, width: 1.2),
            ),
          ),
        ),
      );
    }

    // ─── La etiqueta MÓDULOS con «Contraer todo» ───
    Widget buildEtiquetaModulos() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 4, 4),
        child: Row(
          children: [
            Expanded(
              flex: 2,
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
            // Flexible: con texto grande la etiqueta se corta antes de desbordar.
            Flexible(
              flex: 3,
              child: AnimatedOpacity(
                duration: _dur(context, 180),
                opacity: _hayAbiertos ? 1 : 0.4,
                child: TextButton.icon(
                  key: const ValueKey('sidebar-contraer-todo'),
                  onPressed: _hayAbiertos ? _contraerTodo : null,
                  icon: const Icon(Icons.unfold_less_rounded, size: 16),
                  label: const Text(
                    'Contraer todo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ),
          ],
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
                    color: cs.primary,
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
                  color: cs.error.withValues(alpha: 0.6),
                  size: 28,
                ),
                const SizedBox(height: 12),
                Text(
                  'Error al cargar',
                  style: TextStyle(
                    color: cs.error,
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
                            buildMenuItem(
                              SidebarMenuItem(
                                id: 0,
                                title: 'Dashboard',
                                icon: Icons.space_dashboard_rounded,
                                route: '/dashboard',
                                children: [],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              child: Divider(height: 1, color: dividerColor),
                            ),
                            buildEtiquetaModulos(),
                            // ── TPEX: entradas específicas por rol ─────────
                            if (user?.tipoUsuario == 'ger')
                              buildMenuItem(
                                SidebarMenuItem(
                                  id: 9001,
                                  title: 'Aprobación de Solicitudes',
                                  icon: Icons.approval_rounded,
                                  route: '/dashboard/tpex_Aprobacion/Gerencia',
                                ),
                              ),
                            if (user?.tipoUsuario == 'cob')
                              buildMenuItem(
                                SidebarMenuItem(
                                  id: 9002,
                                  title: 'Cobranzas — Asientos',
                                  icon: Icons.account_balance_wallet_outlined,
                                  route: '/dashboard/tpex_Asientos/Cobranzas',
                                ),
                              ),
                          ],
                          // Al buscar se abre todo lo que coincide, sin tocar
                          // lo que el usuario dejó abierto.
                          for (final item in filteredItems)
                            buildMenuItem(item, forzarAbierto: isSearching),
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

    // ─── Footer: logout + version ───
    Widget buildFooter() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, color: dividerColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await ref.read(menuProvider.notifier).clearCache();
                  await ref.read(userProvider.notifier).clearUser();
                  // El equipo del jefe queda cacheado (miEquipoProvider no es
                  // autoDispose). Si no se tira aquí, quien entre después ve la
                  // pestaña «Su Equipo» con la gente del que se fue.
                  ref.invalidate(miEquipoProvider);
                  context.go('/login');
                  if (isSmallScreen) Navigator.pop(context);
                },
                hoverColor: cs.error.withValues(alpha: 0.06),
                splashColor: cs.error.withValues(alpha: 0.12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: cs.error.withValues(alpha: 0.8),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cerrar Sesión',
                          style: TextStyle(
                            color: cs.error,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user?.versionApp ?? 'v1.0.0',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: subtleText,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      );
    }

    final encabezado = _EncabezadoUsuario(
      nombre: user?.nombreCompleto ?? 'Usuario',
      iniciales: user?.iniciales ?? '',
      cargo: user?.cargo ?? '',
      rol: user?.tipoUsuario ?? '',
      // Sin empleado vinculado no hay ficha que abrir.
      onMiFicha:
          (user?.codEmpleado ?? 0) > 0
              ? () => navegar('/dashboard/${AppConstants.rutaMiFicha}')
              : null,
      miFichaActiva: currentRoute == '/dashboard/${AppConstants.rutaMiFicha}',
    );

    // ─── Layout móvil (Drawer) ───
    if (isSmallScreen) {
      return Drawer(
        elevation: 0,
        backgroundColor: cs.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            SafeArea(bottom: false, child: encabezado),
            Expanded(child: buildSidebarContent()),
            buildFooter(),
          ],
        ),
      );
    }

    // ─── Layout desktop (Sidebar fijo) ───
    return Container(
      width: anchoSidebar,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(right: BorderSide(color: dividerColor, width: 1)),
      ),
      child: Column(
        children: [
          encabezado,
          Expanded(child: buildSidebarContent()),
          buildFooter(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENCABEZADO: QUIÉN ESTÁ Y «MI FICHA»
// ═══════════════════════════════════════════════════════════════════════════

/// El usuario con su avatar de iniciales, cargo y rol, y el acceso a su ficha.
/// Entra con un fundido corto la primera vez que se dibuja.
class _EncabezadoUsuario extends StatelessWidget {
  const _EncabezadoUsuario({
    required this.nombre,
    required this.iniciales,
    required this.cargo,
    required this.rol,
    required this.onMiFicha,
    required this.miFichaActiva,
  });

  final String nombre;

  /// Las del SP (primer nombre + apellido paterno, o materno); vacías en una
  /// sesión del backend anterior, y entonces se toman del nombre.
  final String iniciales;
  final String cargo;
  final String rol;
  final VoidCallback? onMiFicha;
  final bool miFichaActiva;

  static String _iniciales(String nombre) {
    final partes =
        nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    final dos = partes.length > 1 ? partes[0][0] + partes[1][0] : partes[0][0];
    return dos.toUpperCase();
  }

  /// El rol con nombre de persona; los códigos que no se conocen se muestran
  /// tal cual.
  static String _rol(String rol) => switch (rol) {
    'ROLE_ADM' => 'Administrador',
    'ROLE_LIM' => 'Usuario',
    '' => 'Sin rol',
    _ => rol,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final avatar = Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [cs.primary, cs.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CircleAvatar(
        backgroundColor: cs.primaryContainer,
        child: Text(
          iniciales.trim().isNotEmpty
              ? iniciales.trim().toUpperCase()
              : _iniciales(nombre),
          style: t.titleSmall?.copyWith(
            color: cs.onPrimaryContainer,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );

    final contenido = Container(
      margin: const EdgeInsets.fromLTRB(10, 12, 10, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer.withValues(alpha: 0.55),
            cs.tertiaryContainer.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: cs.onSurface,
                      ),
                    ),
                    if (cargo.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        cargo.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    // El rol y «Mi Ficha» en la misma línea, del mismo alto:
                    // el acceso a la ficha se nota sin competir con el nombre.
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surface.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                rol == 'ROLE_ADM'
                                    ? Icons.admin_panel_settings_outlined
                                    : Icons.person_outline,
                                size: 12,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _rol(rol),
                                style: t.labelSmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onMiFicha != null)
                          _EnlaceMiFicha(
                            activa: miFichaActiva,
                            onTap: onMiFicha!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: _dur(context, 420),
      curve: Curves.easeOutCubic,
      builder:
          (context, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, (1 - v) * 8),
              child: child,
            ),
          ),
      child: contenido,
    );
  }
}

/// «Mi Ficha» como enlace chico: contorno fino y color principal; en la ficha
/// propia se rellena apenas para marcar dónde se está.
class _EnlaceMiFicha extends StatelessWidget {
  const _EnlaceMiFicha({required this.activa, required this.onTap});

  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radio = BorderRadius.circular(20);
    return Material(
      key: ValueKey(activa ? 'mi-ficha-activa' : 'mi-ficha'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radio,
        hoverColor: cs.primary.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: _dur(context, 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: radio,
            color: activa ? cs.primary.withValues(alpha: 0.14) : null,
            border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.badge_outlined, size: 12, color: cs.primary),
              const SizedBox(width: 4),
              Text(
                'Mi Ficha',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ÍTEM DEL MENÚ
// ═══════════════════════════════════════════════════════════════════════════

/// Una fila del menú. Al pasar el mouse se aclara el fondo y el texto se corre
/// un poco; la activa lleva el contenedor del color principal y su barra.
class _ItemMenu extends StatefulWidget {
  const _ItemMenu({
    required this.item,
    required this.nivel,
    required this.activo,
    required this.enRama,
    required this.esRama,
    required this.abierto,
    required this.onTap,
  });

  final SidebarMenuItem item;
  final int nivel;
  final bool activo;

  /// Es una rama y adentro está la pantalla abierta.
  final bool enRama;
  final bool esRama;
  final bool abierto;
  final VoidCallback onTap;

  @override
  State<_ItemMenu> createState() => _ItemMenuState();
}

class _ItemMenuState extends State<_ItemMenu> {
  bool _encima = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final raiz = widget.nivel == 0;
    final resaltado = widget.activo || widget.enRama;

    final colorTexto =
        widget.activo
            ? cs.onPrimaryContainer
            : resaltado
            ? cs.primary
            : cs.onSurface.withValues(alpha: 0.88);
    final colorIcono =
        widget.activo
            ? cs.onPrimaryContainer
            : resaltado
            ? cs.primary
            : cs.onSurfaceVariant;

    final fondo =
        widget.activo
            ? cs.primaryContainer
            : _encima
            ? cs.onSurface.withValues(alpha: 0.05)
            : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _encima = true),
        onExit: (_) => setState(() => _encima = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            hoverColor: Colors.transparent,
            splashColor: cs.primary.withValues(alpha: 0.12),
            child: AnimatedContainer(
              duration: _dur(context, 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: raiz ? 10 : 8,
                vertical: raiz ? 10 : 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: fondo,
              ),
              child: AnimatedPadding(
                duration: _dur(context, 160),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  left: _encima && !widget.activo ? 4 : 0,
                ),
                child: Row(
                  children: [
                    // Barra de la activa, solo en el primer nivel. Sin curvas
                    // que se pasen de largo: al bajar a 0 darían alto negativo.
                    if (raiz)
                      AnimatedContainer(
                        duration: _dur(context, 220),
                        curve: Curves.easeOutCubic,
                        width: 3,
                        height: widget.activo ? 18 : 0,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    Icon(
                      widget.item.icon,
                      color: colorIcono,
                      size: raiz ? 19 : 16,
                    ),
                    SizedBox(width: raiz ? 10 : 8),
                    Expanded(
                      child: Text(
                        widget.item.title,
                        style: TextStyle(
                          fontSize: raiz ? 13.2 : 12.5,
                          fontWeight:
                              widget.activo || (widget.enRama && raiz)
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                          color: colorTexto,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (widget.esRama)
                      AnimatedRotation(
                        turns: widget.abierto ? 0.25 : 0,
                        duration: _dur(context, 220),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: raiz ? 18 : 16,
                          color: colorIcono,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RAMA DESPLEGABLE
// ═══════════════════════════════════════════════════════════════════════════

/// Abre y cierra una rama con altura y fundido. Los hijos solo se construyen
/// mientras la rama está abierta o animándose.
class _Desplegable extends StatefulWidget {
  const _Desplegable({required this.abierto, required this.child});

  final bool abierto;
  final Widget child;

  @override
  State<_Desplegable> createState() => _DesplegableState();
}

class _DesplegableState extends State<_Desplegable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: widget.abierto ? 1 : 0,
  );
  late final Animation<double> _curva = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void didUpdateWidget(covariant _Desplegable old) {
    super.didUpdateWidget(old);
    if (old.abierto == widget.abierto) return;
    _c.duration = _dur(context, 240);
    widget.abierto ? _c.forward() : _c.reverse();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        if (_c.value == 0) return const SizedBox.shrink();
        return ClipRect(
          child: SizeTransition(
            sizeFactor: _curva,
            axisAlignment: -1,
            child: FadeTransition(opacity: _curva, child: widget.child),
          ),
        );
      },
    );
  }
}
