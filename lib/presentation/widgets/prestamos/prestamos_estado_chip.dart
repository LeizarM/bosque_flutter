import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_constants.dart';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ESTADO CHIP
// ══════════════════════════════════════════════════════════════════════════════
class PrestamosEstadoChip extends StatelessWidget {
  final String estado;

  const PrestamosEstadoChip({super.key, required this.estado});

  @override
  Widget build(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final cfg = eCfg(estado, isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cfg.bg,
        border: Border.all(color: cfg.fg.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.icon, color: cfg.fg, size: 12),
          const SizedBox(width: 4),
          Text(
            cfg.label,
            style: TextStyle(
              color: cfg.fg,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
