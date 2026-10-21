/// Las respuestas de una pregunta de la semana: cifras, cuántos eligieron cada
/// opción (`p_list_tcpe_PreguntaSemana` E) y quién respondió qué (R).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estadistica_semana_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_semana_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_respondio_semana_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';

Future<void> abrirRespuestasPreguntaSemana(BuildContext context, TcpePreguntaSemanaEntity pregunta) =>
    mostrarFormulario<void>(
      context,
      (completa) => MarcoFormulario(
        titulo: 'Respuestas',
        icono: Icons.how_to_vote_outlined,
        completa: completa,
        ancho: 760,
        acciones: [
          Builder(
            builder: (ctx) => FilledButton.tonal(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
          ),
        ],
        cuerpo: RespuestasPreguntaSemana(pregunta: pregunta),
      ),
    );

/// Letra de la opción en la hoja de respuestas: A, B, C…
String letraOpcion(int i) => String.fromCharCode(65 + (i % 26));

class RespuestasPreguntaSemana extends ConsumerWidget {
  const RespuestasPreguntaSemana({super.key, required this.pregunta});

  final TcpePreguntaSemanaEntity pregunta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cod = pregunta.codPreguntaSemana;
    final estadistica = ref.watch(tcpeEstadisticaSemanaProvider(cod));
    final respuestas = ref.watch(tcpeRespuestasSemanaProvider(cod));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(oGuion(pregunta.tituloMostrado ?? pregunta.titulo), style: context.apagado()),
        const SizedBox(height: Esp.xs),
        Text(oGuion(pregunta.pregunta), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: Esp.s),
        Wrap(
          spacing: Esp.s,
          runSpacing: Esp.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PastillaEstadoSemana(pregunta.estadoHoy),
            Text(plazoSemanaTexto(pregunta.fechaInicio, pregunta.fechaFin), style: context.apagado()),
          ],
        ),
        const SizedBox(height: Esp.l),
        respuestas.when(
          skipLoadingOnReload: true,
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => _Reintentar(error: e, onTap: () => ref.invalidate(tcpeRespuestasSemanaProvider(cod))),
          data: (filas) => _Cifras(filas: filas),
        ),
        const SizedBox(height: Esp.xl),
        Text('Cómo respondieron', style: context.tituloSeccion()),
        const SizedBox(height: Esp.s),
        estadistica.when(
          skipLoadingOnReload: true,
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => _Reintentar(error: e, onTap: () => ref.invalidate(tcpeEstadisticaSemanaProvider(cod))),
          data:
              (ops) => Column(
                children: [for (var i = 0; i < ops.length; i++) _BarraOpcion(letra: letraOpcion(i), opcion: ops[i])],
              ),
        ),
        const SizedBox(height: Esp.xl),
        Text('Quién respondió', style: context.tituloSeccion()),
        const SizedBox(height: Esp.s),
        respuestas.when(
          skipLoadingOnReload: true,
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data:
              (filas) =>
                  filas.isEmpty
                      ? Text('Todavía nadie respondió.', style: context.apagado())
                      : LayoutBuilder(
                        builder:
                            (context, r) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [for (final f in filas) _FilaRespondio(fila: f, ancha: r.maxWidth >= 600)],
                            ),
                      ),
        ),
      ],
    );
  }
}

/// `dd/mm/aaaa – dd/mm/aaaa`.
String plazoSemanaTexto(DateTime? desde, DateTime? hasta) => '${fechaCorta(desde)} – ${fechaCorta(hasta)}';

/// El estado de hoy de una pregunta de la semana como pastilla con icono.
class PastillaEstadoSemana extends StatelessWidget {
  const PastillaEstadoSemana(this.estado, {super.key});

  final EstadoPreguntaSemana estado;

  @override
  Widget build(BuildContext context) {
    final (texto, tono, icono) = switch (estado) {
      EstadoPreguntaSemana.vigente => ('Vigente', TonoExamen.principal, Icons.play_circle_outline),
      EstadoPreguntaSemana.programada => ('Programada', TonoExamen.secundario, Icons.schedule),
      EstadoPreguntaSemana.terminada => ('Terminada', TonoExamen.neutro, Icons.flag_outlined),
      EstadoPreguntaSemana.inactiva => ('Inactiva', TonoExamen.neutro, Icons.block),
      EstadoPreguntaSemana.desconocido => ('--', TonoExamen.neutro, null),
    };
    return PastillaExamen(texto: texto, tono: tono, icono: icono);
  }
}

class _Cifras extends StatelessWidget {
  const _Cifras({required this.filas});

