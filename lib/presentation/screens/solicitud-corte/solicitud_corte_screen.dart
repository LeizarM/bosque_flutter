/// Solicitud de corte: los pedidos de servicio de corte y su estado en SAP.
///
/// Reemplaza a `tccrControlCorteResmado/solicitudCorte.xhtml`. Lo que cambia
/// respecto de la pantalla anterior:
///
/// - **Listado con filtros en lugar de navegacion registro por registro.** El
///   menu Primero / Anterior / Siguiente / Ultimo obligaba a recorrer las
///   solicitudes de a una para encontrar cualquier cosa.
/// - **El periodo lo recorta el SP.** Por defecto el anio en curso: se generan
///   pocas solicitudes y con un mes la pantalla abriria casi siempre vacia.
/// - **Solo se crean solicitudes ESPECIALES.** El "Serv. Corte Estandar" esta
///   comentado en el sistema anterior desde 2025. Las STD historicas se listan
///   y se consultan igual.
library;

import 'package:bosque_flutter/core/state/button_permissions_provider.dart';
import 'package:bosque_flutter/core/state/solicitud_corte_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/descargar_reportes_jasper.dart';
import 'package:bosque_flutter/domain/entities/ccr_solicitud_entity.dart';
import 'package:bosque_flutter/presentation/screens/lote-produccion/ver_lote_produccion_screen.dart'
    show fechaArchivo;
import 'package:bosque_flutter/presentation/widgets/lote-produccion/balance_lote.dart';
import 'package:bosque_flutter/presentation/widgets/lote-produccion/rango_fechas_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/solicitud-corte/detalle_solicitud_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/solicitud-corte/nueva_solicitud_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/solicitud-corte/resumen_periodo_corte.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Permiso para dar de alta una solicitud. Es el mismo nombre que usaba el
/// sistema anterior, asi que no hay que dar de alta un permiso nuevo.
const _btnNueva = 'btnCcrNw';

class SolicitudCorteScreen extends ConsumerStatefulWidget {
  const SolicitudCorteScreen({super.key});

  @override
  ConsumerState<SolicitudCorteScreen> createState() =>
      _SolicitudCorteScreenState();
}

class _SolicitudCorteScreenState extends ConsumerState<SolicitudCorteScreen> {
  final _buscarCtrl = TextEditingController();

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  // ── Acciones ──────────────────────────────────────────────────────────────

  Future<void> _nueva() async {
    final creada = await abrirNuevaSolicitud(context);
    if (creada && mounted) {
      await ref.read(solicitudesCorteProvider.notifier).cargar();
    }
  }

  Future<void> _imprimir(CcrSolicitudEntity s) => mostrarReportePdf(
    context: context,
    downloadFunction: () => ref
        .read(solicitudCorteRepositoryProvider)
        .reporteSolicitudPdf(s.idSolicitud),
    filename: 'solicitud_corte_${s.tipoSolicitud}_${s.datoNroSolicitud}.pdf',
  );

  Future<void> _abrir(CcrSolicitudEntity s) => abrirDetalleSolicitud(
    context,
    solicitud: s,
    onImprimir: () => _imprimir(s),
    onCancelar: s.sePuedeCancelar ? () => _cancelar(s) : null,
  );

