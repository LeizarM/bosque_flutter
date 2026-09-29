// Destino final: lib/presentation/widgets/tareas-rutinarias/tabla_modulo.dart
import 'package:flutter/material.dart';

/// Ancho de una columna de tabla.
///
/// `fijo` para las columnas que tienen que alinearse entre filas (importes,
/// fechas, acciones) y `flexible` para el texto que debe absorber el ancho
/// sobrante. Es lo mismo que hace `Table` con `columnWidths`, pero expresado
/// con `SizedBox`/`Expanded` para que las filas puedan construirse una por una
/// dentro de un `ListView.builder`.
///
/// **Por qué no `Table`.** `Table` mide todas sus filas juntas: con los 125
/// movimientos que llega a tener un lote de caja chica, eso son 125 filas
/// construidas y medidas en un solo frame cada vez que algo cambia. En web se
/// nota como un tirón al abrir y al registrar.
class AnchoCol {
  final double? fijo;
  final int flex;

  const AnchoCol.fijo(double this.fijo) : flex = 0;
  const AnchoCol.flexible([this.flex = 1]) : fijo = null;
}

/// Una fila de tabla con columnas alineadas.
///
/// El contrato es que TODAS las filas de una tabla reciban la misma lista de
/// anchos; ahí está la alineación. Se pasa la lista, no un `Table`, para que
/// cada fila sea un widget independiente y la lista pueda virtualizarse.
class FilaTabla extends StatelessWidget {
  final List<AnchoCol> anchos;
  final List<Widget> celdas;
  final Color? fondo;
  final Border? borde;
  final EdgeInsetsGeometry padding;
  final CrossAxisAlignment alineacion;

  const FilaTabla({
    super.key,
    required this.anchos,
    required this.celdas,
    this.fondo,
    this.borde,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    this.alineacion = CrossAxisAlignment.center,
  }) : assert(anchos.length == celdas.length, 'una celda por columna');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: fondo, border: borde),
      padding: padding,
      child: Row(
        crossAxisAlignment: alineacion,
        children: [
          for (var i = 0; i < celdas.length; i++) ...[
            if (anchos[i].fijo != null)
              SizedBox(width: anchos[i].fijo, child: celdas[i])
            else
              Expanded(flex: anchos[i].flex, child: celdas[i]),
            if (i < celdas.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

/// El encabezado de columnas.
class EncabezadoTabla extends StatelessWidget {
  final List<AnchoCol> anchos;
  final List<String> titulos;

  /// Índices de las columnas cuyo título va alineado a la derecha — las de
  /// importes, para que el rótulo caiga sobre la unidad y no sobre el signo.
  final Set<int> aLaDerecha;

  const EncabezadoTabla({
    super.key,
    required this.anchos,
    required this.titulos,
    this.aLaDerecha = const {},
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final estilo = Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    return FilaTabla(
      anchos: anchos,
      fondo: scheme.surfaceContainerHighest,
      borde: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      celdas: [
        for (var i = 0; i < titulos.length; i++)
          Text(
            titulos[i],
            style: estilo,
            textAlign: aLaDerecha.contains(i) ? TextAlign.right : TextAlign.left,
          ),
      ],
    );
  }
}

/// El marco de la tabla: borde, esquinas y recorte.
class MarcoTabla extends StatelessWidget {
  final Widget child;

  const MarcoTabla({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
