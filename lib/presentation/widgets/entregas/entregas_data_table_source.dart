import 'package:flutter/material.dart';
import 'package:bosque_flutter/domain/entities/entregas_entity.dart';

class EntregasDataTableSource extends DataTableSource {
  final List<MapEntry<int, List<EntregaEntity>>> entregasAgrupadas;
  final bool rutaIniciada;
  final void Function(EntregaEntity entrega) onMarcarEntrega;
  final BuildContext context;

  EntregasDataTableSource({
    required this.entregasAgrupadas,
    required this.rutaIniciada,
    required this.onMarcarEntrega,
    required this.context,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= entregasAgrupadas.length) return null;
    final entregas = entregasAgrupadas[index].value;
    final entregaPrimaria = entregas.first;
    final todosEntregados = entregas.every((e) => e.fueEntregado == 1);

    return DataRow(
      cells: [
        DataCell(
          Text(
            entregaPrimaria.cardName ?? '',
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        DataCell(Text(entregaPrimaria.factura.toString())),
        DataCell(Text(
          entregaPrimaria.fechaEntrega != null
              ? '${entregaPrimaria.docDate.day.toString().padLeft(2, '0')}/${entregaPrimaria.docDate.month.toString().padLeft(2, '0')}/${entregaPrimaria.docDate.year}'
              : '',
        )),
        DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.25),
            child: Text(
              entregaPrimaria.addressEntregaMat ?? '',
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
        DataCell(Text(todosEntregados ? 'Entregado' : 'Pendiente')),
        DataCell(
          ElevatedButton(
            onPressed: !rutaIniciada || todosEntregados
                ? null
                : () => onMarcarEntrega(entregaPrimaria),
            child: const Text('Marcar'),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => entregasAgrupadas.length;

  @override
  int get selectedRowCount => 0;
}