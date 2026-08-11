// Modelo del modulo Rol de Turnos de Sabado. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/domain/entities/programador_entity.dart';

/// **Origen:** tabla `dbo.trs_Programador`, via `p_list_trs_Programador @ACCION='L'`.
///
/// `dependientes` es un COUNT sobre `fn_trs_ProgramadorDependiente()` dentro del
/// mismo @L, no una columna.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL.
class ProgramadorModel {
  final ProgramadorEntity _e;
  const ProgramadorModel(this._e);

  factory ProgramadorModel.fromJson(Map<String, dynamic> json) =>
      ProgramadorModel(
        ProgramadorEntity(
          idProgramador: rsInt(json['idProgramador']),
          codEmpleado: rsInt(json['codEmpleado']),
          jefe: rsStr(json['jefe']),
          codSucursal: rsInt(json['codSucursal']),
          sucursal: rsStr(json['sucursal']),
          alcance: rsStr(json['alcance']),
          codEmpleadoReemplazo: rsInt(json['codEmpleadoReemplazo']),
          reemplazo: rsStr(json['reemplazo']),
          estado: rsStr(json['estado']),
          dependientes: rsInt(json['dependientes']),
        ),
      );

  ProgramadorEntity toEntity() => _e;
}
