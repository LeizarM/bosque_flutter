// Modelo del modulo Rol de Turnos de Sabado. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/domain/entities/programador_dependiente_entity.dart';

/// **Origen:** no hay tabla detras. Es la proyeccion de
/// `p_list_trs_Programador @ACCION='D'`.
///
/// El organigrama expandido en forma recursiva.
///
/// Se llama ProgramadorDependiente y no Dependiente porque `DependienteEntity`
/// ya existe y es otra cosa: los familiares en ficha-trabajador.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL.
class ProgramadorDependienteModel {
  final ProgramadorDependienteEntity _e;
  const ProgramadorDependienteModel(this._e);

  factory ProgramadorDependienteModel.fromJson(Map<String, dynamic> json) =>
      ProgramadorDependienteModel(
        ProgramadorDependienteEntity(
          idProgramador: rsInt(json['idProgramador']),
          codProgramador: rsInt(json['codProgramador']),
          profundidad: rsInt(json['profundidad']),
          codDependiente: rsInt(json['codDependiente']),
          nombreDependiente: rsStr(json['nombreDependiente']),
          sucDependiente: rsInt(json['sucDependiente']),
          // Sólo vienen con @ACCION='P'. Con 'D' el backend no las manda y
          // quedan en '' y 0, que es lo correcto: ahí no se preguntan.
          sucursal: rsStr(json['sucursal']),
          enElRol: rsInt(json['enElRol']),
        ),
      );

  ProgramadorDependienteEntity toEntity() => _e;
}
