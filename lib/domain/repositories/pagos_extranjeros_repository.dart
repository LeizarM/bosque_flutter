import 'package:bosque_flutter/domain/entities/detalle_solicitud_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/proveedor_empresa_entity.dart';

abstract class PagosExtranjerosRepository {
  /// Guarda de forma atómica la solicitud completa (cabecera + proveedores +
  /// detalles) en un único endpoint transaccional.
  /// Retorna el ID de la solicitud generado/actualizado.
  Future<BigInt> guardarSolicitudCompleta(Map<String, dynamic> payload);

  /// Obtiene la lista de empresas disponibles.
  Future<List<EmpresaEntity>> getEmpresas();

  /// Obtiene la lista de proveedores filtrados por empresa.
  Future<List<ProveedorEmpresaEntity>> getProveedoresXEmpresa(int codEmpresa);

  /// Obtiene las facturas de proveedor y órdenes de compra por empresa (SAP).
  Future<List<DetalleSolicitudEntity>> getFacProvYOrdCompra(int codEmpresa);
}
