import 'package:bosque_flutter/core/state/articulo_almacen_provider.dart';
import 'package:bosque_flutter/domain/entities/articulos_almacen_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:bosque_flutter/core/state/articulo_ciudad_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/domain/entities/articulos_ciudad_entity.dart';

class VentasHomeScreen extends ConsumerStatefulWidget {
  const VentasHomeScreen({super.key});

  @override
  ConsumerState<VentasHomeScreen> createState() => _VentasHomeScreenState();
}

class _VentasHomeScreenState extends ConsumerState<VentasHomeScreen> {
  int _codCiudad = 0; // Inicializamos con un valor por defecto

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _codCiudad = ref.read(userProvider.notifier).getCodCiudad();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No usamos appBar aquí porque ya lo tiene el DashboardScreen como contenedor
      body: ResponsiveBreakpoints(
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado del módulo de ventas
            Padding(
              padding: EdgeInsets.all(
                ResponsiveValue<double>(
                  context,
                  defaultValue: 16.0,
                  conditionalValues: [
                    Condition.smallerThan(name: TABLET, value: 12.0),
                    Condition.largerThan(name: DESKTOP, value: 24.0),
                  ],
                ).value,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lista de Artículos',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize:
                          ResponsiveValue<double>(
                            context,
                            defaultValue: 24.0,
                            conditionalValues: [
                              Condition.smallerThan(name: TABLET, value: 20.0),
                              Condition.largerThan(name: DESKTOP, value: 28.0),
                            ],
                          ).value,
                    ),
                  ),
                  SizedBox(
                    height:
                        ResponsiveValue<double>(
                          context,
                          defaultValue: 8.0,
                          conditionalValues: [
                            Condition.largerThan(name: DESKTOP, value: 12.0),
                          ],
                        ).value,
                  ),
                  Text(
                    'Catálogo de productos disponibles',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                      fontSize:
                          ResponsiveValue<double>(
                            context,
                            defaultValue: 14.0,
                            conditionalValues: [
                              Condition.largerThan(name: DESKTOP, value: 16.0),
                            ],
                          ).value,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido principal: Lista de artículos
            Expanded(child: VentasArticulosView(codCiudad: _codCiudad)),
          ],
        ),
      ),
    );
  }
}

class VentasArticulosView extends ConsumerStatefulWidget {
  final int codCiudad;

  const VentasArticulosView({super.key, required this.codCiudad});

  @override
  ConsumerState<VentasArticulosView> createState() =>
      _VentasArticulosViewState();
}

class _VentasArticulosViewState extends ConsumerState<VentasArticulosView> {
  String? _searchQuery;
  String _sortBy = 'datoArt'; // Ordenar por descripción inicialmente
  bool _sortAscending = true;
  int? _selectedFamilia;
  // Estado de carga explícito
  List<ArticulosxCiudadEntity> _articulosCache =
      []; // Cache local para datos de ejemplo

