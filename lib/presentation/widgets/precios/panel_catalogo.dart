import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/precios/cifra_resumen.dart';
import 'package:bosque_flutter/presentation/widgets/precios/tabla_propuestas.dart';

/// Valor del filtro de estado que significa "no filtrar". No se usa `null`
/// porque `PopupMenuButton.onSelected` NO se dispara con un item de valor nulo
/// (Flutter lo toma como "se cerró sin elegir" y llama a `onCanceled`).
const int estadoTodos = -1;

/// Matices de las dos acciones de cada fila: los de editar y rechazar del listado de
/// propuestas ([AccionDePropuesta]), para que el mismo color diga lo mismo.
const Color _matizEditar = Color(0xFFFFA000);
const Color _matizEliminar = Color(0xFFD32F2F);

/// Una columna de la tabla de un catálogo. De ancho declarado y no por `flex`:
/// repartir el ancho de un monitor entre tres columnas dejaba cada dato perdido
/// en una franja de 500 px. La columna que [expande] se queda con lo que sobre.
@immutable
class ColumnaCatalogo<T> {
  const ColumnaCatalogo(
    this.titulo, {
    required this.celda,
    this.ancho = 160,
    this.expande = false,
    this.alinear = Alignment.centerLeft,
    this.ayuda,
  });

  final String titulo;
  final Widget Function(T item) celda;
  final double ancho;
  final bool expande;
  final Alignment alinear;

  /// Que significa la columna, cuando el rotulo no alcanza.
  final String? ayuda;
}

/// Una cifra del resumen de arriba de la tabla.
@immutable
class DatoResumen {
  const DatoResumen({
    required this.rotulo,
    required this.valor,
    required this.detalle,
    required this.matiz,
    required this.icono,
    this.corto,
  });

  final String rotulo;
  final String valor;
  final String detalle;
  final Color matiz;
  final IconData icono;

  /// La version de una linea para el telefono ("10 activos"). Null = no va en
  /// el telefono.
  final String? corto;
}

/// El cuerpo de una pestaña de catálogo: buscador, filtro de estado, resumen,
/// tabla en escritorio y tarjetas en móvil. Los seis catálogos del módulo son la
/// misma pantalla con otros campos: cada pestaña aporta solo columnas, tarjeta,
/// resumen y formulario. No usa `BosqueFlatTable` (cabecera de color fijo, flex,
/// alto de pantalla con diez filas) sino la tabla del módulo: filas de 52 px y
/// alto ajustado a lo que hay.
class PanelCatalogo<T> extends StatefulWidget {
  const PanelCatalogo({
    super.key,
    required this.datos,
    required this.columnas,
    required this.tarjeta,
    required this.textoBuscable,
    required this.nombre,
    required this.contar,
    required this.hintBuscador,
    required this.iconoVacio,
    required this.tituloVacio,
    required this.detalleVacio,
    required this.onReintentar,
    required this.onEditar,
    required this.onEliminar,
    this.etiquetaNuevo,
    this.onNuevo,
    this.accionExtra,
    this.esActivo,
    this.estado,
    this.onEstado,
    this.etiquetaActivo = 'Activos',
    this.etiquetaInactivo = 'Inactivos',
    this.resumen,
  });

  /// El listado completo, tal como lo entrega el provider del modulo. El filtro
  /// de estado lo aplica el panel: el resumen cuenta sobre todo el catalogo.
  final AsyncValue<List<T>> datos;

  /// Las columnas de la tabla de escritorio, segun el aire disponible. Las
  /// acciones las agrega el panel al final.
  final List<ColumnaCatalogo<T>> Function(Aire aire) columnas;

  /// La tarjeta de movil de una fila.
  final Widget Function(T item) tarjeta;

  /// El texto sobre el que busca el buscador. Se compara sin distinguir
  /// mayusculas ni acentos de mas: lo que hay en la fila, en minusculas.
  final String Function(T item) textoBuscable;

  /// Como se llama la fila en los rotulos de las acciones ("Editar AMARILLO").
  final String Function(T item) nombre;

  /// "1 color", "10 colores".
  final String Function(int n) contar;

  final String hintBuscador;

  final IconData iconoVacio;
  final String tituloVacio;
  final String detalleVacio;

  /// Vuelve a pedir el listado cuando la carga fallo.
  final VoidCallback onReintentar;

  final ValueChanged<T> onEditar;
  final ValueChanged<T> onEliminar;

  final String? etiquetaNuevo;
  final VoidCallback? onNuevo;

