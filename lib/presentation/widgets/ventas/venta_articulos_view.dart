import 'package:bosque_flutter/core/state/articulo_almacen_provider.dart';
import 'package:bosque_flutter/core/state/articulo_ciudad_provider.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/articulos_almacen_entity.dart';
import 'package:bosque_flutter/domain/entities/articulos_ciudad_entity.dart';
import 'package:bosque_flutter/presentation/widgets/ventas/database_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class VentasArticulosView extends ConsumerStatefulWidget {
  final int codCiudad;

  const VentasArticulosView({super.key, required this.codCiudad});

  @override
  ConsumerState<VentasArticulosView> createState() =>
      _VentasArticulosViewState();
}

class _VentasArticulosViewState extends ConsumerState<VentasArticulosView> {
  String? _searchQuery;
  String _sortBy = 'datoArt';
  bool _sortAscending = true;
  int? _selectedFamilia;
  List<ArticulosxCiudadEntity> _articulosCache = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(articulosCiudadRefreshProvider.notifier).state++;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final articulosAsyncValue = ref.watch(
      articulosCiudadProvider(widget.codCiudad),
    );

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final isTablet = ResponsiveUtilsBosque.isTablet(context);
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(
      context,
    );
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header con titulo y subtitulo ---
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_rounded,
                  size: isDesktop ? 32 : 26,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catálogo de Artículos',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                          fontSize: isDesktop ? 26 : 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Productos disponibles con precios y stock',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Refresh button
                FilledButton.tonalIcon(
                  onPressed: () {
                    ref.read(articulosCiudadRefreshProvider.notifier).state++;
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label:
                      isDesktop || isTablet
                          ? const Text('Actualizar')
                          : const SizedBox.shrink(),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop || isTablet ? 16 : 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // --- Barra de búsqueda y filtros ---
          _buildSearchAndFilters(context, isDesktop, isTablet, isMobile),

          const SizedBox(height: 12),

          // --- Contenido principal ---
          Expanded(
            child: Builder(
              builder: (context) {
                if (articulosAsyncValue is AsyncLoading &&
                    _articulosCache.isNotEmpty) {
                  return _buildArticulosList(_articulosCache);
                }

                return articulosAsyncValue.when(
                  loading: () {
                    if (_articulosCache.isNotEmpty) {
                      return _buildArticulosList(_articulosCache);
                    }
                    return _buildLoadingState(context);
                  },
                  error: (error, stack) {
                    console('Error cargando artículos: $error');
                    if (_articulosCache.isNotEmpty) {
                      return Column(
                        children: [
                          _buildErrorBanner(context, error),
                          Expanded(child: _buildArticulosList(_articulosCache)),
                        ],
                      );
                    }
                    return _buildErrorState(context, error);
                  },
                  data: (articulos) {
                    if (articulos.isEmpty) {
                      if (_articulosCache.isNotEmpty) {
                        return _buildArticulosList(_articulosCache);
                      }
                      return _buildEmptyState(context);
                    }
                    if (articulos.isNotEmpty && mounted) {
                      _articulosCache = List.from(articulos);
                    }
                    return _buildArticulosList(articulos);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Search & Filter Bar ---
  Widget _buildSearchAndFilters(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Buscar artículo por código o descripción...',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colorScheme.primary,
              ),
              suffixIcon:
                  _searchQuery != null && _searchQuery!.isNotEmpty
                      ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = null);
                        },
                      )
                      : null,
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
            ),
            style: TextStyle(color: colorScheme.onSurface),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.isEmpty ? null : value.toLowerCase();
              });
            },
          ),

          const SizedBox(height: 12),

          // Sort controls row
          Row(
            children: [
              // Sort dropdown
              Expanded(
                flex: isDesktop ? 2 : 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      isExpanded: true,
                      icon: Icon(
                        Icons.unfold_more_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'datoArt',
                          child: Text('Ordenar: Descripción'),
                        ),
                        DropdownMenuItem(
                          value: 'codArticulo',
                          child: Text('Ordenar: Código'),
                        ),
                        DropdownMenuItem(
                          value: 'precio',
                          child: Text('Ordenar: Precio'),
                        ),
                        DropdownMenuItem(
                          value: 'disponible',
                          child: Text('Ordenar: Disponibilidad'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _sortBy = value);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Sort direction button
              Material(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _sortAscending = !_sortAscending),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _sortAscending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        if (isDesktop || isTablet) ...[
                          const SizedBox(width: 6),
                          Text(
                            _sortAscending ? 'ASC' : 'DESC',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Loading state ---
  Widget _buildLoadingState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Cargando artículos...',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // --- Error banner (when cache available) ---
  Widget _buildErrorBanner(BuildContext context, Object error) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sin conexión — mostrando datos guardados',
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(articulosCiudadRefreshProvider.notifier).state++;
            },
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onErrorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // --- Error state (no cache) ---
  Widget _buildErrorState(BuildContext context, Object error) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: colorScheme.error,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Error al cargar artículos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                setState(() {});
                ref.read(articulosCiudadRefreshProvider.notifier).state++;
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Empty state ---
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: colorScheme.onSurfaceVariant,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No se encontraron artículos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otros criterios de búsqueda',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // --- Articles list ---
  Widget _buildArticulosList(List<ArticulosxCiudadEntity> articulos) {
    List<ArticulosxCiudadEntity> filteredArticulos = articulos;

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filteredArticulos =
          filteredArticulos
              .where(
                (a) =>
                    a.datoArt.toLowerCase().contains(_searchQuery!) ||
                    a.codArticulo.toLowerCase().contains(_searchQuery!),
              )
              .toList();
    }

    if (_selectedFamilia != null) {
      filteredArticulos =
          filteredArticulos
              .where((a) => a.codigoFamilia == _selectedFamilia)
              .toList();
    }

    if (filteredArticulos.isEmpty) {
      return _buildEmptyState(context);
    }

    // Agrupar por codArticulo
    Map<String, List<ArticulosxCiudadEntity>> articulosAgrupados = {};
    for (var articulo in filteredArticulos) {
      articulosAgrupados.putIfAbsent(articulo.codArticulo, () => []);
      articulosAgrupados[articulo.codArticulo]!.add(articulo);
    }

    List<String> codigosOrdenados = articulosAgrupados.keys.toList();

    codigosOrdenados.sort((a, b) {
      if (_sortBy == 'datoArt') {
        final aDesc = articulosAgrupados[a]!.first.datoArt;
        final bDesc = articulosAgrupados[b]!.first.datoArt;
        return _sortAscending ? aDesc.compareTo(bDesc) : bDesc.compareTo(aDesc);
      } else if (_sortBy == 'codArticulo') {
        return _sortAscending ? a.compareTo(b) : b.compareTo(a);
      } else if (_sortBy == 'precio') {
        final aPrecioMin = articulosAgrupados[a]!
            .map((e) => e.precio)
            .reduce((v, e) => v < e ? v : e);
        final bPrecioMin = articulosAgrupados[b]!
            .map((e) => e.precio)
            .reduce((v, e) => v < e ? v : e);
        return _sortAscending
            ? aPrecioMin.compareTo(bPrecioMin)
            : bPrecioMin.compareTo(aPrecioMin);
      } else if (_sortBy == 'disponible') {
        final aDisp = articulosAgrupados[a]!.fold<int>(
          0,
          (s, i) => s + i.disponible,
        );
        final bDisp = articulosAgrupados[b]!.fold<int>(
          0,
          (s, i) => s + i.disponible,
        );
        return _sortAscending ? aDisp.compareTo(bDisp) : bDisp.compareTo(aDisp);
      }
      return 0;
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info row
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${codigosOrdenados.length} artículos',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${filteredArticulos.length} variantes',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              isDesktop
                  ? _buildDesktopGrid(codigosOrdenados, articulosAgrupados)
                  : _buildMobileTabletList(
                    codigosOrdenados,
                    articulosAgrupados,
                  ),
        ),
      ],
    );
  }

  // --- Desktop Grid ---
  Widget _buildDesktopGrid(
    List<String> codigosOrdenados,
    Map<String, List<ArticulosxCiudadEntity>> articulosAgrupados,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 4;
    if (screenWidth > 1800) {
      crossAxisCount = 5;
    } else if (screenWidth < 1200) {
      crossAxisCount = 3;
    } else if (screenWidth < 900) {
      crossAxisCount = 2;
    }
    const spacing = 10.0;

    // Build cards list
    final cards =
        codigosOrdenados.map((codigo) {
          final variantes = articulosAgrupados[codigo]!;
          final variantesPorDbYLista = _agruparVariantes(variantes);
          return _buildArticuloCard(variantes.first, variantesPorDbYLista);
        }).toList();

    // Split into rows of crossAxisCount
    final List<List<Widget>> rows = [];
    for (int i = 0; i < cards.length; i += crossAxisCount) {
      rows.add(cards.sublist(i, (i + crossAxisCount).clamp(0, cards.length)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4),
      itemCount: rows.length,
      itemBuilder: (context, rowIndex) {
        final row = rows[rowIndex];
        return Padding(
          padding: EdgeInsets.only(
            bottom: rowIndex < rows.length - 1 ? spacing : 0,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < crossAxisCount; i++) ...[
                  if (i > 0) SizedBox(width: spacing),
                  Expanded(
                    child: i < row.length ? row[i] : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Mobile/Tablet List ---
  Widget _buildMobileTabletList(
    List<String> codigosOrdenados,
    Map<String, List<ArticulosxCiudadEntity>> articulosAgrupados,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4),
      itemCount: codigosOrdenados.length,
      itemBuilder: (context, index) {
        final codigo = codigosOrdenados[index];
        final variantes = articulosAgrupados[codigo]!;
        final variantesPorDbYLista = _agruparVariantes(variantes);
        return _buildArticuloMobileItem(variantes.first, variantesPorDbYLista);
      },
    );
  }

  // --- Helper: Agrupar variantes por DB y ListaPrecio ---
  Map<String?, Map<int?, ArticulosxCiudadEntity>> _agruparVariantes(
    List<ArticulosxCiudadEntity> variantes,
  ) {
    Map<String?, Map<int?, ArticulosxCiudadEntity>> result = {};
    for (var v in variantes) {
      result.putIfAbsent(v.db, () => {});
      result[v.db]![v.listaPrecio] = v;
    }
    return result;
  }

  // --- Helper: Format price with thousand separators ---
  static final _priceFormatter = NumberFormat('#,##0.00', 'en_US');

  String _formatPrice(double precio, String? moneda) {
    return '${moneda ?? 'BS'} ${_priceFormatter.format(precio)}';
  }

  String _formatNumber(int number) {
    return NumberFormat('#,##0', 'en_US').format(number);
  }

  // --- Helper: Get availability color ---
  Color _getDisponibilidadColor(BuildContext context, int disponible) {
    final colorScheme = Theme.of(context).colorScheme;
    if (disponible > 100) return colorScheme.primary;
    if (disponible > 20) return Colors.amber.shade700;
    return colorScheme.error;
  }

  // --- Helper: Get min price ---
  ({double precio, String? moneda}) _getMinPrice(
    Map<String?, Map<int?, ArticulosxCiudadEntity>> variantesPorDbYLista,
  ) {
    double minPrecio = double.infinity;
    String? moneda;
    variantesPorDbYLista.forEach((_, variantes) {
      variantes.forEach((_, articulo) {
        if (articulo.precio < minPrecio) {
          minPrecio = articulo.precio;
          moneda = articulo.moneda;
        }
      });
    });
    return (precio: minPrecio, moneda: moneda);
  }

  // ============================================================
  //  DESKTOP CARD
  // ============================================================
  Widget _buildArticuloCard(
    ArticulosxCiudadEntity articuloPrincipal,
    Map<String?, Map<int?, ArticulosxCiudadEntity>> variantesPorDbYLista,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final disponibilidad = articuloPrincipal.disponible;
    final dispColor = _getDisponibilidadColor(context, disponibilidad);
    final minPrice = _getMinPrice(variantesPorDbYLista);
    final precioFormateado =
        minPrice.precio != double.infinity
            ? _formatPrice(minPrice.precio, minPrice.moneda)
            : 'Consultar';

    int totalVariantes = 0;
    variantesPorDbYLista.forEach((_, v) => totalVariantes += v.length);

    // Collect price rows for preview (top 3 cheapest)
    final previewPrices =
        <
          ({
            String db,
            int lista,
            String condicion,
            double precio,
            String? moneda,
          })
        >[];
    variantesPorDbYLista.forEach((db, variantes) {
      variantes.forEach((lista, art) {
        previewPrices.add((
          db: db ?? '',
          lista: lista ?? 0,
          condicion: art.condicionPrecio,
          precio: art.precio,
          moneda: art.moneda,
        ));
      });
    });
    previewPrices.sort((a, b) => a.precio.compareTo(b.precio));
    final topPrices = previewPrices.take(3).toList();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surface,
      child: InkWell(
        onTap:
            () => _mostrarVariantesPrecio(
              context,
              articuloPrincipal,
              variantesPorDbYLista,
            ),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Compact header ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: dispColor.withValues(alpha: 0.12),
                border: Border(
                  bottom: BorderSide(color: dispColor.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  // Article code
                  Text(
                    articuloPrincipal.codArticulo,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // DB chips
                  ...variantesPorDbYLista.keys.map(
                    (db) => Container(
                      margin: const EdgeInsets.only(right: 3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.7,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        db ?? '',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Stock badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: dispColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_rounded,
                          size: 11,
                          color: dispColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatNumber(disponibilidad),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: dispColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- Description row ---
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Tooltip(
                      message: articuloPrincipal.datoArt,
                      child: Text(
                        articuloPrincipal.datoArt.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                          color: colorScheme.onSurface,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: articuloPrincipal.datoArt),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Descripción copiada'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 13,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- UTM + Gramaje inline ---
            if (articuloPrincipal.utm > 0 || articuloPrincipal.gramaje > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 3, 10, 0),
                child: Row(
                  children: [
                    if (articuloPrincipal.utm > 0) ...[
                      Icon(
                        Icons.straighten_rounded,
                        size: 11,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'UTM: ${articuloPrincipal.utm}',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      if (articuloPrincipal.gramaje > 0)
                        const SizedBox(width: 8),
                    ],
                    if (articuloPrincipal.gramaje > 0) ...[
                      Icon(
                        Icons.scale_rounded,
                        size: 11,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${articuloPrincipal.gramaje}g',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // --- Price preview rows ---
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Column(
                children: [
                  ...topPrices.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text(
                              'L${p.lista}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              p.condicion,
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatPrice(p.precio, p.moneda),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (previewPrices.length > 3)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '+${previewPrices.length - 3} más...',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // --- Bottom bar: price + badge ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Desde',
                    style: TextStyle(
                      fontSize: 9,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    precioFormateado,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer.withValues(
                        alpha: 0.7,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$totalVariantes precios',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onTertiaryContainer,
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

  // ============================================================
  //  MOBILE / TABLET ITEM
  // ============================================================
  Widget _buildArticuloMobileItem(
    ArticulosxCiudadEntity articuloPrincipal,
    Map<String?, Map<int?, ArticulosxCiudadEntity>> variantesPorDbYLista,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final disponibilidad = articuloPrincipal.disponible;
    final dispColor = _getDisponibilidadColor(context, disponibilidad);
    final minPrice = _getMinPrice(variantesPorDbYLista);
    final precioFormateado =
        minPrice.precio != double.infinity
            ? _formatPrice(minPrice.precio, minPrice.moneda)
            : 'Consultar';

    int totalVariantes = 0;
    variantesPorDbYLista.forEach((_, v) => totalVariantes += v.length);
    List<String?> basesDatos = variantesPorDbYLista.keys.toList();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surface,
      child: InkWell(
        onTap:
            () => _mostrarVariantesPrecio(
              context,
              articuloPrincipal,
              variantesPorDbYLista,
            ),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: code + availability badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  // Código artículo
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      articuloPrincipal.codArticulo,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // DB chips
                  ...basesDatos.map(
                    (db) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withValues(
                            alpha: 0.7,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          db ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Disponibilidad
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: dispColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: dispColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 13,
                          color: dispColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatNumber(disponibilidad),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: dispColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: description + details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                articuloPrincipal.datoArt.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: colorScheme.onSurface,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: articuloPrincipal.datoArt,
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Descripción copiada'),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Icon(
                                  Icons.copy_rounded,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (articuloPrincipal.utm > 0) ...[
                              Icon(
                                Icons.straighten_rounded,
                                size: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'UTM: ${articuloPrincipal.utm}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Icon(
                              Icons.price_change_outlined,
                              size: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '$totalVariantes precios',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Right: Price + arrow
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Desde',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        precioFormateado,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  BOTTOM SHEET - Detalle de precios y disponibilidad
  // ============================================================
  void _mostrarVariantesPrecio(
    BuildContext context,
    ArticulosxCiudadEntity articuloPrincipal,
    Map<String?, Map<int?, ArticulosxCiudadEntity>> variantesPorDbYLista,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.inventory_2_rounded,
                            color: colorScheme.onPrimaryContainer,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                articuloPrincipal.codArticulo,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: colorScheme.primary,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      articuloPrincipal.datoArt.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text: articuloPrincipal.datoArt,
                                        ),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Descripción copiada',
                                          ),
                                          duration: const Duration(seconds: 1),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: Icon(
                                        Icons.copy_rounded,
                                        size: 15,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Info chips
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        _infoChip(
                          context,
                          Icons.inventory_rounded,
                          'Disponible: ${_formatNumber(articuloPrincipal.disponible)} ${articuloPrincipal.unidadMedida ?? ''}',
                          _getDisponibilidadColor(
                            context,
                            articuloPrincipal.disponible,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (articuloPrincipal.utm > 0)
                          _infoChip(
                            context,
                            Icons.straighten_rounded,
                            'UTM: ${articuloPrincipal.utm}',
                            colorScheme.tertiary,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tabs
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TabBar(
                              indicator: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelColor: colorScheme.onPrimary,
                              unselectedLabelColor:
                                  colorScheme.onSurfaceVariant,
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              dividerColor: Colors.transparent,
                              tabs: const [
                                Tab(text: 'Precios', height: 40),
                                Tab(text: 'Disponibilidad', height: 40),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildPreciosTab(
                                  context,
                                  variantesPorDbYLista,
                                  scrollController,
                                ),
                                _buildDisponibilidadTab(
                                  context,
                                  articuloPrincipal,
                                  scrollController,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --- Precios Tab ---
  Widget _buildPreciosTab(
    BuildContext context,
    Map<String?, Map<int?, ArticulosxCiudadEntity>> variantesPorDbYLista,
    ScrollController scrollController,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        ...variantesPorDbYLista.entries.map((dbEntry) {
          final db = dbEntry.key ?? '';
          final variantes = dbEntry.value;
          final listasPrecio =
              variantes.keys.toList()
                ..sort((a, b) => (a ?? 0).compareTo(b ?? 0));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // DB header
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.dns_rounded,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      db,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Price rows
              ...listasPrecio.map((listaPrecio) {
                final articulo = variantes[listaPrecio]!;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Lista info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lista ${articulo.listaPrecio}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              articulo.condicionPrecio,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Price
                      Text(
                        _formatPrice(articulo.precio, articulo.moneda),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              if (dbEntry.key != variantesPorDbYLista.entries.last.key)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Divider(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
            ],
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  // --- Disponibilidad Tab ---
  Widget _buildDisponibilidadTab(
    BuildContext context,
    ArticulosxCiudadEntity articulo,
    ScrollController scrollController,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer(
      builder: (context, ref, child) {
        final articleStockAsyncValue = ref.watch(
          articuloAlmacenProvider((articulo.codArticulo, widget.codCiudad)),
        );

        return articleStockAsyncValue.when(
          data: (articles) {
            if (articles.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sin stock disponible',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            int totalGeneral = articulo.disponible;

            return Column(
              children: [
                // Total banner
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'TOTAL DISPONIBLE: ${_formatNumber(totalGeneral)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Stock details
                Expanded(
                  child: _buildStockContent(
                    context,
                    articles,
                    scrollController,
                  ),
                ),
              ],
            );
          },
          loading:
              () => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cargando stock...',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
          error:
              (error, stackTrace) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: colorScheme.error,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error: ${error.toString()}',
                      style: TextStyle(color: colorScheme.error, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
        );
      },
    );
  }

  // --- Stock Content (uses DatabaseSection / CitySection / WarehouseItem) ---
  Widget _buildStockContent(
    BuildContext context,
    List<ArticulosxAlmacenEntity> articles,
    ScrollController scrollController,
  ) {
    final articlesByDb = <String, List<ArticulosxAlmacenEntity>>{};
    for (final article in articles) {
      articlesByDb.putIfAbsent(article.db, () => []);
      articlesByDb[article.db]!.add(article);
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        ...articlesByDb.entries.map((dbEntry) {
          final dbArticles = dbEntry.value;
          final articlesByCity = <String, List<ArticulosxAlmacenEntity>>{};
          for (final article in dbArticles) {
            articlesByCity.putIfAbsent(article.ciudad, () => []);
            articlesByCity[article.ciudad]!.add(article);
          }
          return DatabaseSection(
            dbName: dbEntry.key,
            articlesByCity: articlesByCity,
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
