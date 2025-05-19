// Provider para el estado de permisos de botones

import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/data/repositories/auth_repository_impl.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/entities/usuarioBtn_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
final buttonPermissionsProvider = StateNotifierProvider<ButtonPermissionsNotifier, AsyncValue<List<UsuarioBtnEntity>>>((ref) {
  // Observar el estado del usuario para recargar permisos cuando cambie
  final user = ref.watch(userProvider);
  final userNotifier = ref.watch(userProvider.notifier);
  
  // Crear el notificador con dependencia al usuario
  return ButtonPermissionsNotifier(ref, userNotifier, user);
});

class ButtonPermissionsNotifier extends StateNotifier<AsyncValue<List<UsuarioBtnEntity>>> {
  final Ref _ref;
  final UserStateNotifier _userNotifier;
  final LoginEntity? _currentUser; // Corregido a LoginEntity con L mayúscula
  final AuthRepositoryImpl _authRepository = AuthRepositoryImpl();
  
  ButtonPermissionsNotifier(this._ref, this._userNotifier, this._currentUser) 
      : super(const AsyncValue.loading()) {
    // Solo cargar permisos si hay un usuario autenticado
    if (_currentUser != null) {
      _loadPermisos();
    } else {
      // Si no hay usuario, asegurarnos de que el estado sea vacío
      state = const AsyncValue.data([]);
    }
  }
  
  Future<void> _loadPermisos() async {
    debugPrint("Cargando permisos de botones...");
    try {
      state = const AsyncValue.loading();
      
      // Verificar si hay un usuario autenticado
      if (_currentUser == null) {
        debugPrint("No hay usuario autenticado. No se cargarán permisos.");
        state = const AsyncValue.data([]);
        return;
      }
      
      // Obtener el ID de usuario
      final codUsuario = await _userNotifier.getCodUsuario();
      debugPrint("Cargando permisos para usuario: $codUsuario");
      
      // Establecer el tipo de usuario en el repositorio
      final tipoUsuario = await _userNotifier.getTipoUsuario();
      _authRepository.setTipoUsuario(tipoUsuario);
      
      // Cargar permisos
      final permisos = await _authRepository.cargarPermisosBotones(codUsuario);
      debugPrint("Permisos cargados: ${permisos.length}");
      
      // Verificar si todavía hay un usuario autenticado antes de actualizar el estado
      if (_ref.read(userProvider) != null) {
        state = AsyncValue.data(permisos);
      } else {
        debugPrint("El usuario se desconectó durante la carga de permisos");
        state = const AsyncValue.data([]);
      }
    } catch (e) {
      debugPrint("Error al cargar permisos: $e");
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  // Método para verificar si un botón está autorizado
  bool tienePermiso(String nombreBtn) {
    // Si no hay usuario, no hay permisos
    if (_currentUser == null) {
      return false;
    }
    
    // El rol de administrador siempre tiene permiso
    if (_currentUser?.tipoUsuario == 'ROLE_ADM') {
      return true;
    }
    
    // Verificar permisos desde el repositorio
    return _authRepository.tienePermiso(nombreBtn);
  }
  
  // Método para recargar permisos manualmente
  Future<void> reloadPermisos() async {
    _authRepository.clearPermisos(); // Limpiar caché primero
    await _loadPermisos();
  }
  
  // Método para limpiar permisos al cerrar sesión
  void clearPermisos() {
    debugPrint("Limpiando permisos de botones");
    _authRepository.clearPermisos();
    state = const AsyncValue.loading(); // Reiniciar el estado a loading
  }
}