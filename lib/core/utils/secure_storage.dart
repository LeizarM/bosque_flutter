import 'dart:async';
import 'dart:convert';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  // Usar encryptedSharedPreferences en Android para evitar problemas con el Keystore
  // que puede colgar en algunos dispositivos (Samsung, Huawei, Xiaomi)
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _tokenKey = 'auth_token';
  static const _userDataKey = 'user_data';
  static const _tokenExpiryKey = 'token_expiry';

  /// Timeout de seguridad para operaciones de lectura del storage
  static const _readTimeout = Duration(seconds: 3);

  /// Lectura segura con timeout para evitar cuelgues en dispositivos problemáticos
  Future<String?> _safeRead(String key) async {
    try {
      return await _storage
          .read(key: key)
          .timeout(
            _readTimeout,
            onTimeout: () {
              console('⚠️ SecureStorage timeout al leer key: $key');
              return null;
            },
          );
    } catch (e) {
      console('⚠️ SecureStorage error al leer key $key: $e');
      return null;
    }
  }

  /// Escritura segura con timeout
  Future<void> _safeWrite(String key, String value) async {
    try {
      await _storage
          .write(key: key, value: value)
          .timeout(
            _readTimeout,
            onTimeout: () {
              console('⚠️ SecureStorage timeout al escribir key: $key');
            },
          );
    } catch (e) {
      console('⚠️ SecureStorage error al escribir key $key: $e');
    }
  }

  /// Eliminación segura con timeout
  Future<void> _safeDelete(String key) async {
    try {
      await _storage
          .delete(key: key)
          .timeout(
            _readTimeout,
            onTimeout: () {
              console('⚠️ SecureStorage timeout al eliminar key: $key');
            },
          );
    } catch (e) {
      console('⚠️ SecureStorage error al eliminar key $key: $e');
    }
  }

  Future<void> saveToken(String token) async {
    await _safeWrite(_tokenKey, token);

    // Intenta extraer la fecha de expiración del JWT
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final data = json.decode(decoded);

        if (data.containsKey('exp')) {
          // 'exp' es un timestamp Unix en segundos
          final expDate = DateTime.fromMillisecondsSinceEpoch(
            data['exp'] * 1000,
          );
          await saveTokenExpiry(expDate);
          console('🔑 Token expira el: $expDate');
        }
      }
    } catch (e) {
      console('⚠️ Error decodificando token JWT: $e');
      // Si no podemos extraer, establecemos una expiración predeterminada de 1 hora
      final expDate = DateTime.now().add(const Duration(hours: 1));
      await saveTokenExpiry(expDate);
    }
  }

  Future<String?> getToken() async {
    return await _safeRead(_tokenKey);
  }

  Future<void> deleteToken() async {
    await _safeDelete(_tokenKey);
    await _safeDelete(_tokenExpiryKey);
  }

  Future<void> saveUserData(String userDataJson) async {
    await _safeWrite(_userDataKey, userDataJson);
  }

  Future<String?> getUserData() async {
    return await _safeRead(_userDataKey);
  }

  Future<void> deleteUserData() async {
    await _safeDelete(_userDataKey);
  }

  // Nuevos métodos para manejar la expiración del token
  Future<void> saveTokenExpiry(DateTime expiryDate) async {
    final timestamp = expiryDate.millisecondsSinceEpoch.toString();
    await _safeWrite(_tokenExpiryKey, timestamp);
  }

  Future<DateTime?> getTokenExpiry() async {
    final timestamp = await _safeRead(_tokenExpiryKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    }
    return null;
  }

  Future<bool> isTokenExpired() async {
    try {
      final token = await getToken();
      if (token == null) {
        return true; // No hay token, considerarlo expirado
      }

      final expiry = await getTokenExpiry();
      if (expiry == null) {
        return true; // No hay fecha de expiración, considerarlo expirado
      }

      // Verificar si la fecha de expiración es anterior a la fecha actual
      final now = DateTime.now();
      final isExpired = expiry.isBefore(now);

      if (isExpired) {
        console('🔑 Token expirado el: $expiry');
      }

      return isExpired;
    } catch (e) {
      console('⚠️ Error verificando expiración del token: $e');
      return true; // En caso de error, asumimos que el token está expirado
    }
  }

  // Método para limpiar toda la sesión
  Future<void> clearSession() async {
    await deleteToken();
    await deleteUserData();
  }

  // =========================================================================
  // Métodos para persistir preferencias de tema
  // =========================================================================
  static const _themeColorKey = 'theme_color_index';
  static const _themeDarkModeKey = 'theme_dark_mode';

  /// Guarda el índice del color seleccionado
  Future<void> saveThemeColor(int colorIndex) async {
    await _safeWrite(_themeColorKey, colorIndex.toString());
  }

  /// Obtiene el índice del color guardado (default: 2 = green)
  Future<int> getThemeColor() async {
    final value = await _safeRead(_themeColorKey);
    return value != null ? int.tryParse(value) ?? 2 : 2;
  }

  /// Guarda la preferencia de modo oscuro
  Future<void> saveThemeDarkMode(bool isDark) async {
    await _safeWrite(_themeDarkModeKey, isDark.toString());
  }

  /// Obtiene la preferencia de modo oscuro (default: false)
  Future<bool> getThemeDarkMode() async {
    final value = await _safeRead(_themeDarkModeKey);
    return value == 'true';
  }
}
