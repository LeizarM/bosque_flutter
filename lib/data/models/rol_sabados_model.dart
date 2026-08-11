// Modelo del modulo Rol de Turnos de Sabado. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/domain/entities/rol_sabados_entity.dart';

/// **Origen:** tabla `dbo.trs_Rol`, via `p_list_trs_Rol @ACCION='L'`.
///
/// `sabados`, `participantes` y `celdas` NO son columnas de la tabla: son
/// subqueries COUNT dentro del mismo @L.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL.
class RolSabadosModel {
  final int idRol;
  final int codEmpresa;
  final int codSucursal;
  final String sucursal;
  final int anio;
  final String nombre;
  final int turnosObjetivoA;
  final int turnosObjetivoB;
  final int coberturaObjetivo;
  final int aplicaAsuetoCumple;
  final String estado;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int sabados;
  final int participantes;
  final int celdas;

  const RolSabadosModel({
    required this.idRol,
    required this.codEmpresa,
    required this.codSucursal,
    required this.sucursal,
    required this.anio,
    required this.nombre,
    required this.turnosObjetivoA,
    required this.turnosObjetivoB,
    required this.coberturaObjetivo,
    required this.aplicaAsuetoCumple,
    required this.estado,
    this.fechaInicio,
    this.fechaFin,
    required this.sabados,
    required this.participantes,
    required this.celdas,
  });

  factory RolSabadosModel.fromJson(Map<String, dynamic> json) =>
      RolSabadosModel(
        idRol: rsInt(json['idRol']),
        codEmpresa: rsInt(json['codEmpresa']),
        codSucursal: rsInt(json['codSucursal']),
        sucursal: rsStr(json['sucursal']),
        anio: rsInt(json['anio']),
        nombre: rsStr(json['nombre']),
        turnosObjetivoA: rsInt(json['turnosObjetivoA']),
        turnosObjetivoB: rsInt(json['turnosObjetivoB']),
        coberturaObjetivo: rsInt(json['coberturaObjetivo']),
        aplicaAsuetoCumple: rsInt(json['aplicaAsuetoCumple']),
        estado: rsStr(json['estado']),
        fechaInicio: rsDate(json['fechaInicio']),
        fechaFin: rsDate(json['fechaFin']),
        sabados: rsInt(json['sabados']),
        participantes: rsInt(json['participantes']),
        celdas: rsInt(json['celdas']),
      );

  RolSabadosEntity toEntity() => RolSabadosEntity(
    idRol: idRol,
    codEmpresa: codEmpresa,
    codSucursal: codSucursal,
    sucursal: sucursal,
    anio: anio,
    nombre: nombre,
    turnosObjetivoA: turnosObjetivoA,
    turnosObjetivoB: turnosObjetivoB,
    coberturaObjetivo: coberturaObjetivo,
    aplicaAsuetoCumple: aplicaAsuetoCumple,
    estado: estado,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    sabados: sabados,
    participantes: participantes,
    celdas: celdas,
  );
}
