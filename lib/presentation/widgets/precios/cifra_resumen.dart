/// Las piezas de resumen que comparten los pasos del asistente: la cifra con su
/// franja de color y la variacion de un costo contra el vigente.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/precios/armado_lote_familias.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_detalle_piezas.dart';
import 'package:bosque_flutter/presentation/widgets/precios/tabla_propuestas.dart';

// Matices fijos, por la misma razon que las acciones de las propuestas
// ([AccionDePropuesta]): varias cifras juntas no se distinguen con los dos
// colores de la semilla. [tonosDeMatiz] los lleva al brillo del tema.
const Color matizAzul = Color(0xFF1E88E5);
const Color matizVioleta = Color(0xFF8E24AA);
const Color matizVerde = Color(0xFF2E7D32);
const Color matizNaranja = Color(0xFFF4511E);

IconData iconoVariacion(double v) {
  if (v.abs() < 0.05) return Icons.trending_flat_rounded;
  return v > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded;
}

/// Una cifra del resumen: rotulo, valor grande y detalle, con una franja del
/// color que la identifica.
class CifraResumen extends StatelessWidget {
  const CifraResumen({
    super.key,
    required this.compacto,
    required this.matiz,
    required this.icono,
    required this.rotulo,
    required this.valor,
    required this.detalle,
    this.colorValor,
  });

  final bool compacto;
  final Color matiz;
  final IconData icono;
  final String rotulo;
  final String valor;
  final String detalle;
  final Color? colorValor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = tonosDeMatiz(matiz, cs);

    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rotulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        Text(
          valor,
          maxLines: 1,
          style: (compacto ? tt.titleMedium : tt.titleLarge)?.copyWith(
            fontWeight: Peso.dato,
            fontFeatures: cifrasTabulares,
            color: colorValor ?? cs.onSurface,
          ),
        ),
        Text(
          detalle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // La franja de color identifica la cifra sin ocupar el ancho que
            // en el telefono no sobra. Es un hijo y no un borde izquierdo: un
            // borde de un solo lado no admite esquinas redondeadas.
            Container(width: 4, color: t.icono),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(compacto ? Esp.s : Esp.m),
                child:
                    compacto
                        ? textos
                        : Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: t.fondo,
                                borderRadius: BorderRadius.circular(
                                  Esquina.chica,
                                ),
                              ),
                              child: Icon(icono, size: 22, color: t.icono),
                            ),
                            const SizedBox(width: Esp.m),
                            Expanded(child: textos),
                          ],
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La variacion de un costo contra el vigente, con flecha y color: sube en el
/// color de error, baja en el principal.
class CeldaVariacion extends StatelessWidget {
  const CeldaVariacion({super.key, required this.variacion});

  final double? variacion;

  @override
  Widget build(BuildContext context) {
    final v = variacion;
    if (v == null) return celdaNumero(context, '--');
    final color = colorVariacion(Theme.of(context).colorScheme, v);
    // Se achica en vez de desbordar: un costo de 2.000 contra uno de 100 es
    // "+1.900,0 %" y no entra en la columna.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconoVariacion(v), size: 16, color: color),
          const SizedBox(width: Esp.xs),
          celdaNumero(context, variacionLegible(v), fuerte: true, color: color),
        ],
      ),
    );
  }
}
