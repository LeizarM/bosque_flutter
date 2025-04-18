import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bosque_flutter/core/state/chofer_provider.dart';
import 'package:bosque_flutter/core/state/entregas_provider.dart';
import 'package:bosque_flutter/domain/entities/chofer_entity.dart';
import 'package:bosque_flutter/domain/entities/entregas_entity.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';

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
  int? _selectedRowIndex;

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
      _selectedRowIndex = null;
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
    if (entrega.prioridad == 'Alta') {
      return Colors.orange.shade100;
    } else if (entrega.docEntry == -1) {
      return Colors.blue.shade100;
    } else if (entrega.docEntry == 0) {
      return Colors.green.shade100;
    } else if (entrega.flag == -1) {
      return Colors.red.shade100;
    }
    return Colors.transparent;
  }

  List<EntregaEntity> _getPaginatedData(List<EntregaEntity> allData) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, allData.length);
    if (startIndex >= allData.length) return [];
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

  Widget _buildPlutoGridTable(List<EntregaEntity> historialRuta) {
    final List<PlutoColumn> columns = <PlutoColumn>[
      PlutoColumn(
        title: 'Tipo',
        field: 'tipo',
        type: PlutoColumnType.text(),
        width: 80,
        enableRowChecked: false,
        enableContextMenu: false,
        enableDropToResize: false,
        enableColumnDrag: false,
        enableSorting: true,
      ),
      PlutoColumn(
        title: 'Factura',
        field: 'factura',
        type: PlutoColumnType.text(),
        width: 100,
        enableContextMenu: false,
        enableDropToResize: false,
        enableColumnDrag: false,
      ),
      PlutoColumn(
        title: 'Cliente',
        field: 'cliente',
        type: PlutoColumnType.text(),
        width: 170,
        enableContextMenu: false,
        enableDropToResize: false,
        enableColumnDrag: false,
      ),
      PlutoColumn(
        title: 'Fecha Nota',
        field: 'fechaNota',
        type: PlutoColumnType.text(),
        width: 120,
        enableContextMenu: false,
        enableDropToResize: false,
        enableColumnDrag: false,
      ),
      PlutoColumn(
        title: 'Fecha Entrega',
        field: 'fechaEntrega',
        type: PlutoColumnType.text(),
        width: 120,
        enableContextMenu: false,
        enableDropToResize: false,
        enableColumnDrag: false,
      ),
      PlutoColumn(
        title: 'Dif. Min.',
        field: 'diferenciaMinutos',
        type: PlutoColumnType.text(),
        width: 80,
        textAlign: PlutoColumnTextAlign.right,
        enableContextMenu: false,
        enableDropToResize: false,
        enableColumnDrag: false,
      ),
      PlutoColumn(
        title: 'Dirección',
        field: 'direccion',
        type: PlutoColumnType.text(),
        width: 200,
        enableContextMenu: false,
        enableDropToResize: false,
        enableColumnDrag: false,
      ),
      PlutoColumn(
        title: 'Vendedor',
        field: 'vendedor',
        type: PlutoColumnType.text(),
        width: 120,
        enableContextMenu: false,
        enableDropToResize: false,
        enableColumnDrag: false,
      ),
      PlutoColumn(
        title: 'Chofer',
        field: 'chofer',
        type: PlutoColumnType.text(),
        width: 120,
        enableContextMenu: false,
        enableDropToResize: false,
        enableColumnDrag: false,
      ),
      PlutoColumn(
        title: 'Coche',
        field: 'coche',
        type: PlutoColumnType.text(),
        width: 100,
        enableContextMenu: false,
        enableDropToResize: false,
        enableColumnDrag: false,
      ),
      PlutoColumn(
        title: 'Peso (KG)',
        field: 'peso',
        type: PlutoColumnType.text(),
        width: 80,
        textAlign: PlutoColumnTextAlign.right,
        enableContextMenu: false,
        enableDropToResize: false,
        enableColumnDrag: false,
      ),
      PlutoColumn(
        title: 'Observaciones',
        field: 'observaciones',
        type: PlutoColumnType.text(),
        width: 150,
        enableContextMenu: false,
        enableDropToResize: false,
        enableColumnDrag: false,
      ),
      PlutoColumn(
        title: 'Acciones',
        field: 'acciones',
        type: PlutoColumnType.text(),
        width: 90,
        enableContextMenu: false,
        enableDropToResize: false,
        enableColumnDrag: false,
        renderer: (rendererContext) {
          return Center(
            child: IconButton(
              icon: const Icon(
                Icons.remove_red_eye,
                color: Colors.blue,
                size: 20,
              ),
              onPressed: () {
                final entregaIdx = historialRuta.indexWhere(
                  (e) =>
                      e.idEntrega.toString() ==
                      rendererContext.row.cells['id']?.value,
                );

                if (entregaIdx >= 0) {
                  _onVerEntrega(historialRuta[entregaIdx]);
                }
              },
              tooltip: 'Ver detalles',
            ),
          );
        },
      ),
    ];

    final rows =
        historialRuta.asMap().entries.map((entry) {
          final entrega = entry.value;
          return PlutoRow(
            cells: {
              'id': PlutoCell(value: entrega.idEntrega.toString()),
              'tipo': PlutoCell(
                value:
                    entrega.tipo ??
                    (entrega.cardName != null &&
                            entrega.cardName!.contains("Inicio")
                        ? "Inicio"
                        : entrega.cardName != null &&
                            entrega.cardName!.contains("Fin")
                        ? "Fin"
                        : "-"),
              ),
              'factura': PlutoCell(
                value: entrega.factura > 0 ? entrega.factura.toString() : '-',
              ),
              'cliente': PlutoCell(value: entrega.cardName ?? '-'),
              'fechaNota': PlutoCell(value: _formatDate(entrega.fechaNota)),
              'fechaEntrega': PlutoCell(
                value: _formatDate(entrega.fechaEntrega),
              ),
              'diferenciaMinutos': PlutoCell(
                value: entrega.diferenciaMinutos?.toString() ?? '0',
              ),
              'direccion': PlutoCell(
                value:
                    entrega.direccionEntrega ??
                    entrega.addressEntregaFac ??
                    '-',
              ),
              'vendedor': PlutoCell(value: entrega.vendedor ?? '-'),
              'chofer': PlutoCell(value: entrega.nombreCompleto ?? '-'),
              'coche': PlutoCell(value: entrega.cochePlaca ?? '-'),
              'peso': PlutoCell(
                value: entrega.peso > 0 ? entrega.peso.toStringAsFixed(2) : '-',
              ),
              'observaciones': PlutoCell(value: entrega.obs ?? '-'),
              'acciones': PlutoCell(value: ''),
            },
          );
        }).toList();

    return Column(
      children: [
        _createGridHeader(historialRuta.length),
        Expanded(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            rowColorCallback: (PlutoRowColorContext ctx) {
              final idEntrega =
                  int.tryParse(ctx.row.cells['id']?.value ?? '0') ?? 0;
              final entregaIdx = historialRuta.indexWhere(
                (e) => e.idEntrega == idEntrega,
              );
              if (entregaIdx >= 0) {
                final entrega = historialRuta[entregaIdx];
                return _getRowBackgroundColor(entrega);
              }
              return Colors.transparent;
            },
            configuration: PlutoGridConfiguration(
              columnSize: const PlutoGridColumnSizeConfig(
                autoSizeMode: PlutoAutoSizeMode.scale,
              ),
              style: PlutoGridStyleConfig(
                cellTextStyle: const TextStyle(fontSize: 12),
                columnTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                gridBackgroundColor: Colors.white,
                gridBorderColor: Colors.grey.shade300,
                gridBorderRadius: BorderRadius.circular(8),
                activatedBorderColor: Theme.of(context).colorScheme.primary,
                borderColor: Colors.grey.shade300,
                iconColor: Theme.of(context).colorScheme.primary,
                iconSize: 18,
                rowHeight: 46,
              ),
            ),
            onLoaded: (PlutoGridOnLoadedEvent event) {
              event.stateManager.setSelectingMode(PlutoGridSelectingMode.row);
              event.stateManager.setShowColumnFilter(false);
            },
            onSelected: (PlutoGridOnSelectedEvent event) {
              if (event.row != null) {
                final idEntrega =
                    int.tryParse(event.row!.cells['id']?.value ?? '0') ?? 0;
                final entregaIdx = historialRuta.indexWhere(
                  (e) => e.idEntrega == idEntrega,
                );
                if (entregaIdx >= 0) {
                  setState(() {
                    _selectedRowIndex = entregaIdx;
                  });
                }
              }
            },
          ),
        ),
        _createGridFooter(historialRuta),
      ],
    );
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
    final totalPages = (historialRuta.length / _itemsPerPage).ceil();
    final paginatedData = _getPaginatedData(historialRuta);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Text(
            'Mostrando ${paginatedData.length} de ${historialRuta.length} registros',
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed:
                _currentPage > 1
                    ? () => setState(() {
                      _currentPage = 1;
                      _selectedRowIndex = null;
                    })
                    : null,
            tooltip: 'Primera página',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                _currentPage > 1
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
            onPressed:
                _currentPage < totalPages
                    ? () => setState(() {
                      _currentPage++;
                      _selectedRowIndex = null;
                    })
                    : null,
            tooltip: 'Página siguiente',
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed:
                _currentPage < totalPages
                    ? () => setState(() {
                      _currentPage = totalPages;
                      _selectedRowIndex = null;
                    })
                    : null,
            tooltip: 'Última página',
          ),
          const SizedBox(width: 16),
          DropdownButton<int>(
            value: _itemsPerPage,
            items:
                [10, 25, 50, 100].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value por página'),
                  );
                }).toList(),
            onChanged: (int? newValue) {
              if (newValue != null) {
                setState(() {
                  _itemsPerPage = newValue;
                  _currentPage = 1;
                  _selectedRowIndex = null;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  void _onVerEntrega(EntregaEntity entrega) {
    // Verificar si tiene coordenadas válidas para mostrar en el mapa
    final bool tieneUbicacion = entrega.latitud != 0 && entrega.longitud != 0;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                    _buildDetailItem(
                      'Fecha Nota',
                      _formatDate(entrega.fechaNota),
                    ),
                  if (entrega.fechaEntrega != null)
                    _buildDetailItem(
                      'Fecha Entrega',
                      _formatDate(entrega.fechaEntrega),
                    ),
                  if ((entrega.direccionEntrega != null &&
                          entrega.direccionEntrega!.isNotEmpty) ||
                      (entrega.addressEntregaFac != null &&
                          entrega.addressEntregaFac!.isNotEmpty))
                    _buildDetailItem(
                      'Dirección',
                      entrega.direccionEntrega != null &&
                              entrega.direccionEntrega!.isNotEmpty
                          ? entrega.direccionEntrega!
                          : entrega.addressEntregaFac!,
                    ),
                  if (entrega.obs != null && entrega.obs!.isNotEmpty)
                    _buildDetailItem('Observaciones', entrega.obs!),
                  if (entrega.vendedor != null && entrega.vendedor!.isNotEmpty)
                    _buildDetailItem('Vendedor', entrega.vendedor!),
                  if (entrega.peso > 0)
                    _buildDetailItem(
                      'Peso',
                      '${entrega.peso.toStringAsFixed(2)} kg',
                    ),

                  // Mostrar información de ubicación si está disponible
                  if (tieneUbicacion) ...[
                    const Divider(height: 24),
                    const Text(
                      'Ubicación de entrega',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Latitud: ${entrega.latitud.toStringAsFixed(6)}\nLongitud: ${entrega.longitud.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildMapPreview(entrega),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (tieneUbicacion)
                TextButton(
                  onPressed: () => _abrirMapaExterno(entrega),
                  child: const Text('Ver en Google Maps'),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  // Widget para mostrar un preview del mapa
  Widget _buildMapPreview(EntregaEntity entrega) {
    // Aquí utilizarías un widget de mapa como google_maps_flutter
    // Por ahora, mostraremos una representación visual simple
    return Stack(
      children: [
        // Fondo gris claro para representar el mapa
        Container(color: Colors.grey.shade200),
        // Marcador central
        Center(
          child: Icon(
            Icons.location_on,
            color: Theme.of(context).colorScheme.primary,
            size: 40,
          ),
        ),
        // Información de la ubicación
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.white.withOpacity(0.8),
            child: Text(
              entrega.direccionEntrega ??
                  entrega.addressEntregaFac ??
                  'Ubicación de entrega',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  // Método para abrir la ubicación en Google Maps
  void _abrirMapaExterno(EntregaEntity entrega) async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${entrega.latitud},${entrega.longitud}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('No se pudo abrir el mapa: $uri');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el mapa')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al abrir el mapa: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir el mapa: ${e.toString()}')),
        );
      }
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14)),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildMobileTable(List<EntregaEntity> historialRuta) {
    return ListView.builder(
      itemCount: historialRuta.length,
      itemBuilder: (context, index) {
        final entrega = historialRuta[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(entrega.cardName ?? '-'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Factura: ${entrega.factura > 0 ? entrega.factura.toString() : '-'}',
                ),
                Text('Fecha Entrega: ${_formatDate(entrega.fechaEntrega)}'),
                Text(
                  'Dirección: ${entrega.direccionEntrega ?? entrega.addressEntregaFac ?? '-'}',
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
              onPressed: () => _onVerEntrega(entrega),
            ),
          ),
        );
      },
    );
  }
}
