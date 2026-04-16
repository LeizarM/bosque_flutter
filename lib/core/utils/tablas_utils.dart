import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BosqueColumn<T> {
  final String label;
  final int flex;
  final Alignment alignment;
  final Widget Function(T item) cellBuilder;

  BosqueColumn({
    required this.label,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
    required this.cellBuilder,
  });
}

class BosqueFlatTable<T> extends StatelessWidget {
  final List<T> items;
  final List<BosqueColumn<T>> columns;
  final bool cargando;
  final String searchHint;
  final Function(String)? onSearch;
  final TextEditingController? searchController;
  final List<Widget>? extraFilters;
  final Widget Function(T item) mobileCardBuilder;
  final Widget? footer;

  // Propiedades de paginación integradas
  final int? currentPage;
  final int? totalPages;
  final int? firstRow;
  final int? lastRow;
  final void Function(int)? onPageChanged;

  final int? currentPageSize;
  final void Function(int)? onPageSizeChanged;

  const BosqueFlatTable({
    super.key,
    required this.items,
    required this.columns,
    required this.mobileCardBuilder,
    this.cargando = false,
    this.searchHint = 'Buscar...',
    this.onSearch,
    this.searchController,
    this.extraFilters,
    this.footer,
    this.currentPage,
    this.totalPages,
    this.firstRow,
    this.lastRow,
    this.onPageChanged,
    this.currentPageSize,
    this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    return Column(
      children: [
        _buildTopBar(context, isDesktop),

        // 1. CABECERA CON BORDES REDONDEADOS (Solo Desktop)
        if (isDesktop && items.isNotEmpty && !cargando)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF0D47A1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children:
                  columns.asMap().entries.map((entry) {
                    return _buildCell(
                      entry.value,
                      isHeader: true,
                      isLast: entry.key == columns.length - 1,
                    );
                  }).toList(),
            ),
          ),

        // 2. CUERPO
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 0),
            child:
                cargando
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                    ? const Center(child: Text('No se encontraron registros.'))
                    : _buildContent(isDesktop),
          ),
        ),

        if (footer != null)
          Padding(
            padding: EdgeInsets.only(bottom: isDesktop ? 16 : 80, top: 8),
            child: footer!,
          )
        else if (currentPage != null &&
            totalPages != null &&
            onPageChanged != null)
          Padding(
            padding: EdgeInsets.only(bottom: isDesktop ? 16 : 80, top: 8),
            child: SafeArea(
              child: BosquePaginator(
                currentPage: currentPage!,
                totalPages: totalPages!,
                firstRow: firstRow,
                lastRow: lastRow,
                onPageChanged: onPageChanged!,
                currentPageSize: currentPageSize,
                onPageSizeChanged: onPageSizeChanged,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(bool isDesktop) {
    if (!isDesktop) {
      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: items.length,
        itemBuilder: (context, index) => mobileCardBuilder(items[index]),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color:
                index.isEven
                    ? Colors.white
                    : Colors.blueGrey[50]!.withOpacity(0.3),
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
              left: BorderSide(color: Colors.grey[300]!),
              right: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children:
                columns.asMap().entries.map((entry) {
                  return _buildCell(
                    entry.value,
                    isHeader: false,
                    item: item,
                    isLast: entry.key == columns.length - 1,
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCell(
    BosqueColumn<T> col, {
    required bool isHeader,
    T? item,
    bool isLast = false,
  }) {
    return Expanded(
      flex: col.flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        alignment: col.alignment,
        decoration: BoxDecoration(
          // Divisores verticales notorios
          border:
              isLast
                  ? null
                  : Border(
                    right: BorderSide(
                      color: isHeader ? Colors.white24 : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
        ),
        child:
            isHeader
                ? Text(
                  col.label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                )
                : col.cellBuilder(item!),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child:
          isDesktop
              ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Buscador a la izquierda
                  _buildSearchField(350),
                  // Filtros a la derecha
                  if (extraFilters != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          extraFilters!
                              .map(
                                (f) => Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: f,
                                ),
                              )
                              .toList(),
                    ),
                ],
              )
              : Column(
                // En móvil se mantiene en columna
                children: [
                  _buildSearchField(double.infinity),
                  if (extraFilters != null) ...[
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: extraFilters!),
                  ],
                ],
              ),
    );
  }

  Widget _buildSearchField(double width) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: searchController,
        onChanged: onSearch,
        decoration: InputDecoration(
          hintText: searchHint,
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF0D47A1),
            size: 20,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

//________________________________________________________
// VERSIÓN DE TABLA CON ESTRUCTURA PADRE-HIJO (ÁRBOL) OPTIMIZADA PARA GRANDES CANTIDADES DE DATOS
//________________________________________________________
class BosqueTreeColumn<T> {
  final String label;
  final int flex;
  final Alignment alignment;
  // Ahora el builder recibe el nivel (0 = padre, 1 = hijo) para poder aplicar negritas o estilos
  final Widget Function(T item, int nivel) cellBuilder;

  BosqueTreeColumn({
    required this.label,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
    required this.cellBuilder,
  });
}

class BosqueTreeTable<T> extends StatefulWidget {
  final List<T> items;
  final List<BosqueTreeColumn<T>> columns;
  final String Function(T)
  idMapper; // Para identificar cada fila y su estado de expansión
  final List<T> Function(T) childrenMapper; // Para obtener los hijos

  // Callbacks de estilo para hacerlo reutilizable en otras pantallas
  final BoxDecoration Function(T item, int index, int nivel)?
  rowDecorationBuilder;
  final bool cargando;

  const BosqueTreeTable({
    super.key,
    required this.items,
    required this.columns,
    required this.idMapper,
    required this.childrenMapper,
    this.rowDecorationBuilder,
    this.cargando = false,
  });

  @override
  State<BosqueTreeTable<T>> createState() => _BosqueTreeTableState<T>();
}

class _TreeRow<T> {
  final T item;
  final int nivel;
  final int
  originalIndex; // Para alternar colores (par/impar) basado en el padre
  _TreeRow(this.item, this.nivel, this.originalIndex);
}

class _BosqueTreeTableState<T> extends State<BosqueTreeTable<T>> {
  final Map<String, bool> _expandedMap = {};

  // Método ultra-optimizado que "aplana" el árbol para usar un ListView.builder nativo
  List<_TreeRow<T>> _flattenTree() {
    List<_TreeRow<T>> result = [];
    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      result.add(_TreeRow(item, 0, i));

      final id = widget.idMapper(item);
      if (_expandedMap[id] == true) {
        final children = widget.childrenMapper(item);
        for (var child in children) {
          result.add(
            _TreeRow(child, 1, i),
          ); // Hijos mantienen el índice del padre para el color base si se desea
        }
      }
    }
    return result;
  }

  void _toggleExpand(String id) {
    setState(() {
      _expandedMap[id] = !(_expandedMap[id] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.items.isEmpty) {
      return const Center(child: Text('No hay datos para mostrar.'));
    }

    final flatList = _flattenTree();

    return Column(
      children: [
        // CABECERA
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D47A1),
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 40), // Espacio para el icono de expandir
              ...widget.columns.asMap().entries.map((entry) {
                return _buildHeaderCell(
                  entry.value,
                  isLast: entry.key == widget.columns.length - 1,
                );
              }),
            ],
          ),
        ),

        // CUERPO (Optimizado)
        Expanded(
          child: ListView.builder(
            itemCount: flatList.length,
            itemBuilder: (context, index) {
              final rowData = flatList[index];
              final item = rowData.item;
              final nivel = rowData.nivel;
              final children = widget.childrenMapper(item);
              final hasChildren = children.isNotEmpty;
              final id = widget.idMapper(item);
              final isExpanded = _expandedMap[id] ?? false;

              // Decoración por defecto o personalizada
              final decoration =
                  widget.rowDecorationBuilder != null
                      ? widget.rowDecorationBuilder!(
                        item,
                        rowData.originalIndex,
                        nivel,
                      )
                      : BoxDecoration(
                        color:
                            rowData.originalIndex % 2 == 0
                                ? Colors.white
                                : Colors.grey[100],
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
                        ),
                      );

              return Container(
                decoration: decoration,
                child: Row(
                  children: [
                    // Columna fija para el icono de expandir
                    SizedBox(
                      width: 40,
                      child:
                          hasChildren
                              ? IconButton(
                                icon: Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Colors.blue[800],
                                ),
                                onPressed: () => _toggleExpand(id),
                              )
                              : null,
                    ),
                    // Celdas de datos
                    ...widget.columns.asMap().entries.map((entry) {
                      return _buildDataCell(
                        entry.value,
                        item,
                        nivel,
                        isLast: entry.key == widget.columns.length - 1,
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(BosqueTreeColumn<T> col, {bool isLast = false}) {
    return Expanded(
      flex: col.flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        alignment: col.alignment,
        decoration: BoxDecoration(
          border:
              isLast
                  ? null
                  : const Border(
                    right: BorderSide(color: Colors.white24, width: 1),
                  ),
        ),
        child: Text(
          col.label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(
    BosqueTreeColumn<T> col,
    T item,
    int nivel, {
    bool isLast = false,
  }) {
    return Expanded(
      flex: col.flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        alignment: col.alignment,
        decoration: BoxDecoration(
          border:
              isLast
                  ? null
                  : Border(
                    right: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
        ),
        child: col.cellBuilder(item, nivel),
      ),
    );
  }
}

//________________________________________________________
//extension para mostrar SnackBar de éxito o error basado en el estado de los providers
//________________________________________________________
//listener para mostrar SnackBar de éxito o error basado en el estado de los providers
extension SnackbarListener on WidgetRef {
  void listenMessages(
    ProviderListenable<dynamic> provider,
    BuildContext context,
  ) {
    listen<dynamic>(provider, (previous, next) {
      // 1. EVALUAR MENSAJE DE ÉXITO
      try {
        if (next.mensajeExito != null && next.mensajeExito.isNotEmpty) {
          // Solo se dispara si no había estado previo, o si el mensaje es DIFERENTE al anterior
          if (previous == null || previous.mensajeExito != next.mensajeExito) {
            _showCustomSnackBar(context, next.mensajeExito, Colors.green);
          }
        }
      } catch (
        _
      ) {} // Falla en silencio si el módulo no tiene la variable 'mensajeExito'

      // 2. EVALUAR MENSAJE DE ERROR
      try {
        if (next.mensajeError != null && next.mensajeError.isNotEmpty) {
          if (previous == null || previous.mensajeError != next.mensajeError) {
            _showCustomSnackBar(context, next.mensajeError, Colors.red);
          }
        }
      } catch (_) {} // Falla en silencio si no tiene 'mensajeError'

      // 3. EVALUAR MENSAJE DE ADVERTENCIA (Para CambiosTigo u otros futuros)
      try {
        if (next.mensajeAdvertencia != null &&
            next.mensajeAdvertencia.isNotEmpty) {
          if (previous == null ||
              previous.mensajeAdvertencia != next.mensajeAdvertencia) {
            _showCustomSnackBar(
              context,
              next.mensajeAdvertencia,
              Colors.orange,
            );
          }
        }
      } catch (_) {} // Falla en silencio si no tiene 'mensajeAdvertencia'
    });
  }

  void _showCustomSnackBar(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

//________________________________________________________
// COMPONENTE DE PAGINACIÓN GENÉRICO PARA LAS TABLAS
//________________________________________________________
class BosquePaginator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int? firstRow;
  final int? lastRow;
  final void Function(int) onPageChanged;

  final int? currentPageSize;
  final void Function(int)? onPageSizeChanged;

  const BosquePaginator({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.firstRow,
    this.lastRow,
    this.currentPageSize,
    this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final hPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final hayAnterior = currentPage > 1;
    final hayMas = currentPage < totalPages;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (currentPageSize != null && onPageSizeChanged != null) ...[
            Text(
              'Filas:',
              style: TextStyle(fontSize: 13, color: Colors.blueGrey[600]),
            ),
            const SizedBox(width: 6),
            DropdownButton<int>(
              value:
                  [10, 15, 25, 50].contains(currentPageSize)
                      ? currentPageSize
                      : 15,
              underline: const SizedBox(),
              isDense: true,
              borderRadius: BorderRadius.circular(8),
              items:
                  [10, 15, 25, 50]
                      .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                      .toList(),
              onChanged: (n) {
                if (n != null) onPageSizeChanged!(n);
              },
            ),
            const SizedBox(width: 16),
          ],
          Tooltip(
            message: 'Página anterior',
            child: InkWell(
              onTap: hayAnterior ? () => onPageChanged(currentPage - 1) : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: hayAnterior ? Colors.blue[700] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: hayAnterior ? Colors.white : Colors.grey[400],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              'Página $currentPage de $totalPages',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blue[800],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Página siguiente',
            child: InkWell(
              onTap: hayMas ? () => onPageChanged(currentPage + 1) : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: hayMas ? Colors.blue[700] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: hayMas ? Colors.white : Colors.grey[400],
                ),
              ),
            ),
          ),
          if (!isMobile &&
              firstRow != null &&
              lastRow != null &&
              firstRow! > 0) ...[
            const SizedBox(width: 16),
            Text(
              '$firstRow – $lastRow',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey[500]),
            ),
          ],
        ],
      ),
    );
  }
}
