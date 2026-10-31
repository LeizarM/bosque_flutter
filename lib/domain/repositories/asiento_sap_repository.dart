import 'package:bosque_flutter/domain/entities/asiento_sap_entity.dart';

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

  /// Alta o cambio; no toca la contraseña.
  Future<String> guardarConfig(AsientoSapConfigEntity c);

  /// La contraseña del Service Layer; el backend la cifra y no la devuelve nunca.
  Future<String> guardarClave({required int codEmpresa, required String clave});

  Future<String> eliminarConfig(int codEmpresa);

  /// Inicia y cierra sesión en SAP con lo guardado.
  Future<String> probar(int codEmpresa);
}
