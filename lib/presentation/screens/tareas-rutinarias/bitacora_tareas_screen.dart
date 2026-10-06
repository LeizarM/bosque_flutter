// Destino final: lib/presentation/screens/tareas-rutinarias/bitacora_tareas_screen.dart
import 'package:bosque_flutter/core/constants/tareas_breakpoints.dart';
import 'package:bosque_flutter/core/state/bitacora_tareas_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/theme/tareas_tema.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/cerrar_ruta.dart';
import 'package:bosque_flutter/core/ui/rango_fechas.dart';
import 'package:bosque_flutter/core/ui/visor_pdf.dart';
import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/domain/entities/bitacora_tareas_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/franja_acento.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pildora_cumplimiento.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tabla_modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bitácora de tareas rutinarias (vista `tacTareas/Bitacora`, archivo SQL 55).
///
/// Dos preguntas que hasta ahora no tenían dónde hacerse:
///
/// - **Cumplimiento**: qué tareas se hicieron y cuáles no, en un rango. Una
///   pendiente cuya fecha ya pasó cuenta como no realizada: la gente no marca
///   "No", deja de responder.
/// - **Generación**: por qué el Job le generó o no una tarea a alguien, y
///   cuántos candidatos cayeron en cada motivo en cada corrida.
///
/// Sistemas y RR.HH. ven toda la empresa; los demás, su equipo y a sí mismos.
/// Lo decide el servidor desde el token: esta pantalla no manda ningún alcance.
class BitacoraTareasScreen extends ConsumerWidget {
  const BitacoraTareasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void avisar(String? previo, String? actual) {
      if (actual != null && actual != previo) {
        mostrarAviso(context, actual, tono: TonoAviso.error);
      }
    }

    // Los tres providers son autoDispose. Escucharlos aquí, y no solo dentro
    // de cada pestaña, los mantiene vivos al cambiar de pestaña: si no, volver
    // a "Cumplimiento" consultaba otra vez el rango entero y perdía los
    // filtros.
    ref.listen<String?>(
      bitacoraCumplimientoProvider.select((s) => s.error),
      avisar,
    );
    ref.listen<String?>(
      bitacoraGeneracionProvider.select((s) => s.error),
      avisar,
    );
    ref.listen<String?>(bitacoraPorQueProvider.select((s) => s.error), avisar);

    return TareasScope(
      child: DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBarTareas(
          titulo: 'Bitácora de tareas',
          subtitulo: 'Qué se hizo y qué no, y por qué el Job generó cada tarea',
          insignia: InsigniaTarea.modulo(context, Icons.fact_check_outlined),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.fact_check_outlined), text: 'Cumplimiento'),
              Tab(icon: Icon(Icons.manage_search), text: 'Generación'),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [_PestanaCumplimiento(), _PestanaGeneracion()],
          ),
        ),
      ),
    ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUXILIARES
// ─────────────────────────────────────────────────────────────────────────────

DateTime _soloDia(DateTime f) => DateTime(f.year, f.month, f.day);

String _fecha(DateTime? f) =>
    f == null ? '—' : FormatearFecha.formatearFecha(f);

String _textoRango(DateTime desde, DateTime hasta) =>
    desde == hasta
        ? FormatearFecha.formatearFecha(desde)
        : '${FormatearFecha.formatearFecha(desde)} – '
            '${FormatearFecha.formatearFecha(hasta)}';

// El mismo tono que usa el panel de tareas del día de la revisión de Cierre
// de Operaciones: una "No realizada" no puede verse de dos maneras según la
// pantalla.
({Color fondo, Color texto}) _tono(BuildContext context, Cumplimiento? c) =>
    tonoDeCumplimiento(context, c);

List<({String nombre, DateTime desde, DateTime hasta})> _atajos(DateTime hoy) =>
    [
      (nombre: 'Hoy', desde: hoy, hasta: hoy),
      (
        nombre: '7 días',
        desde: DateTime(hoy.year, hoy.month, hoy.day - 6),
        hasta: hoy,
      ),
      (nombre: 'Este mes', desde: DateTime(hoy.year, hoy.month, 1), hasta: hoy),
      (
        nombre: 'Mes anterior',
        desde: DateTime(hoy.year, hoy.month - 1, 1),
        // El día 0 de un mes es el último del anterior.
        hasta: DateTime(hoy.year, hoy.month, 0),
      ),
    ];

