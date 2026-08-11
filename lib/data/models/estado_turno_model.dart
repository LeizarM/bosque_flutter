// Modelo del modulo Rol de Turnos de Sabado. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/domain/entities/estado_turno_entity.dart';

/// **Origen:** tabla `dbo.trs_EstadoTurno`, via `p_list_trs_EstadoTurno @ACCION='L'`.
///
/// Su PK no es IDENTITY: el id se asigna a mano para que sea el mismo numero en
/// todas las bases.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL.
class EstadoTurnoModel {
  final int idEstadoTurno;
  final String codigoExcel;
  final String nombre;
  final int cuentaTurno;
  final int afectaCobertura;
  final String color;
  final String estado;

  const EstadoTurnoModel({
    required this.idEstadoTurno,
    required this.codigoExcel,
    required this.nombre,
    required this.cuentaTurno,
    required this.afectaCobertura,
    required this.color,
    required this.estado,
  });

  factory EstadoTurnoModel.fromJson(Map<String, dynamic> json) =>
      EstadoTurnoModel(
        idEstadoTurno: rsInt(json['idEstadoTurno']),
        codigoExcel: rsStr(json['codigoExcel']),
        nombre: rsStr(json['nombre']),
        cuentaTurno: rsInt(json['cuentaTurno']),
        afectaCobertura: rsInt(json['afectaCobertura']),
        color: rsStr(json['color']),
        estado: rsStr(json['estado']),
      );

  EstadoTurnoEntity toEntity() => EstadoTurnoEntity(
    idEstadoTurno: idEstadoTurno,
    codigoExcel: codigoExcel,
    nombre: nombre,
    cuentaTurno: cuentaTurno,
    afectaCobertura: afectaCobertura,
    color: color,
    estado: estado,
  );
}
