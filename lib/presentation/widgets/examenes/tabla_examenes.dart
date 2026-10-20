/// La lista de las pantallas del módulo: tabla con acciones en fila y
/// paginación si el contenedor es ancho; tarjetas con menú si es angosto. Mide
/// el contenedor (`LayoutBuilder`), no la ventana: el menú lateral resta ancho.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';

class ColumnaExamen<T> {
  const ColumnaExamen(this.rotulo, this.celda, {this.flex = 2, this.alinear = Alignment.centerLeft});

  final String rotulo;
  final Widget Function(T fila) celda;
  final int flex;
  final Alignment alinear;
}

class AccionExamen<T> {
  const AccionExamen(
    this.etiqueta,
    this.icono,
    this.alTocar, {
    this.destructiva = false,
    this.visible,
    this.tono = TonoExamen.principal,
  });

  final String etiqueta;
  final IconData icono;
  final void Function(T fila) alTocar;
  final bool destructiva;

  /// Si la acción aplica a esta fila. Null = siempre.
  final bool Function(T fila)? visible;

  /// El color del icono; una destructiva va siempre en alerta.
  final TonoExamen tono;

  Color colorEn(ColorScheme cs) => coloresDeTono(cs, destructiva ? TonoExamen.alerta : tono).acento;
}

class TablaExamenes<T> extends StatefulWidget {
  const TablaExamenes({
    super.key,
    required this.filas,
    required this.columnas,
    required this.tarjeta,
    this.acciones = const [],
    this.alTocarFila,
    this.accionesEnLinea = 3,
    this.vacio,
    this.claveFila,
    this.hayBotonFlotante = false,
    this.tonoFila,
  });

  final List<T> filas;
  final List<ColumnaExamen<T>> columnas;

  /// El contenido de la tarjeta en el teléfono (sin el menú: lo agrega la tabla).
  final Widget Function(T fila) tarjeta;
  final List<AccionExamen<T>> acciones;
  final void Function(T fila)? alTocarFila;

  /// Cuántas acciones van como icono en la fila; el resto en "Más".
  final int accionesEnLinea;
  final Widget? vacio;
  final Object Function(T fila)? claveFila;

  /// La pantalla tiene un botón flotante: en el teléfono la paginación sube para no quedar debajo.
  final bool hayBotonFlotante;

  /// La franja de color a la izquierda de cada fila (o tarjeta): su estado o tipo.
  final TonoExamen? Function(T fila)? tonoFila;

  @override
  State<TablaExamenes<T>> createState() => _TablaExamenesState<T>();
}

class _TablaExamenesState<T> extends State<TablaExamenes<T>> {
  static const _tamanios = [15, 25, 50, 100];
  int _pagina = 1;
  int _porPagina = _tamanios.first;
  final _scrollTabla = ScrollController();
  final _scrollTarjetas = ScrollController();

