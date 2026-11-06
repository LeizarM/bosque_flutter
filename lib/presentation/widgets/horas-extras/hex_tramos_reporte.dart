/// El reporte por tramos de tiempo (D36): una barra proporcional con las
/// horas en los límites y la lista de qué ganó cada tramo y cómo se paga.
/// Los textos vienen del SP; la app no hace cuentas.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_tramo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_colores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formatos.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_piezas.dart';

/// Lo más angosto que se dibuja un tramo: uno de pocos minutos sigue visible.
const double _minimoSegmento = 6;

/// La separación entre tramos de la barra y entre las horas de abajo.
const double _separacion = 2;
const double _aireEtiquetas = 6;

/// Desde este ancho la lista va como tabla; por debajo, en tarjetas.
const double anchoTablaTramosHex = 560;

/// El fondo y la letra de un tramo según su `clase`: comida como sus fichas,
/// hora en `primary` y sin pago en `outlineVariant`.
({Color fondo, Color letra}) coloresTramoHex(
  BuildContext context,
  HexReporteTramoEntity t,
) {
  final cs = Theme.of(context).colorScheme;
  return switch (t.clase) {
    'COMIDA' => coloresCodigoHex(
      context,
      t.codigo ?? '',
      familia: FamiliaCodigoHex.comida,
    ),
    'HORA' => (fondo: cs.primary, letra: cs.onPrimary),
    _ => (fondo: cs.outlineVariant, letra: cs.onSurfaceVariant),
  };
}

/// El ancho de cada tramo en [ancho] px, proporcional a sus [minutos], con
/// [minimo] para los muy cortos (lo que falta sale de los largos). Si no
/// alcanza para todos, van iguales.
@visibleForTesting
List<double> anchosTramosHex(
  List<int> minutos,
  double ancho, {
  double minimo = _minimoSegmento,
}) {
  final n = minutos.length;
  if (n == 0) return const [];
  if (!ancho.isFinite || ancho <= 0) return List.filled(n, 0);
  final m = [for (final x in minutos) math.max(x, 0)];
  final total = m.fold<int>(0, (a, b) => a + b);
  if (total <= 0 || minimo * n >= ancho) return List.filled(n, ancho / n);
  final fijos = <int>{};
  while (true) {
    final resto = ancho - minimo * fijos.length;
    var libres = 0;
    for (var i = 0; i < n; i++) {
      if (!fijos.contains(i)) libres += m[i];
    }
    if (libres <= 0) return List.filled(n, ancho / n);
    var cambio = false;
    for (var i = 0; i < n; i++) {
      if (!fijos.contains(i) && resto * m[i] / libres < minimo) {
        fijos.add(i);
        cambio = true;
      }
    }
    if (!cambio) {
      return [
        for (var i = 0; i < n; i++)
          fijos.contains(i) ? minimo : resto * m[i] / libres,
      ];
    }
  }
}

/// Qué horas de los límites entran sin pisarse, dados su centro y su ancho:
/// primero la de inicio y la de fin, luego las de en medio en orden.
@visibleForTesting
List<bool> etiquetasVisiblesHex(
  List<double> centros,
  List<double> anchos,
  double total, {
  double aire = _aireEtiquetas,
}) {
  final n = centros.length;
  final visibles = List.filled(n, false);
  final puestas = <(double, double)>[];
  (double, double) caja(int i) {
    final w = anchos[i];
    final izq =
        (centros[i] - w / 2).clamp(0.0, math.max(0.0, total - w)).toDouble();
    return (izq, izq + w);
  }

  bool entra((double, double) c) =>
      c.$2 <= total + 0.01 &&
      puestas.every((p) => c.$2 + aire <= p.$1 || c.$1 >= p.$2 + aire);

  for (final i in [0, if (n > 1) n - 1, for (var k = 1; k < n - 1; k++) k]) {
    final c = caja(i);
    if (entra(c)) {
      visibles[i] = true;
      puestas.add(c);
    }
  }
  return visibles;
}

/// La barra de tramos: cada uno con ancho proporcional a sus minutos y su
/// código adentro si cabe; debajo, las horas de los límites que no se pisan.
class BarraTramosHex extends StatelessWidget {
  const BarraTramosHex(this.tramos, {super.key});

  final List<HexReporteTramoEntity> tramos;

