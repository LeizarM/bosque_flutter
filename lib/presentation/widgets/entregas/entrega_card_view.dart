import 'package:bosque_flutter/domain/entities/entregas_entity.dart';
import 'package:flutter/material.dart';

class EntregaCardView extends StatelessWidget {
  final List<MapEntry<int, List<EntregaEntity>>> entregasAgrupadas;
  final bool rutaIniciada;
  final Function(EntregaEntity) onTapEntrega;
  final ColorScheme colorScheme;

  const EntregaCardView({
    Key? key,
    required this.entregasAgrupadas,
    required this.rutaIniciada,
    required this.onTapEntrega,
    required this.colorScheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (entregasAgrupadas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No hay entregas pendientes',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entregasAgrupadas.length,
      itemBuilder: (context, index) {
        final docNum = entregasAgrupadas[index].key;
        final entregas = entregasAgrupadas[index].value;
        final entrega = entregas.first;

        // Verificar estados de entrega
        final todosEntregados = entregas.every((e) => e.fueEntregado == 1);
        final algunoEntregado = entregas.any((e) => e.fueEntregado == 1);
        
        // Determinar estado visual
        final estadoColor = todosEntregados
            ? colorScheme.primary
            : algunoEntregado
                ? colorScheme.secondary
                : colorScheme.outline;
        
        final estadoTexto = todosEntregados
            ? 'Entregado'
            : algunoEntregado
                ? 'Parcial'
                : 'Pendiente';
                
        // Obtener dirección
        final direccion = entrega.addressEntregaMat.isNotEmpty
            ? entrega.addressEntregaMat
            : entrega.addressEntregaFac;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          surfaceTintColor: colorScheme.surfaceTint.withOpacity(0.1),
          shadowColor: Colors.black26,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Factura: ${entrega.factura}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          entrega.cardName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          direccion,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Estado
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: estadoColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: estadoColor,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          estadoTexto,
                          style: TextStyle(
                            color: estadoColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Fecha
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatDate(entrega.docDate),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Contador de productos
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${entregas.length}',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              children: [
                // Lista de productos
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entregas.length,
                  itemBuilder: (context, productIndex) {
                    final producto = entregas[productIndex];
                    final entregado = producto.fueEntregado == 1;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: entregado
                            ? colorScheme.primaryContainer.withOpacity(0.1)
                            : colorScheme.surfaceVariant.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: entregado
                              ? colorScheme.primary.withOpacity(0.3)
                              : colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Código del producto
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    producto.itemCode,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Descripción del producto
                                Expanded(
                                  child: Text(
                                    producto.dscription,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Cantidad
                                Row(
                                  children: [
                                    Text(
                                      'Cantidad: ',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '${producto.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                // Almacén
                                Row(
                                  children: [
                                    Text(
                                      'Almacén: ',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      producto.whsCode,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                // Estado
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: entregado
                                        ? colorScheme.primary.withOpacity(0.1)
                                        : colorScheme.outline.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: entregado
                                          ? colorScheme.primary
                                          : colorScheme.outline,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    entregado ? 'Entregado' : 'Pendiente',
                                    style: TextStyle(
                                      color: entregado
                                          ? colorScheme.primary
                                          : colorScheme.outline,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                // Observaciones si existen
                if (entregas.first.obsF != null && entregas.first.obsF.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.comment,
                              color: colorScheme.secondary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Observaciones:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.secondary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(entregas.first.obsF),
                        ),
                      ],
                    ),
                  ),
                
                // Botón de acción si hay entregas pendientes
                if (!todosEntregados && rutaIniciada)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => onTapEntrega(entrega),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Marcar como entregado'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Formatear fecha
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }
}