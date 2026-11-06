/// El mapa del día de los tramos: una barra de 00:00 a 24:00 por tipo de día,
/// cada tramo con su tono y los huecos y cruces en rojo con rayas, con el
/// texto del SP que dice cómo arreglarlos. Debajo, en la misma escala, las
/// ventanas de comida (clase COMIDA). La app solo dibuja.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_mapa_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_colores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formatos.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_tramos_reporte.dart'
    show RayasHex;

/// Lo más angosto que se dibuja una pieza: un hueco de 1 minuto se ve.
const double _minimoPieza = 5;
const int _minutosDia = 1440;
const List<int> _marcas = [0, 6, 12, 18, 24];

/// Aire entre la barra de tramos y la franja de comidas.
const double _separacionComidas = 4;
const String _rotuloComidas = 'Comidas';

/// Los colores de la franja de comidas: contorno terciario, distinto de los
/// tramos rellenos.
({Color fondo, Color borde, Color letra}) _coloresComida(ColorScheme cs) => (
  fondo: cs.tertiary.withValues(alpha: 0.14),
  borde: cs.tertiary,
  letra: cs.onSurface,
);

/// El tono de cada código de tramo, en el orden en que aparece. Se calcula
/// sobre todas las barras que se comparan para que un código no cambie de color.
Map<String, int> tonosMapaHex(Iterable<HexTramoMapaEntity> filas) {
  final tonos = <String, int>{};
  for (final f in filas) {
    final c = f.codigo;
    if (f.clase == 'TRAMO' && c != null) {
      tonos.putIfAbsent(c, () => tonos.length);
    }
  }
  return tonos;
}

/// Los pares fondo/letra del tema que se turnan entre tramos.
({Color fondo, Color letra}) _coloresTono(ColorScheme cs, int tono) {
  final paleta = [
    (fondo: cs.primaryContainer, letra: cs.onPrimaryContainer),
    (fondo: cs.secondaryContainer, letra: cs.onSecondaryContainer),
    (fondo: cs.tertiaryContainer, letra: cs.onTertiaryContainer),
    (fondo: cs.primary, letra: cs.onPrimary),
    (fondo: cs.secondary, letra: cs.onSecondary),
    (fondo: cs.tertiary, letra: cs.onTertiary),
    (fondo: cs.surfaceContainerHighest, letra: cs.onSurface),
  ];
  return paleta[tono % paleta.length];
}

/// Las filas por tipo de día, en el orden del SP y cada grupo por hora.
List<List<HexTramoMapaEntity>> gruposMapaHex(List<HexTramoMapaEntity> filas) {
  final grupos = <String, List<HexTramoMapaEntity>>{};
  for (final f in filas) {
    grupos.putIfAbsent(f.tipoDia, () => []).add(f);
  }
  return [
    for (final g in grupos.values)
      g..sort((a, b) => a.desdeMin.compareTo(b.desdeMin)),
  ];
}

/// El mapa completo: título, una barra por tipo de día con sus problemas
/// debajo y la leyenda de colores.
class MapaTramosHex extends StatelessWidget {
  const MapaTramosHex(this.filas, {super.key});

  final List<HexTramoMapaEntity> filas;

