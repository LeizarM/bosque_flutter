import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/ciudad_venta_model.dart';
import 'package:bosque_flutter/domain/entities/ciudad_venta_entity.dart';
import 'package:bosque_flutter/domain/repositories/ventas_ciudades_repository.dart';

class VentasCiudadesImpl extends BaseApiRepository
    implements VentasCiudadesRepository {
  @override
  Future<CiudadesPermitidasEntity> ciudadesPermitidas() async {
    final model = await postAndReturnObject<CiudadesPermitidasModel>(
      endpoint: AppConstants.ventasCiudadesPermitidas,
      data: const {},
      fromJson: CiudadesPermitidasModel.fromJson,
      errorMessage: 'No se pudieron obtener sus ciudades',
    );
    return model?.toEntity() ??
        const CiudadesPermitidasEntity(
          ciudades: [],
          todas: false,
          esAdmin: false,
          codCiudadInicial: 0,
        );
  }

  @override
  Future<List<CiudadVentaEntity>> ciudadesVenta() async {
    final lista = await postAndReturnList<CiudadVentaModel>(
      endpoint: AppConstants.ventasUsuarioCiudadCiudadesVenta,
      fromJson: CiudadVentaModel.fromJson,
    );
    return lista.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<CiudadVentaEntity>> asignaciones() async {
    final lista = await postAndReturnList<CiudadVentaModel>(
      endpoint: AppConstants.ventasUsuarioCiudadAsignaciones,
      fromJson: CiudadVentaModel.fromJson,
    );
    return lista.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> asignar(int codUsuario, int codCiudad) async {
    await postAndReturnId(
      endpoint: AppConstants.ventasUsuarioCiudadRegistrar,
      data: {'codUsuario': codUsuario, 'codCiudad': codCiudad},
      errorMessage: 'No se pudo asignar la ciudad',
    );
  }

  @override
  Future<void> quitar(int codUsuario, int codCiudad) async {
    await postAndReturnId(
      endpoint: AppConstants.ventasUsuarioCiudadEliminar,
      data: {'codUsuario': codUsuario, 'codCiudad': codCiudad},
      errorMessage: 'No se pudo quitar la ciudad',
    );
  }
}
