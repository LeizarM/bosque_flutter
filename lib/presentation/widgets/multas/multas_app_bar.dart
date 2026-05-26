import 'package:bosque_flutter/core/state/multa_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MultasAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final MultaState st;
  final MultaNotifier ntf;
  final int uid;
  const MultasAppBar({
    super.key,
    required this.st,
    required this.ntf,
    required this.uid,
  });

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
          const Icon(Icons.money_off_rounded, size: 20),
          const SizedBox(width: 10),
          const Text(
            'Multas',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          if (st.totalRegistros > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.onPrimary.withValues(alpha: 0.18),
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
