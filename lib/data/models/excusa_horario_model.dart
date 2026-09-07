// Modelo del modulo Rol de Turnos de Sabado. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/domain/entities/excusa_horario_entity.dart';

/// **Origen:** no hay tabla detras. Es la proyeccion de
/// `POST /rol-sabados/refrescar-excusas-horario`.
///
/// `aplicado` viaja como `bool` real desde Java (es un `boolean` primitivo,
/// no un bit de columna) — Jackson lo serializa nativo, así que no hace falta
/// un conversor tolerante como los `rs*` del resto de este archivo.
class ExcusaHorarioModel {
  final ExcusaHorarioEntity _e;
  const ExcusaHorarioModel(this._e);

  factory ExcusaHorarioModel.fromJson(Map<String, dynamic> json) =>
      ExcusaHorarioModel(
        ExcusaHorarioEntity(
          codEmpleado: rsInt(json['codEmpleado']),
          nombreEmpleado: rsStr(json['nombreEmpleado']),
          idParticipante: rsInt(json['idParticipante']),
          idSabado: rsInt(json['idSabado']),
          fecha: rsDate(json['fecha']),
          minutosSemana: rsNum(json['minutosSemana']),
          minutosCuota: rsNum(json['minutosCuota']),
          motivo: rsStr(json['motivo']),
          aplicado: json['aplicado'] == true,
          error: rsStr(json['error']),
        ),
      );

  ExcusaHorarioEntity toEntity() => _e;
}
