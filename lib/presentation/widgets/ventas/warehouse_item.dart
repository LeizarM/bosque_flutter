import 'package:bosque_flutter/domain/entities/articulos_almacen_entity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WarehouseItem extends StatelessWidget {
  final ArticulosxAlmacenEntity article;

  const WarehouseItem({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final disponible = article.disponible;

    // Color based on stock level
    Color stockColor;
    if (disponible > 100) {
      stockColor = colorScheme.primary;
    } else if (disponible > 20) {
      stockColor = Colors.amber.shade700;
    } else {
      stockColor = colorScheme.error;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6, left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Warehouse icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.warehouse_rounded,
              size: 16,
              color: colorScheme.tertiary,
            ),
          ),
          const SizedBox(width: 12),

          // Warehouse info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.whsName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  article.whsCode,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Stock badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: stockColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: stockColor.withValues(alpha: 0.25)),
            ),
            child: Text(
              NumberFormat('#,##0', 'en_US').format(disponible),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: stockColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
