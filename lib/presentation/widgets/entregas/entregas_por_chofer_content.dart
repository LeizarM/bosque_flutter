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
        // Tabla de resultados (lado izquierdo)
        Expanded(
          flex: tableFlex,
          child: _buildTablaEntregas(historialRuta),
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
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezados de tabla con las columnas solicitadas
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            color: Colors.grey[200],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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

          // Contenido de la tabla
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
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Lista de filas
                        for (int i = 0; i < historialRuta.length; i++)
                          _buildRowItem(historialRuta[i], i),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  // Construir una fila de datos
  Widget _buildRowItem(EntregaEntity entrega, int index) {
    final rowColor = _getTipoColor(entrega);
    final isSelected = _selectedRowIndex == index;
    
    return Container(
      color: isSelected ? Colors.grey.shade300 : rowColor,
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
                        : "-")
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
                      : '-'
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
                    ),
                  ),
                ),
              ),

              // Fecha Nota
              SizedBox(
                width: 120,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(_formatDate(entrega.fechaNota)),
                ),
              ),

              // Fecha Entrega
              SizedBox(
                width: 120,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(_formatDate(entrega.fechaEntrega)),
                ),
              ),

              // Dif. Min
              SizedBox(
                width: 80,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(entrega.diferenciaMinutos?.toString() ?? '0'),
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
                    ),
                  ),
                ),
              ),

              // Vendedor
              SizedBox(
                width: 120,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(entrega.vendedor ?? '-'),
                ),
              ),

              // Chofer
              SizedBox(
                width: 120,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(entrega.nombreCompleto ?? '-'),
                ),
              ),

              // Coche
              SizedBox(
                width: 100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(entrega.cochePlaca ?? '-'),
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
                      : '-'
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
                    ),
                  ),
                ),
              ),

              // Acciones
              SizedBox(
                width: 120,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: entrega.latitud != 0 && entrega.longitud != 0
                    ? IconButton(
                        icon: const Icon(Icons.location_on, color: Colors.blue),
                        onPressed: () {
                          setState(() {
                            _selectedRowIndex = index;
                          });
                        },
                      )
                    : const SizedBox()
                ),
              ),
            ],
          ),
        ),
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