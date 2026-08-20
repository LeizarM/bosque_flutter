/// Ver resmado: los resmados registrados y su imputacion a SAP.
///
/// Reemplaza a `tprod_loteProduccion/ViewResmado.xhtml`. Lo que cambia respecto
/// de la grilla anterior:
///
/// - **Los que faltan imputar se pueden aislar.** El trabajo real de esta
///   pantalla es completar la orden de fabricacion de los resmados que se
///   registraron sin ella; antes habia que buscarlos a ojo entre 125 filas.
/// - **Se puede buscar** por grupo, empleado, empresa u orden.
library;

import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/state/ver_resmado_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/resmado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/lote-produccion/balance_lote.dart';
import 'package:bosque_flutter/presentation/widgets/lote-produccion/detalle_resmado_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/lote-produccion/rango_fechas_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/lote-produccion/resumen_resmado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerResmadoScreen extends ConsumerStatefulWidget {
  const VerResmadoScreen({super.key});

  @override
  ConsumerState<VerResmadoScreen> createState() => _VerResmadoScreenState();
}

class _VerResmadoScreenState extends ConsumerState<VerResmadoScreen> {
  final _buscarCtrl = TextEditingController();

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrir(ResmadoEntity resmado) => abrirDetalleResmado(
    context,
    resmado: resmado,
    audUsuario: ref.read(userProvider)?.codUsuario ?? 0,
  );

  Future<void> _cambiarRango() async {
    final actual = ref.read(verResmadosProvider);
    final rango = await pedirRangoDeFechas(
      context,
      titulo: 'Periodo a consultar',
      explicacion:
          'Se traen de la base solo los resmados registrados en estas fechas.',
      desde: actual.desde,
      hasta: actual.hasta,
      textoAceptar: 'Aplicar',
      iconoAceptar: Icons.filter_alt_outlined,
    );
    if (rango == null || !mounted) return;
    await ref
        .read(verResmadosProvider.notifier)
        .setRango(rango.desde, rango.hasta);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(verResmadosProvider);
    final notifier = ref.read(verResmadosProvider.notifier);

    ref.listen(verResmadosProvider.select((e) => e.error), (_, error) {
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
                onRecargar: notifier.cargar,
              ),
              _BarraFiltros(
                aire: aire,
                estado: estado,
                buscarCtrl: _buscarCtrl,
                onBuscar: notifier.setBusqueda,
                onSoloSinOrden: notifier.setSoloSinOrden,
                onRango: _cambiarRango,
              ),
              if (estado.resmados.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(margen, 0, margen, Esp.m),
                  child: ResumenDelPeriodo(
                    total: estado.totalResmado,
                    grupos: estado.porGrupo,
                    sinOrden: estado.sinOrden,
                    aire: aire,
                    onVerSinOrden: () => notifier.setSoloSinOrden(true),
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
                  onRango: _cambiarRango,
                  onLimpiar: () {
                    _buscarCtrl.clear();
                    notifier.setBusqueda('');
                    notifier.setSoloSinOrden(false);
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

// ═══════════════════════════════════════════════════════════════════════════
// CABECERA
// ═══════════════════════════════════════════════════════════════════════════

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.aire,
    required this.cantidad,
    required this.onRecargar,
  });

  final Aire aire;
  final int cantidad;
  final VoidCallback onRecargar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        aire.esChico ? Esp.m : Esp.xl,
        Esp.l,
        aire.esChico ? Esp.m : Esp.xl,
        Esp.m,
      ),
      color: cs.surfaceContainerLow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resmados',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: Peso.titulo,
                  ),
                ),
                SizedBox(height: Esp.xs),
                // Lo pendiente ya se cuenta en el resumen, con su atajo. Aqui
                // solo va cuantos se estan viendo.
                Text(
                  cantidad == 1
                      ? '1 resmado en el periodo'
                      : '$cantidad resmados en el periodo',
                  style: context.apagado(),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRecargar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
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
    required this.onSoloSinOrden,
    required this.onRango,
  });

  final Aire aire;
  final VerResmadosState estado;
  final TextEditingController buscarCtrl;
  final ValueChanged<String> onBuscar;
  final ValueChanged<bool> onSoloSinOrden;
  final VoidCallback onRango;

  @override
  Widget build(BuildContext context) {
    final buscador = TextField(
      controller: buscarCtrl,
      onChanged: onBuscar,
      decoration: InputDecoration(
        hintText: 'Grupo, empleado, empresa u orden de fabricacion',
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

    final filtro = FilterChip(
      selected: estado.soloSinOrden,
      onSelected: onSoloSinOrden,
      avatar: estado.soloSinOrden ? null : const Icon(Icons.pending_actions, size: 18),
      label: const Text('Solo sin orden'),
    );

    // El periodo va primero y con su propio boton: los otros dos filtros
    // recortan lo que ya esta en pantalla, este decide que se le pide a la base.
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
                Align(alignment: Alignment.centerLeft, child: filtro),
              ],
            )
          : Row(
              children: [
                periodo,
                SizedBox(width: Esp.m),
                Expanded(child: buscador),
                SizedBox(width: Esp.m),
                filtro,
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
    required this.onLimpiar,
    required this.onRango,
  });

  final Aire aire;
  final VerResmadosState estado;
  final void Function(ResmadoEntity) onAbrir;
  final VoidCallback onLimpiar;
  final VoidCallback onRango;

  @override
  Widget build(BuildContext context) {
    if (estado.cargando && estado.resmados.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final resmados = estado.visibles;

    if (resmados.isEmpty) {
      // Dos vacios distintos: no hay resmados en el periodo, o los hay pero
      // ninguno pasa el filtro. Cada uno se resuelve en otro lado.
      final hayFiltro =
          estado.busqueda.trim().isNotEmpty || estado.soloSinOrden;
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
                  ? (estado.soloSinOrden
                        ? 'Todo el periodo esta imputado'
                        : 'Ningun resmado coincide con el filtro')
                  : 'No hay resmados en este periodo',
              detalle: hayFiltro
                  ? (estado.soloSinOrden
                        ? 'Los resmados del periodo $periodo ya tienen su orden '
                              'de fabricacion. Amplie el periodo para revisar '
                              'meses anteriores.'
                        : 'Pruebe con otro grupo, empleado u orden.')
                  : 'El periodo consultado es $periodo. Amplielo para ver '
                        'resmados de meses anteriores.',
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: Esp.xxl),
            child: TextButton.icon(
              onPressed: hayFiltro && !estado.soloSinOrden
                  ? onLimpiar
                  : onRango,
              icon: Icon(
                hayFiltro && !estado.soloSinOrden
                    ? Icons.filter_alt_off
                    : Icons.date_range_outlined,
                size: 18,
              ),
              label: Text(
                hayFiltro && !estado.soloSinOrden
                    ? 'Quitar filtros'
                    : 'Cambiar periodo',
              ),
            ),
          ),
        ],
      );
    }

    final padding = EdgeInsets.symmetric(
      horizontal: aire.esChico ? Esp.m : Esp.xl,
    );

    if (aire == Aire.amplio) {
      return _Tabla(padding: padding, resmados: resmados, onAbrir: onAbrir);
    }

    return ListView.separated(
      padding: padding.copyWith(top: Esp.xs, bottom: Esp.xxl),
      itemCount: resmados.length,
      separatorBuilder: (_, _) => SizedBox(height: Esp.s),
      itemBuilder: (context, i) =>
          _Tarjeta(resmado: resmados[i], onAbrir: () => onAbrir(resmados[i])),
    );
  }
}

