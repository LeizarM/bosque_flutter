import 'package:bosque_flutter/presentation/widgets/entregas/entrega_detalle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/web.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math'; // Para min y max

import 'package:bosque_flutter/core/state/chofer_provider.dart';
import 'package:bosque_flutter/core/state/entregas_provider.dart';
import 'package:bosque_flutter/domain/entities/chofer_entity.dart';
import 'package:bosque_flutter/domain/entities/entregas_entity.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class EntregasPorChoferContent extends ConsumerStatefulWidget {
  const EntregasPorChoferContent({Key? key}) : super(key: key);

  @override
  ConsumerState<EntregasPorChoferContent> createState() =>
      _EntregasPorChoferContentState();
}

class _EntregasPorChoferContentState
    extends ConsumerState<EntregasPorChoferContent> {
  DateTime selectedDate = DateTime.now();
  int? selectedChoferId;
  bool isLoading = false;
  bool isInitialState = true;

  final TextEditingController _dateController = TextEditingController();

  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(choferesProvider.notifier).loadChoferes();
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

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
    });

    ref
        .read(entregasNotifierProvider.notifier)
        .loadHistorialRuta(selectedDate, selectedChoferId!)
        .then((_) {
          setState(() {
            isLoading = false;
          });
        })
        .catchError((error) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar los datos: ${error.toString()}'),
            ),
          );
        });
  }

  String _formatDate(dynamic fecha) {
    if (fecha == null) return '-';
    try {
      if (fecha is String) {
        if (fecha.contains('/')) return fecha;
        return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(fecha));
      } else if (fecha is DateTime) {
        return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
      }
    } catch (e) {
      debugPrint('Error formateando fecha: $e');
    }
    return '-';
  }

  Color _getRowBackgroundColor(EntregaEntity entrega) {
    final colorScheme = Theme.of(context).colorScheme;
    if (entrega.docEntry == -1) {
      return colorScheme.tertiaryContainer.withOpacity(0.5);
    } else if (entrega.docEntry == 0) {
      return colorScheme.primaryContainer.withOpacity(0.5);
    } else {
      return colorScheme.surface;
    }
  }

  List<EntregaEntity> _getPaginatedData(List<EntregaEntity> allData) {
    if (allData.isEmpty) return [];
    final int totalPages = (allData.length / _itemsPerPage).ceil();
    // Asegurar que _currentPage esté en el rango válido
    final int safeCurrentPage = _currentPage.clamp(1, totalPages);
    final int startIndex = (safeCurrentPage - 1) * _itemsPerPage;
    // Si el startIndex es mayor que la cantidad de datos, devolver vacío
    if (startIndex >= allData.length) return [];
    final int endIndex = min(startIndex + _itemsPerPage, allData.length);
    return allData.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    final choferesState = ref.watch(choferesProvider);
    final entregasState = ref.watch(entregasNotifierProvider);
    final choferes = choferesState.choferes;
    final isLoadingChoferes = choferesState.status == ChoferesStatus.loading;
    final historialRuta = entregasState.historialRuta;

    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context),
        vertical: ResponsiveUtilsBosque.getVerticalPadding(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            _buildMobileFilters(isLoadingChoferes, choferes)
          else
            _buildDesktopFilters(isLoadingChoferes, choferes),
          SizedBox(height: 20),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : isInitialState
                    ? _buildInitialStateMessage()
                    : isMobile
                    ? _buildMobileTable(historialRuta)
                    : _buildPlutoGridTable(historialRuta),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilters(
    bool isLoadingChoferes,
    List<ChoferEntity> choferes,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _dateController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Ingrese Fecha',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null && picked != selectedDate) {
                  setState(() {
                    selectedDate = picked;
                    _dateController.text = DateFormat(
                      'dd/MM/yyyy',
                    ).format(selectedDate);
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          value: selectedChoferId,
          decoration: const InputDecoration(
            labelText: 'Chofer',
            border: OutlineInputBorder(),
          ),
          icon: const Icon(Icons.arrow_drop_down),
          isExpanded: true,
          hint: const Text('Seleccione un chofer'),
          items:
              isLoadingChoferes
                  ? [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Cargando...'),
                    ),
                  ]
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

  Widget _buildDesktopFilters(
    bool isLoadingChoferes,
    List<ChoferEntity> choferes,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _dateController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Ingrese Fecha',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null && picked != selectedDate) {
                    setState(() {
                      selectedDate = picked;
                      _dateController.text = DateFormat(
                        'dd/MM/yyyy',
                      ).format(selectedDate);
                    });
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
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
            items:
                isLoadingChoferes
                    ? [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Cargando...'),
                      ),
                    ]
                    : choferes.map((ChoferEntity chofer) {
                      return DropdownMenuItem<int>(
                        value: chofer.codEmpleado,
                        child: Text(
                          '${chofer.nombreCompleto} - ${chofer.cargo}',
                        ),
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
        ElevatedButton(
          onPressed: _buscarEntregas,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
          ),
          child: const Text('Buscar'),
        ),
      ],
    );
  }

  Widget _buildInitialStateMessage() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Seleccione un chofer y una fecha para ver las entregas',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildPlutoGridTable(List<EntregaEntity> historialRuta) {
    // Obtener solo los datos de la página actual
    final List<EntregaEntity> paginatedData = _getPaginatedData(historialRuta);
    final List<PlutoColumn> columns = <PlutoColumn>[
      PlutoColumn(
        title: 'Tipo',
        field: 'tipo',
        type: PlutoColumnType.text(),
        width: 80,
        enableRowChecked: false,
        enableContextMenu: false,
        enableDropToResize: true,
        enableColumnDrag: true,
        enableSorting: false,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Factura',
        field: 'factura',
        type: PlutoColumnType.text(),
        width: 100,
        enableContextMenu: false,
        enableDropToResize: true,
        enableColumnDrag: true,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Cliente',
        field: 'cliente',
        type: PlutoColumnType.text(),
        width: 170,
        enableContextMenu: false,
        enableDropToResize: true,
        enableColumnDrag: true,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Fecha Nota',
        field: 'fechaNota',
        type: PlutoColumnType.text(),
        width: 120,
        enableContextMenu: false,
        enableDropToResize: true,
        enableColumnDrag: true,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Fecha Entrega',
        field: 'fechaEntrega',
        type: PlutoColumnType.text(),
        width: 120,
        enableContextMenu: false,
        enableDropToResize: true,
        enableColumnDrag: true,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Dif. Min.',
        field: 'diferenciaMinutos',
        type: PlutoColumnType.text(),
        width: 80,
        textAlign: PlutoColumnTextAlign.right,
        enableContextMenu: false,
        enableDropToResize: true,
        enableColumnDrag: true,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Dirección',
        field: 'direccion',
        type: PlutoColumnType.text(),
        width: 200,
        enableContextMenu: false,
        enableDropToResize: true,
        enableColumnDrag: true,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Vendedor',
        field: 'vendedor',
        type: PlutoColumnType.text(),
        width: 120,
        enableContextMenu: false,
        enableDropToResize: true,
        enableColumnDrag: true,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Chofer',
        field: 'chofer',
        type: PlutoColumnType.text(),
        width: 120,
        enableContextMenu: false,
        enableDropToResize: true,
        enableColumnDrag: true,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Coche',
        field: 'coche',
        type: PlutoColumnType.text(),
        width: 100,
        enableContextMenu: false,
        enableDropToResize: true,
        enableColumnDrag: true,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Peso (KG)',
        field: 'peso',
        type: PlutoColumnType.text(),
        width: 80,
        textAlign: PlutoColumnTextAlign.right,
        enableContextMenu: false,
        enableDropToResize: true,
        enableColumnDrag: true,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Observaciones',
        field: 'observaciones',
        type: PlutoColumnType.text(),
        width: 150,
        enableContextMenu: false,
        enableDropToResize: true,
        enableColumnDrag: true,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Acciones',
        field: 'acciones',
        type: PlutoColumnType.text(),
        width: 90,
        enableContextMenu: false,
        enableDropToResize: true,
        enableColumnDrag: true,
        renderer: (rendererContext) {
          final int rowIdx = rendererContext.rowIdx;
          final int realIdx = rowIdx;
          final bool isValidIdx = realIdx >= 0 && realIdx < paginatedData.length;
          return Center(
            child: IconButton(
              icon: const Icon(
                Icons.remove_red_eye,
                size: 20,
              ),
              color: Theme.of(context).colorScheme.primary,
              onPressed: isValidIdx ? () {
                _onVerEntrega(paginatedData[realIdx]);
              } : null,
              tooltip: 'Ver detalles',
            ),
          );
        },
      ),
    ];
    // Key única para forzar el rebuild del grid al cambiar de página o tamaño de página
    final gridKey = ValueKey('plutoGrid_${_currentPage}_${_itemsPerPage}');
    return Column(
      children: [
        _createGridHeader(historialRuta.length),
        Expanded(
          child: PlutoGrid(
            key: gridKey,
            columns: columns,
            rows: _buildRows(paginatedData), // Usar solo los datos paginados
            rowColorCallback: (PlutoRowColorContext ctx) {
              final int rowIdx = ctx.rowIdx;
              if (rowIdx >= 0 && rowIdx < paginatedData.length) {
                final entrega = paginatedData[rowIdx];
                return _getRowBackgroundColor(entrega);
              }
              return Colors.transparent;
            },
            configuration: PlutoGridConfiguration(
              columnSize: const PlutoGridColumnSizeConfig(
                autoSizeMode: PlutoAutoSizeMode.scale,
                resizeMode: PlutoResizeMode.normal,
              ),
              style: PlutoGridStyleConfig(
                cellTextStyle: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
                columnTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
                gridBackgroundColor: Theme.of(context).colorScheme.surface,
                gridBorderColor: Theme.of(context).colorScheme.outlineVariant,
                gridBorderRadius: const BorderRadius.all(Radius.circular(8)),
                activatedBorderColor: Theme.of(context).colorScheme.primary,
                borderColor: Theme.of(context).colorScheme.outlineVariant,
                iconColor: Theme.of(context).colorScheme.primary,
                iconSize: 18,
                rowHeight: 46,
                activatedColor: Colors.transparent,
              ),
            ),
            mode: PlutoGridMode.normal,
            onLoaded: (PlutoGridOnLoadedEvent event) {
              event.stateManager.setSelectingMode(PlutoGridSelectingMode.none);
              event.stateManager.setShowColumnFilter(false);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                for (var column in event.stateManager.columns) {
                  double maxWidth = column.width;
                  final double titleWidth = _estimateTextWidth(
                    column.title,
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ) + 32;
                  maxWidth = max(maxWidth, titleWidth);
                  for (var row in event.stateManager.rows) {
                    final cellValue = row.cells[column.field]?.value?.toString() ?? '';
                    final double cellWidth = _estimateTextWidth(
                      cellValue,
                      const TextStyle(fontSize: 12),
                    ) + 16;
                    maxWidth = max(maxWidth, cellWidth);
                  }
                  event.stateManager.resizeColumn(
                    column,
                    min(maxWidth, 300),
                  );
                }
              });
            },
            onSelected: (PlutoGridOnSelectedEvent event) {
              if (event.row != null) {
                final idEntrega =
                    int.tryParse(event.row!.cells['id']?.value ?? '0') ?? 0;
                final entregaIdx = paginatedData.indexWhere(
                  (e) => e.idEntrega == idEntrega,
                );
                if (entregaIdx >= 0) {
                  setState(() {});
                }
              }
            },
          ),
        ),
        _createGridFooter(historialRuta),
      ],
    );
  }

  double _estimateTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      //textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.width;
  }

  List<PlutoRow> _buildRows(List<EntregaEntity> historialRuta) {
    return historialRuta.asMap().entries.map((entry) {
      final entrega = entry.value;
      return PlutoRow(
        cells: {
          'id': PlutoCell(value: entrega.idEntrega.toString()),
          'tipo': PlutoCell(value: entrega.tipo),
          'factura': PlutoCell(
            value: entrega.factura > 0 ? entrega.factura.toString() : '-',
          ),
          'cliente': PlutoCell(value: entrega.cardName),
          'fechaNota': PlutoCell(value: _formatDate(entrega.fechaNota)),
          'fechaEntrega': PlutoCell(
            value: _formatDate(entrega.fechaEntrega),
          ),
          'diferenciaMinutos': PlutoCell(
            value: entrega.diferenciaMinutos.toString(),
          ),
          'direccion': PlutoCell(
            value: entrega.direccionEntrega,
          ),
          'vendedor': PlutoCell(value: entrega.vendedor),
          'chofer': PlutoCell(value: entrega.nombreCompleto),
          'coche': PlutoCell(value: entrega.cochePlaca ?? '-'),
          'peso': PlutoCell(
            value: entrega.peso > 0 ? entrega.peso.toStringAsFixed(2) : '-',
          ),
          'observaciones': PlutoCell(value: entrega.obs),
          'acciones': PlutoCell(value: ''),
        },
      );
    }).toList();
  }

  Widget _createGridHeader(int totalRegistros) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Total de registros: $totalRegistros',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar datos',
            onPressed: selectedChoferId != null ? _buscarEntregas : null,
          ),
        ],
      ),
    );
  }

  Widget _createGridFooter(List<EntregaEntity> historialRuta) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalPages = (historialRuta.length / _itemsPerPage).ceil();
    final paginatedData = _getPaginatedData(historialRuta);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.surfaceVariant,
      child: Row(
        children: [
          Text(
            'Mostrando ${paginatedData.length} de ${historialRuta.length} registros',
            style: TextStyle(color: colorScheme.onSurface),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.first_page, color: colorScheme.primary),
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage = 1;
                    });
                  }
                : null,
            tooltip: 'Primera página',
          ),
          IconButton(
            icon: Icon(Icons.chevron_left, color: colorScheme.primary),
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            tooltip: 'Página anterior',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Página $_currentPage de $totalPages',
              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: colorScheme.primary),
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            tooltip: 'Página siguiente',
          ),
          IconButton(
            icon: Icon(Icons.last_page, color: colorScheme.primary),
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() {
                      _currentPage = totalPages;
                    });
                  }
                : null,
            tooltip: 'Última página',
          ),
          const SizedBox(width: 16),
          DropdownButton<int>(
            value: _itemsPerPage,
            dropdownColor: colorScheme.surface,
            items: [10, 25, 50, 100].map((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value por página', style: TextStyle(color: colorScheme.onSurface)),
              );
            }).toList(),
            onChanged: (int? newValue) {
              if (newValue != null) {
                setState(() {
                  _itemsPerPage = newValue;
                  _currentPage = 1;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  void _onVerEntrega(EntregaEntity entrega) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntregaDetalleScreen(entrega: entrega),
      ),
    );
  }

  Widget _buildMobileTable(List<EntregaEntity> historialRuta) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      itemCount: historialRuta.length,
      itemBuilder: (context, index) {
        final entrega = historialRuta[index];
        return Card(
          color: _getRowBackgroundColor(entrega),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(entrega.cardName ?? '-', style: TextStyle(color: colorScheme.onSurface)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Factura: ${entrega.factura > 0 ? entrega.factura.toString() : '-'}',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                Text('Fecha Entrega: ${_formatDate(entrega.fechaEntrega)}', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                Text(
                  'Dirección: ${entrega.direccionEntrega ?? entrega.addressEntregaFac ?? '-'}',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.remove_red_eye, color: colorScheme.primary),
              onPressed: () => _onVerEntrega(entrega),
            ),
          ),
        );
      },
    );
  }
}
