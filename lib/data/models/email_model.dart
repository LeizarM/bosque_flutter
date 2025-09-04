// To parse this JSON data, do
//
//     final emailModel = emailModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/email_entity.dart';

List<EmailModel> emailModelFromJson(String str) => List<EmailModel>.from(json.decode(str).map((x) => EmailModel.fromJson(x)));

String emailModelToJson(List<EmailModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class EmailModel {
    final int codEmail;
    final int codPersona;
    final String email;
    final int audUsuario;

    EmailModel({
        required this.codEmail,
        required this.codPersona,
        required this.email,
        required this.audUsuario,
    });

    factory EmailModel.fromJson(Map<String, dynamic> json) => EmailModel(
        codEmail: json["codEmail"]?? 0,
        codPersona: json["codPersona"]?? 0,
        email: json["email"]?? '',
        audUsuario: json["audUsuario"]?? 0,
    );

    Map<String, dynamic> toJson() => {
        "codEmail": codEmail,
        "codPersona": codPersona,
        "email": email,
        "audUsuario": audUsuario,
    };
    EmailEntity toEntity() => EmailEntity(
        codEmail: codEmail,
        codPersona: codPersona,
        email: email,
        audUsuario: audUsuario,
    );
    factory EmailModel.fromEntity(EmailEntity entity) => EmailModel(
        codEmail: entity.codEmail,
        codPersona: entity.codPersona,
        email: entity.email,
        audUsuario: entity.audUsuario,
    );
}
