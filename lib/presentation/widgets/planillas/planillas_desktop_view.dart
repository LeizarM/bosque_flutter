import 'package:bosque_flutter/core/state/planilla_provider.dart';
import 'package:bosque_flutter/domain/entities/planilla_entity.dart';
import 'package:bosque_flutter/presentation/widgets/planillas/planillas_detalle_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/planillas/planillas_filter_bar.dart';
import 'package:bosque_flutter/presentation/widgets/planillas/planillas_pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bosque_flutter/presentation/widgets/planillas/planillas_constants.dart';
import 'package:bosque_flutter/core/utils/descargar_reportes_jasper.dart';

class PlanillasDesktopView extends StatelessWidget {
  final PlanillaState st;
  final PlanillaNotifier ntf;

  const PlanillasDesktopView({super.key, required this.st, required this.ntf});

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
              'No se encontraron planillas\npara este periodo',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.withValues(alpha: 0.8)),
            ),
          ],
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TableHeader(cs: cs),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: st.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final item = st.items[i];
                return Consumer(
                  builder: (context, ref, child) {
                    return _TableRow(
                      item: item,
                      cs: cs,
                      onViewDetalle: () {
                        showDialog(
                          context: context,
                          builder: (_) => PlanillasDetalleDialog(planilla: item),
                        );
                      },
                      onReporteCompacto: () async {
                        await mostrarReportePdf(
                          context: context,
                          downloadFunction: () async => await ref.read(pdfPlanillaCompactaProvider(item.codPlanilla).future),
                          filename: 'PlanillaCompacta_${item.codPlanilla}.pdf',
                        );
                      },
                      onReporteExtendido: () async {
                        await mostrarReportePdf(
                          context: context,
                          downloadFunction: () async => await ref.read(pdfPlanillaExtendidaProvider(item.codPlanilla).future),
                          filename: 'PlanillaExtendida_${item.codPlanilla}.pdf',
                        );
                      },
                    );
                  }
                );
              },
            ),
          ),
          PlanillasPaginationBar(st: st, ntf: ntf),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final ColorScheme cs;
  const _TableHeader({required this.cs});

  @override
  Widget build(BuildContext ctx) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          cs.primaryContainer.withValues(alpha: 0.8),
          cs.primaryContainer.withValues(alpha: 0.4),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: cs.shadow.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    child: Row(
      children: [
        _h('#', flex: 1, center: true),
        _h('Empresa', flex: 3),
        _h('Caja de Salud', flex: 3),
        _h('Periodo', flex: 2, center: true),
        _h('Total Liquido', flex: 2, right: true),
        _h('Estado', flex: 2, center: true),
        _h('Ejecución', flex: 2, center: true),
        _h('Acciones', flex: 2, center: true),
      ],
    ),
  );

  Widget _h(String t, {bool right = false, bool center = false, int flex = 0}) {
    return Expanded(
      flex: flex,
      child: Text(
        t.toUpperCase(),
        textAlign:
            right
                ? TextAlign.right
                : center
                ? TextAlign.center
                : TextAlign.left,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final PlanillaEntity item;
  final ColorScheme cs;
  final VoidCallback onViewDetalle;
  final VoidCallback onReporteCompacto;
  final VoidCallback onReporteExtendido;

  const _TableRow({
    required this.item,
    required this.cs,
    required this.onViewDetalle,
    required this.onReporteCompacto,
    required this.onReporteExtendido,
  });

  @override
  Widget build(BuildContext ctx) {
    final fmtMonto = NumberFormat.currency(symbol: 'Bs ', decimalDigits: 2);
    final fmtDate = DateFormat('dd/MM/yyyy');

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '${item.fila}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              item.empresa,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              item.caja,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.fechaPeriodo != null
                  ? '${monthsMap[item.fechaPeriodo!.month.toString()]} ${item.fechaPeriodo!.year}'
                  : '-',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Builder(
                builder: (context) {
                  final parts = fmtMonto.format(item.totalLiquido).split(' ');
                  if (parts.length == 2 &&
                      (parts[0] == 'Bs' || parts[0] == '\$')) {
                    return SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            parts[0],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: cs.primary.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            parts[1],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Text(
                    fmtMonto.format(item.totalLiquido),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Builder(
                builder: (context) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final cfg = eCfgPlanilla(item.estado, isDark);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cfg.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cfg.icon, size: 14, color: cfg.fg),
                        const SizedBox(width: 4),
                        Text(
                          cfg.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: cfg.fg,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.fechaEjecucion != null
                  ? fmtDate.format(item.fechaEjecucion!)
                  : '-',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FilledButton.tonalIcon(
                    onPressed: onViewDetalle,
                    icon: const Icon(Icons.list_alt, size: 16),
                    label: const Text('Detalle', style: TextStyle(fontSize: 11)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  tooltip: 'Reportes PDF',
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'compacta') onReporteCompacto();
                    if (value == 'extendida') onReporteExtendido();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'compacta',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Planilla Compacta', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'extendida',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Planilla Extendida', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
