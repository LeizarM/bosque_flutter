/// Informes · «Preguntas más falladas» (v11, `p_list_tcpe_Resultado` P): por
/// categoría, las preguntas en que más se equivocaron y en qué se equivocaron.
/// Tabla en escritorio y tarjetas en el teléfono; el ancho es el del contenedor.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_ranking_pregunta_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/tabla_examenes.dart';

typedef FiltroRanking = ({BigInt? codClasificacion, DateTime? desde, DateTime? hasta});

final rankingPreguntasProvider = FutureProvider.autoDispose.family<List<TcpeRankingPreguntaEntity>, FiltroRanking>(
  (ref, f) => ref
      .watch(examenesRepositoryProvider)
      .rankingPreguntas(codClasificacion: f.codClasificacion, fechaDesde: f.desde, fechaHasta: f.hasta),
);

/// Debajo de este ancho de contenedor el ranking pasa a tarjetas: son siete datos por fila.
const double anchoTablaRanking = 900;

class RankingPreguntasExamen extends ConsumerStatefulWidget {
  const RankingPreguntasExamen({super.key, required this.compacto});

  final bool compacto;

  @override
  ConsumerState<RankingPreguntasExamen> createState() => _RankingPreguntasExamenState();
}

class _RankingPreguntasExamenState extends ConsumerState<RankingPreguntasExamen> {
  BigInt? _codClasificacion;
  DateTime? _desde;
  DateTime? _hasta;

  /// Se consulta al entrar, con todo el historial; los filtros se aplican con «Consultar».
  FiltroRanking _aplicado = (codClasificacion: null, desde: null, hasta: null);

  bool get _hayFiltro => _aplicado.codClasificacion != null || _aplicado.desde != null || _aplicado.hasta != null;

  Future<void> _fecha(bool desde) async {
    final f = await showDatePicker(
      context: context,
      initialDate: (desde ? _desde : _hasta) ?? DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (f != null) setState(() => desde ? _desde = f : _hasta = f);
  }

  void _consultar() {
    var desde = _desde;
    var hasta = _hasta;
    if (desde != null && hasta != null && desde.isAfter(hasta)) (desde, hasta) = (hasta, desde);
    setState(() {
      _desde = desde;
      _hasta = hasta;
      _aplicado = (codClasificacion: _codClasificacion, desde: desde, hasta: hasta);
    });
  }

  void _limpiar() => setState(() {
    _codClasificacion = null;
    _desde = null;
    _hasta = null;
    _aplicado = (codClasificacion: null, desde: null, hasta: null);
  });

  @override
  Widget build(BuildContext context) {
    final categorias = ref.watch(tcpeCategoriasProvider).valueOrNull ?? const [];
    final activos = (_codClasificacion != null ? 1 : 0) + (_desde != null || _hasta != null ? 1 : 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FiltrosExamenes(
          compacto: widget.compacto,
          activos: activos,
          onLimpiar: _limpiar,
          campos: [
            ComboFiltro<BigInt>(
              etiqueta: 'Categoría',
              valor: _codClasificacion,
              textoTodos: 'Todas',
              ancho: 280,
              opciones: [for (final c in categorias) (c.codClasificacion, c.nombre ?? '')],
              onCambio: (v) => setState(() => _codClasificacion = v),
            ),
            _BotonFecha(etiqueta: 'Desde', fecha: _desde, sinFecha: 'el primero', onTap: () => _fecha(true)),
            _BotonFecha(etiqueta: 'Hasta', fecha: _hasta, sinFecha: 'hoy', onTap: () => _fecha(false)),
            FilledButton.icon(
              onPressed: _consultar,
              icon: const Icon(Icons.query_stats, size: 18),
              label: const Text('Consultar'),
            ),
          ],
        ),
        const SizedBox(height: Esp.m),
        Expanded(
          child: ref
              .watch(rankingPreguntasProvider(_aplicado))
              .when(
                skipLoadingOnReload: true,
                loading: () => const EsqueletoLista(),
                error: (e, _) => MensajeError(error: e, onReintentar: () => ref.invalidate(rankingPreguntasProvider)),
                data:
                    (filas) =>
                        filas.isEmpty
                            ? (_hayFiltro
                                ? VacioExamenes(
                                  icono: Icons.filter_alt_off_outlined,
                                  titulo: 'Nadie falló con estos filtros',
                                  detalle: 'Prueba con otra categoría o con un periodo más amplio.',
                                  accion: 'Quitar filtros',
                                  iconoAccion: Icons.filter_alt_off_outlined,
                                  onAccion: _limpiar,
                                )
                                : const VacioExamenes(
                                  icono: Icons.emoji_events_outlined,
                                  titulo: 'Todavía no hay preguntas falladas',
                                  detalle:
                                      'Cuando se rindan y califiquen exámenes, aquí aparecen las preguntas en que '
                                      'más se equivocaron, ordenadas por categoría.',
                                ))
                            : ListaRankingPreguntas(filas: filas),
              ),
        ),
      ],
    );
  }
}

