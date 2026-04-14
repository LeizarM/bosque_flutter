import 'package:bosque_flutter/core/state/pagos_extranjeros_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/data/repositories/pagos_extranjeros_impl.dart';
import 'package:bosque_flutter/domain/entities/cargo_pago_entity.dart';
import 'package:bosque_flutter/domain/entities/cotizaciones_entity.dart';
import 'package:bosque_flutter/domain/entities/detalle_solicitud_entity.dart';
import 'package:bosque_flutter/domain/entities/log_estados_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_pago_entity.dart';
import 'package:bosque_flutter/domain/entities/transacciones_entity.dart';
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final _numberFormat = NumberFormat('#,##0.00', 'es_BO');
final _dateFormat = DateFormat('dd/MM/yyyy');
final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

/// Descarga el voucher vía POST (con JWT) y lo muestra en un Dialog.
Future<void> _verVoucherPost(
  BuildContext context,
  BigInt idTransaccion, {
  int codEmpresa = 0,
}) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    final repo = PagosExtranjerosImpl();
    final (bytes, contentType) = await repo.descargarVoucher(
      idTransaccion,
      codEmpresa: codEmpresa,
    );
    if (!context.mounted) return;
    Navigator.of(context).pop(); // quitar loading
    final isImage = contentType.startsWith('image/');
    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Dialog(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: cs.primaryContainer,
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, color: cs.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        'Voucher',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child:
                      isImage
                          ? InteractiveViewer(
                            child: Image.memory(bytes, fit: BoxFit.contain),
                          )
                          : PdfPreview(
                            build: (_) async => bytes,
                            canChangeOrientation: false,
                            canChangePageFormat: false,
                            canDebug: false,
                            allowPrinting: false,
                            allowSharing: false,
                            pdfFileName: 'voucher.pdf',
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error al descargar voucher: $e')));
  }
}

/// Abre el panel de detalle de una solicitud (tabs: Proveedores, Cotizaciones,
/// Transacciones, Historial, Timeline). En desktop abre un Dialog; en móvil un BottomSheet.
/// [initialTab] 0=Proveedores, 1=Cotizaciones, 2=Transacciones, 3=Historial, 4=Timeline.
void abrirDetalleSolicitud(
  BuildContext context,
  WidgetRef ref,
  SolicitudPagoEntity solicitud, {
  int initialTab = 0,
}) {
  final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
  final widget = ProviderScope(
    parent: ProviderScope.containerOf(context),
    child: _SolicitudDetailPanel(solicitud: solicitud, initialTab: initialTab),
  );

  if (isDesktop) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => widget,
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, controller) => widget,
          ),
    );
  }
}

class _SolicitudDetailPanel extends ConsumerStatefulWidget {
  final SolicitudPagoEntity solicitud;
  final int initialTab;
  const _SolicitudDetailPanel({required this.solicitud, this.initialTab = 0});

  @override
  ConsumerState<_SolicitudDetailPanel> createState() =>
      _SolicitudDetailPanelState();
}

class _SolicitudDetailPanelState extends ConsumerState<_SolicitudDetailPanel>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 4),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final sol = widget.solicitud;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Text(
                  '${sol.idSolicitud}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solicitud #${sol.idSolicitud}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${sol.nombre}  ·  \$ ${_numberFormat.format(sol.montoTotalSolicitud)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _EstadoBadge(estado: sol.estado),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── Tabs ─────────────────────────────────────────────
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.people_outline_rounded, size: 18),
              text: 'Proveedores',
            ),
            Tab(
              icon: Icon(Icons.currency_exchange_rounded, size: 18),
              text: 'Cotizaciones',
            ),
            Tab(
              icon: Icon(Icons.swap_horiz_rounded, size: 18),
              text: 'Transacciones',
            ),
            Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'Historial'),
            Tab(icon: Icon(Icons.timeline_rounded, size: 18), text: 'Timeline'),
          ],
        ),
        const Divider(height: 1),

        // ── Tab views ────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _TabProveedores(solicitud: sol),
              _TabCotizaciones(solicitud: sol),
              _TabTransacciones(solicitud: sol),
              _TabLog(solicitud: sol),
              _TabTimeline(solicitud: sol),
            ],
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Dialog(
        insetPadding: const EdgeInsets.all(32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820, maxHeight: 700),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: content,
          ),
        ),
      );
    }
    return content;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Badge de estado reutilizable
