import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

/// Barra superior de cada pestana: busqueda a la izquierda, accion a la derecha.
///
/// En movil la accion pasa a un boton compacto para que el campo de busqueda
/// conserve un ancho utilizable.
class BarraModulo extends StatelessWidget {
  const BarraModulo({
    super.key,
    required this.textoBusqueda,
    required this.textoAccion,
    required this.alBuscar,
    required this.alPulsarAccion,
    this.filtroExtra,
    this.conteo,
  });

  final String textoBusqueda;
  final String textoAccion;
  final ValueChanged<String> alBuscar;
  final VoidCallback alPulsarAccion;

  /// Control adicional propio de la pestana, por ejemplo un selector de empresa.
  final Widget? filtroExtra;

  /// Cuantas filas hay, ya filtradas. Se oculta en movil: ahi el ancho se
  /// necesita entero para el campo de busqueda.
  final String? conteo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final esMovil = ResponsiveUtilsBosque.isMobile(context);
    final padding = ResponsiveUtilsBosque.getHorizontalPadding(context);

    final campoBusqueda = TextField(
      onChanged: alBuscar,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: textoBusqueda,
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 8, padding, 8),
      // Align + ConstrainedBox y no un ancho suelto: el Align afloja los
      // constraints para que el tope se aplique, y asi la franja termina en el
      // mismo borde que la tarjeta de abajo.
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ComisionesTema.anchoTabla,
          ),
          child: Container(
            decoration: ComisionesTema.franja(context),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: campoBusqueda,
                    ),
                  ),
                ),
                if (conteo != null && !esMovil) ...[
                  const SizedBox(width: 12),
                  Text(
                    conteo!,
                    style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
                if (filtroExtra != null) ...[
                  const SizedBox(width: 10),
                  filtroExtra!,
                ],
                const SizedBox(width: 10),
                if (esMovil)
                  IconButton.filled(
                    tooltip: textoAccion,
                    onPressed: alPulsarAccion,
                    icon: const Icon(Icons.add),
                  )
                else
                  FilledButton.icon(
                    onPressed: alPulsarAccion,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(textoAccion),
                    // El style no se borra: sin el, la pildora queda en 44 px
                    // visibles contra 48 del campo y la fila se ve desalineada. El
                    // padding ya lo pone el filledButtonTheme del modulo; lo que
                    // falta es el minimo que empareja las dos alturas.
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
