import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/depositos_cheques_provider.dart';
import '../../../core/utils/responsive_utils_bosque.dart';

class DepositoChequeIdentificarViewScreen extends ConsumerStatefulWidget {
  const DepositoChequeIdentificarViewScreen({super.key});

  @override
  ConsumerState<DepositoChequeIdentificarViewScreen> createState() => _DepositoChequeIdentificarViewScreenState();
}

class _DepositoChequeIdentificarViewScreenState extends ConsumerState<DepositoChequeIdentificarViewScreen> {
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  final TextEditingController _fechaDesdeController = TextEditingController();
  final TextEditingController _fechaHastaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inicializar con fechas predeterminadas
    _fechaDesdeController.text = "01/05/2025";
    _fechaHastaController.text = "31/05/2025";
  }

  @override
  void dispose() {
    _fechaDesdeController.dispose();
    _fechaHastaController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isDesde) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDesde ? (_fechaDesde ?? DateTime.now()) : (_fechaHasta ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDesde) {
          _fechaDesde = picked;
          _fechaDesdeController.text = _formatDate(picked);
        } else {
          _fechaHasta = picked;
          _fechaHastaController.text = _formatDate(picked);
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(depositosChequesProvider);
    final notifier = ref.read(depositosChequesProvider.notifier);
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final isTablet = ResponsiveUtilsBosque.isTablet(context);
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    
    // Usar padding mínimo para maximizar espacio
    final horizontalPadding = isMobile 
        ? ResponsiveUtilsBosque.getHorizontalPadding(context) 
        : 2.0; // Aún menor para maximizar espacio en desktop
    
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Depósitos por Identificar', style: ResponsiveUtilsBosque.getTitleStyle(context)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección de búsqueda con padding adecuado
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 0 : 2.0, // Menor padding para el formulario
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchHeader(context),
                    const SizedBox(height: 12),
                    _buildSearchForm(context),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Tabla expandida
              Expanded(
                child: _DepositosIdentificarTable(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.search, color: Color(0xFF6C63FF)),
        const SizedBox(width: 8),
        Text(
          'Criterios de Búsqueda',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSearchForm(BuildContext context) {
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    
    // Versión móvil - layout vertical
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _fechaDesdeController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Desde',
              prefixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(),
            ),
            onTap: () => _pickDate(context, true),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fechaHastaController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Hasta',
              prefixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(),
            ),
            onTap: () => _pickDate(context, false),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text('Buscar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () {
              // Solo buscar por fechas, idBxC=0 y codCliente vacio
              ref.read(depositosChequesProvider.notifier).buscarDepositosPorIdentificar(
                idBxC: 0,
                fechaDesde: _fechaDesde,
                fechaHasta: _fechaHasta,
                codCliente: '',
              );
            },
          ),
        ],
      );
    }

    // Versión desktop - layout como en la imagen
    return Row(
      children: [
        // Campo Desde con etiqueta arriba
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Desde'),
            const SizedBox(height: 4),
            SizedBox(
              width: 300,
              child: TextFormField(
                controller: _fechaDesdeController,
                readOnly: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _pickDate(context, true),
                  ),
                ),
                onTap: () => _pickDate(context, true),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        // Campo Hasta con etiqueta arriba
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hasta'),
            const SizedBox(height: 4),
            SizedBox(
              width: 300,
              child: TextFormField(
                controller: _fechaHastaController,
                readOnly: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _pickDate(context, false),
                  ),
                ),
                onTap: () => _pickDate(context, false),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        // Botón de búsqueda redondeado
        ElevatedButton.icon(
          icon: const Icon(Icons.search),
          label: const Text('Buscar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          onPressed: () {
            // Solo buscar por fechas, idBxC=0 y codCliente vacio
            ref.read(depositosChequesProvider.notifier).buscarDepositosPorIdentificar(
              idBxC: 0,
              fechaDesde: _fechaDesde,
              fechaHasta: _fechaHasta,
              codCliente: '',
            );
          },
        ),
      ],
    );
  }
}

