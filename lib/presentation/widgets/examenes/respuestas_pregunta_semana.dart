/// Las respuestas de una pregunta de la semana (`p_list_tcpe_PreguntaSemana` R):
/// quién respondió, su cargo, qué (texto o número) y cuándo; si es de escala,
/// el promedio y cuántos eligieron cada número (E). Una respuesta se puede quitar.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_escala_semana_entity.dart';
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

/// El promedio de una escala con un decimal: `3.75` → `3,8`.
String promedioSemanaTexto(double? p) => p == null ? '--' : p.toStringAsFixed(1).replaceAll('.', ',');

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
    return [f.nombreCompleto, f.login, f.cargo, f.respuesta, f.valor?.toString()]
        .any((x) => (x ?? '').toLowerCase().contains(q));
  }

  Future<void> _quitar(TcpeRespondioSemanaEntity f) async {
    final ok = await confirmar(
      context,
      titulo: 'Quitar la respuesta',
      detalle:
          'Se borra lo que respondió ${oGuion(f.nombreCompleto ?? f.login)}. Podrá volver a responder mientras la '
          'pregunta esté vigente.',
      textoConfirmar: 'Quitar',
      destructiva: true,
    );
    if (!ok || !mounted) return;
    setState(() => _quitando.add(f.codRsptaSemana));
    try {
      final msg = await ref.read(examenesRepositoryProvider).quitarRespuestaSemana(f.codRsptaSemana);
      ref.invalidate(tcpeRespuestasSemanaProvider(widget.pregunta.codPreguntaSemana));
      ref.invalidate(tcpeDistribucionSemanaProvider(widget.pregunta.codPreguntaSemana));
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
                PastillaTipoSemana(pregunta),
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
                        if (pregunta.esEscala) _CifraPromedio(pregunta: pregunta),
                      ],
                    ),
                    if (pregunta.esEscala) ...[
                      const SizedBox(height: Esp.l),
                      Text('Cómo respondieron', style: context.tituloSeccion()),
                      const SizedBox(height: Esp.s),
                      _Distribucion(pregunta: pregunta),
                    ],
                    const SizedBox(height: Esp.l),
                    Text(
                      pregunta.esEscala ? 'Lo que eligió cada uno' : 'Lo que respondieron',
                      style: context.tituloSeccion(),
                    ),
                    const SizedBox(height: Esp.s),
                    if (filas.length > _conBuscador) ...[
                      TextField(
                        onChanged: (v) => setState(() => _filtro = v),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText:
                              pregunta.esEscala ? 'Buscar por nombre, cargo o número' : 'Buscar por nombre, cargo o respuesta',
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
                          pregunta: pregunta,
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

/// Abierta o de escala, como pastilla; el texto lo arma el SP («Escala del 1 al 5»).
class PastillaTipoSemana extends StatelessWidget {
  const PastillaTipoSemana(this.pregunta, {super.key});

  final TcpePreguntaSemanaEntity pregunta;

  @override
  Widget build(BuildContext context) {
    final p = pregunta;
    final mostrado = (p.tipoMostrado ?? '').trim();
    final texto =
        mostrado.isNotEmpty
            ? mostrado
            : (p.esEscala ? 'Escala del ${p.escalaMin ?? '--'} al ${p.escalaMax ?? '--'}' : 'Abierta');
    return PastillaExamen(
      texto: texto,
      tono: p.esEscala ? TonoExamen.secundario : TonoExamen.terciario,
      icono: p.esEscala ? Icons.linear_scale : Icons.notes,
    );
  }
}

/// El promedio de una escala; mientras llega la distribución, el de la lista.
class _CifraPromedio extends ConsumerWidget {
  const _CifraPromedio({required this.pregunta});

  final TcpePreguntaSemanaEntity pregunta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filas = ref.watch(tcpeDistribucionSemanaProvider(pregunta.codPreguntaSemana)).valueOrNull;
    final promedio = filas == null ? pregunta.promedio : (filas.isEmpty ? null : filas.first.promedio);
    return CifraExamen(
      valor: promedioSemanaTexto(promedio),
      rotulo: 'promedio, del ${pregunta.escalaMin ?? '--'} al ${pregunta.escalaMax ?? '--'}',
      icono: Icons.insights_outlined,
      tono: TonoExamen.principal,
    );
  }
}

/// Cuántos eligieron cada número, una barra por valor (también los que nadie
/// eligió), con la etiqueta de los extremos. La barra más larga va resaltada.
class _Distribucion extends ConsumerWidget {
  const _Distribucion({required this.pregunta});

  final TcpePreguntaSemanaEntity pregunta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cod = pregunta.codPreguntaSemana;
    return ref
        .watch(tcpeDistribucionSemanaProvider(cod))
        .when(
          skipLoadingOnReload: true,
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => _Reintentar(error: e, onTap: () => ref.invalidate(tcpeDistribucionSemanaProvider(cod))),
          data: (filas) {
            if (filas.isEmpty) return const SizedBox.shrink();
            final mayor = filas.map((f) => f.cantidad).reduce(math.max);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final f in filas)
                  _BarraEscala(
                    fila: f,
                    min: filas.first.valor,
                    max: filas.last.valor,
                    destacada: f.cantidad > 0 && f.cantidad == mayor,
                  ),
              ],
            );
          },
        );
  }
}

