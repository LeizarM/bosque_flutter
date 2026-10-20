import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_fases_entity.dart';

/// `tcpe_fases`: Fase de una convocatoria (sin uso).
/// Columnas de `p_list_tcpe_Fases` (sin `password2`) más `nombreUsuario`.
class TcpeFasesModel {
  final BigInt codFase;
  final String? nombre;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeFasesModel({
    required this.codFase,
    this.nombre,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeFasesModel.fromJson(Map<String, dynamic> json) => TcpeFasesModel(
    codFase: tcpeBigInt(json['codFase']) ?? BigInt.zero,
    nombre: tcpeTexto(json['nombre']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codFase': codFase.toInt(),
    'nombre': nombre,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeFasesEntity toEntity() => TcpeFasesEntity(
    codFase: codFase,
    nombre: nombre,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeFasesModel.fromEntity(TcpeFasesEntity e) => TcpeFasesModel(
    codFase: e.codFase,
    nombre: e.nombre,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