class _DepositosIdentificarTable extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(depositosChequesProvider);
    final notifier = ref.read(depositosChequesProvider.notifier);
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final isTablet = ResponsiveUtilsBosque.isTablet(context);
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final depositos = state.depositos;
    final page = state.page;
    final rowsPerPage = state.rowsPerPage;
    final total = state.totalRegistros;
    final start = total == 0 ? 0 : (page * rowsPerPage) + 1;
    final end = ((page + 1) * rowsPerPage).clamp(0, total);
    final paged = depositos.skip(page * rowsPerPage).take(rowsPerPage).toList();

    if (depositos.isEmpty) {
      return Center(
        child: Text('No hay depósitos pendientes por identificar', style: Theme.of(context).textTheme.bodyLarge),
      );
    }

    // Mostrar lista en móvil en lugar de tabla
    if (isMobile) {
      return Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: paged.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final d = paged[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ID: ${d.idDeposito}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            _EstadoChip(estado: d.esPendiente),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('Cliente', d.codCliente),
                        _buildInfoRow('Empresa', d.nombreEmpresa),
                        _buildInfoRow('Banco', d.nombreBanco),
                        _buildInfoRow('Importe', '${d.importe.toStringAsFixed(2)} ${d.moneda}'),
                        _buildInfoRow('Fecha', d.fechaI != null 
                          ? "${d.fechaI!.day.toString().padLeft(2, '0')}/${d.fechaI!.month.toString().padLeft(2, '0')}/${d.fechaI!.year}" 
                          : ''),
                        if (d.obs.isNotEmpty) _buildInfoRow('Observaciones', d.obs),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.vpn_key, color: Colors.orange),
                              tooltip: 'Identificar',
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.indigo),
                              tooltip: 'Copiar',
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildMobilePagination(context, start, end, total, page, notifier, rowsPerPage),
        ],
      );
    }

    // Resolver el problema de la columna de Observaciones en modo desktop con mejor espaciado
    return LayoutBuilder(
      builder: (context, constraints) {
        final paginacionHeight = 60.0;
        final tablaHeight = constraints.maxHeight - paginacionHeight;
        
        if (isDesktop) {
          // Para desktop - usaremos scroll horizontal con anchos de columna adaptados 
          return Column(
            children: [
              SizedBox(
                height: tablaHeight > 0 ? tablaHeight : 0,
                child: _buildOptimizedScrollableTable(paged, constraints.maxWidth),
              ),
              SizedBox(
                height: paginacionHeight,
                child: _buildDesktopPagination(context, start, end, total, page, notifier, rowsPerPage),
              ),
            ],
          );
        } else {
          // Para tablet - con scrolling horizontal
          return Column(
            children: [
              SizedBox(
                height: tablaHeight > 0 ? tablaHeight : 0,
                child: _buildTabletScrollableTable(paged, constraints.maxWidth),
              ),
              SizedBox(
                height: paginacionHeight,
                child: _buildDesktopPagination(context, start, end, total, page, notifier, rowsPerPage),
              ),
            ],
          );
        }
      },
    );
  }

  // Tabla optimizada para desktop con scroll horizontal pero columnas con mejor espaciado
  Widget _buildOptimizedScrollableTable(List<dynamic> paged, double maxWidth) {
    // Definimos anchos específicos para cada columna para controlar mejor el espacio
    final Map<String, double> columnWidths = {
      'ID': 60,
      'Cliente': 90,
      'Empresa': 90,
      'Banco': 200,
      'Importe': 90,
      'Moneda': 60,
      'Fecha': 80,
      'Estado': 100,
      'Observaciones': 180,
      'Acciones': 80,
    };
    
    // Calculamos el ancho total necesario
    final double totalWidth = columnWidths.values.reduce((a, b) => a + b) + 20; // +20 para margen de seguridad
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        // Aseguramos que el ancho sea el adecuado
        width: totalWidth > maxWidth ? totalWidth : maxWidth,
        child: SingleChildScrollView(
          child: Theme(
            data: ThemeData.light().copyWith(
              dataTableTheme: const DataTableThemeData(
                headingTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                dataTextStyle: TextStyle(
                  color: Colors.black87,
                ),
              ),
            ),
            child: DataTable(
              columnSpacing: 8, // Un poco más de espacio entre columnas
              horizontalMargin: 8,
              headingRowHeight: 46,
              dataRowHeight: 52,
              columns: [
                _customDataColumn('ID', columnWidths['ID']!),
                _customDataColumn('Cliente', columnWidths['Cliente']!),
                _customDataColumn('Empresa', columnWidths['Empresa']!),
                _customDataColumn('Banco', columnWidths['Banco']!),
                _customDataColumn('Importe', columnWidths['Importe']!),
                _customDataColumn('Moneda', columnWidths['Moneda']!),
                _customDataColumn('Fecha', columnWidths['Fecha']!),
                _customDataColumn('Estado', columnWidths['Estado']!),
                _customDataColumn('Observaciones', columnWidths['Observaciones']!),
                _customDataColumn('Acciones', columnWidths['Acciones']!),
              ],
              rows: paged.map((d) {
                return DataRow(
                  cells: [
                    _customDataCell(Text(d.idDeposito.toString()), columnWidths['ID']!),
                    _customDataCell(Text(d.codCliente), columnWidths['Cliente']!),
                    _customDataCell(Text(d.nombreEmpresa), columnWidths['Empresa']!),
                    _customDataCell(Text(d.nombreBanco), columnWidths['Banco']!),
                    _customDataCell(Text(d.importe.toStringAsFixed(2)), columnWidths['Importe']!),
                    _customDataCell(Text(d.moneda), columnWidths['Moneda']!),
                    _customDataCell(Text(d.fechaI != null 
                      ? "${d.fechaI!.day.toString().padLeft(2, '0')}/${d.fechaI!.month.toString().padLeft(2, '0')}/${d.fechaI!.year}" 
                      : ''), columnWidths['Fecha']!),
                    _customDataCell(_EstadoChip(estado: d.esPendiente), columnWidths['Estado']!),
                    _customDataCell(
                      Text(d.obs, overflow: TextOverflow.ellipsis), 
                      columnWidths['Observaciones']!
                    ),
                    _customDataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.vpn_key, color: Colors.orange, size: 20),
                          tooltip: 'Identificar',
                          onPressed: () {},
                          constraints: const BoxConstraints(maxWidth: 32),
                          padding: EdgeInsets.zero,
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.indigo, size: 20),
                          tooltip: 'Copiar',
                          onPressed: () {},
                          constraints: const BoxConstraints(maxWidth: 32),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ), columnWidths['Acciones']!),
                  ],
                );
              }).toList(),
              border: TableBorder(
                horizontalInside: BorderSide(width: 1, color: Colors.grey.shade200),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Columna de DataTable con ancho controlado
  DataColumn _customDataColumn(String label, double width) {
    return DataColumn(
      label: Container(
        width: width,
        child: Text(label),
      ),
    );
  }

  // Celda de DataTable con ancho controlado
  DataCell _customDataCell(Widget child, double width) {
    return DataCell(
      Container(
        width: width,
        child: child,
      ),
    );
  }

  // Tabla para tablet (sin la columna de Observaciones)
  Widget _buildTabletScrollableTable(List<dynamic> paged, double maxWidth) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: maxWidth,
        ),
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 12,
            horizontalMargin: 8,
            headingRowHeight: 46,
            dataRowHeight: 52,
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Cliente')),
              DataColumn(label: Text('Empresa')),
              DataColumn(label: Text('Banco')),
              DataColumn(label: Text('Importe')),
              DataColumn(label: Text('Moneda')),
              DataColumn(label: Text('Fecha')),
              DataColumn(label: Text('Estado')),
              DataColumn(label: Text('Acciones')),
            ],
            rows: paged.map((d) {
              return DataRow(
                cells: [
                  DataCell(Text(d.idDeposito.toString())),
                  DataCell(Text(d.codCliente)),
                  DataCell(Text(d.nombreEmpresa)),
                  DataCell(Text(d.nombreBanco)),
                  DataCell(Text(d.importe.toStringAsFixed(2))),
                  DataCell(Text(d.moneda)),
                  DataCell(Text(d.fechaI != null 
                    ? "${d.fechaI!.day.toString().padLeft(2, '0')}/${d.fechaI!.month.toString().padLeft(2, '0')}/${d.fechaI!.year}" 
                    : '')),
                  DataCell(_EstadoChip(estado: d.esPendiente)),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.vpn_key, color: Colors.orange, size: 20),
                        tooltip: 'Identificar',
                        onPressed: () {},
                        constraints: const BoxConstraints(maxWidth: 32),
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.indigo, size: 20),
                        tooltip: 'Copiar',
                        onPressed: () {},
                        constraints: const BoxConstraints(maxWidth: 32),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  )),
                ],
              );
            }).toList(),
            border: TableBorder(
              horizontalInside: BorderSide(width: 1, color: Colors.grey.shade200),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePagination(BuildContext context, int start, int end, int total, int page, 
      dynamic notifier, int rowsPerPage) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            'Mostrando $start a $end de $total depósitos',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.first_page, size: 20),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: page > 0 ? () => notifier.setPage(0) : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: page > 0 ? () => notifier.setPage(page - 1) : null,
              ),
              Text('${page + 1}', style: Theme.of(context).textTheme.bodyLarge),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: end < total ? () => notifier.setPage(page + 1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page, size: 20),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: end < total ? () => notifier.setPage((total / rowsPerPage).ceil() - 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopPagination(BuildContext context, int start, int end, int total, int page,
      dynamic notifier, int rowsPerPage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Text('Mostrando $start a $end de $total depósitos', style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: page > 0 ? () => notifier.setPage(0) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: page > 0 ? () => notifier.setPage(page - 1) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: end < total ? () => notifier.setPage(page + 1) : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: end < total ? () => notifier.setPage((total / rowsPerPage).ceil() - 1) : null,
          ),
          const SizedBox(width: 16),
          DropdownButton<int>(
            value: rowsPerPage,
            items: const [10, 20, 50]
                .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                .toList(),
            onChanged: (v) => notifier.setRowsPerPage(v),
          ),
        ],
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final String estado;
  const _EstadoChip({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label = estado;
    
    if (estado.toLowerCase().contains('pendiente')) {
      color = Colors.orange.shade200;
      label = 'Pendiente';
    } else if (estado.toLowerCase().contains('verific')) {
      color = Colors.green.shade200;
      label = 'Verificado';
    } else {
      color = Colors.grey.shade300;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            estado.toLowerCase().contains('pendiente') 
                ? Icons.access_time 
                : Icons.check_circle,
            size: 14,
            color: Colors.black87,
          ),
          const SizedBox(width: 4),
          Text(
            label, 
            style: const TextStyle(
              fontSize: 12, 
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}