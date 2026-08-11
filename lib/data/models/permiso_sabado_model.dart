// Modelo del modulo Rol de Turnos de Sabado. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/domain/entities/permiso_sabado_entity.dart';

/// **Origen:** no hay tabla detras. Es la proyeccion de
/// `p_list_trs_PermisoSabado @ACCION='L'`.
///
/// @L trae todos; @D solo los desfasados, que es lo que consume la pestania de
/// Control.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL.
class PermisoSabadoModel {
  final PermisoSabadoEntity _e;
  const PermisoSabadoModel(this._e);

  factory PermisoSabadoModel.fromJson(Map<String, dynamic> json) =>
      PermisoSabadoModel(
        PermisoSabadoEntity(
          idSabado: rsInt(json['idSabado']),
          fecha: rsDate(json['fecha']),
          idParticipante: rsInt(json['idParticipante']),
          codEmpleado: rsInt(json['codEmpleado']),
          nombreRol: rsStr(json['nombreRol']),
          tipoPermiso: rsStr(json['tipoPermiso']),
          letraQueCorresponde: rsStr(json['letraQueCorresponde']),
          letraActual: rsStr(json['letraActual']),
          origen: rsStr(json['origen']),
          motivo: rsStr(json['motivo']),
        ),
      );

  PermisoSabadoEntity toEntity() => _e;
}
