import 'dart:typed_data';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/repositories/indemnizacion_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

enum TipoReporteIndemnizacion { normal, todos, rrhh }

extension TipoReporteIndemnizacionExt on TipoReporteIndemnizacion {
  String get titulo {
    switch (this) {
      case TipoReporteIndemnizacion.normal:
        return 'Previsión Indemnización';
      case TipoReporteIndemnizacion.todos:
        return 'Previsión Indemnización (Todos)';
      case TipoReporteIndemnizacion.rrhh:
        return 'Previsión Indemnización RRHH';
    }
  }

  String get descripcion {
    switch (this) {
      case TipoReporteIndemnizacion.normal:
        return 'Excluye otros y externos.';
      case TipoReporteIndemnizacion.todos:
        return 'Incluye todo el personal.';
      case TipoReporteIndemnizacion.rrhh:
        return 'Incluye todos el personal agrupados por Caja.';
    }
  }

  String get endpoint {
    switch (this) {
      case TipoReporteIndemnizacion.normal:
        return AppConstants.reporteIndemnizacion;
      case TipoReporteIndemnizacion.todos:
        return AppConstants.reporteIndemnizacionTodos;
      case TipoReporteIndemnizacion.rrhh:
        return AppConstants.reporteIndemnizacionRRHH;
    }
  }

  String get pdfFileName {
    switch (this) {
      case TipoReporteIndemnizacion.normal:
        return 'Reporte_Prevision_Indemnizacion';
      case TipoReporteIndemnizacion.todos:
        return 'Reporte_Prevision_Indemnizacion_Todos';
      case TipoReporteIndemnizacion.rrhh:
        return 'Reporte_Prevision_Indemnizacion_RRHH';
    }
  }

  IconData get icon {
    switch (this) {
      case TipoReporteIndemnizacion.normal:
        return Icons.description_rounded;
      case TipoReporteIndemnizacion.todos:
        return Icons.groups_rounded;
      case TipoReporteIndemnizacion.rrhh:
        return Icons.account_balance_rounded;
    }
  }
}

/// Genera e imprime el reporte PDF de indemnización
Future<void> generarReporteIndemnizacion(
  BuildContext context, {
  required TipoReporteIndemnizacion tipo,
  required String fechaCorte,
}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  scaffoldMessenger.hideCurrentSnackBar();
  scaffoldMessenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Generando ${tipo.titulo}...')),
        ],
      ),
      duration: const Duration(seconds: 4),
    ),
  );

  try {
    final repo = IndemnizacionImpl();
    final params = <String, dynamic>{
      'fechaCorte':
          fechaCorte.isNotEmpty
              ? fechaCorte
              : DateFormat('yyyy-MM-dd').format(DateTime.now()),
    };

    final Uint8List pdfBytes = await repo.descargarReportePdf(
      endpoint: tipo.endpoint,
      params: params,
    );

    scaffoldMessenger.hideCurrentSnackBar();

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name:
          '${tipo.pdfFileName}_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  } catch (e) {
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Error al generar el reporte: $e'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Diálogo selector y visor de reportes de indemnización con filtros independientes
Future<void> showIndemnizacionReportesDialog(
  BuildContext context, {
  required String fechaCorte,
}) async {
  return showDialog(
    context: context,
    builder:
        (ctx) => _IndemnizacionReportesModal(fechaCorteInicial: fechaCorte),
  );
}

class _IndemnizacionReportesModal extends ConsumerStatefulWidget {
  final String fechaCorteInicial;

  const _IndemnizacionReportesModal({required this.fechaCorteInicial});

  @override
  ConsumerState<_IndemnizacionReportesModal> createState() =>
      _IndemnizacionReportesModalState();
}

class _IndemnizacionReportesModalState
    extends ConsumerState<_IndemnizacionReportesModal> {
  late String _fechaCorte;
  TipoReporteIndemnizacion _tipoSeleccionado = TipoReporteIndemnizacion.normal;
  bool _generando = false;

  @override
  void initState() {
    super.initState();
    _fechaCorte =
        widget.fechaCorteInicial.isNotEmpty
            ? widget.fechaCorteInicial
            : DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  String _formatearFecha(String f) {
    try {
      final d = DateTime.parse(f);
      return DateFormat('dd/MM/yyyy').format(d);
    } catch (_) {
      return f;
    }
  }

  Future<void> _generar() async {
    setState(() => _generando = true);
    await generarReporteIndemnizacion(
      context,
      tipo: _tipoSeleccionado,
      fechaCorte: _fechaCorte,
    );
    if (mounted) setState(() => _generando = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.print_rounded,
                      color: cs.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reportes de Indemnización',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        // const SizedBox(height: 2),
                        // Text(
                        //   'Filtros independientes para generación del reporte',
                        //   style: TextStyle(
                        //     fontSize: 12,
                        //     color: cs.onSurface.withValues(alpha: 0.6),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── FILTROS INDEPENDIENTES ──
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final initDate =
                      DateTime.tryParse(_fechaCorte) ?? DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _fechaCorte = picked.toIso8601String().split('T')[0];
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: cs.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FECHA DE CORTE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 16,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatearFecha(_fechaCorte),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── FORMATOS DE REPORTE ──
              ...TipoReporteIndemnizacion.values.map((tipo) {
                final isSelected = _tipoSeleccionado == tipo;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? cs.primary.withValues(alpha: 0.08)
                            : cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected
                              ? cs.primary
                              : cs.outline.withValues(alpha: 0.2),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _tipoSeleccionado = tipo);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Radio<TipoReporteIndemnizacion>(
                            value: tipo,
                            groupValue: _tipoSeleccionado,
                            onChanged: (v) {
                              if (v != null)
                                setState(() => _tipoSeleccionado = v);
                            },
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            tipo.icon,
                            color:
                                isSelected
                                    ? cs.primary
                                    : cs.onSurface.withValues(alpha: 0.6),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tipo.titulo,
                                  style: TextStyle(
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                    fontSize: 13,
                                    color:
                                        isSelected ? cs.primary : cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tipo.descripcion,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withValues(alpha: 0.65),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _generando ? null : _generar,
                    icon:
                        _generando
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 18,
                            ),
                    label: const Text('Generar PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
