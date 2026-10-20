/// Resultados (`tcpeExamenes/Resultados`): los exámenes de un lote con su
/// estado, la revisión de las respuestas escritas, el cierre de la
/// calificación y la nota manual de los escritos.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_examen.dart';
import 'package:bosque_flutter/domain/entities/tcpe_lote_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_resultado_examen_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/revision_examen.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/tabla_examenes.dart';

final _loteProvider = StateProvider.autoDispose<BigInt?>((ref) => null);
final _estadoProvider = StateProvider.autoDispose<EstadoExamenTcpe?>((ref) => null);
final _buscarProvider = StateProvider.autoDispose<String>((ref) => '');

const FiltroLotes _todosLosLotes = (codArea: null, codClasificacion: null, modalidad: null);

class ResultadosExamenScreen extends ConsumerStatefulWidget {
  const ResultadosExamenScreen({super.key, this.loteInicial});

  /// El lote con el que se abre (viene del detalle del lote).
  final BigInt? loteInicial;

  @override
  ConsumerState<ResultadosExamenScreen> createState() => _ResultadosExamenScreenState();
}

class _ResultadosExamenScreenState extends ConsumerState<ResultadosExamenScreen> {
  @override
  void initState() {
    super.initState();
    final inicial = widget.loteInicial;
    if (inicial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(_loteProvider.notifier).state = inicial;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lotes = ref.watch(tcpeLotesProvider(_todosLosLotes));
    final codLote = ref.watch(_loteProvider);
    final lote = lotes.valueOrNull?.where((l) => l.codRolExamen == codLote).firstOrNull;

    return LayoutBuilder(
      builder: (context, r) {
        final compacto = r.maxWidth < anchoTablaExamenes;
        final margen = compacto ? Esp.l : Esp.xl;
        final selector = ComboFiltro<BigInt>(
          etiqueta: 'Lote',
          valor: codLote,
          textoTodos: 'Elige un lote',
          ancho: compacto ? double.infinity : 420,
          opciones: [
            for (final l in lotes.valueOrNull ?? const <TcpeLoteEntity>[])
              (l.codRolExamen, '${l.titulo ?? ''} · ${fechaCorta(l.fecha)}${l.porRevisar > 0 ? ' · ${l.porRevisar} por revisar' : ''}'),
          ],
          onCambio: (v) {
            ref.read(_loteProvider.notifier).state = v;
            ref.read(_estadoProvider.notifier).state = null;
          },
        );
        return Scaffold(
          body: Padding(
            padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, compacto ? 0 : Esp.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EncabezadoExamenes(
                  ceja: 'Exámenes · Resultados',
                  titulo: 'Resultados',
                  icono: Icons.grading_outlined,
                  detalle:
                      'Al abrir un lote, los exámenes cuyo tiempo venció se entregan solos. Las respuestas '
                      'escritas se marcan en «Revisar» y luego se cierra la calificación.',
                  compacto: compacto,
                  acciones: [
                    if (codLote != null)
                      IconButton(
                        tooltip: 'Actualizar',
                        onPressed: () {
                          ref.invalidate(tcpeResultadosProvider(codLote));
                          ref.invalidate(tcpeLotesProvider);
                        },
                        color: Theme.of(context).colorScheme.primary,
                        icon: const Icon(Icons.refresh),
                      ),
                  ],
                ),
                const SizedBox(height: Esp.l),
                if (lotes.hasError)
                  MensajeError(error: lotes.error, compacto: true, onReintentar: () => ref.invalidate(tcpeLotesProvider))
                else
                  selector,
                const SizedBox(height: Esp.m),
                Expanded(
                  child:
                      lote == null
                          ? (lotes.isLoading
                              ? const EsqueletoLista(filas: 4)
                              : const VacioExamenes(
                                icono: Icons.grading_outlined,
                                titulo: 'Elige un lote para calificar',
                                detalle:
                                    'Arriba aparecen todos los lotes; los que tienen respuestas escritas por marcar lo dicen '
                                    'junto al nombre.',
                              ))
                          : _Resultados(lote: lote, compacto: compacto),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Resultados extends ConsumerWidget {
  const _Resultados({required this.lote, required this.compacto});

  final TcpeLoteEntity lote;
  final bool compacto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(tcpeResultadosProvider(lote.codRolExamen));
    final estado = ref.watch(_estadoProvider);
    final buscar = ref.watch(_buscarProvider).toLowerCase();

    return datos.when(
      skipLoadingOnReload: true,
      loading: () => const EsqueletoLista(),
      error: (e, _) => MensajeError(error: e, onReintentar: () => ref.invalidate(tcpeResultadosProvider(lote.codRolExamen))),
      data: (todos) {
        final cuenta = <EstadoExamenTcpe, int>{};
        for (final e in todos) {
          final s = EstadoExamenTcpe.desde(e.estado);
          cuenta[s] = (cuenta[s] ?? 0) + 1;
        }
        final filas = [
          for (final e in todos)
            if ((estado == null || EstadoExamenTcpe.desde(e.estado) == estado) &&
                (buscar.isEmpty ||
                    '${e.login} ${e.nombreCompleto} ${e.ci}'.toLowerCase().contains(buscar)))
              e,
        ];
        final aprobados = todos.where((e) => e.aprobacion == true).length;
        final reprobados = todos.where((e) => e.aprobacion == false).length;
        final minima = todos.map((e) => e.notaAprobacion).whereType<double>().firstOrNull ?? lote.notaAprobacion;
        int n(EstadoExamenTcpe s) => cuenta[s] ?? 0;
        final tira = TiraEstados(
          tramos: [
            TramoTira(n(EstadoExamenTcpe.calificado), 'calificados', TonoTramo.hecho),
            TramoTira(n(EstadoExamenTcpe.porRevisar), 'por revisar', TonoTramo.revisar),
            TramoTira(n(EstadoExamenTcpe.enCurso), 'en curso', TonoTramo.enCurso),
            TramoTira(n(EstadoExamenTcpe.vencido), 'vencidos', TonoTramo.alerta),
            TramoTira(n(EstadoExamenTcpe.ausente), 'ausentes', TonoTramo.perdido),
            TramoTira(n(EstadoExamenTcpe.sinIniciar), 'sin iniciar', TonoTramo.pendiente),
          ],
        );
        final cifras = Wrap(
          spacing: Esp.m,
          runSpacing: Esp.s,
          children: [
            CifraExamen(
              valor: '$aprobados / $reprobados',
              rotulo: minima == null ? 'aprob. / reprob.' : 'aprob. / reprob. (mín. ${nota(minima)})',
              icono: Icons.how_to_reg_outlined,
              tono: TonoExamen.principal,
            ),
            CifraExamen(
              valor: nota(lote.promedio),
              rotulo: 'promedio',
              icono: Icons.insights_outlined,
              tono:
                  lote.promedio == null || minima == null
                      ? TonoExamen.neutro
                      : (lote.promedio! >= minima ? TonoExamen.principal : TonoExamen.alerta),
            ),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compacto) ...[tira, const SizedBox(height: Esp.m), cifras]
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [Expanded(child: tira), const SizedBox(width: Esp.xl), cifras],
              ),
            const SizedBox(height: Esp.m),
            Wrap(
              spacing: Esp.s,
              runSpacing: Esp.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChoiceChip(
                  label: Text('Todos (${todos.length})'),
                  selected: estado == null,
                  onSelected: (_) => ref.read(_estadoProvider.notifier).state = null,
                ),
                // Cada estado con su icono y su color: el chip elegido se pinta del tono del estado.
                for (final s in EstadoExamenTcpe.values)
                  if ((cuenta[s] ?? 0) > 0)
                    Builder(
                      builder: (context) {
                        final (tono, icono) = aspectoDeEstado(s);
                        final c = coloresDeTono(Theme.of(context).colorScheme, tono);
                        return ChoiceChip(
                          avatar: Icon(icono, size: 18, color: estado == s ? c.letra : c.acento),
                          showCheckmark: false,
                          selectedColor: c.fondo,
                          label: Text('${s.etiqueta} (${cuenta[s]})'),
                          selected: estado == s,
                          onSelected: (_) => ref.read(_estadoProvider.notifier).state = s,
                        );
                      },
                    ),
                SizedBox(
                  width: compacto ? double.infinity : 260,
                  child: TextField(
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.search, size: 20),
                      hintText: 'Buscar por nombre, usuario o CI',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (t) => ref.read(_buscarProvider.notifier).state = t.trim(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Esp.m),
            Expanded(
              child: TablaExamenes<TcpeResultadoExamenEntity>(
                filas: filas,
                claveFila: (e) => e.codExamen,
                tonoFila: (e) => aspectoDeEstado(EstadoExamenTcpe.desde(e.estado)).$1,
                alTocarFila: (e) => _revisar(context, ref, e),
                vacio:
                    todos.isEmpty
                        ? const VacioExamenes(
                          icono: Icons.inbox_outlined,
                          titulo: 'Este lote no tiene exámenes',
                          detalle: 'Agrégalos desde el detalle del lote, en «Lotes».',
                        )
                        : VacioExamenes(
                          icono: Icons.filter_alt_off_outlined,
                          titulo: 'Ningún examen con este filtro',
                          detalle: 'Cambia el estado o la búsqueda.',
                          accion: 'Ver todos',
                          iconoAccion: Icons.filter_alt_off_outlined,
                          onAccion: () => ref.read(_estadoProvider.notifier).state = null,
                        ),
                columnas: [
                  ColumnaExamen(
                    'Persona',
                    (e) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CeldaTexto((e.nombreCompleto ?? '').trim().isEmpty ? 'Sin datos' : e.nombreCompleto, fuerte: true),
                        Text(
                          '${e.login ?? 'Examen N° ${e.codExamen}'}${e.esEmpleado ? ' · empleado' : ''}',
                          style: context.apagado()?.copyWith(fontFamily: fuenteFija),
                        ),
                      ],
                    ),
                    flex: 5,
                  ),
                  ColumnaExamen('CI', (e) => CeldaTexto(e.ci), flex: 2),
                  ColumnaExamen('Estado', (e) => EtiquetaEstadoExamen(EstadoExamenTcpe.desde(e.estado)), flex: 2),
                  ColumnaExamen('Entregó', (e) => CeldaTexto(fechaHora(e.fechaFin), apagado: true), flex: 3),
                  ColumnaExamen('Resp.', (e) => CeldaNumero('${e.respondidas}/${e.totalPreguntas}'), flex: 2, alinear: Alignment.centerRight),
                  ColumnaExamen(
                    'Por marcar',
                    (e) =>
                        e.abiertasPendientes == 0
                            ? const CeldaNumero('--')
                            : PastillaExamen(
                              texto: '${e.abiertasPendientes}',
                              tono: TonoExamen.terciario,
                              icono: Icons.edit_note,
                            ),
                    flex: 2,
                    alinear: Alignment.centerRight,
                  ),
                  ColumnaExamen(
                    'Nota',
                    (e) => CeldaNota(e.resultado, minima: e.notaAprobacion ?? minima),
                    flex: 1,
                    alinear: Alignment.centerRight,
                  ),
                  ColumnaExamen('Resultado', (e) => EtiquetaAprobacion(e.aprobacion, enCelda: true), flex: 2),
                ],
                acciones: [
                  AccionExamen(
                    'Revisar',
                    Icons.rate_review_outlined,
                    (e) => _revisar(context, ref, e),
                    visible: (e) => lote.esOnline && EstadoExamenTcpe.desde(e.estado).cerrado,
                    tono: TonoExamen.terciario,
                  ),
                  AccionExamen(
                    'Cerrar calificación',
                    Icons.verified_outlined,
                    (e) => _cerrar(context, ref, e),
                    visible:
                        (e) =>
                            lote.esOnline &&
                            EstadoExamenTcpe.desde(e.estado) == EstadoExamenTcpe.porRevisar &&
                            e.abiertasPendientes == 0,
                  ),
                  AccionExamen(
                    'Nota manual',
                    Icons.edit_note_outlined,
                    (e) => _nota(context, ref, e),
                    visible: (_) => !lote.esOnline,
                    tono: TonoExamen.secundario,
                  ),
                ],
                tarjeta:
                    (e) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                (e.nombreCompleto ?? '').trim().isEmpty ? (e.login ?? 'Examen N° ${e.codExamen}') : e.nombreCompleto!,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            Text(nota(e.resultado), style: context.numero(fuerte: true)),
                          ],
                        ),
                        const SizedBox(height: Esp.xs),
                        Text(
                          '${e.login ?? ''} · CI ${e.ci ?? '--'} · ${e.respondidas}/${e.totalPreguntas} respondidas',
                          style: context.apagado(),
                        ),
                        const SizedBox(height: Esp.s),
                        Wrap(
                          spacing: Esp.s,
                          children: [
                            EtiquetaEstadoExamen(EstadoExamenTcpe.desde(e.estado)),
                            if (e.aprobacion != null) EtiquetaAprobacion(e.aprobacion),
                            if (e.abiertasPendientes > 0)
                              Etiqueta(texto: '${e.abiertasPendientes} por marcar', tono: TonoEtiqueta.aviso),
                          ],
                        ),
                      ],
                    ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _refrescar(WidgetRef ref) {
    ref.invalidate(tcpeResultadosProvider(lote.codRolExamen));
    ref.invalidate(tcpeLotesProvider);
  }

  Future<void> _revisar(BuildContext context, WidgetRef ref, TcpeResultadoExamenEntity e) async {
    if (!lote.esOnline) {
      await _nota(context, ref, e);
      return;
    }
    if (!EstadoExamenTcpe.desde(e.estado).cerrado) {
      avisar(context, 'Este examen todavía no se entregó.');
      return;
    }
    final cambio = await revisarExamen(context, e);
    if (cambio) _refrescar(ref);
  }

  Future<void> _cerrar(BuildContext context, WidgetRef ref, TcpeResultadoExamenEntity e) async {
    final ok = await confirmar(
      context,
      titulo: 'Cerrar calificación',
      detalle: 'Se calcula la nota con las respuestas correctas sobre el total de preguntas.',
      textoConfirmar: 'Cerrar',
    );
    if (!ok || !context.mounted) return;
    try {
      final msg = await ref.read(examenesRepositoryProvider).cerrarCalificacion(e.codExamen);
      _refrescar(ref);
      if (context.mounted) avisar(context, msg ?? 'Calificación cerrada.');
    } catch (err) {
      if (context.mounted) avisar(context, textoParaUsuario(err), esError: true);
    }
  }

  Future<void> _nota(BuildContext context, WidgetRef ref, TcpeResultadoExamenEntity e) async {
    final n = await pedirNotaManual(context, e);
    if (n == null || !context.mounted) return;
    try {
      final msg = await ref.read(examenesRepositoryProvider).notaManual(e.codExamen, n);
      _refrescar(ref);
      if (context.mounted) avisar(context, msg ?? 'Nota guardada.');
    } catch (err) {
      if (context.mounted) avisar(context, textoParaUsuario(err), esError: true);
    }
  }
}
