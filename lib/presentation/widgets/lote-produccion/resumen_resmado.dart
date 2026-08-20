/// El resumen del periodo en "Ver resmado": cuanto se resmo, quien lo hizo y
/// cuanto falta imputar.
///
/// La grilla anterior contestaba una sola pregunta —que resmados hay— y dejaba
/// las otras dos, que son las que se miran todos los dias, para hacerlas a
/// mano: cuanto salio en el mes y cuanto de eso todavia no tiene orden de
/// fabricacion.
///
/// El color va por grupo y sale de la rampa medida de `tokens_bosque`, la misma
/// que usa el cronograma de permisos: familia + tono, y solo las familias que se
/// separan con las nueve semillas del tema. Un color propio se veria roto en
/// cuanto alguien pase la app a violeta.
library;

import 'package:bosque_flutter/core/state/ver_resmado_provider.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/lote-produccion/balance_lote.dart';
import 'package:flutter/material.dart';

/// El color de un grupo de resmado. Se indexa por `idGrupo` y no por su
/// posicion en la lista para que el color no cambie al cambiar de periodo.
ColorDeEstado colorDeGrupo(ColorScheme cs, int idGrupo) =>
    colorDeCatalogo(cs, idGrupo - 1);

/// El punto de color que identifica al grupo en la tabla y en las tarjetas.
class PuntoGrupo extends StatelessWidget {
  const PuntoGrupo({super.key, required this.idGrupo, required this.nombre});

  final int idGrupo;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final color = colorDeGrupo(Theme.of(context).colorScheme, idGrupo);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.fondo,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: Esp.s),
        Flexible(
          child: Text(
            nombre.isEmpty ? 'Sin grupo' : nombre,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
          ),
        ),
      ],
    );
  }
}

/// Cuanto se resmo en el periodo, repartido por grupo.
class ResumenDelPeriodo extends StatelessWidget {
  const ResumenDelPeriodo({
    super.key,
    required this.total,
    required this.grupos,
    required this.sinOrden,
    required this.aire,
    required this.onVerSinOrden,
  });

  final double total;
  final List<ResumenGrupo> grupos;
  final int sinOrden;
  final Aire aire;
  final VoidCallback onVerSinOrden;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(Esp.l),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resmado del periodo', style: context.apagado()),
                    SizedBox(height: Esp.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          fmtNumero.format(total),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: Peso.dato,
                                fontFeatures: cifrasTabulares,
                              ),
                        ),
                        SizedBox(width: Esp.s),
                        Text('resmas', style: context.apagado()),
                      ],
                    ),
                  ],
                ),
              ),
              if (sinOrden > 0) _AvisoSinOrden(cantidad: sinOrden, onVer: onVerSinOrden),
            ],
          ),

          if (grupos.isNotEmpty && total > 0) ...[
            SizedBox(height: Esp.l),
            _BarraPorGrupo(grupos: grupos, total: total),
            SizedBox(height: Esp.m),
            _Leyenda(grupos: grupos, total: total, aire: aire),
          ],
        ],
      ),
    );
  }
}

/// La barra apilada: cada grupo ocupa lo que resmo.
class _BarraPorGrupo extends StatelessWidget {
  const _BarraPorGrupo({required this.grupos, required this.total});

  final List<ResumenGrupo> grupos;
  final double total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(Esquina.chica),
      child: SizedBox(
        height: 16,
        child: Row(
          children: [
            for (final g in grupos)
              if (g.total > 0)
                Expanded(
                  flex: (g.total / total * 1000).round().clamp(1, 1000),
                  child: Tooltip(
                    message:
                        '${g.nombre}: ${fmtNumero.format(g.total)} resmas '
                        'en ${g.cantidad} registro${g.cantidad == 1 ? "" : "s"}',
                    child: ColoredBox(
                      color: colorDeGrupo(cs, g.idGrupo).fondo,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({
    required this.grupos,
    required this.total,
    required this.aire,
  });

  final List<ResumenGrupo> grupos;
  final double total;
  final Aire aire;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: Esp.xl,
      runSpacing: Esp.s,
      children: [
        for (final g in grupos)
          SizedBox(
            width: aire.esChico ? 140 : 170,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorDeGrupo(cs, g.idGrupo).fondo,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                SizedBox(width: Esp.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.nombre,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${fmtNumero.format(g.total)}  ·  '
                        '${(g.total / total * 100).round()}%',
                        style: context.numero(fuerte: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Lo que falta imputar, con el atajo para aislarlo.
///
/// Es el trabajo pendiente de esta pantalla, asi que no alcanza con contarlo:
/// tiene que llevar a los registros.
class _AvisoSinOrden extends StatelessWidget {
  const _AvisoSinOrden({required this.cantidad, required this.onVer});

  final int cantidad;
  final VoidCallback onVer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.tertiaryContainer,
      borderRadius: BorderRadius.circular(Esquina.chica),
      child: InkWell(
        onTap: onVer,
        borderRadius: BorderRadius.circular(Esquina.chica),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pending_actions,
                size: 18,
                color: cs.onTertiaryContainer,
              ),
              SizedBox(width: Esp.s),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$cantidad sin orden',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onTertiaryContainer,
                      fontWeight: Peso.dato,
                      fontFeatures: cifrasTabulares,
                    ),
                  ),
                  Text(
                    'Ver solo esos',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
