import 'package:bosque_flutter/domain/entities/indemnizacion_entity.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IndemnizacionHistorialTable extends StatelessWidget {
  final List<IndemnizacionEntity> items;
  final ColorScheme cs;
  final Function(IndemnizacionEntity) onEdit;
  final Function(IndemnizacionEntity) onDelete;

  const IndemnizacionHistorialTable({
    required this.items,
    required this.cs,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildRowData(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
                              e.empleadoNombres ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          PermissionWidget(
                            buttonName: 'btnEditarIndemnizacion',
                            child: IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              color: cs.primary,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => onEdit(e),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildRowData(
                        'Fecha',
                        e.fechaIndemnizacion != null
                            ? '${e.fechaIndemnizacion!.day.toString().padLeft(2, '0')}/${e.fechaIndemnizacion!.month.toString().padLeft(2, '0')}/${e.fechaIndemnizacion!.year}'
                            : '-',
                      ),
                      _buildRowData('Descripción', e.descripcion ?? '-'),
                      Divider(color: cs.outlineVariant.withOpacity(0.2)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Monto',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            fmtMoneda.format(e.montoIndemnizacion ?? 0),
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
                      'Nro',
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
                      'Fecha',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Monto',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'Descripción',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Acciones',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows:
                    items.map((e) {
                      return DataRow(
                        cells: [
                          DataCell(Text('${e.nro ?? ''}')),
                          DataCell(
                            SizedBox(
                              width: constraints.maxWidth * 0.35,
                              child: Text(
                                e.empleadoNombres ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              e.fechaIndemnizacion != null
                                  ? '${e.fechaIndemnizacion!.day.toString().padLeft(2, '0')}/${e.fechaIndemnizacion!.month.toString().padLeft(2, '0')}/${e.fechaIndemnizacion!.year}'
                                  : '',
                            ),
                          ),
                          DataCell(
                            Text(
                              fmtMoneda.format(e.montoIndemnizacion ?? 0),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: constraints.maxWidth * 0.20,
                              child: Text(e.descripcion ?? ''),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PermissionWidget(
                                  buttonName: 'btnEditarIndemnizacion',
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    color: cs.primary,
                                    onPressed: () => onEdit(e),
                                  ),
                                ),
                              ],
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


