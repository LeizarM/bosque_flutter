import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userDataKey = 'user_data';
  static const _tokenExpiryKey = 'token_expiry';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    
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
          final expDate = DateTime.fromMillisecondsSinceEpoch(data['exp'] * 1000);
          await saveTokenExpiry(expDate);
          debugPrint('🔑 Token expira el: $expDate');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error decodificando token JWT: $e');
      // Si no podemos extraer, establecemos una expiración predeterminada de 1 hora
      final expDate = DateTime.now().add(const Duration(hours: 1));
      await saveTokenExpiry(expDate);
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _tokenExpiryKey);
  }

  Future<void> saveUserData(String userDataJson) async {
    await _storage.write(key: _userDataKey, value: userDataJson);
  }

  Future<String?> getUserData() async {
    return await _storage.read(key: _userDataKey);
  }

  Future<void> deleteUserData() async {
    await _storage.delete(key: _userDataKey);
  }
  
  // Nuevos métodos para manejar la expiración del token
  Future<void> saveTokenExpiry(DateTime expiryDate) async {
    final timestamp = expiryDate.millisecondsSinceEpoch.toString();
    await _storage.write(key: _tokenExpiryKey, value: timestamp);
  }
  
  Future<DateTime?> getTokenExpiry() async {
    final timestamp = await _storage.read(key: _tokenExpiryKey);
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
        debugPrint('🔑 Token expirado el: $expiry');
      }
      
      return isExpired;
    } catch (e) {
      debugPrint('⚠️ Error verificando expiración del token: $e');
      return true; // En caso de error, asumimos que el token está expirado
    }
  }
  
  // Método para limpiar toda la sesión
  Future<void> clearSession() async {
    await deleteToken();
    await deleteUserData();
  }
}