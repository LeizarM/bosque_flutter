import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/domain/entities/banco_cuenta_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/socio_negocio_entity.dart';
import 'package:bosque_flutter/presentation/screens/depositos-cheques/deposito_cheque_register_screen.dart';
import 'package:bosque_flutter/presentation/screens/depositos-cheques/editable_saldo_pendiente_cell.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/state/depositos_cheques_provider.dart';
import '../../../core/utils/responsive_utils_bosque.dart';

/// Estado propio de la lista, descartado al salir: cada visita empieza limpia.
/// La pantalla lo observa con `ref.watch` mientras está abierta; sin oyentes,
/// `autoDispose` lo destruiría (el diálogo usa su propio provider).
final depositosChequesIdentificarViewProvider =
    StateNotifierProvider.autoDispose<
      DepositosChequesNotifier,
      DepositosChequesState
    >((ref) => DepositosChequesNotifier(ref));

class DepositoChequeIdentificarViewScreen extends ConsumerStatefulWidget {
  const DepositoChequeIdentificarViewScreen({super.key});

  @override
  ConsumerState<DepositoChequeIdentificarViewScreen> createState() =>
      _DepositoChequeIdentificarViewScreenState();
}

class _DepositoChequeIdentificarViewScreenState
    extends ConsumerState<DepositoChequeIdentificarViewScreen> {
  // Sin fecha elegida se envía la consulta sin rango (los pendientes pueden ser
  // antiguos): el texto de los campos dice lo que realmente se consulta.
  static const String _textoTodasLasFechas = 'Todas las fechas';

  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  final TextEditingController _fechaDesdeController = TextEditingController(
    text: _textoTodasLasFechas,
  );
  final TextEditingController _fechaHastaController = TextEditingController(
    text: _textoTodasLasFechas,
  );

  // Antes de la primera búsqueda no se puede afirmar que «no hay depósitos».
  bool _yaBusco = false;

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

  void _buscar(DepositosChequesNotifier notifier) {
    setState(() => _yaBusco = true);
    notifier.buscarDepositosPorIdentificar(
      idBxC: 0,
      fechaDesde: _fechaDesde,
      fechaHasta: _fechaHasta,
      codCliente: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = depositosChequesIdentificarViewProvider;
    final notifier = ref.read(provider.notifier);
    // Solo lo que cambia este cuerpo: la tabla no se desmonta mientras se busca.
    final buscando = ref.watch(provider.select((s) => s.buscando));
    final sinDatos = ref.watch(provider.select((s) => s.depositos.isEmpty));
    final error = ref.watch(provider.select((s) => s.error));

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
              const SizedBox(height: 20),
              // Hueco fijo para la barra (20 + 4 = los 24 de siempre): el
              // contenido no salta al buscar.
              SizedBox(
                height: 4,
                child: buscando ? const LinearProgressIndicator() : null,
              ),
              // Con datos y un fallo de la última búsqueda: aviso con reintento
              // sobre la tabla (sin datos lo muestra la propia tabla).
              if (error != null && !buscando && !sinDatos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MensajeError(
                    error: error,
                    onReintentar: () => _buscar(notifier),
                    compacto: true,
                  ),
                ),
              Expanded(
                child: _DepositosIdentificarTable(
                  yaBusco: _yaBusco,
                  onBuscar: () => _buscar(notifier),
                ),
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

  Widget _buildSearchForm(
    BuildContext context,
    DepositosChequesNotifier notifier,
  ) {
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final colorScheme = Theme.of(context).colorScheme;

    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.6),
        ),
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
              prefixIcon: Icon(
                Icons.calendar_today,
                color: colorScheme.primary,
              ),
            ),
            onTap: () => _pickDate(context, true),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fechaHastaController,
            readOnly: true,
            decoration: inputDecoration.copyWith(
              labelText: 'Hasta',
              prefixIcon: Icon(
                Icons.calendar_today,
                color: colorScheme.primary,
              ),
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
            onPressed: () => _buscar(notifier),
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
              suffixIcon: Icon(
                Icons.calendar_today,
                color: colorScheme.primary,
              ),
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
              suffixIcon: Icon(
                Icons.calendar_today,
                color: colorScheme.primary,
              ),
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
          onPressed: () => _buscar(notifier),
        ),
      ],
    );
  }
}

