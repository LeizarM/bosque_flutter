// To parse this JSON data, do
//
//     final nroCuentaBancariaModel = nroCuentaBancariaModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/nro_cuenta_bancaria_entity.dart';

List<NroCuentaBancariaModel> nroCuentaBancariaModelFromJson(String str) => List<NroCuentaBancariaModel>.from(json.decode(str).map((x) => NroCuentaBancariaModel.fromJson(x)));

String nroCuentaBancariaModelToJson(List<NroCuentaBancariaModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class NroCuentaBancariaModel {
    final int codCuenta;
    final int codEmpleado;
    final int codBanco;
    final String nroCuentaBancaria;
    final int estado;
    final int audUsuarioI;

    NroCuentaBancariaModel({
        required this.codCuenta,
        required this.codEmpleado,
        required this.codBanco,
        required this.nroCuentaBancaria,
        required this.estado,
        required this.audUsuarioI,
    });

    factory NroCuentaBancariaModel.fromJson(Map<String, dynamic> json) => NroCuentaBancariaModel(
        codCuenta: json["codCuenta"],
        codEmpleado: json["codEmpleado"],
        codBanco: json["codBanco"],
        nroCuentaBancaria: json["nroCuentaBancaria"],
        estado: json["estado"],
        audUsuarioI: json["audUsuarioI"],
    );

    Map<String, dynamic> toJson() => {
        "codCuenta": codCuenta,
        "codEmpleado": codEmpleado,
        "codBanco": codBanco,
        "nroCuentaBancaria": nroCuentaBancaria,
        "estado": estado,
        "audUsuarioI": audUsuarioI,
    };
    NroCuentaBancariaEntity toEntity() => NroCuentaBancariaEntity(
        codCuenta: codCuenta,
        codEmpleado: codEmpleado,
        codBanco: codBanco,
        nroCuentaBancaria: nroCuentaBancaria,
        estado: estado,
        audUsuarioI: audUsuarioI,
    );
    factory NroCuentaBancariaModel.fromEntity(NroCuentaBancariaEntity entity) => NroCuentaBancariaModel(
        codCuenta:  entity.codCuenta,
        codEmpleado: entity.codEmpleado,
        codBanco: entity.codBanco,
        nroCuentaBancaria: entity.nroCuentaBancaria,
        estado: entity.estado,
        audUsuarioI: entity.audUsuarioI,
    );
}
