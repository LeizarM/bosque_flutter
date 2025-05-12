import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/depositos_cheques_provider.dart';
import '../../../domain/entities/empresa_entity.dart';
import '../../../domain/entities/banco_cuenta_entity.dart';
import '../../../domain/entities/socio_negocio_entity.dart';

class DepositoChequeViewScreen extends ConsumerWidget {
  const DepositoChequeViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(depositosChequesProvider);
    final notifier = ref.read(depositosChequesProvider.notifier);

    return SingleChildScrollView(
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
                child: DropdownButtonFormField<EmpresaEntity?>(
                  value: state.empresas.contains(state.empresaSeleccionada) ? state.empresaSeleccionada : null,
                  decoration: const InputDecoration(labelText: 'Empresa'),
                  items: [
                    const DropdownMenuItem<EmpresaEntity?>(value: null, child: Text('Todos')),
                    ...state.empresas.map((e) => DropdownMenuItem<EmpresaEntity?>(value: e, child: Text(e.nombre)))
                  ],
                  onChanged: (v) => notifier.seleccionarEmpresa(v),
                ),
              ),
              const SizedBox(width: 16),
              // Banco
              Expanded(
                child: DropdownButtonFormField<BancoXCuentaEntity?>(
                  value: state.bancos.contains(state.bancoSeleccionado) ? state.bancoSeleccionado : null,
                  decoration: const InputDecoration(labelText: 'Banco'),
                  items: [
                    const DropdownMenuItem<BancoXCuentaEntity?>(value: null, child: Text('Banco')),
                    ...state.bancos.map((b) => DropdownMenuItem<BancoXCuentaEntity?>(value: b, child: Text(b.nombreBanco)))
                  ],
                  onChanged: (v) => notifier.seleccionarBanco(v),
                ),
              ),
              const SizedBox(width: 16),
              // Desde
              Expanded(
                child: _DatePickerField(
                  label: 'Desde',
                  date: null, // TODO: Add date state and logic
                  onChanged: (d) {},
                ),
              ),
              const SizedBox(width: 16),
              // Hasta
              Expanded(
                child: _DatePickerField(
                  label: 'Hasta',
                  date: null, // TODO: Add date state and logic
                  onChanged: (d) {},
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
                child: DropdownButtonFormField<SocioNegocioEntity?>(
                  value: state.clientes.contains(state.clienteSeleccionado) ? state.clienteSeleccionado : null,
                  decoration: const InputDecoration(labelText: 'Cliente'),
                  items: [
                    const DropdownMenuItem<SocioNegocioEntity?>(value: null, child: Text('Todos')),
                    ...state.clientes.map((c) => DropdownMenuItem<SocioNegocioEntity?>(value: c, child: Text(c.nombreCompleto)))
                  ],
                  onChanged: (v) => notifier.seleccionarCliente(v),
                ),
              ),
              const SizedBox(width: 16),
              // Estado
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: null, // TODO: Add estado state and logic
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
                    DropdownMenuItem(value: 'Procesado', child: Text('Procesado')),
                    DropdownMenuItem(value: 'Anulado', child: Text('Anulado')),
                  ],
                  onChanged: (v) {},
                ),
              ),
              const SizedBox(width: 16),
              // Botón Buscar
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                ),
                onPressed: () {}, // TODO: Connect to search logic
                icon: const Icon(Icons.search, color: Colors.white),
                label: const Text('Buscar/Actualizar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Resultados
          const Text('Resultados', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 12),
          _DepositosTable(),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;
  const _DatePickerField({required this.label, required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: date != null ? "{date!.day.toString().padLeft(2, '0')}/{date!.month.toString().padLeft(2, '0')}/{date!.year}" : ''),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month, color: Color(0xFF6C63FF)),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            onChanged(picked);
          },
        ),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        onChanged(picked);
      },
    );
  }
}

class _DepositosTable extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Connect to depositos state and pagination logic
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          // Tabla
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: 0, // TODO: Connect to provider sort column index
              sortAscending: true, // TODO: Connect to provider sort ascending
              columns: [
                for (int i = 0; i < 10; i++) // TODO: Replace with actual column count
                  DataColumn(
                    label: Row(
                      children: [
                        Text('Column ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (i < 9)
                          const Icon(Icons.unfold_more, size: 16, color: Colors.black38),
                      ],
                    ),
                    onSort: (col, asc) => {}, // TODO: Connect to provider sort function
                  ),
              ],
              rows: [], // TODO: Connect to provider depositos data
            ),
          ),
          // Estado vacío
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
                Text('Mostrando 1 a 10 de 100 depósitos'), // TODO: Connect to provider pagination info
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.first_page),
                  onPressed: () {}, // TODO: Connect to provider first page function
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {}, // TODO: Connect to provider previous page function
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {}, // TODO: Connect to provider next page function
                ),
                IconButton(
                  icon: const Icon(Icons.last_page),
                  onPressed: () {}, // TODO: Connect to provider last page function
                ),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: 10, // TODO: Connect to provider rows per page
                  items: const [10, 20, 50]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                      .toList(),
                  onChanged: (v) {}, // TODO: Connect to provider set rows per page function
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}