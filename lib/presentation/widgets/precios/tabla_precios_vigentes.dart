/// La planilla de precios vigentes de una familia: una fila por lista y un
/// encabezado por sucursal (nº de listas, rango de precio y listas sin precio).
/// No usa `BosqueFlatTable`, que corta los importes. Es un sliver dentro del
/// `CustomScrollView`: la ficha se va con el scroll y la cabecera queda fija. El
/// precio en cero dice "Sin precio": un cuarto de tpr_precio está en cero.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/precios/precios_vigentes_datos.dart';

/// Cuanta informacion se muestra de cada lista.
enum VistaPrecios {
  esencial('Esencial', Icons.view_agenda_outlined),
  completa('Completa', Icons.table_rows_outlined);

  const VistaPrecios(this.rotulo, this.icono);

  final String rotulo;
  final IconData icono;
}

const double _altoBanda = 24;
const double _altoCabecera = 40;
const double _altoGrupo = 42;
const double _altoFila = 44;
const double _altoPie = 46;

/// La franja de color de la sucursal, a la izquierda de cada fila.
const double _anchoFranja = 4;

/// Lo que se corre la lista hacia adentro para quedar debajo del nombre de la
/// sucursal y no debajo de su icono: 16 del icono y 8 de aire.
const double _sangria = 24;

class TablaPreciosVigentes extends StatelessWidget {
  const TablaPreciosVigentes({
    super.key,
    required this.filas,
    required this.vista,
    required this.padding,
  });

  /// Ya filtradas y ordenadas por sucursal y numero de lista.
  final List<FilaPrecioVigente> filas;
  final VistaPrecios vista;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cols = _columnas(vista);
    final grupos = agruparPorSucursal(filas);
    final renglones = _aplanar(grupos);

