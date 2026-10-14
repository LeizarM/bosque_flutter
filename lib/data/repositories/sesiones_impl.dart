import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/sesion_model.dart';
import 'package:bosque_flutter/domain/entities/sesion_entity.dart';
import 'package:bosque_flutter/domain/repositories/sesiones_repository.dart';
import 'package:intl/intl.dart';

class SesionesImpl extends BaseApiRepository implements SesionesRepository {
  static final DateFormat _dia = DateFormat('yyyy-MM-dd');

  @override
  Future<List<SesionEntity>> abiertas() {
    return postAndReturnList(
      endpoint: AppConstants.sesionesAbiertas,
      fromJson: (json) => SesionModel.fromJson(json).toEntity(),
    );
  }

  @override
  Future<List<SesionEntity>> historial({required DateTime desde, required DateTime hasta}) {
    return postAndReturnList(
      endpoint: AppConstants.sesionesHistorial,
      data: {'desde': _dia.format(desde), 'hasta': _dia.format(hasta)},
      fromJson: (json) => SesionModel.fromJson(json).toEntity(),
    );
  }

  @override
  Future<String> cerrar(BigInt idSesion) {
    return postAndReturnFullResponse(
      endpoint: AppConstants.sesionesCerrar,
      data: {'idSesion': idSesion.toInt()},
      fromJson: (raiz) => raiz['message'] as String? ?? '',
      errorMessage: 'No se pudo cerrar la sesión. Inténtalo de nuevo.',
    );
  }
}
