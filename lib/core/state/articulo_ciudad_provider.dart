// lib/core/state/articulos_ciudad_provider.dart

import 'package:bosque_flutter/data/repositories/articulos_ciudad_impl.dart';
import 'package:bosque_flutter/domain/repositories/articulos_ciudad_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/articulos_ciudad_entity.dart';

// Provider para el repositorio
final articulosCiudadRepositoryProvider = Provider<ArticulosxCiudadRepository>((ref) {
  return ArticulosCiudadImpl();
});

// Provider para acceder a los artículos con caché
final articulosCiudadProvider = FutureProvider.family<List<ArticulosxCiudadEntity>, int>((ref, codCiudad) async {
  final repository = ref.watch(articulosCiudadRepositoryProvider);
  
  // Puedes agregar lógica de caché aquí si quieres
  debugPrint('📦 Solicitando artículos para ciudad: $codCiudad');
  
  return repository.getArticulos(codCiudad);
});

// Provider para control de refresco manual
final articulosCiudadRefreshProvider = StateProvider<int>((ref) => 0);

// Provider que combina refresco manual con datos
final articulosCiudadRefreshableProvider = FutureProvider.family<List<ArticulosxCiudadEntity>, int>((ref, codCiudad) async {
  // Observar el contador de refresco
  final refreshCount = ref.watch(articulosCiudadRefreshProvider);
  debugPrint('🔄 Actualizando artículos (refresco #$refreshCount) para ciudad: $codCiudad');
  
  final repository = ref.watch(articulosCiudadRepositoryProvider);
  return repository.getArticulos(codCiudad);
});