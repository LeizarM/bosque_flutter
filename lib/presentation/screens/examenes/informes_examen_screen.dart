/// Informes (`tcpeExamenes/Informes`): resumen por categoría y fechas, e
/// historial de una persona por su CI.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_examen.dart';
import 'package:bosque_flutter/domain/entities/tcpe_historial_examen_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_informe_categoria_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/tabla_examenes.dart';

typedef _FiltroInforme = ({BigInt? codClasificacion, DateTime? desde, DateTime? hasta});

final _informeProvider = FutureProvider.autoDispose.family<List<TcpeInformeCategoriaEntity>, _FiltroInforme>(
  (ref, f) => ref
      .watch(examenesRepositoryProvider)
      .informe(codClasificacion: f.codClasificacion, fechaDesde: f.desde, fechaHasta: f.hasta),
);
final _historialProvider = FutureProvider.autoDispose.family<List<TcpeHistorialExamenEntity>, String>(
  (ref, ci) => ref.watch(examenesRepositoryProvider).historial(ci),
);

/// El filtro aplicado (null = todavía no se consultó).
final _aplicadoProvider = StateProvider.autoDispose<_FiltroInforme?>((ref) => null);
final _ciProvider = StateProvider.autoDispose<String?>((ref) => null);

class InformesExamenScreen extends StatelessWidget {
  const InformesExamenScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: LayoutBuilder(
      builder: (context, r) {
        final compacto = r.maxWidth < anchoTablaExamenes;
        final margen = compacto ? Esp.l : Esp.xl;
        return Scaffold(
          body: Padding(
            padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, compacto ? 0 : Esp.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EncabezadoExamenes(
                  ceja: 'Exámenes · Informes',
                  titulo: 'Informes de exámenes',
                  icono: Icons.insights_outlined,
                  detalle: 'Cómo les fue a los lotes de una categoría en un periodo, o todo lo que rindió una persona.',
                  compacto: compacto,
                ),
                const SizedBox(height: Esp.m),
                const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [Tab(text: 'Por categoría y fechas'), Tab(text: 'Historial por CI')],
                ),
                const SizedBox(height: Esp.m),
                Expanded(
                  child: TabBarView(
                    children: [_PorCategoria(compacto: compacto), _Historial(compacto: compacto)],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _PorCategoria extends ConsumerStatefulWidget {
  const _PorCategoria({required this.compacto});

  final bool compacto;

  @override
  ConsumerState<_PorCategoria> createState() => _PorCategoriaState();
}

class _PorCategoriaState extends ConsumerState<_PorCategoria> {
  BigInt? _codClasificacion;
  DateTime? _desde = DateTime(DateTime.now().year, 1, 1);
  DateTime? _hasta = DateTime.now();

  Future<void> _fecha(bool desde) async {
    final f = await showDatePicker(
      context: context,
      initialDate: (desde ? _desde : _hasta) ?? DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (f != null) setState(() => desde ? _desde = f : _hasta = f);
  }

  @override
  Widget build(BuildContext context) {
    final categorias = ref.watch(tcpeCategoriasProvider).valueOrNull ?? const [];
    final aplicado = ref.watch(_aplicadoProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FiltrosExamenes(
          compacto: widget.compacto,
          activos: _codClasificacion == null ? 0 : 1,
          campos: [
            ComboFiltro<BigInt>(
              etiqueta: 'Categoría',
              valor: _codClasificacion,
              textoTodos: 'Todas',
              ancho: 280,
              opciones: [for (final c in categorias) (c.codClasificacion, c.nombre ?? '')],
              onCambio: (v) => setState(() => _codClasificacion = v),
            ),
            _BotonFecha(etiqueta: 'Desde', fecha: _desde, onTap: () => _fecha(true)),
            _BotonFecha(etiqueta: 'Hasta', fecha: _hasta, onTap: () => _fecha(false)),
            FilledButton.icon(
              onPressed: () {
                if (_desde != null && _hasta != null && _desde!.isAfter(_hasta!)) {
                  final t = _desde;
                  setState(() {
                    _desde = _hasta;
                    _hasta = t;
                  });
                }
                ref.read(_aplicadoProvider.notifier).state = (
                  codClasificacion: _codClasificacion,
                  desde: _desde,
                  hasta: _hasta,
                );
              },
              icon: const Icon(Icons.query_stats, size: 18),
              label: const Text('Consultar'),
            ),
          ],
        ),
        const SizedBox(height: Esp.m),
        Expanded(
          child:
              aplicado == null
                  ? const VacioExamenes(
                    icono: Icons.insights_outlined,
                    titulo: 'Elige el periodo y consulta',
                    detalle: 'Verás cada lote con sus rendidos, calificados, promedio y aprobados.',
                  )
                  : ref
                      .watch(_informeProvider(aplicado))
                      .when(
                        loading: () => const EsqueletoLista(),
                        error: (e, _) => MensajeError(error: e, onReintentar: () => ref.invalidate(_informeProvider)),
                        data: (filas) => _tablaInforme(context, filas),
                      ),
        ),
      ],
    );
  }

  Widget _tablaInforme(BuildContext context, List<TcpeInformeCategoriaEntity> filas) {
    int suma(int Function(TcpeInformeCategoriaEntity) f) => filas.fold(0, (s, e) => s + f(e));
    final calificados = suma((e) => e.calificados);
    final aprobados = suma((e) => e.aprobados);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (filas.isNotEmpty) ...[
          Wrap(
            spacing: Esp.m,
            runSpacing: Esp.s,
            children: [
              CifraExamen(
                valor: '${filas.length}',
                rotulo: 'lotes',
                icono: Icons.inventory_2_outlined,
                tono: TonoExamen.secundario,
              ),
              CifraExamen(
                valor: '${suma((e) => e.rendidos)}',
                rotulo: 'rendidos',
                icono: Icons.assignment_turned_in_outlined,
                tono: TonoExamen.secundario,
              ),
              CifraExamen(
                valor: '$calificados',
                rotulo: 'calificados',
                icono: Icons.verified_outlined,
                tono: TonoExamen.terciario,
              ),
              CifraExamen(
                valor: calificados == 0 ? '--' : '${(aprobados * 100 / calificados).round()} %',
                rotulo: 'aprobados',
                icono: Icons.how_to_reg_outlined,
                tono: TonoExamen.principal,
              ),
            ],
          ),
          const SizedBox(height: Esp.m),
        ],
        Expanded(
          child: TablaExamenes<TcpeInformeCategoriaEntity>(
            filas: filas,
            claveFila: (e) => e.codRolExamen,
            tonoFila: (e) => e.modalidad == 'E' ? TonoExamen.terciario : TonoExamen.principal,
            vacio: const VacioExamenes(
              icono: Icons.search_off,
              titulo: 'Sin lotes en ese periodo',
              detalle: 'Prueba con otras fechas u otra categoría.',
            ),
            columnas: [
              ColumnaExamen(
                'Lote',
                (e) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [CeldaTexto(e.titulo, fuerte: true), CeldaTexto('${e.nombreArea ?? ''} · ${e.nombreClasificacion ?? ''}', apagado: true)],
                ),
                flex: 6,
              ),
              ColumnaExamen('Fecha', (e) => CeldaTexto(fechaCorta(e.fecha), apagado: true), flex: 2),
              ColumnaExamen('Modalidad', (e) => PastillaModalidad(e.modalidad), flex: 2),
              ColumnaExamen('Exám.', (e) => CeldaNumero('${e.examenes}'), flex: 1, alinear: Alignment.centerRight),
              ColumnaExamen('Rend.', (e) => CeldaNumero('${e.rendidos}'), flex: 1, alinear: Alignment.centerRight),
              ColumnaExamen('Calif.', (e) => CeldaNumero('${e.calificados}'), flex: 1, alinear: Alignment.centerRight),
              ColumnaExamen(
                'Aprob.',
                (e) => CeldaNumero('${e.aprobados}', fuerte: true, color: Theme.of(context).colorScheme.primary),
                flex: 1,
                alinear: Alignment.centerRight,
              ),
              ColumnaExamen(
                'Reprob.',
                (e) => CeldaNumero(
                  '${e.reprobados}',
                  fuerte: e.reprobados > 0,
                  color: e.reprobados > 0 ? Theme.of(context).colorScheme.error : null,
                ),
                flex: 1,
                alinear: Alignment.centerRight,
              ),
              // Los ausentes ya cuentan como reprobados (SQL): se muestran aparte para no confundirlos.
              ColumnaExamen('Aus.', (e) => CeldaNumero('${e.ausentes}'), flex: 1, alinear: Alignment.centerRight),
              ColumnaExamen('Mín.', (e) => CeldaNumero(nota(e.notaAprobacion)), flex: 1, alinear: Alignment.centerRight),
              ColumnaExamen(
                'Prom.',
                (e) => CeldaNota(e.promedio, minima: e.notaAprobacion),
                flex: 1,
                alinear: Alignment.centerRight,
              ),
            ],
            tarjeta:
                (e) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(e.titulo ?? '--', style: Theme.of(context).textTheme.titleSmall)),
                        CeldaNota(e.promedio, minima: e.notaAprobacion),
                      ],
                    ),
                    Text('${e.nombreClasificacion ?? ''} · ${fechaCorta(e.fecha)}', style: context.apagado()),
                    const SizedBox(height: Esp.xs),
                    Text(
                      [
                        '${e.rendidos}/${e.examenes} rendidos',
                        '${e.aprobados} aprobados',
                        '${e.reprobados} reprobados',
                        if (e.ausentes > 0) '${e.ausentes} ausentes',
                        if (e.notaAprobacion != null) 'mínima ${nota(e.notaAprobacion)}',
                      ].join(' · '),
                      style: context.apagado(),
                    ),
                  ],
                ),
          ),
        ),
      ],
    );
  }
}

