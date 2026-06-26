import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/data/repositories/pagos_extranjeros_impl.dart';
import 'package:bosque_flutter/domain/entities/solicitud_pago_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_proveedor_entity.dart';
import 'package:bosque_flutter/domain/entities/detalle_solicitud_entity.dart';
import 'package:bosque_flutter/presentation/screens/pagos-extranjeros/solicitud_detail_panel.dart';
import 'package:bosque_flutter/presentation/widgets/pagos-extranjeros/tpex_estado_ui.dart';
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
      return todas.where((s) => s.estado.toUpperCase() == 'PENDIENTE').toList()
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
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
          color: cs.surface,
          child: Row(
            children: [
              Icon(Icons.approval_rounded, color: cs.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aprobación de Solicitudes (por cuota / por proveedor)',
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
                onPressed:
                    () => ref.read(_pendientesRefreshProvider.notifier).state++,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: asyncSolicitudes.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (e, _) => Center(
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder:
                    (context, index) => _SolicitudPendienteCard(
                      solicitud: solicitudes[index],
                      cs: cs,
                      onTap:
                          () => abrirDetalleSolicitud(
                            context,
                            ref,
                            solicitudes[index],
                            asientosReadOnly: true,
                          ),
                      onChanged:
                          () =>
                              ref
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
// Card de solicitud con aprobación granular por cuota y por proveedor
// ═══════════════════════════════════════════════════════════════════════════

class _SolicitudPendienteCard extends ConsumerStatefulWidget {
  final SolicitudPagoEntity solicitud;
  final ColorScheme cs;
  final VoidCallback onTap;
  final VoidCallback onChanged;

  const _SolicitudPendienteCard({
    required this.solicitud,
    required this.cs,
    required this.onTap,
    required this.onChanged,
  });

  @override
  ConsumerState<_SolicitudPendienteCard> createState() =>
      _SolicitudPendienteCardState();
}

class _SolicitudPendienteCardState
    extends ConsumerState<_SolicitudPendienteCard> {
  bool _cargando = false;
  final Set<int> _expandedProvs = {};

  /// Un proveedor con ≥1 cuota aprobada (APROBADO o APROBADO_PARCIAL) cuenta
  /// como aprobado para habilitar la solicitud.
  bool get _algunProveedorAprobado => widget.solicitud.proveedores
      .any((p) => p.estado == 'APROBADO' || p.estado == 'APROBADO_PARCIAL');

  /// La solicitud puede aprobarse en cuanto hay ≥1 proveedor con cuotas
  /// aprobadas. Los proveedores/cuotas que queden sin aprobar pueden permanecer
  /// pendientes indefinidamente (estilo SAP): no bloquean el avance, solo no se
  /// pagan.
  bool get _puedeAprobarSolicitud => _algunProveedorAprobado;

  Future<void> _aprobarCuota(DetalleSolicitudEntity det) async {
    final ok = await _confirm(
      titulo: 'Aprobar cuota',
      mensaje:
          'Cuota #${det.numeroCuota} del documento ${det.facturaProvSap}\n'
          'Monto: \$${_nf.format(det.montoAPagarUsd)}\n\n'
          '¿Confirma la aprobación de esta cuota?',
      botonOk: 'Aprobar',
    );
    if (ok != true) return;
    await _runOp(() async {
      final audUsuario = ref.read(userProvider)?.codUsuario ?? 0;
      await PagosExtranjerosImpl().aprobarCuota({
        'idDetalle': det.idDetalle.toInt(),
        'audUsuario': audUsuario,
      });
    }, mensajeOk: 'Cuota aprobada');
  }

  Future<void> _revertirCuota(DetalleSolicitudEntity det) async {
    final ok = await _confirm(
      titulo: 'Revertir aprobación',
      mensaje:
          'Cuota #${det.numeroCuota} — \$${_nf.format(det.montoAPagarUsd)}\n\n'
          'Esto desmarcará la cuota como aprobada. Si el proveedor estaba APROBADO, '
          'volverá a PENDIENTE.',
      botonOk: 'Revertir',
    );
    if (ok != true) return;
    await _runOp(() async {
      final audUsuario = ref.read(userProvider)?.codUsuario ?? 0;
      await PagosExtranjerosImpl().revertirAprobacionCuota({
        'idDetalle': det.idDetalle.toInt(),
        'audUsuario': audUsuario,
      });
    }, mensajeOk: 'Aprobación de cuota revertida');
  }

  Future<void> _aprobarProveedor(SolicitudProveedorEntity prov) async {
    final ok = await _confirm(
      titulo: 'Aprobar proveedor',
      mensaje:
          'Proveedor: ${prov.cardName.isNotEmpty ? prov.cardName : prov.cardCode}\n'
          'Total a pagar: \$${_nf.format(prov.totalAPagarUsd)}\n\n'
          'Esto aprobará TODAS sus cuotas y dejará al proveedor en estado APROBADO.',
      botonOk: 'Aprobar todo',
    );
    if (ok != true) return;
    await _runOp(() async {
      final audUsuario = ref.read(userProvider)?.codUsuario ?? 0;
      await PagosExtranjerosImpl().aprobarProveedor({
        'idSolicitudProveedor': prov.idSolicitudProveedor.toInt(),
        'obsAprobacion': 'Aprobación manual del proveedor.',
        'audUsuario': audUsuario,
      });
    }, mensajeOk: 'Proveedor APROBADO');
  }

  Future<void> _rechazarProveedor(SolicitudProveedorEntity prov) async {
    final motivo = await _pedirObservacion(titulo: 'Motivo de rechazo');
    if (motivo == null) return;
    final ok = await _confirm(
      titulo: 'Rechazar proveedor',
      mensaje:
          'Proveedor: ${prov.cardName.isNotEmpty ? prov.cardName : prov.cardCode}\n\n'
          'Motivo: $motivo\n\n'
          'El proveedor quedará excluido del cálculo de cotizaciones.',
      botonOk: 'Rechazar',
      destructivo: true,
    );
    if (ok != true) return;
    await _runOp(() async {
      final audUsuario = ref.read(userProvider)?.codUsuario ?? 0;
      await PagosExtranjerosImpl().rechazarProveedor({
        'idSolicitudProveedor': prov.idSolicitudProveedor.toInt(),
        'obsAprobacion': motivo,
        'audUsuario': audUsuario,
      });
    }, mensajeOk: 'Proveedor RECHAZADO');
  }

  Future<void> _aprobarSolicitud() async {
    if (!_algunProveedorAprobado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Apruebe al menos una cuota (de cualquier proveedor) antes de aprobar la solicitud.',
          ),
        ),
      );
      return;
    }
    final ok = await _confirm(
      titulo: 'Aprobar solicitud',
      mensaje:
          '¿Confirma APROBAR la solicitud #${widget.solicitud.idSolicitud}?\n\n'
          'Se habilita el flujo de cotizaciones para lo aprobado. Las cuotas o '
          'proveedores sin aprobar quedan pendientes (no se pagan).',
      botonOk: 'Aprobar',
    );
    if (ok != true) return;
    await _runOp(() async {
      final audUsuario = ref.read(userProvider)?.codUsuario ?? 0;
      await PagosExtranjerosImpl().aprobarSolicitud({
        'idSolicitud': widget.solicitud.idSolicitud.toInt(),
        'estado': 'APROBADA',
        'audUsuario': audUsuario,
      });
    }, mensajeOk: 'Solicitud APROBADA');
  }

  Future<void> _rechazarSolicitud() async {
    final motivo = await _pedirObservacion(titulo: 'Motivo de rechazo');
    if (motivo == null) return;
    final ok = await _confirm(
      titulo: 'Rechazar solicitud',
      mensaje:
          '¿Confirma RECHAZAR la solicitud #${widget.solicitud.idSolicitud}?\n\n'
          'Motivo: $motivo',
      botonOk: 'Rechazar',
      destructivo: true,
    );
    if (ok != true) return;
    await _runOp(() async {
      final audUsuario = ref.read(userProvider)?.codUsuario ?? 0;
      await PagosExtranjerosImpl().aprobarSolicitud({
        'idSolicitud': widget.solicitud.idSolicitud.toInt(),
        'estado': 'RECHAZADA',
        'observaciones': motivo,
        'audUsuario': audUsuario,
      });
    }, mensajeOk: 'Solicitud RECHAZADA');
  }

  Future<void> _runOp(
    Future<void> Function() op, {
    required String mensajeOk,
  }) async {
    setState(() => _cargando = true);
    try {
      await op();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeOk), backgroundColor: Colors.green),
      );
      widget.onChanged();
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

  Future<bool?> _confirm({
    required String titulo,
    required String mensaje,
    required String botonOk,
    bool destructivo = false,
  }) => showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style:
                  destructivo
                      ? FilledButton.styleFrom(backgroundColor: Colors.red)
                      : null,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(botonOk),
            ),
          ],
        ),
  );

  Future<String?> _pedirObservacion({required String titulo}) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(titulo),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ingrese el motivo (obligatorio)',
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
    final proveedoresAprobados =
        sol.proveedores
            .where(
              (p) => p.estado == 'APROBADO' || p.estado == 'APROBADO_PARCIAL',
            )
            .length;
    final totalProveedores = sol.proveedores.length;

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
              // ── Header solicitud ──────────────────────────────────────
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
                        Row(
                          children: [
                            Text(
                              _df.format(sol.fechaSolicitud),
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            if (sol.project.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.work_outline,
                                size: 11,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                sol.project,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  _estadoBadge('PENDIENTE'),
                ],
              ),
              const SizedBox(height: 8),
              // ── Resumen monto + contador proveedores ─────────────────
              Row(
                children: [
                  Icon(Icons.attach_money_rounded, size: 16, color: cs.primary),
                  const SizedBox(width: 4),
                  Text(
                    '\$ ${_nf.format(sol.montoTotalSolicitud)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: cs.primary,
                      fontFeatures: tpexTabularFigures,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color:
                          proveedoresAprobados > 0
                              ? Colors.green.withValues(alpha: 0.15)
                              : cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$proveedoresAprobados/$totalProveedores prov. aprobados',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color:
                            proveedoresAprobados > 0
                                ? Colors.green.shade800
                                : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              // ── Proveedores con cuotas expandibles ───────────────────
              if (sol.proveedores.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...sol.proveedores.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  final expanded = _expandedProvs.contains(i);
                  return _ProveedorAprobacionTile(
                    prov: p,
                    expanded: expanded,
                    cs: cs,
                    onToggle:
                        () => setState(() {
                          if (expanded) {
                            _expandedProvs.remove(i);
                          } else {
                            _expandedProvs.add(i);
                          }
                        }),
                    onAprobarProveedor: () => _aprobarProveedor(p),
                    onRechazarProveedor: () => _rechazarProveedor(p),
                    onAprobarCuota: _aprobarCuota,
                    onRevertirCuota: _revertirCuota,
                  );
                }),
              ],
              const SizedBox(height: 12),
              // ── Acciones a nivel solicitud ───────────────────────────
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
                        label: const Text('Rechazar solicitud'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(
                            color: Colors.red.withValues(alpha: 0.5),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _rechazarSolicitud,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_circle_rounded, size: 16),
                        label: Text(
                          _puedeAprobarSolicitud
                              ? 'Aprobar solicitud'
                              : 'Aprueba ≥1 cuota',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              _puedeAprobarSolicitud
                                  ? Colors.green.shade700
                                  : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed:
                            _puedeAprobarSolicitud ? _aprobarSolicitud : null,
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

  Widget _estadoBadge(String estado) {
    MaterialColor color;
    switch (estado) {
      case 'APROBADO':
      case 'APROBADA':
        color = Colors.green;
        break;
      case 'APROBADO_PARCIAL':
        color = Colors.amber;
        break;
      case 'RECHAZADO':
      case 'RECHAZADA':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        tpexEstadoLabel(estado),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color.shade800,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tile de proveedor con sus cuotas (aprobación granular)
// ═══════════════════════════════════════════════════════════════════════════

class _ProveedorAprobacionTile extends StatelessWidget {
  final SolicitudProveedorEntity prov;
  final bool expanded;
  final ColorScheme cs;
  final VoidCallback onToggle;
  final VoidCallback onAprobarProveedor;
  final VoidCallback onRechazarProveedor;
  final void Function(DetalleSolicitudEntity) onAprobarCuota;
  final void Function(DetalleSolicitudEntity) onRevertirCuota;

  const _ProveedorAprobacionTile({
    required this.prov,
    required this.expanded,
    required this.cs,
    required this.onToggle,
    required this.onAprobarProveedor,
    required this.onRechazarProveedor,
    required this.onAprobarCuota,
    required this.onRevertirCuota,
  });

  MaterialColor get _color {
    switch (prov.estado) {
      case 'APROBADO':
        return Colors.green;
      case 'APROBADO_PARCIAL':
        return Colors.amber;
      case 'RECHAZADO':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuotasAprob = prov.detalles.where((d) => d.esAprobado == 1).length;
    final totalCuotas = prov.detalles.length;
    final puedeActuar = prov.estado != 'APROBADO' && prov.estado != 'RECHAZADO';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          // Header proveedor
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.store_rounded, size: 14, color: _color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          prov.cardName.isNotEmpty
                              ? prov.cardName
                              : prov.cardCode,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          tpexEstadoLabel(prov.estado),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _color.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        prov.cardCode,
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'A pagar: \$${_nf.format(prov.totalAPagarUsd)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFeatures: tpexTabularFigures,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$cuotasAprob/$totalCuotas cuotas',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color:
                              cuotasAprob == totalCuotas && totalCuotas > 0
                                  ? Colors.green
                                  : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Cuotas expandibles
          if (expanded) ...[
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
            ...prov.detalles.map(
              (det) => _CuotaRow(
                det: det,
                cs: cs,
                puedeActuar: puedeActuar,
                onAprobar: () => onAprobarCuota(det),
                onRevertir: () => onRevertirCuota(det),
              ),
            ),
            // Acciones del proveedor. El estado APROBADO_PARCIAL surge solo al
            // aprobar cuotas (parcial implícito); no hay botón dedicado.
            if (puedeActuar)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel_outlined, size: 14),
                        label: const Text(
                          'Rechazar proveedor',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(
                            color: Colors.red.withValues(alpha: 0.5),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: onRechazarProveedor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.done_all_rounded, size: 14),
                        label: const Text(
                          'Aprobar todo',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: onAprobarProveedor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Fila de cuota individual con botón Aprobar / Revertir
// ═══════════════════════════════════════════════════════════════════════════

class _CuotaRow extends StatelessWidget {
  final DetalleSolicitudEntity det;
  final ColorScheme cs;
  final bool puedeActuar;
  final VoidCallback onAprobar;
  final VoidCallback onRevertir;

  const _CuotaRow({
    required this.det,
    required this.cs,
    required this.puedeActuar,
    required this.onAprobar,
    required this.onRevertir,
  });

  @override
  Widget build(BuildContext context) {
    final aprobada = det.esAprobado == 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  aprobada
                      ? Colors.green.withValues(alpha: 0.15)
                      : cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '#${det.numeroCuota}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: aprobada ? Colors.green.shade800 : cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Doc ${det.facturaProvSap} — venc ${_df.format(det.fechaVencimiento)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (det.montoTotalDocumento > 0)
                  Text(
                    'Doc total: \$${_nf.format(det.montoTotalDocumento)}',
                    style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Text(
            '\$${_nf.format(det.montoAPagarUsd)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: aprobada ? Colors.green.shade800 : cs.onSurface,
              fontFeatures: tpexTabularFigures,
            ),
          ),
          const SizedBox(width: 6),
          if (puedeActuar)
            IconButton(
              tooltip: aprobada ? 'Revertir aprobación' : 'Aprobar cuota',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(
                aprobada ? Icons.undo_rounded : Icons.check_circle_outline,
                size: 18,
                color: aprobada ? Colors.orange : Colors.green,
              ),
              onPressed: aprobada ? onRevertir : onAprobar,
            )
          else
            Icon(
              aprobada ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color:
                  aprobada
                      ? Colors.green
                      : cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
        ],
      ),
    );
  }
}
