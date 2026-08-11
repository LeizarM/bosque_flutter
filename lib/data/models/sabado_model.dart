// Modelo del modulo Rol de Turnos de Sabado. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/domain/entities/sabado_entity.dart';

/// **Origen:** tabla `dbo.trs_Sabado`, via `p_list_trs_Sabado @ACCION='L'`.
///
/// `personasTrabajan` no sale de @L sino de @C (cobertura). Si el listado vino
/// por @L el campo queda en 0, y eso es correcto, no un dato perdido.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL.
class SabadoModel {
  final int idSabado;
  final int idRol;
  final DateTime? fecha;
  final int anio;
  final int mes;
  final int trimestre;
  final int indiceAnio;
  final String grupoQueRota;
  final int esFeriado;
  final String? alcanceEvento;
  final String motivoEspecial;
  final int activo;
  final int personasTrabajan;

  const SabadoModel({
    required this.idSabado,
    required this.idRol,
    this.fecha,
    required this.anio,
    required this.mes,
    required this.trimestre,
    required this.indiceAnio,
    required this.grupoQueRota,
    required this.esFeriado,
    this.alcanceEvento,
    required this.motivoEspecial,
    required this.activo,
    required this.personasTrabajan,
  });

  factory SabadoModel.fromJson(Map<String, dynamic> json) => SabadoModel(
    idSabado: rsInt(json['idSabado']),
    idRol: rsInt(json['idRol']),
    fecha: rsDate(json['fecha']),
    anio: rsInt(json['anio']),
    mes: rsInt(json['mes']),
    trimestre: rsInt(json['trimestre']),
    indiceAnio: rsInt(json['indiceAnio']),
    grupoQueRota: rsStr(json['grupoQueRota']),
    esFeriado: rsInt(json['esFeriado']),
    // Ojo: null acá NO es un dato faltante, significa "sábado normal".
    alcanceEvento: json['alcanceEvento']?.toString(),
    motivoEspecial: rsStr(json['motivoEspecial']),
    activo: rsInt(json['activo']),
    personasTrabajan: rsInt(json['personasTrabajan']),
  );

  SabadoEntity toEntity() => SabadoEntity(
    idSabado: idSabado,
    idRol: idRol,
    fecha: fecha,
    anio: anio,
    mes: mes,
    trimestre: trimestre,
    indiceAnio: indiceAnio,
    grupoQueRota: grupoQueRota,
    esFeriado: esFeriado,
    alcanceEvento: alcanceEvento,
    motivoEspecial: motivoEspecial,
    activo: activo,
    personasTrabajan: personasTrabajan,
  );
}
