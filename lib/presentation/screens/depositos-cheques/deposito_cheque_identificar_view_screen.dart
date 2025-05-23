import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/banco_cuenta_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_remision_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_negocio_entity.dart';
import 'package:bosque_flutter/presentation/screens/depositos-cheques/deposito_cheque_register_screen.dart';
import 'package:bosque_flutter/presentation/screens/depositos-cheques/editable_saldo_pendiente_cell.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/state/depositos_cheques_provider.dart';
import '../../../core/utils/responsive_utils_bosque.dart';

// Un modelo simple para representar documentos
class DocumentoDisponible {
  final String numero;
  final int numeroFactura;
  final DateTime fecha;
  final double total;
  final double saldo;
  bool seleccionado;

  DocumentoDisponible({
    required this.numero,
    required this.numeroFactura,
    required this.fecha,
    required this.total,
    required this.saldo,
    this.seleccionado = false,
  });
}

class DepositoChequeIdentificarViewScreen extends ConsumerStatefulWidget {
  const DepositoChequeIdentificarViewScreen({super.key});

  @override
  ConsumerState<DepositoChequeIdentificarViewScreen> createState() =>
      _DepositoChequeIdentificarViewScreenState();
}

class _DepositoChequeIdentificarViewScreenState
    extends ConsumerState<DepositoChequeIdentificarViewScreen> {
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  final TextEditingController _fechaDesdeController = TextEditingController();
  final TextEditingController _fechaHastaController = TextEditingController();

  void initState() {
    super.initState();
    // Inicializar con fechas predeterminadas
    _fechaDesdeController.text = "01/05/2025";
    _fechaHastaController.text = "31/05/2025";
    
    // Limpiar los resultados de búsqueda de depósitos al entrar a esta pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(depositosChequesProvider.notifier).clearDepositosResults();
    });
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
      initialDate:
          isDesde
              ? (_fechaDesde ?? DateTime.now())
              : (_fechaHasta ?? DateTime.now()),
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
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Depósitos por Identificar',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 2,
        iconTheme: IconThemeData(color: colorScheme.primary),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context),
            vertical: ResponsiveUtilsBosque.getVerticalPadding(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchHeader(context),
              const SizedBox(height: 16),
              _buildSearchForm(context, notifier),
              const SizedBox(height: 24),
              Expanded(
                child: state.cargando
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      )
                    : _DepositosIdentificarTable(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(Icons.search, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          'Criterios de Búsqueda',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchForm(BuildContext context, dynamic notifier) {
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final colorScheme = Theme.of(context).colorScheme;

    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _fechaDesdeController,
            readOnly: true,
            decoration: inputDecoration.copyWith(
              labelText: 'Desde',
              prefixIcon: Icon(Icons.calendar_today, color: colorScheme.primary),
            ),
            onTap: () => _pickDate(context, true),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fechaHastaController,
            readOnly: true,
            decoration: inputDecoration.copyWith(
              labelText: 'Hasta',
              prefixIcon: Icon(Icons.calendar_today, color: colorScheme.primary),
            ),
            onTap: () => _pickDate(context, false),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text('Buscar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              notifier.buscarDepositosPorIdentificar(
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

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _fechaDesdeController,
            readOnly: true,
            decoration: inputDecoration.copyWith(
              labelText: 'Desde',
              suffixIcon: Icon(Icons.calendar_today, color: colorScheme.primary),
            ),
            onTap: () => _pickDate(context, true),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _fechaHastaController,
            readOnly: true,
            decoration: inputDecoration.copyWith(
              labelText: 'Hasta',
              suffixIcon: Icon(Icons.calendar_today, color: colorScheme.primary),
            ),
            onTap: () => _pickDate(context, false),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.search),
          label: const Text('Buscar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            notifier.buscarDepositosPorIdentificar(
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

    // Función para mostrar el diálogo de asignar cliente
    Future<void> _mostrarDialogoAsignarCliente(dynamic deposito) async {
      // Mapear los datos del depósito para pasarlos al diálogo
      final Map<String, dynamic> datosDeposito = {
        'id': deposito.idDeposito,
        'empresa': deposito.nombreEmpresa,
        'banco': deposito.nombreBanco,
        'importe': deposito.importe,
        'moneda': deposito.moneda,
        'fecha': deposito.fechaI,
        'estado': deposito.esPendiente,
        'observacion': deposito.obs,
      };

      final result = await mostrarActualizacionDeposito(context, datosDeposito);

      // Aquí puedes manejar el resultado (actualizar el estado, etc.)
      if (result != null) {
        // Actualizar el estado con el resultado del diálogo
        // notifier.actualizarDeposito(result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Depósito actualizado correctamente')),
        );
      }
    }

    if (depositos.isEmpty) {
      return Center(
        child: Text(
          'No hay depósitos pendientes por identificar',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
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
                final esVerificado = d.esPendiente.toLowerCase().contains('verific');
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 0,
                  ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _EstadoChip(estado: d.esPendiente),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('Cliente', d.codCliente),
                        _buildInfoRow('Empresa', d.nombreEmpresa),
                        _buildInfoRow('Banco', d.nombreBanco),
                        _buildInfoRow(
                          'Importe',
                          '${d.importe.toStringAsFixed(2)} ${d.moneda}',
                        ),
                        _buildInfoRow(
                          'Fecha',
                          d.fechaI != null
                              ? "${d.fechaI!.day.toString().padLeft(2, '0')}/${d.fechaI!.month.toString().padLeft(2, '0')}/${d.fechaI!.year}"
                              : '',
                        ),
                        if (d.obs.isNotEmpty)
                          _buildInfoRow('Observaciones', d.obs),
                        const SizedBox(height: 8),
                        if (!esVerificado) // Solo mostrar el botón si NO está verificado
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.person,
                                  color: Colors.orange,
                                ),
                                tooltip: 'Asignar Cliente',
                                onPressed: () => _mostrarDialogoAsignarCliente(d),
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
          _buildMobilePagination(
            context,
            start,
            end,
            total,
            page,
            notifier,
            rowsPerPage,
          ),
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
                child: _buildOptimizedScrollableTable(
                  paged,
                  constraints.maxWidth,
                  _mostrarDialogoAsignarCliente,
                ),
              ),
              SizedBox(
                height: paginacionHeight,
                child: _buildDesktopPagination(
                  context,
                  start,
                  end,
                  total,
                  page,
                  notifier,
                  rowsPerPage,
                ),
              ),
            ],
          );
        } else {
          // Para tablet - con scrolling horizontal
          return Column(
            children: [
              SizedBox(
                height: tablaHeight > 0 ? tablaHeight : 0,
                child: _buildOptimizedScrollableTable(
                  paged,
                  constraints.maxWidth,
                  _mostrarDialogoAsignarCliente,
                ),
              ),
              SizedBox(
                height: paginacionHeight,
                child: _buildDesktopPagination(
                  context,
                  start,
                  end,
                  total,
                  page,
                  notifier,
                  rowsPerPage,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  // Tabla optimizada para desktop con scroll horizontal pero columnas con mejor espaciado
  Widget _buildOptimizedScrollableTable(
    List<dynamic> paged,
    double maxWidth,
    Function onAsignarCliente,
  ) {
    // Definir una constante para el ancho mínimo de la tabla
    const double tableMinWidth = 950.0;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        // Asegurar un ancho mínimo para la tabla
        width: tableMinWidth > maxWidth ? tableMinWidth : maxWidth,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 8,
            horizontalMargin: 8,
            headingRowHeight: 46,
            dataRowHeight: 52,
            columns: [
              _customDataColumn('ID', 60),
              _customDataColumn('Cliente', 90), 
              _customDataColumn('Empresa', 90),
              _customDataColumn('Banco', 200),
              _customDataColumn('Importe', 90),
              _customDataColumn('Moneda', 60),
              _customDataColumn('Fecha', 80),
              _customDataColumn('Estado', 100),
              _customDataColumn('Observaciones', 180),
              _customDataColumn('Acciones', 80),
            ],
            rows: paged.map((d) {
              final esVerificado = d.esPendiente.toLowerCase().contains('verific');
              return DataRow(
                cells: [
                  _customDataCell(Text(d.idDeposito.toString()), 60),
                  _customDataCell(Text(d.codCliente), 90),
                  _customDataCell(Text(d.nombreEmpresa), 90),
                  _customDataCell(Text(d.nombreBanco), 200),
                  _customDataCell(Text(d.importe.toStringAsFixed(2)), 90),
                  _customDataCell(Text(d.moneda), 60),
                  _customDataCell(
                    Text(
                      d.fechaI != null
                          ? "${d.fechaI!.day.toString().padLeft(2, '0')}/${d.fechaI!.month.toString().padLeft(2, '0')}/${d.fechaI!.year}"
                          : '',
                    ),
                    80,
                  ),
                  _customDataCell(_EstadoChip(estado: d.esPendiente), 100),
                  _customDataCell(Text(d.obs, overflow: TextOverflow.ellipsis), 180),
                  _customDataCell(
                    esVerificado // Si está verificado, mostrar un contenedor vacío
                        ? const SizedBox.shrink()
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.person,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                tooltip: 'Asignar Cliente',
                                onPressed: () => onAsignarCliente(d),
                                constraints: const BoxConstraints(maxWidth: 32),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                    80,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Columna de DataTable con ancho controlado
  DataColumn _customDataColumn(String label, double width) {
    return DataColumn(label: Container(width: width, child: Text(label)));
  }

  // Celda de DataTable con ancho controlado
  DataCell _customDataCell(Widget child, double width) {
    return DataCell(Container(width: width, child: child));
  }

  // Tabla para tablet (sin la columna de Observaciones)
  Widget _buildTabletScrollableTable(
    List<dynamic> paged,
    double maxWidth,
    Function onAsignarCliente,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: maxWidth),
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
            rows:
                paged.map((d) {
                  final esVerificado = d.esPendiente.toLowerCase().contains('verific');
                  return DataRow(
                    cells: [
                      DataCell(Text(d.idDeposito.toString())),
                      DataCell(Text(d.codCliente)),
                      DataCell(Text(d.nombreEmpresa)),
                      DataCell(Text(d.nombreBanco)),
                      DataCell(Text(d.importe.toStringAsFixed(2))),
                      DataCell(Text(d.moneda)),
                      DataCell(
                        Text(
                          d.fechaI != null
                              ? "${d.fechaI!.day.toString().padLeft(2, '0')}/${d.fechaI!.month.toString().padLeft(2, '0')}/${d.fechaI!.year}"
                              : '',
                        ),
                      ),
                      DataCell(_EstadoChip(estado: d.esPendiente)),
                      DataCell(
                        esVerificado // Si está verificado, mostrar un contenedor vacío
                            ? const SizedBox.shrink()
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.person,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                    tooltip: 'Asignar Cliente',
                                    onPressed: () => onAsignarCliente(d),
                                    constraints: const BoxConstraints(maxWidth: 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.copy,
                                      color: Colors.indigo,
                                      size: 20,
                                    ),
                                    tooltip: 'Copiar',
                                    onPressed: () {},
                                    constraints: const BoxConstraints(maxWidth: 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                      ),
                    ],
                  );
                }).toList(),
            border: TableBorder(
              horizontalInside: BorderSide(
                width: 1,
                color: Colors.grey.shade200,
              ),
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
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePagination(
    BuildContext context,
    int start,
    int end,
    int total,
    int page,
    dynamic notifier,
    int rowsPerPage,
  ) {
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
                onPressed:
                    end < total ? () => notifier.setPage(page + 1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page, size: 20),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed:
                    end < total
                        ? () =>
                            notifier.setPage((total / rowsPerPage).ceil() - 1)
                        : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopPagination(
    BuildContext context,
    int start,
    int end,
    int total,
    int page,
    dynamic notifier,
    int rowsPerPage,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Text(
            'Mostrando $start a $end de $total depósitos',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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
            onPressed:
                end < total
                    ? () => notifier.setPage((total / rowsPerPage).ceil() - 1)
                    : null,
          ),
          const SizedBox(width: 16),
          DropdownButton<int>(
            value: rowsPerPage,
            items:
                const [10, 20, 50]
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

// Implementación del diálogo para actualizar depósitos
class ActualizacionDepositoDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> deposito;

  const ActualizacionDepositoDialog({Key? key, required this.deposito})
    : super(key: key);

  @override
  ConsumerState<ActualizacionDepositoDialog> createState() =>
      _ActualizacionDepositoDialogState();
}

class _ActualizacionDepositoDialogState
    extends ConsumerState<ActualizacionDepositoDialog> {
  // Variables para controlar el estado del formulario
  EmpresaEntity? empresaSeleccionada;
  SocioNegocioEntity? clienteSeleccionado;
  BancoXCuentaEntity? bancoSeleccionado;
  double aCuenta = 0;
  XFile? imagenSeleccionada;
  double totalDocumentos = 0;
  double importeDeposito = 0;
  bool cargando = false;
  Uint8List? _webImageBytes;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _aCuentaController = TextEditingController(
    text: '0.00',
  );
  final TextEditingController _observacionesController =
      TextEditingController();

  // Agrega estos controladores como variables de instancia
  ScrollController? _verticalController;
  ScrollController? _horizontalController;

  @override
  void initState() {
    // Inicializar controladores de scroll como instancias normales (no late/final)
    _verticalController = ScrollController();
    _horizontalController = ScrollController();
    super.initState();
    // Inicializar con valores predeterminados
    importeDeposito = widget.deposito['importe'] ?? 0.0;
    _observacionesController.text = widget.deposito['observacion'] ?? '';

    // Limpiar cualquier imagen previa
    if (kIsWeb) {
      ref.read(imageBytesProvider.notifier).state = null;
    }

    // Iniciar carga de datos en un microtask
    Future.microtask(() {
      if (mounted) {
        _cargarDatosIniciales();
      }
    });
  }

  Future<void> _cargarDatosIniciales() async {
    if (!mounted) return;

    setState(() {
      cargando = true;
    });

    try {
      // Simplificar la carga inicial - solo cargar datos si es necesario
      final state = ref.read(depositosChequesProvider);

      // Si ya hay datos cargados, los usamos
      if (state.empresas.isNotEmpty) {
        _configurarDatosIniciales();
      } else {
        // Intentar cargar empresas
        try {
          await ref.read(depositosChequesProvider.notifier).cargarEmpresas();
          if (mounted) {
            _configurarDatosIniciales();
          }
        } catch (e) {
          print('Error al cargar empresas: $e');
        }
      }
    } catch (e) {
      print('Error general: $e');
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  // Método separado para configurar datos iniciales
  void _configurarDatosIniciales() {
    try {
      final state = ref.read(depositosChequesProvider);

      // Primero intentamos encontrar la empresa por nombre
      final nombreEmpresa = widget.deposito['empresa'] ?? '';
      EmpresaEntity? empresa;

      try {
        empresa = state.empresas.firstWhere(
          (e) => e.nombre == nombreEmpresa,
          orElse:
              () => state.empresas.firstWhere(
                (e) => e.codEmpresa != 0,
                orElse: () => state.empresas.first,
              ),
        );

        // Actualizar localmente
        setState(() {
          empresaSeleccionada = empresa;
        });

        // Ahora intentamos cargar clientes y bancos
        _cargarClientesYBancos(empresa);
      } catch (e) {
        print('Error al configurar empresa: $e');
      }
    } catch (e) {
      print('Error en configuración inicial: $e');
    }
  }

  // Método para cargar clientes y bancos basados en la empresa
  Future<void> _cargarClientesYBancos(EmpresaEntity empresa) async {
    if (!mounted) return;

    try {
      // Seleccionar empresa en el provider
      await ref
          .read(depositosChequesProvider.notifier)
          .seleccionarEmpresa(empresa);

      // Obtener clientes y bancos
      final state = ref.read(depositosChequesProvider);
      final clientes = state.clientes;
      final bancos = state.bancos;

      // Configurar cliente si hay disponibles
      if (clientes.isNotEmpty) {
        SocioNegocioEntity? cliente;
        try {
          cliente = clientes.firstWhere(
            (c) => c.codCliente.isNotEmpty,
            orElse: () => clientes.first,
          );

          if (cliente.codCliente.isNotEmpty) {
            setState(() {
              clienteSeleccionado = cliente;
            });

            // Cargar documentos del cliente
            await ref
                .read(depositosChequesProvider.notifier)
                .seleccionarCliente(cliente);
          }
        } catch (e) {
          print('Error al configurar cliente: $e');
        }
      }

      // Configurar banco si hay disponibles
      if (bancos.isNotEmpty) {
        final nombreBanco = widget.deposito['banco'] ?? '';

        try {
          BancoXCuentaEntity? banco = bancos.firstWhere(
            (b) => b.nombreBanco == nombreBanco,
            orElse: () => bancos.first,
          );

          setState(() {
            bancoSeleccionado = banco;
          });

          ref.read(depositosChequesProvider.notifier).seleccionarBanco(banco);
        } catch (e) {
          print('Error al configurar banco: $e');
        }
      }
    } catch (e) {
      print('Error al cargar clientes y bancos: $e');
    }
  }

  // Manejar la selección de documentos
  void _toggleDocumentoSeleccionado(int docNum, bool seleccionado) {
    try {
      ref
          .read(depositosChequesProvider.notifier)
          .seleccionarNota(docNum, seleccionado);
      _actualizarTotales();
    } catch (e) {
      print('Error al seleccionar nota: $e');
    }
  }

  // Calcular totales
  void _actualizarTotales() {
    try {
      final state = ref.read(depositosChequesProvider);
      final notasSeleccionadas = state.notasSeleccionadas;
      final saldosEditados = state.saldosEditados;
      final notasRemision = state.notasRemision;

      double total = 0;
      for (final docNum in notasSeleccionadas) {
        try {
          final nota = notasRemision.firstWhere(
            (n) => n.docNum == docNum,
            orElse:
                () => NotaRemisionEntity(
                  idNr: 0,
                  idDeposito: 0,
                  docNum: 0,
                  totalMonto: 0,
                  saldoPendiente: 0,
                  audUsuario: 0,
                  codCliente: '',
                  nombreCliente: '',
                  db: '',
                  codEmpresaBosque: 0,
                  fecha: DateTime.now(),
                  numFact: 0,
                ),
          );

          if (saldosEditados.containsKey(docNum)) {
            total += saldosEditados[docNum] ?? 0;
          } else {
            total += nota.saldoPendiente;
          }
        } catch (e) {
          print('Error procesando nota $docNum: $e');
        }
      }

      setState(() {
        totalDocumentos = total;
      });
    } catch (e) {
      print('Error al actualizar totales: $e');
    }
  }

  // Método para manejar la selección de imágenes
  Future<void> _seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? imagen = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (imagen != null) {
        setState(() {
          imagenSeleccionada = imagen;
        });

        // For Web, we need to read the bytes
        if (kIsWeb) {
          final bytes = await imagen.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsividad
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final isTablet = ResponsiveUtilsBosque.isTablet(context);
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(
      context,
    );
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);
    final maxDialogWidth =
        isMobile
            ? MediaQuery.of(context).size.width * 0.98
            : isTablet
            ? 600.0
            : 700.0;
    final maxDialogHeight =
        isMobile
            ? MediaQuery.of(context).size.height * 0.98
            : MediaQuery.of(context).size.height * 0.85;

    if (cargando) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxDialogWidth, maxHeight: 200),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando datos...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final state = ref.watch(depositosChequesProvider);
    final notasRemision = state.notasRemision;
    final notasSeleccionadas = state.notasSeleccionadas;
    if (state.notasSeleccionadas.isNotEmpty) {
      _actualizarTotales();
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 4 : 24,
        vertical: isMobile ? 8 : 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxDialogWidth,
          maxHeight: maxDialogHeight,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Actualización de Depósito',
                          style: ResponsiveUtilsBosque.getTitleStyle(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Cerrar',
                        ),
                      ],
                    ),
                    SizedBox(height: verticalPadding),

                    // Sección Asignar Cliente
                    Row(
                      children: [
                        const Icon(
                          Icons.person_add_outlined,
                          color: Colors.indigo,
                        ),
                        SizedBox(width: isMobile ? 4 : 8),
                        Text(
                          'Asignar Cliente',
                          style: TextStyle(
                            fontSize: ResponsiveUtilsBosque.getResponsiveValue(
                              context: context,
                              defaultValue: 16.0,
                              mobile: 14.0,
                              desktop: 18.0,
                            ),
                            fontWeight: FontWeight.w500,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: verticalPadding),

                    // Empresa
                    Text(
                      'Empresa:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 4),
                    DropdownButtonFormField<EmpresaEntity>(
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding / 2,
                          vertical: 12,
                        ),
                      ),
                      value: empresaSeleccionada,
                      hint: const Text("Seleccione una empresa"),
                      items: state.empresas
                          .where((e) => e.codEmpresa != 0) // Filtrar "Todos"
                          .map((empresa) {
                            return DropdownMenuItem<EmpresaEntity>(
                              value: empresa,
                              child: Text(empresa.nombre),
                            );
                          })
                          .toList(),
                      onChanged: null, // <-- Deshabilita el dropdown (solo lectura)
                      disabledHint: empresaSeleccionada != null
                          ? Text(empresaSeleccionada!.nombre)
                          : const Text("Seleccione una empresa"),
                    ),
                    SizedBox(height: verticalPadding),

                    // Cliente
                    Text(
                      'Cliente',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 4),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'Buscar cliente',
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        suffixIcon:
                            clienteSeleccionado != null
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () async {
                                    setState(() {
                                      cargando = true;
                                    });
                                    try {
                                      await ref
                                          .read(depositosChequesProvider.notifier)
                                          .seleccionarCliente(null);
                                    } catch (e) {
                                      print('Error al limpiar cliente: $e');
                                    }
                                    if (mounted) {
                                      setState(() {
                                        clienteSeleccionado = null;
                                        cargando = false;
                                      });
                                      _actualizarTotales();
                                    }
                                  },
                                )
                                : null,
                      ),
                      controller: TextEditingController(
                        text: clienteSeleccionado?.nombreCompleto ?? '',
                      ),
                      onTap: () async {
                        final seleccionado = await showDialog(
                          context: context,
                          builder:
                              (context) => ClienteSearchDialog(
                                clientes: state.clientes,
                                onClienteSelected: (cliente) {
                                  Navigator.pop(context, cliente);
                                },
                              ),
                        );
                        if (seleccionado != null) {
                          setState(() {
                            cargando = true;
                          });
                          try {
                            await ref
                                .read(depositosChequesProvider.notifier)
                                .seleccionarCliente(seleccionado);
                          } catch (e) {
                            print('Error al seleccionar cliente: $e');
                          }
                          if (mounted) {
                            setState(() {
                              clienteSeleccionado = seleccionado;
                              cargando = false;
                            });
                            _actualizarTotales();
                          }
                        }
                      },
                    ),
                    SizedBox(height: verticalPadding),

                    // Banco y A Cuenta
                    isMobile
                        ? Column(
                          children: [
                            // Banco
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Banco',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            SizedBox(height: 4),
                            DropdownButtonFormField<BancoXCuentaEntity>(
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding / 2,
                                  vertical: 12,
                                ),
                              ),
                              value: bancoSeleccionado,
                              hint: const Text("Seleccione un banco"),
                              isExpanded: true,
                              items:
                                  state.bancos.map((banco) {
                                    return DropdownMenuItem<BancoXCuentaEntity>(
                                      value: banco,
                                      child: Text(
                                        banco.nombreBanco,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    bancoSeleccionado = newValue;
                                  });
                                  try {
                                    ref
                                        .read(depositosChequesProvider.notifier)
                                        .seleccionarBanco(newValue);
                                  } catch (e) {
                                    print('Error al seleccionar banco: $e');
                                  }
                                }
                              },
                            ),
                            SizedBox(height: verticalPadding / 2),
                            // A Cuenta
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'A Cuenta',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            SizedBox(height: 4),
                            TextFormField(
                              controller: _aCuentaController,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding / 2,
                                  vertical: 12,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              onChanged: (value) {
                                final nuevaCuenta = double.tryParse(value) ?? 0;
                                setState(() {
                                  aCuenta = nuevaCuenta;
                                });
                                try {
                                  ref
                                      .read(depositosChequesProvider.notifier)
                                      .setACuenta(nuevaCuenta);
                                    _actualizarTotales();
                                } catch (e) {
                                  print('Error al actualizar cuenta: $e');
                                }
                              },
                            ),
                          ],
                        )
                        : Row(
                          children: [
                            // Banco
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Banco',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  SizedBox(height: 4),
                                  DropdownButtonFormField<BancoXCuentaEntity>(
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: horizontalPadding / 2,
                                        vertical: 12,
                                      ),
                                    ),
                                    value: bancoSeleccionado,
                                    hint: const Text("Seleccione un banco"),
                                    isExpanded: true,
                                    items:
                                        state.bancos.map((banco) {
                                          return DropdownMenuItem<
                                            BancoXCuentaEntity
                                          >(
                                            value: banco,
                                            child: Text(
                                              banco.nombreBanco,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          bancoSeleccionado = newValue;
                                        });
                                        try {
                                          ref
                                              .read(
                                                depositosChequesProvider.notifier,
                                              )
                                              .seleccionarBanco(newValue);
                                        } catch (e) {
                                          print('Error al seleccionar banco: $e');
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: horizontalPadding),
                            // A Cuenta
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'A Cuenta',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  SizedBox(height: 4),
                                  TextFormField(
                                    controller: _aCuentaController,
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: horizontalPadding / 2,
                                        vertical: 12,
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      final nuevaCuenta =
                                          double.tryParse(value) ?? 0;
                                      setState(() {
                                        aCuenta = nuevaCuenta;
                                      });
                                      try {
                                        ref
                                            .read(
                                              depositosChequesProvider.notifier,
                                            )
                                            .setACuenta(nuevaCuenta);
                                        _actualizarTotales();
                                      } catch (e) {
                                        print('Error al actualizar cuenta: $e');
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    SizedBox(height: verticalPadding),

                    // Imagen del Depósito
                    Text(
                      'Imagen del Depósito',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      height: isMobile ? 90 : 110,
                      child: GestureDetector(
                        onTap: _seleccionarImagen,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child:
                              kIsWeb
                                  ? (_webImageBytes != null
                                      ? Image.memory(
                                        _webImageBytes!,
                                        fit: BoxFit.cover,
                                      )
                                      : Center(
                                        child: Icon(
                                          Icons.cloud_upload,
                                          size: 32,
                                          color: Colors.grey,
                                        ),
                                      ))
                                  : (imagenSeleccionada != null
                                      ? Image.file(
                                        File(imagenSeleccionada!.path),
                                        fit: BoxFit.cover,
                                      )
                                      : Center(
                                        child: Icon(
                                          Icons.cloud_upload,
                                          size: 32,
                                          color: Colors.grey,
                                        ),
                                      )),
                        ),
                      ),
                    ),
                    if (imagenSeleccionada == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red[300],
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Debe seleccionar una imagen',
                              style: TextStyle(
                                color: Colors.red[300],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: verticalPadding / 2),

                    // Observaciones
                    Text(
                      'Observaciones:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 4),
                    SizedBox(
                      height: isMobile ? 60 : 80,
                      child: TextFormField(
                        controller: _observacionesController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding / 2,
                            vertical: 12,
                          ),
                          hintText: 'Observaciones sobre el depósito',
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          try {
                            ref
                                .read(depositosChequesProvider.notifier)
                                .setObservaciones(value);
                          } catch (e) {
                            print('Error al guardar observaciones: $e');
                          }
                        },
                      ),
                    ),
                    SizedBox(height: verticalPadding),

                    // Documentos Disponibles
                    Text(
                      'Documentos Disponibles',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 8),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: isMobile ? 200 : 320,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: notasRemision.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay documentos disponibles para este cliente',
                              ),
                            )
                          : _buildDocumentosTable(),
                    ),

                    SizedBox(height: verticalPadding),

                    // Totales
                    isMobile
                        ? Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Total Documentos'),
                                      SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${totalDocumentos.toStringAsFixed(2)} BS',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('A Cuenta'),
                                      SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${aCuenta.toStringAsFixed(2)} BS',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                        : Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Documentos'),
                                  SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${totalDocumentos.toStringAsFixed(2)} BS',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: horizontalPadding),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('A Cuenta'),
                                  SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${aCuenta.toStringAsFixed(2)} BS',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    SizedBox(height: verticalPadding),
                    const SizedBox(height: 16),

                    // Importe del Depósito
                    Row(
                      children: [
                        Text(
                          'Importe del Depósito:',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${importeDeposito.toStringAsFixed(2)} BS',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    // Mensaje de validación
                    (totalDocumentos > 0 &&
                            totalDocumentos + aCuenta != importeDeposito)
                        ? Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.amber[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber[800],
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Total debe ser igual al importe: ${(totalDocumentos + aCuenta).toStringAsFixed(2)} ≠ ${importeDeposito.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.amber[800],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        : const SizedBox.shrink(),

                    SizedBox(height: verticalPadding),
                    // Botones de acción
                    isMobile
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate() &&
                                    _validarFormulario()) {
                                  _guardarDepositoYNotas();
                                }
                              },
                              child: const Text('Guardar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate() &&
                                    _validarFormulario()) {
                                  _guardarDepositoYNotas();
                                }
                              },
                              child: const Text('Guardar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      )
    );
  }

  // Método para mostrar diálogo para editar saldo

  bool _validarFormulario() {
    if (empresaSeleccionada == null) {
      _mostrarError('Debe seleccionar una empresa');
      return false;
    }

    if (clienteSeleccionado == null) {
      _mostrarError('Debe seleccionar un cliente');
      return false;
    }

    if (bancoSeleccionado == null) {
      _mostrarError('Debe seleccionar un banco');
      return false;
    }

    if (imagenSeleccionada == null) {
      _mostrarError('Debe seleccionar una imagen del depósito');
      return false;
    }

    try {
      final notasSeleccionadas =
          ref.read(depositosChequesProvider).notasSeleccionadas;
      if (notasSeleccionadas.isEmpty && aCuenta <= 0) {
        _mostrarError(
          'Debe seleccionar al menos un documento o ingresar un valor a cuenta',
        );
        return false;
      }
    } catch (e) {
      print('Error al verificar notas seleccionadas: $e');
    }

    // Verificar que el total coincida con el importe del depósito
    final total = totalDocumentos + aCuenta;
    if (totalDocumentos > 0 && total != importeDeposito) {
      _mostrarError(
        'El total (${total.toStringAsFixed(2)}) debe ser igual al importe del depósito (${importeDeposito.toStringAsFixed(2)})',
      );
      return false;
    }

    return true;
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      // Usar el ScaffoldMessenger del Scaffold interno del diálogo
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _guardarDepositoYNotas() async {
    if (!mounted) return;

    setState(() {
      cargando = true;
    });

    try {
      final depositoIdOriginal = widget.deposito['id'] ?? 0;
      final notifier = ref.read(depositosChequesProvider.notifier);

      // --- SINCRONIZAR ESTADO DEL PROVIDER CON LOS VALORES DEL DIALOG ---
      // IMPORTANTE: Usar métodos de sincronización que NO reseteen las selecciones de notas

      // Empresa (sin recargar datos)
      if (empresaSeleccionada != null) {
        notifier.sincronizarEmpresaSeleccionada(empresaSeleccionada!);
      }

      // Cliente (sin recargar notas - esto es clave para mantener selecciones)
      if (clienteSeleccionado != null) {
        notifier.sincronizarClienteSeleccionado(clienteSeleccionado!);
      }

      // Banco
      if (bancoSeleccionado != null) {
        notifier.sincronizarBancoSeleccionado(bancoSeleccionado!);
      }

      // A Cuenta
      notifier.setACuenta(aCuenta);
      // Importe total (importante para actualizaciones)
      notifier.setImporteTotal(importeDeposito);
      // Observaciones
      notifier.setObservaciones(_observacionesController.text);

      // Debug: Mostrar estado de las notas seleccionadas antes de guardar

      // Guardar las notas de remisión seleccionadas
      bool todasGuardadas = false;

      try {
        todasGuardadas = await notifier.guardarNotasRemision(
          idDepositoParaNotas:
              depositoIdOriginal > 0 ? depositoIdOriginal : null,
        );
      } catch (e) {
        print('[DEBUG][DIALOG] Error al guardar notas: $e');
        todasGuardadas = false;
      }

      // Registrar o actualizar el depósito con la imagen
      // El mismo método registrarDeposito maneja ambos casos basándose en el ID
      bool depositoGuardado = false;

      try {
        if (imagenSeleccionada != null) {
          if (kIsWeb) {
            depositoGuardado = await notifier.registrarDeposito(
              _webImageBytes!,
              idDepositoActualizacion:
                  depositoIdOriginal > 0 ? depositoIdOriginal : null,
            );
          } else {
            depositoGuardado = await notifier.registrarDeposito(
              File(imagenSeleccionada!.path),
              idDepositoActualizacion:
                  depositoIdOriginal > 0 ? depositoIdOriginal : null,
            );
          }
        } else {
          if (depositoIdOriginal > 0) {
            depositoGuardado = await notifier.registrarDeposito(
              null,
              idDepositoActualizacion: depositoIdOriginal,
            );
          } else {
            depositoGuardado = await notifier.registrarDeposito(null);
          }
        }
      } catch (e) {
        // No hacer nada, el error se maneja abajo
      }

      // Devolver resultado
      final depositoActualizado = {
        'empresa': empresaSeleccionada?.nombre,
        'cliente': clienteSeleccionado?.nombreCompleto,
        'banco': bancoSeleccionado?.nombreBanco,
        'aCuenta': aCuenta,
        'importe': importeDeposito,
        'id': depositoIdOriginal,
        'observacion': _observacionesController.text,
      };

      if (mounted) {
        setState(() {
          cargando = false;
        });
      }

      if (todasGuardadas && depositoGuardado) {
        Navigator.pop(context, depositoActualizado);
      } else if (!todasGuardadas) {
        _mostrarError('Hubo problemas al guardar algunos documentos');
      } else {
        _mostrarError('Hubo un problema al guardar el depósito');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          cargando = false;
        });
        _mostrarError('Error al guardar: $e');
      }
    }
  }

  @override
  void dispose() {
    _aCuentaController.dispose();
    _observacionesController.dispose();
    _verticalController?.dispose();
    _horizontalController?.dispose();
    super.dispose();
  }

  // Añadir este nuevo método dentro de la clase _ActualizacionDepositoDialogState:
  Widget _buildDocumentosTable() {
    final state = ref.watch(depositosChequesProvider);
    final notasRemision = state.notasRemision;
    final notasSeleccionadas = state.notasSeleccionadas;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    
    // Configurar un ancho mínimo para la tabla
    final double tableMinWidth = isDesktop ? 800.0 : 700.0;
    
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.grey.shade300,
        dataTableTheme: DataTableThemeData(
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isDesktop ? 14 : 13,
            color: Colors.teal.shade800,
          ),
          dataTextStyle: TextStyle(
            fontSize: isDesktop ? 14 : 13,
            color: Colors.black87,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Scrollbar(
          thumbVisibility: true,
          controller: _verticalController,
          thickness: 8,
          radius: Radius.circular(4),
          child: Scrollbar(
            thumbVisibility: true,
            controller: _horizontalController,
            thickness: 8,
            radius: Radius.circular(4),
            notificationPredicate: (notif) => notif.depth == 1 && notif.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              controller: _verticalController,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: tableMinWidth,
                  ),
                  child: DataTable(
                    columnSpacing: isDesktop ? 20 : 16,
                    headingRowHeight: 50,
                    dataRowHeight: 56,
                    dividerThickness: 1,
                    headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                    border: TableBorder(
                      top: BorderSide(width: 1, color: Colors.grey.shade300),
                      bottom: BorderSide(width: 1, color: Colors.grey.shade300),
                      left: BorderSide.none,
                      right: BorderSide.none,
                      verticalInside: BorderSide(width: 1, color: Colors.grey.shade200),
                      horizontalInside: BorderSide(width: 1, color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    columns: [
                      DataColumn(
                        label: Row(
                          children: [
                            Icon(Icons.check_box_outline_blank, size: 16, color: Colors.teal.shade800),
                            SizedBox(width: 4),
                            Text('Seleccionar'),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Row(
                          children: [
                            Icon(Icons.description, size: 16, color: Colors.teal.shade800),
                            SizedBox(width: 4),
                            Text('Número Doc.'),
                          
                    ]),
            
                      ),
                      DataColumn(
                        label: Row(
                          children: [
                            Icon(Icons.receipt, size: 16, color: Colors.teal.shade800),
                            SizedBox(width: 4),
                            Text('Num. Factura'),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.teal.shade800),
                            SizedBox(width: 4),
                            Text('Fecha'),
                          ]
                        ),
                      ),
                      DataColumn(
                        label: Row(
                          children: [
                            Icon(Icons.attach_money, size: 16, color: Colors.teal.shade800),
                            SizedBox(width: 4),
                            Text('Total (Bs)'),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Row(
                          children: [
                            Icon(Icons.account_balance_wallet, size: 16, color: Colors.teal.shade800),
                            SizedBox(width: 4),
                            Text('Saldo Pendiente'),
                          ],
                        ),
                      ),
                    ],
                    rows: notasRemision.map<DataRow>((doc) {
                      final seleccionado = notasSeleccionadas.contains(doc.docNum);
                      final saldoValue = state.saldosEditados[doc.docNum]?.toString() ??
                          doc.saldoPendiente.toString();
                      
                      // Utilizar una key única para cada fila para mantener el estado
                      return DataRow(
                        key: ValueKey('doc_${doc.docNum}_${seleccionado ? '1' : '0'}'),
                        color: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (seleccionado) return Colors.teal.shade50;
                            if (states.contains(MaterialState.hovered)) return Colors.grey.shade50;
                            return null;
                          },
                        ),
                        cells: [
                          DataCell(
                            Container(
                              key: ValueKey('check_${doc.docNum}_${seleccionado ? '1' : '0'}'),
                              child: Checkbox(
                                value: seleccionado,
                                activeColor: Colors.teal.shade600,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (value) => _toggleDocumentoSeleccionado(
                                  doc.docNum,
                                  value ?? false,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                doc.docNum.toString(),
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          DataCell(Text(doc.numFact.toString())),
                          DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Text(
                                doc.fecha != null
                                    ? "${doc.fecha!.day.toString().padLeft(2, '0')}/${doc.fecha!.month.toString().padLeft(2, '0')}/${doc.fecha!.year}"
                                    : '',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              doc.totalMonto.toStringAsFixed(2),
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          DataCell(
                            seleccionado
                                ? Container(
                                    key: ValueKey('editable_${doc.docNum}_${seleccionado ? '1' : '0'}'),
                                    child: EditableSaldoPendienteCell(
                                      valorOriginal: doc.saldoPendiente,
                                      valorActual: saldoValue,
                                      onChanged: (v, showError) {
                                        final val = double.tryParse(v) ?? 0.0;
                                        if (val <= doc.saldoPendiente) {
                                          ref
                                              .read(depositosChequesProvider.notifier)
                                              .editarSaldoPendiente(doc.docNum, val);
                                          _actualizarTotales();
                                        }
                                        showError(val > doc.saldoPendiente);
                                      },
                                    ),
                                  )
                                : Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      doc.saldoPendiente.toStringAsFixed(2),
                                      style: TextStyle(fontWeight: FontWeight.w400),
                                    ),
                                  ),
                          ),
                        ],
                      );
                    }).toList(growable: false),
                  ),
                ),
              ),
            ),
          ),
        ),
      )
    );
  }
}

// Método para mostrar el diálogo desde cualquier parte de la aplicación
Future<Map<String, dynamic>?> mostrarActualizacionDeposito(
  BuildContext context,
  Map<String, dynamic> deposito,
) async {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return ActualizacionDepositoDialog(deposito: deposito);
    },
  );
}
