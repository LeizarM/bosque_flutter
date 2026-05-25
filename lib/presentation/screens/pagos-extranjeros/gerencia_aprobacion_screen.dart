import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/data/repositories/pagos_extranjeros_impl.dart';
import 'package:bosque_flutter/domain/entities/solicitud_pago_entity.dart';
import 'package:bosque_flutter/presentation/screens/pagos-extranjeros/solicitud_detail_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final _nf = NumberFormat('#,##0.00', 'es_BO');
final _df = DateFormat('dd/MM/yyyy');

// ── Provider local ──────────────────────────────────────────────────────────

/// Refresca las solicitudes PENDIENTES manualmente (invalidar tras cambio).
final _pendientesRefreshProvider = StateProvider<int>((ref) => 0);

final _solicitudesPendientesProvider =
    FutureProvider.autoDispose<List<SolicitudPagoEntity>>((ref) async {
  ref.watch(_pendientesRefreshProvider); // dependencia para forzar refresh
  final repo = PagosExtranjerosImpl();
  final ahora = DateTime.now();
  // Últimos 3 meses para cubrir solicitudes recientes
  final inicio = DateTime(ahora.year, ahora.month - 3, 1);
  final todas = await repo.getSolicitudesRegistradas(inicio, ahora, 0);
  return todas
      .where((s) => s.estado.toUpperCase() == 'PENDIENTE')
      .toList()
    ..sort((a, b) => b.fechaSolicitud.compareTo(a.fechaSolicitud));
});

// ═══════════════════════════════════════════════════════════════════════════
// Screen principal
// ═══════════════════════════════════════════════════════════════════════════

class GerenciaAprobacionScreen extends ConsumerStatefulWidget {
  const GerenciaAprobacionScreen({super.key});

  @override
  ConsumerState<GerenciaAprobacionScreen> createState() =>
      _GerenciaAprobacionScreenState();
}

