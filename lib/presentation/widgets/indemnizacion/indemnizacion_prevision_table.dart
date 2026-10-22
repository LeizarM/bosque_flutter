import 'package:bosque_flutter/domain/entities/indemnizacion_entity.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/utils/descargar_reportes_jasper.dart';
import 'package:bosque_flutter/data/repositories/indemnizacion_impl.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class IndemnizacionPrevisionTable extends ConsumerWidget {
  final List<IndemnizacionEntity> items;
  final ColorScheme cs;
  final String? fechaCorte;

  const IndemnizacionPrevisionTable({
    super.key,
    required this.items,
    required this.cs,
    this.fechaCorte,
  });

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

  Future<void> _descargarFiniquito(
    BuildContext context,
    IndemnizacionEntity e,
  ) async {
    final codEmp = e.codEmpleado;
    if (codEmp == null || codEmp == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código de empleado no disponible')),
      );
      return;
    }
    await descargarArchivo(
      context: context,
      downloadFunction:
          () => IndemnizacionImpl().descargarFiniquitoExcel(
            codEmpleado: codEmp,
            fechaCorte: fechaCorte,
          ),
      filename:
          'Finiquito_${(e.apellidos ?? 'Empleado').replaceAll(' ', '_')}.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmtMoneda = NumberFormat.currency(
      locale: 'es_BO',
      symbol: '',
      decimalDigits: 2,
    );

    final tienePermisoAlerta = tienePermisoDeBoton(ref, 'btnAlertaVacaciones');
    final tienePermisoFiniquito = tienePermisoDeBoton(ref, 'btnExcelFiniquito');

    return LayoutBuilder(
      builder: (context, constraints) {
        if (ResponsiveUtilsBosque.isMobile(context)) {
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final e = items[i];
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final tieneDeudaVacacion = (e.diasVacacion ?? 0) < 0;
              final mostrarAlerta =
                  tieneDeudaVacacion &&
                  tienePermisoAlerta &&
                  (e.descripcion != null && e.descripcion!.isNotEmpty);

              return Card(
                elevation: 0,
                color:
                    mostrarAlerta
                        ? (isDark
                            ? Colors.amber.shade900.withOpacity(0.15)
                            : Colors.amber.shade50.withOpacity(0.6))
                        : cs.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color:
                        mostrarAlerta
                            ? (isDark
                                ? Colors.amber.shade700
                                : Colors.amber.shade400)
                            : cs.outlineVariant.withOpacity(0.4),
                    width: mostrarAlerta ? 1.5 : 1.0,
                  ),
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
                            backgroundColor:
                                mostrarAlerta
                                    ? (isDark
                                        ? Colors.amber.shade800
                                        : Colors.amber.shade200)
                                    : cs.primaryContainer,
                            child: Text(
                              '${e.nro ?? '-'}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color:
                                    mostrarAlerta
                                        ? (isDark
                                            ? Colors.amber.shade100
                                            : Colors.amber.shade900)
                                        : cs.onPrimaryContainer,
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
                          if (tieneDeudaVacacion)
                            PermissionWidget(
                              buttonName: 'btnAlertaVacaciones',
                              child: Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? Colors.red.shade900.withOpacity(0.6)
                                          : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color:
                                        isDark
                                            ? Colors.red.shade400
                                            : Colors.red.shade300,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  '${e.diasVacacion} d.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark
                                            ? Colors.red.shade200
                                            : Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (mostrarAlerta)
                        PermissionWidget(
                          buttonName: 'btnAlertaVacaciones',
                          child: Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? Colors.amber.shade900.withOpacity(0.25)
                                      : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    isDark
                                        ? Colors.amber.shade700
                                        : Colors.amber.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e.descripcion!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isDark
                                              ? Colors.amber.shade200
                                              : Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                      // _buildRowData(
                      //   'Aguinaldo',
                      //   fmtMoneda.format(e.aguinaldo ?? 0),
                      // ),
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
                      if (tienePermisoFiniquito) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green.shade700,
                              side: BorderSide(color: Colors.green.shade400),
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(
                              Icons.description_outlined,
                              size: 16,
                            ),
                            label: const Text(
                              'Finiquito Excel',
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: () => _descargarFiniquito(context, e),
                          ),
                        ),
                      ],
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
                columns: [
                  const DataColumn(
                    label: Text(
                      'N°',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'Empleado',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'F. Ingreso',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'F. Salida',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'Días',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  const DataColumn(
                    label: Text(
                      'Antigüedad',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'Promedio (3 Meses)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  const DataColumn(
                    label: Text(
                      'Indem. Anterior',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  const DataColumn(
                    label: Text(
                      'Indem. Actual',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  // const DataColumn(
                  //   label: Text(
                  //     'Aguinaldo',
                  //     style: TextStyle(fontWeight: FontWeight.bold),
                  //   ),
                  //   numeric: true,
                  // ),
                  const DataColumn(
                    label: Text(
                      'Indem. Final',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  const DataColumn(
                    label: Text(
                      'Area',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (tienePermisoFiniquito)
                    const DataColumn(
                      label: Text(
                        'Finiquito',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
                rows:
                    items.map((e) {
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      final isSelected = items.indexOf(e).isOdd;
                      final tieneDeudaVacacion = (e.diasVacacion ?? 0) < 0;
                      final mostrarAlerta =
                          tieneDeudaVacacion &&
                          tienePermisoAlerta &&
                          (e.descripcion != null && e.descripcion!.isNotEmpty);
                      final nombreCompleto =
                          (e.apellidos ??
                                  '${e.empleadoNombres ?? ''} ${e.empleadoApellidos ?? ''}')
                              .trim();

                      return DataRow(
                        color: MaterialStateProperty.resolveWith<Color?>((
                          states,
                        ) {
                          if (mostrarAlerta) {
                            if (states.contains(MaterialState.hovered)) {
                              return isDark
                                  ? Colors.amber.shade900.withOpacity(0.35)
                                  : Colors.amber.shade100.withOpacity(0.8);
                            }
                            return isDark
                                ? Colors.amber.shade900.withOpacity(0.18)
                                : Colors.amber.shade50.withOpacity(0.7);
                          }
                          if (states.contains(MaterialState.hovered)) {
                            return cs.primary.withOpacity(0.06);
                          }
                          return isSelected
                              ? cs.surfaceVariant.withOpacity(
                                isDark ? 0.1 : 0.3,
                              )
                              : Colors.transparent;
                        }),
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
                            PermissionWidget(
                              buttonName: 'btnAlertaVacaciones',
                              placeholder: Text(
                                nombreCompleto,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child:
                                  mostrarAlerta
                                      ? Tooltip(
                                        message: e.descripcion!,
                                        textStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade900,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                nombreCompleto,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    isDark
                                                        ? Colors.red.shade900
                                                            .withOpacity(0.5)
                                                        : Colors.red.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color:
                                                      isDark
                                                          ? Colors.red.shade400
                                                          : Colors.red.shade300,
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Text(
                                                '${e.diasVacacion} d.',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      isDark
                                                          ? Colors.red.shade200
                                                          : Colors.red.shade800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      : Text(
                                        nombreCompleto,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
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
                          // DataCell(Text(fmtMoneda.format(e.aguinaldo ?? 0))),
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
                          if (tienePermisoFiniquito)
                            DataCell(
                              IconButton(
                                icon: const Icon(
                                  Icons.description_outlined,
                                  color: Colors.green,
                                ),
                                tooltip: 'Descargar Finiquito Excel',
                                onPressed:
                                    () => _descargarFiniquito(context, e),
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
