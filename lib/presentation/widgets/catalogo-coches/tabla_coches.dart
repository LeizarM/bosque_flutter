/// La planilla de vehículos para web y escritorio: columnas, acciones en la fila
/// y paginación. Las columnas se reparten el ancho con `flex` y no tienen ancho
/// fijo: con ocho datos cortos la tabla cabe desde 720 px sin scroll horizontal,
/// que es el mínimo con el que la pantalla elige tabla en vez de tarjetas.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/coche_entity.dart';
import 'package:bosque_flutter/presentation/widgets/catalogo-coches/acciones_coche.dart';

const double _altoCabecera = 40;
const double _altoFila = 52;

/// Tres botones de 40 más el aire de la celda.
const double _anchoAcciones = 136;

/// 15 entra sin scroll vertical en un monitor común.
const List<int> _tamaniosPagina = [15, 25, 50, 100];

class TablaCoches extends StatefulWidget {
  const TablaCoches({
    super.key,
    required this.filas,
    required this.onEditar,
    required this.onAccion,
    this.enCurso = const <int>{},
  });

  final List<CocheEntity> filas;

  /// Tocar la fila abre la ficha.
  final void Function(CocheEntity coche) onEditar;
  final void Function(CocheEntity coche, AccionCoche accion) onAccion;

  /// Los `idCoche` con una escritura viajando: sus botones quedan apagados para
  /// que un segundo toque no reenvíe la fila con datos viejos.
  final Set<int> enCurso;

  @override
  State<TablaCoches> createState() => _TablaCochesState();
}

class _TablaCochesState extends State<TablaCoches> {
  final _scroll = ScrollController();

  int _pagina = 1;
  int _porPagina = _tamaniosPagina.first;

