import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_area_post_entity.dart';

/// `tcpe_areaPost`: Área de una postulación (módulo de convocatorias, hoy sin uso).
/// Columnas de `p_list_tcpe_AreaPost` (sin `password2`) más `nombreUsuario`.
class TcpeAreaPostModel {
  final BigInt codAreaPost;
  final String? nombArea;
  final BigInt? codTipo;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeAreaPostModel({
    required this.codAreaPost,
    this.nombArea,
    this.codTipo,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeAreaPostModel.fromJson(Map<String, dynamic> json) => TcpeAreaPostModel(
    codAreaPost: tcpeBigInt(json['codAreaPost']) ?? BigInt.zero,
    nombArea: tcpeTexto(json['nombArea']),
    codTipo: tcpeBigInt(json['codTipo']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codAreaPost': codAreaPost.toInt(),
    'nombArea': nombArea,
    'codTipo': codTipo?.toInt(),
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeAreaPostEntity toEntity() => TcpeAreaPostEntity(
    codAreaPost: codAreaPost,
    nombArea: nombArea,
    codTipo: codTipo,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeAreaPostModel.fromEntity(TcpeAreaPostEntity e) => TcpeAreaPostModel(
    codAreaPost: e.codAreaPost,
    nombArea: e.nombArea,
    codTipo: e.codTipo,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
