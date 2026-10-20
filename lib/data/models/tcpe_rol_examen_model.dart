import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_rol_examen_entity.dart';

/// `tcpe_rolExamen`: Lote de exámenes: categoría, duración, cantidad de preguntas y fecha.
/// Columnas de `p_list_tcpe_RolExamen` (sin `password2`) más `nombreUsuario`.
class TcpeRolExamenModel {
  final BigInt codRolExamen;
  final BigInt? codCapacitacion;
  final BigInt? codConvocatoria;
  final BigInt? codArea;
  final int? ponderacion;
  final int? puntos;
  final int? duracionMinutos;
  final int? cantidadPreg;
  final int? cantExamenGenerar;
  final String? ubicacion;
  final String? modalidad;
  final bool? esRolCapacitacion;
  final DateTime? fecha;
  final String? horaInicio;
  final String? horaFin;
  final BigInt? codClasificacion;
  final String? titulo;
  final String? observaciones;
  final double? notaAprobacion;
  final bool? mostrarRespuestas;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeRolExamenModel({
    required this.codRolExamen,
    this.codCapacitacion,
    this.codConvocatoria,
    this.codArea,
    this.ponderacion,
    this.puntos,
    this.duracionMinutos,
    this.cantidadPreg,
    this.cantExamenGenerar,
    this.ubicacion,
    this.modalidad,
    this.esRolCapacitacion,
    this.fecha,
    this.horaInicio,
    this.horaFin,
    this.codClasificacion,
    this.titulo,
    this.observaciones,
    this.notaAprobacion,
    this.mostrarRespuestas,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeRolExamenModel.fromJson(Map<String, dynamic> json) => TcpeRolExamenModel(
    codRolExamen: tcpeBigInt(json['codRolExamen']) ?? BigInt.zero,
    codCapacitacion: tcpeBigInt(json['codCapacitacion']),
    codConvocatoria: tcpeBigInt(json['codConvocatoria']),
    codArea: tcpeBigInt(json['codArea']),
    ponderacion: tcpeInt(json['ponderacion']),
    puntos: tcpeInt(json['puntos']),
    duracionMinutos: tcpeInt(json['duracionMinutos']),
    cantidadPreg: tcpeInt(json['cantidadPreg']),
    cantExamenGenerar: tcpeInt(json['cantExamenGenerar']),
    ubicacion: tcpeTexto(json['ubicacion']),
    modalidad: tcpeTexto(json['modalidad']),
    esRolCapacitacion: tcpeBool(json['esRolCapacitacion']),
    fecha: tcpeFecha(json['fecha']),
    horaInicio: tcpeHora(json['horaInicio']),
    horaFin: tcpeHora(json['horaFin']),
    codClasificacion: tcpeBigInt(json['codClasificacion']),
    titulo: tcpeTexto(json['titulo']),
    observaciones: tcpeTexto(json['observaciones']),
    notaAprobacion: tcpeDouble(json['notaAprobacion']),
    mostrarRespuestas: tcpeBool(json['mostrarRespuestas']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codRolExamen': codRolExamen.toInt(),
    'codCapacitacion': codCapacitacion?.toInt(),
    'codConvocatoria': codConvocatoria?.toInt(),
    'codArea': codArea?.toInt(),
    'ponderacion': ponderacion,
    'puntos': puntos,
    'duracionMinutos': duracionMinutos,
    'cantidadPreg': cantidadPreg,
    'cantExamenGenerar': cantExamenGenerar,
    'ubicacion': ubicacion,
    'modalidad': modalidad,
    'esRolCapacitacion': esRolCapacitacion,
    'fecha': tcpeFechaJson(fecha),
    'horaInicio': horaInicio,
    'horaFin': horaFin,
    'codClasificacion': codClasificacion?.toInt(),
    'titulo': titulo,
    'observaciones': observaciones,
    'notaAprobacion': notaAprobacion,
    'mostrarRespuestas': mostrarRespuestas,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeRolExamenEntity toEntity() => TcpeRolExamenEntity(
    codRolExamen: codRolExamen,
    codCapacitacion: codCapacitacion,
    codConvocatoria: codConvocatoria,
    codArea: codArea,
    ponderacion: ponderacion,
    puntos: puntos,
    duracionMinutos: duracionMinutos,
    cantidadPreg: cantidadPreg,
    cantExamenGenerar: cantExamenGenerar,
    ubicacion: ubicacion,
    modalidad: modalidad,
    esRolCapacitacion: esRolCapacitacion,
    fecha: fecha,
    horaInicio: horaInicio,
    horaFin: horaFin,
    codClasificacion: codClasificacion,
    titulo: titulo,
    observaciones: observaciones,
    notaAprobacion: notaAprobacion,
    mostrarRespuestas: mostrarRespuestas,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeRolExamenModel.fromEntity(TcpeRolExamenEntity e) => TcpeRolExamenModel(
    codRolExamen: e.codRolExamen,
    codCapacitacion: e.codCapacitacion,
    codConvocatoria: e.codConvocatoria,
    codArea: e.codArea,
    ponderacion: e.ponderacion,
    puntos: e.puntos,
    duracionMinutos: e.duracionMinutos,
    cantidadPreg: e.cantidadPreg,
    cantExamenGenerar: e.cantExamenGenerar,
    ubicacion: e.ubicacion,
    modalidad: e.modalidad,
    esRolCapacitacion: e.esRolCapacitacion,
    fecha: e.fecha,
    horaInicio: e.horaInicio,
    horaFin: e.horaFin,
    codClasificacion: e.codClasificacion,
    titulo: e.titulo,
    observaciones: e.observaciones,
    notaAprobacion: e.notaAprobacion,
    mostrarRespuestas: e.mostrarRespuestas,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
