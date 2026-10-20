/// El resultado de un examen entregado para quien lo rindió (postulante o
/// empleado): la nota sobre 100, si aprobó según la nota mínima del lote y la
/// devolución pregunta por pregunta. En `POR_REVISAR` solo espera.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_config_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_devolucion_item_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_examen.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_rendicion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';

/// Ancho máximo del resultado en escritorio: la devolución usa todo el ancho.
const double _anchoMaximo = 1080;

class ResultadoExamen extends ConsumerWidget {
  const ResultadoExamen({
    super.key,
    required this.clave,
    required this.estado,
    this.onSalir,
    this.textoSalir = 'Volver a mis exámenes',
  });

  final ClaveRendicion clave;
  final TcpeEstadoRendicionEntity estado;
  final VoidCallback? onSalir;
  final String textoSalir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(configExamenesProvider(clave.origen)).valueOrNull ?? TcpeConfiguracion.respaldo;
    // Rendir F no devuelve filas en POR_REVISAR (espera la revisión) ni en AUSENTE (no rindió): ni se pide.
    final s = EstadoExamenTcpe.desde(estado.estado);
    final espera = s == EstadoExamenTcpe.porRevisar || s == EstadoExamenTcpe.ausente;
    final proveedor = devolucionExamenProvider(clave);
    final devolucion = espera ? const AsyncData(<TcpeDevolucionPreguntaEntity>[]) : ref.watch(proveedor);
    return LayoutBuilder(
      builder: (context, r) {
        final compacto = r.maxWidth < anchoTablaExamenes;
        final margen = compacto ? Esp.l : Esp.xl;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, Esp.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _anchoMaximo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CabeceraResultado(
                    estado: estado,
                    preguntas: devolucion.valueOrNull,
                    compacto: compacto,
                    onSalir: onSalir,
                    textoSalir: textoSalir,
                    textoEspera: cfg.msgPendienteRevision,
                  ),
                  if (!espera) ...[
                    const SizedBox(height: Esp.xl),
                    devolucion.when(
                    loading:
                        () => const SizedBox(height: 320, child: EsqueletoLista(filas: 4, altoFila: 64)),
                    error:
                        (e, _) => MensajeError(error: e, compacto: true, onReintentar: () => ref.invalidate(proveedor)),
                    data:
                        (preguntas) =>
                            preguntas.isEmpty
                                ? const NotaDelDato(
                                  texto: 'La devolución pregunta por pregunta aparece cuando el examen queda entregado.',
                                )
                                : DevolucionExamen(preguntas: preguntas, compacto: compacto),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CABECERA: NOTA Y APROBACIÓN
// ═══════════════════════════════════════════════════════════════════════════

class CabeceraResultado extends StatelessWidget {
  const CabeceraResultado({
    super.key,
    required this.estado,
    required this.compacto,
    this.preguntas,
    this.onSalir,
    this.textoSalir = 'Volver a mis exámenes',
    this.textoEspera,
  });

  final TcpeEstadoRendicionEntity estado;
  final bool compacto;

  /// `msgPendienteRevision` de la configuración, si no vino `mensajeEstado`.
  final String? textoEspera;

  /// La devolución, para el resumen de aciertos (null mientras carga).
  final List<TcpeDevolucionPreguntaEntity>? preguntas;
  final VoidCallback? onSalir;
  final String textoSalir;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = EstadoExamenTcpe.desde(estado.estado);
    final (icono, titulo, respaldo) = switch (s) {
      EstadoExamenTcpe.calificado => (Icons.verified_outlined, 'Examen calificado', 'Esta es tu nota sobre 100.'),
      EstadoExamenTcpe.porRevisar => (
        Icons.hourglass_top_outlined,
        'Examen entregado',
        textoEspera ?? TcpeConfiguracion.respaldo.msgPendienteRevision,
      ),
      EstadoExamenTcpe.ausente => (
        Icons.event_busy_outlined,
        'Ausente',
        'No empezaste el examen dentro de su horario.',
      ),
      _ => (
        Icons.timer_off_outlined,
        'Se terminó el tiempo',
        'El examen ya no admite respuestas. Lo que alcanzaste a guardar queda registrado.',
      ),
    };
    // El texto de cada estado sale de SQL; el de arriba es solo el respaldo.
    final detalle = (estado.mensajeEstado ?? '').trim().isNotEmpty ? estado.mensajeEstado!.trim() : respaldo;
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icono, size: 20, color: cs.primary),
            const SizedBox(width: Esp.s),
            Flexible(
              child: Text(
                (estado.nombreClasificacion ?? 'Examen').toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFamily: fuenteFija,
                  color: cs.primary,
                  letterSpacing: 1.4,
                  fontWeight: Peso.titulo,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Esp.xs),
        Text(
          estado.titulo ?? 'Examen',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: Peso.titulo),
        ),
        const SizedBox(height: Esp.s),
        Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: Esp.xs),
        Text(detalle, style: context.apagado()),
        const SizedBox(height: Esp.m),
        Text(
          [
            '${estado.respondidas} de ${estado.totalPreguntas} preguntas respondidas',
            if (estado.fechaFin != null) 'Entregado el ${fechaHora(estado.fechaFin)}',
          ].join(' · '),
          style: context.apagado(),
        ),
        if (preguntas != null && preguntas!.isNotEmpty) ...[
          const SizedBox(height: Esp.m),
          _Resumen(preguntas: preguntas!),
        ],
      ],
    );
    final notaBloque = s != EstadoExamenTcpe.porRevisar && estado.notaVisible != null ? _Nota(estado: estado) : null;
    final ocultas = preguntas != null && preguntas!.any((p) => p.esCerrada) && !preguntas!.any((p) => p.muestraCorrectas);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerLowest,
      shape: contornoSuperficie(cs),
      child: Padding(
        padding: EdgeInsets.all(compacto ? Esp.l : Esp.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compacto || notaBloque == null) ...[
              textos,
              if (notaBloque != null) ...[const SizedBox(height: Esp.l), notaBloque],
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: textos),
                  const SizedBox(width: Esp.xl),
                  ConstrainedBox(constraints: const BoxConstraints(maxWidth: 300), child: notaBloque),
                ],
              ),
            if (ocultas)
              const NotaDelDato(
                texto: 'Este examen no muestra cuáles eran las respuestas correctas: solo ves si acertaste o fallaste.',
              ),
            if (onSalir != null) ...[
              const SizedBox(height: Esp.l),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(onPressed: onSalir, child: Text(textoSalir)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// La nota grande con Aprobado o Reprobado y la nota mínima.
class _Nota extends StatelessWidget {
  const _Nota({required this.estado});

  final TcpeEstadoRendicionEntity estado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final aprobado = estado.aprobacion;
    final color = aprobado == false ? cs.error : cs.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: nota(estado.notaVisible),
                style: TextStyle(fontFamily: fuenteFija, fontSize: 44, fontWeight: FontWeight.w700, color: color),
              ),
              TextSpan(
                text: ' / 100',
                style: TextStyle(fontFamily: fuenteFija, fontSize: 18, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: Esp.xs),
        Wrap(
          spacing: Esp.s,
          runSpacing: Esp.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (aprobado != null)
              Etiqueta(texto: aprobado ? 'Aprobado' : 'Reprobado', tono: aprobado ? TonoEtiqueta.exito : TonoEtiqueta.error),
            if (estado.notaAprobacion != null)
              Text('Nota mínima ${nota(estado.notaAprobacion)}', style: context.apagado()),
          ],
        ),
      ],
    );
  }
}

