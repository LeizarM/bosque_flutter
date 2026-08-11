import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:flutter/material.dart';
import 'package:bosque_flutter/domain/entities/entregas_entity.dart';
import 'package:bosque_flutter/presentation/widgets/entregas/entregas_tabla_desktop.dart';
import 'package:bosque_flutter/presentation/widgets/entregas/entrega_item.dart';

class EntregasDesktopView extends StatelessWidget {
  final List<MapEntry<int, List<EntregaEntity>>> filteredEntregas;
  final bool rutaIniciada;
  final Function(EntregaEntity) onMarcarEntrega;
  final int? sortColumnIndex;
  final bool sortAscending;
  final Function(int, bool) onSort;

  const EntregasDesktopView({
    super.key,
    required this.filteredEntregas,
    required this.rutaIniciada,
    required this.onMarcarEntrega,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    // El PaginatedDataTable que estaba acá reservaba 8 filas fijas (rowsPerPage)
    // aunque hubiera una sola entrega: eso eran las franjas vacias enormes.
    // EntregasTablaDesktop dibuja solo las filas que existen.
    return EntregasTablaDesktop(
      filteredEntregas: filteredEntregas,
      rutaIniciada: rutaIniciada,
      onMarcarEntrega: onMarcarEntrega,
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      onSort: onSort,
    );
  }
}

class EntregasTabletView extends StatelessWidget {
  final List<MapEntry<int, List<EntregaEntity>>> entregasAgrupadas;
  final bool rutaIniciada;
  final Function(EntregaEntity) onMarcarEntrega;

  const EntregasTabletView({
    super.key,
    required this.entregasAgrupadas,
    required this.rutaIniciada,
    required this.onMarcarEntrega,
  });

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
    super.key,
    required this.entregasAgrupadas,
    required this.rutaIniciada,
    required this.onMarcarEntrega,
  });

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