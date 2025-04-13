import 'dart:convert';

import 'package:bosque_flutter/data/repositories/menu_repository_impl.dart';
import 'package:bosque_flutter/domain/entities/menu_entity.dart';
import 'package:bosque_flutter/domain/repositories/menu_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider para el repositorio de menú
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepositoryImpl();
});

// Estados para el menú
enum MenuStatus {
  initial,
  loading,
  loaded,
  error,
}

// Clase que define el estado del menú
class MenuState {
  final MenuStatus status;
  final List<MenuItemEntity> menuItems;
  final String? errorMessage;

  MenuState({
    required this.status,
    required this.menuItems,
    this.errorMessage,
  });

  MenuState.initial()
      : status = MenuStatus.initial,
        menuItems = [],
        errorMessage = null;

  MenuState copyWith({
    MenuStatus? status,
    List<MenuItemEntity>? menuItems,
    String? errorMessage,
  }) {
    return MenuState(
      status: status ?? this.status,
      menuItems: menuItems ?? this.menuItems,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Notifier para manejar el estado del menú
class MenuNotifier extends StateNotifier<MenuState> {
  final MenuRepository _repository;
  
  // Clave para guardar el menú en SharedPreferences
  static const String _menuCacheKey = 'menu_cache';
  static const String _menuUserIdKey = 'menu_user_id';

  MenuNotifier(this._repository) : super(MenuState.initial());

  // Cargar menú para un usuario
  Future<void> loadUserMenu(int userId) async {
    try {
      state = state.copyWith(status: MenuStatus.loading);
      
      // Intentar cargar desde caché primero
      final cachedMenu = await _loadMenuFromCache(userId);
      
      if (cachedMenu != null) {
        state = state.copyWith(
          status: MenuStatus.loaded,
          menuItems: cachedMenu,
        );
        
        // Actualizar en segundo plano
        _refreshMenuFromServer(userId);
      } else {
        // Si no hay caché, cargar directamente desde el servidor
        final menuEntities = await _repository.getMenuItems(userId);
        
        // Guardar en caché
        await _saveMenuToCache(userId, menuEntities);
        
        state = state.copyWith(
          status: MenuStatus.loaded,
          menuItems: menuEntities,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: MenuStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Método para actualizar menú en segundo plano
  Future<void> _refreshMenuFromServer(int userId) async {
    try {
      final menuEntities = await _repository.getMenuItems(userId);
      
      // Guardar en caché
      await _saveMenuToCache(userId, menuEntities);
      
      // Actualizar estado solo si el userId no ha cambiado
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getInt(_menuUserIdKey);
      
      if (cachedUserId == userId) {
        state = state.copyWith(
          status: MenuStatus.loaded,
          menuItems: menuEntities,
        );
      }
    } catch (e) {
      // No actualizar el estado en caso de error de actualización en segundo plano
      debugPrint('Error actualizando menú en segundo plano: $e');
    }
  }
  
  // Método para guardar menú en caché
  Future<void> _saveMenuToCache(int userId, List<MenuItemEntity> menuItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convertir MenuItemEntity a JSON serializable
      final menuJson = _serializeMenuItems(menuItems);
      
      // Guardar el menú serializado
      await prefs.setString(_menuCacheKey, jsonEncode(menuJson));
      
      // Guardar el ID del usuario
      await prefs.setInt(_menuUserIdKey, userId);
    } catch (e) {
      debugPrint('Error guardando menú en caché: $e');
    }
  }
  
  // Método para cargar menú desde caché
  Future<List<MenuItemEntity>?> _loadMenuFromCache(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Verificar si existe un menú en caché y si pertenece al usuario actual
      final cachedUserId = prefs.getInt(_menuUserIdKey);
      if (cachedUserId != userId) {
        return null;
      }
      
      final menuJsonString = prefs.getString(_menuCacheKey);
      if (menuJsonString == null) {
        return null;
      }
      
      // Deserializar el menú
      final menuJson = jsonDecode(menuJsonString) as List<dynamic>;
      return _deserializeMenuItems(menuJson);
    } catch (e) {
      debugPrint('Error cargando menú desde caché: $e');
      return null;
    }
  }
  
  // Método auxiliar para serializar lista de MenuItemEntity
  List<Map<String, dynamic>> _serializeMenuItems(List<MenuItemEntity> items) {
    return items.map((item) => _serializeMenuItem(item)).toList();
  }
  
  // Método auxiliar para serializar un solo MenuItemEntity
  Map<String, dynamic> _serializeMenuItem(MenuItemEntity item) {
    return {
      'codVista': item.codVista,
      'codVistaPadre': item.codVistaPadre,
      'direccion': item.direccion,
      'titulo': item.titulo,
      'descripcion': item.descripcion,
      'imagen': item.imagen,
      'esRaiz': item.esRaiz,
      'autorizar': item.autorizar,
      'audUsuarioI': item.audUsuarioI,
      'fila': item.fila,
      'label': item.label,
      'tieneHijo': item.tieneHijo,
      'routerLink': item.routerLink,
      'icon': item.icon,
      'items': item.items != null ? _serializeMenuItems(item.items!) : null,
    };
  }
  
  // Método auxiliar para deserializar lista de MenuItemEntity
  List<MenuItemEntity> _deserializeMenuItems(List<dynamic> jsonList) {
    return jsonList.map((json) => _deserializeMenuItem(json)).toList();
  }
  
  // Método auxiliar para deserializar un solo MenuItemEntity
  MenuItemEntity _deserializeMenuItem(Map<String, dynamic> json) {
    return MenuItemEntity(
      codVista: json['codVista'],
      codVistaPadre: json['codVistaPadre'],
      direccion: json['direccion'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      imagen: json['imagen'],
      esRaiz: json['esRaiz'],
      autorizar: json['autorizar'],
      audUsuarioI: json['audUsuarioI'],
      fila: json['fila'],
      label: json['label'],
      tieneHijo: json['tieneHijo'],
      routerLink: json['routerLink'],
      icon: json['icon'],
      items: json['items'] != null ? _deserializeMenuItems(json['items']) : null,
    );
  }

  // Método auxiliar para obtener todos los elementos del menú (aplanados)
  List<MenuItemEntity> getAllMenuItems() {
    List<MenuItemEntity> allItems = [];
    
    void extractItems(List<MenuItemEntity> items) {
      for (var item in items) {
        allItems.add(item);
        if (item.items != null && item.items!.isNotEmpty) {
          extractItems(item.items!);
        }
      }
    }
    
    extractItems(state.menuItems);
    return allItems;
  }
  
  // Método para obtener un item por su ruta
  MenuItemEntity? getMenuItemByPath(String path) {
    final allItems = getAllMenuItems();
    try {
      return allItems.firstWhere(
        (item) => item.direccion == path || item.routerLink == path
      );
    } catch (e) {
      return null;
    }
  }
  
  // Limpiar caché (útil al cerrar sesión)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_menuCacheKey);
      await prefs.remove(_menuUserIdKey);
      state = MenuState.initial();
    } catch (e) {
      debugPrint('Error limpiando caché del menú: $e');
    }
  }
}

// Provider para el estado del menú
final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  final repository = ref.watch(menuRepositoryProvider);
  return MenuNotifier(repository);
});

// Clase auxiliar para manejar los elementos del menú en el sidebar
class SidebarMenuItem {
  final String title;
  final IconData icon;
  final String route;
  final int id;
  final List<SidebarMenuItem>? children;

  SidebarMenuItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.id,
    this.children,
  });
}

