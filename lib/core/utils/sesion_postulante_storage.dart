import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:bosque_flutter/core/utils/console_log.dart';

/// La sesión del postulante en claves propias del almacenamiento seguro: no
/// toca `auth_token` y convive con la del empleado. El token queda también en
/// memoria (en web el cifrado es lento) y solo esta clase lo escribe.
class SesionPostulanteStorage {
  static const _claveToken = 'tcpe_postulante_token';
  static const _claveVence = 'tcpe_postulante_vence';
  static const _claveDatos = 'tcpe_postulante_datos';
  static const _espera = Duration(seconds: 3);

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true, resetOnError: true),
  );

  static String? _token;
  static DateTime? _vence;
  static bool _leido = false;

  /// Manda el `exp` del JWT (epoch, sin zona) y [vence] queda de respaldo: el
  /// `expiracion` del login viene en hora de La Paz sin desfase y en otra zona
  /// horaria se leería corrido varias horas.
  Future<void> guardar(String token, {DateTime? vence, Map<String, dynamic>? datos}) async {
    _token = token;
    _vence = _venceDelJwt(token) ?? vence;
    _leido = true;
    try {
      await _storage.write(key: _claveToken, value: token).timeout(_espera);
      if (_vence != null) {
        await _storage
            .write(key: _claveVence, value: _vence!.millisecondsSinceEpoch.toString())
            .timeout(_espera);
      }
      if (datos != null) await guardarDatos(datos);
    } catch (e) {
      // Queda en memoria: el examen sigue funcionando mientras la pestaña viva.
      console('⚠️ No se pudo guardar la sesión del postulante: $e');
    }
  }

  Future<void> guardarDatos(Map<String, dynamic> datos) async {
    try {
      await _storage.write(key: _claveDatos, value: jsonEncode(datos)).timeout(_espera);
    } catch (e) {
      console('⚠️ No se pudieron guardar los datos del postulante: $e');
    }
  }

  Future<Map<String, dynamic>?> leerDatos() async {
    try {
      final t = await _storage.read(key: _claveDatos).timeout(_espera);
      if (t == null || t.isEmpty) return null;
      final d = jsonDecode(t);
      return d is Map ? Map<String, dynamic>.from(d) : null;
    } catch (_) {
      return null;
    }
  }

  /// El token si sigue vigente; null si no hay o ya venció.
  Future<String?> tokenVigente() async {
    if (!_leido) {
      try {
        _token = await _storage.read(key: _claveToken).timeout(_espera);
        final v = await _storage.read(key: _claveVence).timeout(_espera);
        _vence = v == null ? _venceDelJwt(_token) : DateTime.fromMillisecondsSinceEpoch(int.parse(v));
      } catch (e) {
        console('⚠️ No se pudo leer la sesión del postulante: $e');
      }
      _leido = true;
    }
    final t = _token;
    if (t == null || t.isEmpty) return null;
    if (_vence != null && _vence!.isBefore(DateTime.now())) return null;
    return t;
  }

  Future<void> limpiar() async {
    _token = null;
    _vence = null;
    _leido = true;
    for (final k in [_claveToken, _claveVence, _claveDatos]) {
      try {
        await _storage.delete(key: k).timeout(_espera);
      } catch (_) {
        // Ya está anulado en memoria.
      }
    }
  }

  static DateTime? _venceDelJwt(String? token) {
    try {
      final partes = (token ?? '').split('.');
      if (partes.length != 3) return null;
      final carga = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))));
      final exp = carga is Map ? carga['exp'] : null;
      return exp is num ? DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000) : null;
    } catch (_) {
      return null;
    }
  }
}
