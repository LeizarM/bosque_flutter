import 'dart:async';
import 'dart:convert';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Resultado detallado de leer el token, para que el interceptor pueda
/// distinguir "no hay sesión" de "no se pudo leer ahora" (fallo transitorio).
enum TokenReadStatus {
  /// Token presente y válido.
  ok,

  /// Lectura exitosa pero NO hay token (sesión genuinamente ausente).
  absent,

  /// No se pudo leer (timeout / cuelgue del Keystore). NO implica falta de
  /// sesión: es transitorio y NO debe forzar logout.
  unavailable,
}

class TokenResult {
  final TokenReadStatus status;
  final String? token;
  const TokenResult(this.status, [this.token]);
}

class SecureStorage {
  // Usar encryptedSharedPreferences en Android para evitar problemas con el Keystore
  // que puede colgar en algunos dispositivos (Samsung, Huawei, Xiaomi).
  //
  // resetOnError:true → si el blob cifrado no se puede descifrar (Keystore
  // inválido tras restaurar un backup o actualizar la app), el plugin borra
  // el valor corrupto y devuelve null en vez de dejar el storage inservible
  // de forma permanente. Sin esto, todas las lecturas fallaban para siempre.
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
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
    } on PlatformException catch (e) {
      // Descifrado fallido: el storage quedó corrupto (típicamente por una
      // llave de Keystore inválida tras restaurar un backup o actualizar).
      // Lo reseteamos para que el próximo login pueda re-escribir con una
      // llave válida y no quede inservible de forma permanente.
      console('⚠️ SecureStorage corrupto al leer key $key: $e → deleteAll()');
      await deleteAll();
      return null;
    } catch (e) {
      console('⚠️ SecureStorage error al leer key $key: $e');
      return null;
    }
  }

  /// Borra TODO el contenido del secure storage. Se usa para recuperar un
  /// storage corrupto (PlatformException al descifrar) y desde el interceptor
  /// de Dio cuando detecta una sesión inválida.
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll().timeout(_readTimeout);
    } catch (e) {
      console('⚠️ SecureStorage error en deleteAll: $e');
    }
  }

  /// Escritura segura con timeout. Devuelve `true` sólo si la escritura se
  /// persistió realmente; `false` ante timeout/excepción. Así el llamador
  /// (login) puede detectar dispositivos donde el Keystore no puede escribir
  /// y mostrar un error en vez de entrar en un bucle de login silencioso.
  Future<bool> _safeWrite(String key, String value) async {
    try {
      await _storage.write(key: key, value: value).timeout(_readTimeout);
      return true;
    } on TimeoutException {
      console('⚠️ SecureStorage timeout al escribir key: $key');
      return false;
    } catch (e) {
      console('⚠️ SecureStorage error al escribir key $key: $e');
      return false;
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

  /// Devuelve `true` sólo si el token se persistió (para detectar dispositivos
  /// donde el Keystore no puede escribir). La expiración es best-effort.
  Future<bool> saveToken(String token) async {
    final ok = await _safeWrite(_tokenKey, token);

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
    return ok;
  }

  Future<String?> getToken() async {
    return await _safeRead(_tokenKey);
  }

  /// Lectura del token que DISTINGUE entre "no hay token" (sesión ausente) y
  /// "no se pudo leer" (fallo transitorio del Keystore). Reintenta una vez ante
  /// timeouts para no expulsar a un usuario válido por un cuelgue momentáneo
  /// —el escenario exacto de los dispositivos Samsung/Huawei/Xiaomi—.
  Future<TokenResult> readTokenDetailed() async {
    for (var intento = 0; intento < 2; intento++) {
      try {
        final value = await _storage
            .read(key: _tokenKey)
            .timeout(_readTimeout);
        if (value == null || value.isEmpty) {
          return const TokenResult(TokenReadStatus.absent);
        }
        return TokenResult(TokenReadStatus.ok, value);
      } on TimeoutException {
        console('⚠️ SecureStorage timeout leyendo token (intento ${intento + 1})');
        // Reintentar una vez: los cuelgues del Keystore suelen ser transitorios.
      } on PlatformException catch (e) {
        // Descifrado fallido → storage corrupto. Lo reseteamos y lo tratamos
        // como sesión ausente (el usuario deberá iniciar sesión una vez, y el
        // próximo login re-escribirá con una llave válida).
        console('⚠️ SecureStorage corrupto leyendo token: $e → deleteAll()');
        await deleteAll();
        return const TokenResult(TokenReadStatus.absent);
      } catch (e) {
        console('⚠️ SecureStorage error leyendo token: $e');
        // Error no determinístico: lo tratamos como transitorio.
      }
    }
    return const TokenResult(TokenReadStatus.unavailable);
  }

  Future<void> deleteToken() async {
    await _safeDelete(_tokenKey);
    await _safeDelete(_tokenExpiryKey);
  }

  Future<bool> saveUserData(String userDataJson) async {
    return await _safeWrite(_userDataKey, userDataJson);
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
