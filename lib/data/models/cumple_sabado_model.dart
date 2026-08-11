// Modelo del modulo Rol de Turnos de Sabado. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/domain/entities/cumple_sabado_entity.dart';

/// **Origen:** no hay tabla detras. Es la proyeccion de
/// `p_list_trs_Participante @ACCION='K'`.
///
/// `situacionAsueto` dice si el asueto se aplico, si no correspondia, o si
/// quedo pisado por otra cosa.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL.
class CumpleSabadoModel {
  final CumpleSabadoEntity _e;
  const CumpleSabadoModel(this._e);

  factory CumpleSabadoModel.fromJson(Map<String, dynamic> json) =>
      CumpleSabadoModel(
        CumpleSabadoEntity(
          idParticipante: rsInt(json['idParticipante']),
          codEmpleado: rsInt(json['codEmpleado']),
          nombreRol: rsStr(json['nombreRol']),
          fechaNacimiento: rsDate(json['fechaNacimiento']),
          idSabado: rsInt(json['idSabado']),
          fechaSabado: rsDate(json['fechaSabado']),
          estadoActual: rsStr(json['estadoActual']),
          situacionAsueto: rsStr(json['situacionAsueto']),
          motivoEspecial: rsStr(json['motivoEspecial']),
        ),
      );

  CumpleSabadoEntity toEntity() => _e;
}
