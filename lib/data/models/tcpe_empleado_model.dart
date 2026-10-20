import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_empleado_entity.dart';

/// `tcpe_empleado`: Empleado habilitado en el módulo (el PK es el de tb_empleado).
/// Columnas de `p_list_tcpe_Empleado` (sin `password2`) más `nombreUsuario`.
/// `codEmpleado` no es IDENTITY: en 0 el SP toma el siguiente número.
class TcpeEmpleadoModel {
  final BigInt codEmpleado;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeEmpleadoModel({
    required this.codEmpleado,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeEmpleadoModel.fromJson(Map<String, dynamic> json) => TcpeEmpleadoModel(
    codEmpleado: tcpeBigInt(json['codEmpleado']) ?? BigInt.zero,
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codEmpleado': codEmpleado.toInt(),
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeEmpleadoEntity toEntity() => TcpeEmpleadoEntity(
    codEmpleado: codEmpleado,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeEmpleadoModel.fromEntity(TcpeEmpleadoEntity e) => TcpeEmpleadoModel(
    codEmpleado: e.codEmpleado,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
