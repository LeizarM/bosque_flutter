import 'package:bosque_flutter/core/state/planilla_provider.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_filter_bar.dart'; // Para BosqueFiltroDropdown
import 'package:bosque_flutter/presentation/widgets/planillas/planillas_export_banco_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/utils/descargar_reportes_jasper.dart';

const Map<String, String> monthsMap = {
  '': 'TODOS',
  '1': 'ENERO',
  '2': 'FEBRERO',
  '3': 'MARZO',
  '4': 'ABRIL',
  '5': 'MAYO',
  '6': 'JUNIO',
  '7': 'JULIO',
  '8': 'AGOSTO',
  '9': 'SEPTIEMBRE',
  '10': 'OCTUBRE',
  '11': 'NOVIEMBRE',
  '12': 'DICIEMBRE',
};

class PlanillasFilterBar extends StatelessWidget {
  final PlanillaState st;
  final PlanillaNotifier ntf;
  final List<String> anios;
  final int uid;

  const PlanillasFilterBar({
    super.key,
    required this.st,
    required this.ntf,
    required this.anios,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // ── Mes ──
            _PlanillasFilterChip(
              label: 'MES',
              active: true,
              child: BosqueFiltroDropdown<String>(
                value: monthsMap.containsKey(st.mes) ? st.mes : '',
                items:
                    monthsMap.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) ntf.setFechaFiltro(mes: val);
                },
              ),
            ),
            const SizedBox(width: 8),

            // ── Año ──
            _PlanillasFilterChip(
              label: 'AÑO',
              active: true,
              child: BosqueFiltroDropdown<String>(
                value: st.anio,
                items:
                    anios
                        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                        .toList(),
                onChanged: (val) {
                  if (val != null) ntf.setFechaFiltro(anio: val);
                },
              ),
            ),

            // Spacer and Action Button
            const SizedBox(width: 24),
            _PlanillasFilterDivider(),
            const SizedBox(width: 24),

            FilledButton.icon(
              icon: const Icon(Icons.calculate, size: 18),
              label: const Text('Generar Planillas'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onPressed:
                  st.cargando || st.generando
                      ? null
                      : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (c) => AlertDialog(
                                title: const Text('Confirmar Generación'),
                                content: const Text(
                                  '¿Estás seguro que deseas generar la planilla para el periodo actual? '
                                  'Esto reemplazará cualquier planilla no ejecutada del mes.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Generar'),
                                  ),
                                ],
                              ),
                        );
                        if (confirm == true) {
                          ntf.generarPlanilla(uid);
                        }
                      },
            ),

            const SizedBox(width: 8),

            FilledButton.icon(
              icon: const Icon(Icons.lock_person, size: 18),
              label: const Text('Ejecutar Planillas'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onPressed:
                  st.cargando || st.generando
                      ? null
                      : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (c) => AlertDialog(
                                icon: Icon(
                                  Icons.warning_amber_rounded,
                                  color: cs.error,
                                  size: 40,
                                ),
                                title: const Text('EJECUTAR PLANILLAS CRÍTICO'),
                                content: const Text(
                                  '¿Está seguro de Ejecutar las Planillas de este mes?\n\n'
                                  'Una vez ejecutadas, no podrán ser modificadas ni eliminadas, y todos los bonos y cuotas serán liquidados.',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: cs.error,
                                    ),
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text(
                                      'Sí, Ejecutar Definitivamente',
                                    ),
                                  ),
                                ],
                              ),
                        );
                        if (confirm == true) {
                          ntf.ejecutarPlanilla();
                        }
                      },
            ),

            const SizedBox(width: 8),

            FilledButton.icon(
              icon: const Icon(Icons.download_for_offline, size: 18),
              label: const Text('Exportar Bancos'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.tertiary,
                foregroundColor: cs.onTertiary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onPressed:
                  st.mes.isEmpty || st.anio.isEmpty
                      ? null
                      : () {
                        showDialog(
                          context: context,
                          builder:
                              (_) => PlanillasExportBancoDialog(
                                mes: int.parse(st.mes),
                                anio: int.parse(st.anio),
                                nombreMes: monthsMap[st.mes] ?? 'Mes',
                              ),
                        );
                      },
            ),

            const SizedBox(width: 8),

            Consumer(
              builder: (context, ref, child) {
                return FilledButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Estimado Pago'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onPressed: () async {
                    await mostrarReportePdf(
                      context: context,
                      downloadFunction: () async {
                        final pdfBytes = await ref.read(pdfEstimadoPagoBancoProvider.future);
                        return pdfBytes;
                      },
                      filename: 'EstimadoPagoPlanilla.pdf',
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Divisor vertical en la barra de filtros
class _PlanillasFilterDivider extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Container(
    height: 24,
    width: 1,
    color: Theme.of(ctx).colorScheme.outline.withValues(alpha: 0.3),
  );
}

/// Wrapper visual para cada filtro con label flotante
class _PlanillasFilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Widget child;
  const _PlanillasFilterChip({
    required this.label,
    required this.active,
    required this.child,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (active)
          Positioned(
            top: -5,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
