import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/detalle_solicitud_model.dart';
import 'package:bosque_flutter/data/models/empresa_model.dart';
import 'package:bosque_flutter/data/models/proveedor_empresa_model.dart';
import 'package:bosque_flutter/domain/entities/detalle_solicitud_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/proveedor_empresa_entity.dart';
import 'package:bosque_flutter/domain/repositories/pagos_extranjeros_repository.dart';

class PagosExtranjerosImpl extends BaseApiRepository
    implements PagosExtranjerosRepository {
  @override
  Future<BigInt> guardarSolicitudCompleta(Map<String, dynamic> payload) {
    return postAndReturnId(
      endpoint: AppConstants.guardarSolicitudCompleta,
      data: payload,
      errorMessage: 'Error al guardar la solicitud completa',
    );
  }

  @override
  Future<List<EmpresaEntity>> getEmpresas() async {
    // 3. Mapeamos la lista limpiamente
    final modelos = await postAndReturnList<EmpresaModel>(
      endpoint: AppConstants.deplstEmpresas,
      fromJson: (json) => EmpresaModel.fromJson(json),
    );
    // Convertimos los Modelos a Entities para el Dominio
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ProveedorEmpresaEntity>> getProveedoresXEmpresa(
    int codEmpresa,
  ) async {
    final modelos = await postAndReturnList<ProveedorEmpresaModel>(
      endpoint: AppConstants.lstProveedoresXEmpresa,
      data: {'codEmpresa': codEmpresa},
      fromJson: (json) => ProveedorEmpresaModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<DetalleSolicitudEntity>> getFacProvYOrdCompra(
    int codEmpresa,
  ) async {
    final modelos = await postAndReturnList<DetalleSolicitudModel>(
      endpoint: AppConstants.lstFacProvYOrdCompra,
      data: {'codEmpresa': codEmpresa},
      fromJson: (json) => DetalleSolicitudModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }
}
