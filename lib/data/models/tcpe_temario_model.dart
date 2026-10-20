import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_temario_entity.dart';

/// `tcpe_temario`: Temario de un curso (sin uso).
/// Columnas de `p_list_tcpe_Temario` (sin `password2`) más `nombreUsuario`.
class TcpeTemarioModel {
  final BigInt codTemario;
  final BigInt? codCurso;
  final BigInt? codCapacitador;
  final String? nombre;
  final String? descripcion;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeTemarioModel({
    required this.codTemario,
    this.codCurso,
    this.codCapacitador,
    this.nombre,
    this.descripcion,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeTemarioModel.fromJson(Map<String, dynamic> json) => TcpeTemarioModel(
    codTemario: tcpeBigInt(json['codTemario']) ?? BigInt.zero,
    codCurso: tcpeBigInt(json['codCurso']),
    codCapacitador: tcpeBigInt(json['codCapacitador']),
    nombre: tcpeTexto(json['nombre']),
    descripcion: tcpeTexto(json['descripcion']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codTemario': codTemario.toInt(),
    'codCurso': codCurso?.toInt(),
    'codCapacitador': codCapacitador?.toInt(),
    'nombre': nombre,
    'descripcion': descripcion,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeTemarioEntity toEntity() => TcpeTemarioEntity(
    codTemario: codTemario,
    codCurso: codCurso,
    codCapacitador: codCapacitador,
    nombre: nombre,
    descripcion: descripcion,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeTemarioModel.fromEntity(TcpeTemarioEntity e) => TcpeTemarioModel(
    codTemario: e.codTemario,
    codCurso: e.codCurso,
    codCapacitador: e.codCapacitador,
    nombre: e.nombre,
    descripcion: e.descripcion,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
