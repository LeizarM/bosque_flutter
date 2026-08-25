import 'package:bosque_flutter/core/state/prestamo_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/prestamo_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/prestamo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_constants.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_shared_sheet_widgets.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SHEET DETALLE PRESTAMO
// ══════════════════════════════════════════════════════════════════════════════
class PrestamosDetalleSheet extends ConsumerStatefulWidget {
  final PrestamoEntity prestamo;
  const PrestamosDetalleSheet({super.key, required this.prestamo});
  @override
  ConsumerState<PrestamosDetalleSheet> createState() =>
      _PrestamosDetalleSheetState();
}

class _PrestamosDetalleSheetState extends ConsumerState<PrestamosDetalleSheet> {
  bool _mostrarAnulados = false;

  void _showEditDialog(
    PrestamoDetalleEntity d,
    int codPrestamo,
    int audUsuario,
  ) {
    DateTime selectedDate = d.fechaPago ?? DateTime.now();
    String selectedTipo = d.tipoPago ?? 'PLAN';
    if (selectedTipo != 'PLAN' && selectedTipo != 'CONT') {
      selectedTipo = 'PLAN';
    }

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setStateSB) {
              final cs = Theme.of(context).colorScheme;
              return AlertDialog(
                title: const Text(
                  'Editar Cuota',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PrestamoTipoPagoField(
                      value: selectedTipo,
                      onChanged: (val) => setStateSB(() => selectedTipo = val),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Fecha de Pago',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2050),
                        );
                        if (date != null) setStateSB(() => selectedDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: cs.outline.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(selectedDate),
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: cs.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);

                      try {
                        final ntf = ref.read(prestamoProvider(0).notifier);
                        final msg = await ntf.actualizarCuotaPrestamo(
                          codPrestDetalle: d.codPrestDetalle,
                          tipoPago: selectedTipo,
                          fechaPago: selectedDate,
                          audUsuario: audUsuario,
                          codPrestamo: codPrestamo,
                        );

                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        // Error manejado globalmente
                      }
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showConfirmPayDialog(
    PrestamoDetalleEntity d,
    int codPrestamo,
    int audUsuario,
    bool isCancel,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isCancel ? 'Cobrar Cuota al Contado' : 'Deshacer Cobro'),
          content: Text(
            isCancel
                ? '¿Desea marcar esta cuota como pagada?'
                : '¿Desea revertir el estado de esta cuota?',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(ctx);
                Navigator.pop(ctx);
                try {
                  final ntf = ref.read(prestamoProvider(0).notifier);
                  final msg = await ntf.actualizarCuotaPrestamo(
                    codPrestDetalle: d.codPrestDetalle,
                    tipoPago: d.tipoPago ?? 'CONT',
                    fechaPago: d.fechaPago ?? DateTime.now(),
                    audUsuario: audUsuario,
                    codPrestamo: codPrestamo,
                    estadoCuota: isCancel ? 'Cancelado' : 'No Cancelado',
                  );
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  // Manejado por listener global
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _showAdelantoDialog(
    int codPrestamo,
    double saldoPendiente,
    int audUsuario,
  ) {
    DateTime selectedDate = DateTime.now();
    final _montoCtrl = TextEditingController();
    final _detalleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setStateSB) {
              final cs = Theme.of(context).colorScheme;
              return AlertDialog(
                title: const Text(
                  'Registrar Adelanto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monto a Adelantar (Max. ${fmtAnticipo.format(saldoPendiente)})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _montoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixText: 'Bs. ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Detalle del Pago',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _detalleCtrl,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Ej. Adelanto Aguinaldo',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Fecha de Pago',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2050),
                        );
                        if (date != null) setStateSB(() => selectedDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: cs.outline.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(selectedDate),
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: cs.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final valStr = _montoCtrl.text.replaceAll(',', '.');
                      final monto = double.tryParse(valStr);
                      if (monto == null || monto <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Monto inválido')),
                        );
                        return;
                      }
                      if (monto > saldoPendiente) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('El monto supera el saldo pendiente'),
                          ),
                        );
                        return;
                      }

                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      final detalleStr = _detalleCtrl.text.trim();

                      try {
                        final ntf = ref.read(prestamoProvider(0).notifier);
                        final msg = await ntf.adelantarCuotaPrestamo(
                          codPrestamo: codPrestamo,
                          montoPago: monto,
                          fechaPago: selectedDate,
                          detalle: detalleStr,
                          audUsuario: audUsuario,
                        );

                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        // Manejado por listener global
                      }
                    },
                    child: const Text('Confirmar'),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    // Mantener el provider vivo mientras el sheet está montados
    ref.watch(prestamoProvider(0));

    // Only load if it has a codPrestamo > 0 (assigned)
    final codPrestamo = widget.prestamo.codPrestamo ?? 0;
    final stAsync = ref.watch(
      prestamoDetallesProvider((
        codPrestamo: codPrestamo,
        mostrarAnulados: _mostrarAnulados ? 1 : 0,
      )),
    );
    final p = widget.prestamo;
    final cs = Theme.of(ctx).colorScheme;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

    double? saldoPendienteCalculado = p.saldoPendiente;
    if (stAsync.value != null) {
      double totalPagado = 0.0;
      for (final d in stAsync.value!) {
        if (d.estadoCuota == 'Cancelado') {
          totalPagado += d.haber > 0 ? d.haber : d.debe;
        }
      }
      final montoTotal = p.debe > 0 ? p.debe : p.haber;
      saldoPendienteCalculado = montoTotal - totalPagado;
      if (saldoPendienteCalculado < 0) saldoPendienteCalculado = 0;
    }

    return AnticipoBaseSheet(
      initialChildSize: ResponsiveUtilsBosque.isDesktop(ctx) ? 0.85 : 0.65,
      minChildSize: ResponsiveUtilsBosque.isDesktop(ctx) ? 0.5 : 0.4,
      builder:
          (_, ctrl) => Column(
            children: [
              const AnticipoSheetHandle(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: cs.secondary.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: cs.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalle del Préstamo',
                            style: TextStyle(
                              fontSize:
                                  ResponsiveUtilsBosque.isDesktop(ctx)
                                      ? 18
                                      : 16,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p.concepto,
                            style: TextStyle(
                              fontSize:
                                  ResponsiveUtilsBosque.isDesktop(ctx)
                                      ? 14
                                      : 12,
                              color: cs.onSurface.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Monto Total',
                          style: TextStyle(
                            fontSize:
                                ResponsiveUtilsBosque.isDesktop(ctx) ? 14 : 12,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          'Bs. ${fmtAnticipo.format(p.debe > 0 ? p.debe : p.haber)}',
                          style: TextStyle(
                            fontSize:
                                ResponsiveUtilsBosque.isDesktop(ctx) ? 16 : 13,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        if (saldoPendienteCalculado != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Saldo Pendiente',
                            style: TextStyle(
                              fontSize:
                                  ResponsiveUtilsBosque.isDesktop(ctx)
                                      ? 14
                                      : 12,
                              color: cs.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            'Bs. ${fmtAnticipo.format(saldoPendienteCalculado)}',
                            style: TextStyle(
                              fontSize:
                                  ResponsiveUtilsBosque.isDesktop(ctx)
                                      ? 18
                                      : 14,
                              fontWeight: FontWeight.bold,
                              color:
                                  saldoPendienteCalculado > 0
                                      ? (isDark
                                          ? Colors.orangeAccent.shade200
                                          : Colors.deepOrange)
                                      : (isDark
                                          ? Colors.greenAccent.shade200
                                          : const Color(0xFF1B5E20)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: [
                              if (saldoPendienteCalculado > 0 &&
                                  p.estadoPrestamo != 'ANU')
                                PermissionWidget(
                                  buttonName: 'btnRegistrarNuevaCuota',
                                  child: SizedBox(
                                    height: 28,
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        textStyle: TextStyle(
                                          fontSize:
                                              ResponsiveUtilsBosque.isDesktop(
                                                    context,
                                                  )
                                                  ? 16
                                                  : 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onPressed: () {
                                        final audUsr =
                                            ref
                                                .read(userProvider)
                                                ?.codUsuario ??
                                            0;
                                        _showAdelantoDialog(
                                          codPrestamo,
                                          saldoPendienteCalculado!,
                                          audUsr,
                                        );
                                      },
                                      icon: Icon(
                                        Icons.payment_rounded,
                                        size:
                                            ResponsiveUtilsBosque.isDesktop(
                                                  context,
                                                )
                                                ? 18
                                                : 14,
                                      ),
                                      label: const Text('Nueva Cuota'),
                                    ),
                                  ),
                                ),
                              SizedBox(
                                height: 28,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed:
                                      () => _imprimirReporteCuotas(
                                        context,
                                        ref,
                                        codPrestamo,
                                      ),
                                  icon: const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    size: 15,
                                  ),
                                  label: const Text('Reporte'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Padding(
              //   padding: const EdgeInsets.symmetric(
              //     horizontal: 16,
              //     vertical: 4,
              //   ),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Text(
              //         'Mostrar cuotas anuladas',
              //         style: TextStyle(
              //           fontSize: 12,
              //           fontWeight: FontWeight.w600,
              //           color: cs.onSurface.withValues(alpha: 0.7),
              //         ),
              //       ),
              //       Switch(
              //         value: _mostrarAnulados,
              //         activeColor: cs.primary,
              //         onChanged: (val) {
              //           setState(() => _mostrarAnulados = val);
              //         },
              //       ),
              //     ],
              //   ),
              // ),
              // const Divider(height: 1),
              Expanded(
                child: stAsync.when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(
                        child: Text('No hay detalles para este préstamo.'),
                      );
                    }
                    return ListView.separated(
                      controller: ctrl,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final d = items[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius:
                                    ResponsiveUtilsBosque.isDesktop(context)
                                        ? 18
                                        : 14,
                                backgroundColor: cs.primary.withValues(
                                  alpha: 0.1,
                                ),
                                child: Icon(
                                  d.debe > 0
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  color:
                                      d.debe > 0
                                          ? (isDark
                                              ? Colors.redAccent
                                              : Colors.red.shade700)
                                          : (isDark
                                              ? Colors.greenAccent
                                              : Colors.green.shade700),
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.datoPago ?? 'Desconocido',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    if (d.detalle != null &&
                                        d.detalle!.isNotEmpty)
                                      Text(
                                        d.detalle!,
                                        style: TextStyle(
                                          fontSize:
                                              ResponsiveUtilsBosque.isDesktop(
                                                    context,
                                                  )
                                                  ? 15
                                                  : 13,
                                          color: cs.onSurface.withValues(
                                            alpha: 0.85,
                                          ),
                                        ),
                                      ),
                                    if (d.observacion != null &&
                                        d.observacion!.isNotEmpty)
                                      Text(
                                        d.observacion!,
                                        style: TextStyle(
                                          fontSize:
                                              ResponsiveUtilsBosque.isDesktop(
                                                    context,
                                                  )
                                                  ? 14
                                                  : 12,
                                          color: cs.onSurface.withValues(
                                            alpha: 0.85,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 3),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              size:
                                                  ResponsiveUtilsBosque.isDesktop(
                                                        context,
                                                      )
                                                      ? 12
                                                      : 9,
                                              color: cs.onSurface.withValues(
                                                alpha: 0.6,
                                              ),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              d.fechaPago != null
                                                  ? fmtFechaAnticipo.format(
                                                    d.fechaPago!,
                                                  )
                                                  : 'Sin Fecha',
                                              style: TextStyle(
                                                fontSize:
                                                    ResponsiveUtilsBosque.isDesktop(
                                                          context,
                                                        )
                                                        ? 14
                                                        : 12,
                                                color: cs.onSurface.withValues(
                                                  alpha: 0.75,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (d.estadoCuota != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  d.estadoCuota == 'Cancelado'
                                                      ? Colors.green.withValues(
                                                        alpha:
                                                            isDark ? 0.2 : 0.15,
                                                      )
                                                      : Colors.redAccent
                                                          .withValues(
                                                            alpha:
                                                                isDark
                                                                    ? 0.2
                                                                    : 0.15,
                                                          ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              d.estadoCuota!.toUpperCase(),
                                              style: TextStyle(
                                                fontSize:
                                                    ResponsiveUtilsBosque.isDesktop(
                                                          context,
                                                        )
                                                        ? 12
                                                        : 9,
                                                color:
                                                    d.estadoCuota == 'Cancelado'
                                                        ? (isDark
                                                            ? Colors.greenAccent
                                                            : Colors
                                                                .green
                                                                .shade800)
                                                        : (isDark
                                                            ? Colors.redAccent
                                                            : Colors
                                                                .red
                                                                .shade800),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        if (d.postergado == 'SI')
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withValues(
                                                alpha: isDark ? 0.2 : 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              'POSTERGADO',
                                              style: TextStyle(
                                                fontSize:
                                                    ResponsiveUtilsBosque.isDesktop(
                                                          context,
                                                        )
                                                        ? 12
                                                        : 9,
                                                color:
                                                    isDark
                                                        ? Colors.orangeAccent
                                                        : Colors
                                                            .orange
                                                            .shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    d.debe > 0
                                        ? 'Cargo: Bs. ${fmtAnticipo.format(d.debe)}'
                                        : 'Abono: Bs. ${fmtAnticipo.format(d.haber)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          ResponsiveUtilsBosque.getResponsiveValue<
                                            double
                                          >(
                                            context: context,
                                            defaultValue: 12.0,
                                            mobile: 11.0,
                                            desktop: 15.0,
                                          ),
                                      color:
                                          d.debe > 0
                                              ? (isDark
                                                  ? Colors.redAccent
                                                  : Colors.red.shade800)
                                              : (isDark
                                                  ? Colors.greenAccent
                                                  : Colors.green.shade800),
                                    ),
                                  ),
                                  Text(
                                    'Saldo: Bs. ${fmtAnticipo.format(d.saldo)}',
                                    style: TextStyle(
                                      fontSize:
                                          ResponsiveUtilsBosque.getResponsiveValue<
                                            double
                                          >(
                                            context: context,
                                            defaultValue: 12.0,
                                            mobile: 10.0,
                                            desktop: 14.0,
                                          ),
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSurface.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                  if (p.estadoPrestamo != 'ANU' &&
                                      (d.montoPago == 0 ||
                                          d.tipoPago == 'CONT'))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (d.montoPago == 0)
                                            PermissionWidget(
                                              buttonName: 'btnEditarCuota',
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons.edit_rounded,
                                                  size: 20,
                                                  color: cs.primary,
                                                ),
                                                constraints:
                                                    const BoxConstraints(),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                    ),
                                                tooltip: 'Editar',
                                                onPressed: () {
                                                  final audUsuario =
                                                      ref
                                                          .read(userProvider)
                                                          ?.codUsuario ??
                                                      0;
                                                  _showEditDialog(
                                                    d,
                                                    codPrestamo,
                                                    audUsuario,
                                                  );
                                                },
                                              ),
                                            ),
                                          if (d.tipoPago == 'CONT' &&
                                              d.estadoCuota != 'Cancelado')
                                            PermissionWidget(
                                              buttonName:
                                                  'btnCobrarCuotaContado',
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.check_circle_outline,
                                                  size: 20,
                                                  color: Colors.green,
                                                ),
                                                constraints:
                                                    const BoxConstraints(),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                    ),
                                                tooltip: 'Cobrar Cuota',
                                                onPressed: () {
                                                  final audUsuario =
                                                      ref
                                                          .read(userProvider)
                                                          ?.codUsuario ??
                                                      0;
                                                  _showConfirmPayDialog(
                                                    d,
                                                    codPrestamo,
                                                    audUsuario,
                                                    true,
                                                  );
                                                },
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
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

  Future<void> _imprimirReporteCuotas(
    BuildContext context,
    WidgetRef ref,
    int codPrestamo,
  ) async {
    try {
      final pdfBytes = await ref.read(
        reporteCuotasProvider(codPrestamo).future,
      );

      if (!mounted) return;

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Reporte_Cuotas_$codPrestamo',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar el reporte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
