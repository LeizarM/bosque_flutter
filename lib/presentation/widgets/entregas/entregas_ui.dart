import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';

/// Tokens y piezas chicas compartidas por la pantalla de Entregas.
///
/// Existe para que la pantalla tenga UN solo idioma visual. Antes cada widget
/// resolvía su propio color y su propio espaciado contra el `ColorScheme`, y el
/// resultado era una pantalla con cuatro fondos de color distinto (rosa, lila,
/// verde agua) peleándose por la atención sin que ninguno significara nada.
///
/// La regla acá es: **superficies neutras, un solo acento**. El acento
/// (`colorScheme.primary`) se reserva para dos cosas y nada más — el estado de
/// ruta activa y la acción primaria. Todo lo demás son grises del tema y
/// bordes de un pelo. El color vuelve a significar algo cuando se usa poco.
class EntregasUI {
  const EntregasUI._();

  // Escala de espaciado de 4. No inventar valores intermedios.
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;

  // Radios: más suave el contenedor, más cerrado lo de adentro.
  static const double rContainer = 12;
  static const double rInner = 8;
  static const double rPill = 999;

  /// Ancho máximo del contenido. Sin esto, en un monitor ancho la tabla se
  /// estira de borde a borde y la fila queda ilegible de tan larga.
  static const double maxContentWidth = 1400;

  /// Padding horizontal del proyecto: 32 escritorio / 20 tablet / 16 móvil.
  ///
  /// Se delega en `ResponsiveUtilsBosque` en vez de usar un valor de la escala
  /// de arriba: el margen de página es una decisión de toda la app, no de este
  /// módulo, y clavarlo en 24 rompía la alineación con el resto de pantallas
  /// además de comerse 48 px de los 360 que tiene un teléfono.
  static double padH(BuildContext c) =>
      ResponsiveUtilsBosque.getHorizontalPadding(c);

  static double padV(BuildContext c) =>
      ResponsiveUtilsBosque.getVerticalPadding(c);

  /// Ancho por debajo del cual no entra "texto largo + botón" en una fila.
  /// Se mide contra el ancho real y no contra el breakpoint TABLET porque lo
  /// que importa acá es si la fila entra, no qué clase de dispositivo es.
  static bool esAngosto(BuildContext c) =>
      MediaQuery.of(c).size.width < 560;

  /// Borde de un pelo. Un divisor gris claro comunica separación sin gritar,
  /// que es lo que hacía el bloque de color de fondo.
  static Color hairline(ColorScheme cs) => cs.outlineVariant.withValues(alpha: 0.5);

  /// Fondo de una superficie elevada un escalón sobre el fondo de la página.
  static Color raised(ColorScheme cs) => cs.surfaceContainerLowest;

  /// Texto secundario: etiquetas, metadatos, todo lo que acompaña.
  static Color muted(ColorScheme cs) => cs.onSurfaceVariant;

  /// Cifras alineadas en columna. `tabularFigures` hace que el 1 ocupe lo mismo
  /// que el 8, así los números de factura no bailan de fila en fila.
  static TextStyle numeric(BuildContext context, {FontWeight? weight, Color? color}) {
    return (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      fontWeight: weight ?? FontWeight.w500,
      color: color,
    );
  }

  /// Encabezado de columna: chico, en mayúsculas, con tracking abierto y en
  /// gris. Un encabezado no compite con el dato; lo rotula.
  static TextStyle columnLabel(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: muted(cs),
    );
  }
}

/// Estado de la entrega como pastilla, no como palabra suelta en una celda.
///
/// Un texto plano "Entregado" / "Pendiente" obliga a leer para saber cómo va la
/// ruta. La pastilla se reconoce por forma y color de un vistazo, que es como
/// se lee una tabla en la calle y con el celular en una mano.
class EstadoEntregaPill extends StatelessWidget {
  final bool entregado;

  const EstadoEntregaPill({super.key, required this.entregado});

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    // Verde y ámbar desaturados a propósito: tienen que leerse como estado,
    // no competir con el botón de acción que está al lado.
    final Color fondo;
    final Color texto;
    if (entregado) {
      fondo = oscuro ? const Color(0xFF163D2A) : const Color(0xFFE7F4EC);
      texto = oscuro ? const Color(0xFF7FD4A0) : const Color(0xFF1F6B42);
    } else {
      fondo = oscuro ? const Color(0xFF3A3320) : const Color(0xFFFBF1DC);
      texto = oscuro ? const Color(0xFFE0BE72) : const Color(0xFF8A6516);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EntregasUI.s2 + 2,
        vertical: EntregasUI.s1 + 1,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(EntregasUI.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: texto, shape: BoxShape.circle),
          ),
          const SizedBox(width: EntregasUI.s2 - 2),
          // Flexible: la pastilla se usa dentro de una columna de tabla y de una
          // tarjeta de móvil. Sin esto, en la columna angosta el texto toma su
          // ancho intrínseco y desborda 57 px en vez de recortarse.
          Flexible(
            child: Text(
              entregado ? 'Entregado' : 'Pendiente',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: texto,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Esqueleto de carga con la forma de la tabla.
///
/// Reemplaza al `CircularProgressIndicator` centrado. Un spinner en el medio de
/// la pantalla no dice cuánto falta ni qué va a aparecer, y además hace saltar
/// el layout cuando llegan los datos. El esqueleto ocupa el mismo lugar que van
/// a ocupar las filas, así que la pantalla no se mueve al cargar.
class EntregasSkeleton extends StatefulWidget {
  final int filas;

  const EntregasSkeleton({super.key, this.filas = 4});

  @override
  State<EntregasSkeleton> createState() => _EntregasSkeletonState();
}

class _EntregasSkeletonState extends State<EntregasSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: EntregasUI.maxContentWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: EntregasUI.padH(context)),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              // Pulso suave. Un shimmer con gradiente en movimiento es más
              // vistoso pero también más caro, y esto se ve un segundo.
              final opacidad = 0.35 + (_c.value * 0.25);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(widget.filas, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: EntregasUI.s3),
                    child: Row(
                      children: [
                        _barra(cs, opacidad, flex: 26),
                        const SizedBox(width: EntregasUI.s4),
                        _barra(cs, opacidad, flex: 9),
                        const SizedBox(width: EntregasUI.s4),
                        _barra(cs, opacidad, flex: 11),
                        const SizedBox(width: EntregasUI.s4),
                        _barra(cs, opacidad, flex: 30),
                        const SizedBox(width: EntregasUI.s4),
                        _barra(cs, opacidad, flex: 15),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _barra(ColorScheme cs, double opacidad, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 14,
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.06 * opacidad * 2),
          borderRadius: BorderRadius.circular(EntregasUI.rInner),
        ),
      ),
    );
  }
}

/// Contador con la cifra grande y la etiqueta chica abajo.
///
/// Reemplaza al "Total de facturas: 1" en negrita sobre una franja de color:
/// ahí el número y su rótulo pesaban lo mismo, y el dato quedaba escondido
/// dentro de la oración.
class EntregasStat extends StatelessWidget {
  final String valor;
  final String etiqueta;

  const EntregasStat({super.key, required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          valor,
          style: EntregasUI.numeric(
            context,
            weight: FontWeight.w600,
          ).copyWith(fontSize: 20, height: 1.1, color: cs.onSurface),
        ),
        const SizedBox(height: 2),
        Text(etiqueta, style: EntregasUI.columnLabel(context)),
      ],
    );
  }
}
