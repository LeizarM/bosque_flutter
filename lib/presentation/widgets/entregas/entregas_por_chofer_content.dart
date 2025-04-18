import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bosque_flutter/core/state/chofer_provider.dart';
import 'package:bosque_flutter/core/state/entregas_provider.dart';
import 'package:bosque_flutter/domain/entities/chofer_entity.dart';
import 'package:bosque_flutter/domain/entities/entregas_entity.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';

class EntregasPorChoferContent extends ConsumerStatefulWidget {
  const EntregasPorChoferContent({Key? key}) : super(key: key);

  @override
  ConsumerState<EntregasPorChoferContent> createState() => _EntregasPorChoferContentState();
}

class _EntregasPorChoferContentState extends ConsumerState<EntregasPorChoferContent> {
  DateTime selectedDate = DateTime.now();
  int? selectedChoferId;
  bool isLoading = false;
  bool isInitialState = true;

  // Controlador para el campo de texto de fecha
  final TextEditingController _dateController = TextEditingController();
  
  // Índice de la fila seleccionada para ver en mapa
  int? _selectedRowIndex;

  // State variables for pagination
  int _currentPage = 1;
  int _itemsPerPage = 10; // Can be changed based on user preference

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate);
    // Cargar la lista de choferes al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(choferesProvider.notifier).loadChoferes();
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  // Mostrar selector de fecha
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate);
      });
    }
  }

  // Realizar la búsqueda
  void _buscarEntregas() {
    if (selectedChoferId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione un chofer')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      isInitialState = false;
      _selectedRowIndex = null; // Resetear la selección cuando buscamos nuevos datos
    });

    // Cargar el historial de ruta para el chofer seleccionado en la fecha seleccionada
    ref.read(entregasNotifierProvider.notifier).loadHistorialRuta(
      selectedDate,
      selectedChoferId!,
    ).then((_) {
      setState(() {
        isLoading = false;
      });
    }).catchError((error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los datos: ${error.toString()}')),
      );
    });
  }

  // Formatear fecha desde string o DateTime
  String _formatDate(dynamic fecha) {
    if (fecha == null) return '-';
    
    try {
      if (fecha is String) {
        // Verificar el formato de la fecha
        if (fecha.contains('/')) {
          // Ya viene formateada como dd/MM/yyyy HH:mm:ss
          return fecha;
        }
        // Convertir de ISO a DateTime y luego formatear
        return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(fecha));
      } else if (fecha is DateTime) {
        return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
      }
    } catch (e) {
      debugPrint('Error formateando fecha: $e');
    }
    return '-';
  }

  // Obtener color según el tipo de registro
  Color _getTipoColor(EntregaEntity entrega) {
    final tipo = entrega.tipo?.toLowerCase() ?? '';
    final cardName = entrega.cardName?.toLowerCase() ?? '';
    
    if (cardName.contains('inicio')) {
      return Colors.green.shade100;
    } else if (cardName.contains('fin')) {
      return Colors.red.shade100;
    } else if (tipo.contains('factura')) {
      return Colors.blue.shade50;
    }
    
    return Colors.transparent;
  }

  // Get background color based on priority, docEntry and flag values
  Color _getRowBackgroundColor(EntregaEntity entrega) {
    if (entrega.prioridad == 'Alta') {
      return Colors.orange.shade100; // BG for high priority
    } else if (entrega.docEntry == -1) {
      return Colors.blue.shade100; // BG for inicio de entregas
    } else if (entrega.docEntry == 0) {
      return Colors.green.shade100; // BG for fin de entregas
    } else if (entrega.flag == -1) {
      return Colors.red.shade100; // BG for flagged items
    }
    return Colors.transparent; // Default background
  }

  // Method to get current page data
  List<EntregaEntity> _getPaginatedData(List<EntregaEntity> allData) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage > allData.length 
                    ? allData.length 
                    : startIndex + _itemsPerPage;
    
    if (startIndex >= allData.length) {
      return [];
    }
    return allData.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    final choferesState = ref.watch(choferesProvider);
    final entregasState = ref.watch(entregasNotifierProvider);
    final choferes = choferesState.choferes;
    final isLoadingChoferes = choferesState.status == ChoferesStatus.loading;
    final historialRuta = entregasState.historialRuta;
    
    // Detectar si estamos en móvil, tablet o desktop
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final isTablet = ResponsiveUtilsBosque.isTablet(context);
    
    // Aplicar paddings responsivos
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtros superiores - Responsive layout
          if (isMobile)
            _buildMobileFilters(isLoadingChoferes, choferes)
          else
            _buildDesktopFilters(isLoadingChoferes, choferes),

          SizedBox(height: ResponsiveUtilsBosque.getResponsiveValue(
            context: context,
            defaultValue: 24.0,
            mobile: 16.0,
            tablet: 20.0,
          )),

          // Contenido principal (Tabla y Mapa) - Responsive layout
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : isInitialState
                    ? _buildInitialStateMessage()
                    : isMobile
                        ? _buildMobileContent(historialRuta)
                        : _buildTabletDesktopContent(historialRuta, isMobile, isTablet),
          ),
        ],
      ),
    );
  }

  // Filtros para móvil (layout vertical)
  Widget _buildMobileFilters(bool isLoadingChoferes, List<ChoferEntity> choferes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selector de fecha
        TextField(
          controller: _dateController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Ingrese Fecha',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectDate(context),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Dropdown de choferes
        DropdownButtonFormField<int>(
          value: selectedChoferId,
          decoration: const InputDecoration(
            labelText: 'Chofer',
            border: OutlineInputBorder(),
          ),
          icon: const Icon(Icons.arrow_drop_down),
          isExpanded: true,
          hint: const Text('Seleccione un chofer'),
          items: isLoadingChoferes
              ? [const DropdownMenuItem<int>(value: null, child: Text('Cargando...'))]
              : choferes.map((ChoferEntity chofer) {
                  return DropdownMenuItem<int>(
                    value: chofer.codEmpleado,
                    child: Text('${chofer.nombreCompleto} - ${chofer.cargo}'),
                  );
                }).toList(),
          onChanged: (int? value) {
            setState(() {
              selectedChoferId = value;
            });
          },
        ),
        const SizedBox(height: 16),

        // Botón de búsqueda
        ElevatedButton(
          onPressed: _buscarEntregas,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Buscar'),
        ),
      ],
    );
  }

  // Filtros para tablet/desktop (layout horizontal)
  Widget _buildDesktopFilters(bool isLoadingChoferes, List<ChoferEntity> choferes) {
    return Row(
      children: [
        // Selector de fecha
        Expanded(
          child: TextField(
            controller: _dateController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Ingrese Fecha',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Dropdown de choferes
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<int>(
            value: selectedChoferId,
            decoration: const InputDecoration(
              labelText: 'Chofer',
              border: OutlineInputBorder(),
            ),
            icon: const Icon(Icons.arrow_drop_down),
            isExpanded: true,
            hint: const Text('Seleccione un chofer'),
            items: isLoadingChoferes
                ? [const DropdownMenuItem<int>(value: null, child: Text('Cargando...'))]
                : choferes.map((ChoferEntity chofer) {
                    return DropdownMenuItem<int>(
                      value: chofer.codEmpleado,
                      child: Text('${chofer.nombreCompleto} - ${chofer.cargo}'),
                    );
                  }).toList(),
            onChanged: (int? value) {
              setState(() {
                selectedChoferId = value;
              });
            },
          ),
        ),

        const SizedBox(width: 16),

        // Botón de búsqueda
        ElevatedButton(
          onPressed: _buscarEntregas,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtilsBosque.getResponsiveValue(
                context: context,
                defaultValue: 50.0,
                tablet: 40.0,
                desktop: 50.0,
              ),
              vertical: ResponsiveUtilsBosque.getResponsiveValue(
                context: context,
                defaultValue: 20.0,
                tablet: 18.0,
                desktop: 20.0,
              ),
            ),
          ),
          child: const Text('Buscar'),
        ),
      ],
    );
  }

  // Estado inicial (mensaje de selección)
  Widget _buildInitialStateMessage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Seleccione un chofer y una fecha para ver las entregas',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Layout para móviles (tabs para tabla y mapa)
  Widget _buildMobileContent(List<EntregaEntity> historialRuta) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'TABLA', icon: Icon(Icons.list_alt)),
              Tab(text: 'MAPA', icon: Icon(Icons.map)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTablaEntregas(historialRuta),
                _buildMapa(historialRuta),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Layout para tablet y desktop (tabla y mapa lado a lado)
  Widget _buildTabletDesktopContent(List<EntregaEntity> historialRuta, bool isMobile, bool isTablet) {
    // Determinar proporciones basadas en dispositivo
    final tableFlex = isTablet ? 3 : 2;
    final mapFlex = isTablet ? 2 : 1;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabla de resultados (lado izquierdo) - Wrapped in Expanded with constraints
        Expanded(
          flex: tableFlex,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth,
                child: _buildTablaEntregas(historialRuta),
              );
            },
          ),
        ),

        SizedBox(width: ResponsiveUtilsBosque.getHorizontalPadding(context) / 2),

        // Mapa (lado derecho)
        Expanded(
          flex: mapFlex,
          child: _buildMapa(historialRuta),
        ),
      ],
    );
  }

  // Widget de tabla de entregas
  Widget _buildTablaEntregas(List<EntregaEntity> historialRuta) {
    // Get paginated data
    final paginatedData = _getPaginatedData(historialRuta);
    final totalPages = (historialRuta.length / _itemsPerPage).ceil();
    
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado con scroll horizontal
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              color: Colors.grey[200],
              child: Row(
                children: const [
                  _TableHeader(text: 'Tipo', width: 80),
                  _TableHeader(text: 'Factura', width: 100),
                  _TableHeader(text: 'Cliente', width: 150),
                  _TableHeader(text: 'Fecha Nota', width: 120),
                  _TableHeader(text: 'Fecha Entrega', width: 120),
                  _TableHeader(text: 'Dif. Min.', width: 80),
                  _TableHeader(text: 'Dirección', width: 200),
                  _TableHeader(text: 'Vendedor', width: 120),
                  _TableHeader(text: 'Chofer', width: 120),
                  _TableHeader(text: 'Coche', width: 100),
                  _TableHeader(text: 'Peso (KG)', width: 100),
                  _TableHeader(text: 'Observaciones', width: 150),
                  _TableHeader(text: 'Acciones', width: 120),
                ],
              ),
            ),
          ),

          // Contenido de la tabla con scroll en ambas direcciones
          Expanded(
            child: historialRuta.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'No hay datos disponibles',
                        style: TextStyle(color: Colors.grey[600]),
                      )
                    ],
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    // Set minimum width to ensure horizontal scroll works
                    width: 1540, // Sum of all column widths + padding
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: [
                          // Lista de filas
                          for (int i = 0; i < paginatedData.length; i++)
                            _buildRowItem(paginatedData[i], i + ((_currentPage - 1) * _itemsPerPage)),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
          
          // Paginador
          if (historialRuta.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mostrando ${paginatedData.length} de ${historialRuta.length} registros'),
                    
                    const SizedBox(width: 16),
                    
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.first_page),
                          onPressed: _currentPage > 1 
                              ? () => setState(() {
                                  _currentPage = 1;
                                  _selectedRowIndex = null;
                                }) 
                              : null,
                          tooltip: 'Primera página',
                        ),
                        
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentPage > 1 
                              ? () => setState(() {
                                  _currentPage--;
                                  _selectedRowIndex = null;
                                }) 
                              : null,
                          tooltip: 'Página anterior',
                        ),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Página $_currentPage de $totalPages',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _currentPage < totalPages 
                              ? () => setState(() {
                                  _currentPage++;
                                  _selectedRowIndex = null;
                                }) 
                              : null,
                          tooltip: 'Página siguiente',
                        ),
                        
                        IconButton(
                          icon: const Icon(Icons.last_page),
                          onPressed: _currentPage < totalPages 
                              ? () => setState(() {
                                  _currentPage = totalPages;
                                  _selectedRowIndex = null;
                                }) 
                              : null,
                          tooltip: 'Última página',
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Items per page selector
                        DropdownButton<int>(
                          value: _itemsPerPage,
                          items: [10, 25, 50, 100].map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('$value por página'),
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _itemsPerPage = newValue;
                                _currentPage = 1; // Reset to first page
                                _selectedRowIndex = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Construir una fila de datos
  Widget _buildRowItem(EntregaEntity entrega, int index) {
    final isSelected = _selectedRowIndex == index;
    
    // Apply the background colors according to the criteria
    final bgColor = entrega.prioridad == 'Alta' 
        ? Colors.orange.shade100 
        : entrega.docEntry == -1 
            ? Colors.blue.shade100 
            : entrega.docEntry == 0 
                ? Colors.green.shade100 
                : entrega.flag == -1 
                    ? Colors.red.shade100 
                    : Colors.transparent;
    
    return Container(
      height: 48, // Fixed height as specified in the h-3rem class (approximately 48px)
      color: isSelected ? Colors.grey.shade300 : bgColor,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRowIndex = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              // Tipo
              SizedBox(
                width: 80,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    entrega.tipo ?? 
                    (entrega.cardName.contains("Inicio") 
                      ? "Inicio" 
                      : entrega.cardName.contains("Fin") 
                        ? "Fin" 
                        : "-"),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),

              // Factura
              SizedBox(
                width: 100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    entrega.factura > 0 
                      ? entrega.factura.toString() 
                      : '-',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),

              // Cliente
              SizedBox(
                width: 150,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Tooltip(
                    message: entrega.cardName ?? '-',
                    child: Text(
                      entrega.cardName ?? '-',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),

              // Fecha Nota
              SizedBox(
                width: 120,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _formatDate(entrega.fechaNota),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),

              // Fecha Entrega
              SizedBox(
                width: 120,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _formatDate(entrega.fechaEntrega),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),

              // Dif. Min
              SizedBox(
                width: 80,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    entrega.diferenciaMinutos?.toString() ?? '0',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Dirección
              SizedBox(
                width: 200,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Tooltip(
                    message: entrega.direccionEntrega ?? entrega.addressEntregaFac ?? '-',
                    child: Text(
                      entrega.direccionEntrega ?? entrega.addressEntregaFac ?? '-',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),

              // Vendedor
              SizedBox(
                width: 120,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    entrega.vendedor ?? '-',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),

              // Chofer
              SizedBox(
                width: 120,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    entrega.nombreCompleto ?? '-',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),

              // Coche
              SizedBox(
                width: 100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    entrega.cochePlaca ?? '-',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),

              // Peso
              SizedBox(
                width: 100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    entrega.peso > 0 
                      ? entrega.peso.toStringAsFixed(2) 
                      : '-',
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),

              // Observaciones
              SizedBox(
                width: 150,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Tooltip(
                    message: entrega.obs ?? '-',
                    child: Text(
                      entrega.obs ?? '-',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),

              // Acciones
              SizedBox(
                width: 120,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ElevatedButton(
                    onPressed: entrega.flag == -1 ? null : () => _onVerEntrega(entrega),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                      minimumSize: const Size(32, 32),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                    ),
                    child: const Icon(
                      Icons.remove_red_eye,
                      color: Colors.blue,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onVerEntrega(EntregaEntity entrega) {
    if (entrega.latitud != 0 && entrega.longitud != 0) {
      // Show the selected entrega on map
      setState(() {
        final index = ref.read(entregasNotifierProvider).historialRuta.indexOf(entrega);
        if (index != -1) {
          _selectedRowIndex = index;
        }
      });
    } else {
      // Show details in a dialog if no coordinates available
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Detalles de ${entrega.tipo ?? "Entrega"}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (entrega.cardName != null && entrega.cardName!.isNotEmpty)
                  _buildDetailItem('Cliente', entrega.cardName!),
                if (entrega.factura > 0)
                  _buildDetailItem('Factura', '${entrega.factura}'),
                if (entrega.fechaNota != null)
                  _buildDetailItem('Fecha Nota', _formatDate(entrega.fechaNota)),
                if (entrega.fechaEntrega != null)
                  _buildDetailItem('Fecha Entrega', _formatDate(entrega.fechaEntrega)),
                if ((entrega.direccionEntrega != null && entrega.direccionEntrega!.isNotEmpty) ||
                    (entrega.addressEntregaFac != null && entrega.addressEntregaFac!.isNotEmpty))
                  _buildDetailItem('Dirección', 
                      entrega.direccionEntrega != null && entrega.direccionEntrega!.isNotEmpty
                          ? entrega.direccionEntrega!
                          : entrega.addressEntregaFac!),
                if (entrega.obs != null && entrega.obs!.isNotEmpty)
                  _buildDetailItem('Observaciones', entrega.obs!),
                if (entrega.vendedor != null && entrega.vendedor!.isNotEmpty)
                  _buildDetailItem('Vendedor', entrega.vendedor!),
                if (entrega.peso > 0)
                  _buildDetailItem('Peso', '${entrega.peso.toStringAsFixed(2)} kg'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
          const Divider(),
        ],
      ),
    );
  }

  // Widget de mapa
  Widget _buildMapa(List<EntregaEntity> historialRuta) {
    // Verificar si hay entregas con coordenadas válidas para mostrar en el mapa o una fila seleccionada
    final hasSelectedPoint = _selectedRowIndex != null && 
                            _selectedRowIndex! < historialRuta.length &&
                            historialRuta[_selectedRowIndex!].latitud != 0 && 
                            historialRuta[_selectedRowIndex!].longitud != 0;
                            
    final hasValidLocations = historialRuta.any(
      (entrega) => entrega.latitud != 0 && entrega.longitud != 0
    );
    
    // Obtener la entrega seleccionada si hay una
    final selectedEntrega = hasSelectedPoint ? historialRuta[_selectedRowIndex!] : null;
    
    return Card(
      elevation: 4,
      child: Stack(
        children: [
          // Aquí se implementaría el mapa real con las coordenadas de las entregas
          Container(
            height: double.infinity,
            child: hasValidLocations
                ? Center(
                    // Placeholder para el mapa real
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map, size: 80, color: Colors.blue),
                        const SizedBox(height: 8),
                        Text(
                          selectedEntrega != null 
                            ? 'Ubicación: ${selectedEntrega.direccionEntrega}'
                            : 'Mapa con ${historialRuta.length} puntos de entrega',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (selectedEntrega != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Lat: ${selectedEntrega.latitud.toStringAsFixed(6)}, Long: ${selectedEntrega.longitud.toStringAsFixed(6)}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ]
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map, size: 80, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          'No hay ubicaciones disponibles',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Seleccione una entrega con ubicación para ver en el mapa',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        )
                      ],
                    ),
                  ),
          ),
          
          // Si hay ubicaciones, mostrar una leyenda
          if (hasValidLocations)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Leyenda:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildLeyendaItem(Colors.green.shade100, 'Inicio de Ruta'),
                    _buildLeyendaItem(Colors.blue.shade100, 'Punto de Entrega'),
                    _buildLeyendaItem(Colors.red.shade100, 'Fin de Ruta'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Elemento de leyenda para el mapa
  Widget _buildLeyendaItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// Widget auxiliar para los encabezados de la tabla
class _TableHeader extends StatelessWidget {
  final String text;
  final double width;
  
  const _TableHeader({
    Key? key, 
    required this.text, 
    required this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}