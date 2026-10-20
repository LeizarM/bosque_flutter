import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_inscripcion_entity.dart';

/// `tcpe_inscripcion`: Inscripción a una capacitación (sin uso).
/// Columnas de `p_list_tcpe_Inscripcion` (sin `password2`) más `nombreUsuario`.
class TcpeInscripcionModel {
  final BigInt codInscripcion;
  final BigInt? codCapacitacion;
  final BigInt? codUsuario;
  final String? observaciones;
  final DateTime? fechaInscrip;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeInscripcionModel({
    required this.codInscripcion,
    this.codCapacitacion,
    this.codUsuario,
    this.observaciones,
    this.fechaInscrip,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeInscripcionModel.fromJson(Map<String, dynamic> json) => TcpeInscripcionModel(
    codInscripcion: tcpeBigInt(json['codInscripcion']) ?? BigInt.zero,
    codCapacitacion: tcpeBigInt(json['codCapacitacion']),
    codUsuario: tcpeBigInt(json['codUsuario']),
    observaciones: tcpeTexto(json['observaciones']),
    fechaInscrip: tcpeFecha(json['fechaInscrip']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codInscripcion': codInscripcion.toInt(),
    'codCapacitacion': codCapacitacion?.toInt(),
    'codUsuario': codUsuario?.toInt(),
    'observaciones': observaciones,
    'fechaInscrip': tcpeFechaJson(fechaInscrip),
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeInscripcionEntity toEntity() => TcpeInscripcionEntity(
    codInscripcion: codInscripcion,
    codCapacitacion: codCapacitacion,
    codUsuario: codUsuario,
    observaciones: observaciones,
    fechaInscrip: fechaInscrip,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeInscripcionModel.fromEntity(TcpeInscripcionEntity e) => TcpeInscripcionModel(
    codInscripcion: e.codInscripcion,
    codCapacitacion: e.codCapacitacion,
    codUsuario: e.codUsuario,
    observaciones: e.observaciones,
    fechaInscrip: e.fechaInscrip,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
