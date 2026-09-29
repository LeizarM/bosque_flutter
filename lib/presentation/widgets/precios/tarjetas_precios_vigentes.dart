/// Los mismos precios cuando no entra una tabla: una tarjeta por lista de
/// precios, agrupadas por sucursal.
///
/// **Por que no es la tabla escalada.** En un telefono, ocho columnas se
/// resuelven de dos maneras: achicando la letra hasta que no se lee, o con
/// scroll horizontal, que obliga a recordar de que fila se estaba mirando el
/// precio. Aca cada lista es una tarjeta: lo que se consulta —cuanto vale y con
/// que porcentaje— queda a la vista, y el resto de los datos (lista SAP, id de
/// precio, IVA, IT) se abre tocando la tarjeta. Nunca hay scroll horizontal.
///
/// Con el ancho medio (una tableta, o el escritorio con el menu abierto) las
/// tarjetas van de a dos: una sola columna de tarjetas de 900 px deja el
/// precio a un metro del nombre de la lista.
///
/// **Es un sliver**, como la tabla: la ficha de la familia se va con el scroll
/// y deja la pantalla para las tarjetas.
///
/// La consulta es de solo lectura: no hay acciones por fila que meter en un
/// menu contextual. El unico gesto de la tarjeta es abrir su detalle.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/precios/precios_vigentes_datos.dart';

class TarjetasPreciosVigentes extends StatelessWidget {
  const TarjetasPreciosVigentes({
    super.key,
    required this.filas,
    required this.padding,
    this.columnas = 1,
  });

  /// Ya filtradas y ordenadas por sucursal y numero de lista.
  final List<FilaPrecioVigente> filas;
  final EdgeInsets padding;

  /// Cuantas tarjetas por renglon.
  final int columnas;

  @override
  Widget build(BuildContext context) {
    final renglones = _aplanar(agruparPorSucursal(filas), columnas);

    return SliverPadding(
      padding: padding,
      sliver: SliverList.builder(
        itemCount: renglones.length,
        itemBuilder:
            (context, i) => switch (renglones[i]) {
              final _RenglonTitulo r => _TituloSucursal(
                grupo: r.grupo,
                primero: i == 0,
              ),
              final _RenglonTarjetas r => Padding(
                padding: EdgeInsets.only(bottom: Esp.s),
                child: _Tanda(
                  filas: r.filas,
                  grupo: r.grupo,
                  columnas: columnas,
                ),
              ),
            },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ARMADO DE LA LISTA
//
// Se aplana en vez de anidar listas dentro de tarjetas por sucursal para que
// el `SliverList.builder` siga construyendo solo lo que se ve.
// ═══════════════════════════════════════════════════════════════════════════

sealed class _Renglon {
  const _Renglon();
}

class _RenglonTitulo extends _Renglon {
  const _RenglonTitulo(this.grupo);

  final GrupoSucursal grupo;
}

/// Las tarjetas de un renglon: una en el telefono, hasta [columnas] en el
/// ancho medio.
class _RenglonTarjetas extends _Renglon {
  const _RenglonTarjetas(this.grupo, this.filas);

  final GrupoSucursal grupo;
  final List<FilaPrecioVigente> filas;
}

List<_Renglon> _aplanar(List<GrupoSucursal> grupos, int columnas) {
  final porRenglon = columnas < 1 ? 1 : columnas;
  return [
    for (final g in grupos) ...[
      _RenglonTitulo(g),
      for (var i = 0; i < g.filas.length; i += porRenglon)
        _RenglonTarjetas(g, g.filas.skip(i).take(porRenglon).toList()),
    ],
  ];
}

Color _colorDeGrupo(ColorScheme cs, GrupoSucursal g) =>
    colorDeCatalogo(cs, g.indice).fondo;

// ═══════════════════════════════════════════════════════════════════════════
// PIEZAS
// ═══════════════════════════════════════════════════════════════════════════

class _TituloSucursal extends StatelessWidget {
  const _TituloSucursal({required this.grupo, required this.primero});

  final GrupoSucursal grupo;
  final bool primero;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rango = rangoLegible(grupo.filas);

    return Padding(
      padding: EdgeInsets.only(top: primero ? 0 : Esp.l, bottom: Esp.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.store_outlined,
              size: 18,
              color: _colorDeGrupo(cs, grupo),
            ),
          ),
          SizedBox(width: Esp.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        grupo.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.tituloSeccion(),
                      ),
                    ),
                    SizedBox(width: Esp.s),
                    Text(grupo.listasLegible, style: context.apagado()),
                  ],
                ),
                // El rango de la sucursal, para comparar sucursales sin abrir
                // cada tarjeta.
                if (rango != null)
                  Text(
                    '$rango USD/TM',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.numero(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          if (grupo.sinPrecio > 0) ...[
            SizedBox(width: Esp.s),
            Etiqueta(
              texto: '${grupo.sinPrecio} sin precio',
              tono: TonoEtiqueta.aviso,
            ),
          ],
        ],
      ),
    );
  }
}

