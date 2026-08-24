import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/utils/formato_comision.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/nota_preliminar_entity.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/estado_vista.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

/// Criterios de orden del detalle. El SP devuelve por fecha ascendente, que
/// sirve para conciliar pero no para responder «cual pesa mas», que es lo que
/// se suele mirar en un preliminar. Por eso el que entra por defecto es monto
/// descendente.
enum OrdenNota {
  monto('Monto'),
  fecha('Fecha factura'),
  dias('Dias de cobro'),
  documento('Documento');

  const OrdenNota(this.etiqueta);
  final String etiqueta;
}

/// Desglose de una fila del preliminar: las notas que la componen.
///
/// Reemplaza al dialogo «NOTAS A PAGAR» de Comisiones.xhtml. Aquel era una
/// tabla fija de diez columnas que en un telefono no entraba; aca el escritorio
/// mantiene la tabla y el movil pasa a tarjetas, con la misma informacion.
class DialogoNotasFila extends ConsumerStatefulWidget {
  const DialogoNotasFila({
    super.key,
    required this.filtro,
    required this.nombreVendedor,
    required this.etiqueta,
    required this.periodo,
    required this.comisionVisual,
    this.tramo,
  });

  final FiltroNotaPreliminar filtro;
  final String nombreVendedor;

  /// Grupo o tipo de la fila: Contado, Credito.
  final String etiqueta;

  /// Periodo legible, mm/aaaa.
  final String periodo;

  /// Porcentaje en base 100.
  final double comisionVisual;

  /// Rango de dias del tramo, si se pudo determinar.
  final String? tramo;

  @override
  ConsumerState<DialogoNotasFila> createState() => _DialogoNotasFilaState();
}

class _DialogoNotasFilaState extends ConsumerState<DialogoNotasFila> {
  OrdenNota _orden = OrdenNota.monto;
  bool _descendente = true;

  /// Ordena solo las notas reales. El total va siempre al final: es el cierre
  /// del listado, no un elemento mas de la serie.
  List<NotaPreliminarEntity> _ordenar(List<NotaPreliminarEntity> notas) {
    final detalle = notas.where((n) => !n.esTotal).toList();
    final totales = notas.where((n) => n.esTotal).toList();

    int cmp(NotaPreliminarEntity a, NotaPreliminarEntity b) {
      switch (_orden) {
        case OrdenNota.monto:
          return a.montoCerradoBs.compareTo(b.montoCerradoBs);
        case OrdenNota.fecha:
          final fa = a.fechaDoc;
          final fb = b.fechaDoc;
          if (fa == null && fb == null) return 0;
          if (fa == null) return -1;
          if (fb == null) return 1;
          return fa.compareTo(fb);
        case OrdenNota.dias:
          return (a.diferenciaDias ?? 0).compareTo(b.diferenciaDias ?? 0);
        case OrdenNota.documento:
          return a.docNum.compareTo(b.docNum);
      }
    }

    detalle.sort((a, b) => _descendente ? cmp(b, a) : cmp(a, b));
    return [...detalle, ...totales];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final esMovil = ResponsiveUtilsBosque.isMobile(context);
    final datos = ref.watch(notasDeFilaProvider(widget.filtro));

    return Dialog(
      insetPadding: EdgeInsets.all(esMovil ? 12 : 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Encabezado(
              nombreVendedor: widget.nombreVendedor,
              etiqueta: widget.etiqueta,
              periodo: widget.periodo,
              comisionVisual: widget.comisionVisual,
              tramo: widget.tramo,
              esMovil: esMovil,
            ),
            const Divider(height: 1),
            Flexible(
              child: datos.when(
                loading:
                    () => Padding(
                      padding: const EdgeInsets.all(ComisionesTema.esp4),
                      child: EstadoVista.cargandoTabla(
                        context,
                        columnas: 4,
                        filas: 5,
                      ),
                    ),
                error:
                    (e, _) => Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          '$e',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.error),
                        ),
                      ),
                    ),
                data: (notas) {
                  final cantidad = notas.where((n) => !n.esTotal).length;
                  if (cantidad == 0) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(
                        child: Text('Esta fila no tiene notas para mostrar.'),
                      ),
                    );
                  }
                  final ordenadas = _ordenar(notas);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _BarraOrden(
                        orden: _orden,
                        descendente: _descendente,
                        cantidad: cantidad,
                        onOrden: (o) => setState(() => _orden = o),
                        onSentido:
                            () => setState(() => _descendente = !_descendente),
                      ),
                      Flexible(
                        child:
                            esMovil
                                ? _ListaTarjetas(notas: ordenadas)
                                : _TablaNotas(notas: ordenadas),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Encabezado ───────────────────────────────────────────────────────────────

class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.nombreVendedor,
    required this.etiqueta,
    required this.periodo,
    required this.comisionVisual,
    required this.tramo,
    required this.esMovil,
  });

  final String nombreVendedor;
  final String etiqueta;
  final String periodo;
  final double comisionVisual;
  final String? tramo;
  final bool esMovil;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, esMovil ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notas a pagar',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            nombreVendedor,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          // Wrap y no Row: en un telefono los cuatro datos no entran en una
          // linea y un Row los recortaria sin avisar.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChipEstado(texto: etiqueta),
              if (periodo.isNotEmpty) ChipEstado(texto: periodo),
              ChipPorcentaje(valor: comisionVisual),
              if (tramo != null) ChipEstado(texto: tramo!),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Barra de orden ───────────────────────────────────────────────────────────

