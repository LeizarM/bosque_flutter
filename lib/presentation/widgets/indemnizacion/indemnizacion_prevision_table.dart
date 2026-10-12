import 'package:bosque_flutter/domain/entities/indemnizacion_entity.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IndemnizacionPrevisionTable extends StatelessWidget {
  final List<IndemnizacionEntity> items;
  final ColorScheme cs;

  const IndemnizacionPrevisionTable({required this.items, required this.cs});

  Widget _buildRowData(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmtMoneda = NumberFormat.currency(
      locale: 'es_BO',
      symbol: '',
      decimalDigits: 2,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (ResponsiveUtilsBosque.isMobile(context)) {
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final e = items[i];
              return Card(
                elevation: 0,
                color: cs.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: cs.primaryContainer,
                            child: Text(
                              '${e.nro ?? '-'}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (e.apellidos ??
                                      '${e.empleadoNombres ?? ''} ${e.empleadoApellidos ?? ''}')
                                  .trim(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildRowData('F. Ingreso', e.fechaIngreso ?? '-'),
                      _buildRowData('F. Salida', e.fechaSalida ?? '-'),
                      _buildRowData('Días', '${e.diasactual ?? 0}'),
                      _buildRowData('Antigüedad', e.antiguedad ?? '-'),
                      _buildRowData(
                        'Promedio (3 Meses)',
                        fmtMoneda.format(e.promedioMeses ?? 0),
                      ),
                      _buildRowData(
                        'Indem. Anterior',
                        fmtMoneda.format(e.indemnizacionMesAnterior ?? 0),
                      ),
                      _buildRowData(
                        'Indem. Actual',
                        fmtMoneda.format(e.indemnizacionActual ?? 0),
                      ),
                      Divider(color: cs.outlineVariant.withOpacity(0.2)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Indem. Final',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            fmtMoneda.format(e.indemnizacionFinal ?? 0),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  cs.primaryContainer.withOpacity(0.4),
                ),
                dataRowMinHeight: 40,
                dataRowMaxHeight: 48,
                columnSpacing: 16,
                columns: const [
                  DataColumn(
                    label: Text(
                      'N°',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Empleado',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'F. Ingreso',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'F. Salida',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Días',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'Antigüedad',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Promedio (3 Meses)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'Indem. Anterior',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'Indem. Actual',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'Indem. Final',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'Area',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows:
                    items.map((e) {
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      final isSelected = items.indexOf(e).isOdd;
                      return DataRow(
                        color: MaterialStateProperty.all(
                          isSelected
                              ? cs.surfaceVariant.withOpacity(
                                isDark ? 0.1 : 0.3,
                              )
                              : Colors.transparent,
                        ),
                        cells: [
                          DataCell(
                            Text(
                              '${e.nro ?? e.codIndemnizacion ?? '-'}',
                              style: TextStyle(
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              (e.apellidos ??
                                      '${e.empleadoNombres ?? ''} ${e.empleadoApellidos ?? ''}')
                                  .trim(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(Text(e.fechaIngreso ?? '-')),
                          DataCell(Text(e.fechaSalida ?? '-')),
                          DataCell(Text('${e.diasactual ?? 0}')),
                          DataCell(Text(e.antiguedad ?? '-')),
                          DataCell(
                            Text(fmtMoneda.format(e.promedioMeses ?? 0)),
                          ),
                          DataCell(
                            Text(
                              fmtMoneda.format(e.indemnizacionMesAnterior ?? 0),
                            ),
                          ),
                          DataCell(
                            Text(fmtMoneda.format(e.indemnizacionActual ?? 0)),
                          ),
                          DataCell(
                            Text(
                              fmtMoneda.format(e.indemnizacionFinal ?? 0),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              e.area ?? '-',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withOpacity(0.7),
                              ),
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
    );
  }
}