/// Cuántas acertó, cuántas falló y cuántas esperan revisión.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.preguntas});

  final List<TcpeDevolucionPreguntaEntity> preguntas;

  @override
  Widget build(BuildContext context) {
    final bien = preguntas.where((p) => p.esCorrecta == true).length;
    final mal = preguntas.where((p) => p.esCorrecta == false).length;
    final pendientes = preguntas.where((p) => p.pendiente).length;
    return Wrap(
      spacing: Esp.l,
      runSpacing: Esp.s,
      children: [
        _Marca(resultado: true, texto: '$bien ${bien == 1 ? 'acertada' : 'acertadas'}'),
        _Marca(resultado: false, texto: '$mal ${mal == 1 ? 'fallada' : 'falladas'}'),
        if (pendientes > 0) _Marca(resultado: null, texto: '$pendientes pendientes de revisión'),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DEVOLUCIÓN PREGUNTA POR PREGUNTA
// ═══════════════════════════════════════════════════════════════════════════

/// Cada pregunta con ✓ o ✗ y las opciones con lo que marcó quien rindió. Las
/// correctas se resaltan solo si el lote las muestra (`esValido` informado).
/// Escritorio: lista amplia con columnas; teléfono: tarjetas.
class DevolucionExamen extends StatelessWidget {
  const DevolucionExamen({super.key, required this.preguntas, required this.compacto});

  final List<TcpeDevolucionPreguntaEntity> preguntas;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titulo = Text('Tus respuestas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: Peso.titulo));
    if (compacto) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titulo,
          const SizedBox(height: Esp.m),
          for (var i = 0; i < preguntas.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Esp.m),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: cs.surfaceContainerLowest,
                shape: contornoSuperficie(cs, color: _borde(cs, preguntas[i])),
                child: Padding(
                  padding: const EdgeInsets.all(Esp.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'PREGUNTA ${i + 1}',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontFamily: fuenteFija, letterSpacing: 0.8),
                            ),
                          ),
                          _Marca(resultado: preguntas[i].esCorrecta),
                        ],
                      ),
                      const SizedBox(height: Esp.s),
                      CuerpoPreguntaDevuelta(pregunta: preguntas[i], columnas: 1),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    }
    final rotulo = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: cs.onPrimaryContainer,
      fontWeight: Peso.titulo,
      letterSpacing: 0.6,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        titulo,
        const SizedBox(height: Esp.m),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: cs.surfaceContainerLowest,
          shape: contornoSuperficie(cs),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Color.alphaBlend(cs.primaryContainer.withValues(alpha: 0.7), cs.surface),
                padding: const EdgeInsets.symmetric(horizontal: Esp.l, vertical: Esp.s + 2),
                child: Row(
                  children: [
                    SizedBox(width: 48, child: Text('N°', style: rotulo)),
                    Expanded(child: Text('PREGUNTA Y TU RESPUESTA', style: rotulo)),
                    SizedBox(width: 200, child: Text('RESULTADO', style: rotulo)),
                  ],
                ),
              ),
              for (var i = 0; i < preguntas.length; i++) ...[
                Divider(height: 1, color: cs.outlineVariant),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Esp.l, vertical: Esp.m + 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text('${i + 1}', style: const TextStyle(fontFamily: fuenteFija, fontWeight: FontWeight.w700)),
                      ),
                      Expanded(child: CuerpoPreguntaDevuelta(pregunta: preguntas[i], columnas: 2)),
                      SizedBox(
                        width: 200,
                        child: Padding(
                          padding: const EdgeInsets.only(left: Esp.l),
                          child: Align(alignment: Alignment.topLeft, child: _Marca(resultado: preguntas[i].esCorrecta)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static Color _borde(ColorScheme cs, TcpeDevolucionPreguntaEntity p) => switch (p.esCorrecta) {
    true => cs.primary.withValues(alpha: 0.5),
    false => cs.error.withValues(alpha: 0.5),
    null => cs.tertiary.withValues(alpha: 0.6),
  };
}

/// Una pregunta en solo lectura: el enunciado y, debajo, las opciones con lo
/// marcado (y las válidas, si vienen) o la respuesta escrita. Lo reutiliza el
/// espejo del panel "En vivo".
class CuerpoPreguntaDevuelta extends StatelessWidget {
  const CuerpoPreguntaDevuelta({super.key, required this.pregunta, this.columnas = 1, this.paraEvaluador = false});

  final TcpeDevolucionPreguntaEntity pregunta;

  /// Opciones por fila cuando hay ancho (escritorio).
  final int columnas;

  /// La ve el evaluador (espejo): se habla de quien rinde en tercera persona.
  final bool paraEvaluador;

  @override
  Widget build(BuildContext context) {
    final p = pregunta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectableText(p.pregunta ?? '', style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.35)),
        const SizedBox(height: Esp.s),
        if (p.esCerrada) ...[
          if (p.opciones.isEmpty)
            Text('Sin opciones registradas.', style: context.apagado())
          else
            LayoutBuilder(
              builder: (context, r) {
                final porFila = columnas > 1 && r.maxWidth >= 560 ? columnas : 1;
                final ancho = (r.maxWidth - Esp.s * (porFila - 1)) / porFila;
                return Wrap(
                  spacing: Esp.s,
                  runSpacing: Esp.s,
                  children: [
                    for (var k = 0; k < p.opciones.length; k++)
                      SizedBox(
                        width: ancho,
                        child: _OpcionDevuelta(opcion: p.opciones[k], letra: k, muestraCorrectas: p.muestraCorrectas),
                      ),
                  ],
                );
              },
            ),
          if (!p.respondida) ...[
            const SizedBox(height: Esp.xs),
            Text(paraEvaluador ? 'No marcó ninguna opción.' : 'No marcaste ninguna opción.', style: context.apagado()),
          ],
        ] else
          _RespuestaEscrita(texto: p.respuestaU, rotulo: paraEvaluador ? 'Respuesta escrita' : 'Tu respuesta'),
      ],
    );
  }
}

