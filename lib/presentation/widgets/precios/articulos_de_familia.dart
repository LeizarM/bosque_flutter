/// Los artículos del catálogo (tpr_articulo) de una familia: los que cambian de
/// precio cuando la familia se reprecia. Se ven en el paso de familias y en el
/// editor de la familia.
///
/// Precio por artículo: la propuesta guarda el precio por tonelada de cada lista;
/// al aprobarla, cada artículo toma ese precio dividido por su UTM (unidades por
/// tonelada), igual que la vista preliminar. Por eso se muestra la UTM.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/articulo_precio_entity.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_detalle_piezas.dart';

/// La UTM puede tener varios decimales: con dos, una UTM chica se leia "0".
final NumberFormat _fmtUtm = NumberFormat('#,##0.####', 'es');

/// Como se explica, en una linea, que pasa con estos articulos.
const String textoPrecioDeArticulos =
    'Al aprobar la propuesta, cada artículo toma el precio por tonelada de '
    'cada lista dividido por su UTM.';

/// Abre la lista de articulos de una familia: dialogo en escritorio, hoja en
/// el telefono.
Future<void> mostrarArticulosDeFamilia(
  BuildContext context, {
  required int codigoFamilia,
  required String descripcion,
  required List<ArticuloPrecioEntity> articulos,
}) {
  final pantalla = MediaQuery.sizeOf(context);
  final compacto = pantalla.width < 600;
  final contenido = _PanelArticulos(
    codigoFamilia: codigoFamilia,
    descripcion: descripcion,
    articulos: articulos,
    compacto: compacto,
  );

  if (compacto) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => FractionallySizedBox(heightFactor: 0.85, child: contenido),
    );
  }
  return showDialog<void>(
    context: context,
    builder:
        (_) => Dialog(
          insetPadding: const EdgeInsets.all(Esp.xl),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: pantalla.width < 1000 ? pantalla.width : 920,
            height: pantalla.height * 0.8,
            child: contenido,
          ),
        ),
  );
}

class _PanelArticulos extends StatelessWidget {
  const _PanelArticulos({
    required this.codigoFamilia,
    required this.descripcion,
    required this.articulos,
    required this.compacto,
  });

  final int codigoFamilia;
  final String descripcion;
  final List<ArticuloPrecioEntity> articulos;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final n = articulos.length;

    return Material(
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.s, Esp.s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Artículos de la familia $codigoFamilia',
                        style: tt.titleMedium?.copyWith(fontWeight: Peso.dato),
                      ),
                      if (descripcion.trim().isNotEmpty)
                        Text(descripcion, style: context.apagado()),
                      const SizedBox(height: Esp.xs),
                      Text(
                        n == 0
                            ? 'Ningún artículo del catálogo pertenece a esta '
                                'familia.'
                            : '${n == 1 ? 'Un artículo cambia' : '$n artículos cambian'} '
                                'de precio con la familia. $textoPrecioDeArticulos',
                        style: context.apagado(),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),
          Expanded(
            child: ListaArticulosFamilia(
              articulos: articulos,
              compacto: compacto,
            ),
          ),
        ],
      ),
    );
  }
}

/// La lista de articulos, con buscador cuando son muchos. En escritorio una
/// tabla; en el telefono, renglones de dos lineas.
class ListaArticulosFamilia extends StatefulWidget {
  const ListaArticulosFamilia({
    super.key,
    required this.articulos,
    required this.compacto,
    this.relleno = const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.l, Esp.m),
  });

  final List<ArticuloPrecioEntity> articulos;
  final bool compacto;
  final EdgeInsets relleno;

  @override
  State<ListaArticulosFamilia> createState() => _ListaArticulosFamiliaState();
}

