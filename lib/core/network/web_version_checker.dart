import 'dart:async';
import 'package:bosque_flutter/core/utils/web_reload.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

/// Verifica cada minuto si se publicó otra versión en web.
///
/// Compara el build con el que arrancó la pestaña (`window.bosqueBuild`, de
/// web/flutter_bootstrap.js) con el del index.html publicado. Antes leía
/// `build_number` de version.json, que el build no trae: el aviso nunca salía.
class WebVersionChecker extends StateNotifier<bool> {
  Timer? _timer;
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      responseType: ResponseType.plain,
    ),
  );

  /// [state] = true cuando se detectó nueva versión disponible
  WebVersionChecker() : super(false) {
    if (kIsWeb) _init();
  }

  void _init() {
    final enEjecucion = buildWebEnEjecucion();
    if (enEjecucion == null || enEjecucion.isEmpty) return;
    _timer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _check(enEjecucion),
    );
  }

  Future<void> _check(String enEjecucion) async {
    try {
      // _t evita la caché del navegador.
      final response = await _dio.get<String>(
        'index.html',
        queryParameters: {'_t': DateTime.now().millisecondsSinceEpoch},
      );
      final publicado = buildPublicadoDe(response.data ?? '');
      if (!mounted || publicado == null || publicado == enEjecucion) return;
      state = true; // nueva versión disponible
      _timer?.cancel();
    } catch (e) {
      debugPrint('WebVersionChecker: no se pudo leer index.html: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dio.close();
    super.dispose();
  }
}

/// El build que trae un index.html publicado, o null si no lo trae.
@visibleForTesting
String? buildPublicadoDe(String indexHtml) =>
    RegExp(r'bosqueBuild\s*=\s*"(\d+)"').firstMatch(indexHtml)?.group(1);

/// `true` cuando hay una nueva versión desplegada.
/// Solo activo en web.
final webVersionProvider = StateNotifierProvider<WebVersionChecker, bool>(
  (ref) => WebVersionChecker(),
);
