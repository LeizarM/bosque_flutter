/// Dónde está un reporte: los cuatro pasos (Reportado, Visto bueno, Aprobado,
/// Pagado) con lo que falta en palabras del SP, o el aviso de rechazo o
/// anulación con su motivo.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_colores.dart';

/// Los nombres fijos de los cuatro pasos de un reporte.
const List<String> pasosReporteHex = [
  'Reportado',
  'Visto bueno',
  'Aprobado',
  'Pagado',
];

/// Cuántos pasos lleva hechos el reporte; nulo si su estado no avanza
/// (rechazado, anulado o uno que la app no conoce).
int? pasosHechosHex(String? estado) => switch (estado) {
  'REPORTADO' => 1,
  'VISTO_BUENO' => 2,
  'APROBADO' => 3,
  'LIQUIDADO' => 4,
  _ => null,
};

/// Un reporte rechazado o anulado ya no avanza: se muestra su motivo.
bool reporteCerradoHex(String? estado) =>
    estado == 'RECHAZADO' || estado == 'ANULADO';

/// El avance de [reporte]. [compacto] (tarjeta): barra de cuatro tramos y una
/// línea; si no (detalle), los pasos con su nombre. Debajo, `textoPendiente`.
class AvanceReporteHex extends StatelessWidget {
  const AvanceReporteHex(this.reporte, {super.key, this.compacto = false});

  final HexReporteEntity reporte;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final r = reporte;
    if (reporteCerradoHex(r.estado)) {
      return AvisoRechazoHex(r, compacto: compacto);
    }
    final hechos = pasosHechosHex(r.estado);
    if (hechos == null) return const SizedBox.shrink();
    final hc = HexColores.de(context);
    final completo = hechos >= pasosReporteHex.length;
    final pendiente = r.textoPendiente?.trim() ?? '';
    // Sin el texto del SP, el nombre fijo del paso que sigue.
    final linea =
        pendiente.isNotEmpty
            ? pendiente
            : completo
            ? 'Pagado'
            : 'Siguiente paso: ${pasosReporteHex[hechos]}';
    final actual = completo ? pasosReporteHex.length : hechos + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label:
              'Avance del reporte: paso $actual de ${pasosReporteHex.length}, '
              '${pasosReporteHex[actual - 1]}',
          excludeSemantics: true,
          child:
              compacto
                  ? _BarraAvanceHex(hechos: hechos)
                  : _PasosAvanceHex(hechos: hechos),
        ),
        SizedBox(height: compacto ? Esp.s : Esp.m),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              completo ? Icons.paid_outlined : Icons.hourglass_top,
              size: 16,
              color: completo ? hc.exito : hc.pendiente,
            ),
            const SizedBox(width: Esp.xs),
            Expanded(
              child: Text(
                linea,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Color de un paso: hecho en verde, el actual en ámbar, el resto apagado.
Color _colorPasoHex(BuildContext context, int indice, int hechos) {
  final hc = HexColores.de(context);
  if (indice < hechos) return hc.exito;
  if (indice == hechos) return hc.pendiente;
  return Theme.of(context).colorScheme.outlineVariant;
}

/// Cuatro tramos de 6 px: lo justo para una tarjeta del teléfono.
class _BarraAvanceHex extends StatelessWidget {
  const _BarraAvanceHex({required this.hechos});

  final int hechos;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < pasosReporteHex.length; i++) ...[
        if (i > 0) const SizedBox(width: Esp.xs),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: _colorPasoHex(context, i, hechos),
              borderRadius: BorderRadius.circular(Esquina.pastilla),
            ),
          ),
        ),
      ],
    ],
  );
}

/// Los pasos con su círculo, unidos por una línea, y el nombre debajo.
class _PasosAvanceHex extends StatelessWidget {
  const _PasosAvanceHex({required this.hechos});

  final int hechos;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < pasosReporteHex.length; i++)
        Expanded(child: _PasoAvanceHex(indice: i, hechos: hechos)),
    ],
  );
}

class _PasoAvanceHex extends StatelessWidget {
  const _PasoAvanceHex({required this.indice, required this.hechos});

  final int indice;
  final int hechos;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hc = HexColores.de(context);
    final ultimo = indice == pasosReporteHex.length - 1;
    Widget linea(bool alcanzada, {required bool visible}) => Expanded(
      child: Container(
        height: 3,
        color:
            !visible
                ? Colors.transparent
                : alcanzada
                ? hc.exito
                : cs.outlineVariant,
      ),
    );
    final hecho = indice < hechos;
    final actual = indice == hechos;
    final (Color fondo, Color borde, Widget marca) =
        hecho
            ? (
              hc.exito,
              hc.exito,
              Icon(Icons.check, size: 16, color: hc.alEnExito),
            )
            : actual
            ? (
              hc.pendienteContenedor,
              hc.pendiente,
              Icon(
                Icons.hourglass_top,
                size: 16,
                color: hc.alEnPendienteContenedor,
              ),
            )
            : (
              Colors.transparent,
              cs.outlineVariant,
              Text(
                '${indice + 1}',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            );
    return Column(
      children: [
        SizedBox(
          height: 28,
          child: Row(
            children: [
              linea(indice <= hechos, visible: indice > 0),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: fondo,
                  shape: BoxShape.circle,
                  border: Border.all(color: borde, width: 1.5),
                ),
                child: marca,
              ),
              linea(indice < hechos, visible: !ultimo),
            ],
          ),
        ),
        const SizedBox(height: Esp.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            pasosReporteHex[indice],
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 12,
              fontWeight: actual ? Peso.titulo : FontWeight.w500,
              color:
                  actual
                      ? hc.pendiente
                      : hecho
                      ? cs.onSurface
                      : cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Rechazado o anulado: quién lo hizo (`textoPendiente`) y el motivo del SP.
/// En la tarjeta el motivo se corta a tres renglones; en el detalle va entero.
class AvisoRechazoHex extends StatelessWidget {
  const AvisoRechazoHex(this.reporte, {super.key, this.compacto = false});

  final HexReporteEntity reporte;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final r = reporte;
    final quien = r.textoPendiente?.trim() ?? '';
    final motivo = r.motivoRechazo?.trim() ?? '';
    final titulo =
        quien.isNotEmpty
            ? quien
            : r.estadoTexto.trim().isNotEmpty
            ? r.estadoTexto
            : r.estado;
    return AvisoHex(
      tono: TonoHex.error,
      icono: r.estado == 'ANULADO' ? Icons.block : Icons.cancel_outlined,
      titulo: titulo,
      texto: motivo.isEmpty ? '' : 'Motivo: $motivo',
      maxLineas: compacto ? 3 : null,
    );
  }
}
