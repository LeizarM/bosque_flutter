import 'package:bosque_flutter/core/state/planilla_provider.dart';
import 'package:bosque_flutter/domain/entities/planilla_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/planilla_entity.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class PlanillasDetalleDialog extends ConsumerStatefulWidget {
  final PlanillaEntity planilla;

  const PlanillasDetalleDialog({super.key, required this.planilla});

  @override
  ConsumerState<PlanillasDetalleDialog> createState() =>
      _PlanillasDetalleDialogState();
}

class _PlanillasDetalleDialogState
    extends ConsumerState<PlanillasDetalleDialog> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planilla = widget.planilla;
    final st = ref.watch(planillaDetalleProvider(planilla.codPlanilla));
    final ntf = ref.read(
      planillaDetalleProvider(planilla.codPlanilla).notifier,
    );
    final cs = Theme.of(context).colorScheme;
    final fmtMonto = NumberFormat.currency(symbol: 'Bs ', decimalDigits: 2);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.group, color: cs.primary, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalle de Planilla - ${planilla.empresa}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        'Caja: ${planilla.caja} | Estado: ${planilla.estado}',
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search and filters
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width:
                      ResponsiveUtilsBosque.isMobile(context)
                          ? double.infinity
                          : 300,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar empleado...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (val) {
                      ntf.buscar(val);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Total Liquido: ${fmtMonto.format(planilla.totalLiquido)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table content
            Expanded(
              child:
                  st.cargando && st.items.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : st.items.isEmpty
                      ? const Center(
                        child: Text('No se encontraron registros de detalle.'),
                      )
                      : Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ListView.separated(
                            itemCount: st.items.length,
                            separatorBuilder:
                                (_, __) => Divider(
                                  height: 1,
                                  color: cs.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                            itemBuilder: (context, index) {
                              final emp = st.items[index];
                              return ExpansionTile(
                                collapsedBackgroundColor:
                                    emp.tieneError
                                        ? cs.errorContainer.withValues(
                                          alpha: 0.3,
                                        )
                                        : null,
                                backgroundColor:
                                    emp.tieneError
                                        ? cs.errorContainer.withValues(
                                          alpha: 0.15,
                                        )
                                        : null,
                                leading: CircleAvatar(
                                  backgroundColor:
                                      emp.tieneError
                                          ? cs.error
                                          : cs.primaryContainer,
                                  child: Text(
                                    '${emp.fila}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          emp.tieneError
                                              ? cs.onError
                                              : cs.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        emp.nombreCompleto,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              emp.tieneError ? cs.error : null,
                                        ),
                                      ),
                                    ),
                                    if (emp.tieneError)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: Tooltip(
                                          message:
                                              emp.mensajeError ??
                                              'Error en el detalle',
                                          child: Icon(
                                            Icons.warning_rounded,
                                            color: cs.error,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            emp.tieneError
                                                ? cs.error.withValues(
                                                  alpha: 0.1,
                                                )
                                                : cs.secondaryContainer
                                                    .withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(8),
                                        border:
                                            emp.tieneError
                                                ? Border.all(
                                                  color: cs.error.withValues(
                                                    alpha: 0.5,
                                                  ),
                                                )
                                                : null,
                                      ),
                                      child: Text(
                                        'Líquido: ${fmtMonto.format(emp.liquido)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              emp.tieneError
                                                  ? cs.error
                                                  : cs.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  'Cargo: ${emp.cargo} | CI: ${emp.ciNumero}${emp.mensajeError != null ? '\nError: ${emp.mensajeError}' : ''}',
                                  style: TextStyle(
                                    color: emp.tieneError ? cs.error : null,
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Flex(
                                      direction:
                                          ResponsiveUtilsBosque.isMobile(
                                                context,
                                              )
                                              ? Axis.vertical
                                              : Axis.horizontal,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (ResponsiveUtilsBosque.isMobile(
                                          context,
                                        ))
                                          _buildInfoCol('INGRESOS', [
                                            (
                                              'Días Pagados',
                                              emp.diasPagadosMes.toString(),
                                            ),
                                            (
                                              'Haber Básico',
                                              fmtMonto.format(emp.haberBasico),
                                            ),
                                            (
                                              'Bono Antigüedad',
                                              fmtMonto.format(
                                                emp.bonoAntiguedad,
                                              ),
                                            ),
                                            (
                                              'Total Ganado',
                                              fmtMonto.format(emp.total),
                                            ),
                                          ], cs)
                                        else
                                          Expanded(
                                            child: _buildInfoCol('INGRESOS', [
                                              (
                                                'Días Pagados',
                                                emp.diasPagadosMes.toString(),
                                              ),
                                              (
                                                'Haber Básico',
                                                fmtMonto.format(
                                                  emp.haberBasico,
                                                ),
                                              ),
                                              (
                                                'Bono Antigüedad',
                                                fmtMonto.format(
                                                  emp.bonoAntiguedad,
                                                ),
                                              ),
                                              (
                                                'Total Ganado',
                                                fmtMonto.format(emp.total),
                                              ),
                                            ], cs),
                                          ),

                                        SizedBox(
                                          width:
                                              ResponsiveUtilsBosque.isMobile(
                                                    context,
                                                  )
                                                  ? 0
                                                  : 16,
                                          height:
                                              ResponsiveUtilsBosque.isMobile(
                                                    context,
                                                  )
                                                  ? 16
                                                  : 0,
                                        ),

                                        if (ResponsiveUtilsBosque.isMobile(
                                          context,
                                        ))
                                          _buildInfoCol('DESCUENTOS', [
                                            ('AFP', fmtMonto.format(emp.afp)),
                                            (
                                              'Cuotas BS',
                                              fmtMonto.format(
                                                emp.cuotasBolivianos,
                                              ),
                                            ),
                                            (
                                              'Cuotas USD',
                                              NumberFormat.currency(
                                                symbol: '\$ ',
                                                decimalDigits: 2,
                                              ).format(emp.cuotasDolares),
                                            ),
                                            (
                                              'Anticipos',
                                              fmtMonto.format(emp.anticipo),
                                            ),
                                            (
                                              'Multas',
                                              fmtMonto.format(emp.multas),
                                            ),
                                            (
                                              'Otros Desc.',
                                              fmtMonto.format(emp.otros),
                                            ),
                                            (
                                              'Total Descuentos',
                                              fmtMonto.format(
                                                emp.totalDescuentos,
                                              ),
                                            ),
                                          ], cs)
                                        else
                                          Expanded(
                                            child: _buildInfoCol('DESCUENTOS', [
                                              ('AFP', fmtMonto.format(emp.afp)),
                                              (
                                                'Cuotas BS',
                                                fmtMonto.format(
                                                  emp.cuotasBolivianos,
                                                ),
                                              ),
                                              (
                                                'Cuotas USD',
                                                NumberFormat.currency(
                                                  symbol: '\$ ',
                                                  decimalDigits: 2,
                                                ).format(emp.cuotasDolares),
                                              ),
                                              (
                                                'Anticipos',
                                                fmtMonto.format(emp.anticipo),
                                              ),
                                              (
                                                'Multas',
                                                fmtMonto.format(emp.multas),
                                              ),
                                              (
                                                'Otros Desc.',
                                                fmtMonto.format(emp.otros),
                                              ),
                                              (
                                                'Total Descuentos',
                                                fmtMonto.format(
                                                  emp.totalDescuentos,
                                                ),
                                              ),
                                            ], cs),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
            ),

            // Footer de totales fijos
            if (st.items.isNotEmpty)
              _buildTotalsFooter(st.items.first, cs, fmtMonto),

            // Pagination inside dialog
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total registros: ${st.totalRegistros}',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('Mostrar: '),
                    DropdownButton<int>(
                      value: st.tamanoPagina,
                      isDense: true,
                      underline: const SizedBox(),
                      items:
                          [15, 30, 50, 100]
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text('$e'),
                                ),
                              )
                              .toList(),
                      onChanged: (v) {
                        if (v != null) ntf.cambiarTamanoPagina(v);
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Página ${st.pagina} de ${st.totalPaginas}'),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed:
                          st.pagina > 1
                              ? () => ntf.cambiarPagina(st.pagina - 1)
                              : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed:
                          st.pagina < st.totalPaginas
                              ? () => ntf.cambiarPagina(st.pagina + 1)
                              : null,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCol(
    String title,
    List<(String, String)> items,
    ColorScheme cs,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: cs.primary,
              letterSpacing: 0.5,
            ),
          ),
          const Divider(),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.$1,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final parts = item.$2.split(' ');
                      if (parts.length == 2 &&
                          (parts[0] == 'Bs' || parts[0] == '\$')) {
                        return Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                parts[0],
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  parts[1],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Expanded(
                        child: Text(
                          item.$2,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsFooter(
    PlanillaDetalleEntity item,
    ColorScheme cs,
    NumberFormat fmt,
  ) {
    final fmtUSD = NumberFormat.currency(symbol: '\$ ', decimalDigits: 2);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: RawScrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        interactive: true,
        thumbColor: cs.primary.withValues(alpha: 0.4),
        radius: const Radius.circular(8),
        thickness: 8,
        padding: const EdgeInsets.only(bottom: 2),
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              // Convertir scroll vertical de la rueda en scroll horizontal
              final delta =
                  event.scrollDelta.dy != 0
                      ? event.scrollDelta.dy
                      : event.scrollDelta.dx;
              _scrollController.animateTo(
                (_scrollController.offset + delta).clamp(
                  _scrollController.position.minScrollExtent,
                  _scrollController.position.maxScrollExtent,
                ),
                duration: const Duration(milliseconds: 80),
                curve: Curves.easeOut,
              );
            }
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                _totBadge(
                  'Haber Básico',
                  fmt.format(item.totalHaberBasico),
                  cs,
                ),
                _totBadge(
                  'B. Antigüedad',
                  fmt.format(item.totalBonoAntiguedad),
                  cs,
                ),
                // _totBadge(
                //   'B. Producción',
                //   fmt.format(item.totalBonoProduccion),
                //   cs,
                // ),
                _totBadge(
                  'Tot. Ganado',
                  fmt.format(item.sumTotalGanado),
                  cs,
                  isPrimary: true,
                ),

                Container(
                  width: 1,
                  height: 24,
                  color: cs.outlineVariant,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),

                _totBadge('AFP', fmt.format(item.totalAFP), cs),
                _totBadge(
                  'Cuotas Bs',
                  fmt.format(item.totalCuotasBolivianos),
                  cs,
                ),
                _totBadge(
                  'Cuotas USD',
                  fmtUSD.format(item.totalCuotasDolares),
                  cs,
                ),
                _totBadge('Anticipos', fmt.format(item.totalAnticipo), cs),
                _totBadge('Multas', fmt.format(item.totalMultas), cs),
                _totBadge('Otros', fmt.format(item.totalOtros), cs),
                _totBadge(
                  'Tot. Desc.',
                  fmt.format(item.totalTotalDescuentos),
                  cs,
                  isError: true,
                ),

                Container(
                  width: 1,
                  height: 24,
                  color: cs.outlineVariant,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),

                _totBadge(
                  'Líquido Pagable',
                  fmt.format(item.totalLiquido),
                  cs,
                  isSuccess: true,
                ),
              ],
            ),
          ), // cierre SingleChildScrollView
        ), // cierre Listener
      ), // cierre RawScrollbar
    );
  }

  Widget _totBadge(
    String label,
    String value,
    ColorScheme cs, {
    bool isPrimary = false,
    bool isError = false,
    bool isSuccess = false,
  }) {
    Color bg = cs.surface;
    Color fg = cs.onSurface;
    if (isPrimary) {
      bg = cs.primary;
      fg = cs.onPrimary;
    } else if (isError) {
      bg = cs.errorContainer;
      fg = cs.onErrorContainer;
    } else if (isSuccess) {
      bg = const Color(0xFF2E7D32);
      fg = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border:
            isPrimary || isError || isSuccess
                ? null
                : Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: fg.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: fg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