  final List<TcpeRespondioSemanaEntity> filas;

  @override
  Widget build(BuildContext context) {
    final correctas = filas.where((f) => f.esCorrecta).length;
    return Wrap(
      spacing: Esp.m,
      runSpacing: Esp.s,
      children: [
        CifraExamen(
          valor: '${filas.length}',
          rotulo: filas.length == 1 ? 'respondió' : 'respondieron',
          icono: Icons.groups_outlined,
          tono: TonoExamen.secundario,
        ),
        CifraExamen(
          valor: '$correctas',
          rotulo: correctas == 1 ? 'acertó' : 'acertaron',
          icono: Icons.check_circle_outline,
          tono: TonoExamen.principal,
        ),
        CifraExamen(
          valor: filas.isEmpty ? '--' : '${(correctas * 100 / filas.length).round()} %',
          rotulo: 'de acierto',
          icono: Icons.percent,
          tono: TonoExamen.terciario,
        ),
      ],
    );
  }
}

class _BarraOpcion extends StatelessWidget {
  const _BarraOpcion({required this.letra, required this.opcion});

  final String letra;
  final TcpeEstadisticaSemanaEntity opcion;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final o = opcion;
    final p = (o.porcentaje / 100).clamp(0.0, 1.0);
    final color = o.esValido ? cs.primary : Color.alphaBlend(cs.onSurface.withValues(alpha: 0.35), cs.surface);
    return Semantics(
      label:
          '$letra: ${oGuion(o.opcionRspta)}${o.esValido ? ', correcta' : ''}. '
          '${o.veces} ${o.veces == 1 ? 'persona' : 'personas'}, ${porcentajeTexto(o.porcentaje)}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Esp.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BurbujaHoja(texto: letra, tamanio: 28, marca: o.esValido ? MarcaBurbuja.marcada : MarcaBurbuja.vacia),
            const SizedBox(width: Esp.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: Esp.s,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(oGuion(o.opcionRspta)),
                      if (o.esValido)
                        const PastillaExamen(texto: 'Correcta', tono: TonoExamen.principal, icono: Icons.check),
                    ],
                  ),
                  const SizedBox(height: Esp.xs),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Esquina.pastilla),
                          child: SizedBox(
                            height: 8,
                            child: Stack(
                              children: [
                                Positioned.fill(child: ColoredBox(color: cs.surfaceContainerHighest)),
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: p,
                                  heightFactor: 1,
                                  child: ColoredBox(color: color),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: Esp.s),
                      SizedBox(
                        width: 96,
                        child: Text(
                          '${o.veces} · ${porcentajeTexto(o.porcentaje)}',
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontFeatures: cifrasTabulares),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaRespondio extends StatelessWidget {
  const _FilaRespondio({required this.fila, required this.ancha});

  final TcpeRespondioSemanaEntity fila;
  final bool ancha;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = fila;
    final resultado = PastillaExamen(
      texto: f.esCorrecta ? 'Acertó' : 'No acertó',
      tono: f.esCorrecta ? TonoExamen.principal : TonoExamen.alerta,
      icono: f.esCorrecta ? Icons.check : Icons.close,
    );
    final persona = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(oGuion(f.nombreCompleto ?? f.login), style: const TextStyle(fontWeight: Peso.titulo)),
        if ((f.cargo ?? '').trim().isNotEmpty) Text(f.cargo!, style: context.apagado()),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Esp.s),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)))),
      child:
          ancha
              ? Row(
                children: [
                  Expanded(flex: 5, child: persona),
                  Expanded(flex: 4, child: Text(oGuion(f.opcionRspta), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  SizedBox(width: 112, child: Align(alignment: Alignment.centerLeft, child: resultado)),
                  SizedBox(
                    width: 120,
                    child: Text(fechaHora(f.fechaRespuesta), textAlign: TextAlign.end, style: context.apagado()),
                  ),
                ],
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Expanded(child: persona), resultado]),
                  const SizedBox(height: Esp.xs),
                  Text('Eligió: ${oGuion(f.opcionRspta)} · ${fechaHora(f.fechaRespuesta)}', style: context.apagado()),
                ],
              ),
    );
  }
}

class _Reintentar extends StatelessWidget {
  const _Reintentar({required this.error, required this.onTap});

  final Object error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Icons.cloud_off_outlined, size: 20, color: Theme.of(context).colorScheme.error),
      const SizedBox(width: Esp.s),
      Expanded(child: Text(textoParaUsuario(error), style: context.apagado())),
      TextButton(onPressed: onTap, child: const Text('Reintentar')),
    ],
  );
}
