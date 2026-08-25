import 'package:bosque_flutter/core/state/prestamo_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_reportes_dialog.dart';

// ══════════════════════════════════════════════════════════════════════════════
// APP BAR
// ══════════════════════════════════════════════════════════════════════════════
class PrestamosAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final PrestamoState st;
  final PrestamoNotifier ntf;

  const PrestamosAppBar({super.key, required this.st, required this.ntf});

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
            'Préstamos',
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
        PopupMenuButton<String>(
          icon: const Icon(Icons.print_rounded),
          tooltip: 'Reportes de Préstamos',
          onSelected: (String value) {
            _manejarReporteSeleccionado(ctx, ref, value);
          },
          itemBuilder:
              (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'personal',
                  child: ListTile(
                    leading: Icon(Icons.person_search_rounded, size: 20),
                    title: Text('Préstamos Personal'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'mayor_global_resumido',
                  child: ListTile(
                    leading: Icon(Icons.summarize_rounded, size: 20),
                    title: Text('Mayor Global Resumido'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'global_detallado',
                  child: ListTile(
                    leading: Icon(Icons.list_alt_rounded, size: 20),
                    title: Text('Global Detallado'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'corto_largo_plazo',
                  child: ListTile(
                    leading: Icon(Icons.access_time_rounded, size: 20),
                    title: Text('Corto y Largo Plazo'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'mayor_general',
                  child: ListTile(
                    leading: Icon(Icons.account_balance_rounded, size: 20),
                    title: Text('Mayor General'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
        ),
        Tooltip(
          message: 'Actualizar lista',
          child: IconButton(
            icon: AnimatedRotation(
              turns: st.cargando ? 1 : 0,
              duration: const Duration(milliseconds: 600),
              child: const Icon(Icons.refresh_rounded),
            ),
            onPressed: () => ntf.cargar(pagina: 1),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _manejarReporteSeleccionado(
    BuildContext context,
    WidgetRef ref,
    String reporte,
  ) {
    if (reporte == 'personal' || reporte == 'mayor_general') {
      showPrestamosReportesDialog(context, reporte);
    } else {
      generarReporteGlobalDirecto(context, reporte);
    }
  }
}
