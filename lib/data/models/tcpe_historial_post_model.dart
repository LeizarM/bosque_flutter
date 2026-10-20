import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_historial_post_entity.dart';

/// `tcpe_historialPost`: Historial de fases de una postulación (sin uso).
/// Columnas de `p_list_tcpe_HistorialPost` (sin `password2`) más `nombreUsuario`.
class TcpeHistorialPostModel {
  final BigInt codHistorialPost;
  final BigInt? codFase;
  final BigInt? codPostulacion;
  final DateTime? fechaHistorial;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeHistorialPostModel({
    required this.codHistorialPost,
    this.codFase,
    this.codPostulacion,
    this.fechaHistorial,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeHistorialPostModel.fromJson(Map<String, dynamic> json) => TcpeHistorialPostModel(
    codHistorialPost: tcpeBigInt(json['codHistorialPost']) ?? BigInt.zero,
    codFase: tcpeBigInt(json['codFase']),
    codPostulacion: tcpeBigInt(json['codPostulacion']),
    fechaHistorial: tcpeFecha(json['fechaHistorial']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codHistorialPost': codHistorialPost.toInt(),
    'codFase': codFase?.toInt(),
    'codPostulacion': codPostulacion?.toInt(),
    'fechaHistorial': tcpeFechaJson(fechaHistorial),
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeHistorialPostEntity toEntity() => TcpeHistorialPostEntity(
    codHistorialPost: codHistorialPost,
    codFase: codFase,
    codPostulacion: codPostulacion,
    fechaHistorial: fechaHistorial,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeHistorialPostModel.fromEntity(TcpeHistorialPostEntity e) => TcpeHistorialPostModel(
    codHistorialPost: e.codHistorialPost,
    codFase: e.codFase,
    codPostulacion: e.codPostulacion,
    fechaHistorial: e.fechaHistorial,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
