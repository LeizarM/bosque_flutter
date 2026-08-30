/// Ver lote de produccion: los lotes ya cortados, con su cuadre a la vista.
///
/// Reemplaza a `tprod_loteProduccion/ViewLoteProduccion.xhtml`. Lo que cambia
/// respecto de la grilla anterior:
///
/// - **Cada lote dice si cuadra.** La diferencia sin explicar viaja como
///   estado y no como una columna mas de numeros.
/// - **Se puede buscar y filtrar por maquina.** Antes habia que recorrer los
///   125 registros a ojo.
/// - **El boton de abrir dice por que no esta.** Un lote cerrado solo lo reabre
///   quien tenga el permiso `btnVer`; antes el boton simplemente desaparecia.
///
/// La planilla completa —las diecisiete columnas del sistema anterior mas los
/// totales del periodo— esta en [TablaLotes], y es la vista por defecto: la
/// produccion del dia se revisa comparando lotes, no abriendolos de a uno.
library;

import 'package:bosque_flutter/core/state/button_permissions_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/state/ver_lote_produccion_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/descargar_reportes_jasper.dart';
import 'package:bosque_flutter/domain/entities/lote_produccion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/lote-produccion/balance_lote.dart';
import 'package:bosque_flutter/presentation/widgets/lote-produccion/detalle_lote_dialog.dart';
import 'package:bosque_flutter/core/ui/rango_fechas.dart';
import 'package:bosque_flutter/presentation/widgets/lote-produccion/tabla_lotes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Permiso para reabrir un lote ya cerrado. Es el mismo nombre que usaba el
/// sistema anterior, asi que no hay que dar de alta un permiso nuevo.
const _btnVer = 'btnVer';

class VerLoteProduccionScreen extends ConsumerStatefulWidget {
  const VerLoteProduccionScreen({super.key});

  @override
  ConsumerState<VerLoteProduccionScreen> createState() =>
      _VerLoteProduccionScreenState();
}

