import 'package:bosque_flutter/core/state/anticipo_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ══════════════════════════════════════════════════════════════════════════════
// APP BAR
// ══════════════════════════════════════════════════════════════════════════════
class AnticiposAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final AnticipoState st;
  final AnticipoNotifier ntf;
  const AnticiposAppBar({super.key, required this.st, required this.ntf});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final cs = Theme.of(ctx).colorScheme;
    return AppBar(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded, size: 20),
          const SizedBox(width: 10),
          const Text(
            'Anticipos',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          if (st.totalRegistros > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.onPrimary.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${st.totalRegistros}',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        Tooltip(
          message: 'Actualizar lista',
          child: IconButton(
            icon: AnimatedRotation(
              turns: st.cargando ? 1 : 0,
              duration: const Duration(milliseconds: 600),
              child: const Icon(Icons.refresh_rounded),
            ),
            onPressed: ntf.cargar,
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