  @override
  Widget build(BuildContext context) {
    final grupos = gruposMapaHex(filas);
    if (grupos.isEmpty) return const SizedBox.shrink();
    final tonos = tonosMapaHex(filas);
    final cs = Theme.of(context).colorScheme;
    final hayComidas = filas.any((f) => f.esComida);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: cs.surfaceContainerLow,
        shape: contornoSuperficie(cs),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Esp.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TituloSeccionHex(
              'Cómo se cubre el día',
              icono: Icons.view_timeline_outlined,
            ),
            const SizedBox(height: Esp.xs),
            Text(
              'Cada barra va de 00:00 a 24:00. En rojo, las horas que ningún '
              'tramo paga o que pagan dos a la vez.'
              '${hayComidas ? ' Debajo, en «$_rotuloComidas», las ventanas de comida en la misma escala; la leyenda dice cómo se pagan.' : ''}',
              style: context.apagado(),
            ),
            for (final g in grupos) ...[
              const SizedBox(height: Esp.l),
              Text(
                oGuionHex(g.first.textoTipoDia),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: Peso.titulo),
              ),
              const SizedBox(height: Esp.s),
              BarraDiaHex(g, tonos: tonos),
              for (final p in g)
                if (p.esProblema && textoUsableHex(p.texto) != null) ...[
                  const SizedBox(height: Esp.s),
                  AvisoHex(
                    tono: TonoHex.error,
                    icono: Icons.report_problem_outlined,
                    texto: p.texto!.trim(),
                  ),
                ],
            ],
            const SizedBox(height: Esp.l),
            LeyendaMapaHex(filas, tonos: tonos),
          ],
        ),
      ),
    );
  }
}

/// Un día de 00:00 a 24:00: cada pieza en su posición exacta (las muy cortas
/// con un ancho mínimo, centradas), debajo la franja «Comidas» si las hay y
/// las marcas 00·06·12·18·24. Sin `LayoutBuilder`: también va en un diálogo.
class BarraDiaHex extends StatelessWidget {
  const BarraDiaHex(
    this.piezas, {
    super.key,
    required this.tonos,
    this.alto = 40,
    this.conHoras = true,
    this.conComidas = true,
  });

  final List<HexTramoMapaEntity> piezas;
  final Map<String, int> tonos;
  final double alto;
  final bool conHoras;

  /// Falso: ignora las filas COMIDA (p. ej. «Antes», si «Desde» ya las muestra).
  final bool conComidas;

