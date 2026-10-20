/// La identidad visual del módulo: la **hoja de respuestas**. Burbujas como
/// las del papel que se marca con lápiz, tiras de casillas que cuentan avance
/// y estados, y folios en letra fija. El color sale siempre del tema.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_lote_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';

/// Duración de una microinteracción; cero si el sistema pide menos movimiento.
Duration duracionSuave(BuildContext context, [int milisegundos = 180]) =>
    MediaQuery.maybeDisableAnimationsOf(context) == true ? Duration.zero : Duration(milliseconds: milisegundos);

// ═══════════════════════════════════════════════════════════════════════════
// BURBUJA
// ═══════════════════════════════════════════════════════════════════════════

/// Cómo está marcada una burbuja de la hoja.
enum MarcaBurbuja { vacia, marcada, actual, aviso, error, neutra }

/// Un círculo de la hoja de respuestas con un número o una letra adentro. El
/// tono codifica el estado y el borde grueso, cuál es la actual.
class BurbujaHoja extends StatelessWidget {
  const BurbujaHoja({super.key, required this.texto, this.marca = MarcaBurbuja.vacia, this.tamanio = 32, this.hijo});

  final String texto;
  final MarcaBurbuja marca;
  final double tamanio;

  /// En lugar del texto (por ejemplo, un indicador de guardado).
  final Widget? hijo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (fondo, letra, borde, grosor) = switch (marca) {
      MarcaBurbuja.marcada => (cs.primary, cs.onPrimary, cs.primary, 1.0),
      MarcaBurbuja.actual => (cs.surface, cs.onSurface, cs.onSurface, 2.5),
      MarcaBurbuja.aviso => (cs.tertiaryContainer, cs.onTertiaryContainer, cs.tertiary, 1.5),
      MarcaBurbuja.error => (cs.errorContainer, cs.onErrorContainer, cs.error, 1.5),
      MarcaBurbuja.neutra => (cs.surfaceContainerHighest, cs.onSurfaceVariant, cs.outlineVariant, 1.0),
      MarcaBurbuja.vacia => (cs.surface, cs.onSurfaceVariant, cs.outline, 1.0),
    };
    return AnimatedContainer(
      duration: duracionSuave(context),
      curve: Curves.easeOut,
      width: tamanio,
      height: tamanio,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fondo, shape: BoxShape.circle, border: Border.all(color: borde, width: grosor)),
      child:
          hijo ??
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                texto,
                style: TextStyle(
                  fontFamily: fuenteFija,
                  fontWeight: marca == MarcaBurbuja.actual ? FontWeight.w700 : FontWeight.w600,
                  fontSize: tamanio * 0.38,
                  color: letra,
                  fontFeatures: cifrasTabulares,
                ),
              ),
            ),
          ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TIRA DE ESTADOS
// ═══════════════════════════════════════════════════════════════════════════

/// El tono de un tramo: qué clase de estado cuenta.
enum TonoTramo { hecho, revisar, enCurso, alerta, perdido, pendiente }

/// Los estados de los exámenes de un lote, en el orden en que se leen.
List<TramoTira> tramosDeLote(TcpeLoteEntity l) => [
  TramoTira(l.calificados, 'calificados', TonoTramo.hecho),
  TramoTira(l.porRevisar, 'por revisar', TonoTramo.revisar),
  TramoTira(l.enCurso, 'en curso', TonoTramo.enCurso),
  TramoTira(l.vencidos, 'vencidos', TonoTramo.alerta),
  TramoTira(l.ausentes, 'ausentes', TonoTramo.perdido),
  TramoTira(l.sinIniciar, 'sin iniciar', TonoTramo.pendiente),
];

class TramoTira {
  const TramoTira(this.valor, this.etiqueta, this.tono);

  final int valor;
  final String etiqueta;
  final TonoTramo tono;
}

Color colorDeTramo(ColorScheme cs, TonoTramo t) => switch (t) {
  TonoTramo.hecho => cs.primary,
  TonoTramo.revisar => cs.tertiary,
  TonoTramo.enCurso => Color.alphaBlend(cs.primary.withValues(alpha: 0.45), cs.surface),
  TonoTramo.alerta => cs.error,
  TonoTramo.perdido => Color.alphaBlend(cs.error.withValues(alpha: 0.45), cs.surface),
  TonoTramo.pendiente => Color.alphaBlend(cs.onSurface.withValues(alpha: 0.16), cs.surface),
};

