import 'package:flutter/material.dart';

import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

/// Una pestaña del módulo: nombre e icono.
class ItemPestana {
  const ItemPestana(this.titulo, this.icono);
  final String titulo;
  final IconData icono;
}

/// Barra de pestañas del módulo de Comisiones.
///
/// Vive fuera de la pantalla por dos razones. La primera es que eran cuarenta
/// líneas de estilo incrustadas en medio del árbol de la pantalla. La segunda
/// es que la pantalla necesita sesión, permisos y providers para levantarse, y
/// eso hacía imposible mirar la barra sin backend; acá la vista previa monta
/// esta misma clase, no una copia parecida que después se desincroniza.
class BarraPestanas extends StatelessWidget {
  const BarraPestanas({super.key, required this.items});

  final List<ItemPestana> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      child: TabBar(
        // Desplazable siempre, no solo en móvil: con ocho pestañas el reparto
        // equitativo obliga a recortar los nombres largos incluso en un
        // portátil.
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        // Pastilla en vez del subrayado por defecto. Con ocho pestañas
        // desplazables, una raya de 2px es lo primero que se pierde al mirar
        // de reojo: hay que buscar dónde está parado uno. La pastilla se ve
        // sin buscarla.
        labelColor: cs.onPrimary,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicatorPadding: const EdgeInsets.symmetric(
          vertical: ComisionesTema.esp2,
        ),
        // primary y no primaryContainer: contra el fondo de la barra, el
        // container queda en 1,23:1 en claro y 1,99:1 en oscuro, o sea que la
        // pastilla apenas se despega. Con primary son 6,13:1 y 10,89:1.
        indicator: BoxDecoration(
          color: cs.primary,
          borderRadius: ComisionesTema.brControl,
        ),
        splashBorderRadius: ComisionesTema.brControl,
        // El hover tiene que resolverse distinto sobre la pestania activa:
        // con la pastilla ya en primary, un velo de primary encima da 1,000:1
        // exacto, o sea ningun cambio visible al pasar el mouse.
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
              // El nombre va SIEMPRE, también en móvil. Antes ahí solo se veía
              // el icono y el nombre vivía en un tooltip; en un teléfono no hay
              // hover, así que el usuario tenía que adivinar entre ocho iconos
              // parecidos.
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
