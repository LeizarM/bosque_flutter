import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/network/dio_postulante.dart';
import 'package:bosque_flutter/core/utils/sesion_postulante_storage.dart';
import 'package:bosque_flutter/data/models/tcpe_sesion_postulante_model.dart';
import 'package:bosque_flutter/data/repositories/rendicion_endpoints.dart';
import 'package:bosque_flutter/data/repositories/tcpe_api_base.dart';
import 'package:bosque_flutter/domain/entities/tcpe_sesion_postulante_entity.dart';
import 'package:bosque_flutter/domain/repositories/postulante_examen_repository.dart';

/// `/examen-publico/**` con el Dio y el token del postulante.
class PostulanteExamenImpl extends TcpeApiBase
    with RendicionPorEndpoints
    implements PostulanteExamenRepository {
  PostulanteExamenImpl({SesionPostulanteStorage? storage})
    : _storage = storage ?? SesionPostulanteStorage();

  final SesionPostulanteStorage _storage;

  /// Reemplaza al Dio de empleado de [TcpeApiBase]: todos los helpers de la
  /// base pasan por aquí.
  @override
  Dio get dio => DioPostulante.instancia();

  @override
  RendicionEndpoints get endpointsRendicion => RendicionEndpoints.postulante;

  @override
  Future<TcpeSesionPostulanteEntity> ingresar(String login, String password) async {
    final TcpeSesionPostulanteModel? m;
    try {
      final r = await dio.post<Object?>(
        AppConstants.tcpePublicoLogin,
        data: {'login': login.trim(), 'password2': password},
      );
      final cuerpo = r.data;
      final dato = cuerpo is Map ? cuerpo['data'] : null;
      m = dato is Map ? TcpeSesionPostulanteModel.fromJson(Map<String, dynamic>.from(dato)) : null;
    } on DioException catch (e) {
      throw Exception(mensajeIngresoFallido(e));
    }
    final token = m?.token ?? '';
    if (m == null || token.isEmpty) {
      throw Exception('El servidor no devolvió la sesión del examen.');
    }
    await _storage.guardar(
      token,
      vence: m.expiracion,
      datos: m.toJson()..remove('token'),
    );
    return m.toEntity();
  }

  @override
  Future<void> registrarDatos({
    required String ci,
    required String nombres,
    required String apellidoPaterno,
    String? apellidoMaterno,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.tcpePublicoRegistro,
      data: {
        'ci': ci.trim(),
        'nombres': nombres.trim(),
        'apellidoPaterno': apellidoPaterno.trim(),
        'apellidoMaterno': (apellidoMaterno ?? '').trim(),
      },
      errorMessage: 'No se pudieron guardar tus datos.',
    );
    await marcarDatosCompletos();
  }

  @override
  Future<TcpeSesionPostulanteEntity?> sesionVigente() async {
    final token = await _storage.tokenVigente();
    if (token == null) return null;
    final datos = await _storage.leerDatos() ?? const <String, dynamic>{};
    return TcpeSesionPostulanteModel.fromJson({...datos, 'token': token}).toEntity();
  }

  @override
  Future<void> marcarDatosCompletos() async {
    final datos = await _storage.leerDatos() ?? <String, dynamic>{};
    await _storage.guardarDatos({...datos, 'datosCompletos': true});
  }

  @override
  Future<void> salir() => _storage.limpiar();

  /// El motivo del backend tal cual (clave mala o credencial ya usada tras
  /// entregar). Un 401 sin motivo es usuario o clave incorrectos.
  static String mensajeIngresoFallido(DioException e) {
    final motivo = _motivo(e.response?.data);
    if (e.response?.statusCode == 401) return motivo ?? 'Usuario o clave incorrectos.';
    return motivo ?? DioClient.handleDioError(e, 'No se pudo ingresar al examen.');
  }

  static String? _motivo(Object? cuerpo) {
    var c = cuerpo;
    if (c is String && c.trim().startsWith('{')) {
      try {
        c = jsonDecode(c);
      } catch (_) {
        return null;
      }
    }
    final m = c is Map ? '${c['message'] ?? ''}'.trim() : '';
    return m.isEmpty ? null : m;
  }
}
