// Widget para mostrar una sección de ciudad con sus almacenes
import 'package:bosque_flutter/domain/entities/articulos_almacen_entity.dart';
import 'package:bosque_flutter/presentation/widgets/ventas/warehouse_item.dart';
import 'package:flutter/material.dart';

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
    // Calcular total por ciudad
    int totalDisponibleCity = 0;
    for (var article in articles) {
      totalDisponibleCity += article.disponible;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de ciudad
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_city, size: 16),
                const SizedBox(width: 6),
                Text(
                  cityName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Total: $totalDisponibleCity',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),

          // Lista de almacenes
          ...articles.map((article) {
            return WarehouseItem(article: article);
          }),
        ],
      ),
    );
  }
}
