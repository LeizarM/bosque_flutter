import 'dart:convert';
import 'package:bosque_flutter/domain/entities/proveedor_ext_sap_entity.dart';

ProveedorExtSapModel proveedorExtSapModelFromJson(String str) =>
    ProveedorExtSapModel.fromJson(json.decode(str));

String proveedorExtSapModelToJson(ProveedorExtSapModel data) =>
    json.encode(data.toJson());

class ProveedorExtSapModel {
  BigInt idProveedorSap;
  String codProvExtSap;
  String proveedorExtSap;
  BigInt audUsuario;
  DateTime? audFecha;

  ProveedorExtSapModel({
    required this.idProveedorSap,
    required this.codProvExtSap,
    required this.proveedorExtSap,
    required this.audUsuario,
    this.audFecha,
  });

  factory ProveedorExtSapModel.fromJson(Map<String, dynamic> json) =>
      ProveedorExtSapModel(
        // Cero significa "sin id": es el estado del alta antes de que el
        // IDENTITY asigne el valor real.
        idProveedorSap:
            json["idProveedorSap"] != null
                ? BigInt.from(json["idProveedorSap"])
                : BigInt.zero,
        // Se lee como texto a proposito: la columna es varchar(20) y hay
        // codigos con letras y con ceros a la izquierda.
        codProvExtSap: json["codProvExtSap"]?.toString() ?? '',
        proveedorExtSap: json["proveedorExtSap"] ?? '',
        audUsuario:
            json["audUsuario"] != null
                ? BigInt.from(json["audUsuario"])
                : BigInt.zero,
        // Nulo real: hay filas historicas sin fecha de auditoria.
        audFecha:
            json["audFecha"] != null
                ? DateTime.tryParse(json["audFecha"].toString())
                : null,
      );

  // audFecha no se envia: el procedimiento la graba con la hora del servidor y
  // descarta el valor recibido, asi que aqui es de solo lectura.
  Map<String, dynamic> toJson() => {
    "idProveedorSap": idProveedorSap.toInt(),
    "codProvExtSap": codProvExtSap,
    "proveedorExtSap": proveedorExtSap,
    "audUsuario": audUsuario.toInt(),
  };

  ProveedorExtSapEntity toEntity() => ProveedorExtSapEntity(
    idProveedorSap: idProveedorSap,
    codProvExtSap: codProvExtSap,
    proveedorExtSap: proveedorExtSap,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory ProveedorExtSapModel.fromEntity(ProveedorExtSapEntity e) =>
      ProveedorExtSapModel(
        idProveedorSap: e.idProveedorSap,
        codProvExtSap: e.codProvExtSap,
        proveedorExtSap: e.proveedorExtSap,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
      );
}
