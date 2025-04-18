import 'package:bosque_flutter/domain/entities/articulos_almacen_entity.dart';
import 'package:bosque_flutter/presentation/widgets/ventas/city_section.dart';
import 'package:flutter/material.dart';

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
    // Calcular total por base de datos
    int totalDisponibleDb = 0;
    articlesByCity.forEach((_, articles) {
      for (var article in articles) {
        totalDisponibleDb += article.disponible;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado de base de datos
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BASE DE DATOS: $dbName',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              Text(
                'Total: $totalDisponibleDb',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),

        // Secciones de ciudades
        ...articlesByCity.entries.map((cityEntry) {
          return CitySection(
            cityName: cityEntry.key,
            articles: cityEntry.value,
          );
        }).toList(),

        const SizedBox(height: 20),
      ],
    );
  }
}
