import 'package:bosque_flutter/core/state/Consumo_tigo_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class FacturasTigoCalculoScreen extends ConsumerWidget {
  final String periodoCobrado;
  const FacturasTigoCalculoScreen({Key? key, required this.periodoCobrado}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('Entrando a FacturasTigoCalculoScreen con periodoCobrado: $periodoCobrado');
    final tigoAsync = ref.watch(tigoTotalXCuenta(periodoCobrado));
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
                        Icon(Icons.account_balance, color: Colors.green[700], size: 32),
                        const SizedBox(width: 10),
                        Text(
                          'Cálculo Total por Cuenta',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    tigoAsync.when(
                      loading: () => const SizedBox(),
                      error: (err, _) => const SizedBox(),
                      data: (lista) {
                        if (lista.isEmpty) return const SizedBox();
                        final periodo = lista.first.periodoCobrado;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 22),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_month, color: Colors.green),
                              const SizedBox(width: 10),
                              Text(
                                'Período cobrado: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[900],
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                periodo,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: tigoAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(
                          child: Text(
                            'Error: $err',
                            style: const TextStyle(fontSize: 18, color: Colors.red),
                          ),
                        ),
                        data: (lista) {
                          if (lista.isEmpty) {
                            return const Center(
                              child: Text(
                                'No hay datos.',
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
                                  headingRowColor: MaterialStateProperty.all(Colors.green[100]),
                                  dataRowColor: MaterialStateProperty.all(Colors.white),
                                  columnSpacing: 28,
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        'Nombre Completo',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Carnet de Identidad',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    /* DataColumn(
                                      label: Text(
                                        'Período Cobrado',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),*/
                                    DataColumn(
                                      label: Text(
                                        'Total Cobrado por Cuenta',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Monto Cubierto por Empresa',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Monto por Empleado',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                  rows: lista.map((e) => DataRow(
                                    cells: [
                                      DataCell(Text(e.nombreCompleto)),
                                      DataCell(Text(e.ciNumero ?? '')),
                                      // DataCell(Text(e.periodoCobrado)),
                                      DataCell(Text(e.totalCobradoXCuenta.toStringAsFixed(2))),
                                      DataCell(Text(e.montoCubiertoXEmpresa.toStringAsFixed(2))),
                                      DataCell(Text(e.montoEmpleado.toStringAsFixed(2))),
                                    ],
                                  )).toList(),
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
                colors: [Colors.green[100]!, Colors.green[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.13),
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
                      backgroundColor: Colors.green[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Implementa la búsqueda aquí
                    },
                  ),*/
                  const SizedBox(height: 18),
                  /* ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Agregar Socio'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: const Color.fromARGB(255, 111, 167, 223),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => Dialog(
                          child: FormularioSocios(
                            title: 'Agregar Socio',
                            codEmpleado: null,
                            isEditing: false,
                            socios: null,
                            onSave: (nuevoSocio) async {
                              try{
                                await ref.read(registrarSocioTigo(nuevoSocio).future);
                                ref.refresh(obtenerSociosTigo);
                              }catch(e){
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error al guardar el socio: $e')),
                                );
                              }
                            },
                            onCancel: () => Navigator.of(ctx).pop(),
                          ),
                        ),
                      );
                    },
                  ),*/
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Resumen Detallado'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: const Color.fromARGB(255, 236, 161, 86),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ResumenDetalladoScreen(periodoCobrado: periodoCobrado),
                        ),
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