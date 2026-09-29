import 'package:flutter/widgets.dart';

/// Ancho FIJO para el contenido de un AlertDialog del módulo de precios.
///
/// AlertDialog usa IntrinsicWidth: LayoutBuilder, ListView y similares no saben
/// responder el ancho intrínseco y la UI se cuelga con "Cannot hit test a render
/// box with no size". Un SizedBox de ancho fijo lo resuelve (un ConstrainedBox
/// con solo maxWidth NO). Criterio de comisiones: 90 % de la pantalla en
/// teléfono, [maximo] en escritorio; MediaQuery es correcto porque el diálogo
/// ocupa la ventana.
double anchoDialogo(BuildContext context, double maximo) {
  final pantalla = MediaQuery.sizeOf(context).width;
  return pantalla < 600 ? pantalla * 0.9 : maximo;
}
