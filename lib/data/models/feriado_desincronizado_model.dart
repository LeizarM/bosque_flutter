// Modelo del modulo Rol de Turnos de Sabado. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/domain/entities/feriado_desincronizado_entity.dart';

/// **Origen:** no hay tabla detras. Es la proyeccion de
/// `p_list_trs_Sabado @ACCION='F'`.
///
/// Compara `trs_Sabado.esFeriado` contra `trh_diaNoLaborable`.
///
/// `quePasa` ya viene redactado por el SP: se muestra tal cual.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL.
class FeriadoDesincronizadoModel {
  final FeriadoDesincronizadoEntity _e;
  const FeriadoDesincronizadoModel(this._e);

  factory FeriadoDesincronizadoModel.fromJson(Map<String, dynamic> json) =>
      FeriadoDesincronizadoModel(
        FeriadoDesincronizadoEntity(
          idSabado: rsInt(json['idSabado']),
          idRol: rsInt(json['idRol']),
          rol: rsStr(json['rol']),
          fecha: rsDate(json['fecha']),
          marcadoEnElRol: rsInt(json['marcadoEnElRol']),
          aplicaEnRRHH: rsInt(json['aplicaEnRRHH']),
          motivo: rsStr(json['motivo']),
          quePasa: rsStr(json['quePasa']),
          personasQueHoyFiguranTrabajando: rsInt(
            json['personasQueHoyFiguranTrabajando'],
          ),
        ),
      );

  FeriadoDesincronizadoEntity toEntity() => _e;
}
