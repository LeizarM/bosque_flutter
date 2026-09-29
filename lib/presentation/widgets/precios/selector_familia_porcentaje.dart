/// El buscador de familias de la pantalla de porcentajes.
///
/// **Por que no un `DropdownMenu` ni un `ComboBuscable`.** El catalogo de
/// familias es la tabla mas grande del modulo y el desplegable de Material
/// construye TODAS sus entradas al abrirse: con cientos de familias, el menu
/// tarda y encima se dibuja sobre el campo, asi que en un telefono tapa lo que
/// se esta escribiendo. Aca la lista se construye perezosa
/// (`ListView.builder`), el filtro corre sobre texto ya normalizado y el
/// resultado se muestra en la superficie que corresponde a cada tamanio: un
/// dialogo acotado en escritorio, una hoja inferior en el telefono.
///
/// Busca por codigo y por descripcion a la vez: quien conoce la familia escribe
/// "212" y quien no, escribe "bond".
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/precios/familia_vista.dart';

/// Abre el buscador y devuelve la familia elegida, o null si se cerro sin
/// elegir.
///
/// [compacto] llega desde el LayoutBuilder de la pantalla -el ancho del cajon,
/// no el de la ventana- y decide la superficie: hoja inferior, que es lo que se
/// alcanza con el pulgar, o dialogo centrado, porque una hoja estirada de punta
/// a punta de un monitor de 1920 px es ilegible.
Future<FamiliaVista?> elegirFamiliaPorcentaje(
  BuildContext context, {
  required List<FamiliaVista> familias,
  required bool compacto,
  int? seleccionada,
}) {
  final buscador = _BuscadorFamilias(
    familias: familias,
    seleccionada: seleccionada,
  );

  if (compacto) {
    return showModalBottomSheet<FamiliaVista>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(heightFactor: 0.9, child: buscador),
    );
  }

  return showDialog<FamiliaVista>(
    context: context,
    builder:
        (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
            child: buscador,
          ),
        ),
  );
}

class _BuscadorFamilias extends StatefulWidget {
  const _BuscadorFamilias({required this.familias, this.seleccionada});

  final List<FamiliaVista> familias;
  final int? seleccionada;

  @override
  State<_BuscadorFamilias> createState() => _BuscadorFamiliasState();
}

class _BuscadorFamiliasState extends State<_BuscadorFamilias> {
  final _ctrl = TextEditingController();
  String _busqueda = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<FamiliaVista> get _visibles {
    final aguja = _busqueda.trim().toLowerCase();
    if (aguja.isEmpty) return widget.familias;
    return [
      for (final f in widget.familias)
        if (f.textoBuscable.contains(aguja)) f,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final visibles = _visibles;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Esp.l, Esp.l, Esp.l, Esp.s),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Elegir familia',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Esp.l, 0, Esp.l, Esp.m),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Código o descripción…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (t) => setState(() => _busqueda = t),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child:
              visibles.isEmpty
                  ? const MensajeVacio(
                    icono: Icons.search_off,
                    titulo: 'Ninguna familia coincide',
                    detalle:
                        'La búsqueda mira el código y la descripción de las '
                        'familias ya traídas del servidor.',
                  )
                  : ListView.builder(
                    // Perezosa a proposito: el catalogo de familias es largo y
                    // construirlo entero al abrir el buscador se nota.
                    itemCount: visibles.length,
                    itemBuilder: (context, i) {
                      final f = visibles[i];
                      return ListTile(
                        selected: f.codigoFamilia == widget.seleccionada,
                        leading: CircleAvatar(
                          child: Text(
                            f.codigoLegible,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        title: Text(f.descripcion),
                        subtitle: Text(
                          FamiliaVista.oGuion(f.proveedorSap),
                          overflow: TextOverflow.ellipsis,
                        ),
                        // La familia inactiva se puede elegir igual: sigue
                        // teniendo precios y porcentajes cargados, y esconderla
                        // haria creer que no existen.
                        trailing:
                            f.esActiva
                                ? null
                                : const Etiqueta(texto: 'Inactiva'),
                        onTap: () => Navigator.pop(context, f),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