  /// Un boton mas en la barra, antes del alta: en grupos y proveedores,
  /// "Traer de SAP". Recibe si el cajon es angosto, para dibujarse como icono.
  final Widget Function(bool compacto)? accionExtra;

  /// Null en los catalogos que no tienen columna de estado: no hay filtro.
  final bool Function(T item)? esActivo;

  /// Filtro de estado: [estadoTodos], 1 activos, 0 inactivos.
  final int? estado;
  final ValueChanged<int>? onEstado;

  final String etiquetaActivo;
  final String etiquetaInactivo;

  /// Las cifras de arriba de la tabla, calculadas sobre el catalogo completo.
  final List<DatoResumen> Function(List<T> todos)? resumen;

  @override
  State<PanelCatalogo<T>> createState() => _PanelCatalogoState<T>();
}

class _PanelCatalogoState<T> extends State<PanelCatalogo<T>>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _buscador = TextEditingController();

  String _texto = '';
  int _pagina = 1;
  int _tamanoPagina = 15;

  /// Las seis pestañas conviven en un TabBarView, que descarta el estado de la
  /// que no se ve: sin esto, volver a una pestaña perdía el buscador y la página.
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  List<T> _filtrar(List<T> lista) {
    final esActivo = widget.esActivo;
    final estado = widget.estado ?? estadoTodos;
    final busqueda = _texto.trim().toLowerCase();
    return [
      for (final e in lista)
        if ((esActivo == null ||
                estado == estadoTodos ||
                esActivo(e) == (estado == 1)) &&
            (busqueda.isEmpty ||
                widget.textoBuscable(e).toLowerCase().contains(busqueda)))
          e,
    ];
  }

  void _buscar(String texto) => setState(() {
    _texto = texto;
    _pagina = 1;
  });

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return LayoutBuilder(
      builder: (context, cajon) {
        final aire = Aire.de(cajon.maxWidth);

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          // En movil el alta va al boton flotante: la barra de filtros tiene que
          // quedar para lo que se mira, no para lo que se agrega.
          floatingActionButton:
              (aire.esChico && widget.onNuevo != null)
                  ? FloatingActionButton.extended(
                    // Sin hero: cada pestaña tiene su botón y quedan vivas; con la etiqueta por
                    // defecto, al salir Flutter encuentra varios heroes iguales.
                    heroTag: null,
                    onPressed: widget.onNuevo,
                    icon: const Icon(Icons.add),
                    label: Text(widget.etiquetaNuevo ?? 'Nuevo'),
                  )
                  : null,
          body: widget.datos.when(
            loading: () => const EsqueletoLista(filas: 5),
            error:
                (e, _) =>
                    MensajeError(error: e, onReintentar: widget.onReintentar),
            data: (lista) => _contenido(context, aire, lista),
          ),
        );
      },
    );
  }

  Widget _contenido(BuildContext context, Aire aire, List<T> lista) {
    if (lista.isEmpty) {
      return MensajeVacio(
        icono: widget.iconoVacio,
        titulo: widget.tituloVacio,
        detalle: widget.detalleVacio,
      );
    }

    final filtrada = _filtrar(lista);

    // Paginación del lado del cliente (catálogos chicos, ya descargados enteros): el
    // paginador solo aparece si hay más filas que las de una página.
    final hayPaginacion = filtrada.length > _tamanoPagina;
    final totalPaginas =
        hayPaginacion ? (filtrada.length / _tamanoPagina).ceil() : 1;
    final pagina = _pagina.clamp(1, totalPaginas);
    final desde = (pagina - 1) * _tamanoPagina;
    final hasta = (desde + _tamanoPagina).clamp(0, filtrada.length);
    final visibles = filtrada.sublist(desde, hasta);

    final margen =
        aire.esChico ? Esp.m : (aire == Aire.amplio ? Esp.xl : Esp.l);
    final esActivo = widget.esActivo;
    final activos =
        esActivo == null ? 0 : lista.where((e) => esActivo(e)).length;

    final filtro =
        (esActivo != null && widget.onEstado != null)
            ? FiltroEstado(
              valor: widget.estado ?? estadoTodos,
              onCambiar: (v) {
                setState(() => _pagina = 1);
                widget.onEstado!(v);
              },
              compacto: aire != Aire.amplio,
              etiquetaActivo: widget.etiquetaActivo,
              etiquetaInactivo: widget.etiquetaInactivo,
              cuentas: (lista.length, activos, lista.length - activos),
            )
            : null;

    final buscador = _Buscador(
      controller: _buscador,
      pista: widget.hintBuscador,
      onCambiar: _buscar,
    );

    final Widget barra;
    if (aire.esChico) {
      barra = Row(
        children: [
          Expanded(child: buscador),
          if (filtro != null) ...[const SizedBox(width: Esp.s), filtro],
          if (widget.accionExtra != null) ...[
            const SizedBox(width: Esp.xs),
            widget.accionExtra!(true),
          ],
        ],
      );
    } else {
      // Buscador y filtro a la izquierda, alta al borde derecho. Con un Spacer junto al
      // Flexible el alta quedaba en el medio: el Row reparte la mitad libre a cada uno.
      barra = Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: buscador,
                  ),
                ),
                if (filtro != null) ...[const SizedBox(width: Esp.m), filtro],
              ],
            ),
          ),
          const SizedBox(width: Esp.m),
          if (widget.accionExtra != null) ...[
            widget.accionExtra!(false),
            const SizedBox(width: Esp.s),
          ],
          if (widget.onNuevo != null)
            FilledButton.icon(
              onPressed: widget.onNuevo,
              icon: const Icon(Icons.add, size: 18),
              label: Text(widget.etiquetaNuevo ?? 'Nuevo'),
            ),
        ],
      );
    }

    final datosResumen = widget.resumen?.call(lista) ?? const <DatoResumen>[];

    final pie = _Pie(
      texto:
          filtrada.length == lista.length
              ? widget.contar(lista.length)
              : '${widget.contar(filtrada.length)} de ${lista.length}',
      desde: desde + 1,
      hasta: hasta,
      total: filtrada.length,
      pagina: hayPaginacion ? pagina : null,
      totalPaginas: totalPaginas,
      tamanoPagina: _tamanoPagina,
      onPagina: (p) => setState(() => _pagina = p),
      onTamano:
          (n) => setState(() {
            _tamanoPagina = n;
            _pagina = 1;
          }),
    );

    final Widget cuerpo;
    if (filtrada.isEmpty) {
      final sugerencia =
          filtro == null
              ? 'Pruebe con otro texto.'
              : 'Pruebe con otro texto o con «Todos».';
      cuerpo = MensajeVacio(
        icono: Icons.search_off,
        titulo: 'Ningún resultado',
        detalle:
            'El catálogo tiene ${widget.contar(lista.length)}, pero la '
            'búsqueda o el filtro no deja ver ninguna fila. $sugerencia',
      );
    } else if (aire.esChico) {
      // En el telefono el pie va al final de la lista y no pegado abajo: el
      // boton flotante lo taparia.
      cuerpo = ListView(
        padding: EdgeInsets.fromLTRB(margen, 0, margen, 96),
        children: [
          for (final e in visibles) widget.tarjeta(e),
          Padding(padding: const EdgeInsets.only(top: Esp.xs), child: pie),
        ],
      );
    } else {
      cuerpo = _TablaCatalogo<T>(
        filas: visibles,
        columnas: widget.columnas(aire),
        nombre: widget.nombre,
        onEditar: widget.onEditar,
        onEliminar: widget.onEliminar,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, Esp.m),
          child: barra,
        ),
        if (datosResumen.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(margen, 0, margen, Esp.m),
            child:
                aire.esChico
                    ? _ResumenCorto(datos: datosResumen)
                    : _Resumen(
                      datos: datosResumen,
                      compacto: aire != Aire.amplio,
                    ),
          ),
        if (aire.esChico || filtrada.isEmpty)
          Expanded(child: cuerpo)
        else
          Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: margen),
              child: cuerpo,
            ),
          ),
        if (!aire.esChico && filtrada.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(margen, Esp.s, margen, Esp.m),
            child: pie,
          ),
      ],
    );
  }
}

