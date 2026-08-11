// Modelo del modulo Rol de Turnos de Sabado. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/domain/entities/convocatoria_entity.dart';

/// **Origen:** tabla `dbo.trs_Convocatoria`, via `p_list_trs_Convocatoria @ACCION='L'`.
///
/// @L es la lista cruda. `situacion`, `celdaFinal`, `leTocabaPorRotacion`,
/// `grupoRotacion`, `nombreRol` y `codEmpleado` los aporta @D, que contrasta la
/// convocatoria contra la rotacion. En @L esos campos quedan vacios.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL.
class ConvocatoriaModel {
  final ConvocatoriaEntity _e;
  const ConvocatoriaModel(this._e);

  factory ConvocatoriaModel.fromJson(Map<String, dynamic> json) =>
      ConvocatoriaModel(
        ConvocatoriaEntity(
          idConvocatoria: rsInt(json['idConvocatoria']),
          idRol: rsInt(json['idRol']),
          idSabado: rsInt(json['idSabado']),
          idParticipante: rsInt(json['idParticipante']),
          codEmpleado: rsInt(json['codEmpleado']),
          nombreRol: rsStr(json['nombreRol']),
          grupoRotacion: rsStr(json['grupoRotacion']),
          tipo: rsStr(json['tipo']),
          motivo: rsStr(json['motivo']),
          leTocabaPorRotacion: rsInt(json['leTocabaPorRotacion']),
          celdaFinal: rsStr(json['celdaFinal']),
          situacion: rsStr(json['situacion']),
        ),
      );

  ConvocatoriaEntity toEntity() => _e;
}
