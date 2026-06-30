import 'package:bosque_flutter/core/state/bono_provider.dart';
import 'package:bosque_flutter/domain/entities/bono_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class BonosBeneficiariosDialog extends ConsumerWidget {
  final BonoEntity bono;

  const BonosBeneficiariosDialog({super.key, required this.bono});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(bonoEmpleadoProvider(bono.codBono));
    final ntf = ref.read(bonoEmpleadoProvider(bono.codBono).notifier);
    final cs = Theme.of(context).colorScheme;
    final fmtMonto = NumberFormat.currency(
      locale: 'es_BO',
      symbol: 'Bs',
      decimalDigits: 2,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.stars, color: cs.primary, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Beneficiarios del Bono',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        bono.descripcion,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search and filters
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar empleado...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (val) {
                      ntf.buscar(val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                FilterChip(
                  label: const Text('Solo con bono'),
                  selected: st.soloBono == 1,
                  onSelected: (_) => ntf.toggleSoloBono(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table content
            Expanded(
              child:
                  st.cargando && st.items.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : st.items.isEmpty
                      ? const Center(
                        child: Text('No se encontraron beneficiarios.'),
                      )
                      : Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ListView.separated(
                            itemCount: st.items.length,
                            separatorBuilder:
                                (_, __) => Divider(
                                  height: 1,
                                  color: cs.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                            itemBuilder: (context, index) {
                              final emp = st.items[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: cs.primaryContainer,
                                  child: Text(
                                    '${emp.fila}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  emp.nombreCompleto,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.secondaryContainer.withValues(
                                      alpha: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    fmtMonto.format(emp.monto),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
            ),

            // Pagination inside dialog
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total registros: ${st.totalRegistros}',
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
                ),
                Row(
                  children: [
                    Text('Página ${st.pagina} de ${st.totalPaginas}'),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed:
                          st.pagina > 1
                              ? () => ntf.cambiarPagina(st.pagina - 1)
                              : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed:
                          st.pagina < st.totalPaginas
                              ? () => ntf.cambiarPagina(st.pagina + 1)
                              : null,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
