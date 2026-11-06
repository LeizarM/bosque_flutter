/// El desplazamiento único de una pantalla del módulo Horas Extras y el
/// relleno horizontal que las listas de adentro pueden atravesar.
library;

import 'package:flutter/material.dart';

/// El relleno horizontal que la página pone alrededor de su contenido. Una
/// lista que se desplaza de lado lo lee para llegar hasta el borde de la
/// pantalla y no cortarse en la línea del relleno.
class SangriaHex extends InheritedWidget {
  const SangriaHex({super.key, required this.valor, required super.child});

  final double valor;

  /// La sangría de la página que contiene a [context]; 0 si no hay.
  static double de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SangriaHex>()?.valor ?? 0;

  @override
  bool updateShouldNotify(SangriaHex old) => valor != old.valor;
}

/// El desplazamiento único de una pantalla: barra, controlador primario (la
/// pantalla lo provee sobre su `Scaffold`) y teclado que se cierra al arrastrar.
/// El [relleno] rodea el contenido; [abajo] suma la barra de navegación.
class PaginaDesplazableHex extends StatelessWidget {
  const PaginaDesplazableHex({
    super.key,
    required this.controlador,
    required this.relleno,
    required this.abajo,
    required this.child,
  });

  final ScrollController controlador;
  final double relleno;
  final double abajo;
  final Widget child;

  @override
  Widget build(BuildContext context) => SangriaHex(
    valor: relleno,
    child: Scrollbar(
      controller: controlador,
      child: SingleChildScrollView(
        primary: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          relleno,
          relleno,
          relleno,
          relleno + abajo,
        ),
        child: child,
      ),
    ),
  );
}