class _Vacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? detalle;
  final Widget? accion;

  const _Vacio({
    required this.icono,
    required this.titulo,
    this.detalle,
    this.accion,
  });

  @override
  Widget build(BuildContext context) => EstadoTareas(
    icono: icono,
    titulo: titulo,
    detalle: detalle,
    accion: accion,
  );
}

class _Reintentar extends StatelessWidget {
  final String texto;
  final VoidCallback onReintentar;

  const _Reintentar({required this.texto, required this.onReintentar});

  @override
  Widget build(BuildContext context) =>
      EstadoTareas.error(titulo: texto, onReintentar: onReintentar);
}

class _PildoraEstado extends StatelessWidget {
  final Cumplimiento? cumplimiento;

  const _PildoraEstado({required this.cumplimiento});

  @override
  Widget build(BuildContext context) {
    final tono = _tono(context, cumplimiento);
    return PildoraTareas(
      texto: cumplimiento?.etiqueta ?? '—',
      fondo: tono.fondo,
      color: tono.texto,
    );
  }
}

class _PildoraFrecuencia extends StatelessWidget {
  final int? idFrec;
  final String? texto;

  const _PildoraFrecuencia({required this.idFrec, required this.texto});

  @override
  Widget build(BuildContext context) {
    final t = texto ?? '—';
    final id = idFrec;
    if (id == null) {
      return Text(t, style: Theme.of(context).textTheme.bodySmall);
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: PildoraTareas.frecuencia(context, id, t),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PESTAÑA CUMPLIMIENTO
// ─────────────────────────────────────────────────────────────────────────────

class _PestanaCumplimiento extends ConsumerWidget {
  const _PestanaCumplimiento();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bitacoraCumplimientoProvider);
    final ancho = MediaQuery.sizeOf(context).width;
    final amplia = ancho >= TareasBreakpoints.mediumMax;

    return MargenPaginaTareas(
      abajo: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BarraCumplimiento(state: state, amplia: amplia),
          const SizedBox(height: 12),
          if (state.cargado && state.filas.isNotEmpty) ...[
            _Resumen(state: state, amplia: amplia),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: _CuerpoCumplimiento(
              state: state,
              enTabla: ancho >= TareasBreakpoints.wideMax,
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _selectores(
  BitacoraCumplimientoState s,
  BitacoraCumplimientoNotifier n, {
  required bool anchoFijo,
}) => [
  _Selector(
    etiqueta: 'Sucursal',
    todas: 'Todas',
    valor: s.codSucursal,
    opciones: s.sucursales,
    onCambio: n.filtrarSucursal,
    ancho: anchoFijo ? 200 : null,
  ),
  _Selector(
    etiqueta: 'Cargo',
    todas: 'Todos',
    valor: s.codCargo,
    opciones: s.cargos,
    onCambio: n.filtrarCargo,
    ancho: anchoFijo ? 220 : null,
  ),
  _Selector(
    etiqueta: 'Persona',
    todas: 'Todas',
    valor: s.codEmpleado,
    opciones: s.personas,
    onCambio: n.filtrarPersona,
    ancho: anchoFijo ? 240 : null,
  ),
  _Selector(
    etiqueta: 'Tarea',
    todas: 'Todas',
    valor: s.idTarRuti,
    opciones: s.tareas,
    onCambio: n.filtrarTarea,
    ancho: anchoFijo ? 300 : null,
  ),
];

class _BarraCumplimiento extends ConsumerWidget {
  final BitacoraCumplimientoState state;
  final bool amplia;

  const _BarraCumplimiento({required this.state, required this.amplia});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(bitacoraCumplimientoProvider.notifier);
    final hoy = _soloDia(DateTime.now());

    final rango = ActionChip(
      avatar: const Icon(Icons.date_range, size: 18),
      label: Text(_textoRango(state.desde, state.hasta)),
      tooltip: 'Cambiar el rango',
      onPressed: state.cargando ? null : () => _elegirRango(context, ref),
    );

    final pdf = FilledButton.tonalIcon(
      onPressed:
          !state.cargado || state.visibles.isEmpty || state.descargandoPdf
              ? null
              : () => _abrirPdf(context, ref),
      icon:
          state.descargandoPdf
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.picture_as_pdf_outlined, size: 18),
      label: const Text('PDF'),
    );

    if (!amplia) {
      return Row(
        children: [
          Expanded(child: Align(alignment: Alignment.centerLeft, child: rango)),
          const SizedBox(width: 8),
          Badge(
            isLabelVisible: state.cantidadFiltros > 0,
            label: Text('${state.cantidadFiltros}'),
            child: IconButton.filledTonal(
              tooltip: 'Filtros',
              icon: const Icon(Icons.filter_list),
              onPressed: state.cargado ? () => _abrirFiltros(context) : null,
            ),
          ),
          const SizedBox(width: 8),
          pdf,
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        rango,
        for (final atajo in _atajos(hoy))
          ChoiceChip(
            label: Text(atajo.nombre),
            selected: state.desde == atajo.desde && state.hasta == atajo.hasta,
            onSelected:
                state.cargando
                    ? null
                    : (_) => notifier.cambiarRango(atajo.desde, atajo.hasta),
          ),
        if (state.cargado) ..._selectores(state, notifier, anchoFijo: true),
        if (state.cantidadFiltros > 0)
          TextButton.icon(
            onPressed: notifier.limpiarFiltros,
            icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
            label: const Text('Quitar filtros'),
          ),
        pdf,
      ],
    );
  }

  Future<void> _elegirRango(BuildContext context, WidgetRef ref) async {
    final r = await pedirRangoDeFechas(
      context,
      titulo: 'Rango de la bitácora',
      explicacion:
          'Las tareas cuya fecha de presentación cae en este rango. Hasta un año.',
      desde: state.desde,
      hasta: state.hasta,
      textoAceptar: 'Aplicar',
      iconoAceptar: Icons.check,
    );
    if (r == null || !context.mounted) return;
    await ref
        .read(bitacoraCumplimientoProvider.notifier)
        .cambiarRango(r.desde, r.hasta);
  }

  Future<void> _abrirPdf(BuildContext context, WidgetRef ref) async {
    if (state.visibles.length > maxFilasPdfBitacora) {
      mostrarAviso(
        context,
        'Son ${state.visibles.length} filas. Para el PDF acota el rango o los '
        'filtros (máximo $maxFilasPdfBitacora).',
        tono: TonoAviso.aviso,
      );
      return;
    }
    final desde = state.desde;
    final hasta = state.hasta;
    final bytes = await ref.read(bitacoraCumplimientoProvider.notifier).pdf();
    if (bytes == null || !context.mounted) return;
    await mostrarPdf(
      context,
      bytes: bytes,
      titulo: 'Bitácora de cumplimiento',
      nombreArchivo:
          'bitacora_cumplimiento_${fechaParaSql(desde)}_${fechaParaSql(hasta)}.pdf',
    );
  }

  void _abrirFiltros(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (_) => Consumer(
            builder: (context, ref, _) {
              final s = ref.watch(bitacoraCumplimientoProvider);
              final n = ref.read(bitacoraCumplimientoProvider.notifier);
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    16 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Filtros',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      for (final selector in _selectores(s, n, anchoFijo: false))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: selector,
                        ),
                      Row(
                        children: [
                          if (s.cantidadFiltros > 0)
                            TextButton(
                              onPressed: n.limpiarFiltros,
                              child: const Text('Quitar filtros'),
                            ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () => cerrarRuta(context),
                            child: const Text('Listo'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}

/// Un filtro con lista desplegable. Escribir salta a la opción que coincide.
class _Selector extends StatelessWidget {
  final String etiqueta;
  final String todas;
  final int? valor;
  final List<OpcionFiltro> opciones;
  final ValueChanged<int?> onCambio;

  /// Nulo: ocupa todo el ancho disponible.
  final double? ancho;

  const _Selector({
    required this.etiqueta,
    required this.todas,
    required this.valor,
    required this.opciones,
    required this.onCambio,
    required this.ancho,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<int?>(
      // La clave cambia con el valor: DropdownMenu guarda su propio texto y
      // no se entera si "Quitar filtros" le cambia la selección desde afuera.
      key: ValueKey('$etiqueta:$valor'),
      width: ancho,
      expandedInsets: ancho == null ? EdgeInsets.zero : null,
      menuHeight: 360,
      label: Text(etiqueta),
      leadingIcon:
          valor == null ? null : const Icon(Icons.filter_alt, size: 18),
      initialSelection: valor,
      requestFocusOnTap: true,
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
      onSelected: onCambio,
      dropdownMenuEntries: [
        DropdownMenuEntry<int?>(value: null, label: todas),
        for (final o in opciones)
          DropdownMenuEntry<int?>(value: o.id, label: o.etiqueta),
      ],
    );
  }
}

class _Resumen extends ConsumerWidget {
  final BitacoraCumplimientoState state;
  final bool amplia;

  const _Resumen({required this.state, required this.amplia});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(bitacoraCumplimientoProvider.notifier);
    final r = state.resumen;

    final tarjetas = <Widget>[
      _TarjetaPorcentaje(resumen: r),
      for (final c in Cumplimiento.values)
        _TarjetaEstado(
          cumplimiento: c,
          cantidad: r.cantidad(c),
          total: r.total,
          elegida: state.estado == c,
          onTap: () => notifier.filtrarEstado(state.estado == c ? null : c),
        ),
    ];

    if (amplia) {
      return SizedBox(
        height: 96,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < tarjetas.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(flex: i == 0 ? 2 : 1, child: tarjetas[i]),
            ],
          ],
        ),
      );
    }

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tarjetas.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder:
            (_, i) => SizedBox(width: i == 0 ? 180 : 140, child: tarjetas[i]),
      ),
    );
  }
}

class _TarjetaPorcentaje extends StatelessWidget {
  final ResumenCumplimiento resumen;

  const _TarjetaPorcentaje({required this.resumen});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final p = resumen.porcentaje;
    final color = TareasColors.realizadoTexto(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Tooltip(
        message:
            'Realizadas sobre realizadas más no realizadas. '
            '"No aplica" y "En plazo" no cuentan.',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cumplimiento',
                style: tema.textTheme.labelMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                p == null ? '—' : '${(p * 100).round()} %',
                style: tema.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              LinearProgressIndicator(
                value: p ?? 0,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
                color: color,
                backgroundColor: tema.colorScheme.surfaceContainerHighest,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaEstado extends StatelessWidget {
  final Cumplimiento cumplimiento;
  final int cantidad;
  final int total;
  final bool elegida;
  final VoidCallback onTap;

  const _TarjetaEstado({
    required this.cumplimiento,
    required this.cantidad,
    required this.total,
    required this.elegida,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tono = _tono(context, cumplimiento);
    final parte = total == 0 ? 0 : (cantidad * 100 / total).round();

    return Semantics(
      button: true,
      selected: elegida,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: elegida ? tono.fondo : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: elegida ? tono.texto : tema.colorScheme.outlineVariant,
            width: elegida ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: FranjaAcento(
            color: tono.texto,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cumplimiento.plural,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.labelMedium?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '$cantidad',
                    style: tema.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: tono.texto,
                    ),
                  ),
                  Text(
                    '$parte % del total',
                    maxLines: 1,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
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

class _CuerpoCumplimiento extends ConsumerWidget {
  final BitacoraCumplimientoState state;
  final bool enTabla;

  const _CuerpoCumplimiento({required this.state, required this.enTabla});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(bitacoraCumplimientoProvider.notifier);

    if (!state.cargado) {
      // Una lectura fallida no puede verse como "no hubo tareas".
      return state.cargando
          ? const Center(child: CircularProgressIndicator())
          : _Reintentar(
            texto: 'No se pudo leer la bitácora.',
            onReintentar: notifier.cargar,
          );
    }
    if (state.filas.isEmpty) {
      return const _Vacio(
        icono: Icons.event_busy_outlined,
        titulo: 'No hay tareas rutinarias en este rango',
        detalle: 'Prueba con un rango más amplio.',
      );
    }
    if (state.visibles.isEmpty) {
      return _Vacio(
        icono: Icons.filter_alt_off_outlined,
        titulo: 'Ninguna tarea coincide con los filtros',
        accion: TextButton.icon(
          onPressed: notifier.limpiarFiltros,
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Quitar filtros'),
        ),
      );
    }

    void verDetalle(BitacoraCumplimientoEntity fila) =>
        _mostrarDetalle(context, ref, fila);

    return enTabla
        ? _TablaCumplimiento(filas: state.visibles, onTap: verDetalle)
        : _ListaCumplimiento(filas: state.visibles, onTap: verDetalle);
  }
}

const _anchosCumplimiento = <AnchoCol>[
  AnchoCol.fijo(86), // fecha
  AnchoCol.flexible(3), // persona
  AnchoCol.flexible(2), // cargo
  AnchoCol.fijo(120), // sucursal
  AnchoCol.flexible(4), // tarea
  AnchoCol.fijo(86), // frecuencia
  AnchoCol.fijo(112), // estado
  AnchoCol.fijo(132), // respondida
];

class _TablaCumplimiento extends StatelessWidget {
  final List<BitacoraCumplimientoEntity> filas;
  final ValueChanged<BitacoraCumplimientoEntity> onTap;

  const _TablaCumplimiento({required this.filas, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MarcoTabla(
      child: Column(
        children: [
          const EncabezadoTabla(
            anchos: _anchosCumplimiento,
            titulos: [
              'Fecha',
              'Persona',
              'Cargo en esa fecha',
              'Sucursal',
              'Tarea',
              'Frecuencia',
              'Estado',
              'Respondida',
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filas.length,
              itemBuilder:
                  (_, i) => _FilaCumplimiento(
                    fila: filas[i],
                    par: i.isEven,
                    onTap: onTap,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaCumplimiento extends StatelessWidget {
  final BitacoraCumplimientoEntity fila;
  final bool par;
  final ValueChanged<BitacoraCumplimientoEntity> onTap;

  const _FilaCumplimiento({
    required this.fila,
    required this.par,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final suave = tema.textTheme.bodySmall?.copyWith(
      color: tema.colorScheme.onSurfaceVariant,
    );
    final obs = (fila.obs ?? '').trim();

    return Material(
      color:
          par ? tema.colorScheme.surface : tema.colorScheme.surfaceContainerLowest,
      child: InkWell(
        onTap: () => onTap(fila),
        child: FilaTabla(
          anchos: _anchosCumplimiento,
          alineacion: CrossAxisAlignment.start,
          borde: Border(
            bottom: BorderSide(
              color: tema.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          celdas: [
            Text(_fecha(fila.fechaPresentacion)),
            Text(
              fila.nombreEmpleado,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              fila.descripcionCargo ?? '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: suave,
            ),
            Text(
              fila.nombreSucursal ?? '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: suave,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fila.nombreTareaRutinaria,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (obs.isNotEmpty)
                  Text(
                    'Obs.: $obs',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: suave,
                  ),
              ],
            ),
            _PildoraFrecuencia(
              idFrec: fila.idFrec,
              texto: fila.descripcionFrecuencia,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: _PildoraEstado(cumplimiento: fila.cumplimiento),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fila.fechaCompletado == null
                      ? '—'
                      : FormatearFecha.formatearFechaHora(fila.fechaCompletado!),
                  style: tema.textTheme.bodySmall,
                ),
                if (fila.nombreRespondio != null)
                  Text(
                    fila.nombreRespondio!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: suave,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaCumplimiento extends StatelessWidget {
  final List<BitacoraCumplimientoEntity> filas;
  final ValueChanged<BitacoraCumplimientoEntity> onTap;

  const _ListaCumplimiento({required this.filas, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: filas.length,
      itemBuilder: (_, i) => _TarjetaCumplimiento(fila: filas[i], onTap: onTap),
    );
  }
}

class _TarjetaCumplimiento extends StatelessWidget {
  final BitacoraCumplimientoEntity fila;
  final ValueChanged<BitacoraCumplimientoEntity> onTap;

  const _TarjetaCumplimiento({required this.fila, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tono = _tono(context, fila.cumplimiento);
    final suave = tema.textTheme.bodySmall?.copyWith(
      color: tema.colorScheme.onSurfaceVariant,
    );
    final obs = (fila.obs ?? '').trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap(fila),
        child: FranjaAcento(
          color: tono.texto,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        fila.nombreTareaRutinaria,
                        style: tema.textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _PildoraEstado(cumplimiento: fila.cumplimiento),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    fila.nombreEmpleado,
                    fila.descripcionCargo,
                  ].whereType<String>().join(' · '),
                  style: suave,
                ),
                Text(
                  [
                    _fecha(fila.fechaPresentacion),
                    fila.nombreSucursal,
                    fila.descripcionFrecuencia,
                  ].whereType<String>().join(' · '),
                  style: suave,
                ),
                if (obs.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Obs.: $obs', style: tema.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _mostrarDetalle(
  BuildContext context,
  WidgetRef ref,
  BitacoraCumplimientoEntity f,
) {
  final pestanas = DefaultTabController.of(context);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final tema = Theme.of(ctx);

      Widget dato(String etiqueta, String? valor) {
        if (valor == null || valor.trim().isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  etiqueta,
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(child: Text(valor.trim())),
            ],
          ),
        );
      }

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      f.nombreTareaRutinaria,
                      style: tema.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PildoraEstado(cumplimiento: f.cumplimiento),
                ],
              ),
              const SizedBox(height: 16),
              dato('Persona', f.nombreEmpleado),
              dato('Cargo en esa fecha', f.descripcionCargo),
              dato('Sucursal', f.nombreSucursal),
              dato('Fecha de la tarea', _fecha(f.fechaPresentacion)),
              dato('Frecuencia', f.descripcionFrecuencia),
              dato(
                'Respondida',
                f.fechaCompletado == null
                    ? null
                    : FormatearFecha.formatearFechaHora(f.fechaCompletado!),
              ),
              dato('Respondió', f.nombreRespondio),
              dato('Observación', f.obs),
              if (f.codEmpleado != null && f.fechaPresentacion != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.manage_search),
                  label: const Text('Ver por qué le llegó esta tarea'),
                  onPressed: () {
                    cerrarRuta(ctx);
                    ref
                        .read(bitacoraPorQueProvider.notifier)
                        .consultarPara(
                          PersonaBuscada(
                            codEmpleado: f.codEmpleado!,
                            nombre: f.nombreEmpleado,
                            cargo: f.descripcionCargo,
                          ),
                          f.fechaPresentacion!,
                        );
                    pestanas.animateTo(1);
                  },
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PESTAÑA GENERACIÓN
// ─────────────────────────────────────────────────────────────────────────────

class _PestanaGeneracion extends StatefulWidget {
  const _PestanaGeneracion();

  @override
  State<_PestanaGeneracion> createState() => _PestanaGeneracionState();
}

class _PestanaGeneracionState extends State<_PestanaGeneracion> {
  /// En pantallas angostas los dos paneles no entran juntos.
  int _vista = 0;

  @override
  Widget build(BuildContext context) {
    final amplia = MediaQuery.sizeOf(context).width >= TareasBreakpoints.wideMax;

    if (amplia) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: _PanelPorQue()),
            SizedBox(width: 12),
            Expanded(flex: 4, child: _PanelCorridas()),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                icon: Icon(Icons.person_search_outlined),
                label: Text('Por persona'),
              ),
              ButtonSegment(
                value: 1,
                icon: Icon(Icons.history),
                label: Text('Corridas'),
              ),
            ],
            selected: {_vista},
            onSelectionChanged: (s) => setState(() => _vista = s.first),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _vista == 0 ? const _PanelPorQue() : const _PanelCorridas(),
          ),
        ],
      ),
    );
  }
}

class _PanelPorQue extends ConsumerWidget {
  const _PanelPorQue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bitacoraPorQueProvider);
    final notifier = ref.read(bitacoraPorQueProvider.notifier);
    final tema = Theme.of(context);

    return MarcoTabla(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Por qué le llegó o no una tarea?',
                  style: tema.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Tarea por tarea, el filtro del generador que dejó afuera a '
                  'una persona en una fecha.',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 320,
                      child: _BuscadorPersona(
                        persona: state.persona,
                        onElegir: notifier.elegirPersona,
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.event, size: 18),
                      label: Text(FormatearFecha.formatearFecha(state.fecha)),
                      tooltip: 'Cambiar la fecha',
                      onPressed: () async {
                        final f = await showDatePicker(
                          context: context,
                          initialDate: state.fecha,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 366),
                          ),
                          helpText: 'Fecha de presentación',
                        );
                        if (f != null) notifier.cambiarFecha(f);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 3,
            child: state.cargando ? const LinearProgressIndicator() : null,
          ),
          Expanded(
            child: _ResultadoPorQue(
              state: state,
              onReintentar: notifier.consultar,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuscadorPersona extends ConsumerStatefulWidget {
  /// Nula = quien consulta.
  final PersonaBuscada? persona;
  final ValueChanged<PersonaBuscada?> onElegir;

  const _BuscadorPersona({required this.persona, required this.onElegir});

  @override
  ConsumerState<_BuscadorPersona> createState() => _BuscadorPersonaState();
}

class _BuscadorPersonaState extends ConsumerState<_BuscadorPersona> {
  TextEditingController? _campo;

  Future<Iterable<PersonaBuscada>> _buscar(TextEditingValue valor) async {
    final texto = valor.text.trim();
    if (texto.length < 2) return const [];
    // Espera a que se deje de escribir: cada búsqueda es un pedido al
    // servidor. Si el texto cambió mientras tanto, esta ya no es la que vale.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted || _campo?.text != valor.text) return const [];
    try {
      return await ref.read(bitacoraTareasRepoProvider).buscarPersonas(texto);
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final persona = widget.persona;
    if (persona != null) {
      return InputChip(
        avatar: const Icon(Icons.person_outline, size: 18),
        label: Text(
          persona.cargo == null
              ? persona.nombre
              : '${persona.nombre} · ${persona.cargo}',
          overflow: TextOverflow.ellipsis,
        ),
        deleteButtonTooltipMessage: 'Volver a consultar por mí',
        onDeleted: () => widget.onElegir(null),
      );
    }

    return Autocomplete<PersonaBuscada>(
      displayStringForOption: (p) => p.nombre,
      optionsBuilder: _buscar,
      onSelected: widget.onElegir,
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        _campo = controller;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Persona',
            hintText: 'Tú. Escribe un nombre para consultar por otra',
            prefixIcon: Icon(Icons.person_search_outlined),
            isDense: true,
            border: OutlineInputBorder(),
          ),
        );
      },
    );
  }
}

class _ResultadoPorQue extends StatelessWidget {
  final BitacoraPorQueState state;
  final VoidCallback onReintentar;

  const _ResultadoPorQue({required this.state, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    if (!state.consultado) {
      if (state.cargando) return const SizedBox.shrink();
      return _Reintentar(
        texto: 'No se pudo consultar.',
        onReintentar: onReintentar,
      );
    }
    if (state.filas.isEmpty) {
      return const _Vacio(
        icono: Icons.inbox_outlined,
        titulo: 'Ninguno de los cargos de esta persona tiene tareas rutinarias',
      );
    }

    final r = state.resumen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _Contador(
                icono: Icons.check_circle_outline,
                color: TareasColors.realizadoTexto(context),
                texto:
                    r.generadas == 1
                        ? '1 se generó'
                        : '${r.generadas} se generaron',
              ),
              _Contador(
                icono: Icons.block,
                color: TareasColors.vencidoTexto(context),
                texto:
                    r.fuera == 1 ? '1 quedó afuera' : '${r.fuera} quedaron afuera',
              ),
              _Contador(
                icono: Icons.schedule,
                color: TareasColors.pendienteTexto(context),
                texto:
                    r.sinGenerar == 1
                        ? '1 pasó los filtros sin generarse'
                        : '${r.sinGenerar} pasaron los filtros sin generarse',
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 12),
            itemCount: state.filas.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 54),
            itemBuilder: (_, i) => _FilaDiagnostico(fila: state.filas[i]),
          ),
        ),
      ],
    );
  }
}

class _Contador extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String texto;

  const _Contador({
    required this.icono,
    required this.color,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(width: 4),
        Text(texto, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _FilaDiagnostico extends StatelessWidget {
  final DiagnosticoGeneracionEntity fila;

  const _FilaDiagnostico({required this.fila});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final (IconData icono, Color color) =
        fila.existeOcurrencia
            ? (Icons.check_circle, TareasColors.realizadoTexto(context))
            : fila.filtro == 0
            ? (Icons.schedule, TareasColors.pendienteTexto(context))
            : fila.filtro < 0
            ? (Icons.info_outline, tema.colorScheme.onSurfaceVariant)
            : (Icons.block, TareasColors.vencidoTexto(context));
    final detalle = [
      fila.cargo,
      fila.sucursal,
      fila.frecuencia,
    ].whereType<String>().join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fila.tarea ?? 'Tarea',
                  style: tema.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fila.motivoLegible,
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: fila.quedoFuera ? color : null,
                  ),
                ),
                if (detalle.isNotEmpty)
                  Text(
                    detalle,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (fila.filtro > 0) ...[
            const SizedBox(width: 8),
            Tooltip(
              message:
                  'Filtro ${fila.filtro} del generador, en el orden en que los '
                  'evalúa',
              child: CircleAvatar(
                radius: 12,
                backgroundColor: TareasColors.vencido(context),
                child: Text(
                  '${fila.filtro}',
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: TareasColors.vencidoTexto(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PanelCorridas extends ConsumerWidget {
  const _PanelCorridas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bitacoraGeneracionProvider);
    final notifier = ref.read(bitacoraGeneracionProvider.notifier);
    final tema = Theme.of(context);

    final Widget cuerpo;
    if (!state.cargado) {
      cuerpo =
          state.cargando
              ? const Center(child: CircularProgressIndicator())
              : _Reintentar(
                texto: 'No se pudo leer las corridas.',
                onReintentar: notifier.cargar,
              );
    } else if (state.corridas.isEmpty) {
      cuerpo = const _Vacio(
        icono: Icons.history_toggle_off,
        titulo: 'No hay corridas registradas en este rango',
        detalle: 'Prueba con un rango más amplio.',
      );
    } else {
      cuerpo = ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: state.corridas.length,
        itemBuilder: (_, i) => _TarjetaCorrida(corrida: state.corridas[i]),
      );
    }

    return MarcoTabla(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Corridas del generador · toda la empresa',
                        style: tema.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      // Marcelo no ubicaba el panel: "¿es de todos o de cada
                      // persona?". Es de todos, y la pantalla tiene que decirlo.
                      Text(
                        'No es de una persona. En cada corrida el Job revisa '
                        'cada tarea de cada cargo que tuvo cada persona '
                        '(también cargos viejos y gente que ya no está) y '
                        'cuenta dónde quedó cada combinación. Para una '
                        'persona, usa «¿Por qué le llegó o no una tarea?».',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: Text(_textoRango(state.desde, state.hasta)),
                  tooltip: 'Cambiar el rango',
                  onPressed:
                      state.cargando
                          ? null
                          : () async {
                            final r = await pedirRangoDeFechas(
                              context,
                              titulo: 'Corridas del generador',
                              explicacion:
                                  'Las corridas del Job registradas en este rango.',
                              desde: state.desde,
                              hasta: state.hasta,
                              textoAceptar: 'Aplicar',
                              iconoAceptar: Icons.check,
                            );
                            if (r != null) {
                              notifier.cambiarRango(r.desde, r.hasta);
                            }
                          },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: cuerpo),
        ],
      ),
    );
  }
}

class _TarjetaCorrida extends StatelessWidget {
  final CorridaGeneracion corrida;

  const _TarjetaCorrida({required this.corrida});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final maximo = corrida.maximo;
    // Cada combinación cae en un solo motivo (el primer filtro que la deja
    // afuera), así que la suma es cuántas revisó la corrida.
    final revisadas = corrida.motivos.fold<int>(0, (a, m) => a + m.cantidad);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  size: 18,
                  color: tema.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    FormatearFecha.formatearFechaHora(corrida.corrida),
                    style: tema.textTheme.titleSmall,
                  ),
                ),
                PildoraTareas(
                  texto:
                      corrida.generadas == 1
                          ? '1 generada'
                          : '${corrida.generadas} generadas',
                  fondo: TareasColors.realizado(context),
                  color: TareasColors.realizadoTexto(context),
                  tooltip: explicacionDelMotivo(motivoGeneradas),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Revisó $revisadas combinaciones de persona y tarea',
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            for (final m in corrida.motivos)
              _BarraMotivo(motivo: m, maximo: maximo),
          ],
        ),
      ),
    );
  }
}

class _BarraMotivo extends StatelessWidget {
  final ResumenGeneracionEntity motivo;
  final int maximo;

  const _BarraMotivo({required this.motivo, required this.maximo});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final explicacion = explicacionDelMotivo(motivo.motivo);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conTildes(motivo.motivo),
                      style: tema.textTheme.bodySmall,
                    ),
                    // El nombre solo no dice qué cuenta: "Cargo no vigente"
                    // no se entiende sin conocer el generador.
                    if (explicacion != null)
                      Text(
                        explicacion,
                        style: tema.textTheme.labelSmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${motivo.cantidad}',
                style: tema.textTheme.labelMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          LinearProgressIndicator(
            value: maximo == 0 ? 0 : motivo.cantidad / maximo,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            color: tema.colorScheme.primary.withValues(alpha: 0.75),
            backgroundColor: tema.colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}
