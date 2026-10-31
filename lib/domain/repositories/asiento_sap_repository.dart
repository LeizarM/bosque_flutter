import 'package:bosque_flutter/domain/entities/asiento_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/sap_conexion_entity.dart';

/// El asiento contable de la planilla en SAP y su configuración por empresa.
abstract class AsientoSapRepository {
  /// Las empresas que se pueden enviar: habilitadas y con la contraseña cargada.
  Future<List<AsientoSapEmpresaEntity>> empresas();

  /// El asiento armado, para revisarlo. No toca SAP.
  Future<AsientoSapEntity?> vistaPrevia({
    required int anio,
    required int mes,
    required int codEmpresa,
  });

  /// Crea el asiento en SAP y devuelve el mensaje del backend (con el número de asiento).
  Future<String> enviar({
    required int anio,
    required int mes,
    required int codEmpresa,
  });

  Future<List<AsientoSapConfigEntity>> listarConfig();

  /// Alta o cambio. La conexión tiene que ser de la misma empresa.
  Future<String> guardarConfig(AsientoSapConfigEntity c);

  Future<String> eliminarConfig(int codEmpresa);

  /// Inicia y cierra sesión en SAP con la conexión de esa empresa.
  Future<String> probar(int codEmpresa);

  /// Las conexiones a SAP para el desplegable: sin URL, usuario ni contraseña.
  Future<List<SapConexionEntity>> conexiones();
}
