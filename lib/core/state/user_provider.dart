import 'dart:convert';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/button_permissions_provider.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/repositories/auth_repository.dart';
import 'package:bosque_flutter/data/repositories/auth_repository_impl.dart';

final asyncUserProvider = FutureProvider<LoginEntity?>((ref) async {
  final storage = SecureStorage();
  final userDataJson = await storage.getUserData();
  if (userDataJson != null) {
    try {
      final userDataMap = jsonDecode(userDataJson);
      final userVersion = userDataMap['versionApp']?.toString();
      if (userVersion != null && userVersion != AppConstants.APP_VERSION) {
        // Si la versión no coincide, limpiar usuario y token
        await storage.deleteUserData();
        await storage.deleteToken();
        return null;
      }
      return LoginEntity.fromJson(userDataMap);
    } catch (_) {
      await storage.deleteUserData();
      await storage.deleteToken();
      return null;
    }
  }
  return null;
});

class UserStateNotifier extends StateNotifier<LoginEntity?> {
  final AuthRepository _authRepository = AuthRepositoryImpl();

  UserStateNotifier() : super(null) {
    _loadUserFromStorage(); // Cargar datos del usuario al inicializar
  }

  Future<void> _loadUserFromStorage() async {
    final storage = SecureStorage();
    final userDataJson = await storage.getUserData();
    if (userDataJson != null) {
      try {
        final userDataMap = jsonDecode(userDataJson);
        // Validar versión de la app
        final userVersion = userDataMap['versionApp']?.toString();
        if (userVersion != null && userVersion != AppConstants.APP_VERSION) {
          // Si la versión no coincide, limpiar usuario y token
          state = null;
          await storage.deleteUserData();
          await storage.deleteToken();
          return;
        }
        // Deserializar los datos del usuario desde JSON
        state = LoginEntity.fromJson(userDataMap);
      } catch (e) {
        // Si hay un error al deserializar, limpiar el estado
        state = null;
        await storage.deleteUserData();
        await storage.deleteToken();
      }
    }
  }

  Future<void> setUser(LoginEntity user) async {
    state = user;
    // Guardar los datos del usuario en almacenamiento seguro
    final storage = SecureStorage();
    final userDataJson = jsonEncode(user.toJson());
    await storage.saveUserData(userDataJson);
    // Guardar el token por separado si es necesario
    await storage.saveToken(user.token);
    
  }

  Future<void> clearUser() async {
    state = null;
    // Limpiar los datos del usuario y el token del almacenamiento
    final storage = SecureStorage();
    await storage.deleteUserData();
    await storage.deleteToken();

    // Reiniciar completamente el estado de permisos
    // Usamos una referencia global al contenedor de providers para asegurarnos de limpiar el estado
    try {
      // Obtener el notificador de permisos directamente desde el container global
      final providerContainer = ProviderContainer();
      // Esto asegura que el estado se establezca en "loading" nuevamente
      providerContainer
          .read(buttonPermissionsProvider.notifier)
          .clearPermisos();
      providerContainer.refresh(buttonPermissionsProvider);
    } catch (e) {
      debugPrint('Error al limpiar permisos: $e');
    }
  }

  Future<int> getCodCiudad() async {
    // Obtener el código de la ciudad del usuario desde el estado
    if (state != null) {
      return state!.codCiudad;
    } else {
      final storage = SecureStorage();
      final userDataJson = await storage.getUserData();

      return jsonDecode(userDataJson!)['codCiudad'] ?? 0;
    }
  }

  Future<String> getToken() async {
    // Obtener el token del usuario desde el estado
    if (state != null) {
      return state!.token;
    } else {
      final storage = SecureStorage();
      final userDataJson = await storage.getUserData();

      return jsonDecode(userDataJson!)['token'] ?? 0;
    }
  }

  Future<int> getCodUsuario() async {
    // Obtener el código del usuario desde el estado
    if (state != null) {
      return state!.codUsuario;
    } else {
      final storage = SecureStorage();
      final userDataJson = await storage.getUserData();

      return jsonDecode(userDataJson!)['codUsuario'] ?? 0;
    }
  }

  Future<int> getCodEmpleado() async {
    // Obtener el código del empleado desde el estado
    if (state != null) {
      return state!.codEmpleado;
    } else {
      final storage = SecureStorage();
      final userDataJson = await storage.getUserData();

      return jsonDecode(userDataJson!)['codEmpleado'] ?? 0;
    }
  }

  Future<int> getCodSucursal() async {
    // Obtener el código de la sucursal desde el estado
    if (state != null) {
      return state!.codSucursal;
    } else {
      final storage = SecureStorage();
      final userDataJson = await storage.getUserData();

      return jsonDecode(userDataJson!)['codSucursal'] ?? 0;
    }
  }


  Future<String> getCargo() async {
    // First try to get cargo from state if available
    if (state?.cargo?.isNotEmpty == true) {
      return state!.cargo;
    }
    
    // If not in state, try to get from storage
    final storage = SecureStorage();
    final userDataJson = await storage.getUserData();
    if (userDataJson == null) return 'USUARIO SIN CARGO ASIGNADO';
    
    try {
      final userData = jsonDecode(userDataJson);
      
      // Check for cargo in different possible locations in JSON
      String? cargo;
      
      // Check in nested data object
      if (userData['data']?['cargo'] != null) {
        cargo = userData['data']['cargo'].toString();
      }
      // Check directly in userData
      else if (userData['cargo'] != null) {
        cargo = userData['cargo'].toString();
      }
      // Try to extract from JWT token if present
      else if (userData['token'] != null) {
        final token = userData['token'].toString();
        final parts = token.split('.');
        if (parts.length > 1) {
          final payload = base64Url.normalize(parts[1]);
          final payloadData = jsonDecode(utf8.decode(base64Url.decode(payload)));
          cargo = payloadData['cargo']?.toString();
        }
      }
      
      return cargo?.isNotEmpty == true ? cargo! : 'USUARIO SIN CARGO ASIGNADO';
    } catch (e) {
      return 'USUARIO SIN CARGO ASIGNADO';
    }
  }

  Future<String> getTipoUsuario() async {
    // Obtener el tipo de usuario desde el estado
    if (state != null) {
      return state!.tipoUsuario;
    } else {
      final storage = SecureStorage();
      final userDataJson = await storage.getUserData();

      return jsonDecode(userDataJson!)['tipoUsuario'] ?? 0;
    }
  }

  Future<List<LoginEntity>> getUsers() async {
    try {
      final users = await _authRepository.getUsers();
      if (users.isNotEmpty) {
        print('Primer usuario: \\n${users.first.toJson()}');
      } else {
        print('No llegaron usuarios del backend');
      }
      return users;
    } catch (e) {
      print('Error al obtener usuarios: $e');
      return [];
    }
  }

  Future<bool> changePassword(LoginEntity user) async {
    user.npassword = '123456789';
    return await _authRepository.changePassword(user);
  }

  Future<bool> changePasswordDefault(LoginEntity user) async {
    return await _authRepository.changePassword(user);
  }
}

// Definir un provider adicional para la lista de usuarios
final usersListProvider = FutureProvider<List<LoginEntity>>((ref) {
  final userNotifier = ref.watch(userProvider.notifier);
  return userNotifier.getUsers();
});

// Definimos el provider usando StateNotifierProvider
               final userProvider = StateNotifierProvider<UserStateNotifier, LoginEntity?>((
  ref,
) {
  return UserStateNotifier();
});
