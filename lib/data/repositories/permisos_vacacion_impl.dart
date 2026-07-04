import 'dart:typed_data';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/permiso_model.dart';
import 'package:bosque_flutter/data/models/solicitudPermisoModel.dart';
import 'package:bosque_flutter/domain/entities/permiso_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_permiso_entity.dart';
import 'package:bosque_flutter/domain/repositories/permisos_vacacion_repository.dart';
import 'package:bosque_flutter/data/models/tipo_permiso_vacacion_model.dart';
import 'package:bosque_flutter/domain/entities/tipo_permiso_vacacion_entity.dart';
import 'package:bosque_flutter/data/models/feriado_model.dart';

class PermisosVacacionImpl extends BaseApiRepository
    implements PermisosVacacionRepository {
  @override
  Future<PermisoEntity?> getResumenVacaciones(int codEmpleado) async {
    final modelos = await postAndReturnList<PermisoModel>(
      endpoint: AppConstants.vacDiasDisponibles,
      data: {'codEmpleado': codEmpleado},
      fromJson: (json) => PermisoModel.fromJson(json),
    );
    if (modelos.isNotEmpty) {
      return modelos.first.toEntity();
    }
    return null;
  }

  @override
  Future<String> crearSolicitudPermiso(SolicitudPermisoEntity solicitud) async {
    final model = SolicitudPermisoModel.fromEntity(solicitud);
    final response = await postAndReturnFullResponse<SolicitudPermisoResponse>(
      endpoint: AppConstants.solicitarVacacion,
      data: model.toJson(),
      fromJson: (json) => SolicitudPermisoResponse.fromJson(json),
      errorMessage: 'Error al enviar la solicitud de permiso',
    );
    return response.message;
  }

  @override
  Future<String> aprobarSolicitud(int codSolicitud, int audUsuarioI) async {
    final response = await postAndReturnFullResponse<SolicitudPermisoResponse>(
      endpoint: AppConstants.aprobarVacacion,
      data: {'codSolicitud': codSolicitud, 'audUsuarioI': audUsuarioI},
      fromJson: (json) => SolicitudPermisoResponse.fromJson(json),
      errorMessage: 'Error al aprobar la solicitud',
    );
    return response.message;
  }

  @override
  Future<String> rechazarSolicitud(
    int codSolicitud,
    int audUsuarioI,
    String motivoRechazo,
  ) async {
    final response = await postAndReturnFullResponse<SolicitudPermisoResponse>(
      endpoint: AppConstants.rechazarVacacion,
      data: {
        'codSolicitud': codSolicitud,
        'motivo': motivoRechazo,
        'audUsuarioI': audUsuarioI,
      },
      fromJson: (json) => SolicitudPermisoResponse.fromJson(json),
      errorMessage: 'Error al rechazar la solicitud',
    );
    return response.message;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // permisos_vacacion_impl.dart
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Future<List<SolicitudPermisoEntity>> listarPendientes(
    int codUsuarioLogueado,
  ) async {
    final modelos = await postAndReturnList<SolicitudPermisoModel>(
      endpoint: AppConstants.pendientesVacacion, // '/vacacion/pendientes'
      data: {'codUsuarioLogueado': codUsuarioLogueado},
      fromJson:
          SolicitudPermisoModel.fromJson, // reutiliza el fromJson existente
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<SolicitudPermisoEntity>> listarMisSolicitudes(
    int codEmpleado,
  ) async {
    final modelos = await postAndReturnList(
      endpoint: AppConstants.solicitudesIndividuales,
      data: {
        'codEmpleado': codEmpleado,
      }, // El backend Java armará el filtro con esto
      fromJson: (json) => SolicitudPermisoModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<SolicitudPermisoEntity?> previsualizarSaldo(SolicitudPermisoEntity filtro) async {
    final model = SolicitudPermisoModel.fromEntity(filtro);
    final modelos = await postAndReturnList<SolicitudPermisoModel>(
      endpoint: AppConstants.previsualizarSaldo,
      data: model.toJson(),
      fromJson: (json) => SolicitudPermisoModel.fromJson(json),
    );
    if (modelos.isNotEmpty) {
      return modelos.first.toEntity();
    }
    return null;
  }

  @override
  Future<List<TipoPermisoVacacionEntity>> getTiposPermiso() async {
    final modelos = await postAndReturnList<TipoPermisoVacacionModel>(
      endpoint: AppConstants.tipoPermisoSolicitudVacacion,
      fromJson: (json) => TipoPermisoVacacionModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Uint8List> descargarRptPermisoVacacion(int codPermiso) async {
    return DioClient.descargarReportePdf(
      endpoint: AppConstants.rptPermisoVacacion,
      data: {'codPermiso': codPermiso},
    );
  }

  @override
  Future<List<FeriadoModel>> getFeriados(int codEmpleado) async {
    return postAndReturnList<FeriadoModel>(
      endpoint: AppConstants.feriados,
      data: {'codEmpleado': codEmpleado},
      fromJson: (json) => FeriadoModel.fromJson(json),
    );
  }
}
