import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/articulo_almacen_provider.dart';
import 'package:bosque_flutter/domain/entities/articulos_almacen_entity.dart';

class ArticleStockScreen extends ConsumerStatefulWidget {
  final String codArticulo;
  final int codCiudad;

  const ArticleStockScreen({
    Key? key,
    required this.codArticulo,
    required this.codCiudad,
  }) : super(key: key);

  @override
  ConsumerState<ArticleStockScreen> createState() => _ArticleStockScreenState();
}

class _ArticleStockScreenState extends ConsumerState<ArticleStockScreen> {
  
  @override
  void initState() {
    super.initState();
    // Programamos la recarga del provider en el siguiente frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Invalidamos el provider para asegurar que se obtengan datos frescos
      ref.invalidate(articuloAlmacenProvider((widget.codArticulo, widget.codCiudad)));
    });
  }

  @override
  void didUpdateWidget(ArticleStockScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.codArticulo != widget.codArticulo || 
        oldWidget.codCiudad != widget.codCiudad) {
      // Si los parámetros cambian, invalidamos el provider para recargar
      ref.invalidate(articuloAlmacenProvider((widget.codArticulo, widget.codCiudad)));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Observamos el provider directamente en el build para recibir actualizaciones automáticas
    final articleStockAsyncValue = ref.watch(articuloAlmacenProvider((widget.codArticulo, widget.codCiudad)));

    return Scaffold(
      appBar: AppBar(
        title: Text('Inventario: ${widget.codArticulo}'),
      ),
      body: articleStockAsyncValue.when(
        data: (articles) => _buildArticleStockContent(context, articles),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error al cargar datos: ${error.toString()}'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // Botón para reintentar la carga
                  ref.invalidate(articuloAlmacenProvider((widget.codArticulo, widget.codCiudad)));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticleStockContent(BuildContext context, List<ArticulosxAlmacenEntity> articles) {
    if (articles.isEmpty) {
      return const Center(
        child: Text('No hay stock disponible para este artículo'),
      );
    }

    // First, group the articles by database (db)
    final articlesByDb = <String, List<ArticulosxAlmacenEntity>>{};
    for (final article in articles) {
      if (!articlesByDb.containsKey(article.db)) {
        articlesByDb[article.db] = [];
      }
      articlesByDb[article.db]!.add(article);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display the article name from the first item (should be the same for all)
          if (articles.isNotEmpty) 
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                articles.first.datoArt,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),

          // Build sections for each database
          ...articlesByDb.entries.map((dbEntry) {
            final dbName = dbEntry.key;
            final dbArticles = dbEntry.value;

            // Group by city within this database
            final articlesByCity = <String, List<ArticulosxAlmacenEntity>>{};
            for (final article in dbArticles) {
              if (!articlesByCity.containsKey(article.ciudad)) {
                articlesByCity[article.ciudad] = [];
              }
              articlesByCity[article.ciudad]!.add(article);
            }

            return DatabaseSection(
              dbName: dbName,
              articlesByCity: articlesByCity,
            );
          }).toList(),
        ],
      ),
    );
  }
}

// Widget for displaying a database section
class DatabaseSection extends StatelessWidget {
  final String dbName;
  final Map<String, List<ArticulosxAlmacenEntity>> articlesByCity;

  const DatabaseSection({
    Key? key,
    required this.dbName,
    required this.articlesByCity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Database header
            Text(
              'Base de Datos: $dbName',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),

            // City sections
            ...articlesByCity.entries.map((cityEntry) {
              final cityName = cityEntry.key;
              final cityArticles = cityEntry.value;

              return CitySection(
                cityName: cityName,
                articles: cityArticles,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// Widget for displaying a city section
class CitySection extends StatelessWidget {
  final String cityName;
  final List<ArticulosxAlmacenEntity> articles;

  const CitySection({
    Key? key,
    required this.cityName,
    required this.articles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // City header
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Ciudad: $cityName',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Warehouse list
          ...articles.map((article) => WarehouseItem(article: article)).toList(),
          const Divider(),
        ],
      ),
    );
  }
}

// Widget for displaying a warehouse item
class WarehouseItem extends StatelessWidget {
  final ArticulosxAlmacenEntity article;

  const WarehouseItem({
    Key? key,
    required this.article,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${article.whsCode} - ${article.whsName}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Disponible: ${article.disponible}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: article.disponible > 0 ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}