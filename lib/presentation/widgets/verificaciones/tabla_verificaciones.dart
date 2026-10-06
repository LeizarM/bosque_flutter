/// El armazon de las dos tablas de «Verificar Cheques» (la lista de
/// verificaciones y la de cheques pendientes): columnas que se ocultan por
/// prioridad cuando falta ancho, cabecera tintada, fila con franja de acento,
/// cebrado y resalte bajo el mouse.
///
/// Es la misma gramatica que la tabla de cheques, escrita aparte a proposito: ese
/// archivo es de otro modulo y sus ajustes no deben colarse aqui. A diferencia
/// de aquella, **esta tabla no se desplaza de lado**: por debajo de
/// [anchoMinimoTablaVerificacion] el listado pasa a tarjetas.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';

/// Ancho del area de resultados desde el cual se usa tabla. Se mide el ancho del
/// contenedor y no el de la ventana: dentro del dashboard el menu lateral se
/// come su parte, y dentro de un dialogo el panel tambien.
const double anchoMinimoTablaVerificacion = 720;

/// Ancho minimo de una tarjeta; decide cuantas caben por fila.
const double anchoMinimoTarjetaVerificacion = 340;

/// El ancho minimo, por unidad de flex, de una columna de texto.
const double _unidadTexto = 55;

/// Una columna de la tabla.
class ColumnaTabla {
  const ColumnaTabla(
    this.id,
    this.titulo, {
    this.ancho,
    this.flex = 1,
    this.derecha = false,
    this.descarte = 0,
  });

  final String id;
  final String titulo;

  /// Ancho fijo; sin el, la columna reparte el resto por [flex].
  final double? ancho;
  final int flex;
  final bool derecha;

  /// 0 = esencial. Con un numero mayor, la columna se oculta antes cuando falta
  /// ancho: la de numero mas alto es la primera que se va.
  final int descarte;

  /// Lo minimo que necesita: su ancho fijo o [_unidadTexto] por cada flex.
  double get minimo => ancho ?? flex * _unidadTexto;
}

/// Que columnas se dibujan para un ancho dado.
class PlanTabla {
  const PlanTabla({
    required this.columnas,
    required this.ocultas,
    required this.anchoAcciones,
  });

  final List<ColumnaTabla> columnas;
  final List<ColumnaTabla> ocultas;

  /// Ancho de la celda de acciones; 0 si no hay.
  final double anchoAcciones;
}

double _necesario(List<ColumnaTabla> cols, double anchoAcciones) {
  final acciones = anchoAcciones == 0 ? 0.0 : anchoAcciones + Esp.s;
  final datos = cols.fold<double>(0, (s, c) => s + c.minimo);
  // Los 4 px de la franja se suman al relleno lateral.
  return datos + Esp.s * (cols.length - 1) + acciones + Esp.l * 2 + 4;
}

/// Elige las columnas que entran en [viewport]: todas si caben; si no, se van
/// ocultando las de menos uso (la de `descarte` mas alto primero) hasta que
/// entren o queden solo las esenciales.
PlanTabla planearTabla(
  List<ColumnaTabla> todas,
  double viewport,
  double anchoAcciones,
) {
  final columnas = [...todas];
  final orden =
      todas.where((c) => c.descarte > 0).toList()
        ..sort((a, b) => b.descarte.compareTo(a.descarte));
  for (var i = 0; ; i++) {
    if (_necesario(columnas, anchoAcciones) <= viewport) break;
    if (i == orden.length) break;
    columnas.remove(orden[i]);
  }
  return PlanTabla(
    columnas: columnas,
    ocultas: [
      for (final c in todas)
        if (!columnas.contains(c)) c,
    ],
    anchoAcciones: anchoAcciones,
  );
}

/// Una fila con las celdas alineadas a las columnas del [plan] y, al final, la
/// celda de acciones. Sirve a cabecera y datos.
Widget filaDeTabla(
  PlanTabla plan,
  Widget Function(ColumnaTabla) celda, {
  Widget? acciones,
}) {
  final hijos = <Widget>[];
  for (var i = 0; i < plan.columnas.length; i++) {
    if (i > 0) hijos.add(const SizedBox(width: Esp.s));
    final c = plan.columnas[i];
    final contenido = Align(
      alignment: c.derecha ? Alignment.centerRight : Alignment.centerLeft,
      child: celda(c),
    );
    hijos.add(
      c.ancho != null
          ? SizedBox(width: c.ancho, child: contenido)
          : Expanded(flex: c.flex, child: contenido),
    );
  }
  if (plan.anchoAcciones > 0) {
    hijos.add(const SizedBox(width: Esp.s));
    hijos.add(
      SizedBox(
        width: plan.anchoAcciones,
        child: Align(alignment: Alignment.centerRight, child: acciones),
      ),
    );
  }
  return Row(children: hijos);
}

/// La tabla: tarjeta con cabecera tintada, las filas y, debajo, la paginacion y
/// el aviso de las columnas que no entraron.
class TablaVerificaciones extends StatelessWidget {
  const TablaVerificaciones({
    super.key,
    required this.columnas,
    required this.anchoAcciones,
    required this.cantidad,
    required this.filaDe,
    required this.pie,
    this.tituloAcciones = 'Acciones',
  });

  final List<ColumnaTabla> columnas;

  /// Lo que miden las acciones de una fila; 0 si ninguna fila tiene.
  final double anchoAcciones;
  final int cantidad;

  /// Arma la fila [i]. Recibe el plan para alinear sus celdas con la cabecera.
  final Widget Function(PlanTabla plan, int i) filaDe;

  /// La paginacion: no se desplaza ni se oculta con las columnas.
  final Widget pie;