// Barra y resumen

class _Buscador extends StatelessWidget {
  const _Buscador({
    required this.controller,
    required this.pista,
    required this.onCambiar,
  });

  final TextEditingController controller;
  final String pista;
  final ValueChanged<String> onCambiar;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder:
          (context, valor, _) => TextField(
            controller: controller,
            onChanged: onCambiar,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: pista,
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon:
                  valor.text.isEmpty
                      ? null
                      : IconButton(
                        tooltip: 'Borrar la búsqueda',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          controller.clear();
                          onCambiar('');
                        },
                      ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Esquina.chica),
              ),
            ),
          ),
    );
  }
}

/// Las cifras del catálogo, en fila: cuántos hay, cuántos se ofrecen y cuándo se
/// tocó por última vez.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.datos, required this.compacto});

  final List<DatoResumen> datos;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, d) in datos.indexed) ...[
          if (i > 0) const SizedBox(width: Esp.m),
          Expanded(
            child: CifraResumen(
              compacto: compacto,
              matiz: d.matiz,
              icono: d.icono,
              rotulo: d.rotulo,
              valor: d.valor,
              detalle: d.detalle,
            ),
          ),
        ],
      ],
    );
  }
}

/// El resumen en el telefono: una linea, no cuatro tarjetas que empujan la
/// lista fuera de la pantalla.
class _ResumenCorto extends StatelessWidget {
  const _ResumenCorto({required this.datos});

