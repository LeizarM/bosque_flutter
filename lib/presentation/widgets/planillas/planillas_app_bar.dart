import 'package:bosque_flutter/core/state/planilla_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlanillasAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final PlanillaState st;
  final PlanillaNotifier ntf;

  const PlanillasAppBar({super.key, required this.st, required this.ntf});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final cs = Theme.of(ctx).colorScheme;
    final bool isBusy = st.cargando || st.generando;

    return AppBar(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.request_quote_rounded, size: 20),
          const SizedBox(width: 10),
          const Text(
            'Planillas',
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
              turns: isBusy ? 1 : 0,
              duration: const Duration(milliseconds: 600),
              child: const Icon(Icons.refresh_rounded),
            ),
            onPressed: isBusy
                ? null
                : () {
                    final now = DateTime.now();
                    final isCurrentPeriod =
                        st.mes == now.month.toString() &&
                        st.anio == now.year.toString();

                    if (isCurrentPeriod) {
                      final uid = ref.read(userProvider)?.codUsuario ?? 0;
                      ntf.generarPlanilla(uid);
                    } else {
                      ntf.cargar();
                    }
                  },
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

