import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_curso_entity.dart';

/// `tcpe_curso`: Curso de una capacitación (sin uso).
/// Columnas de `p_list_tcpe_Curso` (sin `password2`) más `nombreUsuario`.
class TcpeCursoModel {
  final BigInt codCurso;
  final BigInt? codCapacitacion;
  final double? inversion;
  final String? titulo;
  final String? descripcion;
  final String? lugar;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeCursoModel({
    required this.codCurso,
    this.codCapacitacion,
    this.inversion,
    this.titulo,
    this.descripcion,
    this.lugar,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeCursoModel.fromJson(Map<String, dynamic> json) => TcpeCursoModel(
    codCurso: tcpeBigInt(json['codCurso']) ?? BigInt.zero,
    codCapacitacion: tcpeBigInt(json['codCapacitacion']),
    inversion: tcpeDouble(json['inversion']),
    titulo: tcpeTexto(json['titulo']),
    descripcion: tcpeTexto(json['descripcion']),
    lugar: tcpeTexto(json['lugar']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codCurso': codCurso.toInt(),
    'codCapacitacion': codCapacitacion?.toInt(),
    'inversion': inversion,
    'titulo': titulo,
    'descripcion': descripcion,
    'lugar': lugar,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeCursoEntity toEntity() => TcpeCursoEntity(
    codCurso: codCurso,
    codCapacitacion: codCapacitacion,
    inversion: inversion,
    titulo: titulo,
    descripcion: descripcion,
    lugar: lugar,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeCursoModel.fromEntity(TcpeCursoEntity e) => TcpeCursoModel(
    codCurso: e.codCurso,
    codCapacitacion: e.codCapacitacion,
    inversion: e.inversion,
    titulo: e.titulo,
    descripcion: e.descripcion,
    lugar: e.lugar,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
