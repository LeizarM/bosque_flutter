import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/pais_entity.dart';
import 'package:bosque_flutter/domain/entities/zona_entity.dart';

class PersonaEntity {
  final int codPersona;
  final int codZona;
  final String nombres;
  final String apPaterno;
  final String apMaterno;
  final String ciExpedido;
  final DateTime ciFechaVencimiento;
  final String ciNumero;
  final String direccion;
  final String estadoCivil;
  final DateTime fechaNacimiento;
  final String lugarNacimiento;
  final int nacionalidad;
  final String sexo;
  final double lat;
  final double lng;
  final int audUsuarioI;
  final String? datoPersona;
  final PaisEntity? pais;
  final CiudadEntity? ciudad;
  final ZonaEntity? zona;

  PersonaEntity({
    required this.codPersona,
    required this.codZona,
    required this.nombres,
    required this.apPaterno,
    required this.apMaterno,
    required this.ciExpedido,
    required this.ciFechaVencimiento,
    required this.ciNumero,
    required this.direccion,
    required this.estadoCivil,
    required this.fechaNacimiento,
    required this.lugarNacimiento,
    required this.nacionalidad,
    required this.sexo,
    required this.lat,
    required this.lng,
    required this.audUsuarioI,
    this.datoPersona,
    this.pais,
    this.ciudad,
    this.zona,
  });
  // Método copyWith
  PersonaEntity copyWith({
    int? codPersona,
    int? codZona,
    String? nombres,
    String? apPaterno,
    String? apMaterno,
    String? ciExpedido,
    DateTime? ciFechaVencimiento,
    String? ciNumero,
    String? direccion,
    String? estadoCivil,
    DateTime? fechaNacimiento,
    String? lugarNacimiento,
    int? nacionalidad,
    String? sexo,
    double? lat,
    double? lng,
    int? audUsuarioI,
    String? datoPersona,
  }) {
    return PersonaEntity(
      codPersona: codPersona ?? this.codPersona,
      codZona: codZona ?? this.codZona,
      nombres: nombres ?? this.nombres,
      apPaterno: apPaterno ?? this.apPaterno,
      apMaterno: apMaterno ?? this.apMaterno,
      ciExpedido: ciExpedido ?? this.ciExpedido,
      ciFechaVencimiento: ciFechaVencimiento ?? this.ciFechaVencimiento,
      ciNumero: ciNumero ?? this.ciNumero,
      direccion: direccion ?? this.direccion,
      estadoCivil: estadoCivil ?? this.estadoCivil,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      lugarNacimiento: lugarNacimiento ?? this.lugarNacimiento,
      nacionalidad: nacionalidad ?? this.nacionalidad,
      sexo: sexo ?? this.sexo,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      audUsuarioI: audUsuarioI ?? this.audUsuarioI,
      datoPersona: datoPersona ?? this.datoPersona,
    );
  }
}