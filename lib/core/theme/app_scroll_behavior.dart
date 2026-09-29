import 'package:flutter/material.dart';

/// ScrollBehavior de la app: pone una scrollbar visible en TODO widget
/// scrolleable (ListView, SingleChildScrollView, CustomScrollView, etc.),
/// en cualquier pantalla, sin tener que envolver cada uno a mano.
///
/// Por qué existe: esta app corre en web y desktop, donde una scrollbar es
/// una señal de wayfinding esperada — le dice al usuario "hay más contenido
/// abajo" y le da algo de qué agarrarse con el mouse. El [ScrollBehavior]
/// default de Material solo dibuja una scrollbar bajo
/// [TargetPlatform.linux/macOS/windows] (es decir, nunca en Flutter Web
/// corriendo como si fuera móvil/táctil, que es el caso de esta app), así
/// que sin este override las pantallas con listas largas —el módulo de
/// Tareas Rutinarias entre ellas— no tenían ningún indicio visual de scroll.
///
/// Se activa una sola vez en `MaterialApp.scrollBehavior` (ver `main.dart`)
/// en lugar de envolver cada ListView/SingleChildScrollView/CustomScrollView
/// de las ~90 pantallas de la app en un `Scrollbar` manualmente.
///
/// `thumbVisibility: true` porque el estándar táctil "aparece al arrastrar,
/// se esconde después" no aplica bien aquí: en desktop/web el usuario navega
/// con mouse, no con el dedo, y con el thumb oculto por default no hay forma
/// de saber de un vistazo que una pantalla scrollea hasta que ya se está
/// arrastrando el mouse sobre ella.
/// ACOTADO 2026-09-07: la primera versión ponía una barra siempre visible en
/// TODO scrollable sin distinguir eje ni controller, y aparecían barras
/// sueltas dentro de formularios y tiras horizontales de chips — ruido, no
/// wayfinding (Marcelo, sobre el formulario de Arqueo). Ahora:
///
///  * Solo eje vertical. En horizontal (chips, tablas anchas, carruseles) una
///    barra permanente tapa contenido y no responde la pregunta "¿hay más
///    abajo?", que es la única que este override quería contestar.
///  * `thumbVisibility: true` solo si hay un controller. Scrollbar EXIGE una
///    ScrollPosition adjunta para poder dibujar el thumb siempre; sin
///    controller (scrollables internos de menús, dropdowns, popups) lanza en
///    tiempo de layout. Sin él se delega al comportamiento default, que
///    muestra la barra al scrollear.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final esVertical =
        details.direction == AxisDirection.down ||
        details.direction == AxisDirection.up;
    if (!esVertical) return child;

    if (details.controller == null) {
      return super.buildScrollbar(context, child, details);
    }

    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      child: child,
    );
  }
}