class _Tabla extends StatelessWidget {
  const _Tabla({
    required this.padding,
    required this.resmados,
    required this.onAbrir,
  });

  final EdgeInsets padding;
  final List<ResmadoEntity> resmados;
  final void Function(ResmadoEntity) onAbrir;

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
              constraints: const BoxConstraints(minWidth: 980),
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
                  DataColumn(label: Text('FECHA')),
                  DataColumn(label: Text('GRUPO')),
                  DataColumn(label: Text('EMPLEADO')),
                  DataColumn(label: Text('TOTAL'), numeric: true),
                  DataColumn(label: Text('HORARIO')),
                  DataColumn(label: Text('ORDEN')),
                  DataColumn(label: Text('EMPRESA')),
                  DataColumn(label: Text('')),
                ],
                rows: [
                  for (final r in resmados)
                    DataRow(
                      onSelectChanged: (_) => onAbrir(r),
                      cells: [
                        DataCell(
                          Text(fechaCorta(r.fecha), style: context.numero()),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: PuntoGrupo(
                              idGrupo: r.idGrupo,
                              nombre: r.descripcion,
                            ),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(
                              r.nombreCompleto,
                              overflow: TextOverflow.ellipsis,
                              style: context.apagado(),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            fmtNumero.format(r.total),
                            style: context.numero(fuerte: true),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${r.hraInicio.isEmpty ? "--" : r.hraInicio} a '
                            '${r.hraFin.isEmpty ? "--" : r.hraFin}',
                            style: context.numero(),
                          ),
                        ),
                        DataCell(_CeldaOrden(resmado: r)),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              r.empresa.isEmpty ? '--' : r.empresa,
                              overflow: TextOverflow.ellipsis,
                              style: context.apagado(),
                            ),
                          ),
                        ),
                        DataCell(
                          TextButton.icon(
                            onPressed: () => onAbrir(r),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Abrir'),
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

/// La orden de fabricacion, o el aviso de que falta.
///
/// Un resmado sin orden no se puede imputar: es lo que hay que completar, asi
/// que se dice con una etiqueta y no con un guion.
class _CeldaOrden extends StatelessWidget {
  const _CeldaOrden({required this.resmado});

  final ResmadoEntity resmado;

  @override
  Widget build(BuildContext context) => resmado.docNumOrdFab > 0
      ? Text(
          resmado.docNumOrdFab.toString(),
          style: context.numero(fuerte: true),
        )
      : const Etiqueta(texto: 'Falta', tono: TonoEtiqueta.aviso);
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.resmado, required this.onAbrir});

  final ResmadoEntity resmado;
  final VoidCallback onAbrir;

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
          padding: EdgeInsets.all(Esp.m),
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
                        PuntoGrupo(
                          idGrupo: resmado.idGrupo,
                          nombre: resmado.descripcion,
                        ),
                        SizedBox(height: Esp.xs),
                        Text(
                          resmado.nombreCompleto,
                          style: context.apagado(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _CeldaOrden(resmado: resmado),
                ],
              ),
              SizedBox(height: Esp.m),
              Row(
                children: [
                  _Dato(etiqueta: 'Fecha', valor: fechaCorta(resmado.fecha)),
                  _Dato(
                    etiqueta: 'Total',
                    valor: fmtNumero.format(resmado.total),
                  ),
                  _Dato(
                    etiqueta: 'Horario',
                    valor:
                        '${resmado.hraInicio.isEmpty ? "--" : resmado.hraInicio}'
                        ' a '
                        '${resmado.hraFin.isEmpty ? "--" : resmado.hraFin}',
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
        Text(
          valor,
          style: context.numero(fuerte: true),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
