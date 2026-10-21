import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/ciudad_model.dart';
import 'package:bosque_flutter/data/models/empresa_model.dart';
import 'package:bosque_flutter/data/models/resultado_escritura_model.dart';
import 'package:bosque_flutter/data/models/sucursal_model.dart';
import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:bosque_flutter/domain/repositories/empresas_sucursales_repository.dart';

/// Empresas y sucursales contra el backend. Los textos de éxito y de error
/// los redactan `p_abm_Empresa` y `p_abm_Sucursal`.
class EmpresasSucursalesImpl extends BaseApiRepository
    implements EmpresasSucursalesRepository {
  @override
  Future<List<EmpresaEntity>> listarEmpresas() async {
    final m = await postAndReturnList<EmpresaModel>(
      endpoint: AppConstants.empresasSucursalesEmpresasListar,
      fromJson: EmpresaModel.fromJson,
    );
    return m.map((x) => x.toEntity()).toList();
  }

  @override
  Future<List<SucursalEntity>> listarSucursales() async {
    final m = await postAndReturnList<SucursalModel>(
      endpoint: AppConstants.empresasSucursalesSucursalesListar,
      data: const {'id': 0},
      fromJson: SucursalModel.fromJson,
    );
    return m.map((x) => x.toEntity()).toList();
  }

  @override
  Future<List<CiudadEntity>> ciudades() async {
    final m = await postAndReturnList<CiudadModel>(
      endpoint: AppConstants.empresasSucursalesCiudades,
      fromJson: CiudadModel.fromJson,
    );
    return m.map((x) => x.toEntity()).toList();
  }

  @override
  Future<ResultadoEscrituraEntity> registrarEmpresa(EmpresaEntity e) =>
      _escribir(
        AppConstants.empresasSucursalesEmpresasRegistrar,
        EmpresaModel.fromEntity(e).toJson(),
      );

  @override
  Future<ResultadoEscrituraEntity> registrarSucursal(SucursalEntity s) {
    final json = SucursalModel.fromEntity(s).toJson()..remove('empresa');
    return _escribir(AppConstants.empresasSucursalesSucursalesRegistrar, json);
  }

  @override
  Future<ResultadoEscrituraEntity> eliminarEmpresa(int codEmpresa) => _escribir(
    AppConstants.empresasSucursalesEmpresasEliminar,
    {'id': codEmpresa},
  );

  @override
  Future<ResultadoEscrituraEntity> eliminarSucursal(int codSucursal) =>
      _escribir(AppConstants.empresasSucursalesSucursalesEliminar, {
        'id': codSucursal,
      });

  Future<ResultadoEscrituraEntity> _escribir(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final m = await postAndReturnFullResponse<ResultadoEscrituraModel>(
      endpoint: endpoint,
      data: data,
      fromJson: ResultadoEscrituraModel.fromJson,
    );
    return m.toEntity();
  }
}
