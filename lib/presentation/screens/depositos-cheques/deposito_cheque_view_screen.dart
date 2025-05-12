import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/depositos_cheques_provider.dart';
import '../../../domain/entities/empresa_entity.dart';
import '../../../domain/entities/banco_cuenta_entity.dart';
import '../../../domain/entities/socio_negocio_entity.dart';

class DepositoChequeViewScreen extends ConsumerWidget {
  const DepositoChequeViewScreen({super.key});

  static final estadosDeposito = const [
    {'label': 'Todos', 'value': 'Todos'},
    {'label': 'Verificado', 'value': 'Verificado'},
    {'label': 'Pendiente', 'value': 'Pendiente'},
    {'label': 'Rechazado', 'value': 'Rechazado'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(depositosChequesProvider);
    final notifier = ref.read(depositosChequesProvider.notifier);

    // Opción 'Todos' para empresa, banco y cliente
    final empresaTodos = EmpresaEntity(codEmpresa: 0, nombre: 'Todos', codPadre: 0, sigla: '', audUsuario: 0);
    final bancoTodos = BancoXCuentaEntity(idBxC: 0, codBanco: 0, numCuenta: '', moneda: '', codEmpresa: 0, audUsuario: 0, nombreBanco: 'Todos');
    final clienteTodos = SocioNegocioEntity(codCliente: '', datoCliente: '', razonSocial: '', nit: '', codCiudad: 0, datoCiudad: '', esVigente: '', codEmpresa: 0, audUsuario: 0, nombreCompleto: 'Todos');

    return Stack(
      children: [
        Opacity(
          opacity: state.cargando ? 0.5 : 1.0,
          child: IgnorePointer(
            ignoring: state.cargando,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, size: 32, color: Colors.black54),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Consulta de Depósitos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Busque y visualice los depósitos registrados', style: TextStyle(fontSize: 15, color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  // Criterios de búsqueda
                  const Text('Criterios de Búsqueda', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Empresa
                      Expanded(
                        child: DropdownButtonFormField<EmpresaEntity>(
                          value: state.empresaSeleccionada ?? empresaTodos,
                          decoration: const InputDecoration(labelText: 'Empresa'),
                          items: [
                            DropdownMenuItem<EmpresaEntity>(value: empresaTodos, child: const Text('Todos')),
                            ...state.empresas.map((e) => DropdownMenuItem<EmpresaEntity>(value: e, child: Text(e.nombre)))
                          ],
                          onChanged: (v) async {
                            notifier.seleccionarEmpresa(v?.codEmpresa == 0 ? null : v);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Banco
                      Expanded(
                        child: DropdownButtonFormField<BancoXCuentaEntity>(
                          value: state.bancoSeleccionado ?? bancoTodos,
                          decoration: const InputDecoration(labelText: 'Banco'),
                          items: [
                            DropdownMenuItem<BancoXCuentaEntity>(value: bancoTodos, child: const Text('Todos')),
                            ...state.bancos.map((b) => DropdownMenuItem<BancoXCuentaEntity>(value: b, child: Text(b.nombreBanco)))
                          ],
                          onChanged: (v) => notifier.seleccionarBanco(v?.idBxC == 0 ? null : v),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Desde
                      Expanded(
                        child: _DatePickerField(
                          label: 'Desde',
                          date: state.fechaDesde,
                          onChanged: notifier.setFechaDesde,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Hasta
                      Expanded(
                        child: _DatePickerField(
                          label: 'Hasta',
                          date: state.fechaHasta,
                          onChanged: notifier.setFechaHasta,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Cliente
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<SocioNegocioEntity>(
                          value: state.clienteSeleccionado ?? clienteTodos,
                          decoration: const InputDecoration(labelText: 'Cliente'),
                          items: [
                            DropdownMenuItem<SocioNegocioEntity>(value: clienteTodos, child: const Text('Todos')),
                            ...state.clientes.map((c) => DropdownMenuItem<SocioNegocioEntity>(value: c, child: Text(c.nombreCompleto)))
                          ],
                          onChanged: (v) => notifier.seleccionarCliente(v?.codCliente == '' ? null : v),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Estado
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: state.selectedEstado ?? 'Todos',
                          decoration: const InputDecoration(labelText: 'Estado'),
                          items: estadosDeposito
                              .map((e) => DropdownMenuItem<String>(value: e['value'], child: Text(e['label']!)))
                              .toList(),
                          onChanged: notifier.setEstado,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Botón Buscar
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                        ),
                        onPressed: notifier.buscarDepositos,
                        icon: const Icon(Icons.search, color: Colors.white),
                        label: const Text('Buscar/Actualizar', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Resultados
                  Row(
                    children: [
                      const Text('Resultados', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6C63FF),
                          side: const BorderSide(color: Color(0xFF6C63FF)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        onPressed: () {}, // TODO: Exportar PDF
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Exportar PDF'),
                      ),
                      const SizedBox(width: 16),
                      Text('${state.totalRegistros} registros encontrados', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DepositosTable(),
                ],
              ),
            ),
          ),
        ),
        if (state.cargando)
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}

class _DatePickerField extends StatefulWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;
  const _DatePickerField({required this.label, required this.date, required this.onChanged});

  @override
  State<_DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<_DatePickerField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _getDateText(widget.date));
  }

  @override
  void didUpdateWidget(covariant _DatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _controller.text = _getDateText(widget.date);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getDateText(DateTime? date) {
    if (date == null) return '';
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  void _clearDate() {
    _controller.clear();
    widget.onChanged(null);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.date != null)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.redAccent),
                tooltip: 'Borrar fecha',
                onPressed: _clearDate,
              ),
            IconButton(
              icon: const Icon(Icons.calendar_month, color: Color(0xFF6C63FF)),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: widget.date ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  _controller.text = _getDateText(picked);
                  widget.onChanged(picked);
                }
              },
            ),
          ],
        ),
      ),
      onTap: () async {
        // Si ya hay una fecha, mostrar el date picker
        if (widget.date != null) {
          final picked = await showDatePicker(
            context: context,
            initialDate: widget.date,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            _controller.text = _getDateText(picked);
            widget.onChanged(picked);
          }
        } else {
          // Si no hay fecha, mostrar el date picker con fecha actual
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            _controller.text = _getDateText(picked);
            widget.onChanged(picked);
          }
        }
      },
    );
  }
}
class _DepositosTable extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(depositosChequesProvider);
    final columns = const [
      'ID', 'Cliente', 'Banco', 'Empresa', 'Importe', 'Moneda', 'Fecha Ingreso', 'Num. Transaccion', 'Estado', 'Acciones'
    ];
    final page = state.page;
    final rowsPerPage = state.rowsPerPage;
    final depositos = state.depositos;
    final total = state.totalRegistros;
    final start = total == 0 ? 0 : (page * rowsPerPage) + 1;
    final end = ((page + 1) * rowsPerPage).clamp(0, total);
    final paged = depositos.skip(page * rowsPerPage).take(rowsPerPage).toList();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                for (final col in columns)
                  DataColumn(
                    label: Text(col, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
              rows: paged.isEmpty
                  ? []
                  : paged.map((d) => DataRow(cells: [
                        DataCell(Text(d.idDeposito.toString())),
                        DataCell(Text(d.codCliente)),
                        DataCell(Text(d.nombreBanco)),
                        DataCell(Text(d.nombreEmpresa)),
                        DataCell(Text(d.importe.toStringAsFixed(2))),
                        DataCell(Text(d.moneda)),
                        DataCell(Text(d.fechaI != null ? "${d.fechaI!.day.toString().padLeft(2, '0')}/${d.fechaI!.month.toString().padLeft(2, '0')}/${d.fechaI!.year}" : '')),
                        DataCell(Text(d.nroTransaccion)),
                        DataCell(Text(d.esPendiente)),
                        DataCell(Row(
                          children: [
                            IconButton(icon: const Icon(Icons.picture_as_pdf, size: 20), onPressed: () {}),
                            IconButton(icon: const Icon(Icons.image, size: 20), onPressed: () {}),
                            IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () {}),
                          ],
                        )),
                      ])).toList(),
            ),
          ),
          if (paged.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: const [
                  Icon(Icons.search_off, size: 48, color: Colors.black26),
                  SizedBox(height: 8),
                  Text('No se encontraron depósitos', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          // Paginación
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              children: [
                Text('Mostrando $start a $end de $total depósitos'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.first_page),
                  onPressed: state.page > 0 ? () => ref.read(depositosChequesProvider.notifier).setPage(0) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: state.page > 0 ? () => ref.read(depositosChequesProvider.notifier).setPage(state.page - 1) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: end < total ? () => ref.read(depositosChequesProvider.notifier).setPage(state.page + 1) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.last_page),
                  onPressed: end < total ? () => ref.read(depositosChequesProvider.notifier).setPage((total / state.rowsPerPage).ceil() - 1) : null,
                ),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: state.rowsPerPage,
                  items: const [10, 20, 50]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                      .toList(),
                  onChanged: (v) => ref.read(depositosChequesProvider.notifier).setRowsPerPage(v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}