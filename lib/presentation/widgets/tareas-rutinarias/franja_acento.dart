import 'package:flutter/material.dart';

/// Contenido con una franja de color pegada al borde izquierdo, estirada a
/// todo el alto — la identidad visual por tipo de bloque del módulo Tareas
/// Rutinarias (Cortes, Documentación, Vales, SAP, Tipo de cambio, estado de
/// una ocurrencia, frecuencia de una tarea).
///
/// POR QUÉ EXISTE ESTE WIDGET (no es azúcar sintáctica)
///
/// El reflejo para "una franja del alto del contenido" es
/// `IntrinsicHeight(child: Row(crossAxisAlignment: stretch, [franja, Expanded(contenido)]))`.
/// Funciona… hasta que el contenido contiene un [LayoutBuilder].
/// IntrinsicHeight consulta las dimensiones intrínsecas de TODO su subárbol, y
/// LayoutBuilder no puede responderlas: lanza en tiempo de layout
///
///     LayoutBuilder does not support returning intrinsic dimensions.
///
/// Como varios contenidos de este módulo usan `FilaFormularioResponsiva` (que
/// es un LayoutBuilder), las tarjetas de Documentación y Vales quedaban sin
/// pintar — un recuadro gris vacío — y el fallo se propagaba a cientos de
/// "Cannot hit test a render box with no size" y a un cuelgue del
/// mouse_tracker (Marcelo, 2026-09-07).
///
/// [Stack] + [PositionedDirectional] con `top` y `bottom` fijados logra lo
/// mismo sin consultar intrínsecos de nadie: el Stack se dimensiona por su
/// hijo NO posicionado (el contenido) y la franja se estira a ese alto ya
/// resuelto. Funciona con cualquier contenido, LayoutBuilder incluido, y
/// además es más barato (IntrinsicHeight hace una pasada de layout extra).
///
/// El `SizedBox(width: double.infinity)` es necesario porque un Stack da
/// restricciones sueltas a sus hijos no posicionados: sin él la tarjeta se
/// encogería al ancho de su contenido en vez de ocupar la fila completa, que
/// es lo que hacía el `Expanded` del Row anterior.
///
/// Con [color] en null devuelve el contenido tal cual, sin envolverlo: los
/// bloques sin tono propio no pagan ni un widget de más.
class FranjaAcento extends StatelessWidget {
  /// Color de la franja. `null` = sin franja (devuelve [child] directo).
  final Color? color;

  /// Ancho de la franja. 4 en tarjetas, 3 en sub-bloques dentro de una tarjeta.
  final double ancho;

  final Widget child;

  const FranjaAcento({
    super.key,
    required this.child,
    this.color,
    this.ancho = 4,
  });

  @override
  Widget build(BuildContext context) {
    final color = this.color;
    if (color == null) return child;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: ancho),
          child: SizedBox(width: double.infinity, child: child),
        ),
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width: ancho,
          child: ColoredBox(color: color),
        ),
      ],
    );
  }
}
