import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/prestamo_provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MODELO UNIFICADO
// ══════════════════════════════════════════════════════════════════════════════

/// Modelo unificado para asignaciones de préstamo.
/// - Para Préstamos Manuales: [empleadoEntity] viene poblado.
/// - Para Préstamos SAP: [empleadoEntity] es null, se usan los campos
///   escalares directamente.
class PrestamoEmpleadoData {
  final int codEmpleado;
  final String datoPersona;
  int codPrestamo;
  String tipo;
  double monto;
  double montoCalculado;
  String tipoEstado;

  /// Solo disponible en el formulario Manual
  final EmpleadoEntity? empleadoEntity;

  PrestamoEmpleadoData({
    required this.codEmpleado,
    required this.datoPersona,
    this.codPrestamo = 0,
    this.tipo = 'A',
    this.monto = 0.0,
    this.montoCalculado = 0.0,
    this.tipoEstado = 'PEN',
    this.empleadoEntity,
  });

  /// Constructor de conveniencia para el sheet Manual (a partir de EmpleadoEntity)
  factory PrestamoEmpleadoData.fromEmpleado(EmpleadoEntity emp) {
    return PrestamoEmpleadoData(
      codEmpleado: emp.codEmpleado,
      datoPersona: emp.persona.datoPersona ?? '',
      empleadoEntity: emp,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET: Fila de Tipo (Auto/Fijo) + Campo de Monto
// ══════════════════════════════════════════════════════════════════════════════
class PrestamoTipoMontoRow extends StatelessWidget {
  final String tipo;
  final TextEditingController montoController;
  final void Function(String, double) onUpdate;
  const PrestamoTipoMontoRow({
    super.key,
    required this.tipo,
    required this.montoController,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final brd = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        children: [
          SizedBox(
            height: 28,
            width: 112,
            child: DropdownButtonFormField<String>(
              value: tipo,
              isExpanded: true,
              isDense: true,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                filled: true,
                fillColor: cs.surface,
                border: brd,
                enabledBorder: brd,
              ),
              style: TextStyle(fontSize: 11, color: cs.onSurface),
              items: const [
                DropdownMenuItem(value: 'A', child: Text('Automático')),
                DropdownMenuItem(value: 'F', child: Text('Fijo')),
              ],
              onChanged: (v) {
                if (v != null) {
                  onUpdate(v, double.tryParse(montoController.text) ?? 0);
                }
              },
            ),
          ),
          if (tipo == 'F') ...[
            const SizedBox(width: 6),
            Expanded(
              child: SizedBox(
                height: 28,
                child: TextField(
                  controller: montoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  style: const TextStyle(fontSize: 11),
                  decoration: InputDecoration(
                    hintText: 'Monto Bs.',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: cs.outline.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  onChanged: (v) => onUpdate('F', double.tryParse(v) ?? 0),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET: Tile de Empleado Seleccionado (Diseño Compacto v2)
// ══════════════════════════════════════════════════════════════════════════════
class PrestamoEmpleadoSeleccionadoTile extends StatelessWidget {
  final PrestamoEmpleadoData asig;
  final TextEditingController montoController;
  final VoidCallback onDelete;
  final void Function(String, double) onUpdate;
  final double numCuotas;

  /// Callback opcional para el botón "Cambiar empleado" (solo Sheet SAP).
  /// Si es null, el botón no se muestra (Sheet Manual).
  final VoidCallback? onSwap;
  final bool isSwapping;

  const PrestamoEmpleadoSeleccionadoTile({
    super.key,
    required this.asig,
    required this.montoController,
    required this.onDelete,
    required this.onUpdate,
    required this.numCuotas,
    this.onSwap,
    this.isSwapping = false,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.18),
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.25)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: cs.primary,
            child: Icon(Icons.person_rounded, size: 12, color: cs.onPrimary),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              asig.datoPersona,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Tooltip(
            message:
                asig.tipo == 'A'
                    ? 'Cambiar a cuota fija'
                    : 'Cambiar a cuota automática',
            child: InkWell(
              onTap: () {
                final newTipo = asig.tipo == 'A' ? 'F' : 'A';
                onUpdate(newTipo, asig.monto);
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: asig.tipo == 'A' ? cs.primaryContainer : cs.tertiaryContainer,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: asig.tipo == 'A'
                        ? cs.primary.withValues(alpha: 0.4)
                        : cs.tertiary.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  asig.tipo == 'A' ? 'AUTO.' : 'FIJO',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: asig.tipo == 'A' ? cs.onPrimaryContainer : cs.onTertiaryContainer,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 80,
            child:
                asig.tipo == 'F'
                    ? TextField(
                      controller: montoController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        hintText: 'Monto',
                        filled: true,
                        fillColor: cs.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                      ),
                      onChanged: (v) => onUpdate('F', double.tryParse(v) ?? 0),
                    )
                    : Text(
                      'Bs.${asig.montoCalculado.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    ),
          ),
          if (onSwap != null)
            Tooltip(
              message: 'Reemplazar empleado',
              child: InkWell(
                onTap: onSwap,
                child: Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    size: 14,
                    color: isSwapping ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          Tooltip(
            message: 'Quitar de la lista',
            child: InkWell(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ══════════════════════════════════════════════════════════════════════════════
// WIDGET: Selector de Fecha (reutilizable)
// ══════════════════════════════════════════════════════════════════════════════
class PrestamoFechaPickerField extends StatelessWidget {
  final String label;
  final DateTime? fecha;
  final void Function(DateTime) onChanged;
  final double fontSize;

  const PrestamoFechaPickerField({
    super.key,
    required this.label,
    required this.fecha,
    required this.onChanged,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
              context: ctx,
              initialDate: fecha ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2050),
            );
            if (date != null) onChanged(date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fecha == null
                      ? 'Seleccionar...'
                      : DateFormat('dd/MM/yyyy').format(fecha!),
                  style: TextStyle(
                    fontSize: fontSize,
                    color:
                        fecha == null
                            ? cs.onSurface.withValues(alpha: 0.5)
                            : cs.onSurface,
                  ),
                ),
                Icon(Icons.calendar_today_rounded, size: 16, color: cs.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET: Dropdown de Tipo de Pago (reutilizable)
// ══════════════════════════════════════════════════════════════════════════════
class PrestamoTipoPagoField extends ConsumerWidget {
  final String value;
  final void Function(String) onChanged;

  const PrestamoTipoPagoField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final cs = Theme.of(ctx).colorScheme;
    final tiposPagoAsync = ref.watch(tiposPagoPrestamoProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Pago',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 36,
          child: DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            style: TextStyle(fontSize: 12, color: cs.onSurface),
            items: tiposPagoAsync.maybeWhen(
              data:
                  (tipos) =>
                      tipos.map((t) {
                        return DropdownMenuItem(
                          value: t.codTipos,
                          child: Text(t.nombre),
                        );
                      }).toList(),
              orElse:
                  () => [
                    const DropdownMenuItem(
                      value: 'PLAN',
                      child: Text('PLANILLA'),
                    ),
                    const DropdownMenuItem(
                      value: 'CONT',
                      child: Text('AL CONTADO'),
                    ),
                  ],
            ),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET: Header Unificado para el Dialog (Diseño v2)
// ══════════════════════════════════════════════════════════════════════════════
class PrestamoDialogHeader extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icon;

  const PrestamoDialogHeader({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icon,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.4,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  subtitulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(ctx).pop(),
            icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
            style: IconButton.styleFrom(
              backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET: Progreso Circular de Monto
// ══════════════════════════════════════════════════════════════════════════════
class PrestamoMontoProgress extends StatelessWidget {
  final double montoTotal;
  final double montoAsignado;

  const PrestamoMontoProgress({
    super.key,
    required this.montoTotal,
    required this.montoAsignado,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final percent = (montoTotal > 0 ? montoAsignado / montoTotal : 0.0).clamp(
      0.0,
      1.0,
    );
    final excede = montoAsignado > montoTotal + 0.01;
    final color = excede ? cs.error : cs.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (excede ? cs.errorContainer : cs.primaryContainer).withValues(alpha: 0.5),
            cs.primaryContainer.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: percent),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder:
                      (context, value, _) => CircularProgressIndicator(
                        value: value,
                        strokeWidth: 4,
                        strokeCap: StrokeCap.round,
                        backgroundColor: cs.surface.withValues(alpha: 0.6),
                        color: color,
                      ),
                ),
                Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bs. ${montoAsignado.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  excede
                      ? 'Excede por Bs. ${(montoAsignado - montoTotal).toStringAsFixed(2)}'
                      : 'de Bs. ${montoTotal.toStringAsFixed(0)} · quedan Bs. ${(montoTotal - montoAsignado).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: excede ? cs.error : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
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

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET: Acciones Footer Unificadas
// ══════════════════════════════════════════════════════════════════════════════
class PrestamoFooterActions extends StatelessWidget {
  final bool puedeConfirmar;
  final bool isCargando;
  final String labelConfirmar;
  final VoidCallback onConfirmar;

  const PrestamoFooterActions({
    super.key,
    required this.puedeConfirmar,
    required this.isCargando,
    required this.labelConfirmar,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: isCargando ? null : () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: (!puedeConfirmar || isCargando) ? null : onConfirmar,
            icon:
                isCargando
                    ? Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(right: 4),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                    : const Icon(Icons.check_circle_rounded, size: 18),
            label: Text(
              isCargando ? 'Procesando...' : labelConfirmar,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
