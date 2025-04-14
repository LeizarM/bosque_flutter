import 'dart:convert';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserStateNotifier extends StateNotifier<LoginEntity?> {
  UserStateNotifier() : super(null) {
    _loadUserFromStorage(); // Cargar datos del usuario al inicializar
  }

  Future<void> _loadUserFromStorage() async {
    final storage = SecureStorage();
    final userDataJson = await storage.getUserData();
    if (userDataJson != null) {
      try {
        // Deserializar los datos del usuario desde JSON
        final userDataMap = jsonDecode(userDataJson);
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
  }

  int getCodCiudad()  {
    // Obtener el código de la ciudad del usuario desde el estado
    if (state != null) {
      return state!.codCiudad;
    } else {
      throw Exception('No user data available');
    }
  }

  String getToken() {
    // Obtener el token del usuario desde el estado
    if (state != null) {
      return state!.token;
    } else {
      throw Exception('No user data available');
    }
  }

  int getCodUsuario() {
    // Obtener el código del usuario desde el estado
    if (state != null) {
      return state!.codUsuario;
    } else {
      throw Exception('No user data available');
    }
  }

  int getCodEmpleado() {
    // Obtener el código del empleado desde el estado
    if (state != null) {
      return state!.codEmpleado;
    } else {
      throw Exception('No user data available');
    }
  }

  int getCodSucursal() {
    // Obtener el código de la sucursal desde el estado
    if (state != null) {
      return state!.codSucursal;
    } else {
      throw Exception('No user data available');
    }
  }

  String getTipoUsuario() {
    // Obtener el tipo de usuario desde el estado
    if (state != null) {
      return state!.tipoUsuario;
    } else {
      throw Exception('No user data available');
    }
  }
}

// Definimos el provider usando StateNotifierProvider
final userProvider = StateNotifierProvider<UserStateNotifier, LoginEntity?>((ref) {
  return UserStateNotifier();
});