import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/control_combustible_maquina_montacarga_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/control_combustible_maquina_montacarga_entity.dart';
import 'package:intl/intl.dart';

class ControlCombustibleMaquinaMontaCargaViewScreen extends ConsumerStatefulWidget {
  const ControlCombustibleMaquinaMontaCargaViewScreen({super.key});

  @override
  ConsumerState<ControlCombustibleMaquinaMontaCargaViewScreen> createState() =>
      _ControlCombustibleMaquinaMontaCargaViewScreenState();
}

class _ControlCombustibleMaquinaMontaCargaViewScreenState
    extends ConsumerState<ControlCombustibleMaquinaMontaCargaViewScreen> {
  
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 7));
  DateTime _fechaFin = DateTime.now();
  String _tipoTransaccionFiltro = 'TODOS';
  int? _sucursalFiltro; // Nuevo filtro de sucursal
  bool _hasSearched = false;

  // Agregar controller para el scroll horizontal
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Cargar sucursales al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sucursalesProvider);
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _cargarDatos() {
    setState(() {
      _hasSearched = true;
    });
    ref.read(controlCombustibleMaquinaMontacargaNotifierProvider.notifier)
        .cargarReporteMovimientos(_fechaInicio, _fechaFin, _sucursalFiltro ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(controlCombustibleMaquinaMontacargaNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Reporte Movimientos Bidones',
          style: ResponsiveUtilsBosque.getTitleStyle(context),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: ResponsiveUtilsBosque.isDesktop(context) ? 2 : 4,
      ),
      body: Column(
        children: [
          _buildFiltros(colorScheme),
          Expanded(
            child: _buildContent(state, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros(ColorScheme colorScheme) {
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    if (isDesktop) {
      // Desktop: filtros en fila
      return Card(
        margin: EdgeInsets.all(ResponsiveUtilsBosque.getHorizontalPadding(context)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildDateField('Fecha Inicio', _fechaInicio, true, colorScheme)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDateField('Fecha Fin', _fechaFin, false, colorScheme)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTipoTransaccionFilter(colorScheme)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSucursalFilter(colorScheme)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: _cargarDatos,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Móvil: filtros en columna y expansion
      return Card(
        margin: EdgeInsets.all(ResponsiveUtilsBosque.getHorizontalPadding(context)),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          title: Row(
            children: [
              Icon(Icons.filter_alt, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Filtros', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDateField('Fecha Inicio', _fechaInicio, true, colorScheme),
                  const SizedBox(height: 12),
                  _buildDateField('Fecha Fin', _fechaFin, false, colorScheme),
                  const SizedBox(height: 12),
                  _buildTipoTransaccionFilter(colorScheme),
                  const SizedBox(height: 12),
                  _buildSucursalFilter(colorScheme),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _cargarDatos,
                      icon: const Icon(Icons.search),
                      label: const Text('Buscar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDateField(String label, DateTime fecha, bool isInicio, ColorScheme colorScheme) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: Icon(Icons.calendar_today, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      controller: TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(fecha),
      ),
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: fecha,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        
        if (selectedDate != null) {
          setState(() {
            if (isInicio) {
              _fechaInicio = selectedDate;
            } else {
              _fechaFin = selectedDate;
            }
          });
        }
      },
    );
  }

  Widget _buildTipoTransaccionFilter(ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      value: _tipoTransaccionFiltro,
      decoration: InputDecoration(
        labelText: 'Tipo Transacción',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      items: const [
        DropdownMenuItem(value: 'TODOS', child: Text('TODOS')),
        DropdownMenuItem(value: 'INGRESO', child: Text('INGRESO')),
        DropdownMenuItem(value: 'SALIDA', child: Text('SALIDA')),
        DropdownMenuItem(value: 'TRASPASO', child: Text('TRASPASO')),
      ],
      onChanged: (value) {
        setState(() {
          _tipoTransaccionFiltro = value!;
        });
      },
    );
  }

  Widget _buildSucursalFilter(ColorScheme colorScheme) {
    return Consumer(
      builder: (context, ref, _) {
        final asyncSucursales = ref.watch(sucursalesProvider);
        
        return asyncSucursales.when(
          loading: () => Container(
            height: 56,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Cargando sucursales...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          error: (error, stackTrace) => Container(
            height: 56,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.red.shade50,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error al cargar sucursales',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          data: (sucursales) {
            // Filter out the "-- Defina Nueva Sucursal --" option
            final validSucursales = sucursales.where((s) => s.codSucursal != -1).toList();
            
            return DropdownButtonFormField<int?>(
              value: _sucursalFiltro,
              decoration: InputDecoration(
                labelText: 'Sucursal',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    'Todas las sucursales',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                ...validSucursales.map((sucursal) => DropdownMenuItem<int?>(
                  value: sucursal.codSucursal,
                  child: Text(
                    sucursal.nombre,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _sucursalFiltro = value;
                });
              },
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: colorScheme.primary,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContent(RegistroState state, ColorScheme colorScheme) {
    // Si no se ha buscado, mostrar mensaje inicial
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_outlined, 
              size: 64, 
              color: colorScheme.onSurfaceVariant.withOpacity(0.6)
            ),
            const SizedBox(height: 16),
            Text(
              'Seleccione fechas y presione "Buscar"',
              style: TextStyle(
                fontSize: 18, 
                color: colorScheme.onSurfaceVariant.withOpacity(0.8)
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'para ver los movimientos de bidones',
              style: TextStyle(
                fontSize: 14, 
                color: colorScheme.onSurfaceVariant.withOpacity(0.6)
              ),
            ),
          ],
        ),
      );
    }

    if (state.reporteStatus == FetchStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.reporteStatus == FetchStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.error.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            ),
            const SizedBox(height: 24),
            Text(
              'No se encontraron movimientos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'No existen registros de movimientos de bidones para los filtros seleccionados.\n\n'
              'Prueba ampliando el rango de fechas, seleccionando otra sucursal o cambiando el tipo de transacción.',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Sugerencia: Ajusta los filtros para ver otros resultados.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final movimientosFiltrados = _filtrarMovimientos(state.reporteMovimientos);

    if (movimientosFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_outlined, 
                size: 64, 
                color: colorScheme.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¡No se encontraron movimientos!',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                _buildNoResultsMessage(),
                style: TextStyle(
                  fontSize: 14, 
                  color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sugerencias:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Amplíe el rango de fechas\n• Seleccione "Todas las sucursales"\n• Cambie el tipo de transacción a "TODOS"',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ResponsiveUtilsBosque.isDesktop(context)
        ? _buildDesktopTable(movimientosFiltrados, colorScheme)
        : _buildMobileList(movimientosFiltrados, colorScheme);
  }

  String _buildNoResultsMessage() {
    List<String> filters = [];
    String sucursalNombre = '';
    
    // Agregar información sobre los filtros aplicados
    if (_tipoTransaccionFiltro != 'TODOS') {
      filters.add('tipo "$_tipoTransaccionFiltro"');
    }
    
    if (_sucursalFiltro != null) {
      // Obtener el nombre de la sucursal seleccionada de forma sincrónica
      final asyncSucursales = ref.read(sucursalesProvider);
      asyncSucursales.whenData((sucursales) {
        try {
          final sucursal = sucursales.firstWhere(
            (s) => s.codSucursal == _sucursalFiltro,
            orElse: () => throw StateError('No encontrado'),
          );
          sucursalNombre = sucursal.nombre;
        } catch (e) {
          sucursalNombre = 'sucursal seleccionada';
        }
      });
      
      if (sucursalNombre.isNotEmpty) {
        filters.add('sucursal "$sucursalNombre"');
      } else {
        filters.add('sucursal específica');
      }
    }
    
    String dateRange = '${_fechaInicio.day.toString().padLeft(2, '0')}/${_fechaInicio.month.toString().padLeft(2, '0')}/${_fechaInicio.year} - ${_fechaFin.day.toString().padLeft(2, '0')}/${_fechaFin.month.toString().padLeft(2, '0')}/${_fechaFin.year}';
    
    if (filters.isEmpty) {
      return 'No hay movimientos de bidones registrados entre las fechas $dateRange.';
    } else {
      String filterText = filters.length == 1 ? filters.first : '${filters.sublist(0, filters.length - 1).join(', ')} y ${filters.last}';
      return 'No se encontraron movimientos de bidones con $filterText entre las fechas $dateRange.';
    }
  }

  List<ControlCombustibleMaquinaMontacargaEntity> _filtrarMovimientos(
      List<ControlCombustibleMaquinaMontacargaEntity> movimientos) {
    var movimientosFiltrados = movimientos;
    
    print('Movimientos antes del filtro: ${movimientos.length}'); // Debug
    print('Filtro seleccionado: $_tipoTransaccionFiltro'); // Debug
    
    // Filtrar por tipo de transacción
    if (_tipoTransaccionFiltro != 'TODOS') {
      movimientosFiltrados = movimientosFiltrados.where((m) {
        // Debug: imprimir el tipo de cada movimiento
        print('Movimiento tipoTransaccion: "${m.tipoTransaccion}" (length: ${m.tipoTransaccion.length})');
        
        // Normalizar el tipo de transacción (trim y uppercase)
        final tipoTransaccionNormalizado = m.tipoTransaccion.trim().toUpperCase();
        final filtroNormalizado = _tipoTransaccionFiltro.trim().toUpperCase();
        
        print('Comparando: "$tipoTransaccionNormalizado" == "$filtroNormalizado"');
        
        // Si el tipo está vacío o es null, no lo incluimos en ningún filtro específico
        if (tipoTransaccionNormalizado.isEmpty) {
          print('Tipo vacío, excluido del filtro');
          return false;
        }
        
        final matches = tipoTransaccionNormalizado == filtroNormalizado;
        print('Match: $matches');
        
        return matches;
      }).toList();
      
      print('Después del filtro por tipo: ${movimientosFiltrados.length}'); // Debug
    }
    
    print('Movimientos finales: ${movimientosFiltrados.length}'); // Debug
    return movimientosFiltrados;
  }

  Widget _buildDesktopTable(List<ControlCombustibleMaquinaMontacargaEntity> movimientos, ColorScheme colorScheme) {
    return Card(
      margin: EdgeInsets.all(ResponsiveUtilsBosque.getHorizontalPadding(context)),
      child: Column(
        children: [
          // Header con información del total de registros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Movimientos de Bidones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${movimientos.length} registros',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tabla con scrollbars explícitos
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  // Área de la tabla con scroll vertical
                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
                      controller: null, // Scroll vertical automático
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Scrollbar(
                          controller: _horizontalScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          thickness: 16,
                          radius: const Radius.circular(8),
                          scrollbarOrientation: ScrollbarOrientation.bottom,
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: MediaQuery.of(context).size.width - 
                                          (ResponsiveUtilsBosque.getHorizontalPadding(context) * 2) - 64,
                              ),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(colorScheme.primaryContainer),
                                dataRowMinHeight: 56,
                                dataRowMaxHeight: 72,
                                horizontalMargin: 16,
                                columnSpacing: 16,
                                showCheckboxColumn: false,
                                headingTextStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                                dataTextStyle: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface,
                                ),
                                columns: const [
                                  DataColumn(
                                    label: SizedBox(
                                      width: 90,
                                      child: Text('Fecha'),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 160,
                                      child: Text('Empleado'),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 120,
                                      child: Text('Origen'),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 140,
                                      child: Text('Clase Origen'),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 120,
                                      child: Text('Destino'),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 140,
                                      child: Text('Clase Destino'),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 120,
                                      child: Text('Sucursal'),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 100,
                                      child: Text('Litros'),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 180,
                                      child: Text('Observaciones'),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 100,
                                      child: Text('Tipo'),
                                    ),
                                  ),
                                ],
                                rows: movimientos.map((movimiento) {
                                  return DataRow(
                                    cells: [
                                      // Fecha
                                      DataCell(
                                        SizedBox(
                                          width: 90,
                                          child: Text(
                                            DateFormat('dd/MM/yyyy').format(movimiento.fecha),
                                          ),
                                        ),
                                      ),
                                      // Empleado
                                      DataCell(
                                        Tooltip(
                                          message: movimiento.nombreCompleto,
                                          child: SizedBox(
                                            width: 160,
                                            child: Text(
                                              movimiento.nombreCompleto,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Origen
                                      DataCell(
                                        Tooltip(
                                          message: movimiento.codigoOrigen,
                                          child: SizedBox(
                                            width: 120,
                                            child: Text(
                                              movimiento.codigoOrigen,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Clase Origen
                                      DataCell(
                                        Tooltip(
                                          message: movimiento.nombreMaquinaOrigen.isNotEmpty 
                                              ? movimiento.nombreMaquinaOrigen 
                                              : 'N/A',
                                          child: SizedBox(
                                            width: 140,
                                            child: Text(
                                              movimiento.nombreMaquinaOrigen.isNotEmpty 
                                                  ? movimiento.nombreMaquinaOrigen 
                                                  : 'N/A',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Destino
                                      DataCell(
                                        Tooltip(
                                          message: movimiento.codigoDestino.isNotEmpty 
                                              ? movimiento.codigoDestino 
                                              : 'N/A',
                                          child: SizedBox(
                                            width: 120,
                                            child: Text(
                                              movimiento.codigoDestino.isNotEmpty 
                                                  ? movimiento.codigoDestino 
                                                  : 'N/A',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Clase Destino
                                      DataCell(
                                        Tooltip(
                                          message: movimiento.nombreMaquinaDestino.isNotEmpty 
                                              ? movimiento.nombreMaquinaDestino 
                                              : 'N/A',
                                          child: SizedBox(
                                            width: 140,
                                            child: Text(
                                              movimiento.nombreMaquinaDestino.isNotEmpty 
                                                  ? movimiento.nombreMaquinaDestino 
                                                  : 'N/A',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Sucursal
                                      DataCell(
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            movimiento.nombreSucursal,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      // Litros
                                      DataCell(
                                        SizedBox(
                                          width: 100,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: colorScheme.secondaryContainer,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              movimiento.litrosIngreso.toStringAsFixed(2),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSecondaryContainer,
                                                fontSize: 11,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Observaciones
                                      DataCell(
                                        Tooltip(
                                          message: movimiento.obs,
                                          child: SizedBox(
                                            width: 180,
                                            child: Text(
                                              movimiento.obs,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Tipo Transacción
                                      DataCell(
                                        SizedBox(
                                          width: 100,
                                          child: _buildTipoTransaccionChip(movimiento.tipoTransaccion, colorScheme),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoTransaccionChip(String tipo, ColorScheme colorScheme) {
    Color chipColor;
    switch (tipo) {
      case 'INGRESO':
        chipColor = Colors.green;
        break;
      case 'SALIDA':
        chipColor = Colors.orange;
        break;
      case 'TRASPASO':
        chipColor = Colors.blue;
        break;
      default:
        chipColor = colorScheme.primary;
    }

    return Chip(
      label: Text(
        tipo,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildMobileList(List<ControlCombustibleMaquinaMontacargaEntity> movimientos, ColorScheme colorScheme) {
    return Column(
      children: [
        // Header para móvil
        Container(
          margin: EdgeInsets.all(ResponsiveUtilsBosque.getHorizontalPadding(context)),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Movimientos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${movimientos.length}',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Lista con scroll
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context),
              ),
              itemCount: movimientos.length,
              itemBuilder: (context, index) {
                final movimiento = movimientos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(movimiento.fecha),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            _buildTipoTransaccionChip(movimiento.tipoTransaccion, colorScheme),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildInfoRow('Empleado:', movimiento.nombreCompleto),
                        _buildInfoRow('Origen:', movimiento.codigoOrigen),
                        _buildInfoRow('Clase Origen:', movimiento.nombreMaquinaOrigen.isNotEmpty 
                            ? movimiento.nombreMaquinaOrigen 
                            : 'N/A'),
                        _buildInfoRow('Destino:', movimiento.codigoDestino.isNotEmpty 
                            ? movimiento.codigoDestino 
                            : 'N/A'),
                        _buildInfoRow('Clase Destino:', movimiento.nombreMaquinaDestino.isNotEmpty 
                            ? movimiento.nombreMaquinaDestino 
                            : 'N/A'),
                        _buildInfoRow('Sucursal:', movimiento.nombreSucursal),
                        Row(
                          children: [
                            _buildInfoRow('Litros:', '', flex: 0),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                movimiento.litrosIngreso.toStringAsFixed(2),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (movimiento.obs.isNotEmpty)
                          _buildInfoRow('Observaciones:', movimiento.obs),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {int flex = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (flex > 0)
            Expanded(
              child: Text(value),
            ),
        ],
      ),
    );
  }
}