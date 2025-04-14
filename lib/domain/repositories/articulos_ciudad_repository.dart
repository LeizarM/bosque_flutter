
import 'package:bosque_flutter/domain/entities/articulos_ciudad_entity.dart';

abstract class ArticulosxCiudadRepository {
  Future<List<ArticulosxCiudadEntity>> getArticulos( int codCiudad );
}