class _ListaArticulosFamiliaState extends State<ListaArticulosFamilia> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (widget.articulos.isEmpty) {
      return const MensajeVacio(
        icono: Icons.inventory_outlined,
        titulo: 'La familia no tiene artículos',
        detalle:
            'El precio por tonelada se propone igual, pero ningún artículo del '
            'catálogo lo toma. Si falta alguno, actualícelo desde SAP.',
      );
    }

    final ordenados = List<ArticuloPrecioEntity>.of(widget.articulos)
      ..sort((a, b) => a.codArticulo.compareTo(b.codArticulo));
    final texto = _busqueda.trim().toLowerCase();
    final visibles = [
      for (final a in ordenados)
        if (texto.isEmpty ||
            a.codArticulo.toLowerCase().contains(texto) ||
            a.datoArt.toLowerCase().contains(texto))
          a,
    ];

    final buscador =
        ordenados.length > 8
            ? Padding(
              padding: EdgeInsets.fromLTRB(
                widget.relleno.left,
                widget.relleno.top,
                widget.relleno.right,
                Esp.s,
              ),
              child: BuscadorPropuesta(
                texto: _busqueda,
                pista: 'Código o descripción',
                ancho: widget.compacto ? null : 320,
                alCambiar: (t) => setState(() => _busqueda = t),
              ),
            )
            : null;

    final cuerpo =
        visibles.isEmpty
            ? Center(
              child: Text(
                'Ningún artículo coincide con "${_busqueda.trim()}".',
                style: context.apagado(),
              ),
            )
            : widget.compacto
            ? ListView.separated(
              padding: EdgeInsets.fromLTRB(
                widget.relleno.left,
                buscador == null ? widget.relleno.top : 0,
                widget.relleno.right,
                widget.relleno.bottom,
              ),
              itemCount: visibles.length,
              separatorBuilder:
                  (_, __) => Divider(height: 1, color: cs.outlineVariant),
              itemBuilder: (context, i) => _Renglon(articulo: visibles[i]),
            )
            : Padding(
              padding: EdgeInsets.fromLTRB(
                widget.relleno.left,
                buscador == null ? widget.relleno.top : 0,
                widget.relleno.right,
                widget.relleno.bottom,
              ),
              child: TablaPropuesta<ArticuloPrecioEntity>(
                filas: visibles,
                columnas: [
                  ColumnaPropuesta(
                    'Código',
                    190,
                    (c, a) => celdaTexto(c, a.codArticulo, fuerte: true),
                    alinear: Alignment.centerLeft,
                  ),
                  ColumnaPropuesta(
                    'Descripción',
                    440,
                    (c, a) => celdaTexto(c, a.datoArt, maxLineas: 2),
                    alinear: Alignment.centerLeft,
                  ),
                  ColumnaPropuesta(
                    'UTM',
                    96,
                    (c, a) => celdaNumero(c, _fmtUtm.format(a.utm)),
                    ayuda:
                        'Unidades por tonelada: el precio por tonelada '
                        'dividido por la UTM es el precio del artículo.',
                  ),
                  ColumnaPropuesta(
                    'Stock',
                    96,
                    (c, a) => celdaNumero(c, fmtCantidad.format(a.stock)),
                  ),
                ],
              ),
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [if (buscador != null) buscador, Expanded(child: cuerpo)],
    );
  }
}

class _Renglon extends StatelessWidget {
  const _Renglon({required this.articulo});

  final ArticuloPrecioEntity articulo;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Esp.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            articulo.codArticulo,
            style: tt.bodyMedium?.copyWith(fontWeight: Peso.titulo),
          ),
          Text(articulo.datoArt, style: tt.bodySmall),
          const SizedBox(height: 2),
          Text(
            'UTM ${_fmtUtm.format(articulo.utm)} · Stock '
            '${fmtCantidad.format(articulo.stock)}',
            style: context.apagado(),
          ),
        ],
      ),
    );
  }
}

/// La cantidad de articulos de una familia como boton: lo toca y ve cuales.
/// Mientras se cargan, una rayita; si la lectura fallo, nada que tocar.
class BotonArticulos extends StatelessWidget {
  const BotonArticulos({
    super.key,
    required this.articulos,
    required this.onVer,
  });

  /// Null mientras se cargan o si la lectura fallo.
  final List<ArticuloPrecioEntity>? articulos;
  final VoidCallback onVer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lista = articulos;
    if (lista == null) {
      return Text('…', style: context.apagado());
    }
    final n = lista.length;
    return Tooltip(
      message:
          n == 0
              ? 'Ningún artículo del catálogo pertenece a esta familia'
              : 'Ver ${n == 1 ? 'el artículo' : 'los $n artículos'} que '
                  'cambian de precio con la familia',
      child: TextButton(
        onPressed: onVer,
        style: TextButton.styleFrom(
          foregroundColor: n == 0 ? cs.onSurfaceVariant : cs.primary,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: Esp.s),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        // Se achica en vez de cortarse: "860 artículos" no entraba en la
        // columna y quedaba "860 artícul".
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                n == 0 ? Icons.inventory_outlined : Icons.inventory_2_outlined,
                size: 16,
              ),
              const SizedBox(width: Esp.xs),
              Text(n == 1 ? '1 artículo' : '$n artículos', maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }
}

/// Los articulos agrupados por familia, a partir de la lectura de varias.
Map<int, List<ArticuloPrecioEntity>> articulosPorFamilia(
  List<ArticuloPrecioEntity> articulos,
) {
  final r = <int, List<ArticuloPrecioEntity>>{};
  for (final a in articulos) {
    (r[a.codigoFamilia] ??= <ArticuloPrecioEntity>[]).add(a);
  }
  return r;
}
