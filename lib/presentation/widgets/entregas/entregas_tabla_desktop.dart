import 'package:flutter/material.dart';

import 'package:bosque_flutter/domain/entities/entregas_entity.dart';
import 'package:bosque_flutter/presentation/widgets/entregas/entregas_ui.dart';

/// Tabla de entregas para escritorio.
///
/// <h3>Por qué no es un `PaginatedDataTable`</h3>
/// El anterior lo era, con `rowsPerPage: 8`. Ese widget reserva SIEMPRE las 8
/// filas aunque haya una sola entrega: de ahí las cuatro franjas vacías
/// gigantes debajo del único registro. No era un problema de estilo sino del
/// componente elegido — un paginador tiene sentido con cientos de filas, y acá
/// un chofer ve entre una y quince entregas en el día.
///
/// Se reemplaza por una lista con encabezado fijo que dibuja exactamente las
/// filas que existen. De paso desaparece la barra de paginación ("Filas por
/// página / 1-1 de 1") que tampoco aportaba nada con este volumen.
class EntregasTablaDesktop extends StatelessWidget {
  final List<MapEntry<int, List<EntregaEntity>>> filteredEntregas;
  final bool rutaIniciada;
  final void Function(EntregaEntity) onMarcarEntrega;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int, bool) onSort;

  const EntregasTablaDesktop({
    super.key,
    required this.filteredEntregas,
    required this.rutaIniciada,
    required this.onMarcarEntrega,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
  });

  // Proporciones de columna. Suman 100. La dirección se lleva la mitad porque
  // es el dato más largo y el que el chofer realmente lee.
  // Los pesos se ajustaron contra el ancho real que pide cada contenido, no a
  // ojo: con ESTADO en 11 la pastilla "Entregado" no entraba a 1024 px y se
  // recortaba con puntos suspensivos, que en una columna de estado es inútil.
  static const _flexCliente = 26;
  static const _flexFactura = 9;
  static const _flexFecha = 11;
  static const _flexDireccion = 30;
  static const _flexEstado = 15;
  static const _anchoAccion = 108.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: EntregasUI.maxContentWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            EntregasUI.padH(context),
            EntregasUI.s2,
            EntregasUI.padH(context),
            EntregasUI.padV(context),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: EntregasUI.raised(cs),
              borderRadius: BorderRadius.circular(EntregasUI.rContainer),
              border: Border.all(color: EntregasUI.hairline(cs)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Encabezado(
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: sortAscending,
                  onSort: onSort,
                ),
                Divider(height: 1, thickness: 1, color: EntregasUI.hairline(cs)),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: filteredEntregas.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      color: EntregasUI.hairline(cs),
                    ),
                    itemBuilder: (context, index) {
                      final entregas = filteredEntregas[index].value;
                      final primaria = entregas.first;
                      final todosEntregados =
                          entregas.every((e) => e.fueEntregado == 1);
                      return _Fila(
                        entrega: primaria,
                        cantidadProductos: entregas.length,
                        entregado: todosEntregados,
                        habilitado: rutaIniciada && !todosEntregados,
                        onMarcar: () => onMarcarEntrega(primaria),
                        esUltima: index == filteredEntregas.length - 1,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int, bool) onSort;

  const _Encabezado({
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EntregasUI.s5,
        vertical: EntregasUI.s3,
      ),
      child: Row(
        children: [
          _Col(
            flex: EntregasTablaDesktop._flexCliente,
            child: _LabelOrdenable(
              texto: 'CLIENTE',
              indice: 0,
              sortColumnIndex: sortColumnIndex,
              sortAscending: sortAscending,
              onSort: onSort,
            ),
          ),
          _Col(
            flex: EntregasTablaDesktop._flexFactura,
            alineacion: Alignment.centerRight,
            child: _LabelOrdenable(
              texto: 'FACTURA',
              indice: 1,
              alDerecha: true,
              sortColumnIndex: sortColumnIndex,
              sortAscending: sortAscending,
              onSort: onSort,
            ),
          ),
          _Col(
            flex: EntregasTablaDesktop._flexFecha,
            child: _LabelOrdenable(
              texto: 'FECHA',
              indice: 2,
              sortColumnIndex: sortColumnIndex,
              sortAscending: sortAscending,
              onSort: onSort,
            ),
          ),
          _Col(
            flex: EntregasTablaDesktop._flexDireccion,
            child: _LabelOrdenable(
              texto: 'DIRECCIÓN',
              indice: 3,
              sortColumnIndex: sortColumnIndex,
              sortAscending: sortAscending,
              onSort: onSort,
            ),
          ),
          _Col(
            flex: EntregasTablaDesktop._flexEstado,
            child: Text('ESTADO', style: EntregasUI.columnLabel(context)),
          ),
          SizedBox(
            width: EntregasTablaDesktop._anchoAccion,
            child: Text(
              'ACCIÓN',
              textAlign: TextAlign.right,
              style: EntregasUI.columnLabel(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelOrdenable extends StatelessWidget {
  final String texto;
  final int indice;
  final bool alDerecha;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int, bool) onSort;

  const _LabelOrdenable({
    required this.texto,
    required this.indice,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
    this.alDerecha = false,
  });

  @override
  Widget build(BuildContext context) {
    final activo = sortColumnIndex == indice;
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onSort(indice, activo ? !sortAscending : true),
      borderRadius: BorderRadius.circular(EntregasUI.rInner),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              alDerecha ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            // Flexible + ellipsis: sin esto el Text toma su ancho intrínseco y
            // en la columna FACTURA (flex 9) desborda 16 px a 1024 de ancho.
            // Un Row con mainAxisSize.min no achica a sus hijos: los deja
            // pasarse y pinta la franja amarilla y negra.
            Flexible(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: EntregasUI.columnLabel(context).copyWith(
                  color: activo ? cs.onSurface : EntregasUI.muted(cs),
                ),
              ),
            ),
            // La flecha solo aparece en la columna por la que se está ordenando.
            // Mostrarla siempre en gris (como hacía DataTable al pasar el mouse)
            // llena el encabezado de ruido y no dice cuál está activa.
            if (activo) ...[
              const SizedBox(width: 2),
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: cs.onSurface,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Una fila. `StatefulWidget` solo para el hover: en escritorio, una tabla sin
/// respuesta al mouse se siente muerta y además cuesta seguir la fila con la
/// vista cuando la dirección ocupa dos renglones.
class _Fila extends StatefulWidget {
  final EntregaEntity entrega;
  final int cantidadProductos;
  final bool entregado;
  final bool habilitado;
  final VoidCallback onMarcar;
  final bool esUltima;

  const _Fila({
    required this.entrega,
    required this.cantidadProductos,
    required this.entregado,
    required this.habilitado,
    required this.onMarcar,
    required this.esUltima,
  });

  @override
  State<_Fila> createState() => _FilaState();
}

class _FilaState extends State<_Fila> {
  bool _hover = false;

  String get _fecha {
    final d = widget.entrega.docDate;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _hover ? cs.onSurface.withValues(alpha: 0.035) : null,
          borderRadius: widget.esUltima
              ? const BorderRadius.vertical(
                  bottom: Radius.circular(EntregasUI.rContainer),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: EntregasUI.s5,
          vertical: EntregasUI.s4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Col(
              flex: EntregasTablaDesktop._flexCliente,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.entrega.cardName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: cs.onSurface,
                    ),
                  ),
                  // El conteo de productos vivía solo en el encabezado global
                  // ("Productos: 2"), donde no se sabía a qué factura pertenecía.
                  if (widget.cantidadProductos > 1) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${widget.cantidadProductos} productos',
                      style: TextStyle(
                        fontSize: 12,
                        color: EntregasUI.muted(cs),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _Col(
              flex: EntregasTablaDesktop._flexFactura,
              alineacion: Alignment.centerRight,
              child: Text(
                widget.entrega.factura.toString(),
                textAlign: TextAlign.right,
                style: EntregasUI.numeric(context, color: cs.onSurface),
              ),
            ),
            _Col(
              flex: EntregasTablaDesktop._flexFecha,
              child: Text(
                _fecha,
                style: EntregasUI.numeric(
                  context,
                  weight: FontWeight.w400,
                  color: EntregasUI.muted(cs),
                ),
              ),
            ),
            _Col(
              flex: EntregasTablaDesktop._flexDireccion,
              child: Text(
                // La dirección venía con saltos de línea del SAP y estiraba la
                // fila a tres renglones. Se aplanan y se corta con elipsis: el
                // detalle completo está en el diálogo al marcar.
                widget.entrega.addressEntregaMat
                    .replaceAll(RegExp(r'\s+'), ' ')
                    .trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(height: 1.35, color: EntregasUI.muted(cs)),
              ),
            ),
            _Col(
              flex: EntregasTablaDesktop._flexEstado,
              child: Align(
                alignment: Alignment.centerLeft,
                child: EstadoEntregaPill(entregado: widget.entregado),
              ),
            ),
            SizedBox(
              width: EntregasTablaDesktop._anchoAccion,
              child: Align(
                alignment: Alignment.centerRight,
                child: widget.entregado
                    // Ya entregada: no se muestra un botón gris que invita a
                    // hacer clic y no hace nada. Se muestra el hecho.
                    ? Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: EntregasUI.muted(cs),
                      )
                    : FilledButton(
                        onPressed: widget.habilitado ? widget.onMarcar : null,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: EntregasUI.s4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(EntregasUI.rInner),
                          ),
                        ),
                        child: const Text('Marcar'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Col extends StatelessWidget {
  final int flex;
  final Widget child;
  final Alignment alineacion;

  const _Col({
    required this.flex,
    required this.child,
    this.alineacion = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: EntregasUI.s4),
        child: Align(alignment: alineacion, child: child),
      ),
    );
  }
}