class _BotonFecha extends StatelessWidget {
  const _BotonFecha({required this.etiqueta, required this.fecha, required this.sinFecha, required this.onTap});

  final String etiqueta;
  final DateTime? fecha;
  final String sinFecha;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: const Icon(Icons.event_outlined, size: 18),
    label: Text('$etiqueta: ${fecha == null ? sinFecha : fechaCorta(fecha)}'),
  );
}

/// El ranking ya consultado: cifras arriba y una sección por categoría.
class ListaRankingPreguntas extends StatelessWidget {
  const ListaRankingPreguntas({super.key, required this.filas});

  final List<TcpeRankingPreguntaEntity> filas;

  @override
  Widget build(BuildContext context) {
    // El SP ya ordena por categoría y puesto: se agrupa sin reordenar.
    final grupos = <BigInt?, List<TcpeRankingPreguntaEntity>>{};
    for (final f in filas) {
      grupos.putIfAbsent(f.codClasificacion, () => []).add(f);
    }
    final fallos = filas.fold<int>(0, (s, f) => s + f.fallos);
    return LayoutBuilder(
      builder: (context, r) {
        final tabla = r.maxWidth >= anchoTablaRanking;
        return ListView(
          padding: const EdgeInsets.only(bottom: Esp.xl),
          children: [
            Wrap(
              spacing: Esp.m,
              runSpacing: Esp.s,
              children: [
                CifraExamen(
                  valor: '${filas.length}',
                  rotulo: filas.length == 1 ? 'pregunta con fallos' : 'preguntas con fallos',
                  icono: Icons.report_gmailerrorred_outlined,
                  tono: TonoExamen.alerta,
                ),
                CifraExamen(
                  valor: '$fallos',
                  rotulo: fallos == 1 ? 'respuesta fallada' : 'respuestas falladas',
                  icono: Icons.close_rounded,
                  tono: TonoExamen.terciario,
                ),
                CifraExamen(
                  valor: '${grupos.length}',
                  rotulo: grupos.length == 1 ? 'categoría' : 'categorías',
                  icono: Icons.category_outlined,
                  tono: TonoExamen.secundario,
                ),
              ],
            ),
            for (final g in grupos.values) ...[
              const SizedBox(height: Esp.xl),
              _EncabezadoCategoria(primera: g.first, cantidad: g.length),
              const SizedBox(height: Esp.s),
              if (tabla) ...[
                const _FilaRotulos(),
                for (final f in g) _FilaRanking(fila: f),
              ] else
                for (final f in g) _TarjetaRanking(fila: f),
            ],
          ],
        );
      },
    );
  }
}

class _EncabezadoCategoria extends StatelessWidget {
  const _EncabezadoCategoria({required this.primera, required this.cantidad});

  final TcpeRankingPreguntaEntity primera;
  final int cantidad;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Wrap(
      spacing: Esp.s,
      runSpacing: Esp.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(oGuion(primera.nombreClasificacion), style: context.tituloSeccion()),
        if ((primera.nombreArea ?? '').trim().isNotEmpty) Text('· ${primera.nombreArea}', style: context.apagado()),
        PastillaExamen(
          texto: cantidad == 1 ? '1 pregunta' : '$cantidad preguntas',
          tono: TonoExamen.neutro,
          icono: Icons.format_list_numbered,
        ),
      ],
    ),
  );
}

/// Burbuja del puesto: la primera en alerta, las dos siguientes en aviso.
Widget _burbujaPuesto(int puesto, {double tamanio = 34}) => BurbujaHoja(
  texto: '$puesto',
  tamanio: tamanio,
  marca:
      puesto == 1
          ? MarcaBurbuja.error
          : puesto <= 3
          ? MarcaBurbuja.aviso
          : MarcaBurbuja.vacia,
);

/// En qué se equivocaron, en palabras: el error más común o, si nadie eligió
/// una incorrecta, que marcaron solo parte de lo correcto.
String? _queFallo(TcpeRankingPreguntaEntity f) {
  if (!f.esCerrada) return 'Respuesta escrita: la califica el evaluador.';
  if ((f.errorComun ?? '').trim().isNotEmpty) {
    return '«${f.errorComun!.trim()}» · ${f.vecesErrorComun} ${f.vecesErrorComun == 1 ? 'vez' : 'veces'}';
  }
  if (f.incompletas > 0) return 'Marcaron solo parte de lo correcto.';
  return null;
}

