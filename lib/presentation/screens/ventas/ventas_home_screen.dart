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
              ).value!),
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
                  ).value!),
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
    List<ArticulosxCiudadEntity> displayedArticulos = articulos;
    
    // Filtrar por búsqueda
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      displayedArticulos = displayedArticulos
          .where((articulo) => 
              (articulo.datoArt.toLowerCase().contains(_searchQuery!)) ||
              (articulo.codArticulo.toLowerCase().contains(_searchQuery!)))
          .toList();
    }
    
    // Filtrar por familia (si hay alguna seleccionada)
    if (_selectedFamilia != null) {
      displayedArticulos = displayedArticulos
          .where((articulo) => articulo.codigoFamilia == _selectedFamilia)
          .toList();
    }
    
    // Ordenar los resultados
    displayedArticulos.sort((a, b) {
      if (_sortBy == 'datoArt') {
        final aValue = a.datoArt ?? '';
        final bValue = b.datoArt ?? '';
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      } else if (_sortBy == 'codArticulo') {
        final aValue = a.codArticulo ?? '';
        final bValue = b.codArticulo ?? '';
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      } else if (_sortBy == 'precio') {
        final aValue = a.precio ?? 0;
        final bValue = b.precio ?? 0;
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      } else if (_sortBy == 'disponible') {
        final aValue = a.disponible ?? 0;
        final bValue = b.disponible ?? 0;
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      }
      return 0;
    });
    
    // Si no hay resultados
    if (displayedArticulos.isEmpty) {
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

    // Solamente el contador de artículos (sin el dropdown de familias)
    final infoRow = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'Mostrando ${displayedArticulos.length} de ${articulos.length} artículos',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    
    // Determinar tipo de dispositivo para el layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isIpadPro = (screenWidth >= 1000 && screenWidth <= 1366);
    final isDesktop = ResponsiveBreakpoints.of(context).largerOrEqualTo(DESKTOP);
    final isTablet = ResponsiveBreakpoints.of(context).between(TABLET, DESKTOP) || 
                     (screenWidth > 750 && screenWidth < 1200);
    final isMobile = !isDesktop && !isTablet;
    
    // Mostrar lista de artículos - usar GridView para desktop/tablet y ListView para móvil
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Solo mostrar el contador de artículos
        infoRow,
        
        // Lista de artículos
        Expanded(
          child: isDesktop || isTablet
            ? GridView.builder(
                padding: const EdgeInsets.only(top: 8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  // Configuración específica para iPad Pro (1024x1366)
                  crossAxisCount: isIpadPro ? 3 : 
                                  (screenWidth > 1100 && screenWidth < 1200 ? 3 : 
                                  isDesktop ? 3 : 
                                  screenWidth > 700 ? 2 : 1),
                  childAspectRatio: isIpadPro ? 1.8 : 
                                  (screenWidth > 1100 && screenWidth < 1200 ? 2.0 :
                                  isDesktop ? 2.2 : 
                                  isTablet ? 2.0 : 1.5),
                  mainAxisSpacing: isIpadPro ? 8 : 16,
                  crossAxisSpacing: isIpadPro ? 8 : 16,
                ),
                itemCount: displayedArticulos.length,
                itemBuilder: (context, index) {
                  return _buildArticuloCard(displayedArticulos[index]);
                },
              )
            : ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: displayedArticulos.length,
                itemBuilder: (context, index) {
                  return _buildArticuloListItem(displayedArticulos[index]);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildArticuloCard(ArticulosxCiudadEntity articulo) {
    // Calcular dimensiones de pantalla para adaptar el diseño
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeDisplay = screenWidth > 1500 && screenHeight > 1200;
    
    // Determinar el color de disponibilidad según la cantidad
    Color disponibilidadColor;
    if (articulo.disponible > 100) {
      disponibilidadColor = Theme.of(context).colorScheme.primary; 
    } else if (articulo.disponible > 20) {
      disponibilidadColor = Theme.of(context).colorScheme.tertiary; 
    } else {
      disponibilidadColor = Theme.of(context).colorScheme.error; 
    }
    
    // Diseño optimizado específicamente para pantallas grandes (1586x1716)
    return Card(
      margin: EdgeInsets.symmetric(
        vertical: isLargeDisplay ? 6 : 4,
        horizontal: isLargeDisplay ? 6 : 4
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1
        ),
      ),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: () => _showArticuloDetails(context, articulo),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banda de disponibilidad en la parte superior (verde, amarilla o roja)
            Container(
              width: double.infinity,
              color: disponibilidadColor,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                'DISPONIBILIDAD: ${articulo.disponible} ${articulo.unidadMedida}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            // Condición de precio
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Text(
                'CONDICIÓN: ${articulo.condicionPrecio}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            
            // Código y descripción del artículo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: RichText(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface
                  ),
                  children: [
                    TextSpan(
                      text: '${articulo.codArticulo} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: articulo.datoArt?.toUpperCase() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Banda de precio al final
            Container(
              width: double.infinity,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                '${articulo.moneda ?? 'BS'} ${articulo.precio?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(
                  fontSize: 12,
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

  Widget _buildArticuloListItem(ArticulosxCiudadEntity articulo) {
    final String precioFormateado = articulo.moneda != null 
      ? '${articulo.moneda} ${articulo.precio?.toStringAsFixed(2)}' 
      : 'BS ${articulo.precio?.toStringAsFixed(2)}';
      
    // Color para la barra lateral según disponibilidad
    Color disponibilidadColor;
    if (articulo.disponible > 10) {
      disponibilidadColor = Theme.of(context).colorScheme.primary;
    } else if (articulo.disponible > 0) {
      disponibilidadColor = Theme.of(context).colorScheme.tertiary;
    } else {
      disponibilidadColor = Theme.of(context).colorScheme.error;
    }
      
    // Diseño específico para dispositivos móviles como en la captura
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IntrinsicHeight( // Asegura que la altura sea suficiente para todo el contenido
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Estira los widgets verticalmente
          children: [
            // Barra lateral de disponibilidad
            Container(
              width: 6,
              color: disponibilidadColor,
            ),
            
            // Contenido principal
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre del artículo
                    Text(
                      articulo.datoArt?.toUpperCase() ?? 'SIN DESCRIPCIÓN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Código del artículo
                    Text(
                      'Código: ${articulo.codArticulo}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    
                    // Disponibilidad con icono
                    Row(
                      mainAxisSize: MainAxisSize.min, // Evita overflow
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: disponibilidadColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Disponible: ${articulo.disponible} ${articulo.unidadMedida}',
                            style: TextStyle(
                              fontSize: 12,
                              color: disponibilidadColor,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    // Condición
                    Text(
                      'Condición: ${articulo.condicionPrecio ?? ""}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            
            // Precio y botón de carrito
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Precio
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        precioFormateado,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Lista: ${articulo.listaPrecio}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Botón de carrito
                  IconButton(
                    icon: Icon(
                      Icons.shopping_cart_outlined, 
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    iconSize: 24,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${articulo.datoArt} agregado a la venta'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para mostrar detalles de artículos (mencionado en el código anterior)
  void _showArticuloDetails(BuildContext context, ArticulosxCiudadEntity articulo) {
    final isTablet = ResponsiveBreakpoints.of(context).largerOrEqualTo(TABLET);
    final isDesktop = ResponsiveBreakpoints.of(context).largerOrEqualTo(DESKTOP);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletSpecificSize = screenWidth > 1000 && screenWidth < 1200;
    
    // Usar Dialog para tablets y desktop
    if (isTablet || isDesktop) {
      showDialog(
        context: context,
        builder: (context) {
          // Calcular el ancho según el tipo de dispositivo
          final dialogWidth = isDesktop ? 700.0 : (isTabletSpecificSize ? 600.0 : 550.0);
          
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: EdgeInsets.symmetric(
              horizontal: (MediaQuery.of(context).size.width - dialogWidth) / 2,
              vertical: 24.0,
            ),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              width: dialogWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Detalles del Artículo',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        tooltip: 'Cerrar',
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Encabezado con el nombre del producto destacado
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primaryContainer,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.science_outlined,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            articulo.datoArt ?? 'Sin descripción',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Código: ${articulo.codArticulo}',
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Datos principales en grid responsiva
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Columna 1
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailItemCard(
                                      'Disponibilidad',
                                      '${articulo.disponible ?? 0} ${articulo.unidadMedida ?? ""}',
                                      Icons.inventory_2_outlined,
                                      isQuantity: true,
                                      isLow: articulo.disponible != null && articulo.disponible! < 5,
                                    ),
                                    const SizedBox(height: 16),
                                    if (articulo.condicionPrecio != null && articulo.condicionPrecio!.isNotEmpty)
                                      _buildDetailItemCard(
                                        'Condición',
                                        articulo.condicionPrecio!,
                                        Icons.description_outlined,
                                      ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Columna 2
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailItemCard(
                                      'Precio',
                                      '${articulo.moneda ?? 'BS'} ${articulo.precio?.toStringAsFixed(2) ?? '0.00'}',
                                      Icons.attach_money,
                                      isPrice: true,
                                    ),
                                    const SizedBox(height: 16),
                                    if (articulo.listaPrecio != null)
                                      _buildDetailItemCard(
                                        'Lista de Precio',
                                        articulo.listaPrecio.toString(),
                                        Icons.list_alt_outlined,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Cerrar'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${articulo.datoArt} agregado a la venta'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Agregar a venta'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // Mantener el BottomSheet para móvil
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            height: MediaQuery.of(context).size.height * 0.6,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const Text(
                    'Detalles del Artículo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Info del artículo
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem('Código:', articulo.codArticulo ?? ''),
                      _buildDetailItem('Descripción:', articulo.datoArt ?? ''),
                      _buildDetailItem('Disponible:', '${articulo.disponible ?? 0} ${articulo.unidadMedida ?? ""}', 
                         isSpecial: articulo.disponible != null && articulo.disponible! < 5),
                      _buildDetailItem('Precio:', '${articulo.moneda ?? 'BS'} ${articulo.precio?.toStringAsFixed(2) ?? '0.00'}', isPrice: true),
                      if (articulo.condicionPrecio != null && articulo.condicionPrecio!.isNotEmpty)
                        _buildDetailItem('Condición:', articulo.condicionPrecio!),
                      if (articulo.listaPrecio != null)
                        _buildDetailItem('Lista de Precio:', articulo.listaPrecio.toString()),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Acciones
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${articulo.datoArt} agregado a la venta'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Agregar a venta'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Cerrar'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          ),
                        ),
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
  }
  
  // Método para crear elementos de detalle estilo tarjeta (mencionado en el código anterior)
  Widget _buildDetailItemCard(String label, String value, IconData icon, {bool isPrice = false, bool isQuantity = false, bool isLow = false}) {
    final color = isPrice ? Colors.green.shade700 : 
                (isQuantity && isLow ? Colors.orange.shade700 : null);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? Colors.blue.shade700).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color ?? Colors.blue.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Método para elementos de detalle en formato móvil
  Widget _buildDetailItem(String label, String value, {bool isPrice = false, bool isSpecial = false}) {
    final textStyle = isPrice 
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green) 
        : (isSpecial 
            ? TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700]) 
            : null);
            
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }
}