  final List<DatoResumen> datos;

  @override
  Widget build(BuildContext context) {
    final cortos = [
      for (final d in datos)
        if (d.corto != null) d.corto!,
    ];
    if (cortos.isEmpty) return const SizedBox.shrink();
    return Text(
      cortos.join(' · '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: context.apagado(),
    );
  }
}

/// Filtro de activos / inactivos. En escritorio son tres pastillas a la vista,
/// con cuántos hay en cada una; si el ancho no alcanza se colapsa en un menú de
/// una sola línea.
class FiltroEstado extends StatelessWidget {
  const FiltroEstado({
    super.key,
    required this.valor,
    required this.onCambiar,
    required this.compacto,
    this.etiquetaActivo = 'Activos',
    this.etiquetaInactivo = 'Inactivos',
    this.cuentas,
  });

  /// [estadoTodos], 1 activos, 0 inactivos.
  final int valor;
  final ValueChanged<int> onCambiar;
  final bool compacto;
  final String etiquetaActivo;
  final String etiquetaInactivo;

  /// (todos, activos, inactivos), para mostrarlos en cada opcion.
  final (int, int, int)? cuentas;

  String get _etiquetaActual => switch (valor) {
    1 => etiquetaActivo,
    0 => etiquetaInactivo,
    _ => 'Todos',
  };

  List<(int, String, int?)> get _opciones => [
    (estadoTodos, 'Todos', cuentas?.$1),
    (1, etiquetaActivo, cuentas?.$2),
    (0, etiquetaInactivo, cuentas?.$3),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (compacto) {
      return PopupMenuButton<int>(
        tooltip: 'Filtrar por estado',
        initialValue: valor,
        onSelected: onCambiar,
        itemBuilder:
            (_) => [
              for (final (opcion, texto, n) in _opciones)
                PopupMenuItem<int>(
                  value: opcion,
                  child: Text(n == null ? texto : '$texto ($n)'),
                ),
            ],
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: Esp.m),
          decoration: BoxDecoration(
            border: Border.all(color: cs.outline),
            borderRadius: BorderRadius.circular(Esquina.chica),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: Esp.xs),
              Text(
                _etiquetaActual,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Icon(Icons.arrow_drop_down, size: 18, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      );
    }

    return SegmentedButton<int>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        for (final (opcion, texto, n) in _opciones)
          ButtonSegment<int>(
            value: opcion,
            label: Text(n == null ? texto : '$texto · $n'),
          ),
      ],
      selected: {valor},
      onSelectionChanged: (s) => onCambiar(s.first),
    );
  }
}

// La tabla

const double _altoCabecera = 44;
const double _altoFila = 52;
const double _anchoAcciones = 104;

class _TablaCatalogo<T> extends StatefulWidget {
  const _TablaCatalogo({
    required this.filas,
    required this.columnas,
    required this.nombre,
    required this.onEditar,
    required this.onEliminar,
  });

  final List<T> filas;
  final List<ColumnaCatalogo<T>> columnas;
  final String Function(T) nombre;
  final ValueChanged<T> onEditar;
  final ValueChanged<T> onEliminar;

  @override
  State<_TablaCatalogo<T>> createState() => _TablaCatalogoState<T>();
}

class _TablaCatalogoState<T> extends State<_TablaCatalogo<T>> {
  final _scrollH = ScrollController();

