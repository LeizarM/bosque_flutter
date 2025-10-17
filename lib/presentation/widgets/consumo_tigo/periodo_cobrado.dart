import 'package:bosque_flutter/core/state/Consumo_tigo_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FacturasEjecutadasView extends ConsumerStatefulWidget {
  const FacturasEjecutadasView({super.key});

  @override
  ConsumerState<FacturasEjecutadasView> createState() => _FacturasEjecutadasViewState();
}

class _FacturasEjecutadasViewState extends ConsumerState<FacturasEjecutadasView> {
  String? _periodoSeleccionado;
  String? _estadoSeleccionado;

  @override
  Widget build(BuildContext context) {
    final facturasAsync = ref.watch(facturasTigoProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Facturas Ejecutadas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        facturasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (facturas) {
            // Obtén los valores únicos para los filtros
            final periodos = facturas.map((f) => f.periodoCobrado).toSet().toList();
            final estados = facturas.map((f) => f.estado ?? 'Pendiente').toSet().toList();

            // Filtra las facturas según selección
            final facturasFiltradas = facturas.where((f) {
              final periodoOk = _periodoSeleccionado == null || f.periodoCobrado == _periodoSeleccionado;
              final estadoOk = _estadoSeleccionado == null || (f.estado ?? 'Pendiente') == _estadoSeleccionado;
              return periodoOk && estadoOk;
            }).toList();

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _periodoSeleccionado,
                        decoration: const InputDecoration(labelText: 'Período Cobrado'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Todos')),
                          ...periodos.map((p) => DropdownMenuItem(value: p, child: Text(p ?? ''))),
                        ],
                        onChanged: (value) => setState(() => _periodoSeleccionado = value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _estadoSeleccionado,
                        decoration: const InputDecoration(labelText: 'Estado'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Todos')),
                          ...estados.map((e) => DropdownMenuItem(value: e, child: Text(e))),
                        ],
                        onChanged: (value) => setState(() => _estadoSeleccionado = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('N° Contrato')),
                          //DataColumn(label: Text('N° Cuenta')),
                          DataColumn(label: Text('Período Cobrado')),
                          DataColumn(label: Text('Estado')),
                          //DataColumn(label: Text('Total Cobrado')),
                        ],
                        rows: facturasFiltradas.map((factura) => DataRow(
                          cells: [
                            DataCell(Text(factura.nroContrato?.toString() ?? '')),
                           // DataCell(Text(factura.nroCuenta?.toString() ?? '')),
                            DataCell(Text(factura.periodoCobrado ?? '')),
                            DataCell(Text(factura.estado ?? '')),
                            //DataCell(Text(factura.totalCobradoXCuenta?.toStringAsFixed(2) ?? '')),
                          ],
                        )).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}