class _BarraOrden extends StatelessWidget {
  const _BarraOrden({
    required this.orden,
    required this.descendente,
    required this.cantidad,
    required this.onOrden,
    required this.onSentido,
  });

  final OrdenNota orden;
  final bool descendente;
  final int cantidad;
  final ValueChanged<OrdenNota> onOrden;
  final VoidCallback onSentido;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      // Wrap para que en un telefono el contador, el desplegable y el sentido
      // bajen de linea en vez de recortarse.
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$cantidad ${cantidad == 1 ? 'nota' : 'notas'}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          DropdownButton<OrdenNota>(
            value: orden,
            underline: const SizedBox.shrink(),
            isDense: true,
            items: [
              for (final o in OrdenNota.values)
                DropdownMenuItem(
                  value: o,
                  child: Text('Ordenar por ${o.etiqueta.toLowerCase()}'),
                ),
            ],
            onChanged: (o) => o == null ? null : onOrden(o),
          ),
          // El sentido es un boton aparte y no dos opciones mas del desplegable
          // porque invertirlo es lo que mas se hace: asi es un solo click.
          TextButton.icon(
            onPressed: onSentido,
            icon: Icon(
              descendente ? Icons.arrow_downward : Icons.arrow_upward,
              size: 18,
            ),
            label: Text(descendente ? 'Mayor a menor' : 'Menor a mayor'),
          ),
        ],
      ),
    );
  }
}

// ── Escritorio: tabla ────────────────────────────────────────────────────────

class _TablaNotas extends StatelessWidget {
  const _TablaNotas({required this.notas});
  final List<NotaPreliminarEntity> notas;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: LayoutBuilder(
        // El ancho se mide FUERA del scroll horizontal: adentro maxWidth es
        // infinito y el minWidth reventaria el layout.
        builder:
            (context, limites) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: limites.maxWidth < 980 ? 980 : limites.maxWidth,
                ),
                child: DataTable(
                  headingRowColor: ComisionesTema.encabezadoTabla(context),
                  columnSpacing: ComisionesTema.separacionColumnas,
                  dataRowMinHeight: ComisionesTema.altoFila,
                  dataRowMaxHeight: ComisionesTema.altoFila,
                  headingRowHeight: ComisionesTema.altoEncabezado,
                  columns: const [
                    DataColumn(label: Text('Documento')),
                    DataColumn(label: Text('Factura')),
                    DataColumn(label: Text('Ultimo pago')),
                    DataColumn(label: Text('Dias'), numeric: true),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Tipo')),
                    DataColumn(label: Text('Sistema')),
                    DataColumn(label: Text('Monto Bs'), numeric: true),
                  ],
                  rows: [
                    for (final n in notas)
                      DataRow(
                        onLongPress: () {},
                        color: WidgetStateProperty.resolveWith((estados) {
                          if (n.esTotal) {
                            return cs.primaryContainer.withValues(alpha: 0.28);
                          }
                          // null y no transparent: transparent es un color, y
                          // gana sobre el dataRowColor del tema.
                          return null;
                        }),
                        cells: [
                          DataCell(
                            n.esTotal
                                ? const Text(
                                  'Total',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                )
                                // El número se transcribe a SAP: se copia de un
                                // clic en vez de seleccionarlo a mano.
                                : NumeroCopiable(valor: '${n.docNum}'),
                          ),
                          DataCell(Text(_fecha(n.fechaDoc))),
                          DataCell(Text(_fecha(n.fechaUltimoPago))),
                          DataCell(
                            Text(n.esTotal ? '' : '${n.diferenciaDias ?? 0}'),
                          ),
                          DataCell(Text(n.estado ?? '')),
                          DataCell(
                            n.anulada
                                ? Text(
                                  n.valido!,
                                  style: TextStyle(color: cs.error),
                                )
                                : Text(n.indicador ?? ''),
                          ),
                          DataCell(Text(n.origen ?? '')),
                          DataCell(
                            Text(
                              FormatoComision.monto.format(n.montoCerradoBs),
                              style: ComisionesTema.numeroCelda(
                                context,
                                fuerte: n.esTotal,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

// ── Movil: tarjetas ──────────────────────────────────────────────────────────

class _ListaTarjetas extends StatelessWidget {
  const _ListaTarjetas({required this.notas});
  final List<NotaPreliminarEntity> notas;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      shrinkWrap: true,
      itemCount: notas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final n = notas[i];

        if (n.esTotal) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.35),
              borderRadius: ComisionesTema.brControl,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${FormatoComision.monto.format(n.montoCerradoBs)} Bs',
                  style: ComisionesTema.numeroTotal(context),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant),
            borderRadius: ComisionesTema.brControl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${n.docNum}',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${FormatoComision.monto.format(n.montoCerradoBs)} Bs',
                    style: ComisionesTema.numeroTotal(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Factura ${_fecha(n.fechaDoc)}  ·  cobro ${_fecha(n.fechaUltimoPago)}',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ChipEstado(texto: '${n.diferenciaDias ?? 0} dias'),
                  if ((n.estado ?? '').isNotEmpty) ChipEstado(texto: n.estado!),
                  if (n.anulada)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: ComisionesTema.brChip,
                      ),
                      child: Text(
                        n.valido!,
                        style: tt.labelMedium?.copyWith(
                          color: cs.onErrorContainer,
                        ),
                      ),
                    )
                  else if ((n.indicador ?? '').isNotEmpty)
                    ChipEstado(texto: n.indicador!),
                  if ((n.origen ?? '').isNotEmpty) ChipEstado(texto: n.origen!),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

String _fecha(DateTime? f) => f == null ? '—' : FormatoComision.fecha.format(f);
