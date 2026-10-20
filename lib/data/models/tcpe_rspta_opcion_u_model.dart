import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_rspta_opcion_u_entity.dart';

/// `tcpe_rsptaOpcionU`: Opción que marcó el usuario al rendir.
/// Columnas de `p_list_tcpe_RsptaOpcionU` (sin `password2`) más `nombreUsuario`.
class TcpeRsptaOpcionUModel {
  final BigInt codRsptaOpU;
  final BigInt? codRsptaOpH;
  final BigInt? codExamen;
  final BigInt? codRespuesta;
  final BigInt? codRsptaOp;
  final String? opcionRspta;
  final bool esValido;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeRsptaOpcionUModel({
    required this.codRsptaOpU,
    this.codRsptaOpH,
    this.codExamen,
    this.codRespuesta,
    this.codRsptaOp,
    this.opcionRspta,
    this.esValido = false,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeRsptaOpcionUModel.fromJson(Map<String, dynamic> json) => TcpeRsptaOpcionUModel(
    codRsptaOpU: tcpeBigInt(json['codRsptaOpU']) ?? BigInt.zero,
    codRsptaOpH: tcpeBigInt(json['codRsptaOpH']),
    codExamen: tcpeBigInt(json['codExamen']),
    codRespuesta: tcpeBigInt(json['codRespuesta']),
    codRsptaOp: tcpeBigInt(json['codRsptaOp']),
    opcionRspta: tcpeTexto(json['opcionRspta']),
    esValido: tcpeBool(json['esValido']) ?? false,
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codRsptaOpU': codRsptaOpU.toInt(),
    'codRsptaOpH': codRsptaOpH?.toInt(),
    'codExamen': codExamen?.toInt(),
    'codRespuesta': codRespuesta?.toInt(),
    'codRsptaOp': codRsptaOp?.toInt(),
    'opcionRspta': opcionRspta,
    'esValido': esValido,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeRsptaOpcionUEntity toEntity() => TcpeRsptaOpcionUEntity(
    codRsptaOpU: codRsptaOpU,
    codRsptaOpH: codRsptaOpH,
    codExamen: codExamen,
    codRespuesta: codRespuesta,
    codRsptaOp: codRsptaOp,
    opcionRspta: opcionRspta,
    esValido: esValido,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeRsptaOpcionUModel.fromEntity(TcpeRsptaOpcionUEntity e) => TcpeRsptaOpcionUModel(
    codRsptaOpU: e.codRsptaOpU,
    codRsptaOpH: e.codRsptaOpH,
    codExamen: e.codExamen,
    codRespuesta: e.codRespuesta,
    codRsptaOp: e.codRsptaOp,
    opcionRspta: e.opcionRspta,
    esValido: e.esValido,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
