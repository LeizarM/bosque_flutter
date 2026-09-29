/// Encabezados arriba, lista que ocupa el resto y, opcionalmente, una barra
/// abajo. Si el alto no alcanza (teclado abierto: 100-150 px), encabezados y
/// barra pasan a franjas con scroll de a lo sumo 40 % y 30 % del alto. El árbol
/// es el mismo en ambos modos: si cambiara, el buscador perdería el foco al
/// abrirse el teclado y este se cerraría.
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
