import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_lote_entity.dart';

/// Lote de exámenes con su avance (`p_list_tcpe_Lote` L).
class TcpeLoteModel {
  final BigInt codRolExamen;
  final String? titulo;
  final String? observaciones;
  final BigInt? codArea;
  final String? nombreArea;
  final BigInt? codClasificacion;
  final String? nombreClasificacion;
  final String? modalidad;
  final int? duracionMinutos;
  final int? cantidadPreg;
  final int? cantExamenGenerar;
  final DateTime? fecha;
  final String? horaInicio;
  final String? horaFin;
  final String? ubicacion;
  final int examenes;
  final int sinIniciar;
  final int enCurso;
  final int vencidos;
  final int porRevisar;
  final int calificados;
  final int ausentes;
  final DateTime? inicioVentana;
  final DateTime? finVentana;
  final double? promedio;
  final double? notaAprobacion;
  final bool? mostrarRespuestas;
  final int aprobados;
  final int reprobados;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeLoteModel({
    required this.codRolExamen,
    this.titulo,
    this.observaciones,
    this.codArea,
    this.nombreArea,
    this.codClasificacion,
    this.nombreClasificacion,
    this.modalidad,
    this.duracionMinutos,
    this.cantidadPreg,
    this.cantExamenGenerar,
    this.fecha,
    this.horaInicio,
    this.horaFin,
    this.ubicacion,
    this.examenes = 0,
    this.sinIniciar = 0,
    this.enCurso = 0,
    this.vencidos = 0,
    this.porRevisar = 0,
    this.calificados = 0,
    this.ausentes = 0,
    this.inicioVentana,
    this.finVentana,
    this.promedio,
    this.notaAprobacion,
    this.mostrarRespuestas,
    this.aprobados = 0,
    this.reprobados = 0,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeLoteModel.fromJson(Map<String, dynamic> json) => TcpeLoteModel(
    codRolExamen: tcpeBigInt(json['codRolExamen']) ?? BigInt.zero,
    titulo: tcpeTexto(json['titulo']),
    observaciones: tcpeTexto(json['observaciones']),
    codArea: tcpeBigInt(json['codArea']),
    nombreArea: tcpeTexto(json['nombreArea']),
    codClasificacion: tcpeBigInt(json['codClasificacion']),
    nombreClasificacion: tcpeTexto(json['nombreClasificacion']),
    modalidad: tcpeTexto(json['modalidad']),
    duracionMinutos: tcpeInt(json['duracionMinutos']),
    cantidadPreg: tcpeInt(json['cantidadPreg']),
    cantExamenGenerar: tcpeInt(json['cantExamenGenerar']),
    fecha: tcpeFecha(json['fecha']),
    horaInicio: tcpeHora(json['horaInicio']),
    horaFin: tcpeHora(json['horaFin']),
    ubicacion: tcpeTexto(json['ubicacion']),
    examenes: tcpeInt(json['examenes']) ?? 0,
    sinIniciar: tcpeInt(json['sinIniciar']) ?? 0,
    enCurso: tcpeInt(json['enCurso']) ?? 0,
    vencidos: tcpeInt(json['vencidos']) ?? 0,
    porRevisar: tcpeInt(json['porRevisar']) ?? 0,
    calificados: tcpeInt(json['calificados']) ?? 0,
    ausentes: tcpeInt(json['ausentes']) ?? 0,
    inicioVentana: tcpeFecha(json['inicioVentana']),
    finVentana: tcpeFecha(json['finVentana']),
    promedio: tcpeDouble(json['promedio']),
    notaAprobacion: tcpeDouble(json['notaAprobacion']),
    mostrarRespuestas: tcpeBool(json['mostrarRespuestas']),
    aprobados: tcpeInt(json['aprobados']) ?? 0,
    reprobados: tcpeInt(json['reprobados']) ?? 0,
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codRolExamen': codRolExamen.toInt(),
    'titulo': titulo,
    'observaciones': observaciones,
    'codArea': codArea?.toInt(),
    'nombreArea': nombreArea,
    'codClasificacion': codClasificacion?.toInt(),
    'nombreClasificacion': nombreClasificacion,
    'modalidad': modalidad,
    'duracionMinutos': duracionMinutos,
    'cantidadPreg': cantidadPreg,
    'cantExamenGenerar': cantExamenGenerar,
    'fecha': tcpeFechaJson(fecha),
    'horaInicio': horaInicio,
    'horaFin': horaFin,
    'ubicacion': ubicacion,
    'examenes': examenes,
    'sinIniciar': sinIniciar,
    'enCurso': enCurso,
    'vencidos': vencidos,
    'porRevisar': porRevisar,
    'calificados': calificados,
    'ausentes': ausentes,
    'inicioVentana': tcpeFechaHoraJson(inicioVentana),
    'finVentana': tcpeFechaHoraJson(finVentana),
    'promedio': promedio,
    'notaAprobacion': notaAprobacion,
    'mostrarRespuestas': mostrarRespuestas,
    'aprobados': aprobados,
    'reprobados': reprobados,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  /// Solo lo que recibe el endpoint de escritura.
  Map<String, dynamic> toGuardarJson() => {
    'codRolExamen': codRolExamen.toInt(),
    'codArea': codArea?.toInt(),
    'codClasificacion': codClasificacion?.toInt(),
    'titulo': titulo,
    'observaciones': observaciones,
    'modalidad': modalidad,
    'duracionMinutos': duracionMinutos,
    'cantidadPreg': cantidadPreg,
    'fecha': tcpeFechaJson(fecha),
    'horaInicio': horaInicio,
    'horaFin': horaFin,
    'ubicacion': ubicacion,
    // Null no viaja: al generar el backend pone 51 y true; al editar, no cambia.
    if (notaAprobacion != null) 'notaAprobacion': notaAprobacion,
    if (mostrarRespuestas != null) 'mostrarRespuestas': mostrarRespuestas,
  };

  TcpeLoteEntity toEntity() => TcpeLoteEntity(
    codRolExamen: codRolExamen,
    titulo: titulo,
    observaciones: observaciones,
    codArea: codArea,
    nombreArea: nombreArea,
    codClasificacion: codClasificacion,
    nombreClasificacion: nombreClasificacion,
    modalidad: modalidad,
    duracionMinutos: duracionMinutos,
    cantidadPreg: cantidadPreg,
    cantExamenGenerar: cantExamenGenerar,
    fecha: fecha,
    horaInicio: horaInicio,
    horaFin: horaFin,
    ubicacion: ubicacion,
    examenes: examenes,
    sinIniciar: sinIniciar,
    enCurso: enCurso,
    vencidos: vencidos,
    porRevisar: porRevisar,
    calificados: calificados,
    ausentes: ausentes,
    inicioVentana: inicioVentana,
    finVentana: finVentana,
    promedio: promedio,
    notaAprobacion: notaAprobacion,
    mostrarRespuestas: mostrarRespuestas,
    aprobados: aprobados,
    reprobados: reprobados,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeLoteModel.fromEntity(TcpeLoteEntity e) => TcpeLoteModel(
    codRolExamen: e.codRolExamen,
    titulo: e.titulo,
    observaciones: e.observaciones,
    codArea: e.codArea,
    nombreArea: e.nombreArea,
    codClasificacion: e.codClasificacion,
    nombreClasificacion: e.nombreClasificacion,
    modalidad: e.modalidad,
    duracionMinutos: e.duracionMinutos,
    cantidadPreg: e.cantidadPreg,
    cantExamenGenerar: e.cantExamenGenerar,
    fecha: e.fecha,
    horaInicio: e.horaInicio,
    horaFin: e.horaFin,
    ubicacion: e.ubicacion,
    examenes: e.examenes,
    sinIniciar: e.sinIniciar,
    enCurso: e.enCurso,
    vencidos: e.vencidos,
    porRevisar: e.porRevisar,
    calificados: e.calificados,
    ausentes: e.ausentes,
    inicioVentana: e.inicioVentana,
    finVentana: e.finVentana,
    promedio: e.promedio,
    notaAprobacion: e.notaAprobacion,
    mostrarRespuestas: e.mostrarRespuestas,
    aprobados: e.aprobados,
    reprobados: e.reprobados,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
