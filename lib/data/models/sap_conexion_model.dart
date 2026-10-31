import 'package:bosque_flutter/domain/entities/sap_conexion_entity.dart';

/// Una fila de POST /sap/conexiones/listar o de un desplegable de módulo (que llega sin URL ni
/// usuario), y el cuerpo de /sap/conexiones/guardar.
abstract final class SapConexionModel {
  static SapConexionEntity fromJson(Map<String, dynamic> j) => SapConexionEntity(
    idConexion: j['idConexion'] as int?,
    nombre: j['nombre'] ?? '',
    codEmpresa: j['codEmpresa'] ?? 0,
    empresa: j['empresa'] ?? '',
    ambiente: j['ambiente'] ?? SapConexionEntity.prueba,
    linkedServer: j['linkedServer'] ?? '',
    baseSap: j['baseSap'] ?? '',
    slUrl: j['slUrl'] ?? '',
    slUsuario: j['slUsuario'] ?? '',
    habilitada: j['habilitada'] != false,
    claveCargada: j['claveCargada'] == true,
    enUso: j['enUso'] ?? 0,
    audFecha:
        j['audFecha'] != null ? DateTime.tryParse(j['audFecha'].toString()) : null,
  );

  /// Sin la contraseña, que tiene su propio endpoint, ni lo que calcula el backend.
  static Map<String, dynamic> toJson(SapConexionEntity c) => {
    'idConexion': c.idConexion,
    'nombre': c.nombre,
    'codEmpresa': c.codEmpresa,
    'ambiente': c.ambiente,
    'linkedServer': c.linkedServer,
    'baseSap': c.baseSap,
    'slUrl': c.slUrl,
    'slUsuario': c.slUsuario,
    'habilitada': c.habilitada,
  };
}
