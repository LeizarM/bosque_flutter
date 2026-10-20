import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_monitor_lote_entity.dart';

/// Un lote para monitorear: con exámenes en curso o la ventana abierta (`p_list_tcpe_Monitor` D).
class TcpeMonitorLoteModel {
  final BigInt codRolExamen;
  final String? titulo;
  final String? nombreClasificacion;
  final String? modalidad;
  final DateTime? inicioVentana;
  final DateTime? finVentana;
  final int examenes;
  final int sinIniciar;
  final int enCurso;
  final int entregados;

  const TcpeMonitorLoteModel({
    required this.codRolExamen,
    this.titulo,
    this.nombreClasificacion,
    this.modalidad,
    this.inicioVentana,
    this.finVentana,
    this.examenes = 0,
    this.sinIniciar = 0,
    this.enCurso = 0,
    this.entregados = 0,
  });

  factory TcpeMonitorLoteModel.fromJson(Map<String, dynamic> json) => TcpeMonitorLoteModel(
    codRolExamen: tcpeBigInt(json['codRolExamen']) ?? BigInt.zero,
    titulo: tcpeTexto(json['titulo']),
    nombreClasificacion: tcpeTexto(json['nombreClasificacion']),
    modalidad: tcpeTexto(json['modalidad']),
    inicioVentana: tcpeFecha(json['inicioVentana']),
    finVentana: tcpeFecha(json['finVentana']),
    examenes: tcpeInt(json['examenes']) ?? 0,
    sinIniciar: tcpeInt(json['sinIniciar']) ?? 0,
    enCurso: tcpeInt(json['enCurso']) ?? 0,
    entregados: tcpeInt(json['entregados']) ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'codRolExamen': codRolExamen.toInt(),
    'titulo': titulo,
    'nombreClasificacion': nombreClasificacion,
    'modalidad': modalidad,
    'inicioVentana': tcpeFechaHoraJson(inicioVentana),
    'finVentana': tcpeFechaHoraJson(finVentana),
    'examenes': examenes,
    'sinIniciar': sinIniciar,
    'enCurso': enCurso,
    'entregados': entregados,
  };

  TcpeMonitorLoteEntity toEntity() => TcpeMonitorLoteEntity(
    codRolExamen: codRolExamen,
    titulo: titulo,
    nombreClasificacion: nombreClasificacion,
    modalidad: modalidad,
    inicioVentana: inicioVentana,
    finVentana: finVentana,
    examenes: examenes,
    sinIniciar: sinIniciar,
    enCurso: enCurso,
    entregados: entregados,
  );

  factory TcpeMonitorLoteModel.fromEntity(TcpeMonitorLoteEntity e) => TcpeMonitorLoteModel(
    codRolExamen: e.codRolExamen,
    titulo: e.titulo,
    nombreClasificacion: e.nombreClasificacion,
    modalidad: e.modalidad,
    inicioVentana: e.inicioVentana,
    finVentana: e.finVentana,
    examenes: e.examenes,
    sinIniciar: e.sinIniciar,
    enCurso: e.enCurso,
    entregados: e.entregados,
  );
}
