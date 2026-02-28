import 'package:bosque_flutter/domain/entities/articulos_almacen_entity.dart';
import 'package:bosque_flutter/presentation/widgets/ventas/city_section.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatabaseSection extends StatelessWidget {
  final String dbName;
  final Map<String, List<ArticulosxAlmacenEntity>> articlesByCity;

  const DatabaseSection({
    super.key,
    required this.dbName,
    required this.articlesByCity,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    int totalDisponibleDb = 0;
    articlesByCity.forEach((_, articles) {
      for (var article in articles) {
        totalDisponibleDb += article.disponible;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // DB header
        Container(
          margin: const EdgeInsets.only(bottom: 10, top: 8),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.dns_rounded,
                size: 18,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dbName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_rounded,
                      size: 14,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${NumberFormat('#,##0', 'en_US').format(totalDisponibleDb)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // City sections
        ...articlesByCity.entries.map((cityEntry) {
          return CitySection(
            cityName: cityEntry.key,
            articles: cityEntry.value,
          );
        }),

        const SizedBox(height: 12),
      ],
    );
  }
}