// Provider para obtener el menú en forma de lista para el sidebar
final sidebarMenuProvider = Provider<List<SidebarMenuItem>>((ref) {
  final menuState = ref.watch(menuProvider);
  
  if (menuState.status != MenuStatus.loaded) {
    return [];
  }
  
  // Función para mapear un ícono string a IconData
  IconData mapIconToIconData(MenuItemEntity item) {
    // Si el ítem no tiene ícono, determinarlo basado en el título
    final title = item.titulo.toLowerCase();
    
    // Verificar el formato "pi pi-xxx" usado por PrimeNG
    if (item.icon != null) {
      final iconName = item.icon!.split(' ').last;
      
      switch (iconName) {
        case 'circle': return Icons.circle;
        case 'home': return Icons.home;
        case 'users': return Icons.people;
        case 'user': return Icons.person;
        case 'cog': return Icons.settings;
        case 'file': return Icons.description;
        case 'money': return Icons.attach_money;
        case 'dollar': return Icons.attach_money;
        // Añadir más íconos según sea necesario
        default: break;
      }
    }
    
    // Determinar ícono basado en el título
    if (title.contains('rrhh') || title.contains('recurso')) {
      return Icons.people;
    } else if (title.contains('admin')) {
      return Icons.admin_panel_settings;
    } else if (title.contains('ventas') || title.contains('libro de ventas')) {
      return Icons.point_of_sale;
    } else if (title.contains('compras')) {
      return Icons.shopping_cart;
    } else if (title.contains('reporte')) {
      return Icons.assessment;
    } else if (title.contains('precios')) {
      return Icons.attach_money;
    } else if (title.contains('comisiones')) {
      return Icons.monetization_on;
    } else if (title.contains('pedidos')) {
      return Icons.shopping_bag;
    } else if (title.contains('tareas')) {
      return Icons.task;
    } else if (title.contains('produccion')) {
      return Icons.precision_manufacturing;
    } else if (title.contains('facturas')) {
      return Icons.receipt;
    } else if (title.contains('material')) {
      return Icons.inventory;
    } else if (title.contains('entregas')) {
      return Icons.local_shipping;
    } else if (title.contains('vehiculo')) {
      return Icons.directions_car;
    } else if (title.contains('licitacion')) {
      return Icons.gavel;
    } else if (title.contains('ficha')) {
      return Icons.badge;
    } else if (title.contains('deposito')) {
      return Icons.account_balance;
    } else if (title.contains('combustible')) {
      return Icons.local_gas_station;
    }
    
    return Icons.folder;
  }

  // Transformar MenuItemEntity a SidebarMenuItem
  List<SidebarMenuItem> transformMenu(List<MenuItemEntity> menuItems) {
    return menuItems.map((item) {
      // Construir la ruta según el valor de direccion
      String route = '';
      if (item.direccion.isNotEmpty) {
        // Usar directamente la dirección para la ruta
        route = '/${item.direccion}';
      } else if (item.routerLink != null && item.routerLink!.isNotEmpty) {
        route = '/${item.routerLink}';
      }
      
      return SidebarMenuItem(
        id: item.codVista,
        title: item.titulo,
        icon: mapIconToIconData(item),
        route: route,
        children: item.items != null && item.items!.isNotEmpty
            ? transformMenu(item.items!)
            : null,
      );
    }).toList();
  }
  
  return transformMenu(menuState.menuItems);
});