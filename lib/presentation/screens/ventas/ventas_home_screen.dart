import 'package:bosque_flutter/presentation/screens/ventas/disponibilidad_detallada_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    _codCiudad =  ref.read(userProvider.notifier).getCodCiudad();
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
              padding: EdgeInsets.all(ResponsiveValue<double>(
                context,
                defaultValue: 16.0,
                conditionalValues: [
                  Condition.smallerThan(name: TABLET, value: 12.0),
                  Condition.largerThan(name: DESKTOP, value: 24.0),
                ],
              ).value),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lista de Artículos',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveValue<double>(
                        context,
                        defaultValue: 24.0,
                        conditionalValues: [
                          Condition.smallerThan(name: TABLET, value: 20.0),
                          Condition.largerThan(name: DESKTOP, value: 28.0),
                        ],
                      ).value,
                    ),
                  ),
                  SizedBox(height: ResponsiveValue<double>(
                    context,
                    defaultValue: 8.0,
                    conditionalValues: [
                      Condition.largerThan(name: DESKTOP, value: 12.0),
                    ],
                  ).value),
                  Text(
                    'Catálogo de productos disponibles',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                      fontSize: ResponsiveValue<double>(
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
            Expanded(
              child: VentasArticulosView(codCiudad: _codCiudad),
            ),
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
  ConsumerState<VentasArticulosView> createState() => _VentasArticulosViewState();
}

class _VentasArticulosViewState extends ConsumerState<VentasArticulosView> {
  String? _searchQuery;
  String _sortBy = 'datoArt'; // Ordenar por descripción inicialmente
  bool _sortAscending = true;
  int? _selectedFamilia;
// Estado de carga explícito
  List<ArticulosxCiudadEntity> _articulosCache = []; // Cache local para datos de ejemplo
  
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
    final articulosAsyncValue = ref.watch(articulosCiudadProvider(widget.codCiudad));
    
    // Calcular dimensiones de pantalla y determinar tipo de dispositivo
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Detección específica para pantalla grande (1586x1716)
    final isLargeDisplay = screenWidth > 1500 && screenHeight > 1200;
    final isIpadPro = (screenWidth >= 1000 && screenWidth <= 1366) && 
                     (screenHeight >= 900 && screenHeight <= 1366);
    
    // Ajuste específico para diferentes dispositivos
    final isDesktop = ResponsiveBreakpoints.of(context).largerOrEqualTo(DESKTOP) || isLargeDisplay;
    final isTablet = ResponsiveBreakpoints.of(context).between(TABLET, DESKTOP) || 
                     (screenWidth > 750 && screenWidth < 1200);
    final isMobile = !isDesktop && !isTablet;
    
    // Padding optimizado según tipo de dispositivo
    final horizontalPadding = isLargeDisplay ? 24.0 :
                             (isIpadPro ? 16.0 : 
                             (isDesktop ? 32.0 : (isTablet ? 20.0 : 16.0)));
    final verticalPadding = isLargeDisplay ? 16.0 : 
                           (isIpadPro ? 8.0 : 
                           (isDesktop ? 24.0 : (isTablet ? 16.0 : 12.0)));
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila de búsqueda y filtros
          ResponsiveRowColumn(
            layout: isDesktop || isTablet 
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
                        ref.read(articulosCiudadRefreshProvider.notifier).state++;
                      },
                      tooltip: 'Actualizar',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          value: _sortBy,
                          items: const [
                            DropdownMenuItem(value: 'datoArt', child: Text('Descripción')),
                            DropdownMenuItem(value: 'codArticulo', child: Text('Código')),
                            DropdownMenuItem(value: 'precio', child: Text('Precio')),
                            DropdownMenuItem(value: 'disponible', child: Text('Disponibilidad')),
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
                          _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: _sortBy,
                      items: const [
                        DropdownMenuItem(value: 'datoArt', child: Text('Descripción')),
                        DropdownMenuItem(value: 'codArticulo', child: Text('Código')),
                        DropdownMenuItem(value: 'precio', child: Text('Precio')),
                        DropdownMenuItem(value: 'disponible', child: Text('Disponibilidad')),
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
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
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
          
          SizedBox(height: ResponsiveValue<double>(
            context,
            defaultValue: 16.0,
            conditionalValues: [
              Condition.smallerThan(name: TABLET, value: 12.0),
              Condition.largerThan(name: DESKTOP, value: 20.0),
            ],
          ).value),
          
          // Mostrar datos según el estado del provider
          Expanded(
            child: Builder(
              builder: (context) {
                // Si tenemos datos de ejemplo y estamos cargando los reales, mostrar los de ejemplo
                if (articulosAsyncValue is AsyncLoading && _articulosCache.isNotEmpty) {
                  return _buildArticulosList(_articulosCache);
                }
                
                return articulosAsyncValue.when(
                  // Mientras carga los datos
                  loading: () {
                    if (_articulosCache.isNotEmpty) {
                      // Si ya tenemos datos en caché, mostrarlos durante la carga
                      return _buildArticulosList(_articulosCache);
                    }
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
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
                                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Error de conexión: mostrando datos guardados',
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ref.read(articulosCiudadRefreshProvider.notifier).state++;
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
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar artículos',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red),
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
                              setState(() {
                              });
                             
                              ref.read(articulosCiudadRefreshProvider.notifier).state++;
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
                            Icon(Icons.search_off, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
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
      filteredArticulos = filteredArticulos
          .where((articulo) => 
              (articulo.datoArt.toLowerCase().contains(_searchQuery!)) ||
              (articulo.codArticulo.toLowerCase().contains(_searchQuery!)))
          .toList();
    }
    
    // Filtrar por familia (si hay alguna seleccionada)
    if (_selectedFamilia != null) {
      filteredArticulos = filteredArticulos
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
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
            .map((e) => e.precio )
            .reduce((value, element) => value < element ? value : element);
        final bPrecioMin = articulosAgrupados[b]!
            .map((e) => e.precio)
            .reduce((value, element) => value < element ? value : element);
        return _sortAscending ? aPrecioMin.compareTo(bPrecioMin) : bPrecioMin.compareTo(aPrecioMin);
      } else if (_sortBy == 'disponible') {
        // Para disponibilidad, sumamos el total disponible de cada grupo
        final aDisponible = articulosAgrupados[a]!
            .fold<int>(0, (sum, item) => sum + (item.disponible ));
        final bDisponible = articulosAgrupados[b]!
            .fold<int>(0, (sum, item) => sum + (item.disponible));
        return _sortAscending ? aDisponible.compareTo(bDisponible) : bDisponible.compareTo(aDisponible);
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
    final isDesktop = ResponsiveBreakpoints.of(context).largerOrEqualTo(DESKTOP) || screenWidth > 1200;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contador de artículos
        infoRow,
        
        // Lista de artículos agrupados - diferente diseño según dispositivo
        Expanded(
          child: isDesktop 
              ? _buildDesktopGrid(codigosOrdenados, articulosAgrupados)
              : _buildMobileTabletList(codigosOrdenados, articulosAgrupados),
        ),
      ],
    );
  }
  
  // Vista en grid para escritorio
  Widget _buildDesktopGrid(
    List<String> codigosOrdenados, 
    Map<String, List<ArticulosxCiudadEntity>> articulosAgrupados
  ) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,  // Dos columnas en desktop
        childAspectRatio: 2.0,  // Proporción de las tarjetas
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
        
        return _buildArticuloCard(
          variantes.first,
          variantesPorDbYLista,
          true
        );
      },
    );
  }
  
  // Vista en lista para móvil/tablet
  Widget _buildMobileTabletList(
    List<String> codigosOrdenados, 
    Map<String, List<ArticulosxCiudadEntity>> articulosAgrupados
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
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
        
        return _buildArticuloMobileItem(
          variantes.first,
          variantesPorDbYLista
        );
      },
    );
  }

  // Vista de tarjeta para dispositivos desktop - muestra precios agrupados en una tarjeta
  Widget _buildArticuloCard(
    ArticulosxCiudadEntity articuloPrincipal,
    Map<String?, Map<int?, ArticulosxCiudadEntity>> variantesPorDbYLista,
    bool isDesktop
  ) {
    // Determinar la disponibilidad total combinando todas las variantes
    int disponibilidadTotal = 0;
    variantesPorDbYLista.forEach((db, variantes) {
      variantes.forEach((listaPrecio, articulo) {
        disponibilidadTotal += articulo.disponible;
      });
    });
    
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
                          ...variantesPorDbYLista.entries.take(2).map((dbEntry) {
                            final db = dbEntry.key ?? '';
                            final variantes = dbEntry.value;
                            
                            // Tomar solo las 3 primeras listas de precio para mostrar
                            final listasPrecio = variantes.keys.toList()
                              ..sort();
                            if (listasPrecio.length > 3) {
                              listasPrecio.removeRange(3, listasPrecio.length);
                            }
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Base de datos
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    'Base: $db',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                ),
                                
                                // Precios por lista
                                ...listasPrecio.map((listaPrecio) {
                                  final articulo = variantes[listaPrecio]!;
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                                    child: Row(
                                      children: [
                                        // Condición
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            articulo.condicionPrecio ,
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
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                
                                // Si hay más bases de datos y no es la última, mostrar separador
                                if (variantesPorDbYLista.entries.length > 1 &&
                                    variantesPorDbYLista.entries.first.key != db)
                                  const Divider(height: 16),
                              ],
                            );
                          }).toList(),
                          
                          // Mensaje si hay más variantes
                          if (variantesPorDbYLista.entries.length > 2)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '+ ${variantesPorDbYLista.entries.length - 2} bases más',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ),
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
                TextButton.icon(
                  onPressed: () => _showArticuloDetails(context, articuloPrincipal),
                  icon: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    'Detalles',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: const Size(0, 36),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _verDisponibilidadDetallada(context, articuloPrincipal),
                  icon: const Icon(Icons.inventory_2, size: 18),
                  label: const Text(
                    'Disponibilidad',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
    Map<String?, Map<int?, ArticulosxCiudadEntity>> variantesPorDbYLista
  ) {
    // Calcular disponibilidad total
    int disponibilidadTotal = 0;
    // Obtener el precio mínimo para mostrar destacado
    double precioMinimo = double.infinity;
    String? monedaPrecioMinimo;
    
    // Calcular valores combinados de todas las variantes
    variantesPorDbYLista.forEach((db, variantes) {
      variantes.forEach((listaPrecio, articulo) {
        disponibilidadTotal += articulo.disponible;
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
    final precioFormateado = precioMinimo != double.infinity 
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
            child: Row(
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
                              children: basesDatos.map((db) {
                                return Chip(
                                  label: Text(
                                    '$db',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
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
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        // Botón ver detalles
                        TextButton.icon(
                          onPressed: () => _showArticuloDetails(context, articuloPrincipal),
                          icon: Icon(
                            Icons.visibility_outlined,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          label: const Text(
                            'Ver',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            minimumSize: const Size(0, 36),
                          ),
                        ),
                        
                        // Botón expandir para ver variantes
                        IconButton(
                          onPressed: () {
                            _mostrarVariantesPrecio(context, articuloPrincipal, variantesPorDbYLista);
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
  void _mostrarVariantesPrecio(
    BuildContext context, 
    ArticulosxCiudadEntity articuloPrincipal,
    Map<String?, Map<int?, ArticulosxCiudadEntity>> variantesPorDbYLista
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
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
                        'Precios por Lista',
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
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(),
                  
                  // Lista de variantes por DB y lista de precio
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        ...variantesPorDbYLista.entries.map((dbEntry) {
                          final db = dbEntry.key ?? '';
                          final variantes = dbEntry.value;
                          final listasPrecio = variantes.keys.toList()
                            ..sort((a, b) => (a ?? 0).compareTo(b ?? 0));
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Encabezado de la base de datos
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                            Text(
                                              'Disponible: ${articulo.disponible} ${articulo.unidadMedida}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        // Condición de precio
                                        if (articulo.condicionPrecio != null)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            child: Text(
                                              'Condición: ${articulo.condicionPrecio}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        
                                        // Precio (sin el botón de disponibilidad)
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
                        
                        // Botón de disponibilidad único al final
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _verDisponibilidadDetallada(context, variantesPorDbYLista.entries.first.value.values.first),
                              icon: const Icon(Icons.inventory_2),
                              label: const Text('Ver Disponibilidad'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  // Método para mostrar detalles completos del artículo
  void _showArticuloDetails(BuildContext context, ArticulosxCiudadEntity articulo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título del diálogo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detalles del Artículo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Datos básicos del artículo
                _buildDetailRow('Código:', articulo.codArticulo ?? ''),
                _buildDetailRow('Descripción:', articulo.datoArt ?? ''),
                _buildDetailRow('Unidad:', articulo.unidadMedida ?? ''),
                _buildDetailRow('Disponible:', '${articulo.disponible ?? 0}'),
                _buildDetailRow('Lista de Precio:', '${articulo.listaPrecio ?? ''}'),
                _buildDetailRow('Precio:', '${articulo.moneda ?? 'BS'} ${articulo.precio?.toStringAsFixed(2) ?? '0.00'}'),
                
                // Datos adicionales si existen
                if (articulo.db != null)
                  _buildDetailRow('Base de Datos:', articulo.db ?? ''),
                if (articulo.condicionPrecio != null)
                  _buildDetailRow('Condición:', articulo.condicionPrecio ?? ''),
                
                const SizedBox(height: 20),
                
                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Show confirmation dialog before adding to cart
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Confirmar acción'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('¿Desea agregar este artículo al carrito?'),
                                  const SizedBox(height: 8),
                                  Text('Artículo: ${articulo.datoArt}', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Código: ${articulo.codArticulo}'),
                                  if (articulo.precio != null)
                                    Text('Precio: ${articulo.moneda ?? 'BS'} ${articulo.precio?.toStringAsFixed(2)}'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context), // Cancel
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    // Close confirmation dialog
                                    Navigator.pop(context);
                                    // Close details dialog
                                    Navigator.pop(context);
                                    // Show confirmation message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${articulo.datoArt} agregado al carrito'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: const Text('Confirmar'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text('Agregar al Carrito'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Widget auxiliar para construir filas de detalles
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // Método para ver la disponibilidad detallada de un artículo
  void _verDisponibilidadDetallada(BuildContext context, ArticulosxCiudadEntity articulo) {
    // Usar el router para navegar a la pantalla de disponibilidad detallada
    context.go('/dashboard/disponibilidad/${articulo.codArticulo}', extra: articulo);
  }
}