class _DepositosIdentificarTable extends ConsumerWidget {
  const _DepositosIdentificarTable({
    required this.yaBusco,
    required this.onBuscar,
  });

  /// Ya se pulsó Buscar al menos una vez (ver la pantalla).
  final bool yaBusco;
  final VoidCallback onBuscar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = depositosChequesIdentificarViewProvider;
    final notifier = ref.read(provider.notifier);
    // Solo lo que dibuja la tabla: marcar un PDF en curso no la reconstruye.
    final datos = ref.watch(
      provider.select(
        (s) => (
          depositos: s.depositos,
          page: s.page,
          rowsPerPage: s.rowsPerPage,
          total: s.totalRegistros,
          error: s.error,
          buscando: s.buscando,
        ),
      ),
    );
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final depositos = datos.depositos;
    final page = datos.page;
    final rowsPerPage = datos.rowsPerPage;
    final total = datos.total;
    final start = total == 0 ? 0 : (page * rowsPerPage) + 1;
    final end = ((page + 1) * rowsPerPage).clamp(0, total);
    final paged = depositos.skip(page * rowsPerPage).take(rowsPerPage).toList();

    // Función para mostrar el diálogo de asignar cliente
    Future<void> mostrarDialogoAsignarCliente(dynamic deposito) async {
      final int idDeposito = deposito.idDeposito;
      // Mapear los datos del depósito para pasarlos al diálogo
      final Map<String, dynamic> datosDeposito = {
        'id': idDeposito,
        'empresa': deposito.nombreEmpresa,
        'banco': deposito.nombreBanco,
        // Códigos para localizar empresa y banco sin depender del nombre.
        'codEmpresa': deposito.codEmpresa,
        'idBxC': deposito.idBxC,
        'importe': deposito.importe,
        'moneda': deposito.moneda,
        'fecha': deposito.fechaI,
        'estado': deposito.esPendiente,
        'observacion': deposito.obs,
      };

      final result = await mostrarActualizacionDeposito(context, datosDeposito);

      // Ya identificado: sale de la lista en memoria, sin repetir la consulta.
      if (result != null && context.mounted) {
        notifier.quitarDeposito(idDeposito);
        mostrarAviso(context, 'Depósito actualizado correctamente');
      }
    }

