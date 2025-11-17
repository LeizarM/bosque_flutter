import 'dart:convert';

import 'package:bosque_flutter/domain/entities/vista_usuario_entity.dart';

VistaUsuarioModel vistaUsuarioModelFromJson(String str) =>
    VistaUsuarioModel.fromJson(json.decode(str));

String vistaUsuarioModelToJson(VistaUsuarioModel data) =>
    json.encode(data.toJson());

class VistaUsuarioModel {
  int codUsuario;
  int codVista;
  int nivelAcceso;
  int autorizador;
  int audUsuarioI;

  int fila;
  int codVistaPadre;
  int codBoton;
  String direccion;
  String nombreComponente;
  String modulo;
  String vista;
  String boton;
  String descripcion;
  String imagen; //hasta el momento no se utiliza
  int nivelAccesoBoton;
  String tipo;

  VistaUsuarioModel({
    required this.codUsuario,
    required this.codVista,
    required this.nivelAcceso,
    required this.autorizador,
    required this.audUsuarioI,

    required this.fila,
    required this.codVistaPadre,
    required this.codBoton,
    required this.direccion,
    required this.nombreComponente,
    required this.modulo,
    required this.vista,
    required this.boton,
    required this.descripcion,
    required this.imagen,
    required this.nivelAccesoBoton,
    required this.tipo,
  });

  factory VistaUsuarioModel.fromJson(Map<String, dynamic> json) =>
      VistaUsuarioModel(
        codUsuario: json["codUsuario"] ?? 0,
        codVista: json["codVista"] ?? 0,
        nivelAcceso: json["nivelAcceso"] ?? 0,
        autorizador: json["autorizador"] ?? 0,
        audUsuarioI: json["audUsuarioI"] ?? 0,

        fila: json["fila"] ?? 0,
        codVistaPadre: json["codVistaPadre"] ?? 0,
        codBoton: json["codBoton"] ?? 0,
        direccion: json["direccion"] ?? '',
        nombreComponente: json["nombreComponente"] ?? '',
        modulo: json["modulo"] ?? '',
        vista: json["vista"] ?? '',
        boton: json["boton"] ?? '',
        descripcion: json["descripcion"] ?? '',
        imagen: json["imagen"] ?? '',
        nivelAccesoBoton: json["nivelAccesoBoton"] ?? 0,
        tipo: json["tipo"] ?? '',
      );

  Map<String, dynamic> toJson() => {
    "codUsuario": codUsuario,
    "codVista": codVista,
    "nivelAcceso": nivelAcceso,
    "autorizador": autorizador,
    "audUsuarioI": audUsuarioI,
    "codBoton": codBoton,
    "tipo": tipo,
    "fila": fila,
    "codVistaPadre": codVistaPadre,
    "direccion": direccion,
    "nombreComponente": nombreComponente,
    "modulo": modulo,
    "vista": vista,
    "boton": boton,
    "descripcion": descripcion,
    "imagen": imagen,
    "nivelAccesoBoton": nivelAccesoBoton,
  };

  // Método para convertir de Model a Entity
  VistaUsuarioEntity toEntity() => VistaUsuarioEntity(
    codUsuario: codUsuario,
    codVista: codVista,
    nivelAcceso: nivelAcceso,
    autorizador: autorizador,
    audUsuarioI: audUsuarioI,

    fila: fila,
    codVistaPadre: codVistaPadre,
    codBoton: codBoton,
    direccion: direccion,
    nombreComponente: nombreComponente,
    modulo: modulo,
    vista: vista,
    boton: boton,
    descripcion: descripcion,
    imagen: imagen,
    nivelAccesoBoton: nivelAccesoBoton,
    tipo: tipo,
  );

  // Método factory para convertir de Entity a Model
  factory VistaUsuarioModel.fromEntity(VistaUsuarioEntity entity) =>
      VistaUsuarioModel(
        codUsuario: entity.codUsuario,
        codVista: entity.codVista,
        nivelAcceso: entity.nivelAcceso,
        autorizador: entity.autorizador,
        audUsuarioI: entity.audUsuarioI,

        fila: entity.fila,
        codVistaPadre: entity.codVistaPadre,
        codBoton: entity.codBoton,
        direccion: entity.direccion,
        nombreComponente: entity.nombreComponente,
        modulo: entity.modulo,
        vista: entity.vista,
        boton: entity.boton,
        descripcion: entity.descripcion,
        imagen: entity.imagen,
        nivelAccesoBoton: entity.nivelAccesoBoton,
        tipo: entity.tipo,
      );
}
