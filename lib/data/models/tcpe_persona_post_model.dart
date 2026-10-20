import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_persona_post_entity.dart';

/// `tcpe_personaPost`: Persona que se postula (sin uso).
/// Columnas de `p_list_tcpe_PersonaPost` (sin `password2`) más `nombreUsuario`.
class TcpePersonaPostModel {
  final BigInt codPersonaPost;
  final String? ci;
  final String? nombre;
  final String? apPaterno;
  final String? apMaterno;
  final String? email;
  final String? ciudad;
  final String? pais;
  final DateTime? fechaNacimiento;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpePersonaPostModel({
    required this.codPersonaPost,
    this.ci,
    this.nombre,
    this.apPaterno,
    this.apMaterno,
    this.email,
    this.ciudad,
    this.pais,
    this.fechaNacimiento,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpePersonaPostModel.fromJson(Map<String, dynamic> json) => TcpePersonaPostModel(
    codPersonaPost: tcpeBigInt(json['codPersonaPost']) ?? BigInt.zero,
    ci: tcpeTexto(json['ci']),
    nombre: tcpeTexto(json['nombre']),
    apPaterno: tcpeTexto(json['apPaterno']),
    apMaterno: tcpeTexto(json['apMaterno']),
    email: tcpeTexto(json['email']),
    ciudad: tcpeTexto(json['ciudad']),
    pais: tcpeTexto(json['pais']),
    fechaNacimiento: tcpeFecha(json['fechaNacimiento']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codPersonaPost': codPersonaPost.toInt(),
    'ci': ci,
    'nombre': nombre,
    'apPaterno': apPaterno,
    'apMaterno': apMaterno,
    'email': email,
    'ciudad': ciudad,
    'pais': pais,
    'fechaNacimiento': tcpeFechaJson(fechaNacimiento),
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpePersonaPostEntity toEntity() => TcpePersonaPostEntity(
    codPersonaPost: codPersonaPost,
    ci: ci,
    nombre: nombre,
    apPaterno: apPaterno,
    apMaterno: apMaterno,
    email: email,
    ciudad: ciudad,
    pais: pais,
    fechaNacimiento: fechaNacimiento,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpePersonaPostModel.fromEntity(TcpePersonaPostEntity e) => TcpePersonaPostModel(
    codPersonaPost: e.codPersonaPost,
    ci: e.ci,
    nombre: e.nombre,
    apPaterno: e.apPaterno,
    apMaterno: e.apMaterno,
    email: e.email,
    ciudad: e.ciudad,
    pais: e.pais,
    fechaNacimiento: e.fechaNacimiento,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
