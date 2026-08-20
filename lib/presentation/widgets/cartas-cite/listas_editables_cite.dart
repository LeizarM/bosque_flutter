import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:flutter/material.dart';

/// Una fila editable de las tres listas del documento: destinatarios del
/// encabezado ("Copia a:"), copias de archivo del pie ("cc/Arch") y remitentes
/// que firman.
///
/// El módulo JSF resolvía esto con tres `dataTable` de PrimeFaces editables
/// celda por celda, más un diálogo aparte para los destinatarios. Acá son tres
/// listas con el mismo comportamiento: agregar al final, editar en el lugar,
/// quitar con la X. Es menos ceremonia y funciona igual con el dedo que con el
/// mouse.
class ListaEditableCite extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final IconData icono;

  /// Cantidad de filas actuales.
  final int cantidad;

  /// Construye los campos de la fila [indice].
  final List<Widget> Function(int indice) camposDe;

  final VoidCallback? onAgregar;
  final void Function(int indice)? onQuitar;

  /// Tope de filas. Los remitentes son dos porque es lo que entra en el
  /// formato impreso; las otras dos listas no tienen límite.
  final int? maximo;

  final String textoVacio;
  final bool soloLectura;

  const ListaEditableCite({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.cantidad,
    required this.camposDe,
    this.onAgregar,
    this.onQuitar,
    this.maximo,
    required this.textoVacio,
    this.soloLectura = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lleno = maximo != null && cantidad >= maximo!;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      padding: EdgeInsets.all(Esp.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: cs.onSurfaceVariant),
              SizedBox(width: Esp.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: context.tituloSeccion()),
                    Text(descripcion, style: context.apagado()),
                  ],
                ),
              ),
              if (!soloLectura)
                TextButton.icon(
                  onPressed: lleno ? null : onAgregar,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(lleno ? 'Máximo $maximo' : 'Agregar'),
                ),
            ],
          ),
          if (cantidad == 0) ...[
            SizedBox(height: Esp.s),
            Text(textoVacio, style: context.apagado()),
          ] else
            ...List.generate(cantidad, (i) {
              return Padding(
                padding: EdgeInsets.only(top: Esp.s),
                child: LayoutBuilder(
                  builder: (context, cons) {
                    final campos = camposDe(i);
                    final apretado = cons.maxWidth < 520;

                    final quitar = soloLectura
                        ? const SizedBox.shrink()
                        : IconButton(
                            tooltip: 'Quitar',
                            icon: const Icon(Icons.close, size: 18),
                            visualDensity: VisualDensity.compact,
                            onPressed: onQuitar == null ? null : () => onQuitar!(i),
                          );

                    // En pantalla angosta los campos de una misma fila se
                    // apilan: dos campos de texto lado a lado en un teléfono
                    // dejan ~120 px cada uno, donde no entra ni un cargo.
                    if (apretado && campos.length > 1) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                for (var k = 0; k < campos.length; k++) ...[
                                  if (k > 0) SizedBox(height: Esp.s),
                                  campos[k],
                                ],
                              ],
                            ),
                          ),
                          quitar,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var k = 0; k < campos.length; k++) ...[
                          if (k > 0) SizedBox(width: Esp.s),
                          Expanded(flex: k == 0 ? 3 : 2, child: campos[k]),
                        ],
                        quitar,
                      ],
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Campo de texto compacto para las filas de las listas.
class CampoFila extends StatelessWidget {
  final TextEditingController controller;
  final String etiqueta;
  final int? maxLargo;
  final bool soloLectura;

  const CampoFila({
    super.key,
    required this.controller,
    required this.etiqueta,
    this.maxLargo,
    this.soloLectura = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: soloLectura,
      maxLength: maxLargo,
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        labelText: etiqueta,
        isDense: true,
        counterText: '',
        border: const OutlineInputBorder(),
      ),
    );
  }
}
