import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

/// Verifica periódicamente si hay una nueva versión desplegada en web.
/// Compara el build_number en /version.json con el capturado al inicio.
class WebVersionChecker extends StateNotifier<bool> {
  Timer? _timer;
  String? _initialBuildNumber;
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  /// [state] = true cuando se detectó nueva versión disponible
  WebVersionChecker() : super(false) {
    if (kIsWeb) _init();
  }

  Future<void> _init() async {
    // Capturar build number actual al iniciar la app
    _initialBuildNumber = await _fetchBuildNumber();
    if (_initialBuildNumber == null) return;

    // Chequear cada 60 segundos
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _check());
  }

  Future<String?> _fetchBuildNumber() async {
    try {
      // Agregar timestamp para evitar cache del navegador
      final response = await _dio.get(
        'version.json',
        queryParameters: {'_t': DateTime.now().millisecondsSinceEpoch},
      );
      final data =
          response.data is String
              ? jsonDecode(response.data) as Map<String, dynamic>
              : response.data as Map<String, dynamic>;
      return data['build_number'] as String?;
    } catch (e) {
      debugPrint('WebVersionChecker: Error fetching version.json: $e');
      return null;
    }
  }

  Future<void> _check() async {
    if (_initialBuildNumber == null) return;
    final remoteBuild = await _fetchBuildNumber();
    if (remoteBuild != null && remoteBuild != _initialBuildNumber) {
      state = true; // nueva versión disponible
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dio.close();
    super.dispose();
  }
}

/// `true` cuando hay una nueva versión desplegada.
/// Solo activo en web.
final webVersionProvider = StateNotifierProvider<WebVersionChecker, bool>(
  (ref) => WebVersionChecker(),
);
