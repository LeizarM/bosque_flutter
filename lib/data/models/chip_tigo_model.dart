// To parse this JSON data, do
//
//     final ChipTigoResponse = ChipTigoResponseFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/chip_tigo_entity.dart';

ChipTigoResponse chipTigoResponseFromJson(String str) => ChipTigoResponse.fromJson(json.decode(str));

String chipTigoResponseToJson(ChipTigoResponse data) => json.encode(data.toJson());

class ChipTigoResponse {
    String message;
    List<ChipTigoModel> data;
    int status;
    int? idGenerado;

    ChipTigoResponse({
        required this.message,
        required this.data,
        required this.status,
        this.idGenerado,
    });

   /* factory ChipTigoResponse.fromJson(Map<String, dynamic> json) => ChipTigoResponse(
        message: json["message"]??'',
        data: json["data"] == null 
            ? [] 
            : List<ChipTigoModel>.from(json["data"].map((x) => ChipTigoModel.fromJson(x))),
        status: json["status"]??0,
        idGenerado: json["idGenerado"],
    );*/

factory ChipTigoResponse.fromJson(Map<String, dynamic> json) {
        List<ChipTigoModel> listaData = [];
        int? idGen;

        // Evaluamos dinámicamente qué tipo de información llegó en "data"
        if (json["data"] != null) {
            if (json["data"] is List) {
                // Si es una lista, la mapeamos normalmente
                listaData = List<ChipTigoModel>.from(
                    (json["data"] as List).map((x) => ChipTigoModel.fromJson(x))
                );
            } else if (json["data"] is int) {
                // Si es un número, Java nos está mandando el ID generado en esa propiedad
                idGen = json["data"];
            }
        }

        return ChipTigoResponse(
            message: json["message"] ?? '',
            data: listaData,
            status: json["status"] ?? 0,
            // Asignamos el idGenerado que vino explícito, o el que rescatamos de "data"
            idGenerado: json["idGenerado"] ?? idGen,
        );
    }
    Map<String, dynamic> toJson() => {
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
        "status": status,
    };
}

class ChipTigoModel {
    int codLinea;
    int codEmpleado;
    DateTime fechaSolicitud;
    String telefono;
    String nombreCompleto;
    String descripcion;
    int audUsuarioI;
    DateTime audFechaI;
    String? search;
    int? fila;
    int? pagina;
    int? tamanoPagina;
    String? periodo;
    String? codigo;

    ChipTigoModel({
        required this.codLinea,
        required this.codEmpleado,
        required this.fechaSolicitud,
        required this.telefono,
        required this.nombreCompleto,
        required this.descripcion,
        required this.audUsuarioI,
        required this.audFechaI,
        required this.search,
        required this.fila,
        required this.pagina,
        required this.tamanoPagina,
        this.periodo,
        this.codigo,
    });

    factory ChipTigoModel.fromJson(Map<String, dynamic> json) => ChipTigoModel(
        codLinea: json["codLinea"]??0,
        codEmpleado: json["codEmpleado"]??0,
        fechaSolicitud: json["fechaSolicitud"] != null 
            ? DateTime.parse(json["fechaSolicitud"]) 
            : DateTime.now(),
        telefono: json["telefono"]??'',
        nombreCompleto: json["nombreCompleto"]??'',
        descripcion: json["descripcion"]??'',
        audUsuarioI: json["audUsuarioI"]??0,
        audFechaI: json["audFechaI"] != null 
            ? DateTime.parse(json["audFechaI"]) 
            : DateTime.now(),
        search: json["search"]??'',
        fila: json["fila"]??0,
        pagina: json["pagina"]??1,
        tamanoPagina: json["tamanoPagina"]??15,
        periodo: json["periodo"],
        codigo: json["codigo"]??'',
    );

    Map<String, dynamic> toJson() => {
        "codLinea": codLinea,
        "codEmpleado": codEmpleado,
        "fechaSolicitud": fechaSolicitud.toIso8601String(),
        "telefono": telefono,
        "nombreCompleto": nombreCompleto,
        "descripcion": descripcion,
        "audUsuarioI": audUsuarioI,
        "audFechaI": audFechaI.toIso8601String(),
        "search": search,
        "fila": fila,
        "pagina": pagina,
        "tamanoPagina": tamanoPagina,
        "periodo": periodo,
        "codigo": codigo,
    };
    // Método para convertir el modelo a la entidad
    ChipTigoEntity toEntity() => ChipTigoEntity(
        codLinea: codLinea,
        codEmpleado: codEmpleado,
        fechaSolicitud: fechaSolicitud,
        telefono: telefono,
        nombreCompleto: nombreCompleto,
        descripcion: descripcion,
        audUsuarioI: audUsuarioI,
        audFechaI: audFechaI,
        search: search,
        fila: fila,
        pagina: pagina,
        tamanoPagina: tamanoPagina,
        periodo: periodo,
        codigo: codigo,
    );  
    // Método para crear el modelo desde la entidad
    factory ChipTigoModel.fromEntity(ChipTigoEntity entity) => ChipTigoModel(
        codLinea: entity.codLinea,
        codEmpleado: entity.codEmpleado,
        fechaSolicitud: entity.fechaSolicitud,
        telefono: entity.telefono,
        nombreCompleto: entity.nombreCompleto,
        descripcion: entity.descripcion,
        audUsuarioI: entity.audUsuarioI,
        audFechaI: entity.audFechaI,
        search: entity.search,
        fila: entity.fila,
        pagina: entity.pagina,
        tamanoPagina: entity.tamanoPagina,
        periodo: entity.periodo,
        codigo: entity.codigo,
    );

}