    return SliverPadding(
      padding: padding,
      sliver: SliverLayoutBuilder(
        builder: (context, restricciones) {
          final trazado = _Trazado.repartir(
            cols,
            restricciones.crossAxisExtent - _anchoFranja,
          );

          return DecoratedSliver(
            // El borde va ENCIMA de las filas: cada una pinta su propio fondo
            // y un borde de fondo quedaria tapado.
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(Esquina.media),
            ),
            sliver: SliverMainAxisGroup(
              slivers: [
                PinnedHeaderSliver(child: _Encabezado(trazado: trazado)),
                SliverList.builder(
                  itemCount: renglones.length,
                  itemBuilder:
                      (context, i) => switch (renglones[i]) {
                        final _RenglonGrupo r => _FilaGrupo(
                          grupo: r.grupo,
                          trazado: trazado,
                          primero: i == 0,
                        ),
                        final _RenglonLista r => _FilaLista(
                          fila: r.fila,
                          grupo: r.grupo,
                          posicion: r.posicion,
                          trazado: trazado,
                        ),
                      },
                ),
                SliverToBoxAdapter(
                  child: _Pie(
                    trazado: trazado,
                    filas: filas,
                    sucursales: grupos.length,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Columnas

enum _Clave { lista, vpp, listaSap, porcentaje, precio, idPrecio, estado }

List<_Col> _columnas(VistaPrecios vista) {
  final todas = <_Col>[
    _Col(
      _Clave.lista,
      'LISTA',
      220,
      (c, f) => Text(
        f.listaLegible,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(c).textTheme.bodyMedium,
      ),
      alinear: Alignment.centerLeft,
      banda: 'LISTA DE PRECIO',
      enEsencial: true,
      ayuda:
          'Nombre de la lista y su número de venta. El nombre casi siempre '
          'es el mismo: lo que distingue una lista de otra es el vpp.',
    ),
    _Col(
      _Clave.vpp,
      'VPP',
      70,
      (c, f) => _cifra(c, '${f.vpp}'),
      banda: 'LISTA DE PRECIO',
      ayuda: 'Número de lista de venta del ERP.',
    ),
    _Col(
      _Clave.listaSap,
      'LISTA SAP',
      100,
      (c, f) => _cifra(c, '${f.listNum}'),
      banda: 'LISTA DE PRECIO',
      ayuda: 'Número de lista equivalente en SAP.',
    ),
    _Col(
      _Clave.porcentaje,
      'PORCENTAJE',
      120,
      (c, f) => _cifra(
        c,
        f.porcentaje == 0 ? '—' : f.porcentajeLegible,
        // Sin porcentaje cargado el precio de esa lista no se recalcula en la
        // proxima propuesta: conviene que se note.
        vacio: f.porcentaje == 0,
      ),
      banda: 'PRECIO VIGENTE',
      enEsencial: true,
      ayuda:
          'Margen sobre el costo de la familia, en puntos porcentuales, para '
          'esta lista.',
    ),
    _Col(
      _Clave.precio,
      'PRECIO USD/TM',
      170,
      (c, f) => _cifra(c, f.precioLegible, fuerte: true, vacio: f.sinPrecio),
      banda: 'PRECIO VIGENTE',
      enEsencial: true,
      ayuda:
          'Precio vigente por tonelada, en dólares: el mismo que imprime el '
          'reporte.',
    ),
    _Col(
      _Clave.idPrecio,
      'ID PRECIO',
      100,
      (c, f) => _cifra(c, '${f.idPrecio}', vacio: true),
      banda: 'PRECIO VIGENTE',
      ayuda:
          'Identificador de la fila de precio. Sirve para rastrear el dato '
          'con soporte.',
    ),
    _Col(
      _Clave.estado,
      'ESTADO',
      130,
      (c, f) =>
          f.sinPrecio
              ? const Etiqueta(texto: 'Sin precio', tono: TonoEtiqueta.aviso)
              : const Etiqueta(texto: 'Vigente', tono: TonoEtiqueta.exito),
      alinear: Alignment.centerLeft,
      banda: 'PRECIO VIGENTE',
      enEsencial: true,
    ),
  ];

  return vista == VistaPrecios.completa
      ? todas
      : todas.where((c) => c.enEsencial).toList();
}

/// Una columna de la planilla.
class _Col {
  const _Col(
    this.clave,
    this.titulo,
    this.ancho,
    this.celda, {
    this.banda = '',
    this.ayuda,
    this.enEsencial = false,
    this.alinear = Alignment.centerRight,
  });

  final _Clave clave;
  final String titulo;

  /// El ancho que pide. El que recibe sale de [_Trazado.repartir].
  final double ancho;
  final Widget Function(BuildContext, FilaPrecioVigente) celda;

  /// El grupo al que pertenece, para la banda de arriba.
  final String banda;

  /// Que significa la columna, cuando el rotulo no alcanza.
  final String? ayuda;

  /// Si sobrevive a la vista corta.
  final bool enEsencial;

  final Alignment alinear;
}

/// Las columnas con el ancho que les toca. Lo que sobra se reparte en proporción
/// y no se lo lleva la última: con la vista corta en pantalla ancha, una columna
/// de estado de 900 px deja los precios pegados a la izquierda.
class _Trazado {
  const _Trazado(this.cols, this.anchos);

  factory _Trazado.repartir(List<_Col> cols, double disponible) {
    final pedido = cols.fold(0.0, (s, c) => s + c.ancho);
    final factor = pedido <= 0 ? 1.0 : disponible / pedido;
    return _Trazado(cols, [for (final c in cols) c.ancho * factor]);
  }

  final List<_Col> cols;
  final List<double> anchos;

  int indiceDe(_Clave clave) => cols.indexWhere((c) => c.clave == clave);

  /// Una fila de celdas, cada una con el ancho de su columna. La última es `Expanded`
  /// y absorbe el redondeo, para no pasarse del cajón por una fracción de píxel.
  Widget fila(
    List<Widget?> celdas, {
    Color? franja,
    double sangriaPrimera = 0,
  }) => Row(
    children: [
      Container(width: _anchoFranja, color: franja),
      for (final (i, col) in cols.indexed)
        if (i == cols.length - 1)
          Expanded(child: celda(col, celdas[i]))
        else
          SizedBox(
            width: anchos[i],
            child: celda(col, celdas[i], sangria: i == 0 ? sangriaPrimera : 0),
          ),
    ],
  );

  Widget celda(_Col col, Widget? hijo, {double sangria = 0}) => Container(
    alignment: col.alinear,
    padding: EdgeInsets.only(left: Esp.s + sangria, right: Esp.s),
    child: hijo ?? const SizedBox(),
  );
}

// Renglones: se aplanan en una sola lista para que el `SliverList.builder` siga
// construyendo solo lo que se ve.

sealed class _Renglon {
  const _Renglon();
}

class _RenglonGrupo extends _Renglon {
  const _RenglonGrupo(this.grupo);

  final GrupoSucursal grupo;
}

class _RenglonLista extends _Renglon {
  const _RenglonLista(this.fila, this.grupo, this.posicion);

  final FilaPrecioVigente fila;
  final GrupoSucursal grupo;

  /// Lugar dentro de su sucursal. Decide el rayado.
  final int posicion;
}

List<_Renglon> _aplanar(List<GrupoSucursal> grupos) => [
  for (final g in grupos) ...[
    _RenglonGrupo(g),
    for (final (i, f) in g.filas.indexed) _RenglonLista(f, g, i),
  ],
];

Color _colorDeGrupo(ColorScheme cs, GrupoSucursal g) =>
    colorDeCatalogo(cs, g.indice).fondo;

// Piezas

/// La banda y los rotulos de columna. Quedan fijos arriba mientras se recorren
/// las filas.
class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.trazado});

  final _Trazado trazado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Esquina.media),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: _altoBanda, child: _Banda(trazado: trazado)),
          SizedBox(
            height: _altoCabecera,
            child: trazado.fila([
              for (final col in trazado.cols)
                col.ayuda == null
                    ? _Rotulo(col.titulo)
                    : Tooltip(
                      message: col.ayuda!,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: _Rotulo(col.titulo)),
                          SizedBox(width: Esp.xs),
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
            ], sangriaPrimera: _sangria),
          ),
        ],
      ),
    );
  }
}

