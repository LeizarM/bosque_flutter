import 'package:bosque_flutter/core/state/Consumo_tigo_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FacturasTigoResumenScreen extends ConsumerWidget {
  final String periodoCobrado;
  const FacturasTigoResumenScreen({Key? key, required this.periodoCobrado}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('Entrando a FacturasTigoResumenScreen con periodoCobrado: $periodoCobrado');
    final tigoResumenPorCuenta = ref.watch(tigoResumenXCuenta(periodoCobrado));
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabla principal en una tarjeta moderna
          Expanded(
            flex: 3,
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet, color: Colors.blue[700], size: 32),
                        const SizedBox(width: 10),
                        Text(
                          'Resumen por Cuenta',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: tigoResumenPorCuenta.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(
                          child: Text(
                            'Error al cargar datos: $err',
                            style: const TextStyle(fontSize: 18, color: Colors.red),
                          ),
                        ),
                        data: (resumen) {
                          if (resumen.isEmpty) {
                            return const Center(
                              child: Text(
                                'No hay facturas subidas.',
                                style: TextStyle(fontSize: 18),
                              ),
                            );
                          }
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(Colors.blue[100]),
                                  dataRowColor: MaterialStateProperty.all(Colors.white),
                                  columnSpacing: 32,
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        'NOMBRE COMPLETO',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'TOTAL Bs',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                  rows: resumen.map((resumenCuenta) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(resumenCuenta.nombreCompleto?.toString() ?? ''),
                                          ),
                                        ),
                                        DataCell(
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(resumenCuenta.totalCobradoXCuenta?.toStringAsFixed(2) ?? ''),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          /*const SizedBox(width: 36),
          // Panel de operaciones con fondo degradado y sombra
          Container(
            width: 340,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [Colors.blue[100]!, Colors.blue[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(4, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: OperacionesTigoWidget(
                accionesExtra: [
                 /* ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Buscar'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Implementa la búsqueda aquí
                    },
                  ),*/
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calculate),
                    label: const Text('Calcular Total por Cuenta'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: Colors.green[100], // color suave
                      foregroundColor: Colors.black,      // letras oscuras
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => FacturasTigoCalculoScreen( periodoCobrado: periodoCobrado),),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),*/
        ],
      ),
    );
  }
}