  /// El rotulo de la celda de acciones en la cabecera.
  final String tituloAcciones;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fondoFila = cs.surfaceContainerLow;
    // La cabecera lleva un tinte del color principal del tema: separa los
    // rotulos de los datos sin inventar un color.
    final fondoCabecera = Color.alphaBlend(
      cs.primary.withValues(alpha: 0.10),
      fondoFila,
    );
    final estiloCabecera = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: Peso.dato,
      color: cs.onSurface,
      letterSpacing: 0.1,
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: fondoFila,
      clipBehavior: Clip.antiAlias,
      shape: contornoSuperficie(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final plan = planearTabla(
                columnas,
                constraints.maxWidth,
                anchoAcciones,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: fondoCabecera,
                      border: Border(
                        bottom: BorderSide(
                          color: cs.primary.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Esp.l + 4,
                        Esp.m,
                        Esp.l,
                        Esp.m,
                      ),
                      child: filaDeTabla(
                        plan,
                        // Dos lineas: «Banco del cheque» no cabe en una
                        // columna angosta y cortado con puntos no se lee.
                        (c) => Text(
                          c.titulo,
                          style: estiloCabecera,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        acciones:
                            plan.anchoAcciones > 0
                                ? Text(
                                  tituloAcciones,
                                  style: estiloCabecera,
                                  maxLines: 1,
                                  softWrap: false,
                                )
                                : null,
                      ),
                    ),
                  ),
                  for (var i = 0; i < cantidad; i++) ...[
                    if (i > 0) Divider(height: 1, color: cs.outlineVariant),
                    filaDe(plan, i),
                  ],
                  if (plan.ocultas.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Esp.l,
                        Esp.s,
                        Esp.l,
                        Esp.xs,
                      ),
                      child: Text(
                        'Por falta de ancho no se muestran: '
                        '${plan.ocultas.map((c) => c.titulo).join(', ')}. '
                        'Están en una ventana más ancha y en la vista de tarjetas.',
                        key: const ValueKey('columnas-ocultas'),
                        style: context.apagado(),
                      ),
                    ),
                ],
              );
            },
          ),
          Divider(height: 1, color: cs.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Esp.m,
              vertical: Esp.xs,
            ),
            child: pie,
          ),
        ],
      ),
    );
  }
}

/// Una fila de datos: fondo cebrado muy tenue, resalte con el mouse encima y la
/// franja de acento de 4 px al borde izquierdo.
class FilaTablaVerificacion extends StatefulWidget {
  const FilaTablaVerificacion({
    super.key,
    required this.indice,
    required this.franja,
    required this.plan,
    required this.celda,
    this.acciones,
    this.alturaMinima = 60,
  });

  /// Posicion en la pagina, para el cebrado.
  final int indice;
  final Color franja;
  final PlanTabla plan;
  final Widget Function(ColumnaTabla) celda;

  /// Las acciones de la fila; recibe si el mouse esta sobre ella, para teñir los
  /// iconos.
  final Widget Function(bool sobre)? acciones;
  final double alturaMinima;

  @override
  State<FilaTablaVerificacion> createState() => _FilaTablaVerificacionState();
}

class _FilaTablaVerificacionState extends State<FilaTablaVerificacion> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base =
        widget.indice.isOdd
            ? Color.alphaBlend(
              cs.onSurface.withValues(alpha: 0.03),
              cs.surfaceContainerLow,
            )
            : cs.surfaceContainerLow;
    final fondo =
        _sobre
            ? Color.alphaBlend(cs.primary.withValues(alpha: 0.08), base)
            : base;

    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      child: Stack(
        children: [
          Container(
            color: fondo,
            constraints: BoxConstraints(minHeight: widget.alturaMinima),
            padding: const EdgeInsets.fromLTRB(
              Esp.l + 4,
              Esp.s,
              Esp.l,
              Esp.s,
            ),
            child: filaDeTabla(
              widget.plan,
              widget.celda,
              acciones: widget.acciones?.call(_sobre),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: ExcludeSemantics(
              child: ColoredBox(color: widget.franja),
            ),
          ),
        ],
      ),
    );
  }
}

/// Texto con puntos suspensivos; el tooltip deja leer lo cortado.
class TextoCelda extends StatelessWidget {
  const TextoCelda(this.texto, {super.key, this.estilo, this.lineas = 1});

  final String texto;
  final TextStyle? estilo;
  final int lineas;

  @override
  Widget build(BuildContext context) {
    final t = Text(
      texto,
      style: estilo,
      maxLines: lineas,
      overflow: TextOverflow.ellipsis,
    );
    return texto.isEmpty ? t : Tooltip(message: texto, child: t);
  }
}

/// El `#n` de una tarjeta.
class InsigniaFila extends StatelessWidget {
  const InsigniaFila(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: 3),
        child: Text(
          texto,
          style: context.cifraCheque(
            fuerte: true,
            color: cs.onSurfaceVariant,
            tam: 11.5,
          ),
        ),
      ),
    );
  }
}

/// Cuantas tarjetas caben por fila y que ancho tiene cada una.
({int columnas, double ancho}) disenoDeTarjetas(double ancho) {
  final columnas =
      ((ancho + Esp.m) / (anchoMinimoTarjetaVerificacion + Esp.m))
          .floor()
          .clamp(1, 3);
  // Hacia abajo: la suma nunca pasa del ancho y la ultima tarjeta no salta de
  // linea por un error de redondeo.
  final anchoTarjeta =
      math.max(0.0, ((ancho - Esp.m * (columnas - 1)) / columnas).floorToDouble());
  return (columnas: columnas, ancho: anchoTarjeta);
}
