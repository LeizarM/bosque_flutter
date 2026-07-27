import 'package:bosque_flutter/core/state/planilla_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart'; // Para empresasProvider
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
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
            const SizedBox(width: 8),
            const SizedBox(width: 24),
            _PlanillasFilterDivider(),
            const SizedBox(width: 24),

            // =========================================================
            // VALIDACIÓN DE SEGURIDAD (Cinturón en el Frontend)
            // =========================================================
            Builder(
              builder: (context) {
                final now = DateTime.now();
                final bool isCurrentPeriod =
                    st.mes == now.month.toString() &&
                    st.anio == now.year.toString();
                final bool isBusy = st.cargando || st.generando;
                final bool isButtonDisabled = isBusy || !isCurrentPeriod;

                return Row(
                  children: [
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
                          isButtonDisabled
                              ? null
                              : () {
                                ntf.generarPlanilla(uid);
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
                          isButtonDisabled
                              ? null
                              : () async {
                                final advertencias =
                                    await ntf.preValidarEjecutarPlanilla();
                                if (advertencias == null)
                                  return; // Error bloqueante detectado, abortar y dejar que el listener muestre el error.

                                final hasWarnings = advertencias.isNotEmpty;

                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (c) => AlertDialog(
                                        icon: Icon(
                                          Icons.warning_amber_rounded,
                                          color: cs.error,
                                          size: 40,
                                        ),
                                        title: const Text('EJECUTAR PLANILLAS'),
                                        content: Text.rich(
                                          TextSpan(
                                            children: [
                                              const TextSpan(
                                                text:
                                                    '¿Está seguro de Ejecutar las Planillas de este mes?\n\n'
                                                    'Una vez ejecutadas, no podrán ser modificadas ni eliminadas.',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (hasWarnings)
                                                TextSpan(
                                                  text:
                                                      '\n\nADVERTENCIAS:\n$advertencias',
                                                  style: TextStyle(
                                                    color: cs.error,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(c, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: cs.error,
                                            ),
                                            onPressed:
                                                () => Navigator.pop(c, true),
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
                  ],
                );
              },
            ),

            const SizedBox(width: 8),

            // ── Botón consolidado "Reportes" ──
            _ReportesMenuButton(st: st),
          ],
        ),
      ),
    );
  }
}

/// Botón con MenuAnchor para reportes, extraído para manejar estado del controlador
class _ReportesMenuButton extends ConsumerStatefulWidget {
  final PlanillaState st;

  const _ReportesMenuButton({required this.st});

  @override
  ConsumerState<_ReportesMenuButton> createState() =>
      _ReportesMenuButtonState();
}

class _ReportesMenuButtonState extends ConsumerState<_ReportesMenuButton> {
  @override
  Widget build(BuildContext context) {
    final empresasAsync = ref.watch(empresasProvider);
    final nombreMes = monthsMap[widget.st.mes] ?? 'Mes';
    final habilitado = widget.st.mes.isNotEmpty && widget.st.anio.isNotEmpty;
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<void>(
      //tooltip: 'Reportes y Descargas',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: IgnorePointer(
        child: FilledButton.icon(
          icon: const Icon(Icons.summarize_rounded, size: 18),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reportes'),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
          style: FilledButton.styleFrom(
            backgroundColor: cs.tertiary,
            foregroundColor: cs.onTertiary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onPressed: () {},
        ),
      ),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<void>>[];

        // ── Exportar Bancos ──
        items.add(
          PopupMenuItem<void>(
            enabled: habilitado,
            onTap: () {
              Future.delayed(Duration.zero, () {
                showDialog(
                  context: context,
                  builder:
                      (_) => PlanillasExportBancoDialog(
                        mes: int.parse(widget.st.mes),
                        anio: int.parse(widget.st.anio),
                        nombreMes: nombreMes,
                      ),
                );
              });
            },
            child: Row(
              children: [
                Icon(Icons.account_balance, size: 20, color: cs.tertiary),
                const SizedBox(width: 12),
                const Text('Exportar Bancos'),
              ],
            ),
          ),
        );

        // ── Estimado Pago ──
        items.add(
          PopupMenuItem<void>(
            onTap: () {
              Future.delayed(Duration.zero, () async {
                await mostrarReportePdf(
                  context: context,
                  downloadFunction: () async {
                    return await ref.read(pdfEstimadoPagoBancoProvider.future);
                  },
                  filename: 'EstimadoPagoPlanilla.pdf',
                );
              });
            },
            child: Row(
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  size: 20,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 12),
                const Text('Estimado Pago'),
              ],
            ),
          ),
        );

        items.add(const PopupMenuDivider());

        // ── Título Planilla Tributaria ──
        items.add(
          PopupMenuItem<void>(
            enabled: false,
            height: 32,
            child: Row(
              children: [
                Icon(
                  Icons.table_view_rounded,
                  size: 16,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'PLANILLA TRIBUTARIA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );

        // ── Opciones Planilla Tributaria (por empresa) ──
        empresasAsync.when(
          data: (empresas) {
            for (final empresa in empresas) {
              final label =
                  '${empresa.nombre.toUpperCase()} $nombreMes ${widget.st.anio}';
              items.add(
                PopupMenuItem<void>(
                  enabled: habilitado,
                  onTap: () {
                    Future.delayed(Duration.zero, () async {
                      await descargarArchivo(
                        context: context,
                        downloadFunction: () async {
                          return await ref.read(
                            excelPlanillaTributariaProvider({
                              'mes': int.parse(widget.st.mes),
                              'anio': int.parse(widget.st.anio),
                              'codEmpresa': empresa.codEmpresa,
                            }).future,
                          );
                        },
                        filename:
                            'Planilla_Tributaria_${empresa.sigla}_${widget.st.anio}_${widget.st.mes}.xlsx',
                        mimeType:
                            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                      );
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.download_rounded,
                        size: 18,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            empresa.nombre.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '$nombreMes ${widget.st.anio}',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color ??
                                  Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
          },
          loading: () {
            items.add(
              const PopupMenuItem<void>(
                enabled: false,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            );
          },
          error: (_, __) {
            items.add(
              const PopupMenuItem<void>(
                enabled: false,
                child: Text('Error al cargar empresas'),
              ),
            );
          },
        );

        return items;
      },
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
