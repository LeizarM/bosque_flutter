// Modelo del modulo Rol de Turnos de Sabado. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/domain/entities/celda_turno_entity.dart';

/// **Origen:** tabla `dbo.trs_Asignacion`, via `p_list_trs_Asignacion @ACCION='L'`.
///
/// Ojo con el vacio: **libre es la AUSENCIA de fila**, no una fila con estado
/// 'L'. Una celda que no viene en la lista es libre.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL.
class CeldaTurnoModel {
  final int idAsignacion;
  final int idRol;
  final int idParticipante;
  final int idSabado;
  final String codigoExcel;
  final String estadoNombre;
  final String origen;
  final String observacion;
  final DateTime? fecha;
  final String nombreRol;

  /// Los tres salen de `trs_Cambio` por el `OUTER APPLY` del `@ACCION='L'`, no
  /// de `trs_Asignacion`. Vienen vacíos cuando la celda no tiene un cambio
  /// aprobado detrás.
  final String cambioCon;
  final String cambioRol;
  final String cambioTipo;

  const CeldaTurnoModel({
    required this.idAsignacion,
    required this.idRol,
    required this.idParticipante,
    required this.idSabado,
    required this.codigoExcel,
    required this.estadoNombre,
    required this.origen,
    required this.observacion,
    this.fecha,
    required this.nombreRol,
    this.cambioCon = '',
    this.cambioRol = '',
    this.cambioTipo = '',
  });

  factory CeldaTurnoModel.fromJson(Map<String, dynamic> json) => CeldaTurnoModel(
    idAsignacion: rsInt(json['idAsignacion']),
    idRol: rsInt(json['idRol']),
    idParticipante: rsInt(json['idParticipante']),
    idSabado: rsInt(json['idSabado']),
    codigoExcel: rsStr(json['codigoExcel']),
    estadoNombre: rsStr(json['estadoNombre']),
    origen: rsStr(json['origen']),
    observacion: rsStr(json['observacion']),
    fecha: rsDate(json['fecha']),
    nombreRol: rsStr(json['nombreRol']),
    cambioCon: rsStr(json['cambioCon']),
    cambioRol: rsStr(json['cambioRol']),
    cambioTipo: rsStr(json['cambioTipo']),
  );

  CeldaTurnoEntity toEntity() => CeldaTurnoEntity(
    idAsignacion: idAsignacion,
    idRol: idRol,
    idParticipante: idParticipante,
    idSabado: idSabado,
    codigoExcel: codigoExcel,
    estadoNombre: estadoNombre,
    origen: origen,
    observacion: observacion,
    fecha: fecha,
    nombreRol: nombreRol,
    cambioCon: cambioCon,
    cambioRol: cambioRol,
    cambioTipo: cambioTipo,
  );
}