// ═════════════════════════════════════════════════════════════════════════════
class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  Color _color() {
    switch (estado.toUpperCase()) {
      case 'APROBADA':
        return Colors.green;
      case 'PAGADA':
        return Colors.teal;
      case 'CANCELADA':
      case 'RECHAZADA':
      case 'RECHAZADO':
        return Colors.red;
      case 'PROCESADO':
        return Colors.blue;
      case 'CONFIRMADO':
        return Colors.teal;
      case 'PENDIENTE':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 1: Proveedores / Facturas
// ═════════════════════════════════════════════════════════════════════════════
class _TabProveedores extends StatelessWidget {
  final SolicitudPagoEntity solicitud;
  const _TabProveedores({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final proveedores = solicitud.proveedores;
    if (proveedores.isEmpty) {
      return _EmptyTab(
        icon: Icons.people_outline_rounded,
        message: 'No hay proveedores registrados',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: proveedores.length,
      itemBuilder: (context, index) {
        final prov = proveedores[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          color: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: ExpansionTile(
            leading: Icon(Icons.business_rounded, size: 20, color: cs.primary),
            title: Text(
              prov.cardName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            subtitle: Builder(
              builder: (_) {
                final aPagar = prov.detalles.fold<double>(
                  0,
                  (s, d) => s + d.montoAPagarUsd,
                );
                return Text(
                  '${prov.cardCode}  ·  A pagar: \$ ${_numberFormat.format(aPagar)}',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                );
              },
            ),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              // Stats — computed from detalles (API returns 0 at provider level)
              Builder(
                builder: (_) {
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
                  return Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MiniChip(
                        label: 'Facturas',
                        value: '\$ ${_numberFormat.format(totalFacturas)}',
                        cs: cs,
                      ),
                      _MiniChip(
                        label: 'Amortizado',
                        value: '\$ ${_numberFormat.format(totalAmort)}',
                        cs: cs,
                      ),
                      _MiniChip(
                        label: 'A Pagar',
                        value: '\$ ${_numberFormat.format(totalPagar)}',
                        cs: cs,
                        bold: true,
                      ),
                    ],
                  );
                },
              ),
              if (prov.detalles.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 6),
                ...prov.detalles.map((det) => _FacturaTile(det: det, cs: cs)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FacturaTile extends StatelessWidget {
  final DetalleSolicitudEntity det;
  final ColorScheme cs;
  const _FacturaTile({required this.det, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              det.tipoDocumento,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: cs.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Doc: ${det.numeroDocumento}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Venc: ${_dateFormat.format(det.fechaVencimiento)}',
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '\$ ${_numberFormat.format(det.montoAPagarUsd)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 2: Cotizaciones
// ═════════════════════════════════════════════════════════════════════════════
class _TabCotizaciones extends ConsumerWidget {
  final SolicitudPagoEntity solicitud;
  const _TabCotizaciones({required this.solicitud});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final asyncCotizaciones = ref.watch(
      cotizacionesXSolicitudProvider(solicitud.idSolicitud),
    );

    return asyncCotizaciones.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorTab(message: e.toString()),
      data: (cotizaciones) {
        if (cotizaciones.isEmpty) {
          return _EmptyTab(
            icon: Icons.currency_exchange_rounded,
            message: 'No hay cotizaciones registradas',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cotizaciones.length,
          itemBuilder:
              (context, index) =>
                  _CotizacionCard(cotizacion: cotizaciones[index], cs: cs),
        );
      },
    );
  }
}

class _CotizacionCard extends ConsumerStatefulWidget {
  final CotizacionesEntity cotizacion;
  final ColorScheme cs;
  const _CotizacionCard({required this.cotizacion, required this.cs});

  @override
  ConsumerState<_CotizacionCard> createState() => _CotizacionCardState();
}

class _CotizacionCardState extends ConsumerState<_CotizacionCard> {
  bool _showCargos = false;

  @override
  Widget build(BuildContext context) {
    final cot = widget.cotizacion;
    final cs = widget.cs;
    final bancosAsync = ref.watch(bancosTPEXProvider);
    final nombreBanco =
        bancosAsync.valueOrNull
            ?.where((b) => b.codBanco == cot.codBanco)
            .firstOrNull
            ?.nombre ??
        'Banco #${cot.codBanco}';
    final esAceptada = cot.estado.toUpperCase() == 'ACEPTADA';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              esAceptada
                  ? Colors.green.withValues(alpha: 0.5)
                  : cs.outlineVariant.withValues(alpha: 0.4),
          width: esAceptada ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  esAceptada
                      ? Icons.emoji_events_rounded
                      : Icons.receipt_long_rounded,
                  size: 20,
                  color: esAceptada ? Colors.amber.shade700 : cs.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cot. #${cot.idCotizacion}  ·  $nombreBanco',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                _EstadoBadge(estado: cot.estado),
              ],
            ),
            const SizedBox(height: 10),
            // Data rows
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _DataPair(
                  label: 'TC Ofrecido',
                  value: cot.tipoCambioOfrecido.toStringAsFixed(4),
                ),
                _DataPair(
                  label: 'Monto Compra',
                  value: '\$ ${_numberFormat.format(cot.montoCompra)}',
                ),
                _DataPair(
                  label: 'Convertido',
                  value: 'Bs. ${_numberFormat.format(cot.montoConvertido)}',
                ),
                _DataPair(
                  label: 'Total Bs.',
                  value: 'Bs. ${_numberFormat.format(cot.totalBolivianos)}',
                  bold: true,
                ),
                _DataPair(
                  label: 'Fecha',
                  value: _dateFormat.format(cot.fechaCotizacion),
                ),
              ],
            ),
            // Cargos inline (from nested entity) or fetch from endpoint
            if (cot.cargos.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setState(() => _showCargos = !_showCargos),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showCargos
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 16,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${cot.cargos.length} cargo(s) bancario(s)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showCargos) _CargosTable(cargos: cot.cargos, cs: cs),
            ] else ...[
              // Fetch cargos from endpoint
              const SizedBox(height: 8),
              _CargosFromEndpoint(
                idCotizacion: cot.idCotizacion.toInt(),
                cs: cs,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CargosFromEndpoint extends ConsumerWidget {
  final int idCotizacion;
  final ColorScheme cs;
  const _CargosFromEndpoint({required this.idCotizacion, required this.cs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCargos = ref.watch(cargosCotizacionProvider(idCotizacion));
    return asyncCargos.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (cargos) {
        if (cargos.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${cargos.length} cargo(s) bancario(s)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 4),
            _CargosTable(cargos: cargos, cs: cs),
          ],
        );
      },
    );
  }
}

class _CargosTable extends StatelessWidget {
  final List<CargoPagoEntity> cargos;
  final ColorScheme cs;
  const _CargosTable({required this.cargos, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children:
            cargos
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.descripcion.isNotEmpty
                                ? c.descripcion
                                : 'Cargo #${c.idCargo}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        if (c.porcentaje > 0)
                          Text(
                            '${c.porcentaje.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(width: 12),
                        Text(
                          _numberFormat.format(c.montoCargo),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 3: Transacciones
// ═════════════════════════════════════════════════════════════════════════════
class _TabTransacciones extends ConsumerWidget {
  final SolicitudPagoEntity solicitud;
  const _TabTransacciones({required this.solicitud});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final asyncTxns = ref.watch(
      transaccionesXSolicitudProvider((
        idSolicitud: solicitud.idSolicitud,
        codEmpresa: solicitud.codEmpresa,
      )),
    );

    return asyncTxns.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorTab(message: e.toString()),
      data: (txns) {
        if (txns.isEmpty) {
          return _EmptyTab(
            icon: Icons.swap_horiz_rounded,
            message: 'No hay transacciones registradas',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: txns.length,
          itemBuilder:
              (context, index) => _TransaccionCard(
                txn: txns[index],
                codEmpresa: solicitud.codEmpresa,
                cs: cs,
              ),
        );
      },
    );
  }
}

class _TransaccionCard extends ConsumerStatefulWidget {
  final TransaccionesEntity txn;
  final int codEmpresa;
  final ColorScheme cs;
  const _TransaccionCard({
    required this.txn,
    required this.codEmpresa,
    required this.cs,
  });

  @override
  ConsumerState<_TransaccionCard> createState() => _TransaccionCardState();
}

class _TransaccionCardState extends ConsumerState<_TransaccionCard> {
  bool _showCargos = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.txn;
    final cs = widget.cs;
    final bancosAsync = ref.watch(bancosTPEXProvider);
    final monedasAsync = ref.watch(monedasProvider);
    final nombreBanco =
        bancosAsync.valueOrNull
            ?.where((b) => b.codBanco == t.codBanco)
            .firstOrNull
            ?.nombre ??
        'Banco #${t.codBanco}';
    final monOrigen =
        monedasAsync.valueOrNull
            ?.where((m) => m.idMoneda == t.idMonedaOrigen)
            .firstOrNull
            ?.codigo ??
        (monedasAsync.isLoading ? '...' : '\$');
    final monDestino =
        monedasAsync.valueOrNull
            ?.where((m) => m.idMoneda == t.idMonedaDestino)
            .firstOrNull
            ?.codigo ??
        (monedasAsync.isLoading ? '...' : 'Bs.');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_rounded, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Txn #${t.idTransaccion}  ·  $nombreBanco',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                _EstadoBadge(estado: t.estado),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _DataPair(
                  label: 'Monto Origen',
                  value: '$monOrigen ${_numberFormat.format(t.montoOrigen)}',
                ),
                _DataPair(
                  label: 'TC Aplicado',
                  value: t.tipoCambioAplicado.toStringAsFixed(4),
                ),
                _DataPair(
                  label: 'Convertido',
                  value:
                      '$monDestino ${_numberFormat.format(t.montoConvertido)}',
                ),
                _DataPair(
                  label: 'Total Final',
                  value: '$monDestino ${_numberFormat.format(t.totalFinal)}',
                  bold: true,
                ),
                _DataPair(
                  label: 'Fecha',
                  value: _dateFormat.format(t.fechaTransaccion),
                ),
                if (t.numeroTransaccion.isNotEmpty)
                  _DataPair(label: 'N° Bancario', value: t.numeroTransaccion),
              ],
            ),
            // TC referencia y diferencia
            if (t.tipoCambioReferencia > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'TC Ref BCB: ${t.tipoCambioReferencia.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Dif: ${t.diferenciaDeMas >= 0 ? "+" : ""}${_numberFormat.format(t.diferenciaDeMas)} (${t.porcentajeDiferencia.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          t.diferenciaDeMas > 0
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ],
            // Cargos
            if (t.cargos.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setState(() => _showCargos = !_showCargos),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showCargos
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 16,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${t.cargos.length} cargo(s)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showCargos) _CargosTable(cargos: t.cargos, cs: cs),
            ] else ...[
              const SizedBox(height: 8),
              _TxnCargosFromEndpoint(
                idTransaccion: t.idTransaccion.toInt(),
                cs: cs,
              ),
            ],
            // Log de la transacción
            const SizedBox(height: 8),
            _TxnLogInline(idTransaccion: t.idTransaccion, cs: cs),
            // Voucher
            const SizedBox(height: 8),
            if (t.tieneVoucher)
              ActionChip(
                avatar: Icon(Icons.check_circle, color: cs.primary, size: 18),
                label: const Text('Ver Voucher'),
                backgroundColor: cs.primaryContainer,
                onPressed:
                    () => _verVoucherPost(
                      context,
                      t.idTransaccion,
                      codEmpresa:
                          t.codEmpresa != 0 ? t.codEmpresa : widget.codEmpresa,
                    ),
              )
            else
              Text(
                'Sin voucher adjunto',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TxnCargosFromEndpoint extends ConsumerWidget {
  final int idTransaccion;
  final ColorScheme cs;
  const _TxnCargosFromEndpoint({required this.idTransaccion, required this.cs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCargos = ref.watch(cargosTransaccionProvider(idTransaccion));
    return asyncCargos.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (cargos) {
        if (cargos.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${cargos.length} cargo(s)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 4),
            _CargosTable(cargos: cargos, cs: cs),
          ],
        );
      },
    );
  }
}

class _TxnLogInline extends ConsumerWidget {
  final BigInt idTransaccion;
  final ColorScheme cs;
  const _TxnLogInline({required this.idTransaccion, required this.cs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLog = ref.watch(logTransaccionProvider(idTransaccion));
    return asyncLog.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (logs) {
        if (logs.isEmpty) return const SizedBox.shrink();
        return ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 4),
          dense: true,
          leading: Icon(Icons.history_rounded, size: 16, color: cs.primary),
          title: Text(
            '${logs.length} cambio(s) de estado',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
          children: logs.map((log) => _LogTileMini(log: log, cs: cs)).toList(),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 4: Historial Solicitud (solo log de la solicitud)
// ═════════════════════════════════════════════════════════════════════════════
class _TabLog extends ConsumerWidget {
  final SolicitudPagoEntity solicitud;
  const _TabLog({required this.solicitud});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLog = ref.watch(logSolicitudProvider(solicitud.idSolicitud));

    return asyncLog.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorTab(message: e.toString()),
      data: (logs) {
        if (logs.isEmpty) {
          return _EmptyTab(
            icon: Icons.history_rounded,
            message: 'Sin historial de estados registrado',
          );
        }
        return _TimelineListView(logs: logs, showEntityBadge: false);
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 5: Timeline Completo (solicitud + cotizaciones + transacciones)
// ═════════════════════════════════════════════════════════════════════════════
class _TabTimeline extends ConsumerWidget {
  final SolicitudPagoEntity solicitud;
  const _TabTimeline({required this.solicitud});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTimeline = ref.watch(
      timelineSolicitudProvider(solicitud.idSolicitud),
    );

    return asyncTimeline.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorTab(message: e.toString()),
      data: (logs) {
        if (logs.isEmpty) {
          return _EmptyTab(
            icon: Icons.timeline_rounded,
            message: 'Sin historial de estados registrado',
          );
        }
        return _TimelineListView(logs: logs, showEntityBadge: true);
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Timeline visual compartido
// ═════════════════════════════════════════════════════════════════════════════

class _TimelineListView extends StatelessWidget {
  final List<LogEstadosEntity> logs;
  final bool showEntityBadge;
  const _TimelineListView({required this.logs, required this.showEntityBadge});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        return _TimelineItem(
          log: logs[index],
          isFirst: index == 0,
          isLast: index == logs.length - 1,
          showEntityBadge: showEntityBadge,
        );
      },
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final LogEstadosEntity log;
  final bool isFirst;
  final bool isLast;
  final bool showEntityBadge;

  const _TimelineItem({
    required this.log,
    required this.isFirst,
    required this.isLast,
    required this.showEntityBadge,
  });

  /// Color del dot/línea según tipoEntidad.
  Color _entityColor() {
    switch (log.tipoEntidad.toUpperCase()) {
      case 'COTIZACION':
        return Colors.orange;
      case 'TRANSACCION':
        return Colors.green.shade700;
      case 'SOLICITUD':
      default:
        return Colors.blue;
    }
  }

  /// Color semántico por estadoNuevo.
  static Color estadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return Colors.grey;
      case 'APROBADA':
        return Colors.blue;
      case 'ENVIADA':
        return Colors.orange;
      case 'ACEPTADA':
        return Colors.lightBlue;
      case 'PROCESADO':
        return Colors.amber.shade700;
      case 'CONFIRMADO':
        return Colors.green;
      case 'PAGADA':
        return Colors.teal.shade700;
      case 'RECHAZADA':
      case 'RECHAZADO':
      case 'CANCELADA':
      case 'ERROR':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _entityIcon() {
    switch (log.tipoEntidad.toUpperCase()) {
      case 'COTIZACION':
        return Icons.currency_exchange_rounded;
      case 'TRANSACCION':
        return Icons.swap_horiz_rounded;
      case 'SOLICITUD':
      default:
        return Icons.description_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dotColor =
        showEntityBadge ? _entityColor() : estadoColor(log.estadoNuevo);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Línea vertical + dot ────────────────────────────────
          SizedBox(
            width: 36,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  )
                else
                  const Spacer(),
                // Dot con icono si timeline completo
                if (showEntityBadge)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor.withValues(alpha: 0.15),
                      border: Border.all(color: dotColor, width: 2),
                    ),
                    child: Icon(_entityIcon(), size: 14, color: dotColor),
                  )
                else
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                      border: Border.all(
                        color: dotColor.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                  ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  )
                else
                  const Spacer(),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ── Contenido ──────────────────────────────────────────
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      showEntityBadge
                          ? dotColor.withValues(alpha: 0.25)
                          : cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila principal: badges de estado + fecha
                  Row(
                    children: [
                      // Badge tipo entidad (solo en timeline completo)
                      if (showEntityBadge) ...[
                        _TipoEntidadChip(
                          tipoEntidad: log.tipoEntidad,
                          idEntidad: log.idEntidad,
                          color: dotColor,
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Estado anterior → nuevo, o solo nuevo si es inicial
                      if (log.estadoAnterior.isNotEmpty) ...[
                        _EstadoNuevoBadge(estado: log.estadoAnterior),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        _EstadoNuevoBadge(estado: log.estadoNuevo),
                      ] else ...[
                        _EstadoNuevoBadge(estado: log.estadoNuevo),
                        const SizedBox(width: 4),
                        Text(
                          '(estado inicial)',
                          style: TextStyle(
                            fontSize: 9,
                            fontStyle: FontStyle.italic,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Fecha
                      Text(
                        _dateTimeFormat.format(log.fechaCreacion),
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  // Observaciones
                  if (log.observaciones.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      log.observaciones,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                  // Usuario
                  if (log.audUsuario > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Usuario: ${log.audUsuario}',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge que muestra el tipo de entidad + ID en timeline completo.
class _TipoEntidadChip extends StatelessWidget {
  final String tipoEntidad;
  final String idEntidad;
  final Color color;
  const _TipoEntidadChip({
    required this.tipoEntidad,
    required this.idEntidad,
    required this.color,
  });

  String get _label {
    final tipo = tipoEntidad.toUpperCase();
    final prefix =
        tipo == 'SOLICITUD'
            ? 'SOL'
            : tipo == 'COTIZACION'
            ? 'COT'
            : tipo == 'TRANSACCION'
            ? 'TXN'
            : tipo;
    return idEntidad.isNotEmpty ? '$prefix #$idEntidad' : prefix;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Badge de estado con color semántico.
class _EstadoNuevoBadge extends StatelessWidget {
  final String estado;
  const _EstadoNuevoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final c = _TimelineItem.estadoColor(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }
}

class _LogTileMini extends StatelessWidget {
  final LogEstadosEntity log;
  final ColorScheme cs;
  const _LogTileMini({required this.log, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          if (log.estadoAnterior.isNotEmpty)
            Text(
              '${log.estadoAnterior} → ',
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
            ),
          _EstadoNuevoBadge(estado: log.estadoNuevo),
          const SizedBox(width: 8),
          Text(
            _dateTimeFormat.format(log.fechaCreacion),
            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Shared helpers
// ═════════════════════════════════════════════════════════════════════════════

class _DataPair extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _DataPair({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: bold ? cs.primary : cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  final bool bold;
  const _MiniChip({
    required this.label,
    required this.value,
    required this.cs,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: bold ? cs.primary : cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyTab({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ErrorTab extends StatelessWidget {
  final String message;
  const _ErrorTab({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
