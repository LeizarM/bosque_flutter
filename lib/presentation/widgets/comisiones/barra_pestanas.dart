import 'package:flutter/material.dart';

import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

/// Una pestaña del módulo: nombre e icono.
class ItemPestana {
  const ItemPestana(this.titulo, this.icono);
  final String titulo;
  final IconData icono;
}

/// Barra de pestañas del módulo de Comisiones. Vive fuera de la pantalla para
/// poder mirarla sin backend (la pantalla necesita sesión, permisos y
/// providers): la vista previa monta esta misma clase, no una copia.
class BarraPestanas extends StatelessWidget {
  const BarraPestanas({super.key, required this.items});

  final List<ItemPestana> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      child: TabBar(
        // Desplazable siempre: con ocho pestañas el reparto equitativo recorta los
        // nombres largos incluso en un portátil.
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        // Pastilla en vez del subrayado: con ocho pestañas desplazables, una raya de
        // 2px se pierde al mirar de reojo; la pastilla se ve sin buscarla.
        labelColor: cs.onPrimary,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicatorPadding: const EdgeInsets.symmetric(
          vertical: ComisionesTema.esp2,
        ),
        // primary y no primaryContainer: contra el fondo de la barra, el
        // container queda en 1,23:1 en claro y 1,99:1 en oscuro; con primary son
        // 6,13:1 y 10,89:1.
        indicator: BoxDecoration(
          color: cs.primary,
          borderRadius: ComisionesTema.brControl,
        ),
        splashBorderRadius: ComisionesTema.brControl,
        // El hover se resuelve distinto sobre la pestaña activa: un velo de primary
        // sobre la pastilla en primary da 1,000:1, sin cambio visible.
        overlayColor: WidgetStateProperty.resolveWith(
          (estados) =>
              estados.contains(WidgetState.selected)
                  ? cs.onPrimary.withValues(alpha: 0.08)
                  : cs.primary.withValues(alpha: 0.06),
        ),
        labelPadding: const EdgeInsets.symmetric(
          horizontal: ComisionesTema.esp3,
        ),
        labelStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: Theme.of(context).textTheme.labelLarge,
        tabs: [
          for (final p in items)
            Tab(
              height: 52,
              // El nombre va SIEMPRE, también en móvil: sin hover no hay tooltip
              // y el usuario tendría que adivinar entre ocho iconos parecidos.
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(p.icono, size: 18),
                  const SizedBox(width: ComisionesTema.esp2),
                  Text(p.titulo),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
