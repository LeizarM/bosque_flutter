import 'package:bosque_flutter/core/state/pagos_extranjeros_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/solicitud_pago_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_proveedor_entity.dart';
import 'package:bosque_flutter/domain/entities/detalle_solicitud_entity.dart';
import 'package:bosque_flutter/presentation/widgets/pagos-extranjeros/tpex_estado_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final _nf = NumberFormat('#,##0.00', 'es_BO');
final _df = DateFormat('dd/MM/yyyy');

class PagosExtranjerosListScreen extends ConsumerStatefulWidget {
  const PagosExtranjerosListScreen({super.key});

  @override
  ConsumerState<PagosExtranjerosListScreen> createState() =>
      _PagosExtranjerosListScreenState();
}

class _PagosExtranjerosListScreenState
    extends ConsumerState<PagosExtranjerosListScreen> {
  late DateTime _fechaInicio;
  late DateTime _fechaFin;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fechaInicio = DateTime(now.year, now.month, 1);
    _fechaFin = now;
  }

  FechaRangoParam get _param => FechaRangoParam(
    fechaInicio: _fechaInicio,
    fechaFin: _fechaFin,
    codEmpresa: ref.read(userProvider)?.codEmpresa ?? 0,
  );

  Future<void> _pickDate(BuildContext context, bool esInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = picked;
          if (_fechaInicio.isAfter(_fechaFin)) _fechaFin = _fechaInicio;
        } else {
          _fechaFin = picked;
          if (_fechaFin.isBefore(_fechaInicio)) _fechaInicio = _fechaFin;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final asyncSolicitudes = ref.watch(solicitudesRegistradasProvider(_param));
    final hPad = isMobile ? 12.0 : 24.0;

    return Column(
      children: [
        // ── Barra de filtros ──────────────────────────────────────
        Container(
          margin: EdgeInsets.fromLTRB(hPad, 12, hPad, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.date_range_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              _DateButton(
                label: 'Desde',
                date: _fechaInicio,
                cs: cs,
                onTap: () => _pickDate(context, true),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: cs.outline,
                ),
              ),
              _DateButton(
                label: 'Hasta',
                date: _fechaFin,
                cs: cs,
                onTap: () => _pickDate(context, false),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed:
                    () =>
                        ref.invalidate(solicitudesRegistradasProvider(_param)),
                icon: const Icon(Icons.search_rounded, size: 16),
                label: const Text('Buscar', style: TextStyle(fontSize: 13)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),

        // ── Lista ─────────────────────────────────────────────────
        Expanded(
          child: asyncSolicitudes.when(
            loading: () => _LoadingState(hPad: hPad),
            error:
                (e, _) => _ErrorState(
                  error: e.toString(),
                  onRetry:
                      () => ref.invalidate(
                        solicitudesRegistradasProvider(_param),
                      ),
                ),
            data: (solicitudes) {
              if (solicitudes.isEmpty) return const _EmptyState();

              return Column(
                children: [
                  _ResumenHeader(solicitudes: solicitudes, hPad: hPad),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 16),
                      itemCount: solicitudes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder:
                          (context, i) => _SolicitudCard(
                            solicitud: solicitudes[i],
                            isMobile: isMobile,
                          ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Date button inline
// ═══════════════════════════════════════════════════════════════════════════════
class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final ColorScheme cs;
  final VoidCallback onTap;
  const _DateButton({
    required this.label,
    required this.date,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            Text(
              _df.format(date),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Resumen header — KPIs del período (cantidad, monto, desglose por estado)
// ═══════════════════════════════════════════════════════════════════════════════
class _ResumenHeader extends StatelessWidget {
  final List<SolicitudPagoEntity> solicitudes;
  final double hPad;
  const _ResumenHeader({required this.solicitudes, required this.hPad});

  int _count(List<String> estados) =>
      solicitudes.where((s) => estados.contains(s.estado.toUpperCase())).length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = solicitudes.fold<double>(
      0,
      (s, x) => s + x.montoTotalSolicitud,
    );
    final pend = _count(['PENDIENTE']);
    final aprob = _count(['APROBADA', 'APROBADO']);
    final pag = _count(['PAGADA', 'PAGADO']);
    final rech = _count(['RECHAZADA', 'RECHAZADO']);

    final chips = <Widget>[
      _StatChip(
        icon: Icons.receipt_long_rounded,
        label: 'Solicitudes',
        value: '${solicitudes.length}',
        color: cs.primary,
        cs: cs,
      ),
      _StatChip(
        icon: Icons.payments_rounded,
        label: 'Monto total',
        value: '\$ ${_nf.format(total)}',
        color: cs.primary,
        cs: cs,
      ),
      if (pend > 0)
        _StatChip(
          icon: Icons.schedule_rounded,
          label: 'Pendientes',
          value: '$pend',
          color: Colors.orange,
          cs: cs,
        ),
      if (aprob > 0)
        _StatChip(
          icon: Icons.verified_rounded,
          label: 'Aprobadas',
          value: '$aprob',
          color: Colors.green,
          cs: cs,
        ),
      if (pag > 0)
        _StatChip(
          icon: Icons.paid_rounded,
          label: 'Pagadas',
          value: '$pag',
          color: Colors.teal,
          cs: cs,
        ),
      if (rech > 0)
        _StatChip(
          icon: Icons.cancel_rounded,
          label: 'Rechazadas',
          value: '$rech',
          color: Colors.red,
          cs: cs,
        ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 4),
      child: SizedBox(
        height: 54,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: chips.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => chips[i],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ColorScheme cs;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                  height: 1.1,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  height: 1.15,
                  fontFeatures: tpexTabularFigures,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Loading — skeletons animados (en vez de spinner pelado)
// ═══════════════════════════════════════════════════════════════════════════════
class _LoadingState extends StatelessWidget {
  final double hPad;
  const _LoadingState({required this.hPad});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: cs.onSurfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0.30, end: 0.65).animate(_ctrl),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(170, 12),
                  const SizedBox(height: 8),
                  bar(110, 10),
                ],
              ),
            ),
            const SizedBox(width: 12),
            bar(70, 14),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Solicitud card — flat design, sin nested expansions
// ═══════════════════════════════════════════════════════════════════════════════
class _SolicitudCard extends StatefulWidget {
  final SolicitudPagoEntity solicitud;
  final bool isMobile;
  const _SolicitudCard({required this.solicitud, required this.isMobile});

  @override
  State<_SolicitudCard> createState() => _SolicitudCardState();
}

class _SolicitudCardState extends State<_SolicitudCard> {
  bool _expanded = false;

  SolicitudPagoEntity get sol => widget.solicitud;

  Color _estadoColor() => tpexEstadoColor(sol.estado);

  IconData _estadoIcon() => tpexEstadoIcon(sol.estado);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estadoColor = _estadoColor();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Header con barra de color a la izquierda ─────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: estadoColor, width: 4)),
              ),
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              child: Row(
                children: [
                  // ID badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${sol.idSolicitud}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sol.nombre.isNotEmpty
                              ? sol.nombre
                              : 'Empresa #${sol.codEmpresa}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: cs.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _df.format(sol.fechaSolicitud),
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.people_alt_outlined,
                              size: 12,
                              color: cs.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${sol.proveedores.length} prov.',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Monto
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$ ${_nf.format(sol.montoTotalSolicitud)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: cs.primary,
                          fontFeatures: tpexTabularFigures,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Estado badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: estadoColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_estadoIcon(), size: 12, color: estadoColor),
                            const SizedBox(width: 4),
                            Text(
                              sol.estado,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: estadoColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: cs.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenido expandible: proveedores y facturas ─────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildProveedoresSection(cs),
            crossFadeState:
                _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildProveedoresSection(ColorScheme cs) {
    if (sol.proveedores.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Sin proveedores registrados',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
      );
    }

    return Column(
      children: [
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
        ...sol.proveedores.map(
          (prov) => _ProveedorSection(
            proveedor: prov,
            cs: cs,
            isMobile: widget.isMobile,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Proveedor section — flat, no expansion tile
// ═══════════════════════════════════════════════════════════════════════════════
class _ProveedorSection extends StatefulWidget {
  final SolicitudProveedorEntity proveedor;
  final ColorScheme cs;
  final bool isMobile;
  const _ProveedorSection({
    required this.proveedor,
    required this.cs,
    required this.isMobile,
  });

  @override
  State<_ProveedorSection> createState() => _ProveedorSectionState();
}

class _ProveedorSectionState extends State<_ProveedorSection> {
  bool _showDetalles = false;

  @override
  Widget build(BuildContext context) {
    final prov = widget.proveedor;
    final cs = widget.cs;
    final totalFacturas = prov.detalles.fold<double>(
      0,
      (s, d) => s + d.montoFacturaUsd,
    );
    final totalAmort = prov.detalles.fold<double>(
      0,
      (s, d) => s + d.montoAmortizadoUsd,
    );
    final totalPagar = prov.detalles.fold<double>(
      0,
      (s, d) => s + d.montoAPagarUsd,
    );

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          // Provider header
          InkWell(
            onTap:
                prov.detalles.isNotEmpty
                    ? () => setState(() => _showDetalles = !_showDetalles)
                    : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.secondaryContainer,
                    child: Icon(
                      Icons.business_rounded,
                      size: 16,
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prov.cardName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          prov.cardCode,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Montos inline
                  if (!widget.isMobile) ...[
                    _MontoChip(label: 'Factura', value: totalFacturas, cs: cs),
                    const SizedBox(width: 6),
                    _MontoChip(label: 'Amort.', value: totalAmort, cs: cs),
                    const SizedBox(width: 6),
                  ],
                  _MontoChip(
                    label: 'A Pagar',
                    value: totalPagar,
                    cs: cs,
                    bold: true,
                  ),
                  if (prov.detalles.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _showDetalles ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 18,
                        color: cs.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Detalles (facturas)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildDetalles(cs),
            crossFadeState:
                _showDetalles
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalles(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        children:
            widget.proveedor.detalles
                .map((det) => _FacturaRow(det: det, cs: cs))
                .toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Monto chip inline
// ═══════════════════════════════════════════════════════════════════════════════
class _MontoChip extends StatelessWidget {
  final String label;
  final double value;
  final ColorScheme cs;
  final bool bold;
  const _MontoChip({
    required this.label,
    required this.value,
    required this.cs,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
        Text(
          '\$ ${_nf.format(value)}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold ? cs.primary : cs.onSurface,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Factura row inline (no card wrapper)
// ═══════════════════════════════════════════════════════════════════════════════
class _FacturaRow extends StatelessWidget {
  final DetalleSolicitudEntity det;
  final ColorScheme cs;
  const _FacturaRow({required this.det, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    det.tipoDocumento,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: cs.onTertiaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Doc: ${det.numeroDocumento}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '\$ ${_nf.format(det.montoAPagarUsd)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _SmallLabel(
                  label: 'Factura',
                  value: '\$ ${_nf.format(det.montoFacturaUsd)}',
                ),
                _SmallLabel(
                  label: 'Amortizado',
                  value: '\$ ${_nf.format(det.montoAmortizadoUsd)}',
                ),
                _SmallLabel(
                  label: 'F. Factura',
                  value: _df.format(det.fechaFactura),
                ),
                _SmallLabel(
                  label: 'F. Venc.',
                  value: _df.format(det.fechaVencimiento),
                ),
                if (det.codigoImportacion.isNotEmpty)
                  _SmallLabel(
                    label: 'Importación',
                    value: det.codigoImportacion,
                  ),
                if (det.obs.isNotEmpty)
                  _SmallLabel(label: 'Obs', value: det.obs),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Small label (key: value)
// ═══════════════════════════════════════════════════════════════════════════════
class _SmallLabel extends StatelessWidget {
  final String label;
  final String value;
  const _SmallLabel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFeatures: tpexTabularFigures,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Empty & Error states
// ═══════════════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 56,
            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Sin solicitudes en este período',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ajuste las fechas y presione Buscar',
            style: TextStyle(fontSize: 12, color: cs.outline),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 44, color: cs.error),
            const SizedBox(height: 10),
            Text(
              'Error al cargar solicitudes',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
