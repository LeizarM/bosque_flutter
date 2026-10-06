// Destino final: lib/core/ui/cerrar_ruta.dart
import 'package:flutter/material.dart';

/// Cierra una ruta soltando el foco ANTES de desmontarla.
///
/// **Por qué existe.** En Flutter web, cerrar una hoja o un diálogo que tiene
/// el foco dentro de un campo de texto revienta con:
///
/// ```
/// Cannot get renderObject of inactive element.
/// The findRenderObject() method was called for the following element: Focus
///   at get rect (focus_manager.dart)
///   at _ReadingOrderSortData
///   at ReadingOrderTraversalPolicy.sortDescendants
///   at findFirstFocus  ←  didChangeViewFocus  ←  handleViewFocusChanged
/// ```
///
/// La secuencia es esta: el `<input>` del DOM desaparece con la ruta, el
/// navegador avisa que cambió el foco de la vista, y Flutter sale a buscar a
/// quién dárselo ordenando los descendientes por posición en pantalla. Para
/// ordenarlos les pide el rectángulo, o sea el `renderObject` — y el nodo que
/// acaba de irse con la ruta ya no tiene ninguno.
///
/// Soltando el foco primero, el foco se mueve a un nodo que sigue montado y el
/// recorrido nunca toca al que se está desmontando.
///
/// `primaryFocus` y no `FocusScope.of(context).unfocus()`: el que hay que
/// soltar es el nodo que REALMENTE tiene el foco, que puede estar en un scope
/// hijo (un campo dentro de un `Form` dentro de la hoja).
/// **Y no cierra lo que no se puede cerrar.** Los flujos que se abren desde el
/// menú —Caja Fuerte, Coches, Caja Chica— entran con `go`, así que su pantalla
/// es la ÚNICA página de la pila y no hay nada atrás. El `pop` de ahí revienta
/// con "You have popped the last page off of the stack, there are no pages left
/// to show" (Marcelo, 2026-10-05, al cerrar la tarea de Caja Fuerte desde el
/// menú). Cuando no hay a dónde volver, la pantalla se queda: la tarea ya quedó
/// cerrada en el servidor y el aviso lo dice.
void cerrarRuta<T extends Object?>(BuildContext context, [T? resultado]) {
  FocusManager.instance.primaryFocus?.unfocus();
  final navegador = Navigator.of(context);
  if (!navegador.canPop()) return;
  navegador.pop<T>(resultado);
}
