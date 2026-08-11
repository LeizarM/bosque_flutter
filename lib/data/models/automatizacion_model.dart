// Modelo del modulo Rol de Turnos de Sabado. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/domain/entities/automatizacion_entity.dart';

/// **Origen:** no hay tabla detras. Es la proyeccion de
/// `p_list_trs_Asignacion @ACCION='A'`.
///
/// **Devuelve UNA sola fila**, por eso el repositorio usa `postAndReturnObject`
/// y no `postAndReturnList`.
///
/// Los contadores son `Integer` y no `int` a proposito: un SUM sobre cero filas
/// devuelve NULL, no 0.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL.
class AutomatizacionModel {
  final AutomatizacionEntity _e;
  const AutomatizacionModel(this._e);

  factory AutomatizacionModel.fromJson(Map<String, dynamic> json) =>
      AutomatizacionModel(
        AutomatizacionEntity(
          celdasTotales: rsInt(json['celdasTotales']),
          conDecisionHumana: rsInt(json['conDecisionHumana']),
          generadasSolas: rsInt(json['generadasSolas']),
        ),
      );

  AutomatizacionEntity toEntity() => _e;
}
