import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/data/models/tcpe_persona_examen_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pedido_examenes_entity.dart';

/// Parte del body de `/examenes/lotes/generar` y `/agregar` (lote mixto):
/// `{cantidad, personas, codEmpleados}`, solo las claves con valor. La clave
/// de los externos siempre la sortea el backend.
class TcpePedidoExamenesModel {
  final int cantidad;
  final List<TcpePersonaExamenModel> personas;
  final List<BigInt> codEmpleados;

  const TcpePedidoExamenesModel({this.cantidad = 0, this.personas = const [], this.codEmpleados = const []});

  factory TcpePedidoExamenesModel.fromJson(Map<String, dynamic> json) => TcpePedidoExamenesModel(
    cantidad: tcpeInt(json['cantidad']) ?? 0,
    personas: [
      for (final p in (json['personas'] as List<dynamic>? ?? const []))
        if (p is Map) TcpePersonaExamenModel.fromJson(Map<String, dynamic>.from(p)),
    ],
    codEmpleados: [
      for (final c in (json['codEmpleados'] as List<dynamic>? ?? const []))
        if (tcpeBigInt(c) != null) tcpeBigInt(c)!,
    ],
  );

  /// Solo los modos con valor: el SP (Lote V) decide si el total corresponde.
  Map<String, dynamic> toJson() => {
    if (cantidad > 0) 'cantidad': cantidad,
    if (personas.isNotEmpty) 'personas': [for (final p in personas) p.toJson()],
    if (codEmpleados.isNotEmpty) 'codEmpleados': [for (final c in codEmpleados) c.toInt()],
  };

  TcpePedidoExamenesEntity toEntity() => TcpePedidoExamenesEntity(
    cantidad: cantidad,
    personas: [for (final p in personas) p.toEntity()],
    codEmpleados: codEmpleados,
  );

  factory TcpePedidoExamenesModel.fromEntity(TcpePedidoExamenesEntity e) => TcpePedidoExamenesModel(
    cantidad: e.cantidad,
    personas: [for (final p in e.personas) TcpePersonaExamenModel.fromEntity(p)],
    codEmpleados: e.codEmpleados,
  );
}
