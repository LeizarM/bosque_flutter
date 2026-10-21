/// Inicio del dashboard (v11): una tarjeta por cada pregunta de la semana
/// vigente para quien entra. Sin vigentes no ocupa lugar; si la carga falla,
/// una línea discreta con «Reintentar». El resultado y su texto los da el SP.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_opcion_semana_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_semana_vigente_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/respuestas_pregunta_semana.dart';

/// Desde este ancho de tarjeta las opciones van en dos columnas.
const double _anchoDosColumnas = 640;

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
                  Icon(Icons.quiz_outlined, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: Esp.s),
                  Flexible(child: Text('No se pudo cargar la pregunta de la semana.', style: context.apagado())),
                  TextButton(
                    onPressed: () => ref.invalidate(tcpePreguntasSemanaVigentesProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
        data:
            (lista) =>
                lista.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                      padding: const EdgeInsets.only(bottom: Esp.l),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < lista.length; i++) ...[
                            if (i > 0) const SizedBox(height: Esp.m),
                            TarjetaPreguntaSemana(key: ValueKey(lista[i].codPreguntaSemana), pregunta: lista[i]),
                          ],
                        ],
                      ),
                    ),
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
  BigInt? _elegida;
  bool _enviando = false;

  Future<void> _responder() async {
    final cod = _elegida;
    if (cod == null) return;
    setState(() => _enviando = true);
    try {
      await ref.read(examenesRepositoryProvider).responderPreguntaSemana(widget.pregunta.codPreguntaSemana, cod);
      // El resultado (y su mensaje) lo trae la vigente de nuevo: hasta tenerla el botón sigue ocupado.
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = widget.pregunta;
    final t = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Color.alphaBlend(cs.primaryContainer.withValues(alpha: 0.22), cs.surface),
      shape: contornoSuperficie(cs, color: cs.primary.withValues(alpha: 0.35)),
      child: Padding(
        padding: const EdgeInsets.all(Esp.l),
        child: LayoutBuilder(
          builder: (context, r) {
            final dos = r.maxWidth >= _anchoDosColumnas;
            final anchoOpcion = dos ? (r.maxWidth - Esp.m) / 2 : r.maxWidth;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SelloExamen(icono: Icons.quiz_outlined, tamanio: 40),
                    const SizedBox(width: Esp.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            oGuion(p.titulo),
                            style: t.titleSmall?.copyWith(color: cs.primary, fontWeight: Peso.titulo),
                          ),
                          Text(plazoInicioTexto(p), style: context.apagado()),
                        ],
                      ),
                    ),
                    if (p.respuestas > 0)
                      PastillaExamen(
                        texto: p.respuestas == 1 ? '1 respondió' : '${p.respuestas} respondieron',
                        tono: TonoExamen.secundario,
                        icono: Icons.groups_outlined,
                      ),
                  ],
                ),
                const SizedBox(height: Esp.m),
                Semantics(
                  header: true,
                  child: Text(oGuion(p.pregunta), style: t.titleMedium?.copyWith(fontWeight: Peso.titulo)),
                ),
                const SizedBox(height: Esp.m),
                Wrap(
                  spacing: Esp.m,
                  runSpacing: Esp.s,
                  children: [
                    for (var i = 0; i < p.opciones.length; i++)
                      SizedBox(
                        width: anchoOpcion,
                        child: _OpcionSemana(
                          letra: letraOpcion(i),
                          opcion: p.opciones[i],
                          respondida: p.respondida,
                          marcadaAhora: p.opciones[i].codRsptaOp == _elegida,
                          onTap:
                              p.respondida || _enviando
                                  ? null
                                  : () => setState(() => _elegida = p.opciones[i].codRsptaOp),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Esp.m),
                if (!p.respondida)
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 48,
                      child: BotonAccion(
                        etiqueta: 'Responder',
                        etiquetaOcupado: 'Enviando…',
                        icono: Icons.send_outlined,
                        ocupado: _enviando,
                        onPressed: _elegida == null ? null : _responder,
                      ),
                    ),
                  )
                else if ((p.mensaje ?? '').trim().isNotEmpty)
                  _Resultado(mensaje: p.mensaje!.trim(), esCorrecta: p.esCorrecta),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OpcionSemana extends StatelessWidget {
  const _OpcionSemana({
    required this.letra,
    required this.opcion,
    required this.respondida,
    required this.marcadaAhora,
    required this.onTap,
  });

  final String letra;
  final TcpeOpcionSemanaEntity opcion;
  final bool respondida;

  /// Antes de responder: la que eligió en esta pantalla.
  final bool marcadaAhora;
  final VoidCallback? onTap;

  /// Antes de responder, la marcada ahora. Después, la elegida y, solo si el SP
  /// manda `esValido`, cuál era la correcta.
  ({MarcaBurbuja marca, Color? fondo, Color borde, String? rotulo, IconData? icono}) _aspecto(ColorScheme cs) {
    final o = opcion;
    if (!respondida) {
      return marcadaAhora
          ? (marca: MarcaBurbuja.marcada, fondo: cs.primaryContainer, borde: cs.primary, rotulo: null, icono: null)
          : (marca: MarcaBurbuja.vacia, fondo: cs.surface, borde: cs.outlineVariant, rotulo: null, icono: null);
    }
    if (o.elegida && o.esValido == true) {
      return (
        marca: MarcaBurbuja.marcada,
        fondo: cs.primaryContainer,
        borde: cs.primary,
        rotulo: 'Tu respuesta · correcta',
        icono: Icons.check_circle,
      );
    }
    if (o.elegida && o.esValido == false) {
      return (
        marca: MarcaBurbuja.error,
        fondo: cs.errorContainer,
        borde: cs.error,
        rotulo: 'Tu respuesta',
        icono: Icons.cancel,
      );
    }
    if (o.elegida) {
      return (
        marca: MarcaBurbuja.marcada,
        fondo: cs.secondaryContainer,
        borde: cs.secondary,
        rotulo: 'Tu respuesta',
        icono: null,
      );
    }
    if (o.esValido == true) {
      return (
        marca: MarcaBurbuja.vacia,
        fondo: cs.surface,
        borde: cs.primary,
        rotulo: 'Correcta',
        icono: Icons.check_circle_outline,
      );
    }
    return (marca: MarcaBurbuja.neutra, fondo: null, borde: cs.outlineVariant, rotulo: null, icono: null);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final o = opcion;
    final (:marca, :fondo, :borde, :rotulo, :icono) = _aspecto(cs);
    final apagada = respondida && !o.elegida && o.esValido != true;
    return Semantics(
      button: onTap != null,
      selected: marcadaAhora || o.elegida,
      label: 'Opción $letra: ${oGuion(o.opcionRspta)}${rotulo == null ? '' : '. $rotulo'}',
      excludeSemantics: true,
      child: Material(
        color: fondo ?? Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Esquina.media),
          side: BorderSide(color: borde, width: marca == MarcaBurbuja.marcada || rotulo != null ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
              child: Row(
                children: [
                  BurbujaHoja(texto: letra, marca: marca, tamanio: 30),
                  const SizedBox(width: Esp.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          oGuion(o.opcionRspta),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: apagada ? cs.onSurfaceVariant : null,
                            fontWeight: marcadaAhora || o.elegida ? Peso.titulo : null,
                          ),
                        ),
                        if (rotulo != null)
                          Text(rotulo, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: borde)),
                      ],
                    ),
                  ),
                  if (icono != null) ...[const SizedBox(width: Esp.s), Icon(icono, size: 20, color: borde)],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El mensaje del SP después de responder, en el tono de lo que pasó: acertó,
/// no acertó o solo quedó registrada (la pregunta no muestra la respuesta).
class _Resultado extends StatelessWidget {
  const _Resultado({required this.mensaje, required this.esCorrecta});

  final String mensaje;
  final bool? esCorrecta;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (tono, icono) = switch (esCorrecta) {
      true => (TonoExamen.principal, Icons.emoji_events_outlined),
      false => (TonoExamen.alerta, Icons.lightbulb_outline),
      null => (TonoExamen.secundario, Icons.task_alt),
    };
    final c = coloresDeTono(cs, tono);
    return Semantics(
      liveRegion: true,
      child: EntradaSuave(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Esp.m),
          decoration: BoxDecoration(color: c.fondo, borderRadius: BorderRadius.circular(Esquina.media)),
          child: Row(
            children: [
              Icon(icono, color: c.letra),
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
