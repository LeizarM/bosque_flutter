import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:flutter/material.dart';

/// El listado mientras la consulta viaja.
///
/// ## Por qué no un spinner
///
/// El spinner centrado dice «esperá» y nada más: la pantalla queda en blanco,
/// el alto salta cuando llegan los datos, y no se sabe si vienen tres filas o
/// veinte. El esqueleto dibuja la forma que va a tener el resultado, así que la
/// página no se mueve al llegar y el ojo ya sabe dónde va a estar el número de
/// CITE antes de que exista.
///
/// ## Por qué está hecho a mano
///
/// `shimmer` sería una dependencia nueva para animar seis rectángulos. Acá hay
/// un solo `AnimationController` para todo el bloque —no uno por rectángulo— y
/// el color sale del tema, así que funciona igual en claro y en oscuro con las
/// nueve semillas.
///
/// Si el sistema pide menos movimiento, el latido no arranca: quedan los
/// rectángulos quietos, que siguen comunicando la forma.
class EsqueletoListaCite extends StatefulWidget {
  final Aire aire;

  /// Cuántas filas dibujar. Por defecto, media pantalla.
  final int filas;

  const EsqueletoListaCite({super.key, required this.aire, this.filas = 6});

  @override
  State<EsqueletoListaCite> createState() => _EsqueletoListaCiteState();
}

class _EsqueletoListaCiteState extends State<EsqueletoListaCite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _latido = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `disableAnimations` es la preferencia de accesibilidad del sistema
    // operativo, no una opción de la app. Un latido continuo es exactamente lo
    // que esa preferencia existe para apagar.
    final quieto = MediaQuery.disableAnimationsOf(context);
    if (quieto && _latido.isAnimating) {
      _latido.stop();
    } else if (!quieto && !_latido.isAnimating) {
      _latido.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _latido.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final padding = EdgeInsets.symmetric(
      horizontal: widget.aire.esChico ? Esp.m : Esp.xl,
    );

    return AnimatedBuilder(
      animation: _latido,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_latido.value);
        final tinta = Color.lerp(
          cs.surfaceContainerHigh,
          cs.surfaceContainerHighest,
          t,
        )!;

        if (widget.aire == Aire.amplio) {
          return SingleChildScrollView(
            padding: padding,
            child: _marco(
              cs,
              Column(
                children: [
                  for (var i = 0; i < widget.filas; i++) _filaTabla(tinta, i),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: padding.copyWith(bottom: Esp.xxl),
          itemCount: widget.filas,
          separatorBuilder: (_, __) => SizedBox(height: Esp.s),
          itemBuilder: (_, __) => _marco(cs, _tarjeta(tinta)),
        );
      },
    );
  }

  Widget _marco(ColorScheme cs, Widget hijo) => Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(Esquina.media),
        ),
        clipBehavior: Clip.antiAlias,
        child: hijo,
      );

  Widget _filaTabla(Color tinta, int indice) => Container(
        padding: EdgeInsets.symmetric(horizontal: Esp.l, vertical: Esp.m),
        decoration: BoxDecoration(
          border: indice == 0
              ? null
              : Border(top: BorderSide(color: context.cs.outlineVariant)),
        ),
        child: Row(
          children: [
            _barra(tinta, ancho: 36, alto: 36, radio: Esquina.chica),
            SizedBox(width: Esp.m),
            Expanded(flex: 3, child: _dosLineas(tinta)),
            SizedBox(width: Esp.l),
            Expanded(flex: 4, child: _barra(tinta, alto: 12)),
            SizedBox(width: Esp.l),
            Expanded(flex: 2, child: _barra(tinta, alto: 12)),
            SizedBox(width: Esp.l),
            _barra(tinta, ancho: 84, alto: 22, radio: Esquina.pastilla),
          ],
        ),
      );

  Widget _tarjeta(Color tinta) => Padding(
        padding: EdgeInsets.all(Esp.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _barra(tinta, ancho: 44, alto: 44, radio: Esquina.chica),
            SizedBox(width: Esp.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dosLineas(tinta),
                  SizedBox(height: Esp.m),
                  _barra(tinta, alto: 10),
                  SizedBox(height: Esp.s),
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    alignment: Alignment.centerLeft,
                    child: _barra(tinta, alto: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _dosLineas(Color tinta) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FractionallySizedBox(
            widthFactor: 0.75,
            alignment: Alignment.centerLeft,
            child: _barra(tinta, alto: 14),
          ),
          SizedBox(height: Esp.xs + 2),
          FractionallySizedBox(
            widthFactor: 0.45,
            alignment: Alignment.centerLeft,
            child: _barra(tinta, alto: 10),
          ),
        ],
      );

  Widget _barra(
    Color tinta, {
    double? ancho,
    required double alto,
    double radio = Esquina.chica,
  }) =>
      Container(
        width: ancho,
        height: alto,
        decoration: BoxDecoration(
          color: tinta,
          borderRadius: BorderRadius.circular(radio),
        ),
      );
}
