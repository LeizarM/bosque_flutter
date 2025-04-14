

import 'package:bosque_flutter/domain/entities/articulos_almacen_entity.dart';

abstract class ArticulosxAlmacenRepository {
  Future<List<ArticulosxAlmacenEntity>> getArticulosXAlmacen( String codArticulo,  int codCiudad );
}