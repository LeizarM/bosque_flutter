import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/cartas-cite/html_cite.dart';
import 'package:flutter/material.dart';

/// Editor del cuerpo del documento.
///
/// ## La decisión de diseño, dicha de frente
///
/// El campo de texto contiene **el HTML**, y la barra de arriba es la que pone
/// las etiquetas: quien redacta selecciona y aprieta **N**, nunca escribe un
/// `<strong>` a mano. Al lado (o en la otra pestaña, en pantalla angosta) está
/// la vista previa, que muestra exactamente lo que va a salir impreso.
///
/// **Por qué no un WYSIWYG de verdad.** Haría falta `flutter_quill` más un
/// conversor Delta→HTML y otro HTML→Delta para poder abrir los ~780 documentos
/// que ya existen. Son tres dependencias nuevas y un round-trip lossy sobre
/// documentos que ya se archivaron en papel: si la conversión pierde una
/// negrita, la carta reimpresa deja de coincidir con la original.
///
/// El precio de esta decisión es que se ven las etiquetas mientras se escribe.
/// La vista previa al lado lo compensa, y el botón de formato hace que nadie
/// tenga que aprender HTML para escribir una carta.
class EditorCuerpoCite extends StatefulWidget {
  final TextEditingController controller;
  final bool soloLectura;

  /// Alto del área de edición. En el diálogo de escritorio conviene fijarlo;
  /// en móvil el editor ocupa lo que le den.
  final double? alto;

  const EditorCuerpoCite({
    super.key,
    required this.controller,
    this.soloLectura = false,
    this.alto,
  });

  @override
  State<EditorCuerpoCite> createState() => _EditorCuerpoCiteState();
}

class _EditorCuerpoCiteState extends State<EditorCuerpoCite> {
  final _focus = FocusNode();
  bool _mostrandoPrevia = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// Envuelve la selección con la etiqueta. Sin selección, deja el cursor
  /// entre la apertura y el cierre para que se pueda seguir escribiendo ya
  /// formateado.
  void _envolver(String etiqueta) {
    final ctrl = widget.controller;
    final sel = ctrl.selection;
    final texto = ctrl.text;

    final apertura = '<$etiqueta>';
    final cierre = '</$etiqueta>';

    if (!sel.isValid) {
      ctrl.text = texto + apertura + cierre;
      ctrl.selection = TextSelection.collapsed(
        offset: ctrl.text.length - cierre.length,
      );
      _focus.requestFocus();
      return;
    }

    final inicio = sel.start;
    final fin = sel.end;
    final seleccionado = texto.substring(inicio, fin);

    final nuevo = texto.replaceRange(inicio, fin, '$apertura$seleccionado$cierre');
    ctrl.value = TextEditingValue(
      text: nuevo,
      selection: TextSelection.collapsed(
        offset: inicio + apertura.length + seleccionado.length + cierre.length,
      ),
    );
    _focus.requestFocus();
  }

  void _insertar(String fragmento, {int retroceso = 0}) {
    final ctrl = widget.controller;
    final sel = ctrl.selection;
    final texto = ctrl.text;
    final pos = sel.isValid ? sel.start : texto.length;
    final fin = sel.isValid ? sel.end : texto.length;

    final nuevo = texto.replaceRange(pos, fin, fragmento);
    ctrl.value = TextEditingValue(
      text: nuevo,
      selection: TextSelection.collapsed(
        offset: pos + fragmento.length - retroceso,
      ),
    );
    _focus.requestFocus();
  }