    if (depositos.isEmpty) {
      // Sin datos aún: el spinner ocupa el lugar de la tabla vacía.
      if (datos.buscando) {
        return const Center(child: CircularProgressIndicator());
      }
      // Un fallo no es «no hay depósitos»: se dice y se deja reintentar.
      if (datos.error != null) {
        return MensajeError(error: datos.error, onReintentar: onBuscar);
      }
      return Center(
        child: Text(
          yaBusco
              ? 'No hay depósitos pendientes por identificar'
              : 'Pulsa Buscar para ver los depósitos pendientes por identificar',
          textAlign: TextAlign.center,
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
                final esVerificado = d.esPendiente.toLowerCase().contains(
                  'verific',
                );
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!esVerificado) // Solo mostrar el botón si NO está verificado
                              IconButton(
                                icon: const Icon(
                                  Icons.person,
                                  color: Colors.orange,
                                ),
                                tooltip: 'Asignar Cliente',
                                onPressed:
                                    () => mostrarDialogoAsignarCliente(d),
                              ),
                            _PdfDepositoButton(idDeposito: d.idDeposito),
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
                  mostrarDialogoAsignarCliente,
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
                  mostrarDialogoAsignarCliente,
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
              _customDataColumn('Acciones', 110),
            ],
            rows:
                paged.map((d) {
                  final esVerificado = d.esPendiente.toLowerCase().contains(
                    'verific',
                  );
                  return DataRow(
                    cells: [
                      _customDataCell(Text(d.idDeposito.toString()), 60),
                      _customDataCell(Text(d.nombreCompleto), 90),
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
                      _customDataCell(
                        Text(d.obs, overflow: TextOverflow.ellipsis),
                        180,
                      ),
                      _customDataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!esVerificado)
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
                            _PdfDepositoButton(idDeposito: d.idDeposito),
                          ],
                        ),
                        110,
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
    return DataColumn(label: SizedBox(width: width, child: Text(label)));
  }

  // Celda de DataTable con ancho controlado
  DataCell _customDataCell(Widget child, double width) {
    return DataCell(SizedBox(width: width, child: child));
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

// Botón para descargar/imprimir el PDF de un depósito (backend genera el PDF).
// El «en curso» vive en el provider, por fila: no bloquea ni reconstruye la
// tabla, y el aviso de éxito o error lo da el propio notifier.
class _PdfDepositoButton extends ConsumerWidget {
  final int idDeposito;
  const _PdfDepositoButton({required this.idDeposito});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = depositosChequesIdentificarViewProvider;
    final descargando = ref.watch(
      provider.select((s) => s.pdfsEnCurso.contains(idDeposito)),
    );
    return IconButton(
      icon:
          descargando
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
      tooltip: 'Descargar PDF',
      // El notifier revisa `context.mounted` tras esperar al servidor.
      onPressed:
          descargando
              ? null
              : () => ref
                  .read(provider.notifier)
                  .descargarPdfDeposito(idDeposito, context),
      constraints: const BoxConstraints(maxWidth: 32),
      padding: EdgeInsets.zero,
    );
  }
}

// Implementación del diálogo para actualizar depósitos
class ActualizacionDepositoDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> deposito;

  const ActualizacionDepositoDialog({super.key, required this.deposito});

  @override
  ConsumerState<ActualizacionDepositoDialog> createState() =>
      _ActualizacionDepositoDialogState();
}

/// Suma de los saldos de las notas marcadas (con el saldo editado, si lo hay).
/// Se calcula a partir del estado: no hay un total aparte que mantener al día.
double _totalDocumentos(DepositosChequesState s) {
  if (s.notasSeleccionadas.isEmpty) return 0;
  final marcadas = s.notasSeleccionadas.toSet();
  var total = 0.0;
  for (final nota in s.notasRemision) {
    if (marcadas.contains(nota.docNum)) {
      total += s.saldosEditados[nota.docNum] ?? nota.saldoPendiente;
    }
  }
  return total;
}

/// Igualdad a centavos: sumar decimales en `double` no da el valor exacto.
bool _montosIguales(double a, double b) => (a - b).abs() < 0.005;

class _ActualizacionDepositoDialogState
    extends ConsumerState<ActualizacionDepositoDialog> {
  // Variables para controlar el estado del formulario
  EmpresaEntity? empresaSeleccionada;
  SocioNegocioEntity? clienteSeleccionado;
  BancoXCuentaEntity? bancoSeleccionado;
  XFile? imagenSeleccionada;
  double importeDeposito = 0;
  bool _guardando = false;
  Uint8List? _webImageBytes;

  final _formKey = GlobalKey<FormState>();
  // «A cuenta» vive solo en su controlador: el resumen de importes lo escucha y
  // se reconstruye él solo; al provider pasa al guardar.
  final TextEditingController _aCuentaController = TextEditingController(
    text: '0.00',
  );
  final TextEditingController _observacionesController =
      TextEditingController();
  final TextEditingController _clienteController = TextEditingController();

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  double get aCuenta => double.tryParse(_aCuentaController.text) ?? 0;

  @override
  void initState() {
    super.initState();
    // Inicializar con valores predeterminados
    importeDeposito = widget.deposito['importe'] ?? 0.0;
    _observacionesController.text = widget.deposito['observacion'] ?? '';

    // El banco del depósito se elige en cuanto llegan los bancos, sin esperar
    // a los clientes (se piden en paralelo).
    ref.listenManual(
      depositosChequesProvider.select((s) => s.bancos),
      (_, bancos) => _elegirBancoDelDeposito(bancos),
    );

    // Fuera del build: toca un provider global y pide datos.
    Future.microtask(_cargarDatosIniciales);
  }

  /// Apertura: empresas (solo si faltan) -> empresa del depósito -> bancos y
  /// clientes en paralelo. No se preselecciona ningún cliente: asignar el
  /// depósito al cliente equivocado es peor que pedir que se elija uno.
  Future<void> _cargarDatosIniciales() async {
    if (!mounted) return;

    // Limpiar cualquier imagen previa (provider global del registro)
    if (kIsWeb) {
      ref.read(imageBytesProvider.notifier).state = null;
    }

    final notifier = ref.read(depositosChequesProvider.notifier);
    await notifier.cargarEmpresasSiFalta();
    if (!mounted) return;

    final empresa = _empresaDelDeposito(
      ref.read(depositosChequesProvider).empresas,
    );
    // Sin empresas el error queda visible en el diálogo, con «Reintentar».
    if (empresa == null) return;

    setState(() => empresaSeleccionada = empresa);
    await notifier.seleccionarEmpresa(empresa);
  }

  /// Empresa del depósito: por código y, si no, por nombre. El selector es de
  /// solo lectura, así que sin coincidencia se conserva lo de antes: la primera.
  EmpresaEntity? _empresaDelDeposito(List<EmpresaEntity> empresas) {
    final reales = empresas.where((e) => e.codEmpresa != 0).toList();
    if (reales.isEmpty) return null;
    final codigo = widget.deposito['codEmpresa'];
    final nombre = widget.deposito['empresa'];
    return reales
            .where((e) => codigo is int && e.codEmpresa == codigo)
            .firstOrNull ??
        reales.where((e) => e.nombre == nombre).firstOrNull ??
        reales.first;
  }

  /// Banco del depósito: por `idBxC` y, si no, por nombre. Sin coincidencia se
  /// deja vacío para que se elija (antes se tomaba el primero, y el depósito
  /// quedaba con un banco que nadie eligió).
  void _elegirBancoDelDeposito(List<BancoXCuentaEntity> bancos) {
    if (!mounted || bancos.isEmpty || bancoSeleccionado != null) return;
    final idBxC = widget.deposito['idBxC'];
    final nombre = widget.deposito['banco'];
    final banco =
        bancos
            .where((b) => idBxC is int && idBxC > 0 && b.idBxC == idBxC)
            .firstOrNull ??
        bancos.where((b) => b.nombreBanco == nombre).firstOrNull;
    if (banco != null) setState(() => bancoSeleccionado = banco);
  }

  /// «Reintentar» del aviso de error: repite solo lo que falló.
  Future<void> _reintentar() async {
    final empresa = empresaSeleccionada;
    if (empresa == null) return _cargarDatosIniciales();

    final notifier = ref.read(depositosChequesProvider.notifier);
    final s = ref.read(depositosChequesProvider);
    final cliente = clienteSeleccionado;
    if (cliente != null && s.bancos.isNotEmpty && s.clientes.isNotEmpty) {
      // Bancos y clientes llegaron: falló solo la carga de sus documentos.
      await notifier.seleccionarCliente(cliente);
      return;
    }
    setState(() {
      clienteSeleccionado = null;
      _clienteController.clear();
      bancoSeleccionado = null;
    });
    await notifier.seleccionarEmpresa(empresa);
  }

  /// Fija el cliente (o lo quita con `null`). La pantalla no se bloquea: los
  /// documentos muestran su propio avance mientras llegan.
  Future<void> _elegirCliente(SocioNegocioEntity? cliente) async {
    setState(() {
      clienteSeleccionado = cliente;
      _clienteController.text = cliente?.nombreCompleto ?? '';
    });
    await ref
        .read(depositosChequesProvider.notifier)
        .seleccionarCliente(cliente);
  }

  Future<void> _buscarCliente() async {
    final s = ref.read(depositosChequesProvider);
    if (s.cargandoClientes) return;
    // «Todos» (sin código) no es un cliente al que se pueda asignar el depósito.
    final clientes = s.clientes.where((c) => c.codCliente.isNotEmpty).toList();
    final seleccionado = await showDialog(
      context: context,
      builder:
          (context) => ClienteSearchDialog(
            clientes: clientes,
            onClienteSelected: (cliente) {
              Navigator.pop(context, cliente);
            },
          ),
    );
    if (!mounted || seleccionado is! SocioNegocioEntity) return;
    await _elegirCliente(seleccionado);
  }

  // Método para manejar la selección de imágenes
  Future<void> _seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();
    try {
      XFile? imagen;
      if (kIsWeb) {
        // En web, solo galería
        imagen = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1800,
          maxHeight: 1800,
          imageQuality: 85,
        );
      } else {
        // En móvil, mostrar opción de cámara o galería
        final contextMenu = await showModalBottomSheet<ImageSource>(
          context: context,
          builder:
              (context) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_library),
                      title: const Text('Galería'),
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text('Cámara'),
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
        );
        if (contextMenu != null) {
          imagen = await picker.pickImage(
            source: contextMenu,
            maxWidth: 1800,
            maxHeight: 1800,
            imageQuality: 85,
          );
        }
      }

