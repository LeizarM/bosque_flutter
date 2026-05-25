import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_constants.dart';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CHIP DE ESTADO
// ══════════════════════════════════════════════════════════════════════════════
class AnticiposEstadoChip extends StatelessWidget {
  final String estado;
  const AnticiposEstadoChip({super.key, required this.estado});

  @override
  Widget build(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final cfg = eCfg(estado, isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.icon, size: 11, color: cfg.fg),
          const SizedBox(width: 4),
          Text(
            estado,
            style: TextStyle(
              fontSize: 10,
              color: cfg.fg,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
