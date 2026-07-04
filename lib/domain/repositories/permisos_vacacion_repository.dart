import 'dart:typed_data';
import 'package:bosque_flutter/data/models/feriado_model.dart';
import 'package:bosque_flutter/domain/entities/permiso_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_permiso_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_permiso_vacacion_entity.dart';

abstract class PermisosVacacionRepository {
  /// Obtiene los días disponibles y el resumen de vacaciones para un empleado.
  Future<PermisoEntity?> getResumenVacaciones(int codEmpleado);
  // En domain/repositories/permisos_vacacion_repository.dart agregar:
  Future<String> crearSolicitudPermiso(SolicitudPermisoEntity solicitud);
  Future<String> aprobarSolicitud(int codSolicitud, int audUsuarioI);
  Future<String> rechazarSolicitud(
    int codSolicitud,
    int audUsuarioI,
    String motivoRechazo,
  );
  Future<List<SolicitudPermisoEntity>> listarPendientes(int codUsuarioLogueado);
  Future<List<SolicitudPermisoEntity>> listarMisSolicitudes(int codEmpleado);
  Future<List<TipoPermisoVacacionEntity>> getTiposPermiso();
  Future<Uint8List> descargarRptPermisoVacacion(int codPermiso);
  Future<List<FeriadoModel>> getFeriados(int codEmpleado);
  Future<SolicitudPermisoEntity?> previsualizarSaldo(SolicitudPermisoEntity filtro);
}
