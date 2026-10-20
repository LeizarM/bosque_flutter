import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_capacitacion_entity.dart';

/// `tcpe_capacitacion`: Capacitación (módulo de capacitaciones, hoy sin uso).
/// Columnas de `p_list_tcpe_Capacitacion` (sin `password2`) más `nombreUsuario`.
class TcpeCapacitacionModel {
  final BigInt codCapacitacion;
  final bool? esInterna;
  final String? titulo;
  final String? descripcion;
  final String? objetivo;
  final String? telfReferencia;
  final String? destinatarios;
  final DateTime? proFechaInicio;
  final DateTime? proFechaFin;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeCapacitacionModel({
    required this.codCapacitacion,
    this.esInterna,
    this.titulo,
    this.descripcion,
    this.objetivo,
    this.telfReferencia,
    this.destinatarios,
    this.proFechaInicio,
    this.proFechaFin,
    this.fechaInicio,
    this.fechaFin,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeCapacitacionModel.fromJson(Map<String, dynamic> json) => TcpeCapacitacionModel(
    codCapacitacion: tcpeBigInt(json['codCapacitacion']) ?? BigInt.zero,
    esInterna: tcpeBool(json['esInterna']),
    titulo: tcpeTexto(json['titulo']),
    descripcion: tcpeTexto(json['descripcion']),
    objetivo: tcpeTexto(json['objetivo']),
    telfReferencia: tcpeTexto(json['telfReferencia']),
    destinatarios: tcpeTexto(json['destinatarios']),
    proFechaInicio: tcpeFecha(json['proFechaInicio']),
    proFechaFin: tcpeFecha(json['proFechaFin']),
    fechaInicio: tcpeFecha(json['fechaInicio']),
    fechaFin: tcpeFecha(json['fechaFin']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codCapacitacion': codCapacitacion.toInt(),
    'esInterna': esInterna,
    'titulo': titulo,
    'descripcion': descripcion,
    'objetivo': objetivo,
    'telfReferencia': telfReferencia,
    'destinatarios': destinatarios,
    'proFechaInicio': tcpeFechaJson(proFechaInicio),
    'proFechaFin': tcpeFechaJson(proFechaFin),
    'fechaInicio': tcpeFechaJson(fechaInicio),
    'fechaFin': tcpeFechaJson(fechaFin),
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeCapacitacionEntity toEntity() => TcpeCapacitacionEntity(
    codCapacitacion: codCapacitacion,
    esInterna: esInterna,
    titulo: titulo,
    descripcion: descripcion,
    objetivo: objetivo,
    telfReferencia: telfReferencia,
    destinatarios: destinatarios,
    proFechaInicio: proFechaInicio,
    proFechaFin: proFechaFin,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeCapacitacionModel.fromEntity(TcpeCapacitacionEntity e) => TcpeCapacitacionModel(
    codCapacitacion: e.codCapacitacion,
    esInterna: e.esInterna,
    titulo: e.titulo,
    descripcion: e.descripcion,
    objetivo: e.objetivo,
    telfReferencia: e.telfReferencia,
    destinatarios: e.destinatarios,
    proFechaInicio: e.proFechaInicio,
    proFechaFin: e.proFechaFin,
    fechaInicio: e.fechaInicio,
    fechaFin: e.fechaFin,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