      if (imagen != null) {
        // En web hay que leer los bytes. Se leen antes de actualizar, para que
        // nunca quede una imagen «elegida» sin bytes que enviar.
        final bytes = kIsWeb ? await imagen.readAsBytes() : null;
        if (!mounted) return;
        setState(() {
          imagenSeleccionada = imagen;
          _webImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        mostrarAviso(
          context,
          'No se pudo seleccionar la imagen: ${textoParaUsuario(e)}',
          tono: TonoAviso.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsividad
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final isTablet = ResponsiveUtilsBosque.isTablet(context);
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(
      context,
    );
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);
    final pantalla = MediaQuery.sizeOf(context);
    final maxDialogWidth =
        isMobile
            ? pantalla.width * 0.98
            : isTablet
            ? 600.0
            : 700.0;
    final maxDialogHeight =
        isMobile ? pantalla.height * 0.98 : pantalla.height * 0.85;

    // Cada dato se observa por separado (select): escribir en «A cuenta» u
    // «Observaciones» o marcar un documento no reconstruye el formulario.
    final provider = depositosChequesProvider;
    final empresas = ref.watch(provider.select((s) => s.empresas));
    final bancos = ref.watch(provider.select((s) => s.bancos));
    final cargandoEmpresas = ref.watch(
      provider.select((s) => s.cargandoEmpresas),
    );
    final cargandoClientes = ref.watch(
      provider.select((s) => s.cargandoClientes),
    );
    final cargandoBancos = ref.watch(provider.select((s) => s.cargandoBancos));
    final error = ref.watch(provider.select((s) => s.error));

    // El formulario siempre está montado: cada sección muestra su avance.
    final hintEmpresa =
        cargandoEmpresas ? 'Cargando empresas...' : 'Seleccione una empresa';
    final hintBanco =
        cargandoBancos ? 'Cargando bancos...' : 'Seleccione un banco';

    return PopScope(
      // Mientras se guarda no se cierra con «atrás»: dejaría el guardado a medias.
      canPop: !_guardando,
      child: Dialog(
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
                            onPressed:
                                _guardando
                                    ? null
                                    : () => Navigator.pop(context),
                            tooltip: 'Cerrar',
                          ),
                        ],
                      ),
                      SizedBox(height: verticalPadding),

                      // Fallo de una carga (empresas, bancos, clientes, documentos)
                      if (error != null) ...[
                        MensajeError(
                          error: error,
                          onReintentar: _reintentar,
                          compacto: true,
                        ),
                        SizedBox(height: verticalPadding),
                      ],

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
                              fontSize:
                                  ResponsiveUtilsBosque.getResponsiveValue(
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
                        hint: Text(hintEmpresa),
                        items:
                            empresas
                                .where(
                                  (e) => e.codEmpresa != 0,
                                ) // Filtrar "Todos"
                                .map((empresa) {
                                  return DropdownMenuItem<EmpresaEntity>(
                                    value: empresa,
                                    child: Text(empresa.nombre),
                                  );
                                })
                                .toList(),
                        onChanged:
                            null, // <-- Deshabilita el dropdown (solo lectura)
                        disabledHint:
                            empresaSeleccionada != null
                                ? Text(empresaSeleccionada!.nombre)
                                : Text(hintEmpresa),
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
                          hintText:
                              cargandoClientes
                                  ? 'Cargando clientes...'
                                  : 'Buscar cliente',
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          suffixIcon:
                              clienteSeleccionado != null
                                  ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () => _elegirCliente(null),
                                  )
                                  : null,
                        ),
                        controller: _clienteController,
                        onTap: _buscarCliente,
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
                                hint: Text(hintBanco),
                                isExpanded: true,
                                items:
                                    bancos.map((banco) {
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
                                onChanged: _cambiarBanco,
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
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
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
                                      hint: Text(hintBanco),
                                      isExpanded: true,
                                      items:
                                          bancos.map((banco) {
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
                                      onChanged: _cambiarBanco,
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
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
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
                        // Sin `onChanged`: el texto pasa al provider al guardar.
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
                        child: _DocumentosSeccion(
                          hayCliente: clienteSeleccionado != null,
                          verticalController: _verticalController,
                          horizontalController: _horizontalController,
                        ),
                      ),

                      SizedBox(height: verticalPadding),

                      // Totales, importe y validación
                      _ResumenImportes(
                        aCuentaController: _aCuentaController,
                        importeDeposito: importeDeposito,
                        isMobile: isMobile,
                        horizontalPadding: horizontalPadding,
                        verticalPadding: verticalPadding,
                      ),

                      SizedBox(height: verticalPadding),
                      // Botones de acción
                      isMobile
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton(
                                onPressed:
                                    _guardando
                                        ? null
                                        : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                child: const Text('Cancelar'),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _guardando ? null : _validarYGuardar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                child: _textoGuardar(context),
                              ),
                            ],
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed:
                                    _guardando
                                        ? null
                                        : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Cancelar'),
                              ),
                              SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _guardando ? null : _validarYGuardar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                ),
                                child: _textoGuardar(context),
                              ),
                            ],
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _cambiarBanco(BancoXCuentaEntity? nuevo) {
    if (nuevo == null) return;
    setState(() => bancoSeleccionado = nuevo);
    ref.read(depositosChequesProvider.notifier).seleccionarBanco(nuevo);
  }

  /// «Guardar», o un indicador mientras el guardado está en curso.
  Widget _textoGuardar(BuildContext context) {
    if (!_guardando) return const Text('Guardar');
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  void _validarYGuardar() {
    if (_formKey.currentState!.validate() && _validarFormulario()) {
      _guardarDepositoYNotas();
    }
  }

  bool _validarFormulario() {
    if (empresaSeleccionada == null) {
      _mostrarError('Debe seleccionar una empresa');
      return false;
    }

    // Sin código no es un cliente real (p. ej. el «Todos» del listado).
    if (clienteSeleccionado == null ||
        clienteSeleccionado!.codCliente.isEmpty) {
      _mostrarError('Debe seleccionar un cliente');
      return false;
    }

    if (bancoSeleccionado == null) {
      _mostrarError('Debe seleccionar un banco');
      return false;
    }

    // En web hacen falta los bytes, no solo el archivo elegido.
    if (imagenSeleccionada == null || (kIsWeb && _webImageBytes == null)) {
      _mostrarError('Debe seleccionar una imagen del depósito');
      return false;
    }

    final estado = ref.read(depositosChequesProvider);
    if (estado.notasSeleccionadas.isEmpty && aCuenta <= 0) {
      _mostrarError(
        'Debe seleccionar al menos un documento o ingresar un valor a cuenta',
      );
      return false;
    }

    // Verificar que el total coincida con el importe del depósito
    final totalDocumentos = _totalDocumentos(estado);
    final total = totalDocumentos + aCuenta;
    if (totalDocumentos > 0 && !_montosIguales(total, importeDeposito)) {
      _mostrarError(
        'El total (${total.toStringAsFixed(2)}) debe ser igual al importe del depósito (${importeDeposito.toStringAsFixed(2)})',
      );
      return false;
    }

    return true;
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      mostrarAviso(context, mensaje, tono: TonoAviso.error);
    }
  }

  /// El texto de un error sin el punto final, para poder seguir la frase.
  String _motivo(Object? error) {
    final texto = textoParaUsuario(error).trim();
    return texto.endsWith('.') ? texto.substring(0, texto.length - 1) : texto;
  }

  Future<void> _guardarDepositoYNotas() async {
    // Anti doble clic: el segundo toque no llega ni a pedir nada.
    if (!mounted || _guardando) return;
    setState(() => _guardando = true);

    final notifier = ref.read(depositosChequesProvider.notifier);
    try {
      final int depositoIdOriginal = widget.deposito['id'] ?? 0;

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
      // Moneda del depósito: sin esto se enviaba siempre la del estado inicial.
      final moneda = widget.deposito['moneda'];
      if (moneda is String && moneda.isNotEmpty) {
        notifier.seleccionarMoneda(moneda);
      }

      // Web: bytes; móvil: archivo.
      final dynamic imagen =
          kIsWeb
              ? _webImageBytes
              : (imagenSeleccionada != null
                  ? File(imagenSeleccionada!.path)
                  : null);

      // Un solo paso: primero las notas (con su idDeposito) y, solo si todas
      // se guardaron, actualiza el depósito. El reintento envía lo pendiente.
      final r = await notifier.asignarDeposito(
        idDeposito: depositoIdOriginal,
        imagen: imagen,
      );
      if (!mounted || r.ignorado) return;

      if (r.ok) {
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
        Navigator.pop(context, depositoActualizado);
      } else if (!r.notas.ok) {
        _mostrarError(
          '${r.notas.fallidas.length} nota(s) no se guardaron: ${_motivo(r.notas.error)}. '
          'Pulsa Guardar para reintentar solo las pendientes.',
        );
      } else {
        _mostrarError(
          'No se pudo actualizar el depósito. Las notas de remisión ya quedaron '
          'guardadas; pulsa Guardar para reintentar.',
        );
      }
    } catch (e) {
      // Actualizar el depósito falló (las notas, si había, ya se guardaron).
      if (!mounted) return;
      final notasYaGuardadas =
          ref.read(depositosChequesProvider).notasGuardadas.isNotEmpty;
      _mostrarError(
        notasYaGuardadas
            ? 'No se pudo actualizar el depósito: ${_motivo(e)}. Las notas de remisión ya quedaron guardadas; pulsa Guardar para reintentar.'
            : 'No se pudo guardar: ${_motivo(e)}.',
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    _aCuentaController.dispose();
    _observacionesController.dispose();
    _clienteController.dispose();
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }
}

/// Contenido de «Documentos Disponibles»: avance, aviso o tabla. Observa solo
/// su parte del estado, así que el resto del formulario no se reconstruye.
class _DocumentosSeccion extends ConsumerWidget {
  const _DocumentosSeccion({
    required this.hayCliente,
    required this.verticalController,
    required this.horizontalController,
  });

  final bool hayCliente;
  final ScrollController verticalController;
  final ScrollController horizontalController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = depositosChequesProvider;
    final cargandoNotas = ref.watch(provider.select((s) => s.cargandoNotas));
    final hayNotas = ref.watch(
      provider.select((s) => s.notasRemision.isNotEmpty),
    );

    if (cargandoNotas) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!hayNotas) {
      return Center(
        child: Text(
          hayCliente
              ? 'No hay documentos disponibles para este cliente'
              : 'Seleccione un cliente para ver sus documentos',
        ),
      );
    }
    return _DocumentosTable(
      verticalController: verticalController,
      horizontalController: horizontalController,
    );
  }
}

