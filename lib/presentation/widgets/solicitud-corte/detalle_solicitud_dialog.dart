/// El detalle de una solicitud de corte: que se pidio y en que quedo en SAP.
///
/// Es de solo lectura. Una solicitud registrada no se edita: se cancela con su
/// motivo y se hace otra. Es la regla del sistema anterior y tiene sentido —el
/// numero de solicitud es el que viaja a planta y a SAP.
library;

import 'package:bosque_flutter/core/state/solicitud_corte_provider.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/ccr_solicitud_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/ccr_solicitud_entity.dart';
import 'package:bosque_flutter/presentation/widgets/lote-produccion/balance_lote.dart';
import 'package:bosque_flutter/presentation/widgets/solicitud-corte/diagrama_corte.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Traduce el estado de SAP a un tono. 'Abierto' es lo normal mientras se
/// trabaja; sin dato es que SAP todavia no la tomo.
TonoEtiqueta tonoSap(String estado) => switch (estado.toLowerCase()) {
  'abierto' => TonoEtiqueta.exito,
  'cerrado' || 'terminado' => TonoEtiqueta.neutro,
  'cancelado' => TonoEtiqueta.error,
  _ => TonoEtiqueta.aviso,
};

Future<void> abrirDetalleSolicitud(
  BuildContext context, {
  required CcrSolicitudEntity solicitud,
  required Future<void> Function() onImprimir,
  required VoidCallback? onCancelar,
}) => showDialog<void>(
  context: context,
  builder: (_) => DetalleSolicitudDialog(
    solicitud: solicitud,
    onImprimir: onImprimir,
    onCancelar: onCancelar,
  ),
);

class DetalleSolicitudDialog extends ConsumerWidget {
  const DetalleSolicitudDialog({
    super.key,
    required this.solicitud,
    required this.onImprimir,
    required this.onCancelar,
  });

  final CcrSolicitudEntity solicitud;
  final Future<void> Function() onImprimir;
  final VoidCallback? onCancelar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final detalle = ref.watch(
      detalleSolicitudCorteProvider(solicitud.idSolicitud),
    );

