import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_capacitador_entity.dart';

/// `tcpe_capacitador`: Capacitador (módulo de capacitaciones, hoy sin uso).
/// Columnas de `p_list_tcpe_Capacitador` (sin `password2`) más `nombreUsuario`.
class TcpeCapacitadorModel {
  final BigInt codCapacitador;
  final int? sexo;
  final String? telefonos;
  final String? ci;
  final String? nombre;
  final String? apPaterno;
  final String? apMaterno;
  final String? direccion;
  final String? email;
  final String? pais;
  final DateTime? fechaNacimiento;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeCapacitadorModel({
    required this.codCapacitador,
    this.sexo,
    this.telefonos,
    this.ci,
    this.nombre,
    this.apPaterno,
    this.apMaterno,
    this.direccion,
    this.email,
    this.pais,
    this.fechaNacimiento,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeCapacitadorModel.fromJson(Map<String, dynamic> json) => TcpeCapacitadorModel(
    codCapacitador: tcpeBigInt(json['codCapacitador']) ?? BigInt.zero,
    sexo: tcpeInt(json['sexo']),
    telefonos: tcpeTexto(json['telefonos']),
    ci: tcpeTexto(json['ci']),
    nombre: tcpeTexto(json['nombre']),
    apPaterno: tcpeTexto(json['apPaterno']),
    apMaterno: tcpeTexto(json['apMaterno']),
    direccion: tcpeTexto(json['direccion']),
    email: tcpeTexto(json['email']),
    pais: tcpeTexto(json['pais']),
    fechaNacimiento: tcpeFecha(json['fechaNacimiento']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codCapacitador': codCapacitador.toInt(),
    'sexo': sexo,
    'telefonos': telefonos,
    'ci': ci,
    'nombre': nombre,
    'apPaterno': apPaterno,
    'apMaterno': apMaterno,
    'direccion': direccion,
    'email': email,
    'pais': pais,
    'fechaNacimiento': tcpeFechaJson(fechaNacimiento),
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeCapacitadorEntity toEntity() => TcpeCapacitadorEntity(
    codCapacitador: codCapacitador,
    sexo: sexo,
    telefonos: telefonos,
    ci: ci,
    nombre: nombre,
    apPaterno: apPaterno,
    apMaterno: apMaterno,
    direccion: direccion,
    email: email,
    pais: pais,
    fechaNacimiento: fechaNacimiento,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeCapacitadorModel.fromEntity(TcpeCapacitadorEntity e) => TcpeCapacitadorModel(
    codCapacitador: e.codCapacitador,
    sexo: e.sexo,
    telefonos: e.telefonos,
    ci: e.ci,
    nombre: e.nombre,
    apPaterno: e.apPaterno,
    apMaterno: e.apMaterno,
    direccion: e.direccion,
    email: e.email,
    pais: e.pais,
    fechaNacimiento: e.fechaNacimiento,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
