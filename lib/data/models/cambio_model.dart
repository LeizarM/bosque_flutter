// Modelo del modulo Rol de Turnos de Sabado. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/domain/entities/cambio_entity.dart';

/// **Origen:** tabla `dbo.trs_Cambio`, via `p_list_trs_Cambio @ACCION='L'`.
///
/// Los nombres de titular y reemplazo vienen ya resueltos por el @L.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL.
class CambioModel {
  final CambioEntity _e;
  const CambioModel(this._e);

  factory CambioModel.fromJson(Map<String, dynamic> json) => CambioModel(
    CambioEntity(
      idCambio: rsInt(json['idCambio']),
      idRol: rsInt(json['idRol']),
      idSabado: rsInt(json['idSabado']),
      sabadoCubierto: rsDate(json['sabadoCubierto']),
      codEmpleadoTitular: rsInt(json['codEmpleadoTitular']),
      titular: rsStr(json['titular']),
      codEmpleadoReemplazo: rsInt(json['codEmpleadoReemplazo']),
      reemplazo: rsStr(json['reemplazo']),
      idSabadoReposicion: rsInt(json['idSabadoReposicion']),
      fechaReposicion: rsDate(json['fechaReposicion']),
      tipo: rsStr(json['tipo']),
      estado: rsStr(json['estado']),
      motivo: rsStr(json['motivo']),
      codAprobador: rsInt(json['codAprobador']),
      fechaSolicitud: rsDate(json['fechaSolicitud']),
      fechaResolucion: rsDate(json['fechaResolucion']),
    ),
  );

  CambioEntity toEntity() => _e;
}
