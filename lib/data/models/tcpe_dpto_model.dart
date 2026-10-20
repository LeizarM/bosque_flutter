import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_dpto_entity.dart';

/// `tcpe_dpto`: Departamento (sin uso).
/// Columnas de `p_list_tcpe_Dpto` (sin `password2`) más `nombreUsuario`.
class TcpeDptoModel {
  final BigInt codDpto;
  final String? departamento;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeDptoModel({
    required this.codDpto,
    this.departamento,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeDptoModel.fromJson(Map<String, dynamic> json) => TcpeDptoModel(
    codDpto: tcpeBigInt(json['codDpto']) ?? BigInt.zero,
    departamento: tcpeTexto(json['departamento']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codDpto': codDpto.toInt(),
    'departamento': departamento,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeDptoEntity toEntity() => TcpeDptoEntity(
    codDpto: codDpto,
    departamento: departamento,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeDptoModel.fromEntity(TcpeDptoEntity e) => TcpeDptoModel(
    codDpto: e.codDpto,
    departamento: e.departamento,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
