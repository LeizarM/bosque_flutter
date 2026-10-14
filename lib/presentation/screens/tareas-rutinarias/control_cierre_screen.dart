// Destino final: lib/presentation/screens/tareas-rutinarias/control_cierre_screen.dart
import 'package:bosque_flutter/core/constants/tareas_breakpoints.dart';
import 'package:bosque_flutter/core/state/control_cierre_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/theme/tareas_tema.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/domain/entities/firma_cierre_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/paneles_cierre.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tabla_modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// El tablero de Verificar Cierre: quién firmó su parte, a tiempo o tarde, y
/// qué quedó sin firmar (archivo SQL 81). Cada uno ve solo sus celdas; el
/// tablero completo, solo quien tiene todas asignadas.
class ControlCierreScreen extends ConsumerWidget {
  const ControlCierreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(controlCierreProvider);
    final n = ref.read(controlCierreProvider.notifier);

    return TareasScope(
      child: Scaffold(
        appBar: AppBarTareas(
          titulo: 'Control del cierre',
          subtitulo: 'Verificar Cierre de Operaciones · últimos ${s.dias} días',
          insignia: InsigniaTarea.deTipo(
            context,
            5,
            icono: Icons.insights_outlined,
          ),
          acciones: [
            IconButton(
              tooltip: 'Volver a leer',
              icon: const Icon(Icons.refresh),
              onPressed: n.cargar,
            ),
          ],
        ),
        body: SafeArea(
          child: MargenPaginaTareas(
            child: RefreshIndicator(
              onRefresh: n.cargar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Wrap(
                    spacing: Esp.m,
                    runSpacing: Esp.s,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 7, label: Text('7 días')),
                          ButtonSegment(value: 30, label: Text('30 días')),
                          ButtonSegment(value: 90, label: Text('90 días')),
                        ],
                        selected: {s.dias},
                        onSelectionChanged: (v) => n.cambiarDias(v.first),
                      ),
                      if (s.celdas.cargado)
                        for (final e in EstadoCelda.values)
                          _Pastilla(
                            estado: e,
                            texto: '${e.etiqueta}: ${s.cuantas(e)}',
                          ),
                    ],
                  ),
                  const SizedBox(height: Esp.l),
                  PanelCierreCard(
                    titulo: 'Por persona',
                    detalle:
                        'Cuántas secciones le tocaban y qué pasó con cada una. '
                        'Una compartida la cuenta quien la firmó; a los demás, '
                        'como hecha por otro.',
                    icono: Icons.groups_outlined,
                    color: TareasColors.tipoTareaTexto(context, 5),
                    datos: s.resumen,
                    vacio:
                        'No tienes secciones de Verificar Cierre en esos días.',
                    tituloError: 'No se pudo leer el resumen',
                    onReintentar: n.cargar,
                    contenido:
                        (_) => _ResumenPorPersona(filas: s.resumen.filas),
                  ),
                  const SizedBox(height: Esp.l),
                  PanelCierreCard(
                    titulo: 'Día por día',
                    detalle:
                        'Cada sección de cada día. Tócala para ver el detalle.',
                    icono: Icons.calendar_view_week_outlined,
                    color: TareasColors.tipoTareaTexto(context, 2),
                    datos: s.celdas,
                    vacio:
                        'No tienes secciones de Verificar Cierre en esos días.',
                    tituloError: 'No se pudo leer el tablero',
                    onReintentar: n.cargar,
                    contenido: (_) => _DiaPorDia(dias: s.porDia),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

({Color fondo, Color texto}) _tono(BuildContext context, EstadoCelda e) =>
    switch (e) {
      EstadoCelda.aTiempo => (
        fondo: TareasColors.realizado(context),
        texto: TareasColors.realizadoTexto(context),
      ),
      EstadoCelda.tarde => (
        fondo: TareasColors.pendiente(context),
        texto: TareasColors.pendienteTexto(context),
      ),
      EstadoCelda.sinFirmar => (
        fondo: TareasColors.vencido(context),
        texto: TareasColors.vencidoTexto(context),
      ),
      EstadoCelda.pendiente => (
        fondo: TareasColors.noAplica(context),
        texto: TareasColors.noAplicaTexto(context),
      ),
    };

class _Pastilla extends StatelessWidget {
  final EstadoCelda estado;
  final String texto;

  const _Pastilla({required this.estado, required this.texto});

  @override
  Widget build(BuildContext context) {
    final t = _tono(context, estado);
    return PildoraTareas(texto: texto, fondo: t.fondo, color: t.texto);
  }
}

const _anchosResumen = <AnchoCol>[
  AnchoCol.flexible(3), // persona
  AnchoCol.fijo(86), // le tocaban
  AnchoCol.fijo(86), // a tiempo
  AnchoCol.fijo(70), // tarde
  AnchoCol.fijo(86), // la hizo otro
  AnchoCol.fijo(86), // no hechas
  AnchoCol.fijo(96), // revisó lo propio
  AnchoCol.fijo(86), // problemas
];

class _ResumenPorPersona extends StatelessWidget {
  final List<ResumenCierrePersona> filas;

  const _ResumenPorPersona({required this.filas});

  @override
  Widget build(BuildContext context) => AnchoDelCajon(
    builder: (context, cajon) {
      if (cajon.maxWidth < TareasBreakpoints.mediumMax) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final r in filas) _TarjetaPersona(r: r)],
        );
      }
      Widget n(int v, {EstadoCelda? alerta}) {
        final t = alerta != null && v > 0 ? _tono(context, alerta) : null;
        return Text(
          '$v',
          textAlign: TextAlign.right,
          style: context.numero(fuerte: t != null, color: t?.texto),
        );
      }

      return TablaCierre(
        anchos: _anchosResumen,
        aLaDerecha: const {1, 2, 3, 4, 5, 6, 7},
        titulos: const [
          'Persona',
          'Le tocaban',
          'A tiempo',
          'Tarde',
          'La hizo otro',
          'No hechas',
          'Revisó lo propio',
          'Problemas',
        ],
        filas: [
          for (final r in filas)
            FilaTabla(
              anchos: _anchosResumen,
              celdas: [
                Text(r.persona, overflow: TextOverflow.ellipsis),
                n(r.leTocaban),
                n(r.hechasATiempo),
                n(r.hechasTarde, alerta: EstadoCelda.tarde),
                n(r.porOtro),
                n(r.noHechas, alerta: EstadoCelda.sinFirmar),
                n(r.autorrevisadas),
                n(r.hallazgos),
              ],
            ),
        ],
      );
    },
  );
}

