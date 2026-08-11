// Modelo del modulo Rol de Turnos de Sabado. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/domain/entities/programacion_entity.dart';

/// **Origen:** tabla `dbo.trs_Programacion`, via `p_list_trs_Programacion @ACCION='L'`.
///
/// `celdasAfectadas` y `controlAntelacion` son calculados dentro del @L, no
/// columnas de la tabla.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL.
class ProgramacionModel {
  final ProgramacionEntity _e;
  const ProgramacionModel(this._e);

  factory ProgramacionModel.fromJson(Map<String, dynamic> json) =>
      ProgramacionModel(
        ProgramacionEntity(
          idProgramacion: rsInt(json['idProgramacion']),
          idRol: rsInt(json['idRol']),
          idSabado: rsInt(json['idSabado']),
          sabado: rsDate(json['sabado']),
          codEmpleadoProgramador: rsInt(json['codEmpleadoProgramador']),
          codEmpleadoEjecutor: rsInt(json['codEmpleadoEjecutor']),
          fechaProgramacion: rsDate(json['fechaProgramacion']),
          diasAntelacion: rsInt(json['diasAntelacion']),
          controlAntelacion: rsStr(json['controlAntelacion']),
          estado: rsStr(json['estado']),
          motivo: rsStr(json['motivo']),
          celdasAfectadas: rsInt(json['celdasAfectadas']),
        ),
      );

  ProgramacionEntity toEntity() => _e;
}
