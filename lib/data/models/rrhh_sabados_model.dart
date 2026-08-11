// Modelo del modulo Rol de Turnos de Sabado. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/domain/entities/rrhh_sabados_entity.dart';

/// **Origen:** tabla `dbo.trs_Rrhh`, via `p_list_trs_Rrhh @ACCION='L'`.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL.
class RrhhSabadosModel {
  final RrhhSabadosEntity _e;
  const RrhhSabadosModel(this._e);

  factory RrhhSabadosModel.fromJson(Map<String, dynamic> json) =>
      RrhhSabadosModel(
        RrhhSabadosEntity(
          idRrhh: rsInt(json['idRrhh']),
          codEmpleado: rsInt(json['codEmpleado']),
          persona: rsStr(json['persona']),
          cargo: rsStr(json['cargo']),
          sucursal: rsStr(json['sucursal']),
          estado: rsStr(json['estado']),
          observacion: rsStr(json['observacion']),
          audFecha: rsDate(json['audFecha']),
        ),
      );

  RrhhSabadosEntity toEntity() => _e;
}