  @override
  void initState() {
    super.initState();

    // Forzar una recarga inmediata al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Incrementar el contador para forzar una actualización
      ref.read(articulosCiudadRefreshProvider.notifier).state++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Intentar obtener datos reales, pero usar el cache si falla
    final articulosAsyncValue = ref.watch(
      articulosCiudadProvider(widget.codCiudad),
    );

    // Calcular dimensiones de pantalla y determinar tipo de dispositivo
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Detección específica para pantalla grande (1586x1716)
    final isLargeDisplay = screenWidth > 1500 && screenHeight > 1200;
    final isIpadPro =
        (screenWidth >= 1000 && screenWidth <= 1366) &&
        (screenHeight >= 900 && screenHeight <= 1366);

    // Ajuste específico para diferentes dispositivos
    final isDesktop =
        ResponsiveBreakpoints.of(context).largerOrEqualTo(DESKTOP) ||
        isLargeDisplay;
    final isTablet =
        ResponsiveBreakpoints.of(context).between(TABLET, DESKTOP) ||
        (screenWidth > 750 && screenWidth < 1200);
    final isMobile = !isDesktop && !isTablet;

    // Padding optimizado según tipo de dispositivo
    final horizontalPadding =
        isLargeDisplay
            ? 24.0
            : (isIpadPro
                ? 16.0
                : (isDesktop ? 32.0 : (isTablet ? 20.0 : 16.0)));
    final verticalPadding =
        isLargeDisplay
            ? 16.0
            : (isIpadPro ? 8.0 : (isDesktop ? 24.0 : (isTablet ? 16.0 : 12.0)));

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila de búsqueda y filtros
          ResponsiveRowColumn(
            layout:
                isDesktop || isTablet
                    ? ResponsiveRowColumnType.ROW
                    : ResponsiveRowColumnType.COLUMN,
            rowCrossAxisAlignment: CrossAxisAlignment.center,
            rowSpacing: 16,
            columnSpacing: 12,
            children: [
              // Barra de búsqueda
              ResponsiveRowColumnItem(
                rowFlex: 3,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por código o descripción...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        ref
                            .read(articulosCiudadRefreshProvider.notifier)
                            .state++;
                      },
                      tooltip: 'Actualizar',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),

              if (isDesktop || isTablet)
                // Filtro de ordenamiento
                ResponsiveRowColumnItem(
                  rowFlex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Ordenar por',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          value: _sortBy,
                          items: const [
                            DropdownMenuItem(
                              value: 'datoArt',
                              child: Text('Descripción'),
                            ),
                            DropdownMenuItem(
                              value: 'codArticulo',
                              child: Text('Código'),
                            ),
                            DropdownMenuItem(
                              value: 'precio',
                              child: Text('Precio'),
                            ),
                            DropdownMenuItem(
                              value: 'disponible',
                              child: Text('Disponibilidad'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sortBy = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          _sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _sortAscending = !_sortAscending;
                          });
                        },
                        tooltip: _sortAscending ? 'Ascendente' : 'Descendente',
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Filtros adicionales para móvil
          if (isMobile)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Ordenar por',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: _sortBy,
                      items: const [
                        DropdownMenuItem(
                          value: 'datoArt',
                          child: Text('Descripción'),
                        ),
                        DropdownMenuItem(
                          value: 'codArticulo',
                          child: Text('Código'),
                        ),
                        DropdownMenuItem(
                          value: 'precio',
                          child: Text('Precio'),
                        ),
                        DropdownMenuItem(
                          value: 'disponible',
                          child: Text('Disponibilidad'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _sortBy = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _sortAscending = !_sortAscending;
                      });
                    },
                    tooltip: _sortAscending ? 'Ascendente' : 'Descendente',
                  ),
                ],
              ),
            ),

          SizedBox(
            height:
                ResponsiveValue<double>(
                  context,
                  defaultValue: 16.0,
                  conditionalValues: [
                    Condition.smallerThan(name: TABLET, value: 12.0),
                    Condition.largerThan(name: DESKTOP, value: 20.0),
                  ],
                ).value,
          ),

          // Mostrar datos según el estado del provider
          Expanded(
            child: Builder(
              builder: (context) {
                // Si tenemos datos de ejemplo y estamos cargando los reales, mostrar los de ejemplo
                if (articulosAsyncValue is AsyncLoading &&
                    _articulosCache.isNotEmpty) {
                  return _buildArticulosList(_articulosCache);
                }

                return articulosAsyncValue.when(
                  // Mientras carga los datos
                  loading: () {
                    if (_articulosCache.isNotEmpty) {
                      // Si ya tenemos datos en caché, mostrarlos durante la carga
                      return _buildArticulosList(_articulosCache);
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                  // Si ocurre un error
                  error: (error, stack) {
                    debugPrint('Error cargando artículos: $error');

                    if (_articulosCache.isNotEmpty) {
                      // Si hay error pero tenemos datos en caché, mostrar los datos de caché
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Error de conexión: mostrando datos guardados',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ref
                                        .read(
                                          articulosCiudadRefreshProvider
                                              .notifier,
                                        )
                                        .state++;
                                  },
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          ),
                          Expanded(child: _buildArticulosList(_articulosCache)),
                        ],
                      );
                    }

                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar artículos',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Forzar recarga y actualizar datos locales
                              setState(() {});

                              ref
                                  .read(articulosCiudadRefreshProvider.notifier)
                                  .state++;
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  },
                  // Cuando los datos están disponibles
                  data: (articulos) {
                    if (articulos.isEmpty) {
                      // Si los datos están vacíos pero tenemos datos en caché, usamos la caché
                      if (_articulosCache.isNotEmpty) {
                        return _buildArticulosList(_articulosCache);
                      }

                      // No hay datos reales ni caché
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron artículos',
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Intenta con otros criterios de búsqueda',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Actualizar nuestra caché con los datos reales
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

  Widget _buildArticulosList(List<ArticulosxCiudadEntity> articulos) {
    // Filtrar artículos según la búsqueda y otros filtros
    List<ArticulosxCiudadEntity> filteredArticulos = articulos;

    // Filtrar por búsqueda
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filteredArticulos =
          filteredArticulos
              .where(
                (articulo) =>
                    (articulo.datoArt.toLowerCase().contains(_searchQuery!)) ||
                    (articulo.codArticulo.toLowerCase().contains(
                      _searchQuery!,
                    )),
              )
              .toList();
    }

    // Filtrar por familia (si hay alguna seleccionada)
    if (_selectedFamilia != null) {
      filteredArticulos =
          filteredArticulos
              .where((articulo) => articulo.codigoFamilia == _selectedFamilia)
              .toList();
    }

    // Si no hay resultados después de filtrar
    if (filteredArticulos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron artículos',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otros criterios de búsqueda',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    // Agrupar artículos por codArticulo
    Map<String, List<ArticulosxCiudadEntity>> articulosAgrupados = {};

    for (var articulo in filteredArticulos) {
      if (!articulosAgrupados.containsKey(articulo.codArticulo)) {
        articulosAgrupados[articulo.codArticulo] = [];
      }
      articulosAgrupados[articulo.codArticulo]!.add(articulo);
    }

    // Lista de códigos de artículos (llaves) ordenados según criterio
    List<String> codigosOrdenados = articulosAgrupados.keys.toList();

    // Ordenamos la lista de códigos según criterio de ordenamiento
    codigosOrdenados.sort((a, b) {
      if (_sortBy == 'datoArt') {
        // Ordenar por descripción usando el primer artículo de cada grupo
        final aDesc = articulosAgrupados[a]!.first.datoArt;
        final bDesc = articulosAgrupados[b]!.first.datoArt;
        return _sortAscending ? aDesc.compareTo(bDesc) : bDesc.compareTo(aDesc);
      } else if (_sortBy == 'codArticulo') {
        return _sortAscending ? a.compareTo(b) : b.compareTo(a);
      } else if (_sortBy == 'precio') {
        // Para precio, usamos el precio mínimo de cada grupo
        final aPrecioMin = articulosAgrupados[a]!
            .map((e) => e.precio)
            .reduce((value, element) => value < element ? value : element);
        final bPrecioMin = articulosAgrupados[b]!
            .map((e) => e.precio)
            .reduce((value, element) => value < element ? value : element);
        return _sortAscending
            ? aPrecioMin.compareTo(bPrecioMin)
            : bPrecioMin.compareTo(aPrecioMin);
      } else if (_sortBy == 'disponible') {
        // Para disponibilidad, sumamos el total disponible de cada grupo
        final aDisponible = articulosAgrupados[a]!.fold<int>(
          0,
          (sum, item) => sum + (item.disponible),
        );
        final bDisponible = articulosAgrupados[b]!.fold<int>(
          0,
          (sum, item) => sum + (item.disponible),
        );
        return _sortAscending
            ? aDisponible.compareTo(bDisponible)
            : bDisponible.compareTo(aDisponible);
      }
      return 0;
    });

    // Contador de artículos
    final infoRow = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'Mostrando ${codigosOrdenados.length} artículos con ${filteredArticulos.length} variantes',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    // Determinar tipo de dispositivo para el layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop =
        ResponsiveBreakpoints.of(context).largerOrEqualTo(DESKTOP) ||
        screenWidth > 1200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contador de artículos
        infoRow,

        // Lista de artículos agrupados - diferente diseño según dispositivo
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

  // Vista en grid para escritorio
  Widget _buildDesktopGrid(
    List<String> codigosOrdenados,
    Map<String, List<ArticulosxCiudadEntity>> articulosAgrupados,
  ) {
    // Obtenemos el ancho de la pantalla para determinar el número de columnas
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Definimos el número de columnas basado en el ancho de la pantalla
    int crossAxisCount = 3; // Por defecto 3 columnas para escritorio
    double childAspectRatio = 1.8; // Proporción reducida para aumentar el alto de las tarjetas
    
    // Ajustes para pantallas muy grandes o pequeñas
    if (screenWidth > 1800) {
      crossAxisCount = 4; // 4 columnas para pantallas muy anchas
      childAspectRatio = 2.0;
    } else if (screenWidth < 1200) {
      crossAxisCount = 2; // 2 columnas para escritorio más pequeño
      childAspectRatio = 1.6;
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount, // Número de columnas según ancho
        childAspectRatio: childAspectRatio, // Proporción reducida para hacer las tarjetas más altas
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: codigosOrdenados.length,
      itemBuilder: (context, index) {
        final codigoArticulo = codigosOrdenados[index];
        final variantes = articulosAgrupados[codigoArticulo]!;

        // Para cada variante, organizamos por base de datos y lista de precio
        Map<String?, Map<int?, ArticulosxCiudadEntity>> variantesPorDbYLista = {};

        for (var variante in variantes) {
          if (!variantesPorDbYLista.containsKey(variante.db)) {
            variantesPorDbYLista[variante.db] = {};
          }
          variantesPorDbYLista[variante.db]![variante.listaPrecio] = variante;
        }

        return _buildArticuloCard(variantes.first, variantesPorDbYLista, true);
      },
    );
  }

  // Vista en lista para móvil/tablet
  Widget _buildMobileTabletList(
    List<String> codigosOrdenados,
    Map<String, List<ArticulosxCiudadEntity>> articulosAgrupados,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: codigosOrdenados.length,
      itemBuilder: (context, index) {
        final codigoArticulo = codigosOrdenados[index];
        final variantes = articulosAgrupados[codigoArticulo]!;

        // Para cada variante, organizamos por base de datos y lista de precio
        Map<String?, Map<int?, ArticulosxCiudadEntity>> variantesPorDbYLista =
            {};

        for (var variante in variantes) {
          if (!variantesPorDbYLista.containsKey(variante.db)) {
            variantesPorDbYLista[variante.db] = {};
          }
          variantesPorDbYLista[variante.db]![variante.listaPrecio] = variante;
        }

        return _buildArticuloMobileItem(variantes.first, variantesPorDbYLista);
      },
    );
  }

  // Vista de tarjeta para dispositivos desktop - muestra precios agrupados en una tarjeta
  Widget _buildArticuloCard(
    ArticulosxCiudadEntity articuloPrincipal,
    Map<String?, Map<int?, ArticulosxCiudadEntity>> variantesPorDbYLista,
    bool isDesktop,
  ) {
    // No es necesario calcular la disponibilidad total, ya viene del backend
    int disponibilidadTotal = articuloPrincipal.disponible;

    // Color para la barra de disponibilidad
    Color disponibilidadColor;
    if (disponibilidadTotal > 100) {
      disponibilidadColor = Theme.of(context).colorScheme.primary;
    } else if (disponibilidadTotal > 20) {
      disponibilidadColor = Theme.of(context).colorScheme.tertiary;
    } else {
      disponibilidadColor = Theme.of(context).colorScheme.error;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de la tarjeta
          Container(
            color: disponibilidadColor,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Código del artículo
                Expanded(
                  child: Text(
                    articuloPrincipal.codArticulo,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Disponibilidad
                Text(
                  'Disp: $disponibilidadTotal ${articuloPrincipal.unidadMedida ?? ''}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal de la tarjeta
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Descripción del artículo
                  Text(
                    articuloPrincipal.datoArt.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Tabla de precios
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ...variantesPorDbYLista.entries.map((dbEntry) {
                            final db = dbEntry.key ?? '';
                            final variantes = dbEntry.value;

                            // Ordenar todas las listas de precio para mostrarlas
                            final listasPrecio =
                                variantes.keys.toList()..sort();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Base de datos
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    'Base de Datos: $db',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                    ),
                                  ),
                                ),

                                // Precios por lista - mostrar TODAS sin limitación
                                ...listasPrecio.map((listaPrecio) {
                                  final articulo = variantes[listaPrecio]!;
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8,
                                      bottom: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        
                                        // Lista de precios
                                        // Código de la variante
                                        Text(
                                          'Lista ${articulo.listaPrecio}: ',
                                          style: const TextStyle(
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        
                                        // Condición
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            articulo.condicionPrecio,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                        // Precio
                                        Text(
                                          '${articulo.moneda ?? 'BS'} ${articulo.precio.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),

                                // Separador entre bases de datos
                                if (db != variantesPorDbYLista.keys.last)
                                  const Divider(height: 16),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer con botones de acción
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed:
                      () => _mostrarVariantesPrecio(
                        context,
                        articuloPrincipal,
                        variantesPorDbYLista,
                      ),
                  icon: const Icon(Icons.inventory_2, size: 18),
                  label: const Text(
                    'Ver Detalles',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Vista de lista para móviles y tablets
  Widget _buildArticuloMobileItem(
    ArticulosxCiudadEntity articuloPrincipal,
    Map<String?, Map<int?, ArticulosxCiudadEntity>> variantesPorDbYLista,
  ) {
    // No es necesario calcular la disponibilidad total, ya viene del backend
    int disponibilidadTotal = articuloPrincipal.disponible;
    
    // Obtener el precio mínimo para mostrar destacado
    double precioMinimo = double.infinity;
    String? monedaPrecioMinimo;

    // Encontrar precio mínimo entre todas las variantes
    variantesPorDbYLista.forEach((db, variantes) {
      variantes.forEach((listaPrecio, articulo) {
        if ((articulo.precio) < precioMinimo) {
          precioMinimo = articulo.precio;
          monedaPrecioMinimo = articulo.moneda;
        }
      });
    });

    // Color para la disponibilidad
    Color disponibilidadColor;
    if (disponibilidadTotal > 100) {
      disponibilidadColor = Theme.of(context).colorScheme.primary;
    } else if (disponibilidadTotal > 20) {
      disponibilidadColor = Theme.of(context).colorScheme.tertiary;
    } else {
      disponibilidadColor = Theme.of(context).colorScheme.error;
    }

    // Preparar texto de precio formateado
    final precioFormateado =
        precioMinimo != double.infinity
            ? '${monedaPrecioMinimo ?? 'BS'} ${precioMinimo.toStringAsFixed(2)}'
            : 'Consultar';

    // Contar cuántas variantes hay en total
    int totalVariantes = 0;
    variantesPorDbYLista.forEach((db, variantes) {
      totalVariantes += variantes.length;
    });

    // Crear un mapa de las bases de datos disponibles para este artículo
    List<String?> basesDatos = variantesPorDbYLista.keys.toList();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con código y disponibilidad
          Container(
            color: disponibilidadColor,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Artículo: ${articuloPrincipal.codArticulo}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Disponible: $disponibilidadTotal ${articuloPrincipal.unidadMedida ?? ''}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Descripción del producto
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Descripción y precio mínimo
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            articuloPrincipal.datoArt.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Bases de datos disponibles
                          const SizedBox(height: 4),
                          if (basesDatos.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              children:
                                  basesDatos.map((db) {
                                    return Chip(
                                      label: Text(
                                        '$db',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        ),
                                      ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      labelPadding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    );
                                  }).toList(),
                            ),
                        ],
                      ),
                    ),

                    // Precio mínimo y botón de compra
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Desde:',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          precioFormateado,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Contador de variantes
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$totalVariantes ${totalVariantes == 1 ? 'variante' : 'variantes'} de precio',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),

                    // Botones de acción
                    Row(
                      children: [
                        // Botón expandir para ver variantes
                        IconButton(
                          onPressed: () {
                            _mostrarVariantesPrecio(
                              context,
                              articuloPrincipal,
                              variantesPorDbYLista,
                            );
                          },
                          icon: const Icon(Icons.expand_more, size: 20),
                          tooltip: 'Ver variantes de precio',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método para mostrar las variantes de precio en un bottom sheet (para móvil/tablet)
  // Incluye también la disponibilidad por almacén
  void _mostrarVariantesPrecio(
    BuildContext context,
    ArticulosxCiudadEntity articuloPrincipal,
    Map<String?, Map<int?, ArticulosxCiudadEntity>> variantesPorDbYLista,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Precios y Disponibilidad',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  // Información del artículo
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Código
                        Text(
                          'Código: ${articuloPrincipal.codArticulo}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),

                        // Descripción
                        Text(
                          articuloPrincipal.datoArt.toUpperCase(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  const Divider(),

                  // Secciones de Tabs para precios y disponibilidad
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          // Tabs de navegación
                          TabBar(
                            tabs: const [
                              Tab(
                                icon: Icon(Icons.price_change),
                                text: 'Precios',
                              ),
                              Tab(
                                icon: Icon(Icons.inventory_2),
                                text: 'Disponibilidad',
                              ),
                            ],
                            indicatorColor: Theme.of(context).colorScheme.primary,
                            labelColor: Theme.of(context).colorScheme.primary,
                          ),
                          
                          // Contenido de los tabs
                          Expanded(
                            child: TabBarView(
                              children: [
                                // TAB 1: PRECIOS
                                _buildPreciosTab(context, variantesPorDbYLista, scrollController),
                                
                                // TAB 2: DISPONIBILIDAD
                                _buildDisponibilidadTab(context, articuloPrincipal, scrollController),
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

  // Widget para construir el tab de precios
  Widget _buildPreciosTab(
    BuildContext context,
    Map<String?, Map<int?, ArticulosxCiudadEntity>> variantesPorDbYLista,
    ScrollController scrollController,
  ) {
    return ListView(
      controller: scrollController,
      children: [
        ...variantesPorDbYLista.entries.map((dbEntry) {
          final db = dbEntry.key ?? '';
          final variantes = dbEntry.value;
          final listasPrecio =
              variantes.keys.toList()..sort((a, b) => (a ?? 0).compareTo(b ?? 0));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado de la base de datos
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'BASE DE DATOS: $db',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),

              // Tabla de precios por lista
              ...listasPrecio.map((listaPrecio) {
                final articulo = variantes[listaPrecio]!;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Lista de precio
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lista de Precio: ${articulo.listaPrecio}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            
                          ],
                        ),

                        // Condición de precio
                        if (articulo.condicionPrecio != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                            child: Text(
                              'Condición: ${articulo.condicionPrecio}',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),

                        // Precio
                        Text(
                          '${articulo.moneda ?? "BS"} ${articulo.precio.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              // Separador entre bases de datos
              if (dbEntry.key != variantesPorDbYLista.entries.last.key)
                const Divider(height: 24),
            ],
          );
        }).toList(),
      ],
    );
  }

  // Widget para construir el tab de disponibilidad
  Widget _buildDisponibilidadTab(
    BuildContext context,
    ArticulosxCiudadEntity articulo,
    ScrollController scrollController,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final articleStockAsyncValue = ref.watch(
          articuloAlmacenProvider((
            articulo.codArticulo,
            widget.codCiudad,
          )),
        );
        
        return articleStockAsyncValue.when(
          data: (articles) {
            if (articles.isEmpty) {
              return Center(
                child: Text(
                  'No hay stock disponible para este artículo',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              );
            }
            
            // No necesitamos calcular la disponibilidad total, ya viene del backend
            // Usamos directamente el valor de disponibilidad del artículo principal
            int totalGeneral = articulo.disponible;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mostrar total general
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16, top: 8),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'DISPONIBILIDAD TOTAL: $totalGeneral',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                
                // Lista de inventario por base de datos y ciudad
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
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Center(
            child: Text(
              'Error al cargar datos: ${error.toString()}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        );
      },
    );
  }

  // Método para construir el contenido del stock usando componentes
  Widget _buildStockContent(
    BuildContext context,
    List<ArticulosxAlmacenEntity> articles,
    ScrollController scrollController,
  ) {
    // First, group the articles by database (db)
    final articlesByDb = <String, List<ArticulosxAlmacenEntity>>{};
    for (final article in articles) {
      final db = article.db ?? 'Sin Base';
      if (!articlesByDb.containsKey(db)) {
        articlesByDb[db] = [];
      }
      articlesByDb[db]!.add(article);
    }

    return ListView(
      controller: scrollController,
      children: [
        // Build sections for each database
        ...articlesByDb.entries.map((dbEntry) {
          final dbName = dbEntry.key;
          final dbArticles = dbEntry.value;

          // Group by city within this database
          final articlesByCity = <String, List<ArticulosxAlmacenEntity>>{};
          for (final article in dbArticles) {
            final city = article.ciudad ?? 'Sin Ciudad';
            if (!articlesByCity.containsKey(city)) {
              articlesByCity[city] = [];
            }
            articlesByCity[city]!.add(article);
          }

          return DatabaseSection(
            dbName: dbName,
            articlesByCity: articlesByCity,
          );
        }).toList(),
      ],
    );
  }
}

// Widget para mostrar una sección de base de datos con sus ciudades
class DatabaseSection extends StatelessWidget {
  final String dbName;
  final Map<String, List<ArticulosxAlmacenEntity>> articlesByCity;

  const DatabaseSection({
    Key? key,
    required this.dbName,
    required this.articlesByCity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calcular total por base de datos
    int totalDisponibleDb = 0;
    articlesByCity.forEach((_, articles) {
      for (var article in articles) {
        totalDisponibleDb += article.disponible;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado de base de datos
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BASE DE DATOS: $dbName',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              Text(
                'Total: $totalDisponibleDb',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),

        // Secciones de ciudades
        ...articlesByCity.entries.map((cityEntry) {
          return CitySection(
            cityName: cityEntry.key,
            articles: cityEntry.value,
          );
        }).toList(),

        const SizedBox(height: 20),
      ],
    );
  }
}

// Widget para mostrar una sección de ciudad con sus almacenes
class CitySection extends StatelessWidget {
  final String cityName;
  final List<ArticulosxAlmacenEntity> articles;

  const CitySection({
    Key? key,
    required this.cityName,
    required this.articles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calcular total por ciudad
    int totalDisponibleCity = 0;
    for (var article in articles) {
      totalDisponibleCity += article.disponible;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de ciudad
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_city, size: 16),
                const SizedBox(width: 6),
                Text(
                  cityName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Total: $totalDisponibleCity',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),

          // Lista de almacenes
          ...articles.map((article) {
            return WarehouseItem(article: article);
          }).toList(),
        ],
      ),
    );
  }
}

// Widget para mostrar un ítem de almacén
class WarehouseItem extends StatelessWidget {
  final ArticulosxAlmacenEntity article;

  const WarehouseItem({
    Key? key,
    required this.article,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8, left: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            // Icono de almacén
            Icon(
              Icons.warehouse,
              size: 20,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(width: 12),
            
            // Información del almacén
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.whsName ?? 'Almacén',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Código: ${article.whsCode}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // Disponibilidad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Disponible: ${article.disponible}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
