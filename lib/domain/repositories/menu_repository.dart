import 'package:bosque_flutter/domain/entities/menu_entity.dart';

abstract class MenuRepository {
  Future<List<MenuItemEntity>> getMenuItems( int codUsuario );
}