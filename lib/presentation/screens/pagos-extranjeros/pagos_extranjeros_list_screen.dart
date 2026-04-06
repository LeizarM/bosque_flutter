import 'package:bosque_flutter/core/state/pagos_extranjeros_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/solicitud_pago_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_proveedor_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final _numberFormat = NumberFormat('#,##0.00', 'es_BO');
final _dateFormat = DateFormat('dd/MM/yyyy');

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final asyncSolicitudes = ref.watch(solicitudesRegistradasProvider(_param));

    return Column(
      children: [
        // ── Filtros de fecha ───────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: 12,
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  _DateChip(
                    label: 'Desde',
                    date: _fechaInicio,
                    colorScheme: colorScheme,
                    onTap: () => _pickDate(context, true),
                  ),
                  _DateChip(
                    label: 'Hasta',
                    date: _fechaFin,
                    colorScheme: colorScheme,
                    onTap: () => _pickDate(context, false),
                  ),
                  FilledButton.tonalIcon(
                    onPressed:
                        () => ref.invalidate(
                          solicitudesRegistradasProvider(_param),
                        ),
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: const Text('Buscar'),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Lista de solicitudes ──────────────────────────────────
        Expanded(
          child: asyncSolicitudes.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
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
                          'Error al cargar las solicitudes',
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
                        FilledButton.tonalIcon(
                          onPressed:
                              () => ref.invalidate(
                                solicitudesRegistradasProvider(_param),
                              ),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Reintentar'),
                        ),
                      ],
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
                        Icons.inbox_rounded,
                        size: 64,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No se encontraron solicitudes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ajuste el rango de fechas e intente de nuevo',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24,
                  vertical: 8,
                ),
                itemCount: solicitudes.length,
                itemBuilder:
                    (context, index) => _SolicitudCard(
                      solicitud: solicitudes[index],
                      colorScheme: colorScheme,
                      isMobile: isMobile,
                    ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip de fecha para filtros
// ─────────────────────────────────────────────────────────────────────────────
class _DateChip extends StatelessWidget {
  final String label;
  final DateTime date;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.date,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(
        Icons.calendar_today_rounded,
        size: 16,
        color: colorScheme.primary,
      ),
      label: Text('$label: ${_dateFormat.format(date)}'),
      onPressed: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de una solicitud con proveedores expandibles
// ─────────────────────────────────────────────────────────────────────────────
class _SolicitudCard extends StatelessWidget {
  final SolicitudPagoEntity solicitud;
  final ColorScheme colorScheme;
  final bool isMobile;

  const _SolicitudCard({
    required this.solicitud,
    required this.colorScheme,
    required this.isMobile,
  });

  Color _estadoColor() {
    switch (solicitud.estado.toUpperCase()) {
      case 'APROBADA':
      case 'APROBADO':
        return Colors.green;
      case 'RECHAZADA':
      case 'RECHAZADO':
        return Colors.red;
      case 'PENDIENTE':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoColor = _estadoColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            '${solicitud.idSolicitud}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                solicitud.nombre.isNotEmpty
                    ? solicitud.nombre
                    : 'Empresa #${solicitud.codEmpresa}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: estadoColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                solicitud.estado,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: estadoColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _InfoTag(
                icon: Icons.calendar_today_rounded,
                text: _dateFormat.format(solicitud.fechaSolicitud),
                colorScheme: colorScheme,
              ),
              _InfoTag(
                icon: Icons.attach_money_rounded,
                text:
                    '\$ ${_numberFormat.format(solicitud.montoTotalSolicitud)}',
                colorScheme: colorScheme,
                bold: true,
              ),
              _InfoTag(
                icon: Icons.people_outline_rounded,
                text: '${solicitud.proveedores.length} proveedor(es)',
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children:
            solicitud.proveedores
                .map(
                  (prov) => _ProveedorExpansion(
                    proveedor: prov,
                    colorScheme: colorScheme,
                    isMobile: isMobile,
                  ),
                )
                .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Etiqueta informativa con icono
// ─────────────────────────────────────────────────────────────────────────────
class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme colorScheme;
  final bool bold;

  const _InfoTag({
    required this.icon,
    required this.text,
    required this.colorScheme,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expansión de un proveedor dentro de la solicitud
// ─────────────────────────────────────────────────────────────────────────────
class _ProveedorExpansion extends StatelessWidget {
  final SolicitudProveedorEntity proveedor;
  final ColorScheme colorScheme;
  final bool isMobile;

  const _ProveedorExpansion({
    required this.proveedor,
    required this.colorScheme,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: ExpansionTile(
        dense: true,
        leading: Icon(
          Icons.business_rounded,
          size: 20,
          color: colorScheme.primary,
        ),
        title: Text(
          proveedor.cardName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          proveedor.cardCode,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          // Resumen del proveedor (calculado desde detalles)
          Builder(
            builder: (context) {
              final totalFacturas = proveedor.detalles.fold<double>(
                0,
                (sum, d) => sum + d.montoFacturaUsd,
              );
              final totalAmortizado = proveedor.detalles.fold<double>(
                0,
                (sum, d) => sum + d.montoAmortizadoUsd,
              );
              final totalAPagar = proveedor.detalles.fold<double>(
                0,
                (sum, d) => sum + d.montoAPagarUsd,
              );
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniStat(
                    label: 'Total Facturas',
                    value: '\$ ${_numberFormat.format(totalFacturas)}',
                    colorScheme: colorScheme,
                  ),
                  _MiniStat(
                    label: 'Amortizado',
                    value: '\$ ${_numberFormat.format(totalAmortizado)}',
                    colorScheme: colorScheme,
                  ),
                  _MiniStat(
                    label: 'A Pagar',
                    value: '\$ ${_numberFormat.format(totalAPagar)}',
                    colorScheme: colorScheme,
                    bold: true,
                  ),
                ],
              );
            },
          ),
          if (proveedor.detalles.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...proveedor.detalles.map(
              (det) => _DetalleTile(
                detalle: det,
                colorScheme: colorScheme,
                isMobile: isMobile,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini estadística
// ─────────────────────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final bool bold;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.colorScheme,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: bold ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile de un detalle (factura)
// ─────────────────────────────────────────────────────────────────────────────
class _DetalleTile extends StatelessWidget {
  final dynamic detalle;
  final ColorScheme colorScheme;
  final bool isMobile;

  const _DetalleTile({
    required this.detalle,
    required this.colorScheme,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    detalle.tipoDocumento,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Doc: ${detalle.numeroDocumento}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$ ${_numberFormat.format(detalle.montoAPagarUsd)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _SmallInfo(
                  label: 'Factura',
                  value: '\$ ${_numberFormat.format(detalle.montoFacturaUsd)}',
                ),
                _SmallInfo(
                  label: 'Amortizado',
                  value:
                      '\$ ${_numberFormat.format(detalle.montoAmortizadoUsd)}',
                ),
                _SmallInfo(
                  label: 'F. Factura',
                  value: _dateFormat.format(detalle.fechaFactura),
                ),
                _SmallInfo(
                  label: 'F. Venc.',
                  value: _dateFormat.format(detalle.fechaVencimiento),
                ),
                if (detalle.codigoImportacion.isNotEmpty)
                  _SmallInfo(
                    label: 'Importación',
                    value: detalle.codigoImportacion,
                  ),
                if (detalle.obs.isNotEmpty)
                  _SmallInfo(label: 'Obs', value: detalle.obs),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallInfo extends StatelessWidget {
  final String label;
  final String value;
  const _SmallInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
