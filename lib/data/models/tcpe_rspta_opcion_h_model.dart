import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_rspta_opcion_h_entity.dart';

/// `tcpe_rsptaOpcionH`: Foto de una opción en un examen generado.
/// Columnas de `p_list_tcpe_RsptaOpcionH` (sin `password2`) más `nombreUsuario`.
class TcpeRsptaOpcionHModel {
  final BigInt codRsptaOpH;
  final BigInt? codRespuestaH;
  final BigInt? codRespuesta;
  final BigInt? codRsptaOp;
  final String? opcionRspta;
  final bool esValido;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeRsptaOpcionHModel({
    required this.codRsptaOpH,
    this.codRespuestaH,
    this.codRespuesta,
    this.codRsptaOp,
    this.opcionRspta,
    this.esValido = false,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeRsptaOpcionHModel.fromJson(Map<String, dynamic> json) => TcpeRsptaOpcionHModel(
    codRsptaOpH: tcpeBigInt(json['codRsptaOpH']) ?? BigInt.zero,
    codRespuestaH: tcpeBigInt(json['codRespuestaH']),
    codRespuesta: tcpeBigInt(json['codRespuesta']),
    codRsptaOp: tcpeBigInt(json['codRsptaOp']),
    opcionRspta: tcpeTexto(json['opcionRspta']),
    esValido: tcpeBool(json['esValido']) ?? false,
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codRsptaOpH': codRsptaOpH.toInt(),
    'codRespuestaH': codRespuestaH?.toInt(),
    'codRespuesta': codRespuesta?.toInt(),
    'codRsptaOp': codRsptaOp?.toInt(),
    'opcionRspta': opcionRspta,
    'esValido': esValido,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeRsptaOpcionHEntity toEntity() => TcpeRsptaOpcionHEntity(
    codRsptaOpH: codRsptaOpH,
    codRespuestaH: codRespuestaH,
    codRespuesta: codRespuesta,
    codRsptaOp: codRsptaOp,
    opcionRspta: opcionRspta,
    esValido: esValido,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeRsptaOpcionHModel.fromEntity(TcpeRsptaOpcionHEntity e) => TcpeRsptaOpcionHModel(
    codRsptaOpH: e.codRsptaOpH,
    codRespuestaH: e.codRespuestaH,
    codRespuesta: e.codRespuesta,
    codRsptaOp: e.codRsptaOp,
    opcionRspta: e.opcionRspta,
    esValido: e.esValido,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
