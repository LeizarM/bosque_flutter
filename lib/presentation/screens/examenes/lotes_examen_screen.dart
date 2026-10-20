/// Lotes de exámenes (`tcpeExamenes/Lotes`): generar exámenes para
/// postulantes externos o empleados, imprimir credenciales y exámenes escritos,
/// y seguir el avance de cada lote.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_lote_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/detalle_lote.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/dialogos_lote.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/tabla_examenes.dart';

final _filtroProvider = StateProvider.autoDispose<FiltroLotes>(
  (ref) => (codArea: null, codClasificacion: null, modalidad: null),
);
final _abiertoProvider = StateProvider.autoDispose<BigInt?>((ref) => null);

class LotesExamenScreen extends ConsumerWidget {
  const LotesExamenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(_filtroProvider);
    final lotes = ref.watch(tcpeLotesProvider(filtro));
    final abierto = ref.watch(_abiertoProvider);

    void refrescar() => ref.invalidate(tcpeLotesProvider);

    final lote = abierto == null ? null : lotes.valueOrNull?.where((l) => l.codRolExamen == abierto).firstOrNull;
    if (lote != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) ref.read(_abiertoProvider.notifier).state = null;
        },
        child: Scaffold(
          body: DetalleLote(
            key: ValueKey(lote.codRolExamen),
            lote: lote,
            onVolver: () => ref.read(_abiertoProvider.notifier).state = null,
            onCambio: refrescar,
            onCalificar:
                () => context.go('/dashboard/${AppConstants.rutaTcpeResultados}', extra: lote.codRolExamen),
            onEnVivo: () => context.go('/dashboard/${AppConstants.rutaTcpeEnVivo}', extra: lote.codRolExamen),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, r) {
        final compacto = r.maxWidth < anchoTablaExamenes;
        final margen = compacto ? Esp.l : Esp.xl;

        Future<void> generar() async {
          final res = await abrirFormularioLote(context);
          if (res is! LoteRecienGenerado || !context.mounted) return;
          refrescar();
          ref.read(_abiertoProvider.notifier).state = res.generado.codRolExamen;
          await avisarGenerados(context, res);
        }

        return Scaffold(
          floatingActionButton:
              compacto
                  ? FloatingActionButton.extended(
                    onPressed: generar,
                    icon: const Icon(Icons.add),
                    label: const Text('Generar lote'),
                  )
                  : null,
          body: Padding(
            padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, compacto ? 0 : Esp.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EncabezadoExamenes(
                  ceja: 'Exámenes · Lotes',
                  titulo: 'Lotes de exámenes',
                  icono: Icons.inventory_2_outlined,
                  detalle: 'Un lote reúne los exámenes de una convocatoria o evaluación: misma categoría, duración y fecha.',
                  compacto: compacto,
                  acciones: [
                    IconButton(
                      tooltip: 'Actualizar',
                      onPressed: refrescar,
                      color: Theme.of(context).colorScheme.primary,
                      icon: const Icon(Icons.refresh),
                    ),
                    if (!compacto)
                      FilledButton.icon(
                        onPressed: generar,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Generar lote'),
                      ),
                  ],
                ),
                const SizedBox(height: Esp.l),
                _Filtros(compacto: compacto),
                const SizedBox(height: Esp.m),
                Expanded(
                  child: lotes.when(
                    skipLoadingOnReload: true,
                    loading: () => const EsqueletoLista(),
                    error: (e, _) => MensajeError(error: e, onReintentar: refrescar),
                    data:
                        (lista) => TablaExamenes<TcpeLoteEntity>(
                          filas: lista,
                          claveFila: (l) => l.codRolExamen,
                          hayBotonFlotante: true,
                          alTocarFila: (l) => ref.read(_abiertoProvider.notifier).state = l.codRolExamen,
                          // La franja dice la modalidad, igual que su pastilla.
                          tonoFila: (l) => l.modalidad == 'E' ? TonoExamen.terciario : TonoExamen.principal,
                          vacio:
                              filtro.codArea == null && filtro.codClasificacion == null && filtro.modalidad == null
                                  ? VacioExamenes(
                                    icono: Icons.inventory_2_outlined,
                                    titulo: 'Todavía no hay lotes',
                                    detalle:
                                        'Un lote reparte un examen distinto a cada persona. Elige la categoría, la duración y '
                                        'a quiénes va dirigido.',
                                    accion: 'Generar el primer lote',
                                    iconoAccion: Icons.add,
                                    onAccion: generar,
                                  )
                                  : VacioExamenes(
                                    icono: Icons.filter_alt_off_outlined,
                                    titulo: 'Ningún lote coincide',
                                    detalle: 'Quita algún filtro para ver más lotes.',
                                    accion: 'Quitar filtros',
                                    iconoAccion: Icons.filter_alt_off_outlined,
                                    onAccion:
                                        () => ref.read(_filtroProvider.notifier).state = (
                                          codArea: null,
                                          codClasificacion: null,
                                          modalidad: null,
                                        ),
                                  ),
                          columnas: [
                            ColumnaExamen(
                              'Lote',
                              (l) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [CeldaTexto(l.titulo, fuerte: true), CeldaTexto(l.nombreClasificacion, apagado: true)],
                              ),
                              flex: 5,
                            ),
                            ColumnaExamen('Modalidad', (l) => PastillaModalidad(l.modalidad), flex: 2),
                            ColumnaExamen('Ventana', (l) => CeldaTexto(ventanaTexto(l), apagado: true), flex: 3),
                            ColumnaExamen('Duración', (l) => CeldaTexto(duracionTexto(l.duracionMinutos)), flex: 2),
                            ColumnaExamen('Preg.', (l) => CeldaNumero('${l.cantidadPreg ?? 0}'), flex: 1, alinear: Alignment.centerRight),
                            ColumnaExamen('Avance', (l) => _Avance(lote: l), flex: 4),
                            ColumnaExamen('Mín.', (l) => CeldaNumero(nota(l.notaAprobacion)), flex: 1, alinear: Alignment.centerRight),
                            ColumnaExamen('Aprob. / Repr.', (l) => _AprobadosReprobados(lote: l), flex: 2, alinear: Alignment.centerRight),
                            ColumnaExamen(
                              'Prom.',
                              (l) => CeldaNota(l.promedio, minima: l.notaAprobacion),
                              flex: 1,
                              alinear: Alignment.centerRight,
                            ),
                          ],
                          acciones: [
                            AccionExamen('Ver detalle', Icons.open_in_new, (l) => ref.read(_abiertoProvider.notifier).state = l.codRolExamen),
                            AccionExamen('Agregar exámenes', Icons.group_add_outlined, (l) async {
                              final res = await agregarExamenes(context, l);
                              if (res == null || !context.mounted) return;
                              refrescar();
                              await avisarGenerados(context, res);
                            }, tono: TonoExamen.secundario),
                          ],
                          tarjeta:
                              (l) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: Esp.s,
                                    runSpacing: Esp.xs,
                                    children: [
                                      PastillaModalidad(l.modalidad),
                                      PastillaExamen(
                                        texto: duracionTexto(l.duracionMinutos),
                                        tono: TonoExamen.secundario,
                                        icono: Icons.timer_outlined,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: Esp.s),
                                  Text(oGuion(l.titulo), style: Theme.of(context).textTheme.titleSmall),
                                  const SizedBox(height: Esp.xs),
                                  Text(oGuion(l.nombreClasificacion), style: context.apagado()),
                                  Text('Ventana ${ventanaTexto(l)}', style: context.apagado()),
                                  Text(
                                    'Nota mínima ${nota(l.notaAprobacion)} · ${l.aprobados} aprobados · ${l.reprobados} reprobados',
                                    style: context.apagado(),
                                  ),
                                  const SizedBox(height: Esp.m),
                                  _Avance(lote: l, leyenda: true),
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
}

/// La tira del lote: cada estado como un tramo, y en texto lo que falta.
class _Avance extends StatelessWidget {
  const _Avance({required this.lote, this.leyenda = false});

  final TcpeLoteEntity lote;
  final bool leyenda;

  @override
  Widget build(BuildContext context) {
    final total = lote.examenes;
    if (leyenda) return TiraEstados(tramos: tramosDeLote(lote));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TiraEstados(tramos: tramosDeLote(lote), leyenda: false, alto: 8),
        const SizedBox(height: Esp.xs),
        Text(
          [
            '${lote.calificados}/$total calificados',
            if (lote.porRevisar > 0) '${lote.porRevisar} por revisar',
            if (lote.enCurso > 0) '${lote.enCurso} en curso',
            if (lote.vencidos > 0) '${lote.vencidos} vencidos',
            if (lote.ausentes > 0) '${lote.ausentes} ausentes',
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.apagado(),
        ),
      ],
    );
  }
}

/// Aprobados en el tono de éxito y reprobados en el de error.
class _AprobadosReprobados extends StatelessWidget {
  const _AprobadosReprobados({required this.lote});

  final TcpeLoteEntity lote;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${lote.aprobados}', style: TextStyle(color: cs.primary)),
          const TextSpan(text: ' / '),
          TextSpan(text: '${lote.reprobados}', style: TextStyle(color: lote.reprobados > 0 ? cs.error : null)),
        ],
      ),
      style: context.numero(fuerte: true),
    );
  }
}

class _Filtros extends ConsumerWidget {
  const _Filtros({required this.compacto});

  final bool compacto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(_filtroProvider);
    final areas = ref.watch(tcpeAreasProvider).valueOrNull ?? const [];
    final categorias = ref.watch(tcpeCategoriasProvider).valueOrNull ?? const [];
    void cambiar(FiltroLotes n) => ref.read(_filtroProvider.notifier).state = n;
    final activos = [f.codArea, f.codClasificacion, f.modalidad].where((v) => v != null).length;
    return FiltrosExamenes(
      compacto: compacto,
      activos: activos,
      onLimpiar: () => cambiar((codArea: null, codClasificacion: null, modalidad: null)),
      campos: [
        ComboFiltro<BigInt>(
          etiqueta: 'Área',
          valor: f.codArea,
          textoTodos: 'Todas',
          opciones: [for (final a in areas) (a.codArea, a.nombreArea ?? '')],
          onCambio: (v) => cambiar((codArea: v, codClasificacion: null, modalidad: f.modalidad)),
        ),
        ComboFiltro<BigInt>(
          etiqueta: 'Categoría',
          valor: f.codClasificacion,
          textoTodos: 'Todas',
          ancho: 260,
          opciones: [
            for (final c in categorias)
              if (f.codArea == null || c.codArea == f.codArea) (c.codClasificacion, c.nombre ?? ''),
          ],
          onCambio: (v) => cambiar((codArea: f.codArea, codClasificacion: v, modalidad: f.modalidad)),
        ),
        ComboFiltro<String>(
          etiqueta: 'Modalidad',
          valor: f.modalidad,
          textoTodos: 'Todas',
          ancho: 180,
          opciones: const [('O', 'En línea'), ('E', 'Escrito')],
          onCambio: (v) => cambiar((codArea: f.codArea, codClasificacion: f.codClasificacion, modalidad: v)),
        ),
      ],
    );
  }
}
