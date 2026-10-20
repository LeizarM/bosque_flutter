import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_registro_examen_entity.dart';

/// `tcpe_registroExamen`: Opción marcada en un examen del sistema anterior.
/// Columnas de `p_list_tcpe_RegistroExamen` (sin `password2`) más `nombreUsuario`.
class TcpeRegistroExamenModel {
  final BigInt codRegExamen;
  final BigInt? codExamen;
  final BigInt? codRsptaOpcion;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeRegistroExamenModel({
    required this.codRegExamen,
    this.codExamen,
    this.codRsptaOpcion,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeRegistroExamenModel.fromJson(Map<String, dynamic> json) => TcpeRegistroExamenModel(
    codRegExamen: tcpeBigInt(json['codRegExamen']) ?? BigInt.zero,
    codExamen: tcpeBigInt(json['codExamen']),
    codRsptaOpcion: tcpeBigInt(json['codRsptaOpcion']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codRegExamen': codRegExamen.toInt(),
    'codExamen': codExamen?.toInt(),
    'codRsptaOpcion': codRsptaOpcion?.toInt(),
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeRegistroExamenEntity toEntity() => TcpeRegistroExamenEntity(
    codRegExamen: codRegExamen,
    codExamen: codExamen,
    codRsptaOpcion: codRsptaOpcion,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeRegistroExamenModel.fromEntity(TcpeRegistroExamenEntity e) => TcpeRegistroExamenModel(
    codRegExamen: e.codRegExamen,
    codExamen: e.codExamen,
    codRsptaOpcion: e.codRsptaOpcion,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
