/// Ver lote de produccion: los lotes ya cortados, con su cuadre a la vista.
///
/// Reemplaza a `tprod_loteProduccion/ViewLoteProduccion.xhtml`. Lo que cambia
/// respecto de la grilla anterior:
///
/// - **Cada lote dice si cuadra.** Antes eran diecisiete columnas de numeros
///   sin jerarquia; ahora la diferencia sin explicar viaja como estado.
/// - **Se puede buscar y filtrar por maquina.** Antes habia que recorrer los
///   125 registros a ojo.
/// - **El boton de abrir dice por que no esta.** Un lote cerrado solo lo reabre
///   quien tenga el permiso `btnVer`; antes el boton simplemente desaparecia.
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
import 'package:bosque_flutter/presentation/widgets/lote-produccion/rango_fechas_dialog.dart';
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
                buscarCtrl: _buscarCtrl,
                onBuscar: notifier.setBusqueda,
                onMaquina: notifier.setMaquina,
                onRango: _cambiarRango,
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
    required this.buscarCtrl,
    required this.onBuscar,
    required this.onMaquina,
    required this.onRango,
  });

  final Aire aire;
  final VerLotesState estado;
  final TextEditingController buscarCtrl;
  final ValueChanged<String> onBuscar;
  final ValueChanged<int?> onMaquina;
  final VoidCallback onRango;

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
              ],
            )
          : Row(
              children: [
                periodo,
                SizedBox(width: Esp.m),
                Expanded(flex: 3, child: buscador),
                SizedBox(width: Esp.m),
                Expanded(child: maquinas),
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
    required this.puedeReabrir,
    required this.onAbrir,
    required this.onReporte,
    required this.onLimpiar,
    required this.onRango,
  });

  final Aire aire;
  final VerLotesState estado;
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
      return _Tabla(
        padding: padding,
        lotes: lotes,
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
        puedeReabrir: puedeReabrir,
        onAbrir: () => onAbrir(lotes[i]),
        onReporte: () => onReporte(lotes[i]),
      ),
    );
  }
}

class _Tabla extends StatelessWidget {
  const _Tabla({
    required this.padding,
    required this.lotes,
    required this.puedeReabrir,
    required this.onAbrir,
    required this.onReporte,
  });

  final EdgeInsets padding;
  final List<LoteProduccionEntity> lotes;
  final bool puedeReabrir;
  final void Function(LoteProduccionEntity) onAbrir;
  final void Function(LoteProduccionEntity) onReporte;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: padding.copyWith(bottom: Esp.xl),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(Esquina.media),
        ),
        clipBehavior: Clip.antiAlias,
        // La tabla scrollea sola de costado; el cuerpo de la pagina nunca.
        child: ScrollConfiguration(
          behavior: const ArrastreLateral(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 1080),
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(
                  cs.surfaceContainerHigh,
                ),
                showCheckboxColumn: false,
                columnSpacing: Esp.xl,
                horizontalMargin: Esp.l,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 64,
                columns: const [
                  DataColumn(label: Text('LOTE')),
                  DataColumn(label: Text('FECHA')),
                  DataColumn(label: Text('BOBINAS'), numeric: true),
                  DataColumn(label: Text('KG INGRESO'), numeric: true),
                  DataColumn(label: Text('RESMAS'), numeric: true),
                  DataColumn(label: Text('MERMA KG'), numeric: true),
                  DataColumn(label: Text('CUADRE')),
                  DataColumn(label: Text('ORDEN')),
                  DataColumn(label: Text('')),
                ],
                rows: [
                  for (final lote in lotes)
                    DataRow(
                      onSelectChanged: (_) => onAbrir(lote),
                      cells: [
                        DataCell(_CeldaLote(lote: lote)),
                        DataCell(
                          Text(
                            fechaCorta(lote.fecha),
                            style: context.numero(),
                          ),
                        ),
                        DataCell(
                          Text(
                            fmtEntero.format(lote.cantBobinasIngresoTotal),
                            style: context.numero(),
                          ),
                        ),
                        DataCell(
                          Text(
                            fmtNumero.format(lote.pesoKilosTotalIngreso),
                            style: context.numero(fuerte: true),
                          ),
                        ),
                        DataCell(
                          Text(
                            fmtEntero.format(lote.cantResmaSalida),
                            style: context.numero(fuerte: true),
                          ),
                        ),
                        DataCell(
                          Text(
                            fmtNumero.format(lote.mermaTotal),
                            style: context.numero(),
                          ),
                        ),
                        DataCell(
                          EtiquetaCuadre(
                            diferenciaKilos: lote.diferenciaProduccion,
                            kilosIngreso: lote.pesoKilosTotalIngreso,
                          ),
                        ),
                        DataCell(
                          Text(
                            lote.docNumOrdFab == 0
                                ? '--'
                                : lote.docNumOrdFab.toString(),
                            style: context.numero(),
                          ),
                        ),
                        DataCell(
                          _Acciones(
                            lote: lote,
                            puedeReabrir: puedeReabrir,
                            onAbrir: () => onAbrir(lote),
                            onReporte: () => onReporte(lote),
                          ),
                        ),
                      ],
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

/// La primera celda: numero de lote y estado juntos, que es como se busca.
class _CeldaLote extends StatelessWidget {
  const _CeldaLote({required this.lote});

  final LoteProduccionEntity lote;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${lote.numLote}/${lote.anio}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: Peso.dato,
          fontFeatures: cifrasTabulares,
        ),
      ),
      Text(
        lote.estado == 1 ? 'Abierto' : 'Cerrado',
        style: context.apagado(),
      ),
    ],
  );
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
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
    final cs = Theme.of(context).colorScheme;

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
              SizedBox(height: Esp.m),
              Row(
                children: [
                  _Dato(
                    etiqueta: 'Kg ingreso',
                    valor: fmtNumero.format(lote.pesoKilosTotalIngreso),
                  ),
                  _Dato(
                    etiqueta: 'Resmas',
                    valor: fmtEntero.format(lote.cantResmaSalida),
                  ),
                  _Dato(
                    etiqueta: 'Merma kg',
                    valor: fmtNumero.format(lote.mermaTotal),
                  ),
                ],
              ),
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

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: context.apagado()),
        Text(valor, style: context.numero(fuerte: true)),
      ],
    ),
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
