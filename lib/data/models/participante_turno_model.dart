// Modelo del modulo Rol de Turnos de Sabado. Ver la entidad del mismo nombre.

import 'package:bosque_flutter/data/models/rol_sabados_json.dart';
import 'package:bosque_flutter/domain/entities/participante_turno_entity.dart';

/// **Origen:** tabla `dbo.trs_Participante`, via `p_list_trs_Participante @ACCION='L'`.
///
/// `turnosTrabaja` y los `dias*` (Vacacion, Cambio, Asueto, Excusado) los aporta
/// @T, el SUM de la derecha del Excel. En un listado @L quedan en 0.
///
/// Los `fromJson` toleran null porque el backend manda wrapper (`Long`,
/// `Integer`) en toda columna que admite NULL.
class ParticipanteTurnoModel {
  final int idParticipante;
  final int idRol;
  final int codEmpleado;
  final String nombreRol;
  final String grupoRotacion;
  final int nroOrden;
  final int turnosObjetivo;
  final int codSucursal;
  final String sucursal;
  final String cargo;
  final int codEmpresa;
  final String empresa;
  final DateTime? fechaNacimiento;
  final int esProgramador;
  final int activo;

  /// VIGENTE · SIN SABADOS · VUELVE EL dd/mm/aaaa · FUERA DE LA EMPRESA.
  /// La resuelve el listado; acá sólo se transporta.
  final String situacion;
  final DateTime? fechaSituacion;
  final int turnosTrabaja;
  final int diasVacacion;
  final int diasCambio;
  final int diasAsueto;
  final int diasExcusado;

  const ParticipanteTurnoModel({
    required this.idParticipante,
    required this.idRol,
    required this.codEmpleado,
    required this.nombreRol,
    required this.grupoRotacion,
    required this.nroOrden,
    required this.turnosObjetivo,
    required this.codSucursal,
    this.sucursal = '',
    this.cargo = '',
    this.codEmpresa = 0,
    this.empresa = '',
    this.fechaNacimiento,
    required this.esProgramador,
    required this.activo,
    this.situacion = '',
    this.fechaSituacion,
    required this.turnosTrabaja,
    required this.diasVacacion,
    required this.diasCambio,
    required this.diasAsueto,
    required this.diasExcusado,
  });

  factory ParticipanteTurnoModel.fromJson(Map<String, dynamic> json) =>
      ParticipanteTurnoModel(
        idParticipante: rsInt(json['idParticipante']),
        idRol: rsInt(json['idRol']),
        codEmpleado: rsInt(json['codEmpleado']),
        nombreRol: rsStr(json['nombreRol']),
        grupoRotacion: rsStr(json['grupoRotacion']),
        nroOrden: rsInt(json['nroOrden']),
        turnosObjetivo: rsInt(json['turnosObjetivo']),
        codSucursal: rsInt(json['codSucursal']),
        sucursal: rsStr(json['sucursal']),
        cargo: rsStr(json['cargo']),
        // LEFT JOIN contra tb_sucursal/tb_empresa: quien no tiene sucursal
        // cargada llega con los dos en null y acá colapsan a 0 y a ''.
        codEmpresa: rsInt(json['codEmpresa']),
        empresa: rsStr(json['empresa']),
        fechaNacimiento: rsDate(json['fechaNacimiento']),
        esProgramador: rsInt(json['esProgramador']),
        activo: rsInt(json['activo']),
        // Sólo vienen en el listado de participantes. En el de turnos por
        // persona llegan vacías, y la entidad trata el vacío como vigente.
        situacion: rsStr(json['situacion']),
        fechaSituacion: rsDate(json['fechaSituacion']),
        turnosTrabaja: rsInt(json['turnosTrabaja']),
        diasVacacion: rsInt(json['diasVacacion']),
        diasCambio: rsInt(json['diasCambio']),
        diasAsueto: rsInt(json['diasAsueto']),
        diasExcusado: rsInt(json['diasExcusado']),
      );

  ParticipanteTurnoEntity toEntity() => ParticipanteTurnoEntity(
    idParticipante: idParticipante,
    idRol: idRol,
    codEmpleado: codEmpleado,
    nombreRol: nombreRol,
    grupoRotacion: grupoRotacion,
    nroOrden: nroOrden,
    turnosObjetivo: turnosObjetivo,
    codSucursal: codSucursal,
    sucursal: sucursal,
    cargo: cargo,
    codEmpresa: codEmpresa,
    empresa: empresa,
    fechaNacimiento: fechaNacimiento,
    esProgramador: esProgramador,
    activo: activo,
    situacion: situacion,
    fechaSituacion: fechaSituacion,
    turnosTrabaja: turnosTrabaja,
    diasVacacion: diasVacacion,
    diasCambio: diasCambio,
    diasAsueto: diasAsueto,
    diasExcusado: diasExcusado,
  );
}
