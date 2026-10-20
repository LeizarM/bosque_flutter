import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_rspta_opcion_entity.dart';

/// `tcpe_rsptaOpcion`: Opción de una pregunta cerrada del banco.
/// Columnas de `p_list_tcpe_RsptaOpcion` (sin `password2`) más `nombreUsuario`.
class TcpeRsptaOpcionModel {
  final BigInt codRsptaOp;
  final BigInt? codRespuesta;
  final String? opcionRspta;
  final bool esValido;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeRsptaOpcionModel({
    required this.codRsptaOp,
    this.codRespuesta,
    this.opcionRspta,
    this.esValido = false,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeRsptaOpcionModel.fromJson(Map<String, dynamic> json) => TcpeRsptaOpcionModel(
    codRsptaOp: tcpeBigInt(json['codRsptaOp']) ?? BigInt.zero,
    codRespuesta: tcpeBigInt(json['codRespuesta']),
    opcionRspta: tcpeTexto(json['opcionRspta']),
    esValido: tcpeBool(json['esValido']) ?? false,
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codRsptaOp': codRsptaOp.toInt(),
    'codRespuesta': codRespuesta?.toInt(),
    'opcionRspta': opcionRspta,
    'esValido': esValido,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeRsptaOpcionEntity toEntity() => TcpeRsptaOpcionEntity(
    codRsptaOp: codRsptaOp,
    codRespuesta: codRespuesta,
    opcionRspta: opcionRspta,
    esValido: esValido,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeRsptaOpcionModel.fromEntity(TcpeRsptaOpcionEntity e) => TcpeRsptaOpcionModel(
    codRsptaOp: e.codRsptaOp,
    codRespuesta: e.codRespuesta,
    opcionRspta: e.opcionRspta,
    esValido: e.esValido,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