/// La banda que agrupa las columnas por lo que responden: de que lista es el
/// precio, y cuanto vale.
class _Banda extends StatelessWidget {
  const _Banda({required this.trazado});

  final _Trazado trazado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Junta las columnas contiguas que comparten banda.
    final grupos = <({String nombre, double ancho})>[];
    for (final (i, col) in trazado.cols.indexed) {
      final ancho = trazado.anchos[i];
      if (grupos.isNotEmpty && grupos.last.nombre == col.banda) {
        final ultimo = grupos.removeLast();
        grupos.add((nombre: col.banda, ancho: ultimo.ancho + ancho));
      } else {
        grupos.add((nombre: col.banda, ancho: ancho));
      }
    }

    Widget banda(int i, String nombre) => Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: Esp.s),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorDeCatalogo(cs, i).fondo, width: 3),
        ),
      ),
      child: Text(
        nombre,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: Peso.titulo,
          letterSpacing: 0.6,
        ),
      ),
    );

    return Row(
      children: [
        const SizedBox(width: _anchoFranja),
        for (final (i, g) in grupos.indexed)
          if (i == grupos.length - 1)
            Expanded(child: banda(i, g.nombre))
          else
            SizedBox(width: g.ancho, child: banda(i, g.nombre)),
      ],
    );
  }
}

class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Text(
    texto,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: Peso.titulo,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      letterSpacing: 0.3,
    ),
  );
}

/// El encabezado de una sucursal: su nombre sobre las columnas de la lista, su
/// rango de precio debajo de la columna del precio y las listas sin precio
/// debajo de la del estado.
class _FilaGrupo extends StatelessWidget {
  const _FilaGrupo({
    required this.grupo,
    required this.trazado,
    required this.primero,
  });

  final GrupoSucursal grupo;
  final _Trazado trazado;
  final bool primero;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _colorDeGrupo(cs, grupo);
    final iPrecio = trazado.indiceDe(_Clave.precio);
    final iEstado = trazado.indiceDe(_Clave.estado);
    final ultima = trazado.cols.length - 1;
    final rango = rangoLegible(grupo.filas);

    // El nombre ocupa todas las columnas que hay antes del precio.
    final anchoNombre = trazado.anchos.take(iPrecio).fold(0.0, (s, a) => s + a);

    Widget? contenido(int i) {
      if (i == iPrecio && rango != null) {
        return Tooltip(
          message: 'Precios de la sucursal, del más bajo al más alto',
          child: _cifra(context, rango, color: cs.onSurfaceVariant),
        );
      }
      if (i == iEstado && grupo.sinPrecio > 0) {
        return Etiqueta(
          texto: '${grupo.sinPrecio} sin precio',
          tono: TonoEtiqueta.aviso,
        );
      }
      return null;
    }

