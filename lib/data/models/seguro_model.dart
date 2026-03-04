// To parse this JSON data, do
//
//     final seguroModel = seguroModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/seguro_entity.dart';

List<SeguroModel> seguroModelFromJson(String str) => List<SeguroModel>.from(json.decode(str).map((x) => SeguroModel.fromJson(x)));

String seguroModelToJson(List<SeguroModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class SeguroModel {
    int codSeguro;
    int codCiudad;
    String nombre;
    String nombreCorto;
    String numero;
    String regional;
    String tipo;
    int audUsuarioI;
    String descripcion;

    SeguroModel({
        required this.codSeguro,
        required this.codCiudad,
        required this.nombre,
        required this.nombreCorto,
        required this.numero,
        required this.regional,
        required this.tipo,
        required this.audUsuarioI,
        required this.descripcion,
    });

    factory SeguroModel.fromJson(Map<String, dynamic> json) => SeguroModel(
        codSeguro: json["codSeguro"]??0,
        codCiudad: json["codCiudad"]??0,
        nombre: json["nombre"]??'',
        nombreCorto: json["nombreCorto"]??'',
        numero: json["numero"]??'',
        regional: json["regional"]??'',
        tipo: json["tipo"]??'',
        audUsuarioI: json["audUsuarioI"]??0,
        descripcion: json["descripcion"]??'',
    );

    Map<String, dynamic> toJson() => {
        "codSeguro": codSeguro,
        "codCiudad": codCiudad,
        "nombre": nombre,
        "nombreCorto": nombreCorto,
        "numero": numero,
        "regional": regional,
        "tipo": tipo,
        "audUsuarioI": audUsuarioI,
        "descripcion": descripcion,
    };
    //metodo toEntity
    SeguroEntity toEntity() => SeguroEntity(
        codSeguro: codSeguro,
        codCiudad: codCiudad,
        nombre: nombre,
        nombreCorto: nombreCorto,
        numero: numero,
        regional: regional,
        tipo: tipo,
        audUsuarioI: audUsuarioI,
        descripcion: descripcion,
    );
    //metodo factory fromEntity
    factory SeguroModel.fromEntity(SeguroEntity entity) => SeguroModel(
        codSeguro: entity.codSeguro,
        codCiudad: entity.codCiudad,
        nombre: entity.nombre,
        nombreCorto: entity.nombreCorto,
        numero: entity.numero,
        regional: entity.regional,
        tipo: entity.tipo,
        audUsuarioI: entity.audUsuarioI,
        descripcion: entity.descripcion,
    );
    //metodo vacio
    factory SeguroModel.empty() => SeguroModel(
        codSeguro: 0,
        codCiudad: 0,
        nombre: '',
        nombreCorto: '',
        numero: '',
        regional: '',
        tipo: '',
        audUsuarioI: 0,
        descripcion: '',
     );
}
