import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:bosque_flutter/domain/entities/entregas_entity.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/state/entregas_provider.dart';

class EntregasDashboardContent extends ConsumerStatefulWidget {
  const EntregasDashboardContent({Key? key}) : super(key: key);

  @override
  ConsumerState<EntregasDashboardContent> createState() => _EntregasDashboardContentState();
}

class _EntregasDashboardContentState extends ConsumerState<EntregasDashboardContent> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  bool _loading = false;
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fechaInicio = DateTime(now.year, now.month, 1);
    _fechaFin = now;
  }

  Future<void> _pickDate(BuildContext context, bool isInicio) async {
    final initialDate = isInicio ? _fechaInicio ?? DateTime.now() : _fechaFin ?? DateTime.now();
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2100);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        if (isInicio) {
          _fechaInicio = picked;
        } else {
          _fechaFin = picked;
        }
      });
    }
  }

  Future<void> _actualizarExtracto() async {
    if (_fechaInicio == null || _fechaFin == null) return;
    setState(() {
      _loading = true;
      _currentPage = 1; // Reiniciar a la primera página al actualizar
    });
    await ref.read(entregasNotifierProvider.notifier).cargarExtractoChoferes(_fechaInicio!, _fechaFin!);
    setState(() => _loading = false);
  }

  List<EntregaEntity> _getPaginatedData(List<EntregaEntity> allData) {
    if (allData.isEmpty) return [];
    final int totalPages = (allData.length / _itemsPerPage).ceil();
    // Si la página actual está fuera de rango, vuelve a la primera página automáticamente
    if (_currentPage > totalPages && totalPages > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() { _currentPage = 1; });
      });
      return allData.sublist(0, _itemsPerPage.clamp(0, allData.length));
    }
    final int safeCurrentPage = _currentPage.clamp(1, totalPages == 0 ? 1 : totalPages);
    final int startIndex = (safeCurrentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage).clamp(0, allData.length);
    return allData.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(entregasNotifierProvider);
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final isTablet = ResponsiveUtilsBosque.isTablet(context);
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final colorScheme = Theme.of(context).colorScheme;

    // Filtros responsivos
    Widget filtros = isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      controller: TextEditingController(text: _fechaInicio != null ? _dateFormat.format(_fechaInicio!) : ''),
                      decoration: const InputDecoration(
                        labelText: 'Fecha Inicio',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () => _pickDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      controller: TextEditingController(text: _fechaFin != null ? _dateFormat.format(_fechaFin!) : ''),
                      decoration: const InputDecoration(
                        labelText: 'Fecha Fin',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () => _pickDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Actualizar'),
                onPressed: _loading ? null : _actualizarExtracto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  controller: TextEditingController(text: _fechaInicio != null ? _dateFormat.format(_fechaInicio!) : ''),
                  decoration: const InputDecoration(
                    labelText: 'Fecha Inicio',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _pickDate(context, true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  controller: TextEditingController(text: _fechaFin != null ? _dateFormat.format(_fechaFin!) : ''),
                  decoration: const InputDecoration(
                    labelText: 'Fecha Fin',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _pickDate(context, false),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 160,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Actualizar'),
                    onPressed: _loading ? null : _actualizarExtracto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
              ),
            ],
          );

    // Resumen responsivo
    final total = state.entregas.where((e) => e.flag != -1).length;
    final completadas = state.entregas.where((e) =>  e.flag == 1 ).length;
    final porcentaje = total > 0 ? (completadas / total * 100).toStringAsFixed(1) : '0.0';
    Widget resumen = isMobile
        ? Column(
            children: [
              Card(
                color: colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.local_shipping, size: 32, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Rutas', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                          Text('$total', style: TextStyle(fontSize: 22, color: colorScheme.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                color: colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 32, color: colorScheme.secondary),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Completadas', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                          Text('$completadas', style: TextStyle(fontSize: 22, color: colorScheme.secondary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: Card(
                  color: colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Rutas', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                              const SizedBox(height: 8),
                              Text('$total', style: TextStyle(fontSize: 28, color: colorScheme.primary)),
                              const SizedBox(height: 4),
                              Text('$completadas completadas', style: TextStyle(color: colorScheme.secondary)),
                            ],
                          ),
                        ),
                        Icon(Icons.local_shipping, color: colorScheme.primary, size: 36),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  color: colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Estado de Rutas', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                              const SizedBox(height: 8),
                              Text('$porcentaje% Completado', style: TextStyle(fontSize: 24, color: colorScheme.primary)),
                            ],
                          ),
                        ),
                        Icon(Icons.check_circle, color: colorScheme.secondary, size: 36),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );

    // Tabla responsiva y paginación
    Widget tablaResponsive;
    if (isDesktop || isTablet) {
      final paginatedData = _getPaginatedData(state.entregas);
      final gridKey = ValueKey('plutoGrid_${_currentPage}_$_itemsPerPage');
      final columns = <PlutoColumn>[
        PlutoColumn(title: '#', field: 'num', type: PlutoColumnType.text(), enableEditingMode: false),
        PlutoColumn(title: 'Chofer', field: 'chofer', type: PlutoColumnType.text(), enableEditingMode: false),
        PlutoColumn(title: 'Ruta Diaria', field: 'ruta', type: PlutoColumnType.text(), enableEditingMode: false),
        PlutoColumn(title: 'Fecha', field: 'fecha', type: PlutoColumnType.text(), enableEditingMode: false),
        PlutoColumn(title: 'Hora Inicio', field: 'inicio', type: PlutoColumnType.text(), enableEditingMode: false),
        PlutoColumn(title: 'Hora Fin', field: 'fin', type: PlutoColumnType.text(), enableEditingMode: false),
        PlutoColumn(title: 'Estado', field: 'estado', type: PlutoColumnType.text(), enableEditingMode: false),
      ];
      final rows = paginatedData.asMap().entries.map((entry) {
        final i = entry.key;
        final e = entry.value;
        final estado = e.fueEntregado == 1
            ? (e.obsF.toLowerCase().contains('sistema') ? 'Completado Por Sistema' : 'Completo')
            : 'Incompleto o en ruta';
        return PlutoRow(cells: {
          'num': PlutoCell(value: (_currentPage - 1) * _itemsPerPage + i + 1),
          'chofer': PlutoCell(value: e.nombreCompleto ?? ''),
          'ruta': PlutoCell(value: e.rutaDiaria.toString()),
          'fecha': PlutoCell(value: e.fechaEntregaCad ?? ''),
          'inicio': PlutoCell(value: e.fechaInicioRutaCad ?? ''),
          'fin': PlutoCell(value: e.fechaFinRutaCad ?? ''),
          'estado': PlutoCell(value: e.estatusRuta),
        });
      }).toList();
      tablaResponsive = Column(
        children: [
          Expanded(
            child: paginatedData.isEmpty
                ? Center(child: Text('No hay datos para mostrar en esta página', style: TextStyle(color: colorScheme.onSurface)))
                : PlutoGrid(
                    key: gridKey,
                    columns: columns,
                    rows: rows,
                    configuration: PlutoGridConfiguration(
                      columnSize: PlutoGridColumnSizeConfig(
                        autoSizeMode: PlutoAutoSizeMode.scale,
                      ),
                      style: PlutoGridStyleConfig(
                        cellTextStyle: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                        columnTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.primary),
                        gridBackgroundColor: colorScheme.surface,
                        activatedColor: Colors.transparent,
                        rowHeight: 44,
                      ),
                    ),
                    mode: PlutoGridMode.readOnly,
                    onLoaded: (event) {
                      event.stateManager.setShowColumnFilter(false);
                    },
                    rowColorCallback: (ctx) {
                      final estado = ctx.row.cells['estado']?.value;
                      if (estado == 'Completo') return colorScheme.primary.withOpacity(0.08);
                      if (estado == 'Completado Por Sistema') return colorScheme.error.withOpacity(0.08);
                      return colorScheme.tertiary.withOpacity(0.08);
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                Text('Página $_currentPage de ${(state.entregas.length / _itemsPerPage).ceil()}', style: TextStyle(color: colorScheme.onSurface)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.first_page, color: colorScheme.primary),
                  onPressed: _currentPage > 1 ? () => setState(() => _currentPage = 1) : null,
                ),
                IconButton(
                  icon: Icon(Icons.chevron_left, color: colorScheme.primary),
                  onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: colorScheme.primary),
                  onPressed: _currentPage < (state.entregas.length / _itemsPerPage).ceil() ? () => setState(() => _currentPage++) : null,
                ),
                IconButton(
                  icon: Icon(Icons.last_page, color: colorScheme.primary),
                  onPressed: _currentPage < (state.entregas.length / _itemsPerPage).ceil() ? () => setState(() => _currentPage = (state.entregas.length / _itemsPerPage).ceil()) : null,
                ),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _itemsPerPage,
                  dropdownColor: colorScheme.surface,
                  items: [10, 25, 50, 100].map((e) => DropdownMenuItem(value: e, child: Text('$e por página', style: TextStyle(color: colorScheme.onSurface)))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() { _itemsPerPage = v; _currentPage = 1; });
                  },
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Tabla móvil con paginación, scroll vertical y footer en columna para evitar overflow
      final paginatedData = _getPaginatedData(state.entregas);
      final totalPages = (state.entregas.length / _itemsPerPage).ceil();
      final startIndex = ((_currentPage - 1) * _itemsPerPage) + 1;
      final endIndex = (_currentPage * _itemsPerPage).clamp(0, state.entregas.length);
      tablaResponsive = Column(
        children: [
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('#', style: TextStyle(color: colorScheme.primary))),
                      DataColumn(label: Text('Chofer', style: TextStyle(color: colorScheme.onSurface))),
                      DataColumn(label: Text('Ruta', style: TextStyle(color: colorScheme.onSurface))),
                      DataColumn(label: Text('Fecha', style: TextStyle(color: colorScheme.onSurface))),
                      DataColumn(label: Text('Inicio', style: TextStyle(color: colorScheme.onSurface))),
                      DataColumn(label: Text('Fin', style: TextStyle(color: colorScheme.onSurface))),
                      DataColumn(label: Text('Estado', style: TextStyle(color: colorScheme.onSurface))),
                    ],
                    rows: paginatedData.asMap().entries.map((entry) {
                      final i = entry.key;
                      final e = entry.value;
                      final estado = e.fueEntregado == 1
                          ? (e.obsF.toLowerCase().contains('sistema') ? 'Completado Por Sistema' : 'Completo')
                          : 'Incompleto o en ruta';
                      final color = estado == 'Completo'
                          ? colorScheme.primary
                          : estado == 'Completado Por Sistema'
                              ? colorScheme.error
                              : colorScheme.tertiary;
                      return DataRow(cells: [
                        DataCell(Text(((_currentPage - 1) * _itemsPerPage + i + 1).toString(), style: TextStyle(color: colorScheme.primary))),
                        DataCell(Text(e.nombreCompleto ?? '', style: TextStyle(color: colorScheme.onSurface))),
                        DataCell(Text(e.rutaDiaria.toString(), style: TextStyle(color: colorScheme.onSurface))),
                        DataCell(Text(_dateFormat.format(e.fechaEntrega), style: TextStyle(color: colorScheme.onSurface))),
                        DataCell(Text(e.fechaInicioRutaCad ?? '', style: TextStyle(color: colorScheme.onSurface))),
                        DataCell(Text(e.fechaFinRutaCad ?? '', style: TextStyle(color: colorScheme.onSurface))),
                        DataCell(Text(estado, style: TextStyle(color: color))),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          // Footer de paginación en móvil, en columna para evitar overflow
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              children: [
                Text('Mostrando $startIndex - $endIndex de ${state.entregas.length} registros', style: TextStyle(color: colorScheme.onSurface)),
                Text('Página $_currentPage de $totalPages', style: TextStyle(color: colorScheme.primary)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.first_page, color: colorScheme.primary),
                      onPressed: _currentPage > 1 ? () => setState(() => _currentPage = 1) : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: colorScheme.primary),
                      onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: colorScheme.primary),
                      onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.last_page, color: colorScheme.primary),
                      onPressed: _currentPage < totalPages ? () => setState(() => _currentPage = totalPages) : null,
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _itemsPerPage,
                      dropdownColor: colorScheme.surface,
                      items: [10, 25, 50, 100].map((e) => DropdownMenuItem(value: e, child: Text('$e por página', style: TextStyle(color: colorScheme.onSurface)))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() { _itemsPerPage = v; _currentPage = 1; });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Estructura principal sin SingleChildScrollView global
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        filtros,
        const SizedBox(height: 12),
        resumen,
        const SizedBox(height: 16),
        Expanded(child: tablaResponsive),
      ],
    );
  }
}