  /// Pasa el contenido a HTML bien formado. Es lo mismo que se hace al guardar,
  /// pero acá el usuario ve el resultado y puede corregirlo.
  void _ordenar() {
    final ctrl = widget.controller;
    ctrl.text = normalizarCuerpo(ctrl.text);
    ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        final aire = Aire.de(cons.maxWidth);
        // Con menos de ~900 px la previa al lado deja dos columnas ilegibles;
        // ahí pasa a ser una pestaña.
        final ladoALado = cons.maxWidth >= 900 && !widget.soloLectura;

        final editor = _CampoHtml(
          controller: widget.controller,
          focus: _focus,
          soloLectura: widget.soloLectura,
          onCambio: () => setState(() {}),
        );

        final previa = _PanelPrevia(html: widget.controller.text);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.soloLectura)
              _BarraFormato(
                compacta: aire.esChico,
                onNegrita: () => _envolver('strong'),
                onCursiva: () => _envolver('em'),
                onSubrayado: () => _envolver('u'),
                onTachado: () => _envolver('s'),
                onParrafo: () => _insertar('<p></p>', retroceso: 4),
                onSalto: () => _insertar('<br>'),
                onLista: () => _insertar('<ul><li></li></ul>', retroceso: 10),
                onOrdenar: _ordenar,
                mostrandoPrevia: _mostrandoPrevia,
                puedeAlternar: !ladoALado,
                onAlternarPrevia: () =>
                    setState(() => _mostrandoPrevia = !_mostrandoPrevia),
              ),
            SizedBox(height: Esp.s),
            SizedBox(
              height: widget.alto,
              child: widget.soloLectura
                  ? previa
                  : ladoALado
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: editor),
                            SizedBox(width: Esp.m),
                            Expanded(child: previa),
                          ],
                        )
                      : (_mostrandoPrevia ? previa : editor),
            ),
            if (!widget.soloLectura) ...[
              SizedBox(height: Esp.xs),
              Text(
                ladoALado
                    ? 'A la izquierda se escribe, a la derecha se ve cómo sale impreso.'
                    : 'Usá los botones de formato; el ojo muestra cómo sale impreso.',
                style: context.apagado(),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CampoHtml extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final bool soloLectura;
  final VoidCallback onCambio;

  const _CampoHtml({
    required this.controller,
    required this.focus,
    required this.soloLectura,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      focusNode: focus,
      readOnly: soloLectura,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      keyboardType: TextInputType.multiline,
      onChanged: (_) => onCambio(),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
      decoration: InputDecoration(
        alignLabelWithHint: true,
        hintText: 'Escribí el contenido del documento…',
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        contentPadding: EdgeInsets.all(Esp.m),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Esquina.chica)),
      ),
    );
  }
}

class _PanelPrevia extends StatelessWidget {
  final String html;
  const _PanelPrevia({required this.html});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      padding: EdgeInsets.all(Esp.l),
      child: SingleChildScrollView(
        child: VistaHtmlCite(html: html),
      ),
    );
  }
}

class _BarraFormato extends StatelessWidget {
  final bool compacta;
  final VoidCallback onNegrita;
  final VoidCallback onCursiva;
  final VoidCallback onSubrayado;
  final VoidCallback onTachado;
  final VoidCallback onParrafo;
  final VoidCallback onSalto;
  final VoidCallback onLista;
  final VoidCallback onOrdenar;
  final bool mostrandoPrevia;
  final bool puedeAlternar;
  final VoidCallback onAlternarPrevia;

  const _BarraFormato({
    required this.compacta,
    required this.onNegrita,
    required this.onCursiva,
    required this.onSubrayado,
    required this.onTachado,
    required this.onParrafo,
    required this.onSalto,
    required this.onLista,
    required this.onOrdenar,
    required this.mostrandoPrevia,
    required this.puedeAlternar,
    required this.onAlternarPrevia,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget boton(IconData icono, String tooltip, VoidCallback onTap) => IconButton(
          icon: Icon(icono, size: 18),
          tooltip: tooltip,
          onPressed: onTap,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            foregroundColor: cs.onSurfaceVariant,
            minimumSize: const Size(36, 36),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      padding: EdgeInsets.symmetric(horizontal: Esp.xs, vertical: Esp.xs),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          boton(Icons.format_bold, 'Negrita', onNegrita),
          boton(Icons.format_italic, 'Cursiva', onCursiva),
          boton(Icons.format_underlined, 'Subrayado', onSubrayado),
          boton(Icons.format_strikethrough, 'Tachado', onTachado),
          const _Separador(),
          boton(Icons.segment, 'Nuevo párrafo', onParrafo),
          boton(Icons.keyboard_return, 'Salto de línea', onSalto),
          boton(Icons.format_list_bulleted, 'Lista', onLista),
          const _Separador(),
          boton(Icons.auto_fix_high, 'Ordenar el formato', onOrdenar),
          if (puedeAlternar)
            boton(
              mostrandoPrevia ? Icons.edit : Icons.visibility,
              mostrandoPrevia ? 'Volver a escribir' : 'Ver cómo sale impreso',
              onAlternarPrevia,
            ),
        ],
      ),
    );
  }
}

class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: Esp.xs),
        child: SizedBox(
          height: 20,
          child: VerticalDivider(
            width: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      );
}
