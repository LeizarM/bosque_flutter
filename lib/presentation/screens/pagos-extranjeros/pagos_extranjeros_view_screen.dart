import 'package:bosque_flutter/core/state/pagos_extranjeros_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/data/repositories/pagos_extranjeros_impl.dart';
import 'package:bosque_flutter/domain/entities/cotizaciones_entity.dart';
import 'package:bosque_flutter/domain/entities/detalle_solicitud_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_pago_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_proveedor_entity.dart';
import 'package:bosque_flutter/domain/entities/transacciones_entity.dart';
import 'package:bosque_flutter/presentation/screens/pagos-extranjeros/solicitud_detail_panel.dart';
import 'package:bosque_flutter/presentation/widgets/pagos-extranjeros/voucher_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final _nf = NumberFormat('#,##0.00', 'es_BO');
final _df = DateFormat('dd/MM/yyyy');

class PagosAlExtranjerosViewScreen extends ConsumerStatefulWidget {
  const PagosAlExtranjerosViewScreen({super.key});

  @override
  ConsumerState<PagosAlExtranjerosViewScreen> createState() =>
      _PagosAlExtranjerosViewScreenState();
}

class _PagosAlExtranjerosViewScreenState
    extends ConsumerState<PagosAlExtranjerosViewScreen> {
  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  BigInt? _approvingId;
  BigInt? _rejectingId;

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
          if (_fechaInicio.isAfter(_fechaFin)) {
            _fechaFin = _fechaInicio;
          }
        } else {
          _fechaFin = picked;
          if (_fechaFin.isBefore(_fechaInicio)) {
            _fechaInicio = _fechaFin;
          }
        }
      });
    }
  }

  void _abrirCotizacion(SolicitudPagoEntity solicitud) {
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    // Init form con idSolicitud
    ref
        .read(cotizacionFormProvider.notifier)
        .init(idSolicitud: solicitud.idSolicitud);

    if (isDesktop) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => ProviderScope(
              parent: ProviderScope.containerOf(context),
              child: _DialogoCotizacion(
                solicitud: solicitud,
                onGuardado: () {
                  ref.invalidate(solicitudesRegistradasProvider(_param));
                },
              ),
            ),
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
            (_) => ProviderScope(
              parent: ProviderScope.containerOf(context),
              child: _DialogoCotizacion(
                solicitud: solicitud,
                onGuardado: () {
                  ref.invalidate(solicitudesRegistradasProvider(_param));
                },
              ),
            ),
      );
    }
  }

  void _abrirComparativa(SolicitudPagoEntity solicitud) {
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    if (isDesktop) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => ProviderScope(
              parent: ProviderScope.containerOf(context),
              child: _DialogoComparativa(
                solicitud: solicitud,
                onAceptada: () {
                  ref.invalidate(solicitudesRegistradasProvider(_param));
                },
              ),
            ),
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
            (_) => ProviderScope(
              parent: ProviderScope.containerOf(context),
              child: _DialogoComparativa(
                solicitud: solicitud,
                onAceptada: () {
                  ref.invalidate(solicitudesRegistradasProvider(_param));
                },
              ),
            ),
      );
    }
  }

  void _abrirTransaccion(SolicitudPagoEntity solicitud) async {
    // Buscar cotización aceptada/ganadora
    List<CotizacionesEntity> cotizaciones = [];
    try {
      cotizaciones = await ref.read(
        cotizacionesXSolicitudProvider(solicitud.idSolicitud).future,
      );
    } catch (_) {
      cotizaciones = [];
    }

    final aceptada =
        cotizaciones
            .where(
              (c) => c.estado.toUpperCase() == 'ACEPTADA' || c.esGanadora == 1,
            )
            .firstOrNull;

    if (aceptada == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Primero acepte una cotización en la Comparativa.',
          ),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    // Verificar si ya existe una transacción sin confirmar para esta solicitud
    // Llamada directa al repo (sin cache) para evitar datos desactualizados
    List<TransaccionesEntity> transacciones = [];
    try {
      transacciones = await PagosExtranjerosImpl().getTransaccionesPorSolicitud(
        solicitud.idSolicitud,
        codEmpresa: solicitud.codEmpresa,
      );
    } catch (_) {
      transacciones = [];
    }

    // Buscar transacción que aún necesita confirmación (PENDIENTE o PROCESADO)
    final sinConfirmar =
        transacciones
            .where(
              (t) =>
                  t.estado.toUpperCase() == 'PENDIENTE' ||
                  t.estado.toUpperCase() == 'PROCESADO',
            )
            .firstOrNull;

    if (sinConfirmar != null) {
      // Ya existe transacción sin confirmar → abrir diálogo de confirmación
      ref.read(transaccionFormProvider.notifier).resetForm();
      ref
          .read(transaccionFormProvider.notifier)
          .precargarDesdeTransaccion(sinConfirmar);

      if (!mounted) return;
      final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
      final dialogWidget = ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _DialogoTransaccion(
          solicitud: solicitud,
          cotizacionAceptada: aceptada,
          modoConfirmar: true,
          estadoTransaccion: sinConfirmar.estado.toUpperCase(),
          onGuardado: () {
            ref.invalidate(solicitudesRegistradasProvider(_param));
            ref.invalidate(
              transaccionesXSolicitudProvider((
                idSolicitud: solicitud.idSolicitud,
                codEmpresa: solicitud.codEmpresa,
              )),
            );
          },
        ),
      );

      if (isDesktop) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => dialogWidget,
        );
      } else {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => dialogWidget,
        );
      }
      return;
    }

    // No hay transacción pendiente → crear nueva (flujo normal Fase 4)

    // codEmpresa: preferir el de la solicitud, pero si viene 0 usar el del usuario logueado
    final codEmpresaFinal =
        solicitud.codEmpresa != 0
            ? solicitud.codEmpresa
            : (ref.read(userProvider)?.codEmpresa ?? 0);

    // Preparar formulario de transacción con datos pre-cargados
    ref.read(transaccionFormProvider.notifier).resetForm();
    ref
        .read(transaccionFormProvider.notifier)
        .precargarDesdeCotizacion(
          cotizacion: aceptada,
          codEmpresa: codEmpresaFinal,
          cardCode:
              solicitud.proveedores.isNotEmpty
                  ? solicitud.proveedores.first.cardCode
                  : '',
        );

    // Auto-set moneda destino a BOB (Bolivianos)
    final monedas = ref.read(monedasProvider).valueOrNull ?? [];
    final bob = monedas.where((m) => m.codigo == 'BOB').firstOrNull;
    if (bob != null) {
      ref
          .read(transaccionFormProvider.notifier)
          .setIdMonedaDestino(bob.idMoneda);
    }

    await ref
        .read(transaccionFormProvider.notifier)
        .cargarTcReferencia(aceptada.codBanco);

    if (!mounted) return;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final dialogWidget = ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: _DialogoTransaccion(
        solicitud: solicitud,
        cotizacionAceptada: aceptada,
        onGuardado: () {
          ref.invalidate(solicitudesRegistradasProvider(_param));
          ref.invalidate(
            transaccionesXSolicitudProvider((
              idSolicitud: solicitud.idSolicitud,
              codEmpresa: solicitud.codEmpresa,
            )),
          );
        },
      ),
    );

    if (isDesktop) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => dialogWidget,
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => dialogWidget,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final asyncSolicitudes = ref.watch(solicitudesRegistradasProvider(_param));
    final hPad = isMobile ? 12.0 : 24.0;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fact_check_outlined, size: 22, color: cs.primary),
            const SizedBox(width: 10),
            const Text(
              'Gestión de Solicitudes',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: Column(
        children: [
          // ── Filtros ─────────────────────────────────────────────
          Container(
            margin: EdgeInsets.fromLTRB(hPad, 12, hPad, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
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
                      () => ref.invalidate(
                        solicitudesRegistradasProvider(_param),
                      ),
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

          // ── Lista ───────────────────────────────────────────────
          Expanded(
            child: asyncSolicitudes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildErrorState(cs, e.toString()),
              data: (solicitudes) {
                if (solicitudes.isEmpty) return _buildEmptyState(cs);

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 16),
                  itemCount: solicitudes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final sol = solicitudes[index];
                    return _SolicitudCard(
                      solicitud: sol,
                      isMobile: isMobile,
                      isApproving: _approvingId == sol.idSolicitud,
                      isRejecting: _rejectingId == sol.idSolicitud,
                      onAprobar: null,
                      onRechazar: null,
                      onCotizar:
                          sol.estado.toUpperCase() == 'APROBADA'
                              ? () => _abrirCotizacion(sol)
                              : null,
                      onComparativa:
                          sol.estado.toUpperCase() == 'APROBADA'
                              ? () => _abrirComparativa(sol)
                              : null,
                      onTransaccion:
                          sol.estado.toUpperCase() == 'APROBADA'
                              ? () => _abrirTransaccion(sol)
                              : null,
                      onDetalle: () => abrirDetalleSolicitud(context, ref, sol, asientosReadOnly: true),
                      onVerTransacciones:
                          () => abrirDetalleSolicitud(
                            context,
                            ref,
                            sol,
                            initialTab: 2,
                            asientosReadOnly: true,
                          ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
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

  Widget _buildErrorState(ColorScheme cs, String error) {
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
              onPressed:
                  () => ref.invalidate(solicitudesRegistradasProvider(_param)),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
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
// Solicitud card — flat design con acciones claras
// ═══════════════════════════════════════════════════════════════════════════════
class _SolicitudCard extends StatefulWidget {
  final SolicitudPagoEntity solicitud;
  final bool isMobile;
  final bool isApproving;
  final bool isRejecting;
  final VoidCallback? onAprobar;
  final VoidCallback? onRechazar;
  final VoidCallback? onCotizar;
  final VoidCallback? onComparativa;
  final VoidCallback? onTransaccion;
  final VoidCallback? onDetalle;
  final VoidCallback? onVerTransacciones;

  const _SolicitudCard({
    required this.solicitud,
    required this.isMobile,
    this.isApproving = false,
    this.isRejecting = false,
    this.onAprobar,
    this.onRechazar,
    this.onCotizar,
    this.onComparativa,
    this.onTransaccion,
    this.onDetalle,
    this.onVerTransacciones,
  });

  @override
  State<_SolicitudCard> createState() => _SolicitudCardState();
}

class _SolicitudCardState extends State<_SolicitudCard> {
  bool _expanded = false;

  SolicitudPagoEntity get sol => widget.solicitud;

  Color _estadoColor() {
    switch (sol.estado.toUpperCase()) {
      case 'APROBADA':
        return Colors.green;
      case 'PAGADA':
        return Colors.teal;
      case 'CANCELADA':
      case 'RECHAZADA':
      case 'RECHAZADO':
        return Colors.red;
      case 'PENDIENTE':
      default:
        return Colors.orange;
    }
  }

  IconData _estadoIcon() {
    switch (sol.estado.toUpperCase()) {
      case 'APROBADA':
        return Icons.check_circle_rounded;
      case 'PAGADA':
        return Icons.verified_rounded;
      case 'RECHAZADA':
      case 'RECHAZADO':
      case 'CANCELADA':
        return Icons.cancel_rounded;
      case 'PENDIENTE':
      default:
        return Icons.schedule_rounded;
    }
  }

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
          // ── Header ───────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: estadoColor, width: 4)),
              ),
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              child: Row(
                children: [
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$ ${_nf.format(sol.montoTotalSolicitud)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
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

          // ── Contenido expandible ────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(cs),
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

  Widget _buildExpandedContent(ColorScheme cs) {
    return Column(
      children: [
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
        // Proveedores
        if (sol.proveedores.isNotEmpty)
          ...sol.proveedores.map(
            (prov) => _ProveedorSection(
              proveedor: prov,
              cs: cs,
              isMobile: widget.isMobile,
            ),
          ),
        // Acciones
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: widget.onDetalle,
                icon: const Icon(Icons.visibility_rounded, size: 16),
                label: const Text(
                  'Ver detalle',
                  style: TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              if (sol.estado.toUpperCase() == 'PENDIENTE' &&
                  widget.onAprobar != null)
                widget.isApproving
                    ? const SizedBox(
                      height: 32,
                      width: 32,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                    : FilledButton.icon(
                      onPressed: widget.onAprobar,
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        'Aprobar',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
              if (sol.estado.toUpperCase() == 'PENDIENTE' &&
                  widget.onRechazar != null)
                widget.isRejecting
                    ? const SizedBox(
                      height: 32,
                      width: 32,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                    : FilledButton.tonalIcon(
                      onPressed: widget.onRechazar,
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text(
                        'Rechazar',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: FilledButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
              if (sol.estado.toUpperCase() == 'APROBADA') ...[
                OutlinedButton.icon(
                  onPressed: widget.onCotizar,
                  icon: const Icon(Icons.currency_exchange_rounded, size: 16),
                  label: const Text('Cotizar', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: widget.onComparativa,
                  icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                  label: const Text(
                    'Comparativa',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                FilledButton.icon(
                  onPressed: widget.onTransaccion,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text(
                    'Transacción',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.indigo.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
              if (sol.estado.toUpperCase() == 'PAGADA') ...[
                OutlinedButton.icon(
                  onPressed: widget.onVerTransacciones,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text(
                    'Ver transacciones',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                Chip(
                  avatar: Icon(
                    Icons.verified_rounded,
                    size: 14,
                    color: Colors.teal.shade700,
                  ),
                  label: Text(
                    'Pago completado',
                    style: TextStyle(fontSize: 11, color: Colors.teal.shade700),
                  ),
                  backgroundColor: Colors.teal.withValues(alpha: 0.08),
                  side: BorderSide(color: Colors.teal.withValues(alpha: 0.2)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Proveedor section — flat, no nested expansion tile
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
// Factura row inline
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
// Small label
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
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog / BottomSheet de transacción (Fase 4)
// ─────────────────────────────────────────────────────────────────────────────
class _DialogoTransaccion extends ConsumerStatefulWidget {
  final SolicitudPagoEntity solicitud;
  final CotizacionesEntity cotizacionAceptada;
  final VoidCallback onGuardado;
  final bool modoConfirmar;
  final String estadoTransaccion;

  const _DialogoTransaccion({
    required this.solicitud,
    required this.cotizacionAceptada,
    required this.onGuardado,
    this.modoConfirmar = false,
    this.estadoTransaccion = 'PENDIENTE',
  });

  @override
  ConsumerState<_DialogoTransaccion> createState() =>
      _DialogoTransaccionState();
}

class _DialogoTransaccionState extends ConsumerState<_DialogoTransaccion> {
  final _formKey = GlobalKey<FormState>();
  final _tcCtrl = TextEditingController();
  final _tcFwdCtrl = TextEditingController();
  final _contratoCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  // Fase 5
  final _confirmarFormKey = GlobalKey<FormState>();
  final _nroTransCtrl = TextEditingController();
  final _obsConfirmarCtrl = TextEditingController();
  bool _transaccionGuardada = false;
  DateTime? _fechaValorConfirmar;
  late String _estadoTransaccion;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _estadoTransaccion = widget.estadoTransaccion;
    if (widget.modoConfirmar) {
      _transaccionGuardada = true;
      _fechaValorConfirmar = DateTime.now();
    }
  }

  @override
  void dispose() {
    _tcCtrl.dispose();
    _tcFwdCtrl.dispose();
    _contratoCtrl.dispose();
    _obsCtrl.dispose();
    _nroTransCtrl.dispose();
    _obsConfirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final formState = ref.read(transaccionFormProvider);
    final montoConvertido = formState.montoConvertido;
    final totalFinal = montoConvertido + formState.totalCargos;

    // Confirmación antes de guardar
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: cs.primary),
              const SizedBox(width: 8),
              const Text('Confirmar Transacción'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Se registrará la transacción con los siguientes datos:',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              _confirmLine(
                'Monto Origen',
                '\$ ${_nf.format(formState.montoOrigen)}',
              ),
              _confirmLine(
                'TC Aplicado',
                formState.tipoCambioAplicado.toStringAsFixed(4),
              ),
              _confirmLine(
                'Monto Convertido',
                'Bs. ${_nf.format(montoConvertido)}',
              ),
              if (formState.totalCargos > 0)
                _confirmLine(
                  'Total Cargos',
                  'Bs. ${_nf.format(formState.totalCargos)}',
                ),
              const Divider(height: 16),
              _confirmLine(
                'Total Final',
                'Bs. ${_nf.format(totalFinal)}',
                bold: true,
              ),
              if (formState.tipoCambioReferencia > 0) ...[
                const Divider(height: 12),
                _confirmLine(
                  'TC Ref. BCB',
                  formState.tipoCambioReferencia.toStringAsFixed(4),
                ),
                _confirmLine(
                  'Equiv. USD Ref.',
                  'Bs. ${_nf.format(formState.equivalenteUsdRef)}',
                ),
                _confirmLine(
                  'Monto Real',
                  'Bs. ${_nf.format(formState.montoConvertido + formState.totalCargos)}',
                ),
                _confirmLine(
                  'Diferencia de más',
                  '${formState.diferenciaDeMas >= 0 ? "+" : ""}${_nf.format(formState.diferenciaDeMas)}',
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Text('% Sobrecosto', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (formState.porcentajeDiferencia / 100).clamp(
                              0.0,
                              1.0,
                            ),
                            minHeight: 8,
                            backgroundColor: cs.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(
                              formState.porcentajeDiferencia < 30
                                  ? Colors.green
                                  : formState.porcentajeDiferencia <= 50
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${formState.porcentajeDiferencia.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color:
                              formState.porcentajeDiferencia < 30
                                  ? Colors.green
                                  : formState.porcentajeDiferencia <= 50
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    final audUsuario = ref.read(userProvider)?.codUsuario ?? 0;
    final ok = await ref
        .read(transaccionFormProvider.notifier)
        .guardarTransaccion(audUsuario);
    if (!mounted) return;
    if (ok) {
      widget.onGuardado();
      // Fase 5: transición a confirmar pago dentro del mismo diálogo
      setState(() {
        _transaccionGuardada = true;
        _fechaValorConfirmar = ref.read(transaccionFormProvider).fechaValor;
      });
    }
  }

  Future<void> _confirmar() async {
    if (!(_confirmarFormKey.currentState?.validate() ?? false)) return;
    final formState = ref.read(transaccionFormProvider);
    final audUsuario = ref.read(userProvider)?.codUsuario ?? 0;
    final nroTransaccion = _nroTransCtrl.text.trim();
    final fechaValor = _fechaValorConfirmar ?? DateTime.now();
    final observaciones = _obsConfirmarCtrl.text.trim();

    // Confirmación final antes de enviar
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.verified_rounded, color: Colors.teal.shade600),
              const SizedBox(width: 8),
              const Expanded(child: Text('Confirmar Pago')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta acción marcará la solicitud como PAGADA y no se podrá deshacer.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _confirmLine('N° Transacción', nroTransaccion),
              _confirmLine('Fecha Valor', _df.format(fechaValor)),
              _confirmLine(
                'Monto',
                '${_nf.format(formState.montoOrigen)} → Bs. ${_nf.format(formState.montoConvertido)}',
              ),
              if (formState.totalCargos > 0)
                _confirmLine(
                  'Total Cargos',
                  'Bs. ${_nf.format(formState.totalCargos)}',
                ),
              const Divider(height: 16),
              _confirmLine(
                'Total Final',
                'Bs. ${_nf.format(formState.montoConvertido + formState.totalCargos)}',
                bold: true,
              ),
              if (formState.tipoCambioReferencia > 0) ...[
                const Divider(height: 12),
                _confirmLine(
                  'TC Ref. BCB',
                  formState.tipoCambioReferencia.toStringAsFixed(4),
                ),
                _confirmLine(
                  'Equiv. USD Ref.',
                  'Bs. ${_nf.format(formState.equivalenteUsdRef)}',
                ),
                _confirmLine(
                  'Diferencia de más',
                  '${formState.diferenciaDeMas >= 0 ? "+" : ""}${_nf.format(formState.diferenciaDeMas)}',
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Text('% Sobrecosto', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (formState.porcentajeDiferencia / 100).clamp(
                              0.0,
                              1.0,
                            ),
                            minHeight: 8,
                            backgroundColor: cs.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(
                              formState.porcentajeDiferencia < 30
                                  ? Colors.green
                                  : formState.porcentajeDiferencia <= 50
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${formState.porcentajeDiferencia.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color:
                              formState.porcentajeDiferencia < 30
                                  ? Colors.green
                                  : formState.porcentajeDiferencia <= 50
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
              ),
              child: const Text('Confirmar Pago'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    final ok = await ref
        .read(transaccionFormProvider.notifier)
        .confirmarPago(
          idTransaccion: BigInt.from(formState.idTransaccion),
          idSolicitud: formState.idSolicitud,
          numeroTransaccion: nroTransaccion,
          fechaValor: fechaValor,
          audUsuario: audUsuario,
          observaciones: observaciones.isNotEmpty ? observaciones : null,
          estadoActual: _estadoTransaccion,
        );
    if (!mounted) return;
    if (ok) {
      widget.onGuardado();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pago confirmado. Solicitud #${widget.solicitud.idSolicitud} cerrada como PAGADA.',
          ),
          backgroundColor: Colors.teal.shade700,
        ),
      );
    }
  }

  Widget _buildConfirmarContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final formState = ref.watch(transaccionFormProvider);
    final fechaValorActual = _fechaValorConfirmar ?? DateTime.now();
    final bancosAsync = ref.watch(bancosTPEXProvider);
    final monedasAsync = ref.watch(monedasProvider);

    // Resolver nombres para el resumen
    final nombreBanco =
        bancosAsync.valueOrNull
            ?.where((b) => b.codBanco == formState.codBanco)
            .firstOrNull
            ?.nombre ??
        'Banco #${formState.codBanco}';
    final monedaOrigen =
        monedasAsync.valueOrNull
            ?.where((m) => m.idMoneda == formState.idMonedaOrigen)
            .firstOrNull
            ?.codigo ??
        '?';
    final monedaDestino =
        monedasAsync.valueOrNull
            ?.where((m) => m.idMoneda == formState.idMonedaDestino)
            .firstOrNull
            ?.codigo ??
        '?';
    final totalFinal = formState.montoConvertido + formState.totalCargos;

    final content = Form(
      key: _confirmarFormKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado ────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.teal.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirmar Pago',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Transacción #${formState.idTransaccion}  ·  '
                        'Solicitud #${widget.solicitud.idSolicitud}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // ── Resumen de la transacción (solo lectura) ──────────────
            Text(
              'Datos de la Transacción',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _confirmLine('Banco', nombreBanco),
                  _confirmLine(
                    'Monto Origen',
                    '$monedaOrigen ${_nf.format(formState.montoOrigen)}',
                  ),
                  _confirmLine(
                    'TC Aplicado',
                    formState.tipoCambioAplicado.toStringAsFixed(4),
                  ),
                  _confirmLine(
                    'Monto Convertido',
                    '$monedaDestino ${_nf.format(formState.montoConvertido)}',
                  ),
                  if (formState.totalCargos > 0)
                    _confirmLine(
                      'Cargos',
                      '$monedaDestino ${_nf.format(formState.totalCargos)}',
                    ),
                  const Divider(height: 12),
                  _confirmLine(
                    'Total Final',
                    '$monedaDestino ${_nf.format(totalFinal)}',
                    bold: true,
                  ),
                  if (formState.tipoCambioReferencia > 0) ...[
                    const Divider(height: 12),
                    _confirmLine(
                      'TC Ref. BCB',
                      formState.tipoCambioReferencia.toStringAsFixed(4),
                    ),
                    _confirmLine(
                      'Equiv. USD Ref.',
                      '$monedaDestino ${_nf.format(formState.equivalenteUsdRef)}',
                    ),
                    _confirmLine(
                      'Monto Real',
                      '$monedaDestino ${_nf.format(totalFinal)}',
                    ),
                    _confirmLine(
                      'Diferencia de más',
                      '${formState.diferenciaDeMas >= 0 ? "+" : ""}${_nf.format(formState.diferenciaDeMas)}',
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text('% Sobrecosto', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (formState.porcentajeDiferencia / 100)
                                    .clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(
                                  formState.porcentajeDiferencia < 30
                                      ? Colors.green
                                      : formState.porcentajeDiferencia <= 50
                                      ? Colors.orange
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${formState.porcentajeDiferencia.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color:
                                  formState.porcentajeDiferencia < 30
                                      ? Colors.green
                                      : formState.porcentajeDiferencia <= 50
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  _confirmLine(
                    'Fecha Transacción',
                    _df.format(formState.fechaTransaccion),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Banner informativo ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ingrese el N° de transacción bancaria y la fecha valor para confirmar el pago.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── N° Transacción bancaria ──────────────────────────────
            _buildLabel('N° Transacción Bancaria *'),
            TextFormField(
              controller: _nroTransCtrl,
              decoration: _inputDeco('Ej: TRX-2026-00123', colorScheme),
              textCapitalization: TextCapitalization.characters,
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Ingrese el número de transacción'
                          : null,
            ),
            const SizedBox(height: 16),

            // ── Fecha Valor ────────────────────────────────────────────
            _buildLabel('Fecha Valor *'),
            _datePicker(
              context,
              date: fechaValorActual,
              colorScheme: colorScheme,
              onPicked: (d) => setState(() => _fechaValorConfirmar = d),
            ),
            const SizedBox(height: 16),

            // ── Observaciones (opcional) ──────────────────────────────
            _buildLabel('Observaciones (opcional)'),
            TextFormField(
              controller: _obsConfirmarCtrl,
              decoration: _inputDeco(
                'Notas adicionales sobre la confirmación',
                colorScheme,
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // ── Voucher ───────────────────────────────────────────────
            _buildLabel('Voucher (comprobante)'),
            const SizedBox(height: 4),
            VoucherButton(
              idTransaccion: BigInt.from(formState.idTransaccion),
              codEmpresa: formState.codEmpresa,
            ),

            // ── Error voucher ─────────────────────────────────────────
            if (formState.errorVoucher != null) ...[
              const SizedBox(height: 8),
              Text(
                formState.errorVoucher!,
                style: TextStyle(fontSize: 12, color: colorScheme.error),
              ),
            ],

            // ── Error ─────────────────────────────────────────────────
            if (formState.mensajeError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formState.mensajeError!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Éxito ─────────────────────────────────────────────────
            if (formState.mensajeExito != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formState.mensajeExito!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ── Botones ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      formState.cargando
                          ? null
                          : () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: formState.cargando ? null : _confirmar,
                  icon:
                      formState.cargando
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.verified_rounded, size: 18),
                  label: Text(
                    formState.cargando ? 'Confirmando…' : 'Confirmar Pago',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (isDesktop) {
      return Dialog(
        insetPadding: const EdgeInsets.all(32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
          child: content,
        ),
      );
    }
    return content;
  }

  Widget _datePicker(
    BuildContext context, {
    required DateTime date,
    required ColorScheme colorScheme,
    required ValueChanged<DateTime> onPicked,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: _inputDeco('Fecha', colorScheme),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_df.format(date)),
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirmLine(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  InputDecoration _inputDeco(String hint, ColorScheme cs) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      fontSize: 13,
      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
    ),
    filled: true,
    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.error, width: 1.5),
    ),
  );

  Widget _infoChip(String label, String value, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
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
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value,
    ColorScheme cs, {
    bool bold = false,
    bool small = false,
    Color? color,
  }) {
    final fontSize = small ? 11.0 : 13.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              color: cs.onSurfaceVariant,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fase 5: cuando la transacción ya fue guardada, mostrar confirmación
    if (_transaccionGuardada) return _buildConfirmarContent(context);

    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final formState = ref.watch(transaccionFormProvider);
    final canalesAsync = ref.watch(canalesPagoProvider);
    final tiposAsync = ref.watch(tiposTransaccionProvider);
    final monedasAsync = ref.watch(monedasProvider);
    final bancosAsync = ref.watch(bancosTPEXProvider);

    // Inicializar campos de texto con valores pre-cargados UNA sola vez
    if (!_initialized && formState.tipoCambioAplicado > 0) {
      _tcCtrl.text = formState.tipoCambioAplicado.toStringAsFixed(4);
      if (formState.observaciones.isNotEmpty) {
        _obsCtrl.text = formState.observaciones;
      }
      _initialized = true;
    }

    // Nombre del banco pre-cargado
    final nombreBanco =
        bancosAsync.valueOrNull
            ?.where((b) => b.codBanco == formState.codBanco)
            .firstOrNull
            ?.nombre ??
        'Banco #${formState.codBanco}';

    // Tipo transacción seleccionado → ¿requiere forward?
    final tiposLista = tiposAsync.valueOrNull ?? [];
    final tipoSel =
        tiposLista
            .where((t) => t.idTipoTransaccion == formState.idTipoTransaccion)
            .firstOrNull;
    final requiereForward = tipoSel?.requiereForward == 1;

    // TC referencia BCB
    final tcRef = formState.tipoCambioReferencia;

    // Nombres de moneda
    final monedasLista = monedasAsync.valueOrNull ?? [];
    final monedaOrigenNombre =
        monedasLista
            .where((m) => m.idMoneda == formState.idMonedaOrigen)
            .firstOrNull
            ?.codigo ??
        '';
    final monedaDestinoNombre =
        monedasLista
            .where((m) => m.idMoneda == formState.idMonedaDestino)
            .firstOrNull
            ?.codigo ??
        'BOB';

    final content = Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado ────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: const Icon(Icons.swap_horiz_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nueva Transacción',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Solicitud #${widget.solicitud.idSolicitud}  ·  '
                        'Cot. #${widget.cotizacionAceptada.idCotizacion}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // ── Datos pre-cargados (solo lectura) ─────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.2,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos de la Cotización Aceptada',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      _infoChip('Banco', nombreBanco, colorScheme),
                      _infoChip(
                        'Monto',
                        '${monedaOrigenNombre.isNotEmpty ? monedaOrigenNombre : "USD"} ${_nf.format(formState.montoOrigen)}',
                        colorScheme,
                      ),
                      _infoChip(
                        'TC Cotizado',
                        formState.tipoCambioAplicado.toStringAsFixed(4),
                        colorScheme,
                      ),
                      _infoChip(
                        'Moneda Destino',
                        monedaDestinoNombre,
                        colorScheme,
                      ),
                      if (tcRef > 0)
                        _infoChip(
                          'TC Ref. BCB',
                          tcRef.toStringAsFixed(4),
                          colorScheme,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Banco (fallback si no vino de la cotización) ──────────
            if (formState.codBanco <= 0) ...[
              _buildLabel('Banco *'),
              bancosAsync.when(
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (_, __) => const Text('Error al cargar bancos'),
                data:
                    (bancos) => DropdownButtonFormField<int>(
                      key: const ValueKey('txn_banco'),
                      decoration: _inputDeco('Seleccione banco', colorScheme),
                      value: null,
                      items:
                          bancos
                              .map(
                                (b) => DropdownMenuItem(
                                  value: b.codBanco,
                                  child: Text(
                                    b.nombre,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                      validator:
                          (v) => v == null ? 'Seleccione un banco' : null,
                      onChanged: (v) {
                        if (v != null) {
                          ref
                              .read(transaccionFormProvider.notifier)
                              .setCodBanco(v);
                          ref
                              .read(transaccionFormProvider.notifier)
                              .cargarTcReferencia(v);
                        }
                      },
                    ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Moneda Origen / Moneda Destino (siempre visibles y editables) ──
            monedasAsync.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (_, __) => const Text('Error al cargar monedas'),
              data: (monedas) {
                final mismaCurrency =
                    formState.idMonedaOrigen > 0 &&
                    formState.idMonedaDestino > 0 &&
                    formState.idMonedaOrigen == formState.idMonedaDestino;

                final origenDropdown = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Moneda Origen *'),
                    DropdownButtonFormField<int>(
                      key: const ValueKey('txn_moneda_origen'),
                      decoration: _inputDeco(
                        'Seleccione moneda origen',
                        colorScheme,
                      ),
                      value:
                          formState.idMonedaOrigen > 0
                              ? formState.idMonedaOrigen
                              : null,
                      items:
                          monedas
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m.idMoneda,
                                  child: Text(
                                    '${m.codigo} — ${m.nombre}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                      validator: (v) {
                        if (v == null) return 'Seleccione moneda origen';
                        if (v == formState.idMonedaDestino) {
                          return 'No puede ser igual a Destino';
                        }
                        return null;
                      },
                      onChanged: (v) {
                        if (v != null) {
                          ref
                              .read(transaccionFormProvider.notifier)
                              .setIdMonedaOrigen(v);
                        }
                      },
                    ),
                  ],
                );

                final destinoDropdown = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Moneda Destino *'),
                    DropdownButtonFormField<int>(
                      key: const ValueKey('txn_moneda_destino'),
                      decoration: _inputDeco(
                        'Seleccione moneda destino',
                        colorScheme,
                      ),
                      value:
                          formState.idMonedaDestino > 0
                              ? formState.idMonedaDestino
                              : null,
                      items:
                          monedas
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m.idMoneda,
                                  child: Text(
                                    '${m.codigo} — ${m.nombre}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                      validator: (v) {
                        if (v == null) return 'Seleccione moneda destino';
                        if (v == formState.idMonedaOrigen) {
                          return 'No puede ser igual a Origen';
                        }
                        return null;
                      },
                      onChanged: (v) {
                        if (v != null) {
                          ref
                              .read(transaccionFormProvider.notifier)
                              .setIdMonedaDestino(v);
                        }
                      },
                    ),
                  ],
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (mismaCurrency) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withValues(
                            alpha: 0.85,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'La moneda origen y destino no pueden ser iguales. '
                                'El flujo normal es USD (origen) → BOB (destino).',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (isMobile)
                      Column(
                        children: [
                          origenDropdown,
                          const SizedBox(height: 12),
                          destinoDropdown,
                        ],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: origenDropdown),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 24, 8, 0),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color:
                                  mismaCurrency
                                      ? colorScheme.error
                                      : colorScheme.primary,
                            ),
                          ),
                          Expanded(child: destinoDropdown),
                        ],
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Tipo transacción + Canal (campos requeridos) ──────────
            isMobile
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Tipo de Transacción *'),
                    tiposAsync.when(
                      loading:
                          () => const LinearProgressIndicator(minHeight: 2),
                      error: (_, __) => const Text('Error al cargar tipos'),
                      data:
                          (tipos) => DropdownButtonFormField<BigInt>(
                            decoration: _inputDeco(
                              'Seleccione tipo',
                              colorScheme,
                            ),
                            value:
                                formState.idTipoTransaccion != BigInt.zero
                                    ? formState.idTipoTransaccion
                                    : null,
                            items:
                                tipos
                                    .where((t) => t.activo == 1)
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t.idTipoTransaccion,
                                        child: Text(
                                          t.nombre,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                            validator:
                                (v) =>
                                    v == null
                                        ? 'Seleccione un tipo de transacción'
                                        : null,
                            onChanged: (v) {
                              if (v == null) return;
                              ref
                                  .read(transaccionFormProvider.notifier)
                                  .setIdTipoTransaccion(v);
                            },
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Canal de Pago *'),
                    canalesAsync.when(
                      loading:
                          () => const LinearProgressIndicator(minHeight: 2),
                      error: (_, __) => const Text('Error al cargar canales'),
                      data:
                          (canales) => DropdownButtonFormField<int>(
                            decoration: _inputDeco(
                              'Seleccione canal',
                              colorScheme,
                            ),
                            value:
                                formState.idCanal > 0
                                    ? formState.idCanal
                                    : null,
                            items:
                                canales
                                    .where((c) => c.activo == 1)
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c.idCanal,
                                        child: Text(
                                          c.nombre,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                            validator:
                                (v) => v == null ? 'Seleccione un canal' : null,
                            onChanged: (v) {
                              if (v != null) {
                                ref
                                    .read(transaccionFormProvider.notifier)
                                    .setIdCanal(v);
                              }
                            },
                          ),
                    ),
                  ],
                )
                : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Tipo de Transacción *'),
                          tiposAsync.when(
                            loading:
                                () =>
                                    const LinearProgressIndicator(minHeight: 2),
                            error:
                                (_, __) => const Text('Error al cargar tipos'),
                            data:
                                (tipos) => DropdownButtonFormField<BigInt>(
                                  decoration: _inputDeco(
                                    'Seleccione tipo',
                                    colorScheme,
                                  ),
                                  value:
                                      formState.idTipoTransaccion != BigInt.zero
                                          ? formState.idTipoTransaccion
                                          : null,
                                  items:
                                      tipos
                                          .where((t) => t.activo == 1)
                                          .map(
                                            (t) => DropdownMenuItem(
                                              value: t.idTipoTransaccion,
                                              child: Text(
                                                t.nombre,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  validator:
                                      (v) =>
                                          v == null
                                              ? 'Seleccione un tipo'
                                              : null,
                                  onChanged: (v) {
                                    if (v == null) return;
                                    ref
                                        .read(transaccionFormProvider.notifier)
                                        .setIdTipoTransaccion(v);
                                  },
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Canal de Pago *'),
                          canalesAsync.when(
                            loading:
                                () =>
                                    const LinearProgressIndicator(minHeight: 2),
                            error:
                                (_, __) =>
                                    const Text('Error al cargar canales'),
                            data:
                                (canales) => DropdownButtonFormField<int>(
                                  decoration: _inputDeco(
                                    'Seleccione canal',
                                    colorScheme,
                                  ),
                                  value:
                                      formState.idCanal > 0
                                          ? formState.idCanal
                                          : null,
                                  items:
                                      canales
                                          .where((c) => c.activo == 1)
                                          .map(
                                            (c) => DropdownMenuItem(
                                              value: c.idCanal,
                                              child: Text(
                                                c.nombre,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  validator:
                                      (v) =>
                                          v == null
                                              ? 'Seleccione un canal'
                                              : null,
                                  onChanged: (v) {
                                    if (v != null) {
                                      ref
                                          .read(
                                            transaccionFormProvider.notifier,
                                          )
                                          .setIdCanal(v);
                                    }
                                  },
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            const SizedBox(height: 16),
            // ── TC Aplicado (editable) ─────────────────────────────
            _buildLabel(
              'TC Aplicado *'
              '${formState.cargandoTcRef
                  ? "  (cargando ref…)"
                  : tcRef > 0
                  ? "  (ref BCB: ${tcRef.toStringAsFixed(4)})"
                  : ""}',
            ),
            TextFormField(
              controller: _tcCtrl,
              decoration: _inputDeco('Ej: 6.9700', colorScheme),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}')),
              ],
              validator: (v) {
                final d = double.tryParse(v ?? '');
                if (d == null || d <= 0) {
                  return 'Ingrese un TC válido';
                }
                return null;
              },
              onChanged: (v) {
                final d = double.tryParse(v) ?? 0.0;
                ref
                    .read(transaccionFormProvider.notifier)
                    .setTipoCambioAplicado(d);
              },
            ),
            const SizedBox(height: 16),

            // ── Sección Forward (condicional) ─────────────────────────
            if (requiereForward) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.tertiary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Datos Forward',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.tertiary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    isMobile
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Número de Contrato'),
                            TextFormField(
                              controller: _contratoCtrl,
                              decoration: _inputDeco(
                                'Ej: FWD-2026-001',
                                colorScheme,
                              ),
                              onChanged:
                                  (v) => ref
                                      .read(transaccionFormProvider.notifier)
                                      .setNumeroContrato(v),
                            ),
                            const SizedBox(height: 12),
                            _buildLabel('TC Forward'),
                            TextFormField(
                              controller: _tcFwdCtrl,
                              decoration: _inputDeco('Ej: 7.0500', colorScheme),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,4}'),
                                ),
                              ],
                              onChanged: (v) {
                                final d = double.tryParse(v) ?? 0.0;
                                ref
                                    .read(transaccionFormProvider.notifier)
                                    .setTipoCambioForward(d);
                              },
                            ),
                          ],
                        )
                        : Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Número de Contrato'),
                                  TextFormField(
                                    controller: _contratoCtrl,
                                    decoration: _inputDeco(
                                      'Ej: FWD-2026-001',
                                      colorScheme,
                                    ),
                                    onChanged:
                                        (v) => ref
                                            .read(
                                              transaccionFormProvider.notifier,
                                            )
                                            .setNumeroContrato(v),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('TC Forward'),
                                  TextFormField(
                                    controller: _tcFwdCtrl,
                                    decoration: _inputDeco(
                                      'Ej: 7.0500',
                                      colorScheme,
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,4}'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      final d = double.tryParse(v) ?? 0.0;
                                      ref
                                          .read(
                                            transaccionFormProvider.notifier,
                                          )
                                          .setTipoCambioForward(d);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    const SizedBox(height: 12),
                    isMobile
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Fecha Pactado'),
                            _datePicker(
                              context,
                              date: formState.fechaPactado ?? DateTime.now(),
                              colorScheme: colorScheme,
                              onPicked:
                                  (d) => ref
                                      .read(transaccionFormProvider.notifier)
                                      .setFechaPactado(d),
                            ),
                            const SizedBox(height: 12),
                            _buildLabel('Fecha Vencimiento'),
                            _datePicker(
                              context,
                              date:
                                  formState.fechaVencimiento ??
                                  DateTime.now().add(const Duration(days: 90)),
                              colorScheme: colorScheme,
                              onPicked:
                                  (d) => ref
                                      .read(transaccionFormProvider.notifier)
                                      .setFechaVencimiento(d),
                            ),
                          ],
                        )
                        : Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Fecha Pactado'),
                                  _datePicker(
                                    context,
                                    date:
                                        formState.fechaPactado ??
                                        DateTime.now(),
                                    colorScheme: colorScheme,
                                    onPicked:
                                        (d) => ref
                                            .read(
                                              transaccionFormProvider.notifier,
                                            )
                                            .setFechaPactado(d),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Fecha Vencimiento'),
                                  _datePicker(
                                    context,
                                    date:
                                        formState.fechaVencimiento ??
                                        DateTime.now().add(
                                          const Duration(days: 90),
                                        ),
                                    colorScheme: colorScheme,
                                    onPicked:
                                        (d) => ref
                                            .read(
                                              transaccionFormProvider.notifier,
                                            )
                                            .setFechaVencimiento(d),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Observaciones ─────────────────────────────────────────
            _buildLabel('Observaciones'),
            TextFormField(
              controller: _obsCtrl,
              decoration: _inputDeco('Notas adicionales', colorScheme),
              maxLines: 2,
              onChanged:
                  (v) => ref
                      .read(transaccionFormProvider.notifier)
                      .setObservaciones(v),
            ),

            // ── Resumen detallado ─────────────────────────────────────
            if (formState.montoOrigen > 0 &&
                formState.tipoCambioAplicado > 0) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen de la Transacción',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _summaryRow(
                      'Monto Origen',
                      '${monedaOrigenNombre.isNotEmpty ? monedaOrigenNombre : "USD"} ${_nf.format(formState.montoOrigen)}',
                      colorScheme,
                    ),
                    _summaryRow(
                      'TC Aplicado',
                      formState.tipoCambioAplicado.toStringAsFixed(4),
                      colorScheme,
                    ),
                    _summaryRow(
                      'Monto Convertido',
                      '$monedaDestinoNombre ${_nf.format(formState.montoConvertido)}',
                      colorScheme,
                    ),
                    if (formState.totalCargos > 0)
                      _summaryRow(
                        'Total Cargos',
                        '$monedaDestinoNombre ${_nf.format(formState.totalCargos)}',
                        colorScheme,
                      ),
                    const Divider(height: 16),
                    _summaryRow(
                      'Total Final',
                      '$monedaDestinoNombre ${_nf.format(formState.montoConvertido + formState.totalCargos)}',
                      colorScheme,
                      bold: true,
                      color: colorScheme.primary,
                    ),
                    if (tcRef > 0) ...[
                      const SizedBox(height: 8),
                      _summaryRow(
                        'TC Ref. BCB',
                        tcRef.toStringAsFixed(4),
                        colorScheme,
                        small: true,
                      ),
                      _summaryRow(
                        'Equiv. USD Ref. (BCB)',
                        '$monedaDestinoNombre ${_nf.format(formState.equivalenteUsdRef)}',
                        colorScheme,
                        small: true,
                      ),
                      _summaryRow(
                        'Monto Real',
                        '$monedaDestinoNombre ${_nf.format(formState.montoConvertido + formState.totalCargos)}',
                        colorScheme,
                        small: true,
                      ),
                      _summaryRow(
                        'Diferencia de más',
                        '$monedaDestinoNombre ${_nf.format(formState.diferenciaDeMas)}',
                        colorScheme,
                        small: true,
                        color:
                            formState.diferenciaDeMas > 0
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Text(
                              '% Sobrecosto',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (formState.porcentajeDiferencia / 100)
                                      .clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation(
                                    formState.porcentajeDiferencia < 30
                                        ? Colors.green
                                        : formState.porcentajeDiferencia <= 50
                                        ? Colors.orange
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${formState.porcentajeDiferencia.toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color:
                                    formState.porcentajeDiferencia < 30
                                        ? Colors.green
                                        : formState.porcentajeDiferencia <= 50
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // ── Error ─────────────────────────────────────────────────
            if (formState.mensajeError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formState.mensajeError!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Botones ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      formState.cargando
                          ? null
                          : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: formState.cargando ? null : _guardar,
                  icon:
                      formState.cargando
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    formState.cargando ? 'Guardando…' : 'Guardar transacción',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (isDesktop) {
      return Dialog(
        insetPadding: const EdgeInsets.all(32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 820),
          child: content,
        ),
      );
    }
    return content;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog / BottomSheet comparativa de cotizaciones (Fase 3)
// ─────────────────────────────────────────────────────────────────────────────
class _DialogoComparativa extends ConsumerStatefulWidget {
  final SolicitudPagoEntity solicitud;
  final VoidCallback onAceptada;

  const _DialogoComparativa({
    required this.solicitud,
    required this.onAceptada,
  });

  @override
  ConsumerState<_DialogoComparativa> createState() =>
      _DialogoComparativaState();
}

class _DialogoComparativaState extends ConsumerState<_DialogoComparativa> {
  BigInt? _acceptingId;

  Future<void> _aceptar(CotizacionesEntity cotizacion) async {
    final audUsuario = ref.read(userProvider)?.codUsuario ?? 0;
    setState(() => _acceptingId = cotizacion.idCotizacion);
    try {
      final ok = await ref
          .read(cotizacionFormProvider.notifier)
          .aceptarCotizacion(cotizacion: cotizacion, audUsuario: audUsuario);
      if (!mounted) return;
      if (ok) {
        widget.onAceptada();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cotización #${cotizacion.idCotizacion} aceptada exitosamente.',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        final error =
            ref.read(cotizacionFormProvider).mensajeError ??
            'Error al aceptar la cotización.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _acceptingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final cotizacionesAsync = ref.watch(
      cotizacionesXSolicitudProvider(widget.solicitud.idSolicitud),
    );
    final bancosAsync = ref.watch(bancosTPEXProvider);

    Widget buildContent(List<CotizacionesEntity> cotizaciones) {
      // ¿Ya tiene una cotización ACEPTADA?
      final yaAceptada = cotizaciones.any(
        (c) => c.estado.toUpperCase() == 'ACEPTADA',
      );

      final header = Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(
          children: [
            Icon(
              Icons.compare_arrows_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comparativa de Cotizaciones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Solicitud #${widget.solicitud.idSolicitud}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Cerrar',
            ),
          ],
        ),
      );

      if (cotizaciones.isEmpty) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            header,
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: 56,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay cotizaciones registradas',
                    style: TextStyle(
                      fontSize: 15,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Use el botón "Cotizar" para agregar cotizaciones.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      final bancos = bancosAsync.valueOrNull ?? [];
      String nombreBanco(int codBanco) {
        final b = bancos.where((b) => b.codBanco == codBanco).firstOrNull;
        return b?.nombre ?? 'Banco #$codBanco';
      }

      final items = <Widget>[];
      for (int i = 0; i < cotizaciones.length; i++) {
        final c = cotizaciones[i];
        final esGanadora = c.esGanadora == 1;
        final estaAceptada = c.estado.toUpperCase() == 'ACEPTADA';
        final isBest = i == 0 && !yaAceptada; // primer item = menor costo
        final estadoColor =
            estaAceptada
                ? Colors.green
                : c.estado.toUpperCase() == 'RECHAZADA'
                ? Colors.red
                : Colors.orange;

        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color:
                      esGanadora || estaAceptada
                          ? Colors.green.withValues(alpha: 0.6)
                          : isBest
                          ? colorScheme.primary.withValues(alpha: 0.5)
                          : colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: esGanadora || estaAceptada || isBest ? 1.5 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Fila superior: banco + posición + estado ──
                    Row(
                      children: [
                        if (isBest && !yaAceptada)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 13,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Mejor oferta',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (esGanadora || estaAceptada)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 13,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 3),
                                const Text(
                                  'Ganadora',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: Text(
                            nombreBanco(c.codBanco),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: estadoColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            c.estado,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: estadoColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // ── Datos numéricos ──
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _ComparativaDataChip(
                          label: 'Fecha',
                          value: _df.format(c.fechaCotizacion),
                          colorScheme: colorScheme,
                        ),
                        _ComparativaDataChip(
                          label: 'Monto compra',
                          value: '\$ ${_nf.format(c.montoCompra)}',
                          colorScheme: colorScheme,
                        ),
                        _ComparativaDataChip(
                          label: 'T.C. ofrecido',
                          value: c.tipoCambioOfrecido.toStringAsFixed(4),
                          colorScheme: colorScheme,
                        ),
                        _ComparativaDataChip(
                          label: 'Total Bs.',
                          value: 'Bs. ${_nf.format(c.totalBolivianos)}',
                          colorScheme: colorScheme,
                          highlight: true,
                        ),
                      ],
                    ),
                    if (c.observaciones.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        c.observaciones,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    // ── Cargos ──
                    if (c.cargos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Divider(height: 12),
                      ...c.cargos.map(
                        (cargo) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  cargo.descripcion,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Text(
                                'Bs. ${_nf.format(cargo.montoCargo)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    // ── Botón Aceptar ──
                    if (!yaAceptada) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child:
                            _acceptingId == c.idCotizacion
                                ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : FilledButton.icon(
                                  onPressed:
                                      _acceptingId != null
                                          ? null
                                          : () => _aceptar(c),
                                  icon: const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Aceptar esta cotización'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                  ),
                                ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const Divider(height: 1),
          if (yaAceptada)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ya existe una cotización aceptada. No se puede aceptar otra.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Flexible(
            child: SingleChildScrollView(child: Column(children: items)),
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    final body = cotizacionesAsync.when(
      loading:
          () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, _) => Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Error al cargar cotizaciones',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed:
                      () => ref.invalidate(
                        cotizacionesXSolicitudProvider(
                          widget.solicitud.idSolicitud,
                        ),
                      ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
      data: buildContent,
    );

    if (isDesktop) {
      return Dialog(
        insetPadding: const EdgeInsets.all(32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650, maxHeight: 700),
          child: body,
        ),
      );
    }
    return body;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip de dato en la tarjeta comparativa
// ─────────────────────────────────────────────────────────────────────────────
class _ComparativaDataChip extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final bool highlight;

  const _ComparativaDataChip({
    required this.label,
    required this.value,
    required this.colorScheme,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:
            highlight
                ? colorScheme.primaryContainer.withValues(alpha: 0.6)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border:
            highlight
                ? Border.all(color: colorScheme.primary.withValues(alpha: 0.4))
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color:
                  highlight
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog / BottomSheet de cotización (Fase 2)
// ─────────────────────────────────────────────────────────────────────────────
class _DialogoCotizacion extends ConsumerStatefulWidget {
  final SolicitudPagoEntity solicitud;
  final VoidCallback onGuardado;

  const _DialogoCotizacion({required this.solicitud, required this.onGuardado});

  @override
  ConsumerState<_DialogoCotizacion> createState() => _DialogoCotizacionState();
}

class _DialogoCotizacionState extends ConsumerState<_DialogoCotizacion> {
  final _formKey = GlobalKey<FormState>();
  final _tcCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _nroGirosCtrl = TextEditingController(text: '1');
  final _obsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-populate monto from solicitud total
    final total = widget.solicitud.montoTotalSolicitud;
    if (total > 0) {
      _montoCtrl.text = total.toStringAsFixed(2);
      // Defer to avoid modifying provider during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(cotizacionFormProvider.notifier).setMontoCompra(total);
      });
    }
  }

  @override
  void dispose() {
    _tcCtrl.dispose();
    _montoCtrl.dispose();
    _nroGirosCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final audUsuario = ref.read(userProvider)?.codUsuario ?? 0;
    final ok = await ref
        .read(cotizacionFormProvider.notifier)
        .guardarCotizacion(audUsuario);
    if (!mounted) return;
    if (ok) {
      widget.onGuardado();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cotización registrada para solicitud #${widget.solicitud.idSolicitud}.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final formState = ref.watch(cotizacionFormProvider);
    final bancosAsync = ref.watch(bancosTPEXProvider);
    final monedasAsync = ref.watch(monedasProvider);

    // Sincronizar campos de texto con el estado solo cuando el usuario no está editando
    if (_tcCtrl.text.isEmpty && formState.tipoCambioOfrecido > 0) {
      _tcCtrl.text = formState.tipoCambioOfrecido.toStringAsFixed(4);
    }

    final content = Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado ──────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: const Icon(Icons.currency_exchange_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nueva Cotización',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Solicitud #${widget.solicitud.idSolicitud} — '
                        '\$ ${_nf.format(widget.solicitud.montoTotalSolicitud)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // ── Formulario en grid responsivo ───────────────────────────
            _buildGrid(
              isMobile: isMobile,
              children: [
                // Banco
                _buildLabel('Banco *'),
                bancosAsync.when(
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (_, __) => const Text('Error al cargar bancos'),
                  data: (bancos) {
                    return DropdownButtonFormField<int>(
                      decoration: _inputDeco('Seleccione banco', colorScheme),
                      value: formState.codBanco > 0 ? formState.codBanco : null,
                      items:
                          bancos
                              .map(
                                (b) => DropdownMenuItem(
                                  value: b.codBanco,
                                  child: Text(
                                    b.nombre,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                      validator:
                          (v) => v == null ? 'Seleccione un banco' : null,
                      onChanged: (v) {
                        if (v == null) return;
                        ref
                            .read(cotizacionFormProvider.notifier)
                            .setCodBanco(v);
                        ref
                            .read(cotizacionFormProvider.notifier)
                            .cargarTcVigente(v);
                      },
                    );
                  },
                ),

                // Fecha cotización
                _buildLabel('Fecha *'),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: formState.fechaCotizacion,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      ref
                          .read(cotizacionFormProvider.notifier)
                          .setFechaCotizacion(picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: _inputDeco('Fecha', colorScheme),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_df.format(formState.fechaCotizacion)),
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                // Moneda
                _buildLabel('Moneda *'),
                monedasAsync.when(
                  loading:
                      () => InputDecorator(
                        decoration: _inputDeco(
                          'Cargando monedas…',
                          colorScheme,
                        ),
                        child: const SizedBox(
                          height: 18,
                          child: LinearProgressIndicator(),
                        ),
                      ),
                  error:
                      (e, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Error al cargar monedas: $e',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.error,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => ref.invalidate(monedasProvider),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Reintentar'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                  data: (monedas) {
                    if (monedas.isEmpty) {
                      return InputDecorator(
                        decoration: _inputDeco(
                          'Sin monedas disponibles',
                          colorScheme,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'No hay monedas registradas',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return DropdownButtonFormField<int>(
                      decoration: _inputDeco('Seleccione moneda', colorScheme),
                      value: formState.idMoneda > 0 ? formState.idMoneda : null,
                      items:
                          monedas
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m.idMoneda,
                                  child: Text(
                                    '${m.codigo} — ${m.nombre}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                      validator:
                          (v) => v == null ? 'Seleccione una moneda' : null,
                      onChanged:
                          (v) =>
                              v != null
                                  ? ref
                                      .read(cotizacionFormProvider.notifier)
                                      .setIdMoneda(v)
                                  : null,
                    );
                  },
                ),

                // Monto compra
                _buildLabel('Monto a comprar (USD) *'),
                TextFormField(
                  controller: _montoCtrl,
                  decoration: _inputDeco('Ej: 10000.00', colorScheme),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  validator: (v) {
                    final d = double.tryParse(v ?? '');
                    if (d == null || d <= 0) {
                      return 'Ingrese un monto válido mayor a 0';
                    }
                    return null;
                  },
                  onChanged: (v) {
                    final d = double.tryParse(v) ?? 0.0;
                    ref.read(cotizacionFormProvider.notifier).setMontoCompra(d);
                  },
                ),

                // Tipo de cambio ofrecido
                _buildLabel(
                  formState.cargandoTc
                      ? 'T.C. ofrecido (cargando…) *'
                      : 'T.C. ofrecido *'
                          '${formState.tcVigenteReferencia > 0 ? "  (ref: ${formState.tcVigenteReferencia.toStringAsFixed(4)})" : ""}',
                ),
                TextFormField(
                  controller: _tcCtrl,
                  decoration: _inputDeco('Ej: 6.9700', colorScheme),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,4}'),
                    ),
                  ],
                  validator: (v) {
                    final d = double.tryParse(v ?? '');
                    if (d == null || d <= 0) {
                      return 'Ingrese un tipo de cambio válido';
                    }
                    return null;
                  },
                  onChanged: (v) {
                    final d = double.tryParse(v) ?? 0.0;
                    ref
                        .read(cotizacionFormProvider.notifier)
                        .setTipoCambioOfrecido(d);
                  },
                ),

                // Nro. Giros
                _buildLabel('Nro. Giros *'),
                TextFormField(
                  controller: _nroGirosCtrl,
                  decoration: _inputDeco('Ej: 1', colorScheme),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) {
                      return 'Ingrese al menos 1 giro';
                    }
                    return null;
                  },
                  onChanged: (v) {
                    final n = int.tryParse(v) ?? 1;
                    ref.read(cotizacionFormProvider.notifier).setNroGiros(n);
                  },
                ),

                // Observaciones (ocupa todo el ancho)
              ],
            ),

            const SizedBox(height: 12),
            _buildLabel('Observaciones'),
            TextFormField(
              controller: _obsCtrl,
              decoration: _inputDeco(
                'Notas adicionales (opcional)',
                colorScheme,
              ),
              maxLines: 2,
              onChanged:
                  (v) => ref
                      .read(cotizacionFormProvider.notifier)
                      .setObservaciones(v),
            ),

            // ── Resumen calculado ────────────────────────────────────────
            if (formState.montoCompra > 0 &&
                formState.tipoCambioOfrecido > 0) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Monto convertido (Bs.)',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Bs. ${_nf.format(formState.montoConvertido)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (formState.totalCargos > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cargos',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '+ Bs. ${_nf.format(formState.totalCargos)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total estimado (Bs.)',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Bs. ${_nf.format(formState.totalBolivianos)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // ── Mensaje de error ─────────────────────────────────────────
            if (formState.mensajeError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formState.mensajeError!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Botones ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      formState.cargando
                          ? null
                          : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: formState.cargando ? null : _guardar,
                  icon:
                      formState.cargando
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    formState.cargando ? 'Guardando…' : 'Guardar cotización',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // En desktop envolver en Dialog, en mobile ya viene dentro del BottomSheet
    if (isDesktop) {
      return Dialog(
        insetPadding: const EdgeInsets.all(32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: content,
        ),
      );
    }
    return content;
  }

  /// Grid de 2 columnas en tablet/desktop, 1 columna en mobile.
  Widget _buildGrid({required bool isMobile, required List<Widget> children}) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    }
    // 2 columnas: label + field, label + field, …
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += 2) {
      final label = children[i];
      final field =
          i + 1 < children.length ? children[i + 1] : const SizedBox();
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [label, const SizedBox(height: 6), field],
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Realmente: pares label+field → 1 columna a full ancho, pero en grid de 2 campos por fila
    // Reconstruir: cada par es un campo, 2 campos por fila
    final fields = <Widget>[];
    for (int i = 0; i < children.length; i += 2) {
      fields.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [children[i], const SizedBox(height: 6), children[i + 1]],
        ),
      );
    }
    final gridRows = <Widget>[];
    for (int i = 0; i < fields.length; i += 2) {
      gridRows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: fields[i]),
              const SizedBox(width: 16),
              if (i + 1 < fields.length)
                Expanded(child: fields[i + 1])
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: gridRows);
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  InputDecoration _inputDeco(String hint, ColorScheme cs) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      fontSize: 13,
      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
    ),
    filled: true,
    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.error, width: 1.5),
    ),
  );
}
