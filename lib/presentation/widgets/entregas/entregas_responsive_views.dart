import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/entregas_entity.dart';
import 'package:bosque_flutter/presentation/widgets/entregas/entregas_data_table_source.dart';
import 'package:bosque_flutter/presentation/widgets/entregas/entrega_item.dart';

class EntregasDesktopView extends StatelessWidget {
  final List<MapEntry<int, List<EntregaEntity>>> filteredEntregas;
  final bool rutaIniciada;
  final Function(EntregaEntity) onMarcarEntrega;
  final int? sortColumnIndex;
  final bool sortAscending;
  final Function(int, bool) onSort;

  const EntregasDesktopView({
    Key? key,
    required this.filteredEntregas,
    required this.rutaIniciada,
    required this.onMarcarEntrega,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
            ),
            child: SingleChildScrollView(
              child: PaginatedDataTable(
                columns: [
                  DataColumn(
                    label: const Text('Cliente'),
                    onSort: (i, asc) => onSort(i, asc),
                  ),
                  DataColumn(
                    label: const Text('Factura'),
                    numeric: true,
                    onSort: (i, asc) => onSort(i, asc),
                  ),
                  DataColumn(
                    label: const Text('Fecha'),
                    onSort: (i, asc) => onSort(i, asc),
                  ),
                  DataColumn(
                    label: const Text('Dirección'),
                    onSort: (i, asc) => onSort(i, asc),
                  ),
                  DataColumn(
                    label: const Text('Estado'),
                    onSort: (i, asc) => onSort(i, asc),
                  ),
                  const DataColumn(label: Text('Acción')),
                ],
                source: EntregasDataTableSource(
                  entregasAgrupadas: filteredEntregas,
                  rutaIniciada: rutaIniciada,
                  onMarcarEntrega: onMarcarEntrega,
                  context: context,
                ),
                rowsPerPage: 8,
                columnSpacing: 24,
                showCheckboxColumn: false,
                sortColumnIndex: sortColumnIndex,
                sortAscending: sortAscending,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 120,
              ),
            ),
          );
        },
      ),
    );
  }
}

class EntregasTabletView extends StatelessWidget {
  final List<MapEntry<int, List<EntregaEntity>>> entregasAgrupadas;
  final bool rutaIniciada;
  final Function(EntregaEntity) onMarcarEntrega;

  const EntregasTabletView({
    Key? key,
    required this.entregasAgrupadas,
    required this.rutaIniciada,
    required this.onMarcarEntrega,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          mainAxisSpacing: ResponsiveUtilsBosque.getGridDimensions(context).mainAxisSpacing,
          crossAxisSpacing: ResponsiveUtilsBosque.getGridDimensions(context).crossAxisSpacing,
          childAspectRatio: 1,
        ),
        itemCount: entregasAgrupadas.length,
        itemBuilder: (context, index) {
          final entregas = entregasAgrupadas[index].value;
          final entregaPrimaria = entregas.first;
          final todosEntregados = entregas.every((e) => e.fueEntregado == 1);
          final algunoEntregado = entregas.any((e) => e.fueEntregado == 1);

          return EntregaItem(
            entrega: entregaPrimaria,
            productosAdicionalesEntrega: entregas,
            rutaIniciada: rutaIniciada,
            onTap: () => onMarcarEntrega(entregaPrimaria),
            disabled: !rutaIniciada || todosEntregados,
            todosEntregados: todosEntregados,
            algunoEntregado: algunoEntregado,
          );
        },
      ),
    );
  }
}

class EntregasMobileView extends StatelessWidget {
  final List<MapEntry<int, List<EntregaEntity>>> entregasAgrupadas;
  final bool rutaIniciada;
  final Function(EntregaEntity) onMarcarEntrega;

  const EntregasMobileView({
    Key? key,
    required this.entregasAgrupadas,
    required this.rutaIniciada,
    required this.onMarcarEntrega,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      itemCount: entregasAgrupadas.length,
      itemBuilder: (context, index) {
        final entregas = entregasAgrupadas[index].value;
        final entregaPrimaria = entregas.first;
        final todosEntregados = entregas.every((e) => e.fueEntregado == 1);
        final algunoEntregado = entregas.any((e) => e.fueEntregado == 1);

        return EntregaItem(
          entrega: entregaPrimaria,
          productosAdicionalesEntrega: entregas,
          rutaIniciada: rutaIniciada,
          onTap: () => onMarcarEntrega(entregaPrimaria),
          disabled: !rutaIniciada || todosEntregados,
          todosEntregados: todosEntregados,
          algunoEntregado: algunoEntregado,
        );
      },
    );
  }
}