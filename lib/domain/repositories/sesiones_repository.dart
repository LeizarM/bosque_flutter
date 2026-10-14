import 'package:bosque_flutter/domain/entities/sesion_entity.dart';

/// Sesiones de la app (pantalla Sesiones). Solo administradores.
/// [cerrar] devuelve el mensaje del backend y lo lanza como `String` si no se pudo.
abstract class SesionesRepository {
  Future<List<SesionEntity>> abiertas();

  /// Las iniciadas entre [desde] y [hasta], los dos días completos (hasta 31 días).
  Future<List<SesionEntity>> historial({required DateTime desde, required DateTime hasta});

  Future<String> cerrar(BigInt idSesion);
}
