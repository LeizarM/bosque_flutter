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
  final DateTime? ciFechaVencimiento;
  final String ciNumero;
  final String direccion;
  final String estadoCivil;
  final DateTime? fechaNacimiento;
  final String lugarNacimiento;
  final int nacionalidad;
  final String sexo;
  final double? lat;
  final double? lng;
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
    this.ciFechaVencimiento,
    required this.ciNumero,
    required this.direccion,
    required this.estadoCivil,
    this.fechaNacimiento,
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
  factory PersonaEntity.vacio() {
    // Definimos una fecha mínima segura para los campos required DateTime

    return PersonaEntity(
      codPersona: 0, // CRUCIAL: 0 indica que es una persona nueva/vacía
      codZona: 0,
      nombres: '',
      apPaterno: '',
      apMaterno: '',
      ciExpedido:
          'LP', // Usar un valor por defecto válido (e.g., 'SN' - Sin Expedir)
      ciFechaVencimiento: null, // Fecha de referencia
      ciNumero: '',
      direccion: '',
      estadoCivil:
          'sol', // Usar un valor por defecto válido (e.g., 'S' - Soltero/a)
      fechaNacimiento: null, // Fecha de referencia
      lugarNacimiento: '',
      nacionalidad: 0,
      sexo: 'M', // Usar un valor por defecto válido (e.g., 'M' - Masculino)
      lat: -16.516064598979447, // Coordenadas por defecto (La Paz)
      lng: -68.13540079367057, // Coordenadas por defecto (La Paz)
      audUsuarioI: 0,
      datoPersona: null,
      pais: null,
      ciudad: null,
      zona: null,
    );
  }
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
    PaisEntity? pais,
    CiudadEntity? ciudad,
    ZonaEntity? zona,
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
      pais: pais ?? this.pais,
      ciudad: ciudad ?? this.ciudad,
      zona: zona ?? this.zona,
    );
  }
}