class _BarraEscala extends StatelessWidget {
  const _BarraEscala({required this.fila, required this.min, required this.max, required this.destacada});

  final TcpeEscalaSemanaEntity fila;
  final int min;
  final int max;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = fila;
    final etiqueta = (f.etiqueta ?? '').trim();
    final personas = f.cantidad == 1 ? 'persona' : 'personas';
    return Semantics(
      label:
          '${valorEscalaTexto(f.valor, min: min, max: max, etiquetaMin: etiqueta, etiquetaMax: etiqueta)}: '
          '${f.cantidad} $personas, ${porcentajeTexto(f.porcentaje)}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Esp.xs),
        child: Row(
          children: [
            NumeroEscala(valor: f.valor, min: min, max: max),
            const SizedBox(width: Esp.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (etiqueta.isNotEmpty) Text(etiqueta, style: context.apagado()),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Esquina.pastilla),
                    child: SizedBox(
                      height: 12,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(color: cs.surfaceContainerHighest),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (f.porcentaje / 100).clamp(0.0, 1.0),
                            child: ColoredBox(color: destacada ? cs.primary : cs.primary.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Esp.m),
            SizedBox(
              width: 96,
              child: Text(
                '${f.cantidad} · ${porcentajeTexto(f.porcentaje)}',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: destacada ? Peso.dato : null,
                  fontFeatures: cifrasTabulares,
                ),
              ),
            ),
          ],
        ),
      ),
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
  const _FilaRespuesta({
    required this.fila,
    required this.pregunta,
    required this.ancha,
    required this.quitando,
    required this.onQuitar,
  });

  final TcpeRespondioSemanaEntity fila;
  final TcpePreguntaSemanaEntity pregunta;
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
                if (pregunta.esEscala && f.valor != null)
                  _ValorElegido(valor: f.valor!, pregunta: pregunta)
                else
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

/// El número que eligió alguien: su círculo y, al lado, «de 5» y la etiqueta si es un extremo.
class _ValorElegido extends StatelessWidget {
  const _ValorElegido({required this.valor, required this.pregunta});

  final int valor;
  final TcpePreguntaSemanaEntity pregunta;

  @override
  Widget build(BuildContext context) {
    final p = pregunta;
    final min = p.escalaMin ?? 0;
    final max = p.escalaMax ?? valor;
    final etiqueta = ((valor == min ? p.etiquetaMin : (valor == max ? p.etiquetaMax : null)) ?? '').trim();
    return Semantics(
      label: valorEscalaTexto(valor, min: min, max: max, etiquetaMin: p.etiquetaMin, etiquetaMax: p.etiquetaMax),
      excludeSemantics: true,
      child: Row(
        children: [
          NumeroEscala(valor: valor, min: min, max: max, lado: 36),
          const SizedBox(width: Esp.s),
          Flexible(child: Text(['de $max', if (etiqueta.isNotEmpty) etiqueta].join(' · '), style: context.apagado())),
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
