/// Inicio del dashboard (v12): cada pregunta de la semana vigente como una
/// charla, la pregunta en un globo y, si quiere, la respuesta de quien entra.
/// Sin vigentes no ocupa lugar; «Ahora no» la oculta hasta volver a entrar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_semana_vigente_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';

/// Desde este ancho de tarjeta los globos no pasan del 70 % del ancho.
const double _anchoAmplio = 640;

/// Las que se ocultaron con «Ahora no» en esta sesión; vuelven al abrir la app de nuevo.
final _ocultasProvider = StateProvider<Set<BigInt>>((ref) => {});

class PreguntasSemanaInicio extends ConsumerWidget {
  const PreguntasSemanaInicio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(tcpePreguntasSemanaVigentesProvider)
      .when(
        skipLoadingOnReload: true,
        // Es contenido secundario del inicio: mientras carga no reserva lugar.
        loading: () => const SizedBox.shrink(),
        error:
            (_, __) => Padding(
              padding: const EdgeInsets.only(bottom: Esp.l),
              child: Row(
                children: [
                  Icon(Icons.forum_outlined, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: Esp.s),
                  Flexible(child: Text('No se pudo cargar la pregunta de la semana.', style: context.apagado())),
                  TextButton(
                    onPressed: () => ref.invalidate(tcpePreguntasSemanaVigentesProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
        data: (lista) {
          final ocultas = ref.watch(_ocultasProvider);
          final visibles = [
            for (final p in lista)
              if (!ocultas.contains(p.codPreguntaSemana)) p,
          ];
          if (visibles.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: Esp.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < visibles.length; i++) ...[
                  if (i > 0) const SizedBox(height: Esp.m),
                  TarjetaPreguntaSemana(key: ValueKey(visibles[i].codPreguntaSemana), pregunta: visibles[i]),
                ],
              ],
            ),
          );
        },
      );
}

/// Hasta cuándo se puede responder, en palabras.
String plazoInicioTexto(TcpePreguntaSemanaVigenteEntity p) => switch (p.diasRestantes) {
  0 => 'Hoy es el último día para responder.',
  1 => 'Puedes responder hasta mañana.',
  _ => 'Puedes responder hasta el ${fechaCorta(p.fechaFin)}.',
};

class TarjetaPreguntaSemana extends ConsumerStatefulWidget {
  const TarjetaPreguntaSemana({super.key, required this.pregunta});

  final TcpePreguntaSemanaVigenteEntity pregunta;

  @override
  ConsumerState<TarjetaPreguntaSemana> createState() => _TarjetaPreguntaSemanaState();
}

class _TarjetaPreguntaSemanaState extends ConsumerState<TarjetaPreguntaSemana> {
  final _texto = TextEditingController();
  bool _enviando = false;

  bool get _hayTexto => _texto.text.trim().isNotEmpty;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_hayTexto) return;
    setState(() => _enviando = true);
    try {
      await ref
          .read(examenesRepositoryProvider)
          .responderPreguntaSemana(widget.pregunta.codPreguntaSemana, _texto.text.trim());
      // La respuesta y el agradecimiento los trae la vigente de nuevo: hasta tenerla el botón sigue ocupado.
      ref.invalidate(tcpePreguntasSemanaVigentesProvider);
      try {
        await ref.read(tcpePreguntasSemanaVigentesProvider.future);
      } catch (_) {
        // Si la recarga falla, la lista muestra su propio error.
      }
    } catch (e) {
      if (mounted) avisar(context, textoParaUsuario(e), esError: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _ocultar() =>
      ref.read(_ocultasProvider.notifier).state = {...ref.read(_ocultasProvider), widget.pregunta.codPreguntaSemana};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final p = widget.pregunta;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Color.alphaBlend(cs.primaryContainer.withValues(alpha: 0.18), cs.surface),
      shape: contornoSuperficie(cs, color: cs.primary.withValues(alpha: 0.3)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.s, Esp.l),
        child: LayoutBuilder(
          builder: (context, r) {
            final anchoGlobo = r.maxWidth * (r.maxWidth >= _anchoAmplio ? 0.7 : 0.92);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: Esp.xs),
                      child: SelloExamen(icono: Icons.forum_outlined, tamanio: 40),
                    ),
                    const SizedBox(width: Esp.m),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: Esp.xs),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              oGuion(p.titulo),
                              style: t.titleSmall?.copyWith(color: cs.primary, fontWeight: Peso.titulo),
                            ),
                            Text(p.respondida ? 'Ya respondiste.' : plazoInicioTexto(p), style: context.apagado()),
                          ],
                        ),
                      ),
                    ),
                    // Sin responder, «Ahora no» va junto a Enviar; ya respondida, solo queda ocultarla.
                    if (p.respondida)
                      IconButton(tooltip: 'Ocultar', onPressed: _ocultar, icon: const Icon(Icons.close))
                    else
                      const SizedBox(width: Esp.s),
                  ],
                ),
                const SizedBox(height: Esp.m),
                Padding(
                  padding: const EdgeInsets.only(right: Esp.s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(header: true, child: GloboSemana(texto: p.pregunta, ancho: anchoGlobo)),
                      if (p.respondida) ...[
                        const SizedBox(height: Esp.s),
                        GloboSemana(
                          texto: p.respuesta,
                          propio: true,
                          ancho: anchoGlobo,
                          pie: 'Tu respuesta · ${fechaHora(p.fechaRespuesta)}',
                        ),
                        if ((p.mensaje ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: Esp.m),
                          _Gracias(mensaje: p.mensaje!.trim()),
                        ],
                      ] else ...[
                        const SizedBox(height: Esp.m),
                        TextField(
                          controller: _texto,
                          enabled: !_enviando,
                          minLines: 2,
                          maxLines: 5,
                          maxLength: p.maxRespuesta,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Escribe tu respuesta…',
                            helperText: p.ayuda,
                            helperMaxLines: 3,
                            filled: true,
                            fillColor: cs.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(Esquina.media)),
                          ),
                        ),
                        const SizedBox(height: Esp.s),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: Esp.s,
                          runSpacing: Esp.s,
                          children: [
                            TextButton(onPressed: _enviando ? null : _ocultar, child: const Text('Ahora no')),
                            SizedBox(
                              height: 48,
                              child: BotonAccion(
                                etiqueta: 'Enviar',
                                etiquetaOcupado: 'Enviando…',
                                icono: Icons.send_outlined,
                                ocupado: _enviando,
                                onPressed: _hayTexto ? _enviar : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Un globo de la charla: la pregunta (a la izquierda, en el color principal) o
/// una respuesta (a la derecha, en el terciario). Lo usan el inicio, el
/// editor (vista previa) y las respuestas de la gestión.
class GloboSemana extends StatelessWidget {
  const GloboSemana({super.key, required this.texto, required this.ancho, this.propio = false, this.pie});

  final String? texto;

  /// Ancho máximo del globo.
  final double ancho;

  /// true = una respuesta; false = la pregunta.
  final bool propio;

  /// Una línea chica bajo el globo (quién o cuándo).
  final String? pie;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final fondo = propio ? cs.tertiaryContainer : cs.primaryContainer;
    final letra = propio ? cs.onTertiaryContainer : cs.onPrimaryContainer;
    const curva = Radius.circular(18);
    const pico = Radius.circular(4);
    return Align(
      alignment: propio ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ancho),
        child: Column(
          crossAxisAlignment: propio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Esp.l, vertical: Esp.m),
              decoration: BoxDecoration(
                color: fondo,
                borderRadius: BorderRadius.only(
                  topLeft: propio ? curva : pico,
                  topRight: propio ? pico : curva,
                  bottomLeft: curva,
                  bottomRight: curva,
                ),
              ),
              child: Text(
                oGuion(texto),
                style:
                    propio
                        ? t.bodyLarge?.copyWith(color: letra)
                        : t.titleMedium?.copyWith(color: letra, fontWeight: Peso.titulo),
              ),
            ),
            if (pie != null)
              Padding(padding: const EdgeInsets.only(top: Esp.xs), child: Text(pie!, style: context.apagado())),
          ],
        ),
      ),
    );
  }
}

/// El agradecimiento del SP después de responder.
class _Gracias extends StatelessWidget {
  const _Gracias({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final c = coloresDeTono(Theme.of(context).colorScheme, TonoExamen.principal);
    return Semantics(
      liveRegion: true,
      child: EntradaSuave(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Esp.m),
          decoration: BoxDecoration(color: c.fondo, borderRadius: BorderRadius.circular(Esquina.media)),
          child: Row(
            children: [
              Icon(Icons.favorite_outline, color: c.letra),
              const SizedBox(width: Esp.m),
              Expanded(
                child: Text(
                  mensaje,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.letra, fontWeight: Peso.titulo),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