/// Totales, importe del depósito y aviso de descuadre. «A cuenta» llega por su
/// controlador y los documentos por el estado; solo este bloque se reconstruye
/// con cada tecla o cada saldo editado.
class _ResumenImportes extends ConsumerWidget {
  const _ResumenImportes({
    required this.aCuentaController,
    required this.importeDeposito,
    required this.isMobile,
    required this.horizontalPadding,
    required this.verticalPadding,
  });

  final TextEditingController aCuentaController;
  final double importeDeposito;
  final bool isMobile;
  final double horizontalPadding;
  final double verticalPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalDocumentos = ref.watch(
      depositosChequesProvider.select(_totalDocumentos),
    );

    return ListenableBuilder(
      listenable: aCuentaController,
      builder: (context, _) {
        final aCuenta = double.tryParse(aCuentaController.text) ?? 0;
        final descuadre =
            totalDocumentos > 0 &&
            !_montosIguales(totalDocumentos + aCuenta, importeDeposito);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                                  border: Border.all(color: Colors.grey[300]!),
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
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('${aCuenta.toStringAsFixed(2)} BS'),
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
                              border: Border.all(color: Colors.grey[300]!),
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
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('${aCuenta.toStringAsFixed(2)} BS'),
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
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
            descuadre
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
          ],
        );
      },
    );
  }
}

