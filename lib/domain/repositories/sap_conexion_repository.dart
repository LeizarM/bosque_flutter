import 'package:bosque_flutter/domain/entities/sap_conexion_entity.dart';

/// Las conexiones a SAP que comparten los módulos (Administración > Conexiones SAP).
abstract class SapConexionRepository {
  Future<List<SapConexionEntity>> listar();

  /// Alta ([SapConexionEntity.idConexion] null) o cambio; no toca la contraseña.
  Future<String> guardar(SapConexionEntity c);

  /// La contraseña del Service Layer; el backend la cifra y no la devuelve nunca.
  Future<String> guardarClave({required int idConexion, required String clave});

  /// Falla si algún módulo la usa.
  Future<String> eliminar(int idConexion);

  /// Inicia y cierra sesión en SAP con lo guardado.
  Future<String> probar(int idConexion);
}
