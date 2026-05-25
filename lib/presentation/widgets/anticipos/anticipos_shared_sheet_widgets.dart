import 'package:bosque_flutter/domain/entities/anticipo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SHARED SHEET WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class AnticipoSheetHandle extends StatelessWidget {
  const AnticipoSheetHandle({super.key});

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 0),
      child: Row(
        children: [
          const SizedBox(width: 44), // contrabalance visual
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(ctx).pop(),
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: cs.onSurface.withOpacity(0.5),
            ),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }
}

class AnticipoSheetCabecera extends StatelessWidget {
  final AnticipoEntity cabecera;
  final String titulo;
  final IconData? icon;
  const AnticipoSheetCabecera({
    super.key,
    required this.cabecera,
    required this.titulo,
    this.icon,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withOpacity(isDark ? 0.25 : 0.1),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: cs.primary),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (cabecera.db.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: cs.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          cabecera.db,
                          style: TextStyle(
                            fontSize: 9,
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: cabecera.numAsiento),
                              );
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Asiento copiado'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Text(
                              cabecera.numAsiento,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (cabecera.referencia.isNotEmpty)
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: cabecera.referencia),
                                );
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nro. de documento copiado'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Text(
                                'Nro. Documento: ${cabecera.referencia}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: cs.primary.withOpacity(0.8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  cabecera.concepto,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.55),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Bs.',
                style: TextStyle(
                  fontSize: 9,
                  color: cs.onSurface.withOpacity(0.45),
                ),
              ),
              Text(
                fmtAnticipo.format(cabecera.debe),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark
                          ? Colors.greenAccent.shade200
                          : const Color(0xFF1B5E20),
                ),
              ),
              Text(
                fmtFechaAnticipo.format(cabecera.fechaAsiento),
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurface.withOpacity(0.45),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AnticipoMontoProgress extends StatelessWidget {
  final double montoTotal;
  final double montoAsignado;
  final bool cargando;
  final bool hayItems;
  final bool esperando;
  final String prefixLabel;
  const AnticipoMontoProgress({
    super.key,
    required this.montoTotal,
    required this.montoAsignado,
    required this.cargando,
    required this.hayItems,
    this.esperando = false,
    this.prefixLabel = 'Seleccionado',
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final dif = montoTotal - montoAsignado;
    final hayDif = dif.abs() > 0.01;
    final progreso =
        montoTotal > 0 ? (montoAsignado / montoTotal).clamp(0.0, 1.0) : 0.0;
    final color = hayDif ? Colors.orange.shade700 : Colors.green.shade700;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$prefixLabel: Bs. ${fmtAnticipo.format(montoAsignado)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              if (cargando)
                Text(
                  'Calculando…',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.primary,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else if (esperando && hayItems)
                Text(
                  'Esperando cálculo…',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.primary,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else if (hayDif && hayItems)
                Text(
                  dif > 0
                      ? 'Faltan Bs. ${fmtAnticipo.format(dif)}'
                      : 'Excede Bs. ${fmtAnticipo.format(-dif)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: dif > 0 ? Colors.orange.shade600 : cs.error,
                  ),
                )
              else if (!hayDif && hayItems)
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 12,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Monto exacto',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hayItems ? progreso : 0.0,
              minHeight: 5,
              backgroundColor: cs.outline.withOpacity(0.15),
              color:
                  progreso > 1.0
                      ? cs.error
                      : progreso == 1.0
                      ? Colors.green.shade600
                      : cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class AnticipoSheetSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  const AnticipoSheetSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder:
          (_, val, __) => TextField(
            controller: controller,
            onChanged: onChanged,
            style: TextStyle(fontSize: 13, color: cs.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.4),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 18,
                color: cs.primary,
              ),
              suffixIcon:
                  val.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.close, size: 15),
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                      )
                      : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              filled: true,
              fillColor: cs.primary.withOpacity(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          ),
    );
  }
}

class AnticipoSelectAllButton extends StatelessWidget {
  final bool allSelected;
  final bool enabled;
  final VoidCallback? onTap;
  const AnticipoSelectAllButton({
    super.key,
    required this.allSelected,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return Tooltip(
      message: allSelected ? 'Deseleccionar todos' : 'Seleccionar todos',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: allSelected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: allSelected ? cs.primary : cs.outline.withOpacity(0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                allSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
                size: 16,
                color: allSelected ? cs.onPrimary : cs.onSurface,
              ),
              const SizedBox(width: 4),
              Text(
                'Todos',
                style: TextStyle(
                  fontSize: 12,
                  color: allSelected ? cs.onPrimary : cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnticipoConfirmButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  const AnticipoConfirmButton({
    super.key,
    required this.enabled,
    required this.loading,
    required this.label,
    this.onPressed,
    this.icon = Icons.assignment_turned_in_outlined,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor:
                  (enabled && !loading)
                      ? cs.primary
                      : cs.outline.withOpacity(0.3),
              foregroundColor:
                  (enabled && !loading)
                      ? cs.onPrimary
                      : cs.onSurface.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            icon:
                loading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Icon(icon),
            label: Text(label),
            onPressed: (enabled && !loading) ? onPressed : null,
          ),
        ),
      ),
    );
  }
}

class AnticipoBaseSheet extends StatelessWidget {
  final double initialChildSize;
  final double maxChildSize;
  final double minChildSize;
  final Widget Function(BuildContext, ScrollController) builder;
  const AnticipoBaseSheet({
    super.key,
    this.initialChildSize = 0.75,
    this.maxChildSize = 0.95,
    this.minChildSize = 0.5,
    required this.builder,
  });

  @override
  Widget build(BuildContext ctx) => DraggableScrollableSheet(
    initialChildSize: initialChildSize,
    maxChildSize: maxChildSize,
    minChildSize: minChildSize,
    builder:
        (c, ctrl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: builder(c, ctrl),
        ),
  );
}

class AnticipoEmptyState extends StatelessWidget {
  final String mensaje;
  final IconData icon;
  const AnticipoEmptyState({
    super.key,
    required this.mensaje,
    this.icon = Icons.inbox_rounded,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: cs.outline.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class AnticipoSectionHeader extends StatelessWidget {
  final String label;
  const AnticipoSectionHeader({super.key, required this.label});

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: cs.primary.withOpacity(0.06),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: cs.primary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class AnticipoQuickTipoBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const AnticipoQuickTipoBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? cs.primary : cs.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: cs.primary.withOpacity(active ? 1 : 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: active ? cs.onPrimary : cs.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? cs.onPrimary : cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
