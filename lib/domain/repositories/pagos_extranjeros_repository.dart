import 'package:bosque_flutter/domain/entities/detalle_solicitud_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/proveedor_empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_pago_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_proveedor_entity.dart';

abstract class PagosExtranjerosRepository {
  /// Registra o actualiza la cabecera de la solicitud de pago.
  /// Retorna el ID generado/actualizado.
  Future<BigInt> registrarSolicitudPago(SolicitudPagoEntity entity);

  /// Registra o actualiza un proveedor dentro de la solicitud.
  /// Retorna el ID generado/actualizado.
  Future<BigInt> registrarSolicitudProveedor(SolicitudProveedorEntity entity);

  /// Registra o actualiza un detalle (factura) de un proveedor.
  /// Retorna el ID generado/actualizado.
  Future<BigInt> registrarDetalleSolicitud(DetalleSolicitudEntity entity);

  /// Obtiene la lista de empresas disponibles.
  Future<List<EmpresaEntity>> getEmpresas();

  /// Obtiene la lista de proveedores filtrados por empresa.
  Future<List<ProveedorEmpresaEntity>> getProveedoresXEmpresa(int codEmpresa);

  /// Obtiene las facturas de proveedor y órdenes de compra por empresa (SAP).
  Future<List<DetalleSolicitudEntity>> getFacProvYOrdCompra(int codEmpresa);
}
