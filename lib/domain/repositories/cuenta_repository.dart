import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';

/// La cuenta del propio usuario (pantalla tbUsuario/cpassword).
abstract class CuentaRepository {
  /// Cambia la contraseña del usuario de la sesión. Las reglas y los textos
  /// los pone el servidor; una clave actual errada vuelve como 400, no 401.
  Future<ResultadoEscrituraEntity> cambiarClave({
    required String actual,
    required String nueva,
    required String confirmacion,
  });
}
