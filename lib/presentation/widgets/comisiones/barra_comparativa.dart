import 'package:flutter/material.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

// BarraComparativa vivia aca y la usaba la vista de grafico del
// preliminar. Se quito al pasar el grafico a un ranking agrupado por
// vendedor: la fila nueva (_FilaVendedor) lleva puesto y desglose, que
// esta clase no contemplaba, y no quedo ningun otro llamador.

/// Tarjeta de una cifra: rótulo arriba, número grande abajo.
///
/// Una cifra de cabecera: rotulo, numero y una linea de contexto.
///
/// Antes era una caja con fondo, borde y radio. Tres cajas seguidas compiten
/// entre si y con la tabla de abajo, y el borde no comunica nada: no hay nada
/// que separar porque las tres cifras son del mismo bloque. Ahora la caja la
/// pone FranjaCifras una sola vez alrededor de todas, y aca queda el dato.
///
/// La cifra importante se distingue por color y tamano, no por tener recuadro.
class TarjetaCifra extends StatelessWidget {
  const TarjetaCifra({
    super.key,
    required this.rotulo,
    required this.valor,
    this.detalle,
    this.icono,
    this.destacada = false,
  });

  final String rotulo;
  final String valor;
  final String? detalle;
  final IconData? icono;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icono != null) ...[
              Icon(
                icono,
                size: 13,
                color: destacada ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: ComisionesTema.esp1 + 2),
            ],
            Flexible(
              child: Text(
                rotulo.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.labelSmall?.copyWith(
                  fontSize: 10.5,
                  letterSpacing: 0.9,
                  color: destacada ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: ComisionesTema.esp2),
        Text(
          valor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ComisionesTema.numeroGrande(context)?.copyWith(
            color: destacada ? cs.primary : cs.onSurface,
            fontSize: destacada ? 26 : 22,
          ),
        ),
        if (detalle != null) ...[
          const SizedBox(height: ComisionesTema.esp1),
          Text(
            detalle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// Agrupa las cifras de cabecera en un solo bloque.
///
/// Una caja alrededor de las tres en vez de tres cajas: las cifras de un
/// periodo son una unidad, y separarlas con recuadros sugiere que no lo son.
/// Las reglas verticales separan sin encerrar.
class FranjaCifras extends StatelessWidget {
  const FranjaCifras({super.key, required this.cifras});

  final List<Widget> cifras;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (cifras.isEmpty) return const SizedBox.shrink();

    // En un telefono las reglas verticales obligarian a tres columnas de menos
    // de 100px y el importe se cortaria; apiladas cada cifra tiene el ancho
    // completo.
    if (ComisionesTema.esMovil(context)) {
      return Container(
        decoration: ComisionesTema.contenedor(context),
        padding: const EdgeInsets.symmetric(
          horizontal: ComisionesTema.esp4,
          vertical: ComisionesTema.esp3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cifras.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: ComisionesTema.esp3,
                  ),
                  child: Divider(
                    height: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
              cifras[i],
            ],
          ],
        ),
      );
    }

    return IntrinsicHeight(
      child: Container(
        decoration: ComisionesTema.contenedor(context),
        padding: const EdgeInsets.symmetric(vertical: ComisionesTema.esp4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cifras.length; i++) ...[
              if (i > 0)
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: ComisionesTema.esp1,
                  endIndent: ComisionesTema.esp1,
                  color: cs.outlineVariant.withValues(alpha: 0.7),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ComisionesTema.esp5,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: cifras[i],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