  @override
  Widget build(BuildContext context) {
    final validos = [
      for (final t in tramos)
        if (t.minutos > 0) t,
    ];
    if (validos.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final escala = MediaQuery.textScalerOf(context);
    final direccion = Directionality.of(context);
    final estiloHora = estiloCifrasHex(
      t.labelSmall,
    )?.copyWith(color: cs.onSurfaceVariant);
    final estiloCodigo = estiloCifrasHex(t.labelSmall, fuerte: true);

    Size medir(String texto, TextStyle? estilo) {
      final p = TextPainter(
        text: TextSpan(text: texto, style: estilo),
        textDirection: direccion,
        textScaler: escala,
        maxLines: 1,
      )..layout();
      final s = p.size;
      p.dispose();
      return s;
    }

    final horas = [
      for (final s in validos) s.horaDesde,
      validos.last.horaHasta,
    ];
    final tamHoras = [for (final h in horas) medir(h, estiloHora)];
    final tamCodigos = [
      for (final s in validos) medir(s.codigo ?? '', estiloCodigo),
    ];
    final altoCodigo = tamCodigos.map((s) => s.height).fold(0.0, math.max);
    final altoBarra = math.max(22.0, altoCodigo + 6);
    final altoHoras = tamHoras.map((s) => s.height).fold(0.0, math.max);
    final descripcion = validos
        .map(
          (s) =>
              '${s.horaDesde} a ${s.horaHasta}, ${s.duracionTexto}: '
              '${s.leyenda ?? s.textoPago}',
        )
        .join('; ');

    return Semantics(
      container: true,
      label: 'Tramos del reporte. $descripcion',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, c) {
            final ancho = c.maxWidth.isFinite ? c.maxWidth : 320.0;
            final anchos = anchosTramosHex([
              for (final s in validos) s.minutos,
            ], ancho);
            final bordes = <double>[0];
            for (final w in anchos) {
              bordes.add(bordes.last + w);
            }
            bordes[bordes.length - 1] = ancho;
            final visibles = etiquetasVisiblesHex(bordes, [
              for (final s in tamHoras) s.width,
            ], ancho);
            return SizedBox(
              height: altoBarra + Esp.xs + altoHoras,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    width: ancho,
                    height: altoBarra,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Esquina.chica),
                      child: ColoredBox(
                        color: cs.surface,
                        child: Stack(
                          children: [
                            for (var i = 0; i < validos.length; i++)
                              Positioned(
                                left: bordes[i],
                                top: 0,
                                bottom: 0,
                                width: math.max(
                                  0,
                                  anchos[i] -
                                      (i < validos.length - 1
                                          ? _separacion
                                          : 0),
                                ),
                                child: _SegmentoHex(
                                  tramo: validos[i],
                                  mostrarCodigo:
                                      tamCodigos[i].width + 8 <=
                                      anchos[i] - _separacion,
                                  estilo: estiloCodigo,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  for (var i = 0; i < horas.length; i++)
                    if (visibles[i])
                      Positioned(
                        top: altoBarra + Esp.xs,
                        left: (bordes[i] - tamHoras[i].width / 2).clamp(
                          0.0,
                          math.max(0.0, ancho - tamHoras[i].width),
                        ),
                        child: Text(
                          horas[i],
                          maxLines: 1,
                          softWrap: false,
                          style: estiloHora,
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SegmentoHex extends StatelessWidget {
  const _SegmentoHex({
    required this.tramo,
    required this.mostrarCodigo,
    required this.estilo,
  });

  final HexReporteTramoEntity tramo;
  final bool mostrarCodigo;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    final par = coloresTramoHex(context, tramo);
    final codigo = tramo.codigo ?? '';
    final texto =
        mostrarCodigo && codigo.isNotEmpty
            ? Center(
              child: Text(
                codigo,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: estilo?.copyWith(color: par.letra),
              ),
            )
            : null;
    if (tramo.clase == 'SIN_PAGO') {
      final cs = Theme.of(context).colorScheme;
      return CustomPaint(
        painter: RayasHex(fondo: par.fondo, raya: cs.outline),
        child: texto,
      );
    }
    return ColoredBox(color: par.fondo, child: texto);
  }
}

/// Fondo tenue con rayas diagonales: una hora que no se paga, o un hueco o
/// cruce del mapa de tramos.
class RayasHex extends CustomPainter {
  const RayasHex({required this.fondo, required this.raya});

  final Color fondo;
  final Color raya;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = fondo);
    final p =
        Paint()
          ..color = raya.withValues(alpha: 0.45)
          ..strokeWidth = 1.5;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var x = -size.height; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(RayasHex old) => old.fondo != fondo || old.raya != raya;
}

/// La ficha de «Qué gana»: el código con su familia y la leyenda; la hora sin
/// pago va apagada.
class _QueGanaHex extends StatelessWidget {
  const _QueGanaHex(this.t);

  final HexReporteTramoEntity t;

  @override
  Widget build(BuildContext context) {
    final codigo = t.codigo?.trim() ?? '';
    final leyenda = t.leyenda?.trim() ?? '';
    if (codigo.isEmpty && leyenda.isEmpty) return const Text('—');
    return Wrap(
      spacing: Esp.s,
      runSpacing: Esp.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (codigo.isNotEmpty)
          CodigoHex(
            codigo,
            familia:
                t.clase == 'HORA'
                    ? FamiliaCodigoHex.tramo
                    : FamiliaCodigoHex.comida,
            apagado: t.clase == 'SIN_PAGO',
            explicar: true,
          ),
        if (leyenda.isNotEmpty)
          Text(leyenda, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

/// La muestra de color del tramo, la misma que en la barra.
class _MuestraHex extends StatelessWidget {
  const _MuestraHex(this.t);

  final HexReporteTramoEntity t;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fondo = coloresTramoHex(context, t).fondo;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: cs.outlineVariant),
      ),
    );
  }
}

String _rangoHex(HexReporteTramoEntity t) => '${t.horaDesde} → ${t.horaHasta}';

/// Los tramos en lista: tabla en el ancho, tarjetas en el angosto.
class ListaTramosHex extends StatelessWidget {
  const ListaTramosHex(this.tramos, {super.key});

  final List<HexReporteTramoEntity> tramos;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder:
        (context, c) =>
            c.maxWidth >= anchoTablaTramosHex
                ? _TablaTramosHex(tramos)
                : _TarjetasTramosHex(tramos),
  );
}

class _TablaTramosHex extends StatelessWidget {
  const _TablaTramosHex(this.tramos);

  final List<HexReporteTramoEntity> tramos;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final encabezado = t.labelMedium?.copyWith(color: cs.onSurfaceVariant);
    Widget celda(Widget hijo) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Esp.s, horizontal: Esp.s),
      child: hijo,
    );
    // El monto solo lo trae el simulador: en el reporte no hay columna.
    final conMonto = tramos.any((s) => s.monto != null);
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(3),
        4: IntrinsicColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(
        horizontalInside: BorderSide(color: cs.outlineVariant),
      ),
      children: [
        TableRow(
          children: [
            for (final r in [
              'Tramo',
              'Tiempo',
              'Qué gana',
              'Cómo se paga',
              if (conMonto) 'Monto',
            ])
              celda(Text(r, style: encabezado)),
          ],
        ),
        for (final s in tramos)
          TableRow(
            children: [
              celda(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MuestraHex(s),
                    const SizedBox(width: Esp.s),
                    Text(
                      _rangoHex(s),
                      softWrap: false,
                      style: estiloCifrasHex(t.bodyMedium, fuerte: true),
                    ),
                  ],
                ),
              ),
              celda(
                Text(
                  s.duracionTexto,
                  softWrap: false,
                  style: estiloCifrasHex(t.bodyMedium),
                ),
              ),
              celda(_QueGanaHex(s)),
              celda(Text(s.textoPago, style: t.bodyMedium)),
              if (conMonto)
                celda(
                  Text(
                    s.monto == null ? '—' : bsHex(s.monto),
                    softWrap: false,
                    textAlign: TextAlign.end,
                    style: estiloCifrasHex(t.bodyMedium, fuerte: true),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _TarjetasTramosHex extends StatelessWidget {
  const _TarjetasTramosHex(this.tramos);

  final List<HexReporteTramoEntity> tramos;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < tramos.length; i++) ...[
        if (i > 0) const SizedBox(height: Esp.s),
        _TarjetaTramoHex(tramos[i]),
      ],
    ],
  );
}

/// Un tramo en el angosto: el color de la barra como filo izquierdo, el rango
/// con su duración, qué gana y cómo se paga.
class _TarjetaTramoHex extends StatelessWidget {
  const _TarjetaTramoHex(this.s);

  final HexReporteTramoEntity s;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    // Sin radio en el borde de un solo lado: lo redondea el recorte.
    return ClipRRect(
      borderRadius: BorderRadius.circular(Esquina.chica),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          border: Border(
            left: BorderSide(
              color:
                  s.clase == 'SIN_PAGO'
                      ? cs.outline
                      : coloresTramoHex(context, s).fondo,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Esp.m, Esp.s, Esp.m, Esp.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: Esp.s,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _rangoHex(s),
                    style: estiloCifrasHex(t.bodyMedium, fuerte: true),
                  ),
                  Text(
                    s.duracionTexto,
                    style: estiloCifrasHex(context.apagado()),
                  ),
                  if (s.monto case final monto?)
                    Text(
                      bsHex(monto),
                      style: estiloCifrasHex(t.bodyMedium, fuerte: true),
                    ),
                ],
              ),
              const SizedBox(height: Esp.xs),
              _QueGanaHex(s),
              if (s.textoPago.isNotEmpty) ...[
                const SizedBox(height: Esp.xs),
                Text(s.textoPago, style: t.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