class _VerLoteProduccionScreenState
    extends ConsumerState<VerLoteProduccionScreen> {
  final _buscarCtrl = TextEditingController();

  /// Arranca completa: es lo que se pidio ver sin entrar lote por lote. La
  /// vista corta queda a un clic para el dia a dia.
  VistaLotes _vista = VistaLotes.completa;

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  // ── Acciones ──────────────────────────────────────────────────────────────

  Future<void> _abrir(LoteProduccionEntity lote, bool puedeReabrir) async {
    final abierto = lote.estado == 1;
    final soloLectura = !abierto && !puedeReabrir;

    final guardado = await abrirDetalleLote(
      context,
      lote: lote,
      audUsuario: ref.read(userProvider)?.codUsuario ?? 0,
      soloLectura: soloLectura,
    );
    if (guardado && mounted) {
      await ref.read(verLotesProvider.notifier).cargar();
    }
  }

  Future<void> _reporteDelLote(LoteProduccionEntity lote) => mostrarReportePdf(
    context: context,
    downloadFunction: () => ref
        .read(loteProduccionRepositoryProvider)
        .reporteLotePdf(lote.idLp),
    filename: 'lote_produccion_${lote.numLote}_${lote.anio}.pdf',
  );

  Future<void> _cambiarRango() async {
    final actual = ref.read(verLotesProvider);
    final rango = await pedirRangoDeFechas(
      context,
      titulo: 'Periodo a consultar',
      explicacion:
          'Se traen de la base solo los lotes cortados en estas fechas.',
      desde: actual.desde,
      hasta: actual.hasta,
      textoAceptar: 'Aplicar',
      iconoAceptar: Icons.filter_alt_outlined,
    );
    if (rango == null || !mounted) return;
    await ref.read(verLotesProvider.notifier).setRango(rango.desde, rango.hasta);
  }

  Future<void> _reporteProduccion() async {
    final rango = await pedirRangoDeFechas(
      context,
      titulo: 'Reporte de produccion',
      explicacion:
          'Cuadro resumen por maquina de los lotes cortados en el periodo.',
    );
    if (rango == null || !mounted) return;

    await mostrarReportePdf(
      context: context,
      downloadFunction: () => ref
          .read(loteProduccionRepositoryProvider)
          .reporteResumenProduccionPdf(rango.desde, rango.hasta),
      filename:
          'resumen_produccion_${fechaArchivo(rango.desde)}_'
          '${fechaArchivo(rango.hasta)}.pdf',
    );
  }

  Future<void> _reporteResmado() async {
    final rango = await pedirRangoDeFechas(
      context,
      titulo: 'Reporte de resmado',
      explicacion: 'Resmas por grupo y por articulo en el periodo.',
    );
    if (rango == null || !mounted) return;

    await mostrarReportePdf(
      context: context,
      downloadFunction: () => ref
          .read(loteProduccionRepositoryProvider)
          .reporteResmadoPdf(rango.desde, rango.hasta),
      filename:
          'resmado_${fechaArchivo(rango.desde)}_'
          '${fechaArchivo(rango.hasta)}.pdf',
    );
  }

  Future<void> _reporteCorte() async {
    final rango = await pedirRangoDeFechas(
      context,
      titulo: 'Reporte de solicitud de corte',
      explicacion: 'Consolidado de corte por maquina en el periodo.',
    );
    if (rango == null || !mounted) return;

    await mostrarReportePdf(
      context: context,
      downloadFunction: () => ref
          .read(loteProduccionRepositoryProvider)
          .reporteConsolidadoCortePdf(rango.desde, rango.hasta),
      filename:
          'consolidado_corte_${fechaArchivo(rango.desde)}_'
          '${fechaArchivo(rango.hasta)}.pdf',
    );
  }

  // ── Dibujo ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(verLotesProvider);
    final notifier = ref.read(verLotesProvider.notifier);

    // Se observa, no se lee de una vez: los permisos llegan por red despues del
    // primer dibujo, y con `read` la lista quedaba con los botones del estado
    // inicial hasta que algo mas la hiciera reconstruirse.
    final puedeReabrir = ref
        .watch(buttonPermissionsProvider)
        .maybeWhen(
          data: (_) => ref
              .read(buttonPermissionsProvider.notifier)
              .tienePermiso(_btnVer),
          orElse: () => false,
        );

    ref.listen(verLotesProvider.select((e) => e.error), (_, error) {
      if (error != null && mounted) avisar(context, error, esError: true);
    });

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, restricciones) {
          final aire = Aire.de(restricciones.maxWidth);

          return Column(
            children: [
              _Cabecera(
                aire: aire,
                cantidad: estado.visibles.length,
                onReporteProduccion: _reporteProduccion,
                onReporteResmado: _reporteResmado,
                onReporteCorte: _reporteCorte,
                onRecargar: notifier.cargar,
              ),
              _BarraFiltros(
                aire: aire,
                estado: estado,
                vista: _vista,
                buscarCtrl: _buscarCtrl,
                onBuscar: notifier.setBusqueda,
                onMaquina: notifier.setMaquina,
                onRango: _cambiarRango,
                onVista: (v) => setState(() => _vista = v),
              ),
              SizedBox(
                height: 2,
                child: estado.cargando
                    ? const LinearProgressIndicator(minHeight: 2)
                    : null,
              ),
              Expanded(
                child: _Listado(
                  aire: aire,
                  estado: estado,
                  vista: _vista,
                  puedeReabrir: puedeReabrir,
                  onAbrir: (lote) => _abrir(lote, puedeReabrir),
                  onReporte: _reporteDelLote,
                  onRango: _cambiarRango,
                  onLimpiar: () {
                    _buscarCtrl.clear();
                    notifier.setBusqueda('');
                    notifier.setMaquina(null);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// `yyyy-MM-dd` para nombrar archivos, que es donde el orden alfabetico coincide
/// con el cronologico.
String fechaArchivo(DateTime f) =>
    '${f.year}-${f.month.toString().padLeft(2, '0')}-'
    '${f.day.toString().padLeft(2, '0')}';

// ═══════════════════════════════════════════════════════════════════════════
// CABECERA
// ═══════════════════════════════════════════════════════════════════════════

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.aire,
    required this.cantidad,
    required this.onReporteProduccion,
    required this.onReporteResmado,
    required this.onReporteCorte,
    required this.onRecargar,
  });

  final Aire aire;
  final int cantidad;
  final VoidCallback onReporteProduccion;
  final VoidCallback onReporteResmado;
  final VoidCallback onReporteCorte;
  final VoidCallback onRecargar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final acciones = [
      OutlinedButton.icon(
        onPressed: onReporteProduccion,
        icon: const Icon(Icons.summarize_outlined, size: 18),
        label: const Text('Reporte de produccion'),
      ),
      OutlinedButton.icon(
        onPressed: onReporteResmado,
        icon: const Icon(Icons.inventory_2_outlined, size: 18),
        label: const Text('Reporte de resmado'),
      ),
      OutlinedButton.icon(
        onPressed: onReporteCorte,
        icon: const Icon(Icons.content_cut, size: 18),
        label: const Text('Reporte de corte'),
      ),
      IconButton(
        onPressed: onRecargar,
        icon: const Icon(Icons.refresh),
        tooltip: 'Actualizar',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        aire.esChico ? Esp.m : Esp.xl,
        Esp.l,
        aire.esChico ? Esp.m : Esp.xl,
        Esp.m,
      ),
      color: cs.surfaceContainerLow,
      child: aire.esChico
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Titulo(cantidad: cantidad),
                SizedBox(height: Esp.m),
                Wrap(spacing: Esp.s, runSpacing: Esp.s, children: acciones),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Titulo(cantidad: cantidad)),
                Wrap(spacing: Esp.s, runSpacing: Esp.s, children: acciones),
              ],
            ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo({required this.cantidad});

  final int cantidad;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Lotes de produccion',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: Peso.titulo),
      ),
      SizedBox(height: Esp.xs),
      // No se repite el periodo: esta en el boton de abajo, que es donde se
      // cambia.
      Text(
        cantidad == 1 ? '1 lote en el periodo' : '$cantidad lotes en el periodo',
        style: context.apagado(),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// FILTROS
// ═══════════════════════════════════════════════════════════════════════════

class _BarraFiltros extends StatelessWidget {
  const _BarraFiltros({
    required this.aire,
    required this.estado,
    required this.vista,
    required this.buscarCtrl,
    required this.onBuscar,
    required this.onMaquina,
    required this.onRango,
    required this.onVista,
  });

  final Aire aire;
  final VerLotesState estado;
  final VistaLotes vista;
  final TextEditingController buscarCtrl;
  final ValueChanged<String> onBuscar;
  final ValueChanged<int?> onMaquina;
  final VoidCallback onRango;
  final ValueChanged<VistaLotes> onVista;

  @override
  Widget build(BuildContext context) {
    final buscador = TextField(
      controller: buscarCtrl,
      onChanged: onBuscar,
      decoration: InputDecoration(
        hintText: 'Numero de lote, orden de fabricacion u observacion',
        prefixIcon: const Icon(Icons.search, size: 20),
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: buscarCtrl.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  buscarCtrl.clear();
                  onBuscar('');
                },
              ),
      ),
    );

    final maquinas = DropdownButtonFormField<int?>(
      value: estado.idMaquina,
      decoration: const InputDecoration(
        labelText: 'Maquina',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
        for (final m in estado.maquinas)
          DropdownMenuItem<int?>(value: m.idMa, child: Text(m.descripcion)),
      ],
      onChanged: onMaquina,
    );

    // El periodo va primero y con su propio boton porque no es como los otros
    // dos filtros: los demas recortan lo que ya esta en pantalla, este decide
    // que se le pide a la base.
    final periodo = OutlinedButton.icon(
      onPressed: onRango,
      icon: const Icon(Icons.date_range_outlined, size: 18),
      label: Text(
        '${fechaCorta(estado.desde)} a ${fechaCorta(estado.hasta)}',
        style: context.numero(fuerte: true),
      ),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.m),
      ),
    );

    // Los rotulos salen solo con `amplio`: entre 600 y 1000 px los dos
    // segmentos rotulados empujan el buscador hasta dejarlo inservible, y el
    // icono con su tooltip dice lo mismo.
    final conmutador = SegmentedButton<VistaLotes>(
      segments: [
        for (final v in VistaLotes.values)
          ButtonSegment(
            value: v,
            icon: Icon(v.icono, size: 18),
            label: aire == Aire.amplio ? Text(v.rotulo) : null,
            tooltip: v == VistaLotes.completa
                ? 'Todas las columnas del sistema anterior'
                : 'Solo lo esencial de cada lote',
          ),
      ],
      selected: {vista},
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onSelectionChanged: (s) => onVista(s.first),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        aire.esChico ? Esp.m : Esp.xl,
        0,
        aire.esChico ? Esp.m : Esp.xl,
        Esp.m,
      ),
      child: aire.esChico
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                periodo,
                SizedBox(height: Esp.s),
                buscador,
                SizedBox(height: Esp.s),
                maquinas,
                SizedBox(height: Esp.s),
                Align(alignment: Alignment.centerLeft, child: conmutador),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    periodo,
                    SizedBox(width: Esp.m),
                    Expanded(flex: 3, child: buscador),
                    SizedBox(width: Esp.m),
                    Expanded(child: maquinas),
                    // Debajo de los 1000 px el conmutador va en su propio
                    // renglon: sumado al periodo dejaba el combo de maquina en
                    // sesenta pixeles.
                    if (aire == Aire.amplio) ...[
                      SizedBox(width: Esp.m),
                      conmutador,
                    ],
                  ],
                ),
                if (aire != Aire.amplio) ...[
                  SizedBox(height: Esp.s),
                  conmutador,
                ],
              ],
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LISTADO
// ═══════════════════════════════════════════════════════════════════════════

