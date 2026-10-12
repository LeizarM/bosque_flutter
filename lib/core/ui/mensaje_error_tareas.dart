// Destino final: lib/core/ui/mensaje_error_tareas.dart
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:dio/dio.dart';

/// El texto de un error para mostrarlo en Tareas Rutinarias: el mensaje del
/// servidor tal cual, sin el "Exception: " del repositorio, o uno en palabras
/// si falló la red. No usa `textoParaUsuario`, que reescribe textos de otro
/// módulo, ni deja ver una DioException cruda.
String mensajeError(
  Object? e, {
  String porDefecto = 'No se pudo completar. Vuelve a intentar.',
}) {
  if (e is DioException) return DioClient.handleDioError(e, porDefecto);
  final texto = (e ?? '').toString().replaceFirst('Exception: ', '').trim();
  return texto.isEmpty ? porDefecto : texto;
}
