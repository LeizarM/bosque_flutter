import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tc_ancla_entity.dart';

/// El ancla del tipo de cambio de una empresa, SOLO PARA MIRAR.
///
/// tpr_tcAncla (reprecio nocturno automático) la escribe un proceso externo, no
/// la app: por eso no hay botón de edición. La bandera de "supera el umbral" es
/// informativa; la decisión de repreciar es del proceso nocturno.
class TarjetaTcAncla extends StatelessWidget {
  const TarjetaTcAncla({super.key, required this.ancla, this.compacta = false});

  final TcAnclaEntity ancla;

  /// En un telefono los datos van uno debajo del otro; con ancho, en bloques.
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final datos = <(String, String)>[
      ('Tipo de cambio ancla', ancla.tcAnclaLegible),
      ('Umbral de variación', ancla.umbralLegible),
      ('Fecha del ancla', ancla.fechaAnclaLegible),
      ('Último tipo de cambio', ancla.tcUltimoLegible),
      ('Variación acumulada', ancla.variacionLegible),
    ];

    return Container(
      padding: const EdgeInsets.all(Esp.l),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business_outlined, size: 18, color: cs.primary),
              const SizedBox(width: Esp.s),
              Expanded(
                child: Text(
                  ancla.tieneEmpresa ? ancla.companyDB : 'Empresa sin definir',
                  style: tt.titleSmall?.copyWith(fontWeight: Peso.dato),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Etiqueta(texto: ancla.estadoLegible, tono: _tono),
            ],
          ),
          const SizedBox(height: Esp.m),
          if (compacta)
            for (final (titulo, valor) in datos)
              Padding(
                padding: const EdgeInsets.only(bottom: Esp.s),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(titulo, style: context.apagado())),
                    const SizedBox(width: Esp.s),
                    Text(valor, style: context.numero(fuerte: true)),
                  ],
                ),
              )
          else
            Wrap(
              spacing: Esp.xl,
              runSpacing: Esp.m,
              children: [
                for (final (titulo, valor) in datos)
                  SizedBox(
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: context.apagado()),
                        const SizedBox(height: Esp.xs),
                        Text(
                          valor,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: Peso.dato,
                            fontFeatures: cifrasTabulares,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// El color sale del significado: la variacion pasada de umbral es algo para
  /// mirar -no un error de nadie-, y sin lectura todavia no hay nada que decir.
  TonoEtiqueta get _tono {
    if (!ancla.esAnclaSembrada || !ancla.tieneLecturaTc) {
      return TonoEtiqueta.neutro;
    }
    return ancla.superaUmbralVisual ? TonoEtiqueta.aviso : TonoEtiqueta.exito;
  }
}
