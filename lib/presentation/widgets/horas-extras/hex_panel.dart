/// Panel de lectura del módulo Horas Extras (el detalle de un reporte, las
/// líneas de un empleado): hoja inferior en el teléfono y diálogo en el ancho.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formatos.dart';

/// Ancho máximo del diálogo en el escritorio.
const double _anchoDialogo = 720;

/// Abre [panel] en una hoja inferior en el teléfono o en un diálogo en el
/// ancho. Se decide por la ventana y no por el contenedor: se dibuja sobre
/// toda la pantalla. [panel] recibe el control de la hoja (nulo en el diálogo).
Future<void> mostrarPanelHex(
  BuildContext context, {
  required Widget Function(ScrollController? control) panel,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  final pantalla = MediaQuery.sizeOf(context);
  if (pantalla.width < hexAnchoTabla) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder:
          (_) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.92,
            minChildSize: 0.5,
            maxChildSize: 1,
            builder: (_, control) => panel(control),
          ),
    );
  }
  return showDialog<void>(
    context: context,
    builder:
        (_) => Dialog(
          insetPadding: const EdgeInsets.all(Esp.xl),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _anchoDialogo,
              maxHeight: pantalla.height * 0.9,
            ),
            child: panel(null),
          ),
        ),
  );
}

/// El cuerpo de [mostrarPanelHex]: [cabecera] fija con «Cerrar» y [hijos] en
/// una lista. En la hoja desplaza con su [control] (arrastrar la agranda); en
/// el diálogo, con uno propio y se encoge a su contenido.
class PanelHex extends StatefulWidget {
  const PanelHex({
    super.key,
    required this.control,
    required this.cabecera,
    required this.hijos,
  });

  final ScrollController? control;
  final Widget cabecera;
  final List<Widget> hijos;

  @override
  State<PanelHex> createState() => _PanelHexState();
}

class _PanelHexState extends State<PanelHex> {
  // Solo el diálogo lo necesita: en la hoja no se crea.
  ScrollController? _propio;

  ScrollController get _control =>
      widget.control ?? (_propio ??= ScrollController());

  bool get _enDialogo => widget.control == null;

  @override
  void dispose() {
    _propio?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // En la hoja, el asa de arrastre ya deja el aire de arriba.
      Padding(
        padding: EdgeInsets.fromLTRB(
          Esp.l,
          _enDialogo ? Esp.l : 0,
          Esp.s,
          Esp.s,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: widget.cabecera),
            IconButton(
              tooltip: 'Cerrar',
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                visualDensity: VisualDensity.standard,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
      const Divider(height: 1),
      Flexible(
        child: Scrollbar(
          controller: _control,
          child: ListView(
            controller: _control,
            shrinkWrap: _enDialogo,
            padding: EdgeInsets.fromLTRB(
              Esp.l,
              Esp.m,
              Esp.l,
              Esp.xl + MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: widget.hijos,
          ),
        ),
      ),
    ],
  );
}
