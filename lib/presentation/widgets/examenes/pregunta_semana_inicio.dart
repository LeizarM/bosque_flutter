/// Inicio del dashboard (v12/v13): cada pregunta de la semana vigente como una
/// charla, la pregunta en un globo y, si quiere, la respuesta de quien entra:
/// un texto o un número de la escala. «Ahora no» la oculta hasta volver a entrar.
library;

import 'dart:math' as math;

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

  /// El número elegido en una pregunta de escala.
  int? _valor;

  /// Abierta: hay texto; de escala: hay un número elegido.
  bool get _listo => widget.pregunta.esEscala ? _valor != null : _texto.text.trim().isNotEmpty;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_listo) return;
    final p = widget.pregunta;
    setState(() => _enviando = true);
    try {
      await ref
          .read(examenesRepositoryProvider)
          .responderPreguntaSemana(
            p.codPreguntaSemana,
            respuesta: p.esEscala ? null : _texto.text.trim(),
            valor: p.esEscala ? _valor : null,
          );
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
                          texto:
                              p.esEscala
                                  ? valorEscalaTexto(
                                    p.valor,
                                    min: p.escalaMin,
                                    max: p.escalaMax,
                                    etiquetaMin: p.etiquetaMin,
                                    etiquetaMax: p.etiquetaMax,
                                  )
                                  : p.respuesta,
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
                        if (p.esEscala) ...[
                          SelectorEscalaSemana(
                            min: p.escalaMin ?? 1,
                            max: p.escalaMax ?? 5,
                            etiquetaMin: p.etiquetaMin,
                            etiquetaMax: p.etiquetaMax,
                            valor: _valor,
                            onElegir: _enviando ? null : (v) => setState(() => _valor = v),
                          ),
                          if ((p.ayuda ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: Esp.m),
                            Text(p.ayuda!.trim(), style: context.apagado()),
                          ],
                        ] else
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
                                onPressed: _listo ? _enviar : null,
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

/// «4 de 5»; si es un extremo con etiqueta, «5 de 5 · Excelente».
String valorEscalaTexto(int? valor, {int? min, int? max, String? etiquetaMin, String? etiquetaMax}) {
  if (valor == null) return '--';
  final etiqueta = ((valor == min ? etiquetaMin : (valor == max ? etiquetaMax : null)) ?? '').trim();
  final base = max == null ? '$valor' : '$valor de $max';
  return etiqueta.isEmpty ? base : '$base · $etiqueta';
}

/// El tinte de un número según su lugar en la escala: de la superficie (el
/// primero) al contenedor principal (el último). Dice «más», nunca «bien» o «mal».
Color tinteEscala(ColorScheme cs, double t) =>
    Color.lerp(cs.surfaceContainerHighest, cs.primaryContainer, t.clamp(0.0, 1.0))!;

Color _letraEscala(ColorScheme cs, double t) =>
    Color.lerp(cs.onSurfaceVariant, cs.onPrimaryContainer, t.clamp(0.0, 1.0))!;

/// La escala de una pregunta de la semana: un botón redondo por número, teñidos
/// de menos a más, con lo que significan los extremos debajo. Sin [onElegir]
/// solo se muestra (la vista previa del editor).
class SelectorEscalaSemana extends StatelessWidget {
  const SelectorEscalaSemana({
    super.key,
    required this.min,
    required this.max,
    this.etiquetaMin,
    this.etiquetaMax,
    this.valor,
    this.onElegir,
  });

  final int min;
  final int max;
  final String? etiquetaMin;
  final String? etiquetaMax;
  final int? valor;
  final ValueChanged<int>? onElegir;

  static const double _ladoMax = 56;

  /// Más chico que esto no se toca cómodo: los botones pasan a varias filas.
  static const double _ladoMin = 44;
  static const double _separacion = Esp.s;

  @override
  Widget build(BuildContext context) {
    final valores = [for (var v = min; v <= math.max(min, max); v++) v];
    final n = valores.length;
    final etqMin = (etiquetaMin ?? '').trim();
    final etqMax = (etiquetaMax ?? '').trim();
    return LayoutBuilder(
      builder: (context, r) {
        // Las filas justas para que cada botón mida al menos 44 px, y parejas (4, 4 y 3; no 5, 5 y 1).
        var porFila = n;
        var lado = (r.maxWidth - _separacion * (n - 1)) / n;
        for (var filas = 2; lado < _ladoMin && porFila > 1; filas++) {
          porFila = (n / filas).ceil();
          lado = (r.maxWidth - _separacion * (porFila - 1)) / porFila;
        }
        lado = math.min(lado, _ladoMax).floorToDouble();
        final ancho = porFila * lado + _separacion * (porFila - 1);
        final enFila = porFila == n;
        Widget boton(int i) => _BotonEscala(
          valor: valores[i],
          tinte: n == 1 ? 1 : i / (n - 1),
          lado: lado,
          elegido: valores[i] == valor,
          semantica: valorEscalaTexto(valores[i], min: min, max: max, etiquetaMin: etqMin, etiquetaMax: etqMax),
          onTap: onElegir == null ? null : () => onElegir!(valores[i]),
        );
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: ancho,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var desde = 0; desde < n; desde += porFila)
                  Padding(
                    padding: EdgeInsets.only(top: desde == 0 ? 0 : _separacion),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = desde; i < math.min(desde + porFila, n); i++) ...[
                          if (i > desde) const SizedBox(width: _separacion),
                          boton(i),
                        ],
                      ],
                    ),
                  ),
                // Cada botón ya dice su etiqueta al lector de pantalla. En una fila van bajo los
                // extremos; en varias, el último no queda a la derecha y van en una línea.
                if (etqMin.isNotEmpty || etqMax.isNotEmpty) ...[
                  const SizedBox(height: Esp.xs),
                  ExcludeSemantics(
                    child:
                        enFila
                            ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: Text(etqMin, style: context.apagado())),
                                const SizedBox(width: Esp.s),
                                Expanded(child: Text(etqMax, textAlign: TextAlign.end, style: context.apagado())),
                              ],
                            )
                            : Text(
                              [if (etqMin.isNotEmpty) '$min: $etqMin', if (etqMax.isNotEmpty) '$max: $etqMax'].join(' · '),
                              style: context.apagado(),
                            ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BotonEscala extends StatelessWidget {
  const _BotonEscala({
    required this.valor,
    required this.tinte,
    required this.lado,
    required this.elegido,
    required this.semantica,
    this.onTap,
  });

  final int valor;

  /// De 0 (el primero de la escala) a 1 (el último).
  final double tinte;
  final double lado;
  final bool elegido;
  final String semantica;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final quieto = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: onTap != null,
      selected: elegido,
      label: semantica,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: elegido ? 1.1 : 1,
        duration: quieto ? Duration.zero : const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: Material(
          color: elegido ? cs.primary : tinteEscala(cs, tinte),
          shape: CircleBorder(
            side: elegido ? BorderSide.none : BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: lado,
              height: lado,
              child: Center(
                child: Text(
                  '$valor',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: elegido ? cs.onPrimary : _letraEscala(cs, tinte),
                    fontWeight: Peso.dato,
                    fontFeatures: cifrasTabulares,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un número de la escala en su círculo teñido, para las respuestas de la gestión.
class NumeroEscala extends StatelessWidget {
  const NumeroEscala({super.key, required this.valor, required this.min, required this.max, this.lado = 32});

  final int valor;
  final int min;
  final int max;
  final double lado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = max > min ? (valor - min) / (max - min) : 1.0;
    return Container(
      width: lado,
      height: lado,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tinteEscala(cs, t), shape: BoxShape.circle),
      child: Text(
        '$valor',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: _letraEscala(cs, t),
          fontWeight: Peso.dato,
          fontFeatures: cifrasTabulares,
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
