import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/prestamo_entity.dart';
import 'package:bosque_flutter/domain/entities/prestamo_detalle_entity.dart';
import 'package:bosque_flutter/core/state/prestamo_provider.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum PrestamoDialogModo { asignacionSap, edicionSap, manual }

class PrestamosAsignacionController extends ChangeNotifier {
  final PrestamoDialogModo modo;
  final double montoCabecera; // debe o haber del SAP

  PrestamosAsignacionController({
    required this.modo,
    required this.montoCabecera,
  });

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  // ── ESTADO ──
  final Map<int, PrestamoEmpleadoData> seleccionados = {};
  int? swapCodEmpleado;

  DateTime? fecIniPago;
  DateTime? fechaDesembolso = DateTime.now();
  int? codEmpresa;
  String tipoPagoGlobal = 'PLAN';
  bool isMontoFijo = false;

  double numCuotas = 1;
  double montoManual = 0;
  String concepto = '';

  double montoCalculadoTotal = 0;
  bool esValido = false;

  // Estado del Preview
  List<PrestamoDetalleEntity>? cuotasPreview;
  bool isLoadingPreview = false;

  // ── GETTERS ──
  double get totalMonto =>
      modo == PrestamoDialogModo.manual ? montoManual : montoCabecera;

  double getActualCuotas(double montoPrestamo) {
    return isMontoFijo && numCuotas > 0
        ? (montoPrestamo / numCuotas)
        : numCuotas;
  }

  // ── MÉTODOS ──
  Future<void> cargarDatosEdicion(
    WidgetRef ref,
    PrestamoEntity cabecera,
  ) async {
    if (modo == PrestamoDialogModo.edicionSap) {
      final asignados = await ref.read(
        prestamoEmpleadosAsignadosProvider((
          codEmpresa: cabecera.codEmpresa,
          db: cabecera.db,
          transIdSAP: int.tryParse(cabecera.numAsiento) ?? 0,
          codPrestamo: cabecera.codPrestamo,
        )).future,
      );

      if (asignados.isNotEmpty) {
        fecIniPago = DateFormat(
          'yyyy-MM-dd',
        ).parse(asignados.first.fecIniPago ?? '');
        numCuotas = (asignados.first.numCuotas ?? 1).toDouble();
        tipoPagoGlobal = asignados.first.tipoPago ?? 'PLAN';

        for (final asig in asignados) {
          if (asig.codEmpleado != null) {
            seleccionados[asig.codEmpleado!] = PrestamoEmpleadoData(
              codEmpleado: asig.codEmpleado!,
              datoPersona: asig.nombreEmpleadoAsignado ?? '',
              codPrestamo: asig.codPrestamo ?? 0,
              tipo: 'F',
              monto: asig.debe > 0 ? asig.debe : asig.haber,
              montoCalculado: asig.debe > 0 ? asig.debe : asig.haber,
              tipoEstado: asig.estadoPrestamo ?? 'PEN',
            );
          }
        }
      }
    } else if (modo == PrestamoDialogModo.manual) {
      tipoPagoGlobal = cabecera.tipoPago ?? 'PLAN';
      montoManual = cabecera.debe;
      concepto = cabecera.concepto;
      fechaDesembolso = cabecera.fechaAsiento;

      try {
        final detalles = await ref.read(
          prestamoDetallesProvider((
            codPrestamo: cabecera.codPrestamo!,
            mostrarAnulados: 0,
          )).future,
        );
        if (detalles.isNotEmpty) {
          numCuotas = detalles.length.toDouble();
          fecIniPago = detalles.first.fechaPago;
        } else {
          numCuotas = 1;
          fecIniPago = DateTime.now();
        }

        // Manual asume 1 empleado
        seleccionados[cabecera.codEmpleado!] = PrestamoEmpleadoData(
          codEmpleado: cabecera.codEmpleado!,
          datoPersona: cabecera.nombreEmpleadoAsignado ?? '',
          codPrestamo: cabecera.codPrestamo ?? 0,
          tipo: 'F',
          monto: cabecera.debe,
          montoCalculado: cabecera.debe,
          tipoEstado: cabecera.estadoPrestamo ?? 'PEN',
        );
      } catch (e) {
        debugPrint('Error al cargar detalles manual: $e');
        numCuotas = 1;
      }
    }
    recalcular();
  }

  void recalcular() {
    double sumaFijos = 0;
    int cantAutos = 0;

    for (final e in seleccionados.values) {
      if (e.tipo == 'F') {
        sumaFijos += e.monto;
      } else {
        cantAutos++;
      }
    }

    final montoRestante = totalMonto - sumaFijos;
    final montoAuto =
        cantAutos > 0
            ? (montoRestante > 0 ? montoRestante / cantAutos : 0.0)
            : 0.0;

    double totalCalc = 0;
    for (final e in seleccionados.values) {
      if (e.tipo == 'A') {
        e.montoCalculado = montoAuto;
      } else {
        e.montoCalculado = e.monto;
      }
      totalCalc += e.montoCalculado;
    }

    montoCalculadoTotal = totalCalc;

    if (modo == PrestamoDialogModo.manual) {
      esValido =
          seleccionados.isNotEmpty &&
          codEmpresa != null &&
          fechaDesembolso != null &&
          montoManual > 0 &&
          concepto.isNotEmpty &&
          (totalCalc - montoManual).abs() < 0.01;
    } else {
      esValido = (totalMonto - totalCalc).abs() < 0.01;
    }

    // Check si hay montos negativos
    if (seleccionados.values.any((e) => e.montoCalculado <= 0)) {
      esValido = false;
    }

    notifyListeners();
  }

