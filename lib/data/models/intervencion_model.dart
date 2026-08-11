// Modelo del modulo Rol de Turnos de Sabado. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/domain/entities/intervencion_entity.dart';

/// **Origen:** no hay tabla detras. Es la proyeccion de
/// `p_list_trs_Rol @ACCION='I'`.
///
/// Unifica las cuatro formas de salirse del default: evento, programacion,
/// cambio y correccion manual.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL.
class IntervencionModel {
  final IntervencionEntity _e;
  const IntervencionModel(this._e);

  factory IntervencionModel.fromJson(Map<String, dynamic> json) =>
      IntervencionModel(
        IntervencionEntity(
          idRol: rsInt(json['idRol']),
          idSabado: rsInt(json['idSabado']),
          fechaSabado: rsDate(json['fechaSabado']),
          tipoIntervencion: rsStr(json['tipoIntervencion']),
          codEmpleado: rsInt(json['codEmpleado']),
          nombreRol: rsStr(json['nombreRol']),
          quedoEn: rsStr(json['quedoEn']),
          loHizo: rsInt(json['loHizo']),
          cuando: rsDate(json['cuando']),
          diasAntelacion: rsInt(json['diasAntelacion']),
          motivo: rsStr(json['motivo']),
        ),
      );

  IntervencionEntity toEntity() => _e;
}