/// Un renglon de tarjetas, todas del mismo alto.
class _Tanda extends StatelessWidget {
  const _Tanda({
    required this.filas,
    required this.grupo,
    required this.columnas,
  });

  final List<FilaPrecioVigente> filas;
  final GrupoSucursal grupo;
  final int columnas;

  @override
  Widget build(BuildContext context) {
    if (columnas <= 1) return _Tarjeta(fila: filas.first, grupo: grupo);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < columnas; i++) ...[
            if (i > 0) SizedBox(width: Esp.s),
            // El hueco de un renglon incompleto se reserva igual, para que la
            // ultima tarjeta no se estire al doble de ancho que las demas.
            Expanded(
              child:
                  i < filas.length
                      ? _Tarjeta(fila: filas[i], grupo: grupo)
                      : const SizedBox(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.fila, required this.grupo});

  final FilaPrecioVigente fila;
  final GrupoSucursal grupo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: cs.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Esquina.media),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        onTap: () => mostrarDetalleDePrecio(context, fila),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // La franja de la sucursal, la misma que en la tabla del
              // escritorio.
              Container(width: 4, color: _colorDeGrupo(cs, grupo)),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.s, Esp.m),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              fila.listaLegible,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.titleSmall?.copyWith(
                                fontWeight: Peso.titulo,
                              ),
                            ),
                            SizedBox(height: Esp.xs),
                            Text(
                              'Porcentaje '
                              '${fila.porcentaje == 0 ? "sin cargar" : fila.porcentajeLegible}'
                              '  ·  Lista SAP ${fila.listNum}',
                              maxLines: 2,
                              style: context.apagado(),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: Esp.s),
                      // El precio a la derecha y en grande: es el dato que se
                      // vino a buscar. Sin precio no se escribe un cero, se
                      // dice que no hay.
                      fila.sinPrecio
                          ? const Etiqueta(
                            texto: 'Sin precio',
                            tono: TonoEtiqueta.aviso,
                          )
                          : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                fila.precioLegible,
                                style: tt.titleMedium?.copyWith(
                                  fontWeight: Peso.dato,
                                  fontFeatures: cifrasTabulares,
                                ),
                              ),
                              Text(
                                'USD por tonelada',
                                style: context.apagado(),
                              ),
                            ],
                          ),
                      SizedBox(width: Esp.xs),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DETALLE
// ═══════════════════════════════════════════════════════════════════════════

/// Todos los datos de una lista de precios, los que no entran en la tarjeta
/// incluidos. Es el equivalente en telefono a correr la tabla de costado.
void mostrarDetalleDePrecio(BuildContext context, FilaPrecioVigente fila) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Con scroll: en un telefono apaisado o una ventana baja la hoja tiene
    // menos alto que las nueve lineas del detalle.
    isScrollControlled: true,
    builder:
        (context) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(Esp.l, 0, Esp.l, Esp.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fila.listaLegible, style: context.tituloSeccion()),
                SizedBox(height: Esp.xs),
                Text(fila.sucursalLegible, style: context.apagado()),
                SizedBox(height: Esp.l),
                _Linea(
                  rotulo: 'Precio por tonelada (USD)',
                  valor: fila.precioLegible,
                  fuerte: true,
                  vacio: fila.sinPrecio,
                  // El cero de la base significa que la lista no tiene precio
                  // cargado; decirlo aca evita que alguien lo cotice en cero.
                  nota:
                      fila.sinPrecio
                          ? 'La lista no tiene precio cargado.'
                          : null,
                ),
                _Linea(
                  rotulo: 'Porcentaje',
                  valor: fila.porcentaje == 0 ? '—' : fila.porcentajeLegible,
                  vacio: fila.porcentaje == 0,
                ),
                _Linea(rotulo: 'Número de lista (vpp)', valor: '${fila.vpp}'),
                _Linea(rotulo: 'Lista en SAP', valor: '${fila.listNum}'),
                _Linea(rotulo: 'IVA', valor: fmtPorcentaje(fila.iva)),
                _Linea(rotulo: 'IT', valor: fmtPorcentaje(fila.it)),
                _Linea(rotulo: 'Id de precio', valor: '${fila.idPrecio}'),
              ],
            ),
          ),
        ),
  );
}

class _Linea extends StatelessWidget {
  const _Linea({
    required this.rotulo,
    required this.valor,
    this.fuerte = false,
    this.vacio = false,
    this.nota,
  });

  final String rotulo;
  final String valor;
  final bool fuerte;
  final bool vacio;
  final String? nota;

  @override
  Widget build(BuildContext context) {
    final notaTexto = nota;

    return Padding(
      padding: EdgeInsets.only(bottom: Esp.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(rotulo, style: context.apagado())),
              SizedBox(width: Esp.m),
              Text(
                valor,
                style: context.numero(
                  fuerte: fuerte && !vacio,
                  color:
                      vacio
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : null,
                ),
              ),
            ],
          ),
          if (notaTexto != null) ...[
            SizedBox(height: Esp.xs),
            Text(notaTexto, style: context.apagado()),
          ],
        ],
      ),
    );
  }
}