  @override
  void didUpdateWidget(TablaExamenes<T> anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.filas.length != widget.filas.length) _pagina = 1;
  }

  @override
  void dispose() {
    _scrollTabla.dispose();
    _scrollTarjetas.dispose();
    super.dispose();
  }

  /// Cambia de página y vuelve arriba: la página nueva se lee desde su primera fila.
  void _irAPagina(int p) {
    setState(() => _pagina = p);
    for (final c in [_scrollTabla, _scrollTarjetas]) {
      if (c.hasClients) c.jumpTo(0);
    }
  }

  List<AccionExamen<T>> _accionesDe(T fila) => [
    for (final a in widget.acciones)
      if (a.visible == null || a.visible!(fila)) a,
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.filas.isEmpty) {
      return widget.vacio ?? const SizedBox.shrink();
    }
    final total = widget.filas.length;
    final paginas = math.max(1, (total / _porPagina).ceil());
    final pagina = _pagina.clamp(1, paginas);
    final desde = (pagina - 1) * _porPagina;
    final hasta = math.min(desde + _porPagina, total);
    final visibles = widget.filas.sublist(desde, hasta);

    return LayoutBuilder(
      builder: (context, r) {
        final compacto = r.maxWidth < anchoTablaExamenes;
        return Column(
          children: [
            Expanded(child: compacto ? _tarjetas(visibles) : _tabla(context, visibles)),
            // En el teléfono, una sola página no necesita paginación: las tarjetas ya se cuentan solas.
            if (!compacto || paginas > 1) _paginacion(context, total, desde, hasta, pagina, paginas, compacto),
          ],
        );
      },
    );
  }

  Widget _tabla(BuildContext context, List<T> visibles) {
    final cs = Theme.of(context).colorScheme;
    final estilo = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: cs.onPrimaryContainer, fontWeight: Peso.titulo, letterSpacing: 0.6);
    // Con franja, la cabecera reserva su ancho para que las columnas sigan alineadas.
    final conFranja = widget.tonoFila != null;
    final enLinea = math.min(widget.accionesEnLinea, widget.acciones.length);
    final hayMas = widget.acciones.length > enLinea;
    // 48 px por acción: el objetivo táctil mínimo, también con el mouse.
    final anchoAcciones = widget.acciones.isEmpty ? 0.0 : (enLinea + (hayMas ? 1 : 0)) * 48.0 + Esp.s;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: Esp.s),
            decoration: BoxDecoration(
              color: Color.alphaBlend(cs.primaryContainer.withValues(alpha: 0.7), cs.surface),
              border: Border(
                bottom: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                left: conFranja ? const BorderSide(color: Colors.transparent, width: 4) : BorderSide.none,
              ),
            ),
            child: Row(
              children: [
                for (final c in widget.columnas)
                  Expanded(
                    flex: c.flex,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Esp.s),
                      child: Align(
                        alignment: c.alinear,
                        child: Text(
                          c.rotulo.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: estilo,
                        ),
                      ),
                    ),
                  ),
                if (anchoAcciones > 0) SizedBox(width: anchoAcciones),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: _scrollTabla,
              child: ListView.separated(
                controller: _scrollTabla,
                padding: EdgeInsets.zero,
                itemCount: visibles.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant),
                itemBuilder: (context, i) {
                  final fila = visibles[i];
                  final acciones = _accionesDe(fila);
                  return Semantics(
                    key: widget.claveFila == null ? null : ValueKey(widget.claveFila!(fila)),
                    button: widget.alTocarFila != null,
                    child: InkWell(
                      onTap: widget.alTocarFila == null ? null : () => widget.alTocarFila!(fila),
                      hoverColor: cs.primary.withValues(alpha: 0.06),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 56),
                        decoration: BoxDecoration(border: _franja(cs, fila)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: Esp.s),
                          child: Row(
                            children: [
                              for (final c in widget.columnas)
                                Expanded(
                                  flex: c.flex,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: Esp.s),
                                    child: Align(alignment: c.alinear, child: c.celda(fila)),
                                  ),
                                ),
                              if (anchoAcciones > 0)
                                SizedBox(
                                  width: anchoAcciones,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      for (final a in acciones.take(enLinea))
                                        IconButton(
                                          tooltip: a.etiqueta,
                                          style: IconButton.styleFrom(
                                            foregroundColor: a.colorEn(cs),
                                            hoverColor: a.colorEn(cs).withValues(alpha: 0.1),
                                          ),
                                          icon: Icon(a.icono, size: 20, color: a.colorEn(cs)),
                                          onPressed: () => a.alTocar(fila),
                                        ),
                                      if (acciones.length > enLinea) _menu(acciones.skip(enLinea).toList(), fila),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Al pie, el alto de la barra del sistema más el del botón flotante: la
  // última tarjeta nunca queda tapada.
  Widget _tarjetas(List<T> visibles) => Scrollbar(
    controller: _scrollTarjetas,
    child: ListView.separated(
      controller: _scrollTarjetas,
      padding: EdgeInsets.only(bottom: 88 + MediaQuery.viewPaddingOf(context).bottom),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: visibles.length,
      separatorBuilder: (_, __) => const SizedBox(height: Esp.s),
      itemBuilder: (context, i) {
        final fila = visibles[i];
        final acciones = _accionesDe(fila);
        final cs = Theme.of(context).colorScheme;
        return Semantics(
          key: widget.claveFila == null ? null : ValueKey(widget.claveFila!(fila)),
          button: widget.alTocarFila != null,
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: cs.surfaceContainerLowest,
            shape: contornoSuperficie(cs),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.alTocarFila == null ? null : () => widget.alTocarFila!(fila),
              child: Container(
                decoration: BoxDecoration(border: _franja(cs, fila)),
                padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.xs, Esp.m),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: widget.tarjeta(fila)),
                    if (acciones.isNotEmpty) _menu(acciones, fila) else const SizedBox(width: Esp.m),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  /// La franja izquierda de la fila con el acento de su tono; null sin [TablaExamenes.tonoFila].
  Border? _franja(ColorScheme cs, T fila) {
    if (widget.tonoFila == null) return null;
    final tono = widget.tonoFila!(fila);
    final color = tono == null ? Colors.transparent : coloresDeTono(cs, tono).acento;
    return Border(left: BorderSide(color: color, width: 4));
  }

  Widget _menu(List<AccionExamen<T>> acciones, T fila) => PopupMenuButton<int>(
    tooltip: 'Más acciones',
    icon: const Icon(Icons.more_vert),
    onSelected: (i) => acciones[i].alTocar(fila),
    itemBuilder:
        (context) => [
          for (var i = 0; i < acciones.length; i++)
            PopupMenuItem(
              value: i,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(acciones[i].icono, color: acciones[i].colorEn(Theme.of(context).colorScheme)),
                title: Text(acciones[i].etiqueta),
              ),
            ),
        ],
  );

  Widget _paginacion(BuildContext context, int total, int desde, int hasta, int pagina, int paginas, bool compacto) =>
      Padding(
        padding: EdgeInsets.only(top: Esp.s, bottom: compacto && widget.hayBotonFlotante ? 72 : 0),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Esp.l,
          runSpacing: Esp.xs,
          children: [
            Text('${desde + 1}–$hasta de $total', style: context.apagado()),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!compacto) ...[
                  Text('Filas', style: context.apagado()),
                  const SizedBox(width: Esp.s),
                  DropdownButton<int>(
                    value: _porPagina,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    items: [for (final n in _tamanios) DropdownMenuItem(value: n, child: Text('$n'))],
                    onChanged: (n) {
                      if (n != null) {
                        setState(() {
                          _porPagina = n;
                          _pagina = 1;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: Esp.m),
                ],
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Página anterior',
                  onPressed: pagina > 1 ? () => _irAPagina(pagina - 1) : null,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.xs),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(Esquina.pastilla),
                  ),
                  child: Text(
                    '$pagina de $paginas',
                    style: context
                        .numero(fuerte: true, color: Theme.of(context).colorScheme.onPrimaryContainer)
                        ?.copyWith(fontFamily: fuenteFija),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Página siguiente',
                  onPressed: pagina < paginas ? () => _irAPagina(pagina + 1) : null,
                ),
              ],
            ),
          ],
        ),
      );
}

/// Texto de celda: una línea, con puntos suspensivos.
class CeldaTexto extends StatelessWidget {
  const CeldaTexto(this.texto, {super.key, this.fuerte = false, this.apagado = false, this.lineas = 1});

  final String? texto;
  final bool fuerte;
  final bool apagado;
  final int lineas;

  @override
  Widget build(BuildContext context) => Text(
    (texto == null || texto!.trim().isEmpty) ? '--' : texto!,
    maxLines: lineas,
    overflow: TextOverflow.ellipsis,
    style:
        apagado
            ? context.apagado()
            : Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: fuerte ? Peso.titulo : null),
  );
}

/// Número de celda, con cifras tabulares.
class CeldaNumero extends StatelessWidget {
  const CeldaNumero(this.texto, {super.key, this.fuerte = false, this.color});

  final String texto;
  final bool fuerte;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(texto, maxLines: 1, style: context.numero(fuerte: fuerte, color: color));
}
