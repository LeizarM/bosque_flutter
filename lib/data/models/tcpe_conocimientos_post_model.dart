import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_conocimientos_post_entity.dart';

/// `tcpe_conocimientosPost`: Catálogo de conocimientos de un postulante (sin uso).
/// Columnas de `p_list_tcpe_ConocimientosPost` (sin `password2`) más `nombreUsuario`.
/// `codConocimiento` no es IDENTITY: en 0 el SP toma el siguiente número.
class TcpeConocimientosPostModel {
  final BigInt codConocimiento;
  final String? nombreConocimiento;
  final bool? esVigente;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeConocimientosPostModel({
    required this.codConocimiento,
    this.nombreConocimiento,
    this.esVigente,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeConocimientosPostModel.fromJson(Map<String, dynamic> json) => TcpeConocimientosPostModel(
    codConocimiento: tcpeBigInt(json['codConocimiento']) ?? BigInt.zero,
    nombreConocimiento: tcpeTexto(json['nombreConocimiento']),
    esVigente: tcpeBool(json['esVigente']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codConocimiento': codConocimiento.toInt(),
    'nombreConocimiento': nombreConocimiento,
    'esVigente': esVigente,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeConocimientosPostEntity toEntity() => TcpeConocimientosPostEntity(
    codConocimiento: codConocimiento,
    nombreConocimiento: nombreConocimiento,
    esVigente: esVigente,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeConocimientosPostModel.fromEntity(TcpeConocimientosPostEntity e) => TcpeConocimientosPostModel(
    codConocimiento: e.codConocimiento,
    nombreConocimiento: e.nombreConocimiento,
    esVigente: e.esVigente,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