/// Cuántos hay en cada estado, como tramos proporcionales de una tira, con la
/// leyenda debajo. El color nunca va solo: cada tramo lleva su número y rótulo.
class TiraEstados extends StatelessWidget {
  const TiraEstados({super.key, required this.tramos, this.alto = 10, this.leyenda = true, this.ocultarCeros = true});

  final List<TramoTira> tramos;
  final double alto;
  final bool leyenda;
  final bool ocultarCeros;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visibles = [
      for (final t in tramos)
        if (t.valor > 0 || !ocultarCeros) t,
    ];
    final conValor = [
      for (final t in tramos)
        if (t.valor > 0) t,
    ];
    final total = tramos.fold<int>(0, (s, t) => s + t.valor);
    final resumen = visibles.map((t) => '${t.valor} ${t.etiqueta}').join(', ');
    return Semantics(
      label: total == 0 ? 'Sin exámenes' : resumen,
      container: true,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Esquina.pastilla),
              child: SizedBox(
                height: alto,
                child:
                    total == 0
                        ? ColoredBox(color: colorDeTramo(cs, TonoTramo.pendiente), child: const SizedBox.expand())
                        : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final (i, t) in conValor.indexed) ...[
                              if (i > 0) SizedBox(width: 2, child: ColoredBox(color: cs.surface)),
                              Expanded(flex: t.valor, child: ColoredBox(color: colorDeTramo(cs, t.tono))),
                            ],
                          ],
                        ),
              ),
            ),
            if (leyenda && visibles.isNotEmpty) ...[
              const SizedBox(height: Esp.s),
              Wrap(
                spacing: Esp.m,
                runSpacing: Esp.xs,
                children: [
                  for (final t in visibles)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: colorDeTramo(cs, t.tono), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: Esp.xs + 2),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${t.valor}',
                                style: context
                                    .numero(fuerte: true)
                                    ?.copyWith(fontFamily: fuenteFija, color: cs.onSurface),
                              ),
                              TextSpan(text: ' ${t.etiqueta}'),
                            ],
                          ),
                          style: context.apagado(),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TIRA DE RESPUESTAS (avance de la rendición)
// ═══════════════════════════════════════════════════════════════════════════

/// Una casilla por pregunta: llena si está respondida, marcada si es la
/// actual. Se lee de un vistazo cuánto falta y dónde se está.
class TiraRespuestas extends StatelessWidget {
  const TiraRespuestas({super.key, required this.respondidas, required this.actual, this.alto = 6});

