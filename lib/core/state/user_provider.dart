import 'dart:convert';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/repositories/auth_repository.dart';
import 'package:bosque_flutter/data/repositories/auth_repository_impl.dart';

final asyncUserProvider = FutureProvider<LoginEntity?>((ref) async {
  try {
    final storage = SecureStorage();
    final userDataJson = await storage.getUserData().timeout(
      const Duration(seconds: 4),
      onTimeout: () => null,
    );
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
  } catch (e) {
    return null;
  }
});

class UserStateNotifier extends StateNotifier<LoginEntity?> {
  final AuthRepository _authRepository = AuthRepositoryImpl();

  UserStateNotifier() : super(null) {
    _loadUserFromStorage(); // Cargar datos del usuario al inicializar
  }

  Future<void> _loadUserFromStorage() async {
    try {
      final storage = SecureStorage();
      final userDataJson = await storage.getUserData().timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
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
    } catch (e) {
      // Timeout o error inesperado: dejar state en null (usuario no autenticado)
      state = null;
    }
  }

  /// Persiste el usuario en el estado y en el storage seguro.
  /// Devuelve `true` sólo si AMBAS escrituras (user_data y token) se
  /// persistieron; `false` permite al login detectar dispositivos donde el
  /// Keystore no puede escribir y evitar un bucle de login silencioso.
  Future<bool> setUser(LoginEntity user) async {
    state = user;
    final storage = SecureStorage();
    final userDataJson = jsonEncode(user.toJson());
    final okData = await storage.saveUserData(userDataJson);
    final okToken = await storage.saveToken(user.token);
    return okData && okToken;
  }

  Future<void> clearUser() async {
    state = null;
    // Limpiar los datos del usuario y el token del almacenamiento.
    final storage = SecureStorage();
    await storage.clearSession();

    // NOTA: la limpieza del estado de permisos (buttonPermissionsProvider) la
    // hace el llamador que posee el `ref` REAL de la app (el callback de 401 en
    // router.dart y los handlers de logout). Antes se creaba aquí un
    // ProviderContainer() aislado que NO afectaba el estado vivo de la app.
  }

  Future<int> getCodCiudad() async {
    if (state != null) return state!.codCiudad;
    final userDataJson = await SecureStorage().getUserData();
    if (userDataJson == null) return 0;
    try {
      return jsonDecode(userDataJson)['codCiudad'] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<String> getToken() async {
    // Obtener el token del usuario desde el estado
    if (state != null) {
      return state!.token;
    }
    // Fallback al storage, con null-safety (antes usaba userDataJson! y '?? 0',
    // que crasheaba o devolvía un int en un Future<String>).
    final storage = SecureStorage();
    final userDataJson = await storage.getUserData();
    if (userDataJson == null) return '';
    try {
      final token = jsonDecode(userDataJson)['token'];
      return token is String ? token : '';
    } catch (_) {
      return '';
    }
  }

  Future<int> getCodUsuario() async {
    if (state != null) return state!.codUsuario;
    final userDataJson = await SecureStorage().getUserData();
    if (userDataJson == null) return 0;
    try {
      return jsonDecode(userDataJson)['codUsuario'] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getCodEmpleado() async {
    if (state != null) return state!.codEmpleado;
    final userDataJson = await SecureStorage().getUserData();
    if (userDataJson == null) return 0;
    try {
      return jsonDecode(userDataJson)['codEmpleado'] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getCodSucursal() async {
    if (state != null) return state!.codSucursal;
    final userDataJson = await SecureStorage().getUserData();
    if (userDataJson == null) return 0;
    try {
      return jsonDecode(userDataJson)['codSucursal'] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<String> getCargo() async {
    // First try to get cargo from state if available
    if (state?.cargo.isNotEmpty == true) {
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
          final payloadData = jsonDecode(
            utf8.decode(base64Url.decode(payload)),
          );
          cargo = payloadData['cargo']?.toString();
        }
      }

      return cargo?.isNotEmpty == true ? cargo! : 'USUARIO SIN CARGO ASIGNADO';
    } catch (e) {
      return 'USUARIO SIN CARGO ASIGNADO';
    }
  }

  Future<String> getTipoUsuario() async {
    if (state != null) return state!.tipoUsuario;
    final userDataJson = await SecureStorage().getUserData();
    if (userDataJson == null) return '';
    try {
      final v = jsonDecode(userDataJson)['tipoUsuario'];
      return v is String ? v : '';
    } catch (_) {
      return '';
    }
  }

  Future<List<LoginEntity>> getUsers() async {
    try {
      final users = await _authRepository.getUsers();

      return users;
    } catch (e) {
      //console('Error al obtener usuarios: $e');
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

// Provider para cargar la lista de empleados desde el backend
final empleadosListProvider = FutureProvider<List<EmpleadoEntity>>((ref) async {
  final authRepository = AuthRepositoryImpl();
  final empleados = await authRepository.listarEmpleados();
  return empleados;
});
