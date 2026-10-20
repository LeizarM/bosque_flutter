import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_informe_categoria_entity.dart';

/// Resumen de un lote para el informe por categoría y fechas (`p_list_tcpe_Resultado` C).
class TcpeInformeCategoriaModel {
  final BigInt codRolExamen;
  final String? titulo;
  final String? nombreArea;
  final String? nombreClasificacion;
  final String? modalidad;
  final DateTime? fecha;
  final int examenes;
  final int rendidos;
  final int calificados;
  final double? promedio;
  final int aprobados;
  final int reprobados;
  final double? notaAprobacion;
  final int ausentes;

  const TcpeInformeCategoriaModel({
    required this.codRolExamen,
    this.titulo,
    this.nombreArea,
    this.nombreClasificacion,
    this.modalidad,
    this.fecha,
    this.examenes = 0,
    this.rendidos = 0,
    this.calificados = 0,
    this.promedio,
    this.aprobados = 0,
    this.reprobados = 0,
    this.notaAprobacion,
    this.ausentes = 0,
  });

  factory TcpeInformeCategoriaModel.fromJson(Map<String, dynamic> json) => TcpeInformeCategoriaModel(
    codRolExamen: tcpeBigInt(json['codRolExamen']) ?? BigInt.zero,
    titulo: tcpeTexto(json['titulo']),
    nombreArea: tcpeTexto(json['nombreArea']),
    nombreClasificacion: tcpeTexto(json['nombreClasificacion']),
    modalidad: tcpeTexto(json['modalidad']),
    fecha: tcpeFecha(json['fecha']),
    examenes: tcpeInt(json['examenes']) ?? 0,
    rendidos: tcpeInt(json['rendidos']) ?? 0,
    calificados: tcpeInt(json['calificados']) ?? 0,
    promedio: tcpeDouble(json['promedio']),
    aprobados: tcpeInt(json['aprobados']) ?? 0,
    reprobados: tcpeInt(json['reprobados']) ?? 0,
    notaAprobacion: tcpeDouble(json['notaAprobacion']),
    ausentes: tcpeInt(json['ausentes']) ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'codRolExamen': codRolExamen.toInt(),
    'titulo': titulo,
    'nombreArea': nombreArea,
    'nombreClasificacion': nombreClasificacion,
    'modalidad': modalidad,
    'fecha': tcpeFechaJson(fecha),
    'examenes': examenes,
    'rendidos': rendidos,
    'calificados': calificados,
    'promedio': promedio,
    'aprobados': aprobados,
    'reprobados': reprobados,
    'notaAprobacion': notaAprobacion,
    'ausentes': ausentes,
  };

  TcpeInformeCategoriaEntity toEntity() => TcpeInformeCategoriaEntity(
    codRolExamen: codRolExamen,
    titulo: titulo,
    nombreArea: nombreArea,
    nombreClasificacion: nombreClasificacion,
    modalidad: modalidad,
    fecha: fecha,
    examenes: examenes,
    rendidos: rendidos,
    calificados: calificados,
    promedio: promedio,
    aprobados: aprobados,
    reprobados: reprobados,
    notaAprobacion: notaAprobacion,
    ausentes: ausentes,
  );

  factory TcpeInformeCategoriaModel.fromEntity(TcpeInformeCategoriaEntity e) => TcpeInformeCategoriaModel(
    codRolExamen: e.codRolExamen,
    titulo: e.titulo,
    nombreArea: e.nombreArea,
    nombreClasificacion: e.nombreClasificacion,
    modalidad: e.modalidad,
    fecha: e.fecha,
    examenes: e.examenes,
    rendidos: e.rendidos,
    calificados: e.calificados,
    promedio: e.promedio,
    aprobados: e.aprobados,
    reprobados: e.reprobados,
    notaAprobacion: e.notaAprobacion,
    ausentes: e.ausentes,
  );
}
