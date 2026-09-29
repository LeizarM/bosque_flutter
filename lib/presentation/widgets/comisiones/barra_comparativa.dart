import 'package:flutter/material.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

/// Cifra de cabecera: rótulo, número y una línea de contexto. Sin caja propia:
/// la caja la pone FranjaCifras una sola vez alrededor de todas, y la cifra
/// importante se distingue por color y tamaño.
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

/// Agrupa las cifras de cabecera en un solo bloque: las cifras de un período son
/// una unidad, así que se separan con reglas verticales en vez de recuadros.
class FranjaCifras extends StatelessWidget {
  const FranjaCifras({super.key, required this.cifras});

  final List<Widget> cifras;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (cifras.isEmpty) return const SizedBox.shrink();

    // En teléfono las reglas verticales darían tres columnas de <100px y el importe
    // se cortaría; apiladas, cada cifra usa el ancho completo.
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
