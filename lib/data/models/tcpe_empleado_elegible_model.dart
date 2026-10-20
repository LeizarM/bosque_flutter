import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_empleado_elegible_entity.dart';

/// Fila de `/examenes/lotes/empleados` (`p_list_tcpe_Lote` E).
class TcpeEmpleadoElegibleModel {
  final BigInt codEmpleado;
  final String? nombreCompleto;
  final String? ci;
  final String? cargo;
  final bool puedeRendir;
  final String? motivo;

  const TcpeEmpleadoElegibleModel({
    required this.codEmpleado,
    this.nombreCompleto,
    this.ci,
    this.cargo,
    this.puedeRendir = true,
    this.motivo,
  });

  factory TcpeEmpleadoElegibleModel.fromJson(Map<String, dynamic> json) => TcpeEmpleadoElegibleModel(
    codEmpleado: tcpeBigInt(json['codEmpleado']) ?? BigInt.zero,
    nombreCompleto: tcpeTexto(json['nombreCompleto']),
    ci: tcpeTexto(json['ci']),
    cargo: tcpeTexto(json['cargo']),
    puedeRendir: tcpeBool(json['puedeRendir']) ?? true,
    motivo: tcpeTexto(json['motivo']),
  );

  Map<String, dynamic> toJson() => {
    'codEmpleado': codEmpleado.toInt(),
    'nombreCompleto': nombreCompleto,
    'ci': ci,
    'cargo': cargo,
    'puedeRendir': puedeRendir,
    'motivo': motivo,
  };

  TcpeEmpleadoElegibleEntity toEntity() => TcpeEmpleadoElegibleEntity(
    codEmpleado: codEmpleado,
    nombreCompleto: nombreCompleto,
    ci: ci,
    cargo: cargo,
    puedeRendir: puedeRendir,
    motivo: motivo,
  );

  factory TcpeEmpleadoElegibleModel.fromEntity(TcpeEmpleadoElegibleEntity e) => TcpeEmpleadoElegibleModel(
    codEmpleado: e.codEmpleado,
    nombreCompleto: e.nombreCompleto,
    ci: e.ci,
    cargo: e.cargo,
    puedeRendir: e.puedeRendir,
    motivo: e.motivo,
  );
}
