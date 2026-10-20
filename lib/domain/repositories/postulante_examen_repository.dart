import 'package:bosque_flutter/domain/entities/tcpe_sesion_postulante_entity.dart';
import 'package:bosque_flutter/domain/repositories/rendicion_examen_repository.dart';

/// Endpoints `/examen-publico/**`: el postulante externo con su propio token,
/// que se guarda aparte del de empleado y nunca se mezcla con él.
abstract class PostulanteExamenRepository implements RendicionExamenRepository {
  /// Guarda el token del postulante y devuelve la sesión.
  Future<TcpeSesionPostulanteEntity> ingresar(String login, String password);

  Future<void> registrarDatos({
    required String ci,
    required String nombres,
    required String apellidoPaterno,
    String? apellidoMaterno,
  });

  /// La sesión guardada si el token sigue vigente, o null.
  Future<TcpeSesionPostulanteEntity?> sesionVigente();

  /// Marca en la sesión guardada que ya completó sus datos.
  Future<void> marcarDatosCompletos();

  Future<void> salir();
}
