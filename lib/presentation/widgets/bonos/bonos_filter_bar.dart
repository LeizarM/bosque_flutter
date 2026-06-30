import 'package:bosque_flutter/core/state/bono_provider.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_filter_bar.dart'; // For BosqueFiltroDropdown
import 'package:flutter/material.dart';

const Map<String, String> monthsMap = {
  '': 'TODOS',
  '1': 'ENERO',
  '2': 'FEBRERO',
  '3': 'MARZO',
  '4': 'ABRIL',
  '5': 'MAYO',
  '6': 'JUNIO',
  '7': 'JULIO',
  '8': 'AGOSTO',
  '9': 'SEPTIEMBRE',
  '10': 'OCTUBRE',
  '11': 'NOVIEMBRE',
  '12': 'DICIEMBRE',
};

class BonosFilterBar extends StatelessWidget {
  final BonoState st;
  final BonoNotifier ntf;
  final List<String> anios;
  final int uid;

  const BonosFilterBar({
    super.key,
    required this.st,
    required this.ntf,
    required this.anios,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // ── Mes ──
            _BonosFilterChip(
              label: 'MES',
              active: true,
              child: BosqueFiltroDropdown<String>(
                value: monthsMap.containsKey(st.mes) ? st.mes : '',
                items:
                    monthsMap.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) ntf.setFechaFiltro(mes: val);
                },
              ),
            ),
            const SizedBox(width: 8),

            // ── Año ──
            _BonosFilterChip(
              label: 'AÑO',
              active: true,
              child: BosqueFiltroDropdown<String>(
                value: st.anio,
                items:
                    anios
                        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                        .toList(),
                onChanged: (val) {
                  if (val != null) ntf.setFechaFiltro(anio: val);
                },
              ),
            ),

            // Spacer and Action Button
            const SizedBox(width: 24),
            _BonosFilterDivider(),
            const SizedBox(width: 24),

            FilledButton.icon(
              icon: const Icon(Icons.calculate, size: 18),
              label: const Text('Generar Bonos'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onPressed:
                  st.cargando || st.generando
                      ? null
                      : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (c) => AlertDialog(
                                title: const Text('Confirmar'),
                                content: const Text(
                                  '¿Estás seguro que deseas generar o recalcular los bonos para el periodo actual?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Generar'),
                                  ),
                                ],
                              ),
                        );
                        if (confirm == true) {
                          ntf.generarBono(uid);
                        }
                      },
            ),
          ],
        ),
      ),
    );
  }
}

/// Divisor vertical en la barra de filtros
class _BonosFilterDivider extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Container(
    height: 24,
    width: 1,
    color: Theme.of(ctx).colorScheme.outline.withValues(alpha: 0.3),
  );
}

/// Wrapper visual para cada filtro con label flotante
class _BonosFilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Widget child;
  const _BonosFilterChip({
    required this.label,
    required this.active,
    required this.child,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (active)
          Positioned(
            top: -5,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
