/// Las respuestas de una pregunta de la semana (`p_list_tcpe_PreguntaSemana` R):
/// quién respondió, su cargo, qué escribió y cuándo. Una respuesta fuera de
/// lugar se puede quitar; la persona podrá volver a responder.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_semana_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_respondio_semana_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/pregunta_semana_inicio.dart';

/// Con más respuestas que estas aparece el buscador.
const int _conBuscador = 5;

Future<void> abrirRespuestasPreguntaSemana(BuildContext context, TcpePreguntaSemanaEntity pregunta) =>
    mostrarFormulario<void>(
      context,
      (completa) => MarcoFormulario(
        titulo: 'Respuestas',
        icono: Icons.forum_outlined,
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

/// `dd/mm/aaaa – dd/mm/aaaa`.
String plazoSemanaTexto(DateTime? desde, DateTime? hasta) => '${fechaCorta(desde)} – ${fechaCorta(hasta)}';

/// Iniciales para el círculo de la persona: las dos primeras palabras del nombre.
String inicialesDe(String? nombre) {
  final partes = (nombre ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
  final s = partes.map((p) => p.characters.first.toUpperCase()).join();
  return s.isEmpty ? '?' : s;
}

class RespuestasPreguntaSemana extends ConsumerStatefulWidget {
  const RespuestasPreguntaSemana({super.key, required this.pregunta});

  final TcpePreguntaSemanaEntity pregunta;

  @override
  ConsumerState<RespuestasPreguntaSemana> createState() => _RespuestasPreguntaSemanaState();
}

class _RespuestasPreguntaSemanaState extends ConsumerState<RespuestasPreguntaSemana> {
  String _filtro = '';
  final Set<BigInt> _quitando = {};

  bool _coincide(TcpeRespondioSemanaEntity f) {
    final q = _filtro.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [f.nombreCompleto, f.login, f.cargo, f.respuesta].any((x) => (x ?? '').toLowerCase().contains(q));
  }

  Future<void> _quitar(TcpeRespondioSemanaEntity f) async {
    final ok = await confirmar(
      context,
      titulo: 'Quitar la respuesta',
      detalle:
          'Se borra lo que escribió ${oGuion(f.nombreCompleto ?? f.login)}. Podrá volver a responder mientras la '
          'pregunta esté vigente.',
      textoConfirmar: 'Quitar',
      destructiva: true,
    );
    if (!ok || !mounted) return;
    setState(() => _quitando.add(f.codRsptaSemana));
    try {
      final msg = await ref.read(examenesRepositoryProvider).quitarRespuestaSemana(f.codRsptaSemana);
      ref.invalidate(tcpeRespuestasSemanaProvider(widget.pregunta.codPreguntaSemana));
      ref.invalidate(tcpePreguntasSemanaProvider);
      if (mounted) avisar(context, msg ?? 'Respuesta quitada.');
    } catch (e) {
      if (mounted) avisar(context, textoParaUsuario(e), esError: true);
    } finally {
      if (mounted) setState(() => _quitando.remove(f.codRsptaSemana));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pregunta = widget.pregunta;
    final cod = pregunta.codPreguntaSemana;
    final respuestas = ref.watch(tcpeRespuestasSemanaProvider(cod));
    return LayoutBuilder(
      builder: (context, r) {
        final ancha = r.maxWidth >= 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(oGuion(pregunta.tituloMostrado ?? pregunta.titulo), style: context.apagado()),
            const SizedBox(height: Esp.s),
            GloboSemana(texto: pregunta.pregunta, ancho: r.maxWidth * (ancha ? 0.8 : 0.95)),
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
              data: (filas) {
                final vistas = filas.where(_coincide).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: Esp.m,
                      runSpacing: Esp.s,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        CifraExamen(
                          valor: '${filas.length}',
                          rotulo: filas.length == 1 ? 'respondió' : 'respondieron',
                          icono: Icons.groups_outlined,
                          tono: TonoExamen.secundario,
                        ),
                      ],
                    ),
                    const SizedBox(height: Esp.l),
                    Text('Lo que respondieron', style: context.tituloSeccion()),
                    const SizedBox(height: Esp.s),
                    if (filas.length > _conBuscador) ...[
                      TextField(
                        onChanged: (v) => setState(() => _filtro = v),
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'Buscar por nombre, cargo o respuesta',
                          prefixIcon: Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: Esp.s),
                    ],
                    if (filas.isEmpty)
                      Text('Todavía nadie respondió.', style: context.apagado())
                    else if (vistas.isEmpty)
                      Text('Ninguna respuesta coincide con la búsqueda.', style: context.apagado())
                    else
                      for (final f in vistas)
                        _FilaRespuesta(
                          fila: f,
                          ancha: ancha,
                          quitando: _quitando.contains(f.codRsptaSemana),
                          onQuitar: () => _quitar(f),
                        ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

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

class _FilaRespuesta extends StatelessWidget {
  const _FilaRespuesta({required this.fila, required this.ancha, required this.quitando, required this.onQuitar});

  final TcpeRespondioSemanaEntity fila;
  final bool ancha;
  final bool quitando;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final f = fila;
    final nombre = oGuion(f.nombreCompleto ?? f.login);
    final cargo = (f.cargo ?? '').trim();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Esp.m),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: CircleAvatar(
              radius: 18,
              backgroundColor: cs.tertiaryContainer,
              child: Text(
                inicialesDe(f.nombreCompleto ?? f.login),
                style: t.labelLarge?.copyWith(color: cs.onTertiaryContainer, fontWeight: Peso.titulo),
              ),
            ),
          ),
          const SizedBox(width: Esp.m),
          Expanded(
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
                          Text(nombre, style: const TextStyle(fontWeight: Peso.titulo)),
                          if (cargo.isNotEmpty || !ancha)
                            Text(
                              [if (cargo.isNotEmpty) cargo, if (!ancha) fechaHora(f.fechaRespuesta)].join(' · '),
                              style: context.apagado(),
                            ),
                        ],
                      ),
                    ),
                    if (ancha)
                      Padding(
                        padding: const EdgeInsets.only(left: Esp.s, top: 2),
                        child: Text(fechaHora(f.fechaRespuesta), style: context.apagado()),
                      ),
                  ],
                ),
                const SizedBox(height: Esp.s),
                // Lo que escribió, en un globo como el del inicio.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer.withValues(alpha: 0.55),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: SelectableText(
                    oGuion(f.respuesta),
                    style: t.bodyMedium?.copyWith(color: cs.onTertiaryContainer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Esp.xs),
          quitando
              ? const Padding(
                padding: EdgeInsets.all(Esp.m),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              )
              : IconButton(
                tooltip: 'Quitar respuesta',
                onPressed: onQuitar,
                icon: Icon(Icons.delete_outline, color: cs.onSurfaceVariant),
              ),
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