class _GerenciaAprobacionScreenState
    extends ConsumerState<GerenciaAprobacionScreen> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final asyncSolicitudes = ref.watch(_solicitudesPendientesProvider);
    return _buildLista(cs, asyncSolicitudes);
  }

  Widget _buildLista(
    ColorScheme cs,
    AsyncValue<List<SolicitudPagoEntity>> asyncSolicitudes,
  ) {
    return Column(
      children: [
        // AppBar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
          color: cs.surface,
          child: Row(
            children: [
              Icon(Icons.approval_rounded, color: cs.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aprobación de Solicitudes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Actualizar',
                onPressed: () => ref
                    .read(_pendientesRefreshProvider.notifier)
                    .state++,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Cuerpo
        Expanded(
          child: asyncSolicitudes.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error: $e',
                  style: TextStyle(color: cs.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (solicitudes) {
              if (solicitudes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 64,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sin solicitudes pendientes',
                        style: TextStyle(
                          fontSize: 15,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: solicitudes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _SolicitudPendienteCard(
                  solicitud: solicitudes[index],
                  cs: cs,
                  onTap: () => abrirDetalleSolicitud(
                    context,
                    ref,
                    solicitudes[index],
                    asientosReadOnly: true,
                  ),
                  onAprobada: () => ref
                      .read(_pendientesRefreshProvider.notifier)
                      .state++,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Card de solicitud PENDIENTE con botones Aprobar / Rechazar
// ═══════════════════════════════════════════════════════════════════════════

class _SolicitudPendienteCard extends ConsumerStatefulWidget {
  final SolicitudPagoEntity solicitud;
  final ColorScheme cs;
  final VoidCallback onTap;
  final VoidCallback onAprobada;

  const _SolicitudPendienteCard({
    required this.solicitud,
    required this.cs,
    required this.onTap,
    required this.onAprobada,
  });

  @override
  ConsumerState<_SolicitudPendienteCard> createState() =>
      _SolicitudPendienteCardState();
}

class _SolicitudPendienteCardState
    extends ConsumerState<_SolicitudPendienteCard> {
  bool _cargando = false;

  Future<void> _cambiarEstado(String nuevoEstado) async {
    String? observacion;

    if (nuevoEstado == 'RECHAZADA') {
      observacion = await _pedirObservacion();
      if (observacion == null) return; // canceló
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          nuevoEstado == 'APROBADA'
              ? 'Aprobar solicitud'
              : 'Rechazar solicitud',
        ),
        content: Text(
          nuevoEstado == 'APROBADA'
              ? '¿Confirma APROBAR la solicitud #${widget.solicitud.idSolicitud}?'
              : '¿Confirma RECHAZAR la solicitud #${widget.solicitud.idSolicitud}?\n\nMotivo: $observacion',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: nuevoEstado == 'RECHAZADA'
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(nuevoEstado == 'APROBADA' ? 'Aprobar' : 'Rechazar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _cargando = true);
    try {
      final audUsuario = ref.read(userProvider)?.codUsuario ?? 0;
      final repo = PagosExtranjerosImpl();
      await repo.aprobarSolicitud({
        'idSolicitud': widget.solicitud.idSolicitud.toInt(),
        'estado': nuevoEstado,
        'observaciones': observacion ?? '',
        'audUsuario': audUsuario,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nuevoEstado == 'APROBADA'
                ? 'Solicitud aprobada exitosamente'
                : 'Solicitud rechazada',
          ),
          backgroundColor:
              nuevoEstado == 'APROBADA' ? Colors.green : Colors.red,
        ),
      );
      widget.onAprobada();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<String?> _pedirObservacion() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Motivo de rechazo'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Ingrese el motivo del rechazo (obligatorio)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, ctrl.text.trim());
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sol = widget.solicitud;
    final cs = widget.cs;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      '${sol.idSolicitud}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sol.nombre.isNotEmpty
                              ? sol.nombre
                              : 'Solicitud #${sol.idSolicitud}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _df.format(sol.fechaSolicitud),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'PENDIENTE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // ── Monto total + empresa ────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.attach_money_rounded,
                    size: 16,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '\$ ${_nf.format(sol.montoTotalSolicitud)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: cs.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.business_rounded,
                    size: 13,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Empresa #${sol.codEmpresa}',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              // ── Proveedores detallados ──────────────────────────────
              if (sol.proveedores.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: sol.proveedores.asMap().entries.map((entry) {
                      final i = entry.key;
                      final p = entry.value;
                      final totalFacturas = p.detalles.length;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (i > 0)
                            Divider(
                              height: 1,
                              color: cs.outlineVariant.withValues(alpha: 0.3),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nombre + código
                                Row(
                                  children: [
                                    Icon(
                                      Icons.store_rounded,
                                      size: 13,
                                      color: cs.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        p.cardName.isNotEmpty
                                            ? p.cardName
                                            : p.cardCode,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      p.cardCode,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Montos
                                Row(
                                  children: [
                                    _MontoChip(
                                      label: 'Facturas',
                                      value:
                                          '\$${_nf.format(p.totalFacturasUsd)}',
                                      cs: cs,
                                    ),
                                    const SizedBox(width: 6),
                                    _MontoChip(
                                      label: 'Amort.',
                                      value:
                                          '\$${_nf.format(p.totalAmortizadoUsd)}',
                                      cs: cs,
                                    ),
                                    const SizedBox(width: 6),
                                    _MontoChip(
                                      label: 'A pagar',
                                      value:
                                          '\$${_nf.format(p.totalAPagarUsd)}',
                                      cs: cs,
                                      highlight: true,
                                    ),
                                    const Spacer(),
                                    if (totalFacturas > 0)
                                      Text(
                                        '$totalFacturas fact.',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
              // Botones
              const SizedBox(height: 12),
              if (_cargando)
                const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Rechazar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(
                            color: Colors.red.withValues(alpha: 0.5),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _cambiarEstado('RECHAZADA'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Aprobar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _cambiarEstado('APROBADA'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widget auxiliar para chips de monto ───────────────────────────────────────

class _MontoChip extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  final bool highlight;
  const _MontoChip({
    required this.label,
    required this.value,
    required this.cs,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight ? cs.primary : cs.onSurface,
          ),
        ),
      ],
    );
  }
}
