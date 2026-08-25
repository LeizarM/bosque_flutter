import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/data/repositories/prestamo_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';

Future<void> showPrestamosReportesDialog(
  BuildContext context,
  String tipoReporte,
) async {
  return showDialog(
    context: context,
    builder: (ctx) => _ReportesPrestamosDialog(tipoReporte: tipoReporte),
  );
}

Future<void> generarReporteGlobalDirecto(
  BuildContext context,
  String tipoReporte,
) async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Generando reporte...'),
      duration: Duration(seconds: 1),
    ),
  );
  try {
    final repo = PrestamoImpl();
    Uint8List bytes;
    switch (tipoReporte) {
      case 'mayor_global_resumido':
        bytes = await repo.getReporteMayorGlobalResumido({});
        break;
      case 'global_detallado':
        bytes = await repo.getReporteGlobalDetallado({});
        break;
      case 'corto_largo_plazo':
        bytes = await repo.getReporteCortoLargoPlazo({});
        break;
      default:
        throw Exception('Reporte no soportado para generación directa');
    }

    if (!context.mounted) return;
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Reporte_$tipoReporte',
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al generar: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class _ReportesPrestamosDialog extends ConsumerStatefulWidget {
  final String tipoReporte;

  const _ReportesPrestamosDialog({required this.tipoReporte});

  @override
  ConsumerState<_ReportesPrestamosDialog> createState() =>
      _ReportesPrestamosDialogState();
}

class _ReportesPrestamosDialogState
    extends ConsumerState<_ReportesPrestamosDialog> {
  DateTime _fechaDesde = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _fechaHasta = DateTime.now();
  int? _codEmpleado;
  EmpleadoEntity? _empleadoSeleccionado;
  bool _generando = false;

  String get _tituloReporte {
    switch (widget.tipoReporte) {
      case 'personal':
        return 'Préstamos Personal';
      case 'mayor_global_resumido':
        return 'Mayor Global Resumido';
      case 'global_detallado':
        return 'Global Detallado';
      case 'corto_largo_plazo':
        return 'Corto y Largo Plazo';
      case 'mayor_general':
        return 'Mayor General';
      default:
        return 'Reporte';
    }
  }

  bool get _requiereFechas {
    return widget.tipoReporte == 'personal' ||
        widget.tipoReporte == 'mayor_general';
  }

  bool get _requiereEmpleado {
    return widget.tipoReporte == 'personal';
  }

  Future<void> _generarReporte() async {
    setState(() => _generando = true);
    try {
      final repo = PrestamoImpl();
      final DateFormat df = DateFormat('yyyy-MM-dd');

      final params = <String, dynamic>{
        'fechaDesde': df.format(_fechaDesde),
        'fechaHasta': df.format(_fechaHasta),
        if (_requiereEmpleado && _codEmpleado != null)
          'codEmpleado': _codEmpleado,
      };

      Uint8List bytes;
      switch (widget.tipoReporte) {
        case 'personal':
          bytes = await repo.getReportePersonal(params);
          break;
        case 'mayor_global_resumido':
          bytes = await repo.getReporteMayorGlobalResumido(params);
          break;
        case 'global_detallado':
          bytes = await repo.getReporteGlobalDetallado(params);
          break;
        case 'corto_largo_plazo':
          bytes = await repo.getReporteCortoLargoPlazo(params);
          break;
        case 'mayor_general':
          bytes = await repo.getReporteMayorGeneral(params);
          break;
        default:
          throw Exception('Reporte desconocido');
      }

      if (!mounted) return;
      Navigator.of(context).pop();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'Reporte_${widget.tipoReporte}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  Future<void> _seleccionarFecha(bool isDesde) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDesde ? _fechaDesde : _fechaHasta,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDesde) {
          _fechaDesde = picked;
        } else {
          _fechaHasta = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.picture_as_pdf_rounded, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            _tituloReporte,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_requiereFechas) ...[
              Row(
                children: [
                  Expanded(
                    child: _FechaField(
                      label: 'Desde',
                      fecha: _fechaDesde,
                      onTap: () => _seleccionarFecha(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FechaField(
                      label: 'Hasta',
                      fecha: _fechaHasta,
                      onTap: () => _seleccionarFecha(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (_requiereEmpleado) ...[
              DropdownSearch<EmpleadoEntity>(
                selectedItem: _empleadoSeleccionado,
                asyncItems: (text) async {
                  final items = await ref.read(
                    getListaEmpleados((
                      text.isEmpty ? null : text,
                      1, // activos
                      1,
                      200, // limite
                      null, // de todas las empresas
                    )).future,
                  );
                  return items;
                },
                itemAsString: (e) => e.persona.datoPersona ?? '',
                compareFn: (a, b) => a.codEmpleado == b.codEmpleado,
                onChanged: (emp) {
                  setState(() {
                    _empleadoSeleccionado = emp;
                    _codEmpleado = emp?.codEmpleado;
                  });
                },
                clearButtonProps: const ClearButtonProps(isVisible: true),
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: 'Empleado (Opcional)',
                    hintText: 'Todos los empleados',
                    prefixIcon: Icon(Icons.person_search, color: cs.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                  ),
                ),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchDelay: const Duration(milliseconds: 300),
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Buscar empleado...',
                      prefixIcon: Icon(Icons.search, color: cs.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                  ),
                  emptyBuilder:
                      (context, searchEntry) => const Center(
                        child: Text('No se encontraron empleados'),
                      ),
                ),
              ),
            ],
            if (!_requiereFechas && !_requiereEmpleado)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Este reporte se generará con los datos globales.'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _generando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _generando ? null : _generarReporte,
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
                  : const Icon(Icons.print_rounded, size: 18),
          label: Text(_generando ? 'Generando...' : 'Generar PDF'),
        ),
      ],
    );
  }
}

class _FechaField extends StatelessWidget {
  final String label;
  final DateTime fecha;
  final VoidCallback onTap;

  const _FechaField({
    required this.label,
    required this.fecha,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final DateFormat df = DateFormat('dd/MM/yyyy');
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(df.format(fecha), style: const TextStyle(fontSize: 14)),
                Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
