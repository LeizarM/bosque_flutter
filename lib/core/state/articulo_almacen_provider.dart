



import 'package:bosque_flutter/data/repositories/articulos_almacen_impl.dart';
import 'package:bosque_flutter/domain/entities/articulos_almacen_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/repositories/articulos_almacen_repository.dart';

final articuloAlmacenRepositoryProvider = Provider<ArticulosxAlmacenRepository>((ref) {
  return ArticulosAlmacenImpl();
});



final articuloAlmacenProvider = FutureProvider.family<List<ArticulosxAlmacenEntity>, (String, int)>((ref, params) async {
  final repository = ref.watch(articuloAlmacenRepositoryProvider);
  final (codArticulo, codCiudad) = params;
  return repository.getArticulosXAlmacen(codArticulo, codCiudad);
});