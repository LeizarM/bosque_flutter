/// Preguntas de la semana (`tcpeExamenes/PreguntaSemana`, v12/v13): una pregunta
/// abierta («¿Qué tal tu día?») o de escala que cada empleado ve en el inicio y
/// responde si quiere. Se publica con su plazo y se ve qué respondió cada uno.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_semana_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/editor_pregunta_semana.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/respuestas_pregunta_semana.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/tabla_examenes.dart';

/// null = todas; true / false = activas o inactivas.
final _activoProvider = StateProvider.autoDispose<bool?>((ref) => null);
final _enCursoProvider = StateProvider.autoDispose<Set<BigInt>>((ref) => {});

TonoExamen _tonoDe(EstadoPreguntaSemana e) => switch (e) {
  EstadoPreguntaSemana.vigente => TonoExamen.principal,
  EstadoPreguntaSemana.programada => TonoExamen.secundario,
  _ => TonoExamen.neutro,
};

class PreguntasSemanaScreen extends ConsumerWidget {
  const PreguntasSemanaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activo = ref.watch(_activoProvider);
    final datos = ref.watch(tcpePreguntasSemanaProvider(activo));
    final enCurso = ref.watch(_enCursoProvider);

    return LayoutBuilder(
      builder: (context, r) {
        final compacto = r.maxWidth < anchoTablaExamenes;
        final margen = compacto ? Esp.l : Esp.xl;
        return Scaffold(
          floatingActionButton:
              compacto
                  ? FloatingActionButton.extended(
                    onPressed: () => _editar(context, ref, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva'),
                  )
                  : null,
          body: Padding(
            padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, compacto ? 0 : Esp.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EncabezadoExamenes(
                  ceja: 'Exámenes · Preguntas de la semana',
                  titulo: 'Preguntas de la semana',
                  icono: Icons.forum_outlined,
                  detalle:
                      'Una pregunta que cada empleado ve en su inicio: abierta, como «¿Qué tal tu día?», o de '
                      'escala, como «Del 1 al 5, ¿cómo ves el ambiente laboral?». Responder es opcional y aquí '
                      'ves lo que respondió cada uno.',
                  compacto: compacto,
                  acciones: [
                    IconButton(
                      tooltip: 'Actualizar',
                      onPressed: () => ref.invalidate(tcpePreguntasSemanaProvider),
                      color: Theme.of(context).colorScheme.primary,
                      icon: const Icon(Icons.refresh),
                    ),
                    if (!compacto)
                      FilledButton.icon(
                        onPressed: () => _editar(context, ref, null),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Nueva pregunta'),
                      ),
                  ],
                ),
                const SizedBox(height: Esp.l),
                FiltrosExamenes(
                  compacto: compacto,
                  activos: activo == null ? 0 : 1,
                  onLimpiar: () => ref.read(_activoProvider.notifier).state = null,
                  campos: [
                    ComboFiltro<bool>(
                      etiqueta: 'Estado',
                      valor: activo,
                      textoTodos: 'Activas e inactivas',
                      opciones: const [(true, 'Activas'), (false, 'Inactivas')],
                      onCambio: (v) => ref.read(_activoProvider.notifier).state = v,
                    ),
                  ],
                ),
                const SizedBox(height: Esp.m),
                Expanded(
                  child: datos.when(
                    skipLoadingOnReload: true,
                    loading: () => const EsqueletoLista(),
                    error:
                        (e, _) =>
                            MensajeError(error: e, onReintentar: () => ref.invalidate(tcpePreguntasSemanaProvider)),
                    data:
                        (filas) => TablaExamenes<TcpePreguntaSemanaEntity>(
                          filas: filas,
                          claveFila: (p) => p.codPreguntaSemana,
                          tonoFila: (p) => _tonoDe(p.estadoHoy),
                          hayBotonFlotante: compacto,
                          alTocarFila: (p) => abrirRespuestasPreguntaSemana(context, p),
                          vacio:
                              activo == null
                                  ? VacioExamenes(
                                    icono: Icons.forum_outlined,
                                    titulo: 'Todavía no publicaste ninguna',
                                    detalle:
                                        'Escribe una pregunta, como «¿Qué tal tu día?»: cada empleado la ve en su '
                                        'inicio y, si quiere, responde con sus palabras o con un número de una '
                                        'escala.',
                                    accion: 'Nueva pregunta',
                                    iconoAccion: Icons.add,
                                    onAccion: () => _editar(context, ref, null),
                                  )
                                  : VacioExamenes(
                                    icono: Icons.filter_alt_off_outlined,
                                    titulo: activo ? 'No hay preguntas activas' : 'No hay preguntas inactivas',
                                    detalle: 'Prueba con otro estado.',
                                    accion: 'Ver todas',
                                    iconoAccion: Icons.filter_alt_off_outlined,
                                    onAccion: () => ref.read(_activoProvider.notifier).state = null,
                                  ),
                          columnas: [
                            ColumnaExamen('Estado', (p) => _estado(p, enCurso), flex: 2),
                            ColumnaExamen(
                              'Pregunta',
                              (p) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CeldaTexto(p.pregunta, fuerte: true, lineas: 2),
                                  CeldaTexto(oGuion(p.tituloMostrado ?? p.titulo), apagado: true),
                                ],
                              ),
                              flex: 7,
                            ),
                            ColumnaExamen(
                              'Tipo',
                              (p) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PastillaTipoSemana(p),
                                  if (p.esEscala && p.promedio != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: CeldaTexto('Promedio ${promedioSemanaTexto(p.promedio)}', apagado: true),
                                    ),
                                ],
                              ),
                              flex: 3,
                            ),
                            ColumnaExamen(
                              'Plazo',
                              (p) => CeldaTexto(plazoSemanaTexto(p.fechaInicio, p.fechaFin), apagado: true),
                              flex: 3,
                            ),
                            ColumnaExamen(
                              'Resp.',
                              (p) => CeldaNumero('${p.respuestas}', fuerte: p.respuestas > 0),
                              flex: 1,
                              alinear: Alignment.centerRight,
                            ),
                          ],
                          acciones: [
                            AccionExamen(
                              'Ver respuestas',
                              Icons.forum_outlined,
                              (p) => abrirRespuestasPreguntaSemana(context, p),
                              tono: TonoExamen.secundario,
                            ),
                            AccionExamen('Editar', Icons.edit_outlined, (p) => _editar(context, ref, p)),
                            AccionExamen(
                              'Desactivar',
                              Icons.block,
                              (p) => _alternar(context, ref, p),
                              visible: (p) => p.activo,
                              tono: TonoExamen.terciario,
                            ),
                            AccionExamen(
                              'Activar',
                              Icons.check_circle_outline,
                              (p) => _alternar(context, ref, p),
                              visible: (p) => !p.activo,
                            ),
                            AccionExamen(
                              'Eliminar',
                              Icons.delete_outline,
                              (p) => _eliminar(context, ref, p),
                              destructiva: true,
                              visible: (p) => p.respuestas == 0,
                            ),
                          ],
                          tarjeta:
                              (p) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          oGuion(p.tituloMostrado ?? p.titulo),
                                          style: context.apagado(),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      _estado(p, enCurso),
                                    ],
                                  ),
                                  const SizedBox(height: Esp.xs),
                                  Text(oGuion(p.pregunta), style: Theme.of(context).textTheme.titleSmall),
                                  const SizedBox(height: Esp.xs),
                                  Wrap(
                                    spacing: Esp.s,
                                    runSpacing: Esp.xs,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      PastillaTipoSemana(p),
                                      Text(
                                        [
                                          plazoSemanaTexto(p.fechaInicio, p.fechaFin),
                                          '${p.respuestas} ${p.respuestas == 1 ? 'respuesta' : 'respuestas'}',
                                          if (p.esEscala && p.promedio != null)
                                            'promedio ${promedioSemanaTexto(p.promedio)}',
                                        ].join(' · '),
                                        style: context.apagado(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _estado(TcpePreguntaSemanaEntity p, Set<BigInt> enCurso) {
    if (enCurso.contains(p.codPreguntaSemana)) {
      return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
    }
    return PastillaEstadoSemana(p.estadoHoy);
  }

  void _marcar(WidgetRef ref, BigInt cod, bool en) {
    final s = {...ref.read(_enCursoProvider)};
    en ? s.add(cod) : s.remove(cod);
    ref.read(_enCursoProvider.notifier).state = s;
  }

  Future<void> _editar(BuildContext context, WidgetRef ref, TcpePreguntaSemanaEntity? p) async {
    final ok = await abrirEditorPreguntaSemana(context, pregunta: p);
    if (ok) ref.invalidate(tcpePreguntasSemanaProvider);
  }

  Future<void> _alternar(BuildContext context, WidgetRef ref, TcpePreguntaSemanaEntity p) async {
    if (p.activo) {
      final ok = await confirmar(
        context,
        titulo: 'Desactivar la pregunta de la semana',
        detalle: 'Deja de aparecer en el inicio y ya no se puede responder. Las respuestas que tiene se conservan.',
        textoConfirmar: 'Desactivar',
      );
      if (!ok || !context.mounted) return;
    }
    _marcar(ref, p.codPreguntaSemana, true);
    try {
      final msg = await ref.read(examenesRepositoryProvider).activarPreguntaSemana(p.codPreguntaSemana, !p.activo);
      ref.invalidate(tcpePreguntasSemanaProvider);
      if (context.mounted) avisar(context, msg ?? (p.activo ? 'Pregunta desactivada.' : 'Pregunta activada.'));
    } catch (e) {
      if (context.mounted) avisar(context, textoParaUsuario(e), esError: true);
    } finally {
      if (context.mounted) _marcar(ref, p.codPreguntaSemana, false);
    }
  }

  Future<void> _eliminar(BuildContext context, WidgetRef ref, TcpePreguntaSemanaEntity p) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar la pregunta de la semana',
      detalle: 'Se quita del inicio y de esta lista.',
      textoConfirmar: 'Eliminar',
      destructiva: true,
    );
    if (!ok || !context.mounted) return;
    _marcar(ref, p.codPreguntaSemana, true);
    try {
      final msg = await ref.read(examenesRepositoryProvider).eliminarPreguntaSemana(p.codPreguntaSemana);
      ref.invalidate(tcpePreguntasSemanaProvider);
      if (context.mounted) avisar(context, msg ?? 'Pregunta de la semana eliminada.');
    } catch (e) {
      if (context.mounted) avisar(context, textoParaUsuario(e), esError: true);
    } finally {
      if (context.mounted) _marcar(ref, p.codPreguntaSemana, false);
    }
  }
}