  /// Una por pregunta, en orden.
  final List<bool> respondidas;
  final int actual;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = respondidas.length;
    final hechas = respondidas.where((r) => r).length;
    return Semantics(
      label: 'Respondiste $hechas de $total preguntas. Estás en la pregunta ${actual + 1}.',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, r) {
            // Con muchas preguntas en poco ancho, el hueco entre casillas se achica.
            final hueco = total <= 1 ? 0.0 : math.min(3.0, (r.maxWidth / total) * 0.25);
            return SizedBox(
              height: alto + 4,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < total; i++) ...[
                    if (i > 0) SizedBox(width: hueco),
                    Expanded(
                      child: AnimatedContainer(
                        duration: duracionSuave(context, 220),
                        height: i == actual ? alto + 4 : alto,
                        decoration: BoxDecoration(
                          color: respondidas[i] ? cs.primary : colorDeTramo(cs, TonoTramo.pendiente),
                          borderRadius: BorderRadius.circular(2),
                          border: i == actual ? Border.all(color: cs.onSurface, width: 1.5) : null,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PASOS
// ═══════════════════════════════════════════════════════════════════════════

/// Los pasos de un flujo en orden, como burbujas: hechos, actual y por venir.
/// En el teléfono solo las burbujas y el nombre del paso actual.
class PasosBurbuja extends StatelessWidget {
  const PasosBurbuja({super.key, required this.pasos, required this.actual, this.compacto = false});

  final List<String> pasos;
  final int actual;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget burbuja(int i) => BurbujaHoja(
      texto: '${i + 1}',
      tamanio: 28,
      marca:
          i < actual
              ? MarcaBurbuja.marcada
              : i == actual
              ? MarcaBurbuja.actual
              : MarcaBurbuja.vacia,
      hijo: i < actual ? Icon(Icons.check, size: 16, color: cs.onPrimary) : null,
    );
    Widget linea({bool estirar = true}) {
      final trazo = Container(
        height: 1.5,
        color: cs.outlineVariant,
        margin: const EdgeInsets.symmetric(horizontal: Esp.xs),
      );
      return estirar ? Expanded(child: trazo) : SizedBox(width: Esp.xl, child: trazo);
    }

    // Con poco aire (o letra grande) los rótulos se esconden: quedan las burbujas.
    return LayoutBuilder(
      builder: (context, r) {
        final compacto = this.compacto || r.maxWidth < pasos.length * 130;
        return Semantics(
          label: 'Paso ${actual + 1} de ${pasos.length}: ${pasos[actual]}',
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < pasos.length; i++) ...[
                      if (i > 0) linea(estirar: compacto),
                      if (compacto)
                        burbuja(i)
                      else
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              burbuja(i),
                              const SizedBox(width: Esp.s),
                              Flexible(
                                child: Text(
                                  pasos[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: i == actual ? Peso.titulo : Peso.normal,
                                    color: i == actual ? cs.onSurface : cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
                if (compacto) ...[
                  const SizedBox(height: Esp.s),
                  Text(
                    'PASO ${actual + 1} DE ${pasos.length} · ${pasos[actual].toUpperCase()}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(fontFamily: fuenteFija, letterSpacing: 1, color: cs.primary),
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

// ═══════════════════════════════════════════════════════════════════════════
// VACÍO CON GUÍA
// ═══════════════════════════════════════════════════════════════════════════

/// Estado vacío con guía: por qué no hay nada y el botón que lo resuelve. Es
/// el [MensajeVacio] del kit con una acción, y el texto secundario en
/// `onSurfaceVariant` para que el contraste no dependa de la semilla.
class VacioExamenes extends StatelessWidget {
  const VacioExamenes({
    super.key,
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.accion,
    this.iconoAccion,
    this.onAccion,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final String? accion;
  final IconData? iconoAccion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Esp.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // La burbuja de la hoja, en el color del tema: invita a marcar la primera.
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primaryContainer,
                  border: Border.all(color: cs.primary.withValues(alpha: 0.45), width: 2),
                ),
                child: Icon(icono, size: 34, color: cs.onPrimaryContainer),
              ),
              const SizedBox(height: Esp.l),
              Semantics(
                header: true,
                child: Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: Peso.titulo),
                ),
              ),
              const SizedBox(height: Esp.xs + 2),
              Text(
                detalle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              if (accion != null && onAccion != null) ...[
                const SizedBox(height: Esp.l),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: onAccion,
                  icon: Icon(iconoAccion ?? Icons.arrow_forward, size: 18),
                  label: Text(accion!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENTRADA SUAVE
// ═══════════════════════════════════════════════════════════════════════════

/// Aparece con un fundido y un desplazamiento corto hacia arriba. Una vez, al
/// montarse: sirve para que un aviso o un bloque nuevo se note sin saltar.
class EntradaSuave extends StatelessWidget {
  const EntradaSuave({super.key, required this.child, this.retraso = 0});

  final Widget child;

  /// En milisegundos, para escalonar bloques vecinos.
  final int retraso;

  @override
  Widget build(BuildContext context) {
    final d = duracionSuave(context, 220 + retraso);
    if (d == Duration.zero) return child;
    final inicio = retraso / (220 + retraso);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: d,
      curve: Interval(inicio, 1, curve: Curves.easeOutCubic),
      builder:
          (context, t, hijo) =>
              Opacity(opacity: t, child: Transform.translate(offset: Offset(0, (1 - t) * 8), child: hijo)),
      child: child,
    );
  }
}