  Future<void> _cancelar(CcrSolicitudEntity s) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => _MotivoCancelacionDialog(numero: s.datoNroSolicitud),
    );
    if (motivo == null || !mounted) return;

    try {
      await ref
          .read(solicitudCorteRepositoryProvider)
          .cancelarSolicitud(
            idSolicitud: s.idSolicitud,
            motivo: motivo,
            audUsuario: ref.read(userProvider)?.codUsuario ?? 0,
          );
      if (!mounted) return;
      avisar(context, 'Solicitud ${s.datoNroSolicitud} cancelada.');
      // Se cierra el detalle, que quedo mostrando el estado viejo.
      Navigator.of(context).popUntil((r) => r.isFirst);
      await ref.read(solicitudesCorteProvider.notifier).cargar();
    } catch (e) {
      if (!mounted) return;
      avisar(context, e.toString(), esError: true);
    }
  }

  Future<void> _cambiarRango() async {
    final actual = ref.read(solicitudesCorteProvider);
    final rango = await pedirRangoDeFechas(
      context,
      titulo: 'Periodo a consultar',
      explicacion:
          'Se traen de la base solo las solicitudes emitidas en estas fechas.',
      desde: actual.desde,
      hasta: actual.hasta,
      textoAceptar: 'Aplicar',
      iconoAceptar: Icons.filter_alt_outlined,
    );
    if (rango == null || !mounted) return;
    await ref
        .read(solicitudesCorteProvider.notifier)
        .setRango(rango.desde, rango.hasta);
  }

  Future<void> _reporteResumen() async {
    final actual = ref.read(solicitudesCorteProvider);
    final rango = await pedirRangoDeFechas(
      context,
      titulo: 'Resumen de solicitudes',
      explicacion: 'Consolidado de lo pedido en el periodo.',
      desde: actual.desde,
      hasta: actual.hasta,
    );
    if (rango == null || !mounted) return;

    await mostrarReportePdf(
      context: context,
      downloadFunction: () => ref
          .read(solicitudCorteRepositoryProvider)
          .reporteResumenPdf(rango.desde, rango.hasta),
      filename:
          'resumen_solicitudes_corte_${fechaArchivo(rango.desde)}_'
          '${fechaArchivo(rango.hasta)}.pdf',
    );
  }

  // ── Dibujo ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(solicitudesCorteProvider);
    final notifier = ref.read(solicitudesCorteProvider.notifier);

    final puedeCrear = ref
        .watch(buttonPermissionsProvider)
        .maybeWhen(
          data: (_) => ref
              .read(buttonPermissionsProvider.notifier)
              .tienePermiso(_btnNueva),
          orElse: () => false,
        );

    ref.listen(solicitudesCorteProvider.select((e) => e.error), (_, error) {
      if (error != null && mounted) avisar(context, error, esError: true);
    });

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, restricciones) {
          final aire = Aire.de(restricciones.maxWidth);
          final margen = aire.esChico ? Esp.m : Esp.xl;

          return Column(
            children: [
              _Cabecera(
                aire: aire,
                cantidad: estado.visibles.length,
                puedeCrear: puedeCrear,
                onNueva: _nueva,
                onReporte: _reporteResumen,
                onRecargar: notifier.cargar,
              ),
              _BarraFiltros(
                aire: aire,
                estado: estado,
                buscarCtrl: _buscarCtrl,
                onBuscar: notifier.setBusqueda,
                onEstado: notifier.setEstado,
                onRango: _cambiarRango,
              ),
              if (estado.solicitudes.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(margen, 0, margen, Esp.m),
                  child: ResumenPeriodoCorte(
                    solicitudes: estado.solicitudes,
                    desde: estado.desde,
                    hasta: estado.hasta,
                    aire: aire,
                  ),
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
                  onAbrir: _abrir,
                  onImprimir: _imprimir,
                  onRango: _cambiarRango,
                  onLimpiar: () {
                    _buscarCtrl.clear();
                    notifier.setBusqueda('');
                    notifier.setEstado(null);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton:
          puedeCrear && Aire.de(MediaQuery.of(context).size.width).esChico
          ? FloatingActionButton.extended(
              onPressed: _nueva,
              icon: const Icon(Icons.add),
              label: const Text('Nueva'),
            )
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CABECERA
// ═══════════════════════════════════════════════════════════════════════════

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.aire,
    required this.cantidad,
    required this.puedeCrear,
    required this.onNueva,
    required this.onReporte,
    required this.onRecargar,
  });

  final Aire aire;
  final int cantidad;
  final bool puedeCrear;
  final VoidCallback onNueva;
  final VoidCallback onReporte;
  final VoidCallback onRecargar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Solicitudes de corte',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: Peso.titulo),
        ),
        SizedBox(height: Esp.xs),
        Text(
          cantidad == 1
              ? '1 solicitud en el periodo'
              : '$cantidad solicitudes en el periodo',
          style: context.apagado(),
        ),
      ],
    );

    final acciones = <Widget>[
      OutlinedButton.icon(
        onPressed: onReporte,
        icon: const Icon(Icons.summarize_outlined, size: 18),
        label: const Text('Reporte resumen'),
      ),
      if (puedeCrear && !aire.esChico)
        FilledButton.icon(
          onPressed: onNueva,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nueva solicitud'),
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
                titulo,
                SizedBox(height: Esp.m),
                Wrap(spacing: Esp.s, runSpacing: Esp.s, children: acciones),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titulo),
                Wrap(spacing: Esp.s, runSpacing: Esp.s, children: acciones),
              ],
            ),
    );
  }
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
    required this.onEstado,
    required this.onRango,
  });

  final Aire aire;
  final SolicitudesCorteState estado;
  final TextEditingController buscarCtrl;
  final ValueChanged<String> onBuscar;
  final ValueChanged<String?> onEstado;
  final VoidCallback onRango;

  @override
  Widget build(BuildContext context) {
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

    final buscador = TextField(
      controller: buscarCtrl,
      onChanged: onBuscar,
      decoration: InputDecoration(
        hintText: 'Numero, solicitante u observacion',
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

    final estados = DropdownButtonFormField<String?>(
      value: estado.estado,
      decoration: const InputDecoration(
        labelText: 'Estado',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem<String?>(value: null, child: Text('Todos')),
        DropdownMenuItem<String?>(value: 'SOL', child: Text('Vigentes')),
        DropdownMenuItem<String?>(value: 'CNC', child: Text('Canceladas')),
      ],
      onChanged: onEstado,
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
                estados,
              ],
            )
          : Row(
              children: [
                periodo,
                SizedBox(width: Esp.m),
                Expanded(flex: 3, child: buscador),
                SizedBox(width: Esp.m),
                Expanded(child: estados),
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
    required this.onAbrir,
    required this.onImprimir,
    required this.onRango,
    required this.onLimpiar,
  });

  final Aire aire;
  final SolicitudesCorteState estado;
  final void Function(CcrSolicitudEntity) onAbrir;
  final void Function(CcrSolicitudEntity) onImprimir;
  final VoidCallback onRango;
  final VoidCallback onLimpiar;

  @override
  Widget build(BuildContext context) {
    if (estado.cargando && estado.solicitudes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final lista = estado.visibles;

    if (lista.isEmpty) {
      final hayFiltro =
          estado.busqueda.trim().isNotEmpty || estado.estado != null;
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
                  ? 'Ninguna solicitud coincide con el filtro'
                  : 'No hay solicitudes en este periodo',
              detalle: hayFiltro
                  ? 'Pruebe con otro numero o quite el filtro de estado.'
                  : 'El periodo consultado es $periodo. Amplielo para ver '
                        'solicitudes de anios anteriores.',
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
        lista: lista,
        onAbrir: onAbrir,
        onImprimir: onImprimir,
      );
    }

    return ListView.separated(
      padding: padding.copyWith(top: Esp.xs, bottom: Esp.xxl + Esp.xxl),
      itemCount: lista.length,
      separatorBuilder: (_, _) => SizedBox(height: Esp.s),
      itemBuilder: (context, i) => _Tarjeta(
        s: lista[i],
        onAbrir: () => onAbrir(lista[i]),
        onImprimir: () => onImprimir(lista[i]),
      ),
    );
  }
}

class _Tabla extends StatelessWidget {
  const _Tabla({
    required this.padding,
    required this.lista,
    required this.onAbrir,
    required this.onImprimir,
  });

  final EdgeInsets padding;
  final List<CcrSolicitudEntity> lista;
  final void Function(CcrSolicitudEntity) onAbrir;
  final void Function(CcrSolicitudEntity) onImprimir;

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
        child: ScrollConfiguration(
          behavior: const ArrastreLateral(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 940),
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
                  DataColumn(label: Text('NRO')),
                  DataColumn(label: Text('FECHA')),
                  DataColumn(label: Text('TIPO')),
                  DataColumn(label: Text('ESTADO')),
                  DataColumn(label: Text('KILOS'), numeric: true),
                  DataColumn(label: Text('SOLICITANTE')),
                  DataColumn(label: Text('')),
                ],
                rows: [
                  for (final s in lista)
                    DataRow(
                      onSelectChanged: (_) => onAbrir(s),
                      cells: [
                        DataCell(
                          Text(
                            s.datoNroSolicitud.isEmpty
                                ? s.numeracion.toString()
                                : s.datoNroSolicitud,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: Peso.dato,
                                  fontFeatures: cifrasTabulares,
                                ),
                          ),
                        ),
                        DataCell(
                          Text(
                            fechaCorta(s.fechaSolicitud),
                            style: context.numero(),
                          ),
                        ),
                        DataCell(
                          Text(
                            s.datoTipoSolicitud.isEmpty
                                ? s.tipoSolicitud
                                : s.datoTipoSolicitud,
                            style: context.apagado(),
                          ),
                        ),
                        DataCell(
                          Etiqueta(
                            texto: s.datoEstado.isEmpty
                                ? s.estado
                                : s.datoEstado,
                            tono: s.estaCancelada
                                ? TonoEtiqueta.error
                                : TonoEtiqueta.exito,
                          ),
                        ),
                        DataCell(
                          Text(
                            fmtNumero.format(s.totalToneladas),
                            style: context.numero(fuerte: true),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 190),
                            child: Text(
                              s.datoSolicitante,
                              overflow: TextOverflow.ellipsis,
                              style: context.apagado(),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.picture_as_pdf_outlined,
                                  size: 18,
                                ),
                                tooltip: 'Boleta PDF',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => onImprimir(s),
                              ),
                              TextButton.icon(
                                onPressed: () => onAbrir(s),
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                ),
                                label: const Text('Ver'),
                              ),
                            ],
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

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.s,
    required this.onAbrir,
    required this.onImprimir,
  });

  final CcrSolicitudEntity s;
  final VoidCallback onAbrir;
  final VoidCallback onImprimir;

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
                          'Nro ${s.datoNroSolicitud}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: Peso.dato,
                                fontFeatures: cifrasTabulares,
                              ),
                        ),
                        Text(
                          '${fechaCorta(s.fechaSolicitud)}  ·  '
                          '${s.datoTipoSolicitud.isEmpty ? s.tipoSolicitud : s.datoTipoSolicitud}',
                          style: context.apagado(),
                        ),
                      ],
                    ),
                  ),
                  Etiqueta(
                    texto: s.datoEstado.isEmpty ? s.estado : s.datoEstado,
                    tono: s.estaCancelada
                        ? TonoEtiqueta.error
                        : TonoEtiqueta.exito,
                  ),
                ],
              ),
              SizedBox(height: Esp.m),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kilos', style: context.apagado()),
                        Text(
                          fmtNumero.format(s.totalToneladas),
                          style: context.numero(fuerte: true),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Solicitante', style: context.apagado()),
                        Text(
                          s.datoSolicitante,
                          style: context.numero(fuerte: true),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 18,
                    ),
                    tooltip: 'Boleta PDF',
                    onPressed: onImprimir,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CANCELACION
// ═══════════════════════════════════════════════════════════════════════════

/// Pide el motivo de la cancelacion.
///
/// El minimo de 16 caracteres viene del sistema anterior y vale la pena
/// conservarlo: cancelar consume un numero de solicitud para siempre, y "error"
/// no le explica nada a quien lo lea dentro de seis meses.
class _MotivoCancelacionDialog extends StatefulWidget {
  const _MotivoCancelacionDialog({required this.numero});

  final String numero;

  @override
  State<_MotivoCancelacionDialog> createState() =>
      _MotivoCancelacionDialogState();
}

class _MotivoCancelacionDialogState extends State<_MotivoCancelacionDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final largo = _ctrl.text.trim().length;
    final alcanza = largo > 15;

    return AlertDialog(
      icon: const Icon(Icons.block, size: 36),
      title: Text('Cancelar la solicitud ${widget.numero}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La solicitud queda cancelada y su numero no se reutiliza. '
              'Explique por que, para que se entienda mas adelante.',
              style: context.apagado(),
            ),
            SizedBox(height: Esp.l),
            TextField(
              controller: _ctrl,
              maxLines: 3,
              maxLength: 250,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Motivo',
                border: const OutlineInputBorder(),
                helperText: alcanza
                    ? null
                    : 'Faltan ${16 - largo} caracteres',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Volver'),
        ),
        FilledButton(
          onPressed: alcanza
              ? () => Navigator.pop(context, _ctrl.text.trim())
              : null,
          child: const Text('Cancelar solicitud'),
        ),
      ],
    );
  }
}
