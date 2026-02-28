import 'package:bosque_flutter/domain/entities/articulos_almacen_entity.dart';
import 'package:bosque_flutter/presentation/widgets/ventas/warehouse_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CitySection extends StatelessWidget {
  final String cityName;
  final List<ArticulosxAlmacenEntity> articles;

  const CitySection({
    super.key,
    required this.cityName,
    required this.articles,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    int totalDisponibleCity = 0;
    for (var article in articles) {
      totalDisponibleCity += article.disponible;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // City header
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cityName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.onSecondaryContainer.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Total: ${NumberFormat('#,##0', 'en_US').format(totalDisponibleCity)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Warehouse list
          ...articles.map((article) => WarehouseItem(article: article)),
        ],
      ),
    );
  }
}