/// Tabla de documentos (notas de remisión) del cliente elegido.
///
/// Observa solo `notasRemision` y `notasSeleccionadas`. `saldosEditados` no se
/// observa: la celda editable conserva su propio texto y los totales los da
/// [_ResumenImportes]; así, escribir un saldo no reconstruye todas las filas.
/// El saldo editado se lee al construir cada fila (p. ej. al volver a marcarla).
class _DocumentosTable extends ConsumerWidget {
  const _DocumentosTable({
    required this.verticalController,
    required this.horizontalController,
  });

  final ScrollController verticalController;
  final ScrollController horizontalController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = depositosChequesProvider;
    final notasRemision = ref.watch(provider.select((s) => s.notasRemision));
    final notasSeleccionadas = ref.watch(
      provider.select((s) => s.notasSeleccionadas),
    );
    final saldosEditados = ref.read(provider).saldosEditados;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Scrollbar(
          thumbVisibility: true,
          controller: verticalController,
          thickness: 8,
          radius: Radius.circular(4),
          child: Scrollbar(
            thumbVisibility: true,
            controller: horizontalController,
            thickness: 8,
            radius: Radius.circular(4),
            notificationPredicate:
                (notif) =>
                    notif.depth == 1 && notif.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              controller: verticalController,
              child: SingleChildScrollView(
                controller: horizontalController,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: tableMinWidth),
                  child: DataTable(
                    columnSpacing: isDesktop ? 20 : 16,
                    headingRowHeight: 50,
                    dataRowHeight: 56,
                    dividerThickness: 1,
                    headingRowColor: WidgetStateProperty.all(
                      Colors.grey.shade100,
                    ),
                    border: TableBorder(
                      top: BorderSide(width: 1, color: Colors.grey.shade300),
                      bottom: BorderSide(width: 1, color: Colors.grey.shade300),
                      left: BorderSide.none,
                      right: BorderSide.none,
                      verticalInside: BorderSide(
                        width: 1,
                        color: Colors.grey.shade200,
                      ),
                      horizontalInside: BorderSide(
                        width: 1,
                        color: Colors.grey.shade200,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    columns: [
                      DataColumn(
                        label: Row(
                          children: [
                            Icon(
                              Icons.check_box_outline_blank,
                              size: 16,
                              color: Colors.teal.shade800,
                            ),
                            SizedBox(width: 4),
                            Text('Seleccionar'),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Row(
                          children: [
                            Icon(
                              Icons.description,
                              size: 16,
                              color: Colors.teal.shade800,
                            ),
                            SizedBox(width: 4),
                            Text('Número Doc.'),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Row(
                          children: [
                            Icon(
                              Icons.receipt,
                              size: 16,
                              color: Colors.teal.shade800,
                            ),
                            SizedBox(width: 4),
                            Text('Num. Factura'),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.teal.shade800,
                            ),
                            SizedBox(width: 4),
                            Text('Fecha'),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 16,
                              color: Colors.teal.shade800,
                            ),
                            SizedBox(width: 4),
                            Text('Total (Bs)'),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              size: 16,
                              color: Colors.teal.shade800,
                            ),
                            SizedBox(width: 4),
                            Text('Saldo Pendiente'),
                          ],
                        ),
                      ),
                    ],
                    rows: notasRemision
                        .map<DataRow>((doc) {
                          final seleccionado = notasSeleccionadas.contains(
                            doc.docNum,
                          );
                          final saldoValue =
                              saldosEditados[doc.docNum]?.toString() ??
                              doc.saldoPendiente.toString();

                          // La key NO lleva `seleccionado`: si cambiara, marcar
                          // una fila la desmontaría y la montaría de nuevo.
                          return DataRow(
                            key: ValueKey('doc_${doc.docNum}'),
                            color: WidgetStateProperty.resolveWith<Color?>((
                              Set<WidgetState> states,
                            ) {
                              if (seleccionado) return Colors.teal.shade50;
                              if (states.contains(WidgetState.hovered)) {
                                return Colors.grey.shade50;
                              }
                              return null;
                            }),
                            cells: [
                              DataCell(
                                Container(
                                  key: ValueKey('check_${doc.docNum}'),
                                  child: Checkbox(
                                    value: seleccionado,
                                    activeColor: Colors.teal.shade600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged:
                                        (value) => ref
                                            .read(provider.notifier)
                                            .seleccionarNota(
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(doc.numFact.toString())),
                              DataCell(
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue.shade100,
                                    ),
                                  ),
                                  child: Text(
                                    // ignore: unnecessary_null_comparison
                                    doc.fecha != null
                                        ? "${doc.fecha.day.toString().padLeft(2, '0')}/${doc.fecha.month.toString().padLeft(2, '0')}/${doc.fecha.year}"
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
                                      key: ValueKey('editable_${doc.docNum}'),
                                      child: EditableSaldoPendienteCell(
                                        valorOriginal: doc.saldoPendiente,
                                        valorActual: saldoValue,
                                        onChanged: (v, showError) {
                                          final val = double.tryParse(v) ?? 0.0;
                                          if (val <= doc.saldoPendiente) {
                                            ref
                                                .read(provider.notifier)
                                                .editarSaldoPendiente(
                                                  doc.docNum,
                                                  val,
                                                );
                                          }
                                          showError(val > doc.saldoPendiente);
                                        },
                                      ),
                                    )
                                    : Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Text(
                                        doc.saldoPendiente.toStringAsFixed(2),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                              ),
                            ],
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
