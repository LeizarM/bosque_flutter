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
  Future<String> anularSolicitud(
    int codSolicitud,
    int audUsuarioI,
    String motivoAnulacion,
  );
  Future<List<SolicitudPermisoEntity>> listarPendientes(int codUsuarioLogueado);
  /// El kardex de solicitudes y permisos de una persona.
  ///
  /// [anio] y [mes] en `null` son «no filtres»: el SP los recibe como NULL y
  /// devuelve todo el histórico. La pantalla manda el año corriente por defecto
  /// porque esta lista no se purga nunca y crece con cada solicitud.
  Future<List<SolicitudPermisoEntity>> listarMisSolicitudes(
    int codEmpleado, {
    int? anio,
    int? mes,
  });
  Future<List<TipoPermisoVacacionEntity>> getTiposPermisosVacaciones(int codEmpleado, int codUsuarioLogueado);
  Future<Uint8List> descargarRptPermisoVacacion(int codPermiso);
  Future<List<FeriadoModel>> getFeriados(int codEmpleado);
  Future<SolicitudPermisoEntity?> previsualizarSaldo(
    SolicitudPermisoEntity filtro,
  );
  Future<List<SolicitudPermisoEntity>> obtenerPermisosProximosDashboard(int audUsuarioI);
}