  static String _descripcion(
    List<HexTramoMapaEntity> tramos,
    List<HexTramoMapaEntity> comidas,
  ) => [
    tramos
        .map(
          (p) =>
              '${p.horaDesde} a ${p.horaHasta}: '
              '${switch (p.clase) {
                'HUECO' => 'sin tramo',
                'CRUCE' => 'cruce de ${p.codigo ?? 'tramos'}',
                _ => p.codigo ?? '',
              }}',
        )
        .join('; '),
    if (comidas.isNotEmpty)
      '$_rotuloComidas: '
          '${comidas.map((c) => '${c.codigo ?? ''} ${c.horaDesde} a ${c.horaHasta}').join('; ')}',
  ].join('. ');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final escala = MediaQuery.textScalerOf(context);
    final letra = escala.scale(t.labelSmall?.fontSize ?? 11);
    final altoMarcas = conHoras ? letra * 1.5 + 2 : 0.0;
    final tramos = [
      for (final p in piezas)
        if (!p.esComida) p,
    ];
    final comidas = [
      if (conComidas)
        for (final p in piezas)
          if (p.esComida) p,
    ]..sort((a, b) => a.desdeMin.compareTo(b.desdeMin));
    // Franja de comidas: rótulo arriba y carril; sin comidas no ocupa nada.
    final altoRotulo = letra * 1.5;
    final altoCarril = math.max(18.0, letra * 1.5 + 4);
    final altoComidas =
        comidas.isEmpty
            ? 0.0
            : _separacionComidas + altoRotulo + 2 + altoCarril;
    // Los tramos primero; los problemas encima, para que siempre se vean.
    final ordenadas = [
      for (final p in tramos)
        if (!p.esProblema) p,
      for (final p in tramos)
        if (p.esProblema) p,
    ];
    final colorComida = _coloresComida(cs);
    return Semantics(
      container: true,
      label: _descripcion(tramos, comidas),
      child: ExcludeSemantics(
        child: SizedBox(
          width: double.infinity,
          height: alto + altoComidas + altoMarcas,
          child: CustomPaint(
            painter: _PintorDiaHex(
              piezas: [
                for (final p in ordenadas)
                  (
                    pieza: p,
                    colores:
                        p.esProblema
                            ? (
                              fondo: cs.errorContainer,
                              letra: cs.onErrorContainer,
                            )
                            : _coloresTono(cs, tonos[p.codigo] ?? 0),
                  ),
              ],
              alto: alto,
              conHoras: conHoras,
              fondo: cs.surfaceContainerHighest,
              raya: cs.error,
              borde: cs.onSurface,
              estiloCodigo: estiloCifrasHex(t.labelSmall, fuerte: true),
              estiloHoras: estiloCifrasHex(t.labelSmall),
              estiloMarca: estiloCifrasHex(
                t.labelSmall,
              )?.copyWith(color: cs.onSurfaceVariant),
              escala: escala,
              direccion: Directionality.of(context),
              comidas: comidas,
              altoRotulo: altoRotulo,
              altoCarril: altoCarril,
              comidaFondo: colorComida.fondo,
              comidaBorde: colorComida.borde,
              pista: cs.outlineVariant,
              estiloComida: estiloCifrasHex(
                t.labelSmall,
              )?.copyWith(color: colorComida.letra),
              estiloRotulo: t.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: Peso.titulo,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef _PiezaPintadaHex =
    ({HexTramoMapaEntity pieza, ({Color fondo, Color letra}) colores});

/// Pinta la barra: el fondo, cada pieza (las de problema con rayas, la
/// propuesta con borde), su código y horas si entran, la franja de comidas
/// con guías hasta la barra y las marcas.
class _PintorDiaHex extends CustomPainter {
  _PintorDiaHex({
    required this.piezas,
    required this.alto,
    required this.conHoras,
    required this.fondo,
    required this.raya,
    required this.borde,
    required this.estiloCodigo,
    required this.estiloHoras,
    required this.estiloMarca,
    required this.escala,
    required this.direccion,
    required this.comidas,
    required this.altoRotulo,
    required this.altoCarril,
    required this.comidaFondo,
    required this.comidaBorde,
    required this.pista,
    required this.estiloComida,
    required this.estiloRotulo,
  });

  final List<_PiezaPintadaHex> piezas;
  final double alto;
  final bool conHoras;
  final Color fondo;
  final Color raya;
  final Color borde;
  final TextStyle? estiloCodigo;
  final TextStyle? estiloHoras;
  final TextStyle? estiloMarca;
  final TextScaler escala;
  final TextDirection direccion;
  final List<HexTramoMapaEntity> comidas;
  final double altoRotulo;
  final double altoCarril;
  final Color comidaFondo;
  final Color comidaBorde;
  final Color pista;
  final TextStyle? estiloComida;
  final TextStyle? estiloRotulo;

  double get _altoComidas =>
      comidas.isEmpty ? 0 : _separacionComidas + altoRotulo + 2 + altoCarril;

  TextPainter _texto(String texto, TextStyle? estilo) => TextPainter(
    text: TextSpan(text: texto, style: estilo),
    textDirection: direccion,
    textScaler: escala,
    maxLines: 1,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final ancho = size.width;
    if (ancho <= 0) return;
    double x(int minuto) => ancho * minuto.clamp(0, _minutosDia) / _minutosDia;
    final barra = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, ancho, alto),
      const Radius.circular(Esquina.chica),
    );
    canvas
      ..save()
      ..clipRRect(barra)
      ..drawRect(barra.outerRect, Paint()..color = fondo);
    for (final (:pieza, :colores) in piezas) {
      final real = math.max(0.0, x(pieza.hastaMin) - x(pieza.desdeMin));
      final w = math.min(ancho, math.max(real, _minimoPieza));
      final double izq =
          (x(pieza.desdeMin) - (w - real) / 2)
              .clamp(0.0, math.max(0.0, ancho - w))
              .toDouble();
      // Un trazo de 1 px separa un tramo del siguiente.
      final separa =
          !pieza.esProblema && pieza.hastaMin < _minutosDia ? 1.0 : 0.0;
      final rect = Rect.fromLTWH(izq, 0, math.max(0.0, w - separa), alto);
      if (pieza.esProblema) {
        canvas
          ..save()
          ..translate(rect.left, 0);
        RayasHex(
          fondo: colores.fondo,
          raya: raya,
        ).paint(canvas, Size(rect.width, alto));
        canvas.restore();
      } else {
        canvas.drawRect(rect, Paint()..color = colores.fondo);
        if (pieza.esPropuesto) {
          canvas.drawRect(
            rect.deflate(1),
            Paint()
              ..color = borde
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      }
      _etiqueta(canvas, pieza, rect, colores.letra);
    }
    canvas.restore();
    if (comidas.isNotEmpty) _pintarComidas(canvas, ancho, x);
    if (conHoras) _pintarMarcas(canvas, ancho, x);
  }

  /// La pieza en su posición exacta; si es muy corta, con el ancho mínimo y
  /// centrada sobre su minuto.
  static ({double izq, double ancho}) _ubicar(
    double ancho,
    double desde,
    double hasta,
  ) {
    final real = math.max(0.0, hasta - desde);
    final w = math.min(ancho, math.max(real, _minimoPieza));
    final izq = (desde - (w - real) / 2).clamp(0.0, math.max(0.0, ancho - w));
    return (izq: izq.toDouble(), ancho: w);
  }

  /// Rótulo «Comidas», el carril de 00:00 a 24:00 (solo contorno), guías
  /// discontinuas de cada borde de ventana hasta la barra y cada ventana.
  void _pintarComidas(Canvas canvas, double ancho, double Function(int) x) {
    final yRotulo = alto + _separacionComidas;
    final yCarril = yRotulo + altoRotulo + 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.5, yCarril + 0.5, ancho - 1, altoCarril - 1),
        const Radius.circular(Esquina.chica),
      ),
      Paint()
        ..color = pista
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final guia =
        Paint()
          ..color = comidaBorde
          ..strokeWidth = 1;
    final bordes = <double>{
      for (final c in comidas) ...[x(c.desdeMin), x(c.hastaMin)],
    };
    for (final gx in bordes) {
      final px = gx.clamp(0.5, math.max(0.5, ancho - 0.5)).toDouble();
      for (var y = alto; y < yCarril; y += 5) {
        canvas.drawLine(
          Offset(px, y),
          Offset(px, math.min(y + 3, yCarril)),
          guia,
        );
      }
    }
    // El rótulo a la izquierda; a la derecha si allí lo cruza una guía.
    final r = _texto(_rotuloComidas, estiloRotulo);
    final libreIzq = bordes.every((b) => b > r.width + 4);
    final libreDer = bordes.every((b) => b < ancho - r.width - 4);
    final rx = !libreIzq && libreDer ? math.max(0.0, ancho - r.width) : 0.0;
    r.paint(canvas, Offset(rx, yRotulo + (altoRotulo - r.height) / 2));
    r.dispose();
    final ventanas = <(HexTramoMapaEntity, Rect)>[];
    for (final c in comidas) {
      final u = _ubicar(ancho, x(c.desdeMin), x(c.hastaMin));
      final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(u.izq, yCarril, u.ancho, altoCarril),
        const Radius.circular(Esquina.chica),
      );
      canvas
        ..drawRRect(rr, Paint()..color = comidaFondo)
        ..drawRRect(
          rr.deflate(0.5),
          Paint()
            ..color = comidaBorde
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      ventanas.add((c, rr.outerRect));
    }
    _etiquetasComida(canvas, ancho, ventanas);
  }

  /// «C 18:00–20:00» dentro de la ventana; si no entra, «C» dentro y las horas
  /// al costado libre; si ni el código entra, el texto al costado. Los textos
  /// no se pisan: lo que no entra en ningún lado no se escribe.
  void _etiquetasComida(
    Canvas canvas,
    double ancho,
    List<(HexTramoMapaEntity, Rect)> ventanas,
  ) {
    const aire = 3.0;
    var ocupado = 0.0;
    for (var i = 0; i < ventanas.length; i++) {
      final (c, r) = ventanas[i];
      final siguiente =
          i + 1 < ventanas.length ? ventanas[i + 1].$2.left : ancho;
      final desdeIzq = ocupado;
      var fin = r.right;
      // Pinta el texto dentro (centrado) o al costado; dice hasta dónde llegó.
      double? escribir(String texto, {required bool adentro}) {
        final p = _texto(texto, estiloComida);
        final y = r.center.dy - p.height / 2;
        double? hasta;
        if (adentro) {
          if (p.width <= r.width - 6 && p.height <= r.height) {
            p.paint(canvas, Offset(r.center.dx - p.width / 2, y));
            hasta = r.right;
          }
        } else if (r.right + aire + p.width <= siguiente - aire) {
          p.paint(canvas, Offset(r.right + aire, y));
          hasta = r.right + aire + p.width;
        } else if (r.left - aire - p.width >= desdeIzq + aire) {
          p.paint(canvas, Offset(r.left - aire - p.width, y));
          hasta = r.right;
        }
        p.dispose();
        return hasta;
      }

      final codigo = c.codigo?.trim() ?? '';
      if (codigo.isNotEmpty) {
        final horas = '${c.horaDesde}–${c.horaHasta}';
        if (escribir('$codigo $horas', adentro: true) == null) {
          if (escribir(codigo, adentro: true) != null) {
            fin = escribir(horas, adentro: false) ?? fin;
          } else {
            fin =
                escribir('$codigo $horas', adentro: false) ??
                escribir(codigo, adentro: false) ??
                fin;
          }
        }
      }
      ocupado = math.max(ocupado, fin);
    }
  }

  /// El código y, si hay alto y ancho, las horas debajo; nada si no entra.
  void _etiqueta(Canvas canvas, HexTramoMapaEntity p, Rect rect, Color letra) {
    final codigo = p.codigo?.trim() ?? '';
    if (codigo.isEmpty) return;
    final libre = rect.width - 8;
    final c = _texto(codigo, estiloCodigo?.copyWith(color: letra));
    if (c.width > libre || c.height > alto) {
      c.dispose();
      return;
    }
    final h = _texto(
      '${p.horaDesde}–${p.horaHasta}',
      estiloHoras?.copyWith(color: letra),
    );
    final conHoras = h.width <= libre && c.height + h.height <= alto - 4;
    final total = c.height + (conHoras ? h.height : 0);
    var y = (alto - total) / 2;
    c.paint(canvas, Offset(rect.center.dx - c.width / 2, y));
    y += c.height;
    if (conHoras) h.paint(canvas, Offset(rect.center.dx - h.width / 2, y));
    c.dispose();
    h.dispose();
  }

  void _pintarMarcas(Canvas canvas, double ancho, double Function(int) x) {
    for (final hora in _marcas) {
      final m = _texto(hora.toString().padLeft(2, '0'), estiloMarca);
      final izq = (x(hora * 60) - m.width / 2).clamp(
        0.0,
        math.max(0.0, ancho - m.width),
      );
      m.paint(canvas, Offset(izq.toDouble(), alto + _altoComidas + 2));
      m.dispose();
    }
  }

  @override
  bool shouldRepaint(_PintorDiaHex old) =>
      old.piezas != piezas ||
      old.comidas != comidas ||
      old.alto != alto ||
      old.conHoras != conHoras ||
      old.fondo != fondo ||
      old.raya != raya ||
      old.comidaBorde != comidaBorde ||
      old.estiloCodigo != estiloCodigo ||
      old.escala != escala;
}

/// Qué es cada color: la muestra, el código, la leyenda y el factor; debajo,
/// cada comida con el texto del SP que dice cómo se paga.
class LeyendaMapaHex extends StatelessWidget {
  const LeyendaMapaHex(this.filas, {super.key, required this.tonos});

  final List<HexTramoMapaEntity> filas;
  final Map<String, int> tonos;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final vistos = <String, HexTramoMapaEntity>{};
    for (final f in filas) {
      final c = f.codigo;
      if (f.clase == 'TRAMO' && c != null) vistos.putIfAbsent(c, () => f);
    }
    // Cada comida una vez: el SP la repite en cada tipo de día.
    final comidas = <String, HexTramoMapaEntity>{};
    for (final f in filas) {
      final c = f.codigo;
      if (f.esComida && c != null) comidas.putIfAbsent(c, () => f);
    }
    final hayProblema = filas.any((f) => f.esProblema);
    Widget muestra(Color fondo, {bool rayas = false}) => SizedBox(
      width: 14,
      height: 14,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child:
            rayas
                ? CustomPaint(painter: RayasHex(fondo: fondo, raya: cs.error))
                : ColoredBox(color: fondo),
      ),
    );
    Widget item(Widget marca, InlineSpan texto) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        marca,
        const SizedBox(width: Esp.xs + 2),
        Flexible(child: Text.rich(texto, style: t.bodySmall)),
      ],
    );
    final colorComida = _coloresComida(cs);
    final muestraComida = SizedBox(
      width: 14,
      height: 14,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorComida.fondo,
          border: Border.all(color: colorComida.borde),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
    final tramos = Wrap(
      spacing: Esp.l,
      runSpacing: Esp.s,
      children: [
        for (final MapEntry(key: codigo, value: f) in vistos.entries)
          item(
            muestra(_coloresTono(cs, tonos[codigo] ?? 0).fondo),
            TextSpan(
              children: [
                TextSpan(
                  text: codigo,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text:
                      [
                        if (textoUsableHex(f.leyenda) case final l?) ' $l',
                        if (f.multiplicador != null)
                          ' · ×${decimalHex(f.multiplicador)}',
                      ].join(),
                ),
              ],
            ),
          ),
        if (hayProblema)
          item(
            muestra(cs.errorContainer, rayas: true),
            const TextSpan(text: 'Sin tramo o con dos tramos'),
          ),
      ],
    );
    if (comidas.isEmpty) return tramos;
    // El texto del SP; si no llegó, la leyenda y la ventana.
    String detalleComida(HexTramoMapaEntity f) =>
        textoUsableHex(f.texto) ??
        [
          if (textoUsableHex(f.leyenda) case final l?) l,
          '${f.horaDesde}–${f.horaHasta}',
        ].join(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tramos,
        for (final MapEntry(key: codigo, value: f) in comidas.entries)
          Padding(
            padding: const EdgeInsets.only(top: Esp.s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: muestraComida,
                ),
                const SizedBox(width: Esp.xs + 2),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: codigo,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' ${detalleComida(f)}'),
                      ],
                    ),
                    style: t.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Los textos de los huecos y cruces en una línea de error cada uno, para
/// el diálogo, donde un aviso grande taparía el formulario.
class ProblemasMapaHex extends StatelessWidget {
  const ProblemasMapaHex(this.piezas, {super.key});

  final List<HexTramoMapaEntity> piezas;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textos = [
      for (final p in piezas)
        if (p.esProblema)
          if (textoUsableHex(p.texto) case final texto?) texto,
    ];
    if (textos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final texto in textos)
          Padding(
            padding: const EdgeInsets.only(top: Esp.xs),
            child: IconoTextoHex(
              texto: texto,
              icono: Icons.report_problem_outlined,
              tono: TonoHex.error,
              estilo: Theme.of(context).textTheme.bodySmall,
              colorTexto: cs.error,
            ),
          ),
      ],
    );
  }
}
