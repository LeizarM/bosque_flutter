/// Las acciones sobre una familia que no dependen de la forma en que este
/// dibujada: la tabla de escritorio las pone en linea y la tarjeta de movil en
/// su menu contextual, pero hacen lo mismo.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/presentation/widgets/precios/familia_vista.dart';

/// Lo que se hace sobre una familia desde su fila. Lo resuelve la pantalla:
/// la tabla y la tarjeta solo lo piden.
enum AccionFamilia {
  abrir,
  nuevaDesde,
  historial,
  asignarSap,
  cambiarEstado,
  eliminar,
  copiar,
}

/// Los items de menu de las acciones que no van como boton en la tabla. La
/// tarjeta de movil agrega el historial, que en escritorio tiene su boton.
List<PopupMenuEntry<AccionFamilia>> itemsAccionesFamilia(
  FamiliaVista familia, {
  bool conHistorial = false,
}) => [
  if (conHistorial)
    const PopupMenuItem(
      value: AccionFamilia.historial,
      child: _Item(Icons.timeline_outlined, 'Historial del costo'),
    ),
  const PopupMenuItem(
    value: AccionFamilia.asignarSap,
    child: _Item(Icons.account_tree_outlined, 'Cambiar grupo o proveedor SAP'),
  ),
  PopupMenuItem(
    value: AccionFamilia.cambiarEstado,
    child:
        familia.esActiva
            ? const _Item(Icons.archive_outlined, 'Dar de baja')
            : const _Item(Icons.unarchive_outlined, 'Reactivar'),
  ),
  const PopupMenuItem(
    value: AccionFamilia.copiar,
    child: _Item(Icons.content_copy_outlined, 'Copiar código'),
  ),
  const PopupMenuDivider(),
  const PopupMenuItem(
    value: AccionFamilia.eliminar,
    child: _Item(Icons.delete_outline, 'Eliminar', destructiva: true),
  ),
];

class _Item extends StatelessWidget {
  const _Item(this.icono, this.texto, {this.destructiva = false});

  final IconData icono;
  final String texto;
  final bool destructiva;

  @override
  Widget build(BuildContext context) {
    final color = destructiva ? Theme.of(context).colorScheme.error : null;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icono, color: color),
      title: Text(texto, style: TextStyle(color: color)),
    );
  }
}

/// Copia el código de familia al portapapeles y lo avisa (se pega después en SAP
/// y en el buscador de artículos; transcribirlo a mano es donde se cambia un
/// dígito).
Future<void> copiarCodigo(BuildContext context, FamiliaVista familia) async {
  await Clipboard.setData(ClipboardData(text: familia.codigoLegible));
  if (!context.mounted) return;
  mostrarAviso(context, 'Código ${familia.codigoLegible} copiado');
}
