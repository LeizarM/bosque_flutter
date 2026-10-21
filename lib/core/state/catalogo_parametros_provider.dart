import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';

/// El texto de un fallo tal como lo redactó el servidor. Solo se quita el
/// prefijo `Exception: ` y se traduce un error de red a su aviso.
String textoDeErrorParametros(Object error) {
  const respaldo = 'No se pudo completar la operación.';
  if (error is DioException) return DioClient.handleDioError(error, respaldo);
  final t = error.toString().replaceFirst(_prefijoException, '').trim();
  return t.isEmpty ? respaldo : t;
}

final _prefijoException = RegExp(r'^\s*(Exception:\s*)+');

@immutable
class EstadoOperacionCatalogo {
  const EstadoOperacionCatalogo({this.ocupado = false, this.error});

  /// Hay una escritura en vuelo.
  final bool ocupado;

  /// El mensaje del servidor de la última escritura fallida, tal cual.
  final String? error;
}

/// Escrituras de una pantalla de parámetros. Al salir bien llama a
/// [_alTerminar], que invalida las listas que cambiaron; el texto de éxito o
/// de error es el que redactó el procedimiento.
class OperacionesCatalogoNotifier
    extends StateNotifier<EstadoOperacionCatalogo> {
  OperacionesCatalogoNotifier(this._alTerminar)
    : super(const EstadoOperacionCatalogo());

  final void Function() _alTerminar;

  /// Devuelve null si falló o si ya había otra escritura en curso.
  Future<ResultadoEscrituraEntity?> ejecutar(
    Future<ResultadoEscrituraEntity> Function() accion,
  ) async {
    if (state.ocupado) return null;
    state = const EstadoOperacionCatalogo(ocupado: true);
    try {
      final r = await accion();
      if (!mounted) return r;
      state = const EstadoOperacionCatalogo();
      _alTerminar();
      return r;
    } catch (e) {
      if (mounted) {
        state = EstadoOperacionCatalogo(error: textoDeErrorParametros(e));
      }
      return null;
    }
  }

  void limpiarError() {
    if (state.error != null) state = const EstadoOperacionCatalogo();
  }
}
