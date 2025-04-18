import 'dart:convert';

import 'package:bosque_flutter/data/repositories/chofer_repository_impl.dart';
import 'package:bosque_flutter/domain/entities/chofer_entity.dart';
import 'package:bosque_flutter/domain/repositories/chofer_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Estados para los choferes
enum ChoferesStatus {
  initial,
  loading,
  loaded,
  error,
}

// Clase que define el estado de los choferes
class ChoferesState {
  final ChoferesStatus status;
  final List<ChoferEntity> choferes;
  final String? errorMessage;
  final DateTime? lastUpdated;

  ChoferesState({
    required this.status,
    required this.choferes,
    this.errorMessage,
    this.lastUpdated,
  });

  ChoferesState.initial()
      : status = ChoferesStatus.initial,
        choferes = [],
        errorMessage = null,
        lastUpdated = null;

  ChoferesState copyWith({
    ChoferesStatus? status,
    List<ChoferEntity>? choferes,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return ChoferesState(
      status: status ?? this.status,
      choferes: choferes ?? this.choferes,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// Notifier para manejar el estado de los choferes
class ChoferesNotifier extends StateNotifier<ChoferesState> {
  final ChoferRepository _repository;
  
  // Claves para SharedPreferences
  static const String _choferesCacheKey = 'choferes_cache';
  static const String _choferesLastUpdateKey = 'choferes_last_update';
  static const Duration _cacheMaxAge = Duration(hours: 24);

  ChoferesNotifier(this._repository) : super(ChoferesState.initial()) {
    // Cargar desde caché al inicializar
    loadChoferesFromCache();
  }

  // Cargar choferes (primero desde caché luego actualizar de servidor)
  Future<void> loadChoferes({bool forceRefresh = false}) async {
    try {
      // Verificar si debemos mostrar loading
      if (state.choferes.isEmpty || state.status == ChoferesStatus.initial) {
        state = state.copyWith(status: ChoferesStatus.loading);
      }
      
      // Si no se fuerza refresh, intentar cargar desde caché primero
      if (!forceRefresh) {
        final cachedChoferes = await _loadChoferesFromCache();
        
        if (cachedChoferes != null && cachedChoferes.isNotEmpty) {
          state = state.copyWith(
            status: ChoferesStatus.loaded,
            choferes: cachedChoferes,
          );
          
          // Verificar si la caché es reciente o necesita actualización
          final lastUpdate = await _getLastUpdateTime();
          final now = DateTime.now();
          if (lastUpdate != null && now.difference(lastUpdate) < _cacheMaxAge) {
            // Caché aún es válida
            return;
          }
          // Caché expirada, se actualizará en segundo plano
        }
      }
      
      // Cargar desde servidor
      await _fetchAndSaveChoferes();
    } catch (e) {
      debugPrint('❌ Error cargando choferes: $e');
      
      // Solo actualizar estado a error si no hay datos en caché
      if (state.choferes.isEmpty) {
        state = state.copyWith(
          status: ChoferesStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
  }

  // Obtener y guardar choferes desde el servidor
  Future<void> _fetchAndSaveChoferes() async {
    try {
      debugPrint('🔄 Solicitando choferes al servidor');
      final choferesList = await _repository.getChoferes();
      
      if (choferesList.isNotEmpty) {
        debugPrint('✅ Choferes obtenidos con éxito: ${choferesList.length} registros');
        
        // Guardar en caché
        await _saveChoferesToCache(choferesList);
        
        // Actualizar estado
        state = state.copyWith(
          status: ChoferesStatus.loaded,
          choferes: choferesList,
          lastUpdated: DateTime.now(),
        );
      } else {
        debugPrint('⚠️ La lista de choferes está vacía');
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo choferes del servidor: $e');
      rethrow;
    }
  }
  
  // Guardar choferes en caché
  Future<void> _saveChoferesToCache(List<ChoferEntity> choferes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Serializar datos de choferes
      final choferesData = choferes.map((chofer) => {
        'codEmpleado': chofer.codEmpleado,
        'nombreCompleto': chofer.nombreCompleto,
        'cargo': chofer.cargo,
      }).toList();
      
      // Guardar como JSON string
      await prefs.setString(_choferesCacheKey, jsonEncode(choferesData));
      
      // Guardar fecha de última actualización
      await prefs.setString(_choferesLastUpdateKey, DateTime.now().toIso8601String());
      
      debugPrint('✅ Choferes guardados en caché: ${choferes.length} registros');
    } catch (e) {
      debugPrint('❌ Error guardando choferes en caché: $e');
    }
  }
  
  // Cargar choferes desde caché (uso interno)
  Future<List<ChoferEntity>?> _loadChoferesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final choferesJson = prefs.getString(_choferesCacheKey);
      
      if (choferesJson == null) {
        debugPrint('⚠️ No hay caché de choferes disponible');
        return null;
      }
      
      // Deserializar lista
      final choferesData = jsonDecode(choferesJson) as List<dynamic>;
      
      // Convertir a entidades
      final choferes = choferesData.map((item) => ChoferEntity(
        codEmpleado: item['codEmpleado'],
        nombreCompleto: item['nombreCompleto'],
        cargo: item['cargo'],
      )).toList();
      
      debugPrint('✅ Choferes cargados de caché: ${choferes.length} registros');
      return choferes;
    } catch (e) {
      debugPrint('❌ Error cargando choferes desde caché: $e');
      return null;
    }
  }
  
  // Método público para cargar desde caché (útil al iniciar la aplicación)
  Future<void> loadChoferesFromCache() async {
    try {
      final cachedChoferes = await _loadChoferesFromCache();
      if (cachedChoferes != null && cachedChoferes.isNotEmpty) {
        state = state.copyWith(
          status: ChoferesStatus.loaded,
          choferes: cachedChoferes,
        );
        debugPrint('✅ Estado actualizado con choferes desde caché');
      }
    } catch (e) {
      debugPrint('❌ Error cargando choferes desde caché: $e');
    }
  }
  
  // Obtener fecha de última actualización
  Future<DateTime?> _getLastUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateStr = prefs.getString(_choferesLastUpdateKey);
      
      if (lastUpdateStr != null) {
        return DateTime.parse(lastUpdateStr);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo fecha de última actualización: $e');
      return null;
    }
  }
  
  // Buscar un chofer por ID
  Future<ChoferEntity?> getChoferById(int codEmpleado) async {
    // Primero buscar en el estado actual
    try {
      if (state.status == ChoferesStatus.loaded && state.choferes.isNotEmpty) {
        return state.choferes.firstWhere(
          (chofer) => chofer.codEmpleado == codEmpleado,
          orElse: () => throw Exception(),
        );
      }
      
      // Si no está en el estado, buscar desde el repositorio
      return await _repository.getChoferById(codEmpleado);
    } catch (e) {
      debugPrint('⚠️ Chofer no encontrado: $codEmpleado');
      return null;
    }
  }
  
  // Limpiar caché (útil al cerrar sesión)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_choferesCacheKey);
      await prefs.remove(_choferesLastUpdateKey);
      
      state = ChoferesState.initial();
      debugPrint('✅ Caché de choferes limpiada');
    } catch (e) {
      debugPrint('❌ Error limpiando caché de choferes: $e');
    }
  }
}

// Provider para el repositorio de choferes
final choferRepositoryProvider = Provider<ChoferRepository>((ref) {
  return ChoferRepositoryImpl();
});

// Provider para el estado de los choferes (con notifier)
final choferesProvider = StateNotifierProvider<ChoferesNotifier, ChoferesState>((ref) {
  final repository = ref.watch(choferRepositoryProvider);
  return ChoferesNotifier(repository);
});

// Provider sencillo para acceder a la lista de choferes (sin necesidad de manejar el estado)
final choferesListProvider = Provider<List<ChoferEntity>>((ref) {
  final choferesState = ref.watch(choferesProvider);
  return choferesState.choferes;
});

// Provider para obtener un chofer por su ID
final choferByIdProvider = FutureProvider.family<ChoferEntity?, int>((ref, codEmpleado) async {
  final choferesNotifier = ref.watch(choferesProvider.notifier);
  return choferesNotifier.getChoferById(codEmpleado);
});

// Provider para filtrar choferes por cargo
final choferesByCargoPredicate = Provider.family<List<ChoferEntity>, String>((ref, cargo) {
  final choferes = ref.watch(choferesListProvider);
  if (cargo.isEmpty) return choferes;
  
  return choferes.where((chofer) => 
    chofer.cargo.toLowerCase().contains(cargo.toLowerCase())
  ).toList();
});

// Provider para búsqueda de choferes por nombre
final choferesSearchProvider = Provider.family<List<ChoferEntity>, String>((ref, searchQuery) {
  final choferes = ref.watch(choferesListProvider);
  if (searchQuery.isEmpty) return choferes;
  
  final query = searchQuery.toLowerCase();
  return choferes.where((chofer) => 
    chofer.nombreCompleto.toLowerCase().contains(query)
  ).toList();
});