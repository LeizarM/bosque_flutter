// Destino final: lib/presentation/widgets/tareas-rutinarias/fila_formulario_responsiva.dart
import 'package:flutter/material.dart';

/// Un campo dentro de [FilaFormularioResponsiva]: el widget ya armado por
/// quien lo declara (TextFormField, DropdownButtonFormField, botón de
/// fecha, lo que sea) junto con el único dato que la fila necesita de él
/// para decidir su ancho -- [minWidth]. No es un widget en sí (no tiene
/// build ni Element propio): es la especificación que
/// [FilaFormularioResponsiva] usa para calcular el layout real.
///
/// [minWidth] cumple doble función: es el ancho que el campo ocupa cuando
/// comparte línea con otros en pantallas anchas, y también el umbral que
/// decide si esa línea colapsa a columna única en pantallas angostas (ver
/// el dartdoc de [FilaFormularioResponsiva]).
@immutable
class CampoResponsivo {
  const CampoResponsivo({required this.child, this.minWidth = 160})
    : assert(minWidth > 0, 'minWidth debe ser positivo');

  /// El campo ya construido por el llamador.
  final Widget child;

  /// Ancho "natural" del campo en una fila ancha. En una fila angosta que
  /// colapsa a columna única, el campo pasa a ocupar el 100% del ancho
  /// disponible en su lugar -- ver [FilaFormularioResponsiva].
  final double minWidth;
}

/// Layout reusable para el patrón "tarjeta con varios campos de formulario
/// repetida N veces" (vales de un arqueo, movimientos de una caja chica,
/// cualquier fila repetible de tareas-rutinarias con la misma forma).
///
/// Reemplaza el patrón anterior de partir los campos a mano en filas fijas
/// (p.ej. "3 campos, después otros 3") con anchos elegidos por separado
/// para cada uno: eso rompe la alineación en cuanto cambia la cantidad de
/// campos o el largo de una etiqueta, y en la fila de vales real (Marcelo,
/// 2026-09-07, comparando capturas de escritorio y celular) el resultado
/// no era ni simétrico ni ordenado en ninguno de los dos anchos, con el
/// ícono de basurero flotando junto a la primera mitad de campos en vez de
/// quedar anclado a la tarjeta completa.
///
/// Aquí en cambio TODOS los campos viven en un único [Wrap]: es el propio
/// Wrap el que decide cuántos entran por línea según el ancho real
/// disponible, así que agregar/quitar un campo o alargar una etiqueta
/// nunca vuelve a desalinear nada a mano. Cada campo declara su propio
/// [CampoResponsivo.minWidth] y lo mantiene mientras comparte línea con
/// otros; en una pantalla angosta, cuando ni siquiera dos campos de ese
/// ancho entrarían uno junto al otro, ese campo pasa a ocupar el 100% del
/// ancho disponible -- por construcción, sin un breakpoint aparte, esto
/// hace que TODOS los campos terminen apilados a ancho completo en
/// mobile, que es exactamente el "columna única ordenada" pedido.
///
/// La acción de la fila (típicamente el ícono de borrar) se declara una
/// sola vez en [accion] y siempre queda al final de la fila exterior --
/// es decir, arriba-a-la-derecha en LTR / arriba-al-final en RTL de la
/// tarjeta completa (nunca de la primera línea de campos nada más),
/// porque el [Wrap] con todos los campos es un único hijo `Expanded` de
/// esa fila exterior, sin importar a cuántas líneas se parta.
///
/// Uso:
/// ```dart
/// FilaFormularioResponsiva(
///   accion: IconButton(
///     icon: const Icon(Icons.delete_outline),
///     tooltip: 'Quitar vale',
///     onPressed: onQuitar,
///   ),
///   campos: [
///     CampoResponsivo(minWidth: 90, child: campoNumVale),
///     CampoResponsivo(minWidth: 180, child: campoNombre),
///     CampoResponsivo(minWidth: 120, child: campoMonto),
///     CampoResponsivo(minWidth: 150, child: campoFecha),
///     CampoResponsivo(minWidth: 170, child: campoEmpresa),
///     CampoResponsivo(minWidth: 220, child: campoObservaciones),
///   ],
/// )
/// ```
class FilaFormularioResponsiva extends StatelessWidget {
  const FilaFormularioResponsiva({
    super.key,
    required this.campos,
    this.accion,
    this.espaciado = _espaciadoPorDefecto,
    this.margenInferior = 10,
    this.padding = const EdgeInsets.all(10),
  });

  /// Mismo valor que ya usaban los Wrap de arqueo_caja_screen.dart (spacing
  /// y runSpacing) antes de esta refactorización -- no es un número nuevo,
  /// es nombrarle el que ya estaba en uso en este módulo.
  static const double _espaciadoPorDefecto = 8;

  /// Los campos de esta fila, en el orden en que deben leerse.
  final List<CampoResponsivo> campos;

  /// Acción de la tarjeta completa (p.ej. borrar esta fila). Se posiciona
  /// siempre al final de la fila exterior -- arriba-a-la-derecha en LTR --
  /// sin importar cuántas líneas ocupen los campos. `null` no reserva
  /// espacio.
  final Widget? accion;

  /// Separación horizontal entre campos de una misma línea y vertical
  /// entre líneas envueltas, y también el hueco antes de [accion].
  final double espaciado;

  /// Margen inferior de la tarjeta -- para separarla de la siguiente fila
  /// en una lista de tarjetas repetidas.
  final double margenInferior;

  /// Padding interno de la tarjeta.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsetsDirectional.only(bottom: margenInferior),
      padding: padding,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double anchoDisponible = constraints.maxWidth;
                return Wrap(
                  spacing: espaciado,
                  runSpacing: espaciado,
                  children: [
                    for (final campo in campos)
                      _CampoAncho(
                        campo: campo,
                        anchoDisponible: anchoDisponible,
                        espaciado: espaciado,
                      ),
                  ],
                );
              },
            ),
          ),
          if (accion != null) ...[SizedBox(width: espaciado), accion!],
        ],
      ),
    );
  }
}

/// Le da a un [CampoResponsivo] su ancho final dentro del [Wrap] de
/// [FilaFormularioResponsiva]: su [CampoResponsivo.minWidth] si todavía
/// entran al menos dos campos de ese ancho uno junto al otro, o el 100%
/// del ancho disponible en caso contrario (columna única). El Wrap no le
/// da a sus hijos un ancho máximo acotado por sí solo -- de ahí el
/// SizedBox explícito, el mismo mecanismo que ya usaban los campos de
/// arqueo_caja_screen.dart antes de esta refactorización, solo que ahora
/// el número sale de una única decisión en vez de estar copiado a mano en
/// cada TextFormField.
class _CampoAncho extends StatelessWidget {
  const _CampoAncho({
    required this.campo,
    required this.anchoDisponible,
    required this.espaciado,
  });

  final CampoResponsivo campo;
  final double anchoDisponible;
  final double espaciado;

  @override
  Widget build(BuildContext context) {
    final bool colapsaAColumnaUnica =
        anchoDisponible.isFinite &&
        anchoDisponible < campo.minWidth * 2 + espaciado;
    final double ancho =
        colapsaAColumnaUnica ? anchoDisponible : campo.minWidth;
    return SizedBox(width: ancho, child: campo.child);
  }
}
