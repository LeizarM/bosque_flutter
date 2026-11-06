/// Las líneas (Q) de un empleado en la vista previa de una planilla: se
/// piden recién al abrirlas y se agrupan por reporte, con el haber con que se
/// valuó cada uno y el acceso a su detalle.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_planilla_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_previa_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_planilla_repository.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_detalle_reporte.dart';

/// Las líneas de [empleado] en la vista previa: se piden recién aquí, en el
/// panel del módulo (hoja en el teléfono, diálogo en el ancho).
Future<void> mostrarLineasPreviaHex(
  BuildContext context,
  CombinacionHex c,
  HexPrevistaEmpleadoEntity empleado,
) => mostrarPanelHex(
  context,
  panel:
      (control) => _LineasEmpleadoHex(
        combinacion: c,
        empleado: empleado,
        control: control,
      ),
);

/// Las líneas del empleado agrupadas por reporte, cada grupo con su jornada,
/// el haber con que se valuó y «Ver reporte».
class _LineasEmpleadoHex extends ConsumerWidget {
  const _LineasEmpleadoHex({
    required this.combinacion,
    required this.empleado,
    required this.control,
  });

  final CombinacionHex combinacion;
  final HexPrevistaEmpleadoEntity empleado;
  final ScrollController? control;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = combinacion;
    final e = empleado;
    final contenido = ref
        .watch(hexVistaPreviaLineasProvider(c))
        .when(
          skipLoadingOnReload: true,
          loading:
              () => const [
                SizedBox(
                  height: hexAltoEstado,
                  child: EsqueletoLista(filas: 3),
                ),
              ],
          error:
              (err, _) => [
                SizedBox(
                  height: hexAltoEstado,
                  child: vistaErrorHex(
                    err,
                    reintentar:
                        () => ref.invalidate(hexVistaPreviaLineasProvider(c)),
                  ),
                ),
              ],
          data: (todas) {
            final porReporte = <BigInt?, List<HexPrevistaLineaEntity>>{};
            // En el lote un empleado puede estar en dos combinaciones: se
            // filtra también por la empresa y la sucursal de su fila (D39).
            for (final l in todas) {
              if (l.codEmpleado == e.codEmpleado &&
                  (e.codSucursal == null || l.codSucursal == e.codSucursal) &&
                  (e.codEmpresa == null || l.codEmpresa == e.codEmpresa)) {
                porReporte.putIfAbsent(l.idReporte, () => []).add(l);
              }
            }
            if (porReporte.isEmpty) {
              return const [
                SizedBox(
                  height: hexAltoEstado,
                  child: MensajeVacio(
                    icono: Icons.inbox_outlined,
                    titulo: 'Sin líneas',
                    detalle: 'El SP no devolvió líneas para este empleado.',
                  ),
                ),
              ];
            }
            return [
              for (final lineas in porReporte.values)
                _ReporteLineasHex(lineas: lineas),
            ];
          },
        );
    return PanelHex(
      control: control,
      cabecera: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Líneas de ${oGuionHex(e.nombreEmpleado)}',
            style: context.tituloSeccion(),
          ),
          const SizedBox(height: 2),
          Text(
            'Vista previa de ${periodoHex(c.anio, c.mes)}: así se valuaría '
            'cada reporte.',
            style: context.apagado(),
          ),
        ],
      ),
      hijos: contenido,
    );
  }
}

/// Un reporte de la vista previa: jornada, inicio y fin con su origen, haber,
/// divisor y costo hora, y cada línea con su código, cantidad y monto.
class _ReporteLineasHex extends StatelessWidget {
  const _ReporteLineasHex({required this.lineas});

  final List<HexPrevistaLineaEntity> lineas;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final r = lineas.first;
    final id = r.idReporte;
    return Card(
      margin: const EdgeInsets.only(bottom: Esp.m),
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: contornoSuperficie(cs),
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: Esp.s,
              runSpacing: Esp.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Jornada ${fechaHex(r.fechaJornada)}',
                  style: t.titleSmall?.copyWith(fontWeight: Peso.titulo),
                ),
                if (r.esProvisional)
                  const Etiqueta(
                    texto: 'provisional',
                    tono: TonoEtiqueta.aviso,
                  ),
                if (r.avisoBiometrico) const EtiquetaAvisoBiometricoHex(),
                if (r.esPeriodoAnterior)
                  const Etiqueta(
                    texto: 'De período anterior',
                    tono: TonoEtiqueta.neutro,
                  ),
              ],
            ),
            const SizedBox(height: Esp.s),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: HoraOrigenHex(
                    r.inicio,
                    r.origenInicio,
                    jornada: r.fechaJornada,
                    idReporte: id,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Esp.s),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: HoraOrigenHex(
                    r.fin,
                    r.origenFin,
                    jornada: r.fechaJornada,
                    idReporte: id,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Esp.s),
            Text(
              'Haber ${bsHex(r.haberBasico)} · divisor ${decimalHex(r.divisor)} '
              '· costo hora ${bsHex(r.costoHora)}',
              style: estiloCifrasHex(context.apagado()),
            ),
            const Divider(height: Esp.l),
            for (final l in lineas) _LineaHex(l),
            if (id != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    visualDensity: VisualDensity.standard,
                  ),
                  onPressed: () => mostrarDetalleReporteHex(context, id),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Ver reporte'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Una línea: el código y su leyenda, cantidad, multiplicador y valor
/// unitario, y el monto del SP.
class _LineaHex extends StatelessWidget {
  const _LineaHex(this.l);

  final HexPrevistaLineaEntity l;

  @override
  Widget build(BuildContext context) {
    final cifras = estiloCifrasHex(context.apagado());
    final detalle = [
      numeroHex(l.cantidad),
      if (l.multiplicador != null) '×${decimalHex(l.multiplicador)}',
      '${bsHex(l.valorUnitario)} c/u',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Esp.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CodigoHex(l.codigo),
          const SizedBox(width: Esp.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  oGuionHex(l.leyenda),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(detalle, style: cifras),
              ],
            ),
          ),
          const SizedBox(width: Esp.s),
          Text(
            bsHex(l.monto),
            style: estiloCifrasHex(
              Theme.of(context).textTheme.bodyMedium,
              fuerte: true,
            ),
          ),
        ],
      ),
    );
  }
}
