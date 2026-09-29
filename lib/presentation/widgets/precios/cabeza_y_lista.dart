/// Encabezados arriba, una lista que ocupa el resto y, opcionalmente, una barra
/// abajo: la forma de casi todas las pantallas del modulo.
///
/// **El problema que resuelve.** Con alto de sobra eso es un `Column` con la
/// lista en `Expanded`. En un telefono con el teclado abierto -se abre justo al
/// tocar el buscador de arriba- al contenido le quedan 100 o 150 px, menos que
/// los encabezados solos, y el `Column` se desborda.
///
/// Cuando el alto no alcanza, los encabezados pasan a una franja con scroll
/// propio de a lo sumo el 40 % del alto (y la barra de abajo, del 30 %), y la
/// lista se queda con el resto.
///
/// **El arbol es el mismo en los dos modos**: solo cambian los topes. Si
/// cambiara, el buscador se reconstruiria al abrirse el teclado, perderia el
/// foco, el teclado se cerraria y la pantalla volveria al modo normal.
library;

import 'package:flutter/material.dart';

class CabezaYLista extends StatelessWidget {
  const CabezaYLista({
    super.key,
    required this.cabeza,
    required this.lista,
    this.pie,
    this.altoCompacto = 400,
  });

  final List<Widget> cabeza;

  /// Recibe alto acotado: puede ser un ListView.
  final Widget lista;

  final Widget? pie;

  /// Por debajo de este alto, los encabezados y la barra se acotan.
  final double altoCompacto;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, r) {
      final alto = r.maxHeight;
      final apretado = alto.isFinite && alto < altoCompacto;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: apretado ? alto * 0.4 : double.infinity,
            ),
            // primary: false para que no se cuelgue del PrimaryScrollController
            // que en el telefono ya usa la lista.
            child: SingleChildScrollView(
              primary: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: cabeza,
              ),
            ),
          ),
          Expanded(child: lista),
          if (pie != null)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: apretado ? alto * 0.3 : double.infinity,
              ),
              child: SingleChildScrollView(primary: false, child: pie),
            ),
        ],
      );
    },
  );
}