class _FilaRotulos extends StatelessWidget {
  const _FilaRotulos();

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: Peso.titulo);
    Widget r(String t, int flex, {bool derecha = false}) =>
        Expanded(flex: flex, child: Text(t, style: estilo, textAlign: derecha ? TextAlign.end : TextAlign.start));
    return Padding(
      padding: const EdgeInsets.fromLTRB(Esp.m, Esp.xs, Esp.m, Esp.xs),
      child: Row(
        children: [
          SizedBox(width: 34 + Esp.m, child: Text('#', style: estilo)),
          r('Pregunta', 7),
          const SizedBox(width: Esp.m),
          r('Fallo', 3),
          const SizedBox(width: Esp.m),
          r('Fallaron', 2, derecha: true),
          r('Sin resp.', 2, derecha: true),
          r('Incompl.', 2, derecha: true),
          const SizedBox(width: Esp.l),
          r('Error más común', 5),
        ],
      ),
    );
  }
}

class _FilaRanking extends StatelessWidget {
  const _FilaRanking({required this.fila});

  final TcpeRankingPreguntaEntity fila;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = fila;
    return Container(
      margin: const EdgeInsets.only(bottom: Esp.xs),
      padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s + 2),
      decoration: BoxDecoration(
        color: f.puesto == 1 ? Color.alphaBlend(cs.errorContainer.withValues(alpha: 0.28), cs.surface) : null,
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6))),
      ),
      child: Row(
        children: [
          _burbujaPuesto(f.puesto),
          const SizedBox(width: Esp.m),
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  oGuion(f.pregunta),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
                ),
                if (!f.esCerrada) ...[
                  const SizedBox(height: Esp.xs),
                  const PastillaExamen(texto: 'Abierta', tono: TonoExamen.terciario, icono: Icons.edit_note),
                ],
              ],
            ),
          ),
          const SizedBox(width: Esp.m),
          Expanded(flex: 3, child: BarraFallo(porcentaje: f.porcentajeFallo)),
          const SizedBox(width: Esp.m),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: CeldaNumero('${f.fallos} de ${f.veces}', fuerte: true, color: cs.error),
            ),
          ),
          Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: CeldaNumero('${f.sinResponder}'))),
          Expanded(
            flex: 2,
            child: Align(alignment: Alignment.centerRight, child: CeldaNumero(f.esCerrada ? '${f.incompletas}' : '--')),
          ),
          const SizedBox(width: Esp.l),
          Expanded(
            flex: 5,
            child: Text(_queFallo(f) ?? '--', maxLines: 2, overflow: TextOverflow.ellipsis, style: context.apagado()),
          ),
        ],
      ),
    );
  }
}

class _TarjetaRanking extends StatelessWidget {
  const _TarjetaRanking({required this.fila});

  final TcpeRankingPreguntaEntity fila;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = fila;
    final que = _queFallo(f);
    return Card(
      margin: const EdgeInsets.only(bottom: Esp.s),
      elevation: 0,
      shape: contornoSuperficie(cs, color: f.puesto == 1 ? cs.error.withValues(alpha: 0.5) : null),
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _burbujaPuesto(f.puesto, tamanio: 30),
                const SizedBox(width: Esp.m),
                Expanded(child: Text(oGuion(f.pregunta), style: Theme.of(context).textTheme.titleSmall)),
              ],
            ),
            const SizedBox(height: Esp.s),
            BarraFallo(porcentaje: f.porcentajeFallo),
            const SizedBox(height: Esp.xs),
            Text(
              [
                '${f.fallos} de ${f.veces} fallaron',
                if (f.sinResponder > 0) '${f.sinResponder} sin responder',
                if (f.esCerrada && f.incompletas > 0) '${f.incompletas} incompletas',
                if (!f.esCerrada) 'abierta',
              ].join(' · '),
              style: context.apagado(),
            ),
            if (que != null) ...[
              const SizedBox(height: Esp.xs),
              Text('Error más común: $que', style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

/// El porcentaje de fallo como barra en el color de alerta, con su número al
/// lado: el color nunca va solo.
class BarraFallo extends StatelessWidget {
  const BarraFallo({super.key, required this.porcentaje});

  final double porcentaje;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = (porcentaje / 100).clamp(0.0, 1.0);
    return Semantics(
      label: '${porcentajeTexto(porcentaje)} de fallo',
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Esquina.pastilla),
              child: SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: cs.surfaceContainerHighest)),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: p,
                      heightFactor: 1,
                      child: ColoredBox(color: cs.error),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: Esp.s),
          SizedBox(
            width: 56,
            child: Text(
              porcentajeTexto(porcentaje),
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: Peso.dato, fontFeatures: cifrasTabulares, color: cs.error),
            ),
          ),
        ],
      ),
    );
  }
}