  @override
  void dispose() {
    _scrollH.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cols = widget.columnas;

    return LayoutBuilder(
      builder: (context, r) {
        final pedido = cols.fold(0.0, (s, c) => s + c.ancho) + _anchoAcciones;
        // El borde de la caja se come un pixel de cada lado.
        final disponible = r.maxWidth - 2;
        final desborda = pedido > disponible;
        // Lo que sobra se lo lleva la columna que expande: es la del nombre, la
        // unica con texto que se corta.
        final sobra = desborda ? 0.0 : disponible - pedido;
        final expanden = cols.where((c) => c.expande).length;
        double ancho(ColumnaCatalogo<T> c) =>
            c.ancho + (c.expande && expanden > 0 ? sobra / expanden : 0);
        final anchoTotal = desborda ? pedido : disponible;

        // El alto sigue a las filas: diez colores no necesitan una caja del
        // alto de la pantalla con medio metro vacio adentro.
        final contenido =
            _altoCabecera +
            widget.filas.length * _altoFila +
            2 +
            (desborda ? 12 : 0);
        final alto =
            r.maxHeight.isFinite
                ? contenido.clamp(0.0, r.maxHeight).toDouble()
                : contenido;

        Widget celda(ColumnaCatalogo<T> c, Widget hijo) => Container(
          width: ancho(c),
          alignment: c.alinear,
          padding: const EdgeInsets.symmetric(horizontal: Esp.m),
          child: hijo,
        );

        final cabecera = Container(
          height: _altoCabecera,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            border: Border(bottom: BorderSide(color: cs.outlineVariant)),
          ),
          child: Row(
            children: [
              for (final c in cols)
                celda(
                  c,
                  c.ayuda == null
                      ? _Rotulo(c.titulo)
                      : Tooltip(
                        message: c.ayuda!,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(child: _Rotulo(c.titulo)),
                            const SizedBox(width: Esp.xs),
                            Icon(
                              Icons.info_outline,
                              size: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                ),
              Container(
                width: _anchoAcciones,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: Esp.m),
                child: const _Rotulo('ACCIONES'),
              ),
            ],
          ),
        );

        Widget fila(int i) {
          final item = widget.filas[i];
          final nombre = widget.nombre(item);
          return Material(
            color: i.isOdd ? cs.surfaceContainerLow : cs.surfaceContainerLowest,
            child: InkWell(
              // Tocar la fila abre la ficha: es lo que se quiere casi siempre.
              onTap: () => widget.onEditar(item),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    for (final c in cols) celda(c, c.celda(item)),
                    Container(
                      width: _anchoAcciones,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: Esp.s),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BotonAccionCatalogo(
                            matiz: _matizEditar,
                            icono: Icons.edit_outlined,
                            ayuda: 'Editar $nombre',
                            onPressed: () => widget.onEditar(item),
                          ),
                          BotonAccionCatalogo(
                            matiz: _matizEliminar,
                            icono: Icons.delete_outline,
                            ayuda: 'Eliminar $nombre',
                            onPressed: () => widget.onEliminar(item),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SizedBox(
          height: alto,
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(Esquina.media),
            ),
            clipBehavior: Clip.antiAlias,
            child: ScrollConfiguration(
              behavior: const ArrastreLateral(),
              child: Scrollbar(
                controller: _scrollH,
                thumbVisibility: desborda,
                child: SingleChildScrollView(
                  controller: _scrollH,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: anchoTotal,
                    child: Column(
                      children: [
                        cabecera,
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemExtent: _altoFila,
                            itemCount: widget.filas.length,
                            itemBuilder: (_, i) => fila(i),
                          ),
                        ),
                        SizedBox(height: desborda ? 12 : 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Text(
    texto.toUpperCase(),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: Peso.titulo,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      letterSpacing: 0.4,
    ),
  );
}

/// Un boton de accion de una fila, con fondo de su color: el mismo dibujo que
/// las acciones del listado de propuestas.
class BotonAccionCatalogo extends StatelessWidget {
  const BotonAccionCatalogo({
    super.key,
    required this.matiz,
    required this.icono,
    required this.ayuda,
    required this.onPressed,
  });

  final Color matiz;
  final IconData icono;
  final String ayuda;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = tonosDeMatiz(matiz, cs);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: IconButton(
        icon: Icon(icono, size: 18),
        tooltip: ayuda,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: t.fondo,
          foregroundColor: t.icono,
          minimumSize: const Size(34, 34),
          maximumSize: const Size(34, 34),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Esquina.chica),
            side: BorderSide(color: t.icono.withValues(alpha: 0.35)),
          ),
        ),
      ),
    );
  }
}

// Pie y paginación

class _Pie extends StatelessWidget {
  const _Pie({
    required this.texto,
    required this.desde,
    required this.hasta,
    required this.total,
    required this.pagina,
    required this.totalPaginas,
    required this.tamanoPagina,
    required this.onPagina,
    required this.onTamano,
  });

  final String texto;
  final int desde;
  final int hasta;
  final int total;

  /// Null = entra todo en una pagina: no hay paginador.
  final int? pagina;
  final int totalPaginas;
  final int tamanoPagina;
  final ValueChanged<int> onPagina;
  final ValueChanged<int> onTamano;

  @override
  Widget build(BuildContext context) {
    final p = pagina;
    final cuenta = Text(
      p == null ? texto : 'Mostrando $desde–$hasta de $total',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.apagado(),
    );
    if (p == null) return cuenta;

    return Row(
      children: [
        Expanded(child: cuenta),
        PopupMenuButton<int>(
          tooltip: 'Filas por página',
          initialValue: tamanoPagina,
          onSelected: onTamano,
          itemBuilder:
              (_) => [
                for (final n in const [15, 30, 50])
                  PopupMenuItem<int>(value: n, child: Text('$n filas')),
              ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Esp.s),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$tamanoPagina filas', style: context.apagado()),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'Página anterior',
          onPressed: p > 1 ? () => onPagina(p - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('$p / $totalPaginas', style: context.numero(fuerte: true)),
        IconButton(
          tooltip: 'Página siguiente',
          onPressed: p < totalPaginas ? () => onPagina(p + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

// La tarjeta del teléfono

/// La fila de un catálogo en móvil. No es la tabla escalada: el nombre manda, el
/// estado va como etiqueta, los datos de apoyo bajan a una línea secundaria y las
/// acciones van al menú contextual, sin scroll horizontal.
class TarjetaCatalogo extends StatelessWidget {
  const TarjetaCatalogo({
    super.key,
    required this.icono,
    required this.titulo,
    required this.onEditar,
    required this.onEliminar,
    this.etiqueta,
    this.subtitulo,
    this.datos = const <String>[],
  });

  final IconData icono;
  final String titulo;
  final Widget? etiqueta;
  final String? subtitulo;

  /// Lineas cortas de apoyo: codigos, fechas de auditoria, conteos.
  final List<String> datos;

  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = tonosDeMatiz(matizAzul, cs);

    return Container(
      margin: const EdgeInsets.only(bottom: Esp.s),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onEditar,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.xs, Esp.m),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: t.fondo,
                    borderRadius: BorderRadius.circular(Esquina.chica),
                  ),
                  child: Icon(icono, size: 20, color: t.icono),
                ),
                const SizedBox(width: Esp.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              titulo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: tt.titleSmall?.copyWith(
                                fontWeight: Peso.dato,
                              ),
                            ),
                          ),
                          if (etiqueta != null) ...[
                            const SizedBox(width: Esp.s),
                            etiqueta!,
                          ],
                        ],
                      ),
                      if (subtitulo != null && subtitulo!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitulo!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium,
                        ),
                      ],
                      if (datos.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          datos.join('  ·  '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.apagado(),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<_AccionFila>(
                  tooltip: 'Acciones',
                  icon: const Icon(Icons.more_vert),
                  onSelected:
                      (accion) => switch (accion) {
                        _AccionFila.editar => onEditar(),
                        _AccionFila.eliminar => onEliminar(),
                      },
                  itemBuilder:
                      (_) => [
                        const PopupMenuItem<_AccionFila>(
                          value: _AccionFila.editar,
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Editar'),
                          ),
                        ),
                        PopupMenuItem<_AccionFila>(
                          value: _AccionFila.eliminar,
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.delete_outline,
                              color: cs.error,
                            ),
                            title: Text(
                              'Eliminar',
                              style: TextStyle(color: cs.error),
                            ),
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _AccionFila { editar, eliminar }

// Celdas

/// El texto de una celda de la tabla, recortado en vez de desbordado.
class CeldaTexto extends StatelessWidget {
  const CeldaTexto(
    this.texto, {
    super.key,
    this.fuerte = false,
    this.apagado = false,
    this.bajada,
  });

  final String texto;
  final bool fuerte;
  final bool apagado;

  /// Una segunda linea chica debajo (un alias, un detalle).
  final String? bajada;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final principal = Text(
      texto,
      maxLines: bajada == null ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style:
          apagado
              ? context.apagado()
              : tt.bodyMedium?.copyWith(
                fontWeight: fuerte ? Peso.dato : Peso.normal,
              ),
    );
    final b = bajada;
    if (b == null || b.isEmpty) return principal;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        principal,
        Text(
          b,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.apagado(),
        ),
      ],
    );
  }
}
