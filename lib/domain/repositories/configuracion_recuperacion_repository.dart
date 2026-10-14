import 'package:bosque_flutter/domain/entities/configuracion_recuperacion_entity.dart';

/// Parámetros de la recuperación de acceso. Solo administradores.
/// [guardar] y [probar] devuelven el mensaje del backend y lo lanzan como `String` si no se pudo.
abstract class ConfiguracionRecuperacionRepository {
  Future<List<ConfiguracionRecuperacionEntity>> listar();

  Future<String> guardar({required String clave, required String valor});

  Future<String> probar(String correo);
}