    return Container(
      height: _altoGrupo,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.10),
          cs.surfaceContainerLowest,
        ),
        border:
            primero ? null : Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Container(width: _anchoFranja, color: color),
          SizedBox(
            width: anchoNombre,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Esp.s),
              child: Row(
                children: [
                  Icon(Icons.store_outlined, size: 16, color: color),
                  SizedBox(width: Esp.s),
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
            ),
          ),
          for (var i = iPrecio; i <= ultima; i++)
            if (i == ultima)
              Expanded(child: trazado.celda(trazado.cols[i], contenido(i)))
            else
              SizedBox(
                width: trazado.anchos[i],
                child: trazado.celda(trazado.cols[i], contenido(i)),
              ),
        ],
      ),
    );
  }
}

/// Una lista de precios. El rayado alterna dentro de cada sucursal, y al pasar
/// el mouse la fila se marca entera: en una planilla estirada al ancho de la
/// pantalla, es lo que evita leer el precio de la fila de al lado.
class _FilaLista extends StatefulWidget {
  const _FilaLista({
    required this.fila,
    required this.grupo,
    required this.posicion,
    required this.trazado,
  });

  final FilaPrecioVigente fila;
  final GrupoSucursal grupo;
  final int posicion;
  final _Trazado trazado;

  @override
  State<_FilaLista> createState() => _FilaListaState();
}

class _FilaListaState extends State<_FilaLista> {
  bool _encima = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base =
        widget.posicion.isOdd
            ? cs.surfaceContainerLow
            : cs.surfaceContainerLowest;

    return MouseRegion(
      onEnter: (_) => setState(() => _encima = true),
      onExit: (_) => setState(() => _encima = false),
      child: Container(
        height: _altoFila,
        color:
            _encima
                ? Color.alphaBlend(cs.primary.withValues(alpha: 0.07), base)
                : base,
        child: widget.trazado.fila(
          [
            for (final col in widget.trazado.cols)
              col.celda(context, widget.fila),
          ],
          franja: _colorDeGrupo(cs, widget.grupo),
          sangriaPrimera: _sangria,
        ),
      ),
    );
  }
}

/// El resumen de la familia, cada dato debajo de su columna.
class _Pie extends StatelessWidget {
  const _Pie({
    required this.trazado,
    required this.filas,
    required this.sucursales,
  });

  final _Trazado trazado;
  final List<FilaPrecioVigente> filas;
  final int sucursales;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sinPrecio = filas.where((f) => f.sinPrecio).length;
    final rango = rangoLegible(filas);
    final listas = filas.length == 1 ? '1 lista' : '${filas.length} listas';
    final enSucursales =
        sucursales == 1 ? 'en 1 sucursal' : 'en $sucursales sucursales';

    return Container(
      height: _altoPie,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(Esquina.media),
        ),
      ),
      child: trazado.fila([
        for (final col in trazado.cols)
          switch (col.clave) {
            _Clave.lista => Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: listas,
                    style: const TextStyle(fontWeight: Peso.dato),
                  ),
                  TextSpan(
                    text: '  $enSucursales',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            _Clave.precio =>
              rango == null
                  ? _cifra(context, '—', vacio: true)
                  : _cifra(context, rango, fuerte: true),
            _Clave.estado =>
              sinPrecio == 0
                  ? Text('Todas con precio', style: context.apagado())
                  : Etiqueta(
                    texto: '$sinPrecio sin precio',
                    tono: TonoEtiqueta.aviso,
                  ),
            _ => null,
          },
      ]),
    );
  }
}

/// Una cifra de la planilla. Lo que no tiene valor se atenua: en una columna de
/// importes, un guion en negro compite con los numeros que si dicen algo.
Widget _cifra(
  BuildContext context,
  String texto, {
  bool fuerte = false,
  bool vacio = false,
  Color? color,
}) => Text(
  texto,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: context.numero(
    fuerte: fuerte && !vacio,
    color: vacio ? Theme.of(context).colorScheme.onSurfaceVariant : color,
  ),
);