class _BotonFecha extends StatelessWidget {
  const _BotonFecha({required this.etiqueta, required this.fecha, required this.onTap});

  final String etiqueta;
  final DateTime? fecha;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: const Icon(Icons.event_outlined, size: 18),
    label: Text('$etiqueta: ${fecha == null ? '--' : fechaCorta(fecha)}'),
  );
}

class _Historial extends ConsumerStatefulWidget {
  const _Historial({required this.compacto});

  final bool compacto;

  @override
  ConsumerState<_Historial> createState() => _HistorialState();
}

class _HistorialState extends ConsumerState<_Historial> {
  final _ci = TextEditingController();

  @override
  void dispose() {
    _ci.dispose();
    super.dispose();
  }

  void _buscar() {
    final ci = _ci.text.trim();
    if (ci.isNotEmpty) ref.read(_ciProvider.notifier).state = ci;
  }

  @override
  Widget build(BuildContext context) {
    final ci = ref.watch(_ciProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Esp.m,
          runSpacing: Esp.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: widget.compacto ? double.infinity : 260,
              child: TextField(
                controller: _ci,
                inputFormatters: [LengthLimitingTextInputFormatter(20)],
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'CI',
                  prefixIcon: Icon(Icons.badge_outlined, size: 20),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _buscar(),
              ),
            ),
            FilledButton.icon(onPressed: _buscar, icon: const Icon(Icons.search, size: 18), label: const Text('Buscar')),
          ],
        ),
        const SizedBox(height: Esp.m),
        Expanded(
          child:
              ci == null
                  ? const VacioExamenes(
                    icono: Icons.person_search_outlined,
                    titulo: 'Busca a una persona por su CI',
                    detalle: 'Aparecen todos los exámenes que rindió, como empleado o como postulante.',
                  )
                  : ref
                      .watch(_historialProvider(ci))
                      .when(
                        loading: () => const EsqueletoLista(),
                        error: (e, _) => MensajeError(error: e, onReintentar: () => ref.invalidate(_historialProvider)),
                        data: (filas) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (filas.isNotEmpty) ...[
                              Text(
                                '${filas.first.nombreCompleto ?? 'Sin nombre'} · CI ${filas.first.ci ?? ci}',
                                style: context.tituloSeccion(),
                              ),
                              const SizedBox(height: Esp.s),
                            ],
                            Expanded(child: _tablaHistorial(context, filas, ci)),
                          ],
                        ),
                      ),
        ),
      ],
    );
  }

  Widget _tablaHistorial(BuildContext context, List<TcpeHistorialExamenEntity> filas, String ci) =>
      TablaExamenes<TcpeHistorialExamenEntity>(
        filas: filas,
        claveFila: (e) => e.codExamen,
        tonoFila: (e) => aspectoDeEstado(EstadoExamenTcpe.desde(e.estado)).$1,
        vacio: VacioExamenes(
          icono: Icons.search_off,
          titulo: 'No hay exámenes con el CI $ci',
          detalle: 'Revisa el número o prueba sin el complemento.',
        ),
        columnas: [
          ColumnaExamen('Fecha', (e) => CeldaTexto(fechaHora(e.fechaInicio), apagado: true), flex: 3),
          ColumnaExamen('Lote', (e) => CeldaTexto(e.tituloLote, fuerte: true), flex: 5),
          ColumnaExamen('Categoría', (e) => CeldaTexto(e.nombreClasificacion), flex: 4),
          ColumnaExamen('Usuario', (e) => Text(e.login ?? '--', style: const TextStyle(fontFamily: fuenteFija)), flex: 2),
          ColumnaExamen('Estado', (e) => EtiquetaEstadoExamen(EstadoExamenTcpe.desde(e.estado)), flex: 2),
          ColumnaExamen('Nota', (e) => _notaHistorial(context, e), flex: 1, alinear: Alignment.centerRight),
          ColumnaExamen('Resultado', (e) => EtiquetaAprobacion(e.aprobado, enCelda: true), flex: 2),
        ],
        tarjeta:
            (e) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(e.tituloLote ?? '--', style: Theme.of(context).textTheme.titleSmall)),
                    _notaHistorial(context, e),
                  ],
                ),
                Text('${e.nombreClasificacion ?? ''} · ${fechaHora(e.fechaInicio)}', style: context.apagado()),
                const SizedBox(height: Esp.xs),
                Wrap(
                  spacing: Esp.s,
                  runSpacing: Esp.xs,
                  children: [
                    EtiquetaEstadoExamen(EstadoExamenTcpe.desde(e.estado)),
                    if (e.aprobado != null) EtiquetaAprobacion(e.aprobado),
                  ],
                ),
              ],
            ),
      );

  /// La nota en el color de su resultado: principal si aprobó, alerta si no.
  Widget _notaHistorial(BuildContext context, TcpeHistorialExamenEntity e) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (e.aprobado) {
      true => cs.primary,
      false => cs.error,
      null => null,
    };
    return CeldaNumero(nota(e.resultado), fuerte: true, color: color);
  }
}
