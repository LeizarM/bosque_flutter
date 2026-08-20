/// Lo pedido en el periodo, mes a mes.
///
/// El periodo por defecto de esta pantalla es un anio, asi que la pregunta que
/// se contesta sola es como se reparte el pedido en el tiempo: donde se
/// concentro el corte y que meses quedaron vacios.
///
/// **Columnas y no una barra apilada** a proposito: el modulo ya usa barra
/// apilada dos veces —el balance del lote y el resmado por grupo— y una tercera
/// dejaria de leerse como informacion para leerse como decoracion. Ademas una
/// serie de tiempo tiene un eje natural, y ese eje es horizontal.
library;

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/ccr_solicitud_entity.dart';
import 'package:bosque_flutter/presentation/widgets/lote-produccion/balance_lote.dart';
import 'package:flutter/material.dart';

const _meses = [
  'E', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D',
];
const _mesesLargo = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

class _Mes {
  final int anio;
  final int mes;
  final double kilos;
  final int cantidad;

  const _Mes(this.anio, this.mes, this.kilos, this.cantidad);
}

class ResumenPeriodoCorte extends StatelessWidget {
  const ResumenPeriodoCorte({
    super.key,
    required this.solicitudes,
    required this.desde,
    required this.hasta,
    required this.aire,
  });

  final List<CcrSolicitudEntity> solicitudes;
  final DateTime desde;
  final DateTime hasta;
  final Aire aire;

  /// Un punto por cada mes del periodo, incluidos los que no tuvieron nada:
  /// un mes vacio es informacion, y saltearlo mentiria sobre el ritmo.
  List<_Mes> get _serie {
    final acumulado = <String, (double, int)>{};
    for (final s in solicitudes) {
      if (s.estaCancelada) continue;
      final k = '${s.fechaSolicitud.year}-${s.fechaSolicitud.month}';
      final previo = acumulado[k] ?? (0.0, 0);
      acumulado[k] = (previo.$1 + s.totalToneladas, previo.$2 + 1);
    }

    final serie = <_Mes>[];
    var cursor = DateTime(desde.year, desde.month);
    final fin = DateTime(hasta.year, hasta.month);
    // Tope de 24 columnas: mas alla de dos anios cada barra mide menos de un
    // pixel util y el grafico deja de decir nada.
    while (!cursor.isAfter(fin) && serie.length < 24) {
      final v = acumulado['${cursor.year}-${cursor.month}'] ?? (0.0, 0);
      serie.add(_Mes(cursor.year, cursor.month, v.$1, v.$2));
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return serie;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final serie = _serie;
    final total = solicitudes
        .where((s) => !s.estaCancelada)
        .fold(0.0, (t, s) => t + s.totalToneladas);
    final canceladas = solicitudes.where((s) => s.estaCancelada).length;
    final vigentes = solicitudes.length - canceladas;
    final tope = serie.fold(0.0, (m, e) => e.kilos > m ? e.kilos : m);

    return Container(
      padding: EdgeInsets.all(Esp.l),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: Flex(
        direction: aire.esChico ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Totales(total: total, vigentes: vigentes, canceladas: canceladas),
          SizedBox(width: aire.esChico ? 0 : Esp.xxl, height: aire.esChico ? Esp.l : 0),
          if (tope > 0)
            aire.esChico
                ? _Columnas(serie: serie, tope: tope)
                : Expanded(child: _Columnas(serie: serie, tope: tope)),
        ],
      ),
    );
  }
}

class _Totales extends StatelessWidget {
  const _Totales({
    required this.total,
    required this.vigentes,
    required this.canceladas,
  });

  final double total;
  final int vigentes;
  final int canceladas;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Pedido en el periodo', style: context.apagado()),
      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            fmtNumero.format(total),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: Peso.dato,
              fontFeatures: cifrasTabulares,
            ),
          ),
          SizedBox(width: Esp.s),
          Text('kg', style: context.apagado()),
        ],
      ),
      SizedBox(height: Esp.s),
      Wrap(
        spacing: Esp.s,
        runSpacing: Esp.xs,
        children: [
          Etiqueta(
            texto: vigentes == 1 ? '1 vigente' : '$vigentes vigentes',
            tono: TonoEtiqueta.exito,
          ),
          if (canceladas > 0)
            Etiqueta(
              texto: canceladas == 1 ? '1 cancelada' : '$canceladas canceladas',
              tono: TonoEtiqueta.error,
            ),
        ],
      ),
    ],
  );
}

/// Las columnas del periodo. La altura es proporcional a los kilos pedidos.
class _Columnas extends StatelessWidget {
  const _Columnas({required this.serie, required this.tope});

  final List<_Mes> serie;
  final double tope;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 68,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final m in serie)
                Expanded(
                  child: Tooltip(
                    message: m.cantidad == 0
                        ? '${_mesesLargo[m.mes - 1]} ${m.anio}: sin solicitudes'
                        : '${_mesesLargo[m.mes - 1]} ${m.anio}: '
                              '${fmtNumero.format(m.kilos)} kg en '
                              '${m.cantidad} solicitud'
                              '${m.cantidad == 1 ? "" : "es"}',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          // Los meses sin nada dejan una marca minima en vez de
                          // desaparecer: el hueco tambien es un dato.
                          height: m.kilos <= 0
                              ? 2
                              : (m.kilos / tope * 64).clamp(4.0, 64.0),
                          decoration: BoxDecoration(
                            color: m.kilos <= 0
                                ? cs.outlineVariant
                                : cs.primary,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: Esp.xs),
        Row(
          children: [
            for (final m in serie)
              Expanded(
                child: Text(
                  _meses[m.mes - 1],
                  textAlign: TextAlign.center,
                  style: context.apagado(),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
