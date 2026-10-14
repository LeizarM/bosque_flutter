import 'package:bosque_flutter/domain/entities/recuperacion_enviada_entity.dart';

/// Recuperación de acceso con un código que llega al correo corporativo.
/// Los dos métodos lanzan el mensaje para el usuario como `String` cuando no se puede.
abstract class RecuperacionAccesoRepository {
  Future<RecuperacionEnviadaEntity> solicitarCodigo(String login);

  /// Devuelve el mensaje de confirmación del backend.
  Future<String> restablecer({
    required String login,
    required String codigo,
    required String nuevaContrasena,
  });
}