class _OpcionDevuelta extends StatelessWidget {
  const _OpcionDevuelta({required this.opcion, required this.letra, required this.muestraCorrectas});

  final TcpeDevolucionItemEntity opcion;
  final int letra;
  final bool muestraCorrectas;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final marcada = opcion.marcada;
    final valida = muestraCorrectas && opcion.esValido == true;
    final errada = muestraCorrectas && marcada && opcion.esValido == false;
    final (fondo, borde) =
        valida
            ? (cs.primaryContainer.withValues(alpha: 0.55), cs.primary)
            : errada
            ? (cs.errorContainer.withValues(alpha: 0.55), cs.error)
            : marcada
            ? (cs.surfaceContainerHighest, cs.outline)
            : (cs.surface, cs.outlineVariant);
    final etiqueta =
        valida
            ? const Etiqueta(texto: 'Correcta', tono: TonoEtiqueta.exito)
            : errada
            ? const Etiqueta(texto: 'No era correcta', tono: TonoEtiqueta.error)
            : null;
    return Semantics(
      label: [
        'Opción ${String.fromCharCode(97 + letra % 26)}',
        marcada ? 'marcada' : 'sin marcar',
        if (valida) 'correcta',
      ].join(', '),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(Esquina.chica),
          border: Border.all(color: borde, width: valida || errada ? 1.5 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              marcada ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: marcada ? (errada ? cs.error : cs.primary) : cs.outline,
            ),
            const SizedBox(width: Esp.s),
            Text(
              '${String.fromCharCode(97 + letra % 26)})',
              style: TextStyle(fontFamily: fuenteFija, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: Esp.s),
            Expanded(child: Text(opcion.opcionRspta ?? '')),
            if (etiqueta != null) ...[const SizedBox(width: Esp.s), etiqueta],
          ],
        ),
      ),
    );
  }
}

class _RespuestaEscrita extends StatelessWidget {
  const _RespuestaEscrita({required this.texto, required this.rotulo});

  final String? texto;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vacia = (texto ?? '').trim().isEmpty;
    return Container(
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.chica),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: context.apagado()),
          const SizedBox(height: Esp.xs),
          vacia ? Text('Sin respuesta', style: context.apagado()) : SelectableText(texto!),
        ],
      ),
    );
  }
}

/// ✓ acertó, ✗ falló o pendiente de revisión, con su texto.
class _Marca extends StatelessWidget {
  const _Marca({required this.resultado, this.texto});

  final bool? resultado;
  final String? texto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icono, color, rotulo) = switch (resultado) {
      true => (Icons.check_circle, cs.primary, 'Acertaste'),
      false => (Icons.cancel, cs.error, 'Fallaste'),
      null => (Icons.hourglass_top_rounded, cs.tertiary, 'Pendiente de revisión'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 18, color: color),
        const SizedBox(width: Esp.xs + 2),
        Flexible(
          child: Text(
            texto ?? rotulo,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color, fontWeight: Peso.titulo),
          ),
        ),
      ],
    );
  }
}