    return LayoutBuilder(
      builder: (context, restricciones) {
        final aire = Aire.de(restricciones.maxWidth);

        return Dialog(
          insetPadding: EdgeInsets.all(aire.esChico ? Esp.s : Esp.xxl),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Cabecera(solicitud: solicitud),

                Flexible(
                  child: ListView(
                    padding: EdgeInsets.all(aire.esChico ? Esp.m : Esp.xl),
                    children: [
                      _Resumen(solicitud: solicitud, aire: aire),
                      if (solicitud.observacion.isNotEmpty) ...[
                        SizedBox(height: Esp.m),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(Esp.m),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(Esquina.chica),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                solicitud.estaCancelada
                                    ? 'Motivo de la cancelacion'
                                    : 'Observacion',
                                style: context.apagado(),
                              ),
                              SizedBox(height: Esp.xs),
                              Text(solicitud.observacion),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: Esp.xl),
                      Text('Items a cortar', style: context.tituloSeccion()),
                      SizedBox(height: Esp.m),

                      detalle.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, _) => Text(
                          'No se pudo cargar el detalle de la solicitud.',
                          style: context.apagado(),
                        ),
                        data: (items) => items.isEmpty
                            ? Text(
                                'Esta solicitud no tiene items cargados.',
                                style: context.apagado(),
                              )
                            : Column(
                                children: [
                                  for (final i in items)
                                    _ItemSolicitado(item: i),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Esp.l),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    border: Border(top: BorderSide(color: cs.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      if (onCancelar != null)
                        TextButton.icon(
                          onPressed: onCancelar,
                          icon: const Icon(Icons.block, size: 18),
                          label: const Text('Cancelar solicitud'),
                          style: TextButton.styleFrom(
                            foregroundColor: cs.error,
                          ),
                        ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: onImprimir,
                        icon: const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 18,
                        ),
                        label: const Text('Boleta PDF'),
                      ),
                      SizedBox(width: Esp.s),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.solicitud});

  final CcrSolicitudEntity solicitud;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(Esp.xl, Esp.l, Esp.m, Esp.l),
      color: cs.surfaceContainerHigh,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Solicitud de corte', style: context.apagado()),
                SizedBox(height: Esp.xs),
                Row(
                  children: [
                    Text(
                      'Nro ${solicitud.datoNroSolicitud}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: Peso.dato,
                            fontFeatures: cifrasTabulares,
                          ),
                    ),
                    SizedBox(width: Esp.m),
                    Etiqueta(
                      texto: solicitud.datoEstado.isEmpty
                          ? solicitud.estado
                          : solicitud.datoEstado,
                      tono: solicitud.estaCancelada
                          ? TonoEtiqueta.error
                          : TonoEtiqueta.exito,
                    ),
                    SizedBox(width: Esp.s),
                    Etiqueta(
                      texto: solicitud.datoTipoSolicitud.isEmpty
                          ? solicitud.tipoSolicitud
                          : solicitud.datoTipoSolicitud,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cerrar',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.solicitud, required this.aire});

  final CcrSolicitudEntity solicitud;
  final Aire aire;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final datos = <(String, String)>[
      ('Fecha', fechaCorta(solicitud.fechaSolicitud)),
      ('Solicitante', solicitud.datoSolicitante),
      ('Empresa', solicitud.datoEmpresa),
      ('Total pedido', '${fmtNumero.format(solicitud.totalToneladas)} kg'),
    ];

    return Container(
      padding: EdgeInsets.all(Esp.l),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: Wrap(
        spacing: Esp.xxl,
        runSpacing: Esp.m,
        children: [
          for (final (etiqueta, valor) in datos)
            SizedBox(
              width: aire.esChico ? 140 : 175,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiqueta, style: context.apagado()),
                  Text(
                    valor.isEmpty ? '--' : valor,
                    style: context.numero(fuerte: true),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Un item pedido, con lo que devolvio SAP si ya lo tomo.
class _ItemSolicitado extends StatelessWidget {
  const _ItemSolicitado({required this.item});

  final CcrSolicitudDetalleEntity item;

  /// El formato de salida efectivo: los campos Esp cuando estan cargados, los
  /// del articulo de salida cuando no (las STD historicas).
  double get anchoCorte =>
      item.anchoSalidaEsp > 0 ? item.anchoSalidaEsp : item.anchoSAPSalida;
  double get largoCorte =>
      item.largoSalidaEsp > 0 ? item.largoSalidaEsp : item.largoSAPSalida;
  double get hojasPorResma => item.cantHojasSalidaEsp > 0
      ? item.cantHojasSalidaEsp.toDouble()
      : item.cantHojasSAPSalida;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tieneSap = item.sapDocNum > 0;

    return Container(
      margin: EdgeInsets.only(bottom: Esp.s),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(Esp.m),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DiagramaCorte.deItem(
                  anchoBase: item.anchoSAPBase,
                  largoBase: item.largoSAPBase,
                  anchoSalidaEsp: item.anchoSalidaEsp,
                  largoSalidaEsp: item.largoSalidaEsp,
                  anchoSAPSalida: item.anchoSAPSalida,
                  largoSAPSalida: item.largoSAPSalida,
                  compacto: true,
                ),
                SizedBox(width: Esp.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.codigoSAPBase,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: Peso.dato,
                          fontFeatures: cifrasTabulares,
                        ),
                      ),
                      Text(item.datoSAPBase, style: context.apagado()),
                      SizedBox(height: Esp.s),
                      Wrap(
                        spacing: Esp.l,
                        runSpacing: Esp.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Las solicitudes STD historicas no usan los campos
                          // Esp: para esas el formato es el del articulo de
                          // salida y no hay nro. de cortes que mostrar.
                          _Par(
                            'Corte',
                            '${fmtNumero.format(anchoCorte)} × '
                                '${fmtNumero.format(largoCorte)} cm',
                          ),
                          if (item.nroCortes > 0)
                            _Par('Cortes', fmtEntero.format(item.nroCortes)),
                          if (hojasPorResma > 0)
                            _Par(
                              'Hojas/resma',
                              fmtEntero.format(hojasPorResma),
                            ),
                          _Par(
                            'Kilos',
                            fmtNumero.format(item.cantToneladasSolicitados),
                          ),
                          _Par(
                            'Paquetes',
                            fmtNumero.format(item.cantPaquetesSolicitados),
                          ),
                          EtiquetaEntrega(
                            entrega: item.fechaEntrega,
                            texto: item.datoFechaEntregaStr,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lo que devolvio SAP. Sin orden todavia, se dice explicitamente en
          // vez de dejar la fila muda.
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: Esp.m,
              vertical: Esp.s,
            ),
            color: cs.surfaceContainerLow,
            child: tieneSap
                ? Wrap(
                    spacing: Esp.l,
                    runSpacing: Esp.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Etiqueta(
                        texto: item.sapEstado.isEmpty
                            ? 'En SAP'
                            : item.sapEstado,
                        tono: tonoSap(item.sapEstado),
                      ),
                      _Par('NR', item.sapDocNum.toString()),
                      if (item.datoFecInicioStr.isNotEmpty)
                        _Par('Inicio', item.datoFecInicioStr),
                      if (item.datoFecCierreStr.isNotEmpty)
                        _Par('Cierre', item.datoFecCierreStr),
                      if (item.sapPlannedQty > 0)
                        _Par(
                          'Planificado',
                          fmtNumero.format(item.sapPlannedQty),
                        ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Theme.of(context).hintColor,
                      ),
                      SizedBox(width: Esp.s),
                      Text(
                        'SAP todavia no genero la orden de fabricacion',
                        style: context.apagado(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Par extends StatelessWidget {
  const _Par(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$etiqueta ', style: context.apagado()),
      Text(valor, style: context.numero(fuerte: true)),
    ],
  );
}