  @override
  void didUpdateWidget(TablaCoches anterior) {
    super.didUpdateWidget(anterior);
    // Otro filtro, otro listado: quedarse en la página 3 de un resultado de una
    // sola página muestra una tabla vacía y parece que nada coincide.
    if (anterior.filas.length != widget.filas.length) {
      _pagina = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<_Col> get _columnas => [
    _Col(
      'PLACA',
      2,
      (c, f) => Text(
        placaLegible(f),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: c.numero(fuerte: true),
      ),
    ),
    _Col('MARCA', 2, (c, f) => _texto(c, f, oGuion(f.marca))),
    _Col('CLASE', 2, (c, f) => _texto(c, f, oGuion(f.clase))),
    _Col(
      'AÑO',
      1,
      (c, f) => Text(
        f.anio?.toString() ?? '--',
        style: c.numero(color: f.esActivo ? null : c.cs.onSurfaceVariant),
      ),
      alinear: Alignment.centerRight,
    ),
    _Col('COLOR', 2, (c, f) => _texto(c, f, oGuion(f.color))),
    _Col('SUCURSAL', 3, (c, f) => _texto(c, f, sucursalLegible(f))),
    _Col(
      'ESTADO',
      2,
      (c, f) => Etiqueta(
        texto: f.esActivo ? 'Activo' : 'Inactivo',
        tono: f.esActivo ? TonoEtiqueta.exito : TonoEtiqueta.neutro,
      ),
    ),
  ];

  /// Un vehículo dado de baja se ve apagado: sigue en la lista, pero no compite
  /// con los que están en uso.
  Widget _texto(BuildContext c, CocheEntity f, String valor) => Text(
    valor,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(c).textTheme.bodyMedium?.copyWith(
      color: f.esActivo ? null : Theme.of(c).colorScheme.onSurfaceVariant,
    ),
  );

  Widget _acciones(BuildContext context, CocheEntity f) {
    final cs = Theme.of(context).colorScheme;
    final ocupado = widget.enCurso.contains(f.idCoche);
    final placa = placaLegible(f);

    Widget boton(
      IconData icono,
      String ayuda,
      AccionCoche accion, {
      Color? color,
    }) => IconButton(
      icon: Icon(icono, size: 20, color: ocupado ? null : color),
      tooltip: ayuda,
      visualDensity: VisualDensity.compact,
      onPressed: ocupado ? null : () => widget.onAccion(f, accion),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        boton(Icons.edit_outlined, 'Editar el vehículo $placa', AccionCoche.editar),
        boton(
          f.esActivo ? Icons.block_outlined : Icons.restore_outlined,
          '${rotuloCambiarEstado(f)} el vehículo $placa',
          AccionCoche.cambiarEstado,
        ),
        boton(
          Icons.delete_outline,
          'Eliminar el vehículo $placa',
          AccionCoche.eliminar,
          color: cs.error,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final columnas = _columnas;

    final total = widget.filas.length;
    final paginas = math.max(1, (total / _porPagina).ceil());
    final pagina = _pagina.clamp(1, paginas);
    final desde = (pagina - 1) * _porPagina;
    final hasta = math.min(desde + _porPagina, total);
    final visibles = widget.filas.sublist(desde, hasta);

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(Esquina.media),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _cabecera(context, columnas),
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: EdgeInsets.zero,
                    itemExtent: _altoFila,
                    itemCount: visibles.length,
                    itemBuilder:
                        (context, i) => _fila(context, visibles[i], i, columnas),
                  ),
                ),
              ],
            ),
          ),
        ),
        _Paginador(
          pagina: pagina,
          paginas: paginas,
          primera: total == 0 ? 0 : desde + 1,
          ultima: hasta,
          total: total,
          porPagina: _porPagina,
          onPagina: (p) => setState(() => _pagina = p),
          onPorPagina:
              (n) => setState(() {
                _porPagina = n;
                _pagina = 1;
              }),
        ),
      ],
    );
  }

  Widget _cabecera(BuildContext context, List<_Col> columnas) {
    final cs = Theme.of(context).colorScheme;
    final estilo = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: Peso.titulo,
      letterSpacing: 0.6,
    );

    return Container(
      height: _altoCabecera,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          for (final c in columnas)
            Expanded(
              flex: c.flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Esp.s),
                child: Align(
                  alignment: c.alinear,
                  child: Text(
                    c.rotulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: estilo,
                  ),
                ),
              ),
            ),
          SizedBox(
            width: _anchoAcciones,
            child: Center(child: Text('ACCIONES', style: estilo)),
          ),
        ],
      ),
    );
  }

  Widget _fila(
    BuildContext context,
    CocheEntity f,
    int indice,
    List<_Col> columnas,
  ) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => widget.onEditar(f),
      child: Container(
        decoration: BoxDecoration(
          // El rayado cebra sale de la superficie del tema, no de un gris fijo:
          // el usuario elige entre nueve semillas y hay modo oscuro.
          color: indice.isEven ? Colors.transparent : cs.surfaceContainerLow,
          border: Border(bottom: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          children: [
            for (final c in columnas)
              Expanded(
                flex: c.flex,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Esp.s),
                  child: Align(
                    alignment: c.alinear,
                    child: c.celda(context, f),
                  ),
                ),
              ),
            SizedBox(
              width: _anchoAcciones,
              child: Center(child: _acciones(context, f)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Col {
  const _Col(this.rotulo, this.flex, this.celda, {this.alinear = Alignment.centerLeft});

  final String rotulo;
  final int flex;
  final Widget Function(BuildContext context, CocheEntity coche) celda;
  final Alignment alinear;
}

class _Paginador extends StatelessWidget {
  const _Paginador({
    required this.pagina,
    required this.paginas,
    required this.primera,
    required this.ultima,
    required this.total,
    required this.porPagina,
    required this.onPagina,
    required this.onPorPagina,
  });

  final int pagina;
  final int paginas;
  final int primera;
  final int ultima;
  final int total;
  final int porPagina;
  final ValueChanged<int> onPagina;
  final ValueChanged<int> onPorPagina;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final apagado = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.only(top: Esp.s),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Esp.l,
        runSpacing: Esp.s,
        children: [
          Text(
            total == 0
                ? 'Sin vehículos para mostrar'
                : 'Mostrando $primera-$ultima de $total vehículos',
            style: apagado,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Filas', style: apagado),
              const SizedBox(width: Esp.s),
              DropdownButton<int>(
                value: porPagina,
                isDense: true,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(Esquina.chica),
                items: [
                  for (final n in _tamaniosPagina)
                    DropdownMenuItem(value: n, child: Text('$n')),
                ],
                onChanged: (n) {
                  if (n != null) onPorPagina(n);
                },
              ),
              const SizedBox(width: Esp.m),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Página anterior',
                visualDensity: VisualDensity.compact,
                onPressed: pagina > 1 ? () => onPagina(pagina - 1) : null,
              ),
              Text('$pagina de $paginas', style: apagado),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Página siguiente',
                visualDensity: VisualDensity.compact,
                onPressed: pagina < paginas ? () => onPagina(pagina + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
