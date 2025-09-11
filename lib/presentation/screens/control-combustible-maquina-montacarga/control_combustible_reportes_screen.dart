import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/control_combustible_maquina_montacarga_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_contenedor_entity.dart';
import 'package:bosque_flutter/domain/entities/movimiento_entity.dart';
import 'package:intl/intl.dart';

class ControlCombustibleReportesScreen extends ConsumerStatefulWidget {
  const ControlCombustibleReportesScreen({super.key});

  @override
  ConsumerState<ControlCombustibleReportesScreen> createState() =>
      _ControlCombustibleReportesScreenState();
}

class _ControlCombustibleReportesScreenState
    extends ConsumerState<ControlCombustibleReportesScreen> {
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 7));
  DateTime _fechaFin = DateTime.now();
  bool _hasSearched = false;
  int? _selectedSucursal;
  int? _selectedTipoContenedor;
  bool _isFiltersExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sucursalesProvider);
      ref.read(tipoContenedorProvider);
    });
  }

  void _cargarDatos() {
    setState(() {
      _hasSearched = true;
    });

    ref
        .read(controlCombustibleMaquinaMontacargaNotifierProvider.notifier)
        .cargarMovimientos(
          _fechaInicio,
          _fechaFin,
          _selectedSucursal ?? 0,
          _selectedTipoContenedor ?? 0,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      controlCombustibleMaquinaMontacargaNotifierProvider,
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Reportes de Movimientos',
          style: ResponsiveUtilsBosque.getTitleStyle(context),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body:
          isDesktop
              ? _buildDesktopLayout(context, state, colorScheme)
              : _buildMobileLayout(context, state, colorScheme),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    RegistroState state,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        // Panel de filtros lateral (izquierdo)
        Container(
          width: 350,
          height: double.infinity,
          color: colorScheme.surface,
          child: Column(children: [_buildFiltersSection(context, colorScheme)]),
        ),

        // Divisor vertical
        Container(width: 1, color: colorScheme.outline.withOpacity(0.3)),

        // Panel de resultados (derecho)
        Expanded(child: _buildResultsSection(context, state, colorScheme)),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    RegistroState state,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        // Filtros expandibles
        _buildFiltersSection(context, colorScheme),

        // Resultados
        Expanded(child: _buildResultsSection(context, state, colorScheme)),
      ],
    );
  }

  Widget _buildFiltersSection(BuildContext context, ColorScheme colorScheme) {
    final sucursalesAsync = ref.watch(sucursalesProvider);
    final tipoContenedorAsync = ref.watch(tipoContenedorProvider);
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    if (isDesktop) {
      // Layout de filtros para desktop (panel lateral)
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Filtros de Búsqueda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Fechas
            _buildDateFilters(colorScheme),
            const SizedBox(height: 20),

            // Dropdown de Sucursales
            _buildSucursalDropdown(sucursalesAsync, colorScheme),
            const SizedBox(height: 20),

            // Dropdown de Tipo de Contenedor
            _buildTipoContenedorDropdown(tipoContenedorAsync, colorScheme),
            const SizedBox(height: 24),

            // Botón de búsqueda
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cargarDatos,
                icon: const Icon(Icons.search),
                label: const Text('Buscar Movimientos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Layout de filtros para móvil (expansible)
      return Card(
        margin: const EdgeInsets.all(16),
        elevation: 4,
        child: ExpansionTile(
          title: Text(
            'Filtros de Búsqueda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          leading: Icon(Icons.filter_list, color: colorScheme.primary),
          initiallyExpanded: _isFiltersExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isFiltersExpanded = expanded;
            });
          },
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fechas
                  _buildDateFilters(colorScheme),
                  const SizedBox(height: 16),

                  // Dropdown de Sucursales
                  _buildSucursalDropdown(sucursalesAsync, colorScheme),
                  const SizedBox(height: 16),

                  // Dropdown de Tipo de Contenedor
                  _buildTipoContenedorDropdown(
                    tipoContenedorAsync,
                    colorScheme,
                  ),
                  const SizedBox(height: 16),

                  // Botón de búsqueda
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _cargarDatos,
                      icon: const Icon(Icons.search),
                      label: const Text('Buscar Movimientos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildResultsSection(
    BuildContext context,
    RegistroState state,
    ColorScheme colorScheme,
  ) {
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Presiona "Buscar" para ver los movimientos',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (state.movimientosStatus == FetchStatus.loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando movimientos...'),
          ],
        ),
      );
    }

    if (state.movimientosStatus == FetchStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error al cargar los datos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarDatos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final movimientos = state.movimientos;

    if (movimientos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron movimientos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta ajustar los filtros de búsqueda',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'o selecciona un rango de fechas diferente',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Vista responsiva: tabla para desktop, cards para móvil
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    if (isDesktop) {
      // Para desktop, mostrar directamente la tabla sin padding adicional
      return _buildDesktopTable(movimientos, colorScheme);
    } else {
      // Para móvil, mantener el diseño con header
      return Column(
        children: [
          // Header con contador
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.list, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Resultados: ${movimientos.length} movimientos encontrados',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Vista responsiva
          Expanded(child: _buildMobileCards(movimientos, colorScheme)),
        ],
      );
    }
  }

  Widget _buildDateFilters(ColorScheme colorScheme) {
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rango de Fechas',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),

        // En desktop, mantenemos las fechas en columna para el panel lateral
        // En móvil, usamos columna para pantallas pequeñas y fila para medianas
        if (isDesktop || ResponsiveUtilsBosque.isMobile(context))
          Column(
            children: [
              _buildDateField(
                label: 'Fecha Inicio',
                selectedDate: _fechaInicio,
                onDateSelected: (date) {
                  setState(() {
                    _fechaInicio = date;
                  });
                },
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 12),
              _buildDateField(
                label: 'Fecha Fin',
                selectedDate: _fechaFin,
                onDateSelected: (date) {
                  setState(() {
                    _fechaFin = date;
                  });
                },
                colorScheme: colorScheme,
              ),
            ],
          )
        else
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'Fecha Inicio',
                    selectedDate: _fechaInicio,
                    onDateSelected: (date) {
                      setState(() {
                        _fechaInicio = date;
                      });
                    },
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    label: 'Fecha Fin',
                    selectedDate: _fechaFin,
                    onDateSelected: (date) {
                      setState(() {
                        _fechaFin = date;
                      });
                    },
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime selectedDate,
    required Function(DateTime) onDateSelected,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              onDateSelected(date);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(selectedDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSucursalDropdown(
    AsyncValue<List<SucursalEntity>> sucursalesAsync,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sucursal',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        sucursalesAsync.when(
          data:
              (sucursales) => DropdownButtonFormField<int>(
                value: _selectedSucursal,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                hint: const Text('Seleccione sucursal'),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Seleccione sucursal'),
                  ),
                  ...sucursales
                      .where((sucursal) => sucursal.codSucursal != -1)
                      .map(
                        (sucursal) => DropdownMenuItem<int>(
                          value: sucursal.codSucursal,
                          child: Text(sucursal.nombre),
                        ),
                      ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSucursal = value;
                  });
                },
              ),
          loading:
              () => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Cargando sucursales...'),
                  ],
                ),
              ),
          error:
              (error, _) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.error),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error al cargar sucursales',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildTipoContenedorDropdown(
    AsyncValue<List<TipoContenedorEntity>> tipoContenedorAsync,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Combustible',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        tipoContenedorAsync.when(
          data:
              (tipos) => DropdownButtonFormField<int>(
                value: _selectedTipoContenedor,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                hint: const Text('Seleccione tipo de combustible'),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Seleccione contenedor'),
                  ),
                  ...tipos.map(
                    (tipo) => DropdownMenuItem<int>(
                      value: tipo.idTipo,
                      child: Text(tipo.tipo),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTipoContenedor = value;
                  });
                },
              ),
          loading:
              () => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Cargando tipos...'),
                  ],
                ),
              ),
          error:
              (error, _) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.error),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error al cargar tipos de contenedor',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(
    List<MovimientoEntity> movimientos,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        // Header con información - ocupando todo el ancho
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: colorScheme.primaryContainer),
          child: Row(
            children: [
              Icon(Icons.table_chart, color: colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                'Movimientos de Combustible (${movimientos.length} registros)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        // Tabla ocupando todo el espacio disponible
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
            ),
            child: Scrollbar(
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    horizontalMargin: 16,
                    headingRowHeight: 56,
                    dataRowHeight: 48,
                    headingRowColor: WidgetStatePropertyAll(
                      colorScheme.surfaceContainerHighest,
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Fecha',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Tipo',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Origen',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Destino',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Entrada (L)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Salida (L)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Saldo (L)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Empleado',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Observaciones',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows:
                        movimientos.map((movimiento) {
                          final tipoColor = _getTipoMovimientoColor(
                            movimiento.tipoMovimiento,
                          );

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  movimiento.fechaMovimientoString,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tipoColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: tipoColor),
                                  ),
                                  child: Text(
                                    movimiento.tipoMovimiento,
                                    style: TextStyle(
                                      color: tipoColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    movimiento.origen,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    movimiento.destino,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  movimiento.valorEntrada > 0
                                      ? movimiento.valorEntrada.toStringAsFixed(
                                        1,
                                      )
                                      : '-',
                                  style: TextStyle(
                                    color:
                                        movimiento.valorEntrada > 0
                                            ? Colors.green
                                            : colorScheme.onSurfaceVariant,
                                    fontWeight:
                                        movimiento.valorEntrada > 0
                                            ? FontWeight.bold
                                            : null,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  movimiento.valorSalida > 0
                                      ? movimiento.valorSalida.toStringAsFixed(
                                        1,
                                      )
                                      : '-',
                                  style: TextStyle(
                                    color:
                                        movimiento.valorSalida > 0
                                            ? Colors.red
                                            : colorScheme.onSurfaceVariant,
                                    fontWeight:
                                        movimiento.valorSalida > 0
                                            ? FontWeight.bold
                                            : null,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  movimiento.valorSaldo.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color:
                                        movimiento.valorSaldo > 0
                                            ? Colors.blue
                                            : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 140,
                                  child: Text(
                                    movimiento.nombreCompleto,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    movimiento.obs,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: const TextStyle(fontSize: 12),
                                  ),
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
      ],
    );
  }

  Widget _buildMobileCards(
    List<MovimientoEntity> movimientos,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: movimientos.length,
      itemBuilder:
          (context, index) =>
              _buildMovimientoMobileCard(movimientos[index], colorScheme),
    );
  }

  Widget _buildMovimientoMobileCard(
    MovimientoEntity movimiento,
    ColorScheme colorScheme,
  ) {
    final tipoColor = _getTipoMovimientoColor(movimiento.tipoMovimiento);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tipoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: tipoColor),
                  ),
                  child: Text(
                    movimiento.tipoMovimiento,
                    style: TextStyle(
                      color: tipoColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  movimiento.fechaMovimientoString,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildMovimientoMobileDetails(movimiento, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildMovimientoMobileDetails(
    MovimientoEntity movimiento,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Origen',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  Text(movimiento.origen, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Destino',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    movimiento.destino,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            if (movimiento.valorEntrada > 0) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entrada',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${movimiento.valorEntrada.toStringAsFixed(1)} L',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (movimiento.valorSalida > 0) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salida',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${movimiento.valorSalida.toStringAsFixed(1)} L',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${movimiento.valorSaldo.toStringAsFixed(1)} L',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Empleado',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    movimiento.nombreCompleto,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (movimiento.obs.isNotEmpty) ...[
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Observaciones',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              Text(movimiento.obs, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ],
    );
  }

  Color _getTipoMovimientoColor(String tipo) {
    switch (tipo) {
      case 'Entrada':
        return Colors.green;
      case 'Salida':
        return Colors.red;
      case 'Transferencia':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
