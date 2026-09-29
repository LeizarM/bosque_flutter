import 'package:flutter/widgets.dart';

/// Ancho FIJO para el contenido de un AlertDialog del modulo de precios.
///
/// AlertDialog envuelve su contenido en un IntrinsicWidth, que le pregunta el
/// ancho intrinseco a cada widget de adentro. LayoutBuilder, ListView y otros no
/// saben responderlo: el layout falla, el dialogo queda sin tamano y la UI se
/// cuelga repitiendo "Cannot hit test a render box with no size".
///
/// Un SizedBox con ancho fijo responde esa consulta el mismo, sin bajar al
/// contenido. Un ConstrainedBox con solo maxWidth NO alcanza: igual deja pasar la
/// consulta hacia adentro. Por eso todo AlertDialog del modulo con formulario usa
/// este ancho.
///
/// Criterio: el mismo de los dialogos de comisiones (90 % de la pantalla en el
/// telefono, [maximo] en escritorio). MediaQuery es correcto aca porque el
/// dialogo ocupa la ventana entera, no el cajon del dashboard. Si el valor supera
/// el espacio real, el AlertDialog lo recorta: nunca desborda.
double anchoDialogo(BuildContext context, double maximo) {
  final pantalla = MediaQuery.sizeOf(context).width;
  return pantalla < 600 ? pantalla * 0.9 : maximo;
}
