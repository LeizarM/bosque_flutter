// To parse this JSON data, do
//
//     final personaModel = personaModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/data/models/ciudad_model.dart';
import 'package:bosque_flutter/data/models/pais_model.dart';
import 'package:bosque_flutter/data/models/zona_model.dart';
import 'package:bosque_flutter/domain/entities/persona_entity.dart';

PersonaModel personaModelFromJson(String str) => PersonaModel.fromJson(json.decode(str));

String personaModelToJson(PersonaModel data) => json.encode(data.toJson());

class PersonaModel {
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
    final ZonaModel zona;
    final PaisModel pais;
    final CiudadModel ciudad;

    PersonaModel({
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
        required this.zona,
        required this.pais,
        required this.ciudad,
    });

    factory PersonaModel.fromJson(Map<String, dynamic> json) => PersonaModel(
        codPersona: json["codPersona"]?? 0,
        codZona: json["codZona"]?? 0,
        nombres: json["nombres"]??'',
        apPaterno: json["apPaterno"]??'',
        apMaterno: json["apMaterno"]??'',
        ciExpedido: json["ciExpedido"]??'',
        ciFechaVencimiento:json["ciFechaVencimiento"] != null ? DateTime.parse(json["ciFechaVencimiento"]) : DateTime.now(),
        ciNumero: json["ciNumero"]??'',
        direccion: json["direccion"]??'',
        estadoCivil: json["estadoCivil"]??'',
        fechaNacimiento: json["fechaNacimiento"] != null ? DateTime.parse(json["fechaNacimiento"]) : DateTime.now(),
        lugarNacimiento: json["lugarNacimiento"]??'',
        nacionalidad: json["nacionalidad"]?? 0,
        sexo: json["sexo"]?? '',
        lat: json["lat"]?? 0.0,
        lng: json["lng"]?? 0.0,
        audUsuarioI: json["audUsuarioI"]?? 0,
        datoPersona: json["datoPersona"]??'',
        zona: ZonaModel.fromJson(json["zona"]),
        pais: PaisModel.fromJson(json["pais"]),
        ciudad: CiudadModel.fromJson(json["ciudad"]),
    );

    Map<String, dynamic> toJson() => {
        "codPersona": codPersona,
        "codZona": codZona,
        "nombres": nombres,
        "apPaterno": apPaterno,
        "apMaterno": apMaterno,
        "ciExpedido": ciExpedido,
        "ciFechaVencimiento": "${ciFechaVencimiento.year.toString().padLeft(4, '0')}-${ciFechaVencimiento.month.toString().padLeft(2, '0')}-${ciFechaVencimiento.day.toString().padLeft(2, '0')}",
        "ciNumero": ciNumero,
        "direccion": direccion,
        "estadoCivil": estadoCivil,
        "fechaNacimiento": "${fechaNacimiento.year.toString().padLeft(4, '0')}-${fechaNacimiento.month.toString().padLeft(2, '0')}-${fechaNacimiento.day.toString().padLeft(2, '0')}",
        "lugarNacimiento": lugarNacimiento,
        "nacionalidad": nacionalidad,
        "sexo": sexo,
        "lat": lat,
        "lng": lng,
        "audUsuarioI": audUsuarioI,
        "datoPersona": datoPersona,
        "zona": zona.toJson(),
        "pais": pais.toJson(),
        "ciudad": ciudad.toJson(),
    };
    PersonaEntity toEntity() => PersonaEntity(
        codPersona: codPersona,
        codZona: codZona,
        nombres: nombres,
        apPaterno: apPaterno,
        apMaterno: apMaterno,
        ciExpedido: ciExpedido,
        ciFechaVencimiento: ciFechaVencimiento,
        ciNumero: ciNumero,
        direccion: direccion,
        estadoCivil: estadoCivil,
        fechaNacimiento: fechaNacimiento,
        lugarNacimiento: lugarNacimiento,
        nacionalidad: nacionalidad,
        sexo: sexo,
        lat: lat,
        lng: lng,
        audUsuarioI: audUsuarioI,
        datoPersona: datoPersona,
        zona: zona.toEntity(),
        pais: pais.toEntity(),
        ciudad: ciudad.toEntity(),
    );
    factory PersonaModel.fromEntity(PersonaEntity entity) => PersonaModel(
        codPersona: entity.codPersona,
        codZona: entity.codZona,
        nombres: entity.nombres,
        apPaterno: entity.apPaterno,
        apMaterno: entity.apMaterno,
        ciExpedido: entity.ciExpedido,
        ciFechaVencimiento: entity.ciFechaVencimiento,
        ciNumero: entity.ciNumero,
        direccion: entity.direccion,
        estadoCivil: entity.estadoCivil,
        fechaNacimiento: entity.fechaNacimiento,
        lugarNacimiento: entity.lugarNacimiento,
        nacionalidad: entity.nacionalidad,
        sexo: entity.sexo,
        lat: entity.lat,
        lng: entity.lng,
        audUsuarioI: entity.audUsuarioI,
        datoPersona: entity.datoPersona??'',
        zona: ZonaModel(codZona: 0, codCiudad: 0, zona: '', audUsuario: 0), 
        pais: PaisModel(codPais: 0, pais: '', audUsuario: 0), 
        ciudad: CiudadModel(codCiudad: 0, codPais: 0, ciudad: '', audUsuario: 0), 
    );
}


