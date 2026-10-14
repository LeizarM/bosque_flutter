import 'package:bosque_flutter/domain/entities/recuperacion_enviada_entity.dart';
import 'package:bosque_flutter/domain/repositories/recuperacion_acceso_repository.dart';

/// Recuperación de acceso sin backend: guarda lo que se le pidió y responde
/// lo configurado. Un `String` en los errores imita al repositorio real.
class RepoRecuperacionFalso implements RecuperacionAccesoRepository {
  final List<String> solicitudes = [];
  final List<Map<String, String>> restablecimientos = [];

  Object? errorAlSolicitar;
  Object? errorAlRestablecer;
  RecuperacionEnviadaEntity enviada = const RecuperacionEnviadaEntity(
    correo: 'j****z@esppapel.com',
    minutosVigencia: 15,
    segundosParaReenviar: 60,
  );
  String mensajeListo = 'Listo: cambiamos tu contraseña. Ya puedes iniciar sesión.';

  @override
  Future<RecuperacionEnviadaEntity> solicitarCodigo(String login) async {
    solicitudes.add(login);
    final error = errorAlSolicitar;
    if (error != null) throw error;
    return enviada;
  }

  @override
  Future<String> restablecer({
    required String login,
    required String codigo,
    required String nuevaContrasena,
  }) async {
    restablecimientos.add({
      'login': login,
      'codigo': codigo,
      'nuevaContrasena': nuevaContrasena,
    });
    final error = errorAlRestablecer;
    if (error != null) throw error;
    return mensajeListo;
  }
}