class _Listado extends StatelessWidget {
  const _Listado({
    required this.aire,
    required this.estado,
    required this.vista,
    required this.puedeReabrir,
    required this.onAbrir,
    required this.onReporte,
    required this.onLimpiar,
    required this.onRango,
  });

  final Aire aire;
  final VerLotesState estado;
  final VistaLotes vista;
  final bool puedeReabrir;
  final void Function(LoteProduccionEntity) onAbrir;
  final void Function(LoteProduccionEntity) onReporte;
  final VoidCallback onLimpiar;
  final VoidCallback onRango;

  @override
  Widget build(BuildContext context) {
    if (estado.cargando && estado.lotes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final lotes = estado.visibles;

    if (lotes.isEmpty) {
      // Se distinguen los dos vacios: no hay lotes en el periodo, o los hay
      // pero ninguno pasa el buscador. Cada uno se resuelve en otro lado.
      final hayFiltro =
          estado.busqueda.trim().isNotEmpty || estado.idMaquina != null;
      final periodo =
          '${fechaCorta(estado.desde)} a ${fechaCorta(estado.hasta)}';

      return Column(
        children: [
          Expanded(
            child: MensajeVacio(
              icono: hayFiltro
                  ? Icons.filter_alt_off
                  : Icons.event_busy_outlined,
              titulo: hayFiltro
                  ? 'Ningun lote coincide con el filtro'
                  : 'No hay lotes cortados en este periodo',
              detalle: hayFiltro
                  ? 'Hay lotes en el periodo $periodo, pero ninguno coincide '
                        'con lo que busca. Pruebe con otro numero de lote o '
                        'quite el filtro de maquina.'
                  : 'El periodo consultado es $periodo. Amplielo para ver '
                        'lotes de meses anteriores.',
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: Esp.xxl),
            child: TextButton.icon(
              onPressed: hayFiltro ? onLimpiar : onRango,
              icon: Icon(
                hayFiltro ? Icons.filter_alt_off : Icons.date_range_outlined,
                size: 18,
              ),
              label: Text(hayFiltro ? 'Quitar filtros' : 'Cambiar periodo'),
            ),
          ),
        ],
      );
    }

    final padding = EdgeInsets.symmetric(
      horizontal: aire.esChico ? Esp.m : Esp.xl,
    );

    if (aire == Aire.amplio) {
      return TablaLotes(
        padding: padding,
        lotes: lotes,
        vista: vista,
        puedeReabrir: puedeReabrir,
        onAbrir: onAbrir,
        onReporte: onReporte,
      );
    }

    return ListView.separated(
      padding: padding.copyWith(top: Esp.xs, bottom: Esp.xxl),
      itemCount: lotes.length,
      separatorBuilder: (_, _) => SizedBox(height: Esp.s),
      itemBuilder: (context, i) => _Tarjeta(
        lote: lotes[i],
        vista: vista,
        puedeReabrir: puedeReabrir,
        onAbrir: () => onAbrir(lotes[i]),
        onReporte: () => onReporte(lotes[i]),
      ),
    );
  }
}

/// El mismo lote cuando no entra una tabla.
///
/// En vista completa la tarjeta trae los mismos numeros que la planilla: en un
/// telefono no hay forma de mostrar veintidos columnas, pero si de mostrar los
/// veintidos datos.
class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.lote,
    required this.vista,
    required this.puedeReabrir,
    required this.onAbrir,
    required this.onReporte,
  });

  final LoteProduccionEntity lote;
  final VistaLotes vista;
  final bool puedeReabrir;
  final VoidCallback onAbrir;
  final VoidCallback onReporte;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completa = vista == VistaLotes.completa;

    return Material(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(Esquina.media),
      child: InkWell(
        onTap: onAbrir,
        borderRadius: BorderRadius.circular(Esquina.media),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(Esquina.media),
          ),
          padding: EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.s, Esp.s),
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
                        Text(
                          'Lote ${lote.numLote}/${lote.anio}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: Peso.dato,
                                fontFeatures: cifrasTabulares,
                              ),
                        ),
                        Text(
                          '${fechaCorta(lote.fecha)}  ·  '
                          '${lote.estado == 1 ? "Abierto" : "Cerrado"}',
                          style: context.apagado(),
                        ),
                      ],
                    ),
                  ),
                  EtiquetaCuadre(
                    diferenciaKilos: lote.diferenciaProduccion,
                    kilosIngreso: lote.pesoKilosTotalIngreso,
                  ),
                ],
              ),
              if (completa) ...[
                SizedBox(height: Esp.s),
                _Horario(lote: lote),
              ],
              SizedBox(height: Esp.m),
              if (completa)
                Wrap(
                  spacing: Esp.l,
                  runSpacing: Esp.m,
                  children: [
                    for (final (etiqueta, valor) in _datosDelLote(lote))
                      SizedBox(
                        width: 96,
                        child: _Dato(etiqueta: etiqueta, valor: valor),
                      ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _Dato(
                        etiqueta: 'Kg ingreso',
                        valor: fmtNumero.format(lote.pesoKilosTotalIngreso),
                      ),
                    ),
                    Expanded(
                      child: _Dato(
                        etiqueta: 'Resmas',
                        valor: fmtEntero.format(lote.cantResmaSalida),
                      ),
                    ),
                    Expanded(
                      child: _Dato(
                        etiqueta: 'Merma kg',
                        valor: fmtNumero.format(lote.mermaTotal),
                      ),
                    ),
                  ],
                ),
              if (completa && lote.obs.trim().isNotEmpty) ...[
                SizedBox(height: Esp.m),
                Text(lote.obs.trim(), style: context.apagado()),
              ],
              SizedBox(height: Esp.xs),
              Align(
                alignment: Alignment.centerRight,
                child: _Acciones(
                  lote: lote,
                  puedeReabrir: puedeReabrir,
                  onAbrir: onAbrir,
                  onReporte: onReporte,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Los mismos numeros que las columnas de la planilla, en el orden en que se
/// leen: primero lo que entro, despues lo que salio y al final el cuadre.
List<(String, String)> _datosDelLote(LoteProduccionEntity lote) => [
  ('Bobinas', fmtEntero.format(lote.cantBobinasIngresoTotal)),
  ('Kg ingreso', fmtNumero.format(lote.pesoKilosTotalIngreso)),
  ('Kg salida', fmtNumero.format(lote.pesoTotalSalida)),
  ('Kg paleta', fmtNumero.format(lote.pesoPaletaSalida)),
  ('Kg material', fmtNumero.format(lote.pesoMaterialSalida)),
  ('Resmas', fmtEntero.format(lote.cantResmaSalida)),
  ('Hojas', fmtEntero.format(lote.cantHojasSalida)),
  ('Merma kg', fmtNumero.format(lote.mermaTotal)),
  ('Dif. kg', fmtNumero.format(lote.diferenciaProduccion)),
  ('Dif. resmas', fmtNumero.format(lote.diferenciaProdResma)),
  (
    'Resmas est.',
    lote.cantEstimadaResma <= 0 ? '--' : fmtNumero.format(lote.cantEstimadaResma),
  ),
  ('Kg balanza', fmtNumero.format(lote.pesoBalanzaTotal)),
  ('Orden', lote.docNumOrdFab == 0 ? '--' : lote.docNumOrdFab.toString()),
];

/// Las tres horas del lote y cuanto duro, en un renglon.
class _Horario extends StatelessWidget {
  const _Horario({required this.lote});

  final LoteProduccionEntity lote;

  @override
  Widget build(BuildContext context) {
    final inicioCorte = lote.hraInicioCorte.isEmpty
        ? '--'
        : lote.hraInicioCorte;
    final inicio = lote.hraInicio.isEmpty ? '--' : lote.hraInicio;
    final fin = lote.hraFin.isEmpty ? '--' : lote.hraFin;

    return Row(
      children: [
        Icon(
          Icons.schedule_outlined,
          size: 14,
          color: Theme.of(context).hintColor,
        ),
        SizedBox(width: Esp.xs),
        Expanded(
          child: Text(
            'Corte $inicioCorte  ·  $inicio a $fin  ·  '
            '${duracionCorte(lote.hraInicio, lote.hraFin)}',
            style: context.apagado(),
          ),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        etiqueta,
        style: context.apagado(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(valor, style: context.numero(fuerte: true)),
    ],
  );
}

/// Abrir y generar el PDF del lote.
///
/// Un lote cerrado se abre igual, pero en solo lectura: ver lo que se corto no
/// necesita permiso; corregirlo si.
class _Acciones extends StatelessWidget {
  const _Acciones({
    required this.lote,
    required this.puedeReabrir,
    required this.onAbrir,
    required this.onReporte,
  });

  final LoteProduccionEntity lote;
  final bool puedeReabrir;
  final VoidCallback onAbrir;
  final VoidCallback onReporte;

  @override
  Widget build(BuildContext context) {
    final editable = lote.estado == 1 || puedeReabrir;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          tooltip: 'Generar PDF del lote',
          visualDensity: VisualDensity.compact,
          onPressed: onReporte,
        ),
        TextButton.icon(
          onPressed: onAbrir,
          icon: Icon(
            editable ? Icons.edit_outlined : Icons.visibility_outlined,
            size: 18,
          ),
          label: Text(editable ? 'Abrir' : 'Ver'),
        ),
      ],
    );
  }
}