class _TarjetaPersona extends StatelessWidget {
  final ResumenCierrePersona r;

  const _TarjetaPersona({required this.r});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Esp.s),
    child: Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: context.cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.persona, style: Theme.of(context).textTheme.titleSmall),
            Text('Le tocaban ${r.leTocaban}', style: context.apagado()),
            const SizedBox(height: Esp.s),
            Wrap(
              spacing: Esp.s,
              runSpacing: Esp.xs,
              children: [
                _Pastilla(
                  estado: EstadoCelda.aTiempo,
                  texto: 'A tiempo: ${r.hechasATiempo}',
                ),
                if (r.hechasTarde > 0)
                  _Pastilla(
                    estado: EstadoCelda.tarde,
                    texto: 'Tarde: ${r.hechasTarde}',
                  ),
                if (r.noHechas > 0)
                  _Pastilla(
                    estado: EstadoCelda.sinFirmar,
                    texto: 'No hechas: ${r.noHechas}',
                  ),
                if (r.porOtro > 0)
                  _Pastilla(
                    estado: EstadoCelda.pendiente,
                    texto: 'La hizo otro: ${r.porOtro}',
                  ),
              ],
            ),
            if (r.autorrevisadas > 0 || r.hallazgos > 0) ...[
              const SizedBox(height: Esp.xs),
              Text(
                'Revisó lo propio: ${r.autorrevisadas} · Problemas: ${r.hallazgos}',
                style: context.apagado(),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _DiaPorDia extends StatelessWidget {
  final List<DiaDelTablero> dias;

  const _DiaPorDia({required this.dias});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final d in dias) ...[
        Text(
          '${_conDiaSemana(d.fechaTarea)} · revisa ${FormatearFecha.formatearFecha(d.celdas.first.fechaRevisada)}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: Esp.s),
        Wrap(
          spacing: Esp.s,
          runSpacing: Esp.s,
          children: [for (final c in d.celdas) _Celda(c: c)],
        ),
        if (d != dias.last) const Divider(height: Esp.xl),
      ],
    ],
  );
}

class _Celda extends StatelessWidget {
  final CeldaTablero c;

  const _Celda({required this.c});

  @override
  Widget build(BuildContext context) {
    final t = _tono(context, c.estado);
    return Material(
      color: t.fondo,
      borderRadius: BorderRadius.circular(Esquina.media),
      child: InkWell(
        borderRadius: BorderRadius.circular(Esquina.media),
        onTap: () => _detalle(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Esp.m,
            vertical: Esp.s,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${c.nombreSeccion} · ${c.nombreSucursal}',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: t.texto),
              ),
              Text(
                c.firmadoPor == null
                    ? c.estado.etiqueta
                    : '${c.estado.etiqueta} · ${c.firmadoPor}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: t.texto),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _detalle(BuildContext context) {
    final lineas = <(String, String)>[
      ('Estado', c.estado.etiqueta),
      ('Revisa el', FormatearFecha.formatearFecha(c.fechaRevisada)),
      if (c.firmadoPor != null) ('Firmó', c.firmadoPor!),
      if (c.fechaFirma != null)
        ('Cuándo', FormatearFecha.formatearFechaHora(c.fechaFirma!)),
      if (c.filas != null)
        ('Filas revisadas', '${c.filasRevisadas ?? 0} de ${c.filas}'),
      if ((c.autorrevisadas ?? 0) > 0)
        ('Revisó lo propio', '${c.autorrevisadas}'),
      if (c.hallazgos != null) ('Problemas', '${c.hallazgos}'),
      if (c.obs != null) ('Observación', c.obs!),
      if (c.responsables != null) ('Responsables', c.responsables!),
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder:
          (ctx) => SafeArea(
            // Con scroll: con muchas líneas o letra grande la hoja desbordaba.
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(Esp.l, 0, Esp.l, Esp.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${c.nombreSeccion} · ${c.nombreSucursal}',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  const SizedBox(height: Esp.m),
                  for (final (titulo, valor) in lineas)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Esp.s),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 130,
                            child: Text(titulo, style: ctx.apagado()),
                          ),
                          Expanded(child: Text(valor)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
    );
  }
}

const _diasDeLaSemana = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

String _conDiaSemana(DateTime d) =>
    '${_diasDeLaSemana[d.weekday - 1]} ${FormatearFecha.formatearFecha(d)}';
