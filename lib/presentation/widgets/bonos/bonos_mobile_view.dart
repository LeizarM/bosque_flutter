import 'package:bosque_flutter/core/state/bono_provider.dart';
import 'package:bosque_flutter/presentation/widgets/bonos/bonos_beneficiarios_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/bonos/bonos_pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bosque_flutter/presentation/widgets/bonos/bonos_constants.dart';

class BonosMobileView extends StatelessWidget {
  final BonoState st;
  final BonoNotifier ntf;

  const BonosMobileView({super.key, required this.st, required this.ntf});

  @override
  Widget build(BuildContext context) {
    if (st.cargando && st.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (st.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 60,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron bonos',
              style: TextStyle(color: Colors.grey.withValues(alpha: 0.8)),
            ),
          ],
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final fmtMonto = NumberFormat.currency(
      locale: 'es_BO',
      symbol: 'Bs',
      decimalDigits: 2,
    );
    final fmtDate = DateFormat('dd/MM/yyyy');

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: st.items.length,
            itemBuilder: (context, i) {
              final item = st.items[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.descripcion,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final isDark =
                                  Theme.of(context).brightness ==
                                  Brightness.dark;
                              final cfg = eCfgBono(item.estado, isDark);
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: cfg.bg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(cfg.icon, size: 14, color: cfg.fg),
                                    const SizedBox(width: 4),
                                    Text(
                                      cfg.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: cfg.fg,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Tipo: ${item.tipoBono}'),
                      Text(
                        'Total: ${fmtMonto.format(item.montoTotal)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                      if (item.fechaEjecucion != null)
                        Text(
                          'Fecha Ejecución: ${fmtDate.format(item.fechaEjecucion!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      if (item.fechaCreacion != null)
                        Text(
                          'Fecha Creación: ${fmtDate.format(item.fechaCreacion!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder:
                                  (_) => BonosBeneficiariosDialog(bono: item),
                            );
                          },
                          icon: const Icon(Icons.people_alt, size: 18),
                          label: const Text('Ver Beneficiarios'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        BonosPaginationBar(st: st, ntf: ntf),
      ],
    );
  }
}
