// Modelo del modulo Rol de Turnos de Sabado. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/domain/entities/puente_vacacion_entity.dart';

/// **Origen:** no hay tabla detrás. Es la proyección de
/// `trs_sp_puenteVacacion @ACCION='S'`.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL.
class PuenteVacacionModel {
  final PuenteVacacionEntity _e;
  const PuenteVacacionModel(this._e);

  factory PuenteVacacionModel.fromJson(Map<String, dynamic> json) =>
      PuenteVacacionModel(
        PuenteVacacionEntity(
          accion: rsStr(json['accion']),
          nombreRol: rsStr(json['nombreRol']),
          codEmpleado: rsInt(json['codEmpleado']),
          // rsNum y no rsInt: los días vienen en fracciones (0.4375, 0.5) y
          // truncarlos convertiría medio día de vacación en cero.
          dias: rsNum(json['dias']),
          origen: rsStr(json['origen']),
          detalle: rsStr(json['detalle']),
          fecha: rsDate(json['fecha']),
          permisoDesde: rsDate(json['permisoDesde']),
          permisoHasta: rsDate(json['permisoHasta']),
          motivo: rsStr(json['motivo']),
          totalAlta: rsInt(json['totalAlta']),
          totalSalteados: rsInt(json['totalSalteados']),
          diasTotales: rsNum(json['diasTotales']),
        ),
      );

  PuenteVacacionEntity toEntity() => _e;
}
