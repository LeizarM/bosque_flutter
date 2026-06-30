import 'package:bosque_flutter/core/state/planilla_provider.dart';
import 'package:bosque_flutter/presentation/widgets/planillas/planillas_detalle_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/planillas/planillas_filter_bar.dart';
import 'package:bosque_flutter/presentation/widgets/planillas/planillas_pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bosque_flutter/presentation/widgets/planillas/planillas_constants.dart';
import 'package:bosque_flutter/core/utils/descargar_reportes_jasper.dart';

class PlanillasMobileView extends StatelessWidget {
  final PlanillaState st;
  final PlanillaNotifier ntf;

  const PlanillasMobileView({super.key, required this.st, required this.ntf});

  @override
  Widget build(BuildContext context) {
    if (st.cargando && st.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (st.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 60,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron planillas',
              style: TextStyle(color: Colors.grey.withValues(alpha: 0.8)),
            ),
          ],
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final fmtMonto = NumberFormat.currency(symbol: 'Bs ', decimalDigits: 2);
    final fmtDate = DateFormat('dd/MM/yyyy');

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: st.items.length,
            itemBuilder: (context, i) {
              final item = st.items[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.empresa,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final isDark =
                                  Theme.of(context).brightness ==
                                  Brightness.dark;
                              final cfg = eCfgPlanilla(item.estado, isDark);
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: cfg.bg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(cfg.icon, size: 14, color: cfg.fg),
                                    const SizedBox(width: 4),
                                    Text(
                                      cfg.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: cfg.fg,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Caja: ${item.caja}'),
                      if (item.fechaPeriodo != null)
                        Text(
                          'Periodo: ${monthsMap[item.fechaPeriodo!.month.toString()]} ${item.fechaPeriodo!.year}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      Text(
                        'Total Líquido: ${fmtMonto.format(item.totalLiquido)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                      if (item.fechaEjecucion != null)
                        Text(
                          'Fecha Ejecución: ${fmtDate.format(item.fechaEjecucion!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Consumer(
                        builder: (context, ref, child) {
                          return Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (_) => PlanillasDetalleDialog(
                                            planilla: item,
                                          ),
                                    );
                                  },
                                  icon: const Icon(Icons.list_alt, size: 18),
                                  label: const Text('Ver Detalle'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                tooltip: 'Reportes PDF',
                                onSelected: (value) async {
                                  if (value == 'compacta') {
                                    await mostrarReportePdf(
                                      context: context,
                                      downloadFunction:
                                          () async => await ref.read(
                                            pdfPlanillaCompactaProvider(
                                              item.codPlanilla,
                                            ).future,
                                          ),
                                      filename:
                                          'PlanillaCompacta_${item.codPlanilla}.pdf',
                                    );
                                  } else if (value == 'extendida') {
                                    await mostrarReportePdf(
                                      context: context,
                                      downloadFunction:
                                          () async => await ref.read(
                                            pdfPlanillaExtendidaProvider(
                                              item.codPlanilla,
                                            ).future,
                                          ),
                                      filename:
                                          'PlanillaExtendida_${item.codPlanilla}.pdf',
                                    );
                                  }
                                },
                                itemBuilder:
                                    (context) => [
                                      const PopupMenuItem(
                                        value: 'compacta',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.picture_as_pdf,
                                              color: Colors.red,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Planilla Compacta'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'extendida',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.picture_as_pdf,
                                              color: Colors.red,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Planilla Extendida'),
                                          ],
                                        ),
                                      ),
                                    ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        PlanillasPaginationBar(st: st, ntf: ntf),
      ],
    );
  }
}
