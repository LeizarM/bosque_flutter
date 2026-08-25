import 'package:bosque_flutter/core/state/prestamo_provider.dart';
import 'package:bosque_flutter/domain/entities/prestamo_detalle_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class PrestamosAmortizacionPreview extends ConsumerStatefulWidget {
  final double montoPrestamo;
  final double numCuotas;
  final DateTime fecIniPago;
  final String tipoPago;
  final ValueChanged<String?> onConfirm;

  const PrestamosAmortizacionPreview({
    super.key,
    required this.montoPrestamo,
    required this.numCuotas,
    required this.fecIniPago,
    required this.tipoPago,
    required this.onConfirm,
  });

  @override
  ConsumerState<PrestamosAmortizacionPreview> createState() =>
      _PrestamosAmortizacionPreviewState();
}

class _PrestamosAmortizacionPreviewState
    extends ConsumerState<PrestamosAmortizacionPreview> {
  final List<PrestamoDetalleEntity> _cuotas = [];
  final Map<int, TextEditingController> _montoControllers = {};
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void dispose() {
    for (var c in _montoControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPreview() async {
    try {
      final repo = ref.read(prestamoProvider(0).notifier).repo;
      final result = await repo.previsualizarCuotas(
        montoPrestamo: widget.montoPrestamo,
        numCuotas: widget.numCuotas,
        fecIniPago: DateFormat('yyyy-MM-dd').format(widget.fecIniPago),
        tipoPago: widget.tipoPago,
      );

      _cuotas.clear();
      _cuotas.addAll(result);

      for (var c in _cuotas) {
        final ctrl = TextEditingController(text: c.haber.toStringAsFixed(4));
        ctrl.addListener(() => setState(() {}));
        _montoControllers[c.numeroCuota!] = ctrl;
      }

      _isLoading = false;
      if (mounted) setState(() {});
    } catch (e) {
      _errorMsg = e.toString();
      _isLoading = false;
      if (mounted) setState(() {});
    }
  }

  double get _sumaActual {
    double sum = 0;
    for (var c in _cuotas) {
      final val =
          double.tryParse(_montoControllers[c.numeroCuota!]?.text ?? '0') ?? 0;
      sum += val;
    }
    return sum;
  }

  String _generarXml() {
    final sb = StringBuffer();
    sb.writeln('<cuotas>');
    for (var c in _cuotas) {
      final monto =
          double.tryParse(_montoControllers[c.numeroCuota!]?.text ?? '0') ?? 0;
      final fechaStr = DateFormat(
        'yyyy-MM-dd',
      ).format(c.fechaPago ?? DateTime.now());
      sb.writeln(
        '  <cuota num="${c.numeroCuota}" monto="${monto.toStringAsFixed(4)}" fecha="$fechaStr" />',
      );
    }
    sb.writeln('</cuotas>');
    return sb.toString();
  }

  void _seleccionarFecha(PrestamoDetalleEntity cuota) async {
    final date = await showDatePicker(
      context: context,
      initialDate: cuota.fechaPago ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );
    if (date != null && mounted) {
      setState(() {
        final idx = _cuotas.indexOf(cuota);
        _cuotas[idx] = cuota.copyWith(fechaPago: date);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_errorMsg != null) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              _errorMsg!,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.error),
            ),
          ],
        ),
      );
    }

    final suma = _sumaActual;
    final diff = (widget.montoPrestamo - suma).abs();
    final esExacto = diff < 0.01;

    return Container(
      constraints: const BoxConstraints(maxHeight: 600),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.table_chart_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tabla de Amortización Editable',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total esperado: Bs. ${widget.montoPrestamo.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _cuotas.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final c = _cuotas[i];
                return Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${c.numeroCuota}',
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () => _seleccionarFecha(c),
                        borderRadius: BorderRadius.circular(6),
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
                                DateFormat(
                                  'dd/MM/yyyy',
                                ).format(c.fechaPago ?? DateTime.now()),
                                style: const TextStyle(fontSize: 13),
                              ),
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: cs.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 34,
                        child: TextField(
                          controller: _montoControllers[c.numeroCuota!],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            prefixText: 'Bs. ',
                            prefixStyle: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  esExacto
                      ? (isDark
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.green.shade50)
                      : (isDark
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.red.shade50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suma de cuotas',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            esExacto
                                ? (isDark
                                    ? Colors.green.shade200
                                    : Colors.green.shade800)
                                : (isDark
                                    ? Colors.red.shade200
                                    : Colors.red.shade800),
                      ),
                    ),
                    Text(
                      'Bs. ${suma.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            esExacto
                                ? (isDark
                                    ? Colors.greenAccent
                                    : Colors.green.shade900)
                                : (isDark
                                    ? Colors.redAccent
                                    : Colors.red.shade900),
                      ),
                    ),
                    if (!esExacto)
                      Text(
                        'Diferencia: Bs. ${diff.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.red.shade300 : Colors.red,
                        ),
                      ),
                  ],
                ),
                FilledButton.icon(
                  onPressed:
                      esExacto
                          ? () {
                            widget.onConfirm(_generarXml());
                          }
                          : null,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Confirmar y Guardar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: cs.surfaceContainerHighest,
                    disabledForegroundColor: cs.onSurface.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> showPrestamoAmortizacionPreview({
  required BuildContext context,
  required double montoPrestamo,
  required double numCuotas,
  required DateTime fecIniPago,
  required String tipoPago,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: PrestamosAmortizacionPreview(
          montoPrestamo: montoPrestamo,
          numCuotas: numCuotas,
          fecIniPago: fecIniPago,
          tipoPago: tipoPago,
          onConfirm: (xml) => Navigator.of(ctx).pop(xml),
        ),
      );
    },
  );
}
