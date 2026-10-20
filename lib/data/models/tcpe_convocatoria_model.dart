import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_convocatoria_entity.dart';

/// `tcpe_convocatoria`: Convocatoria a un puesto (sin uso).
/// Columnas de `p_list_tcpe_Convocatoria` (sin `password2`) más `nombreUsuario`.
class TcpeConvocatoriaModel {
  final BigInt codConvocatoria;
  final BigInt? codArea;
  final BigInt? codDpto;
  final DateTime? gestion;
  final bool? esInterna;
  final String? titulo;
  final String? observacion;
  final String? descripcion;
  final String? nombrePuesto;
  final String? competencias;
  final String? objCargo;
  final String? funciones;
  final String? estado;
  final DateTime? proFechaInicio;
  final DateTime? proFechaFin;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeConvocatoriaModel({
    required this.codConvocatoria,
    this.codArea,
    this.codDpto,
    this.gestion,
    this.esInterna,
    this.titulo,
    this.observacion,
    this.descripcion,
    this.nombrePuesto,
    this.competencias,
    this.objCargo,
    this.funciones,
    this.estado,
    this.proFechaInicio,
    this.proFechaFin,
    this.fechaInicio,
    this.fechaFin,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeConvocatoriaModel.fromJson(Map<String, dynamic> json) => TcpeConvocatoriaModel(
    codConvocatoria: tcpeBigInt(json['codConvocatoria']) ?? BigInt.zero,
    codArea: tcpeBigInt(json['codArea']),
    codDpto: tcpeBigInt(json['codDpto']),
    gestion: tcpeFecha(json['gestion']),
    esInterna: tcpeBool(json['esInterna']),
    titulo: tcpeTexto(json['titulo']),
    observacion: tcpeTexto(json['observacion']),
    descripcion: tcpeTexto(json['descripcion']),
    nombrePuesto: tcpeTexto(json['nombrePuesto']),
    competencias: tcpeTexto(json['competencias']),
    objCargo: tcpeTexto(json['objCargo']),
    funciones: tcpeTexto(json['funciones']),
    estado: tcpeTexto(json['estado']),
    proFechaInicio: tcpeFecha(json['proFechaInicio']),
    proFechaFin: tcpeFecha(json['proFechaFin']),
    fechaInicio: tcpeFecha(json['fechaInicio']),
    fechaFin: tcpeFecha(json['fechaFin']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codConvocatoria': codConvocatoria.toInt(),
    'codArea': codArea?.toInt(),
    'codDpto': codDpto?.toInt(),
    'gestion': tcpeFechaJson(gestion),
    'esInterna': esInterna,
    'titulo': titulo,
    'observacion': observacion,
    'descripcion': descripcion,
    'nombrePuesto': nombrePuesto,
    'competencias': competencias,
    'objCargo': objCargo,
    'funciones': funciones,
    'estado': estado,
    'proFechaInicio': tcpeFechaJson(proFechaInicio),
    'proFechaFin': tcpeFechaJson(proFechaFin),
    'fechaInicio': tcpeFechaJson(fechaInicio),
    'fechaFin': tcpeFechaJson(fechaFin),
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeConvocatoriaEntity toEntity() => TcpeConvocatoriaEntity(
    codConvocatoria: codConvocatoria,
    codArea: codArea,
    codDpto: codDpto,
    gestion: gestion,
    esInterna: esInterna,
    titulo: titulo,
    observacion: observacion,
    descripcion: descripcion,
    nombrePuesto: nombrePuesto,
    competencias: competencias,
    objCargo: objCargo,
    funciones: funciones,
    estado: estado,
    proFechaInicio: proFechaInicio,
    proFechaFin: proFechaFin,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeConvocatoriaModel.fromEntity(TcpeConvocatoriaEntity e) => TcpeConvocatoriaModel(
    codConvocatoria: e.codConvocatoria,
    codArea: e.codArea,
    codDpto: e.codDpto,
    gestion: e.gestion,
    esInterna: e.esInterna,
    titulo: e.titulo,
    observacion: e.observacion,
    descripcion: e.descripcion,
    nombrePuesto: e.nombrePuesto,
    competencias: e.competencias,
    objCargo: e.objCargo,
    funciones: e.funciones,
    estado: e.estado,
    proFechaInicio: e.proFechaInicio,
    proFechaFin: e.proFechaFin,
    fechaInicio: e.fechaInicio,
    fechaFin: e.fechaFin,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