  void toggle(EmpleadoEntity emp, bool sel) {
    if (sel) {
      seleccionados[emp.codEmpleado] = PrestamoEmpleadoData.fromEmpleado(emp);
    } else {
      seleccionados.remove(emp.codEmpleado);
    }
    recalcular();
  }

  void toggleTodos(List<EmpleadoEntity> empleados, bool sel) {
    for (final emp in empleados) {
      if (sel && !seleccionados.containsKey(emp.codEmpleado)) {
        seleccionados[emp.codEmpleado] = PrestamoEmpleadoData.fromEmpleado(emp);
      } else if (!sel) {
        seleccionados.remove(emp.codEmpleado);
      }
    }
    recalcular();
  }

  void onUpdate(int id, String tipo, double monto) {
    final asig = seleccionados[id];
    if (asig != null) {
      asig.tipo = tipo;
      asig.monto = monto;
    }
    recalcular();
  }

  void setAllTipo(String tipo) {
    for (final asig in seleccionados.values) {
      asig.tipo = tipo;
    }
    recalcular();
  }

  void setSwapCodEmpleado(int? id) {
    swapCodEmpleado = id;
    notifyListeners();
  }

  bool onEmployeeTap(EmpleadoEntity emp) {
    // Retorna true si hizo un swap exitoso
    if (swapCodEmpleado != null) {
      if (seleccionados.containsKey(emp.codEmpleado)) {
        return false; // Ya está
      }
      final oldData = seleccionados.remove(swapCodEmpleado);
      if (oldData != null) {
        seleccionados[emp.codEmpleado] = PrestamoEmpleadoData(
          codEmpleado: emp.codEmpleado,
          datoPersona: emp.persona.datoPersona ?? '',
          codPrestamo: oldData.codPrestamo,
          tipo: oldData.tipo,
          monto: oldData.monto,
          montoCalculado: oldData.montoCalculado,
          tipoEstado: oldData.tipoEstado,
        );
      }
      swapCodEmpleado = null;
      recalcular();
      return true;
    } else {
      if (!seleccionados.containsKey(emp.codEmpleado)) {
        seleccionados[emp.codEmpleado] = PrestamoEmpleadoData(
          codEmpleado: emp.codEmpleado,
          datoPersona: emp.persona.datoPersona ?? '',
          codPrestamo: 0,
        );
      }
      recalcular();
      return false;
    }
  }

  // ── UTILIDADES ──
  String generarXml() {
    final sb = StringBuffer();
    sb.writeln('<empleados>');

    final fechaStr =
        fecIniPago != null ? DateFormat('yyyy-MM-dd').format(fecIniPago!) : '';

    for (final e in seleccionados.values) {
      if (modo == PrestamoDialogModo.asignacionSap) {
        sb.writeln(
          '  <empleado codEmpleado="${e.codEmpleado}" '
          'tipo="${e.tipo}" monto="${e.montoCalculado}" tipoPago="$tipoPagoGlobal" />',
        );
      } else if (modo == PrestamoDialogModo.edicionSap) {
        final cuotas = getActualCuotas(e.montoCalculado);
        sb.writeln(
          '  <empleado codPrestamo="${e.codPrestamo}" codEmpleado="${e.codEmpleado}" '
          'tipo="${e.tipo}" monto="${e.montoCalculado}" '
          'fecIniPago="$fechaStr" numCuotas="$cuotas" tipoPago="$tipoPagoGlobal" tipoEstado="${e.tipoEstado}" />',
        );
      } else if (modo == PrestamoDialogModo.manual) {
        sb.writeln(
          '  <empleado codEmpleado="${e.codEmpleado}" '
          'tipo="${e.tipo}" monto="${e.montoCalculado}" />',
        );
      }
    }
    sb.writeln('</empleados>');
    return sb.toString();
  }

  static Future<void> ejecutarConManejoDuplicado({
    required BuildContext context,
    required Future<String> Function(int forzar) request,
    required VoidCallback onSuccess,
  }) async {
    try {
      final msg = await request(0);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700),
        );
        onSuccess();
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('DUPLICADO|')) {
        if (!context.mounted) return;
        final cleanMsg = errorMsg.split('DUPLICADO|').last.trim();
        final confirm = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Advertencia de Duplicado'),
                content: Text(cleanMsg),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Sí, guardar'),
                  ),
                ],
              ),
        );
        if (confirm == true && context.mounted) {
          try {
            final msg2 = await request(1);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg2),
                  backgroundColor: Colors.green.shade700,
                ),
              );
              onSuccess();
            }
          } catch (e2) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e2.toString()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
