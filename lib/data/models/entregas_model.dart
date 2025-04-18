// To parse this JSON data, do
//
//     final entregaModel = entregaModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/entregas_entity.dart';

List<EntregaModel> entregaModelFromJson(String str) => List<EntregaModel>.from(json.decode(str).map((x) => EntregaModel.fromJson(x)));

String entregaModelToJson(List<EntregaModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class EntregaModel {
    final int idEntrega;
    final int docEntry;
    final int docNum;
    final int docNumF;
    final int factura;
    final DateTime docDate;
    final String docTime;
    final String cardCode;
    final String cardName;
    final String addressEntregaFac;
    final String addressEntregaMat;
    final String vendedor;
    final String itemCode;
    final String dscription;
    final String whsCode;
    final int quantity;
    final int openQty;
    final String db;
    final String valido;
    final double peso;
    final dynamic cochePlaca;
    final dynamic prioridad;
    final String tipo;
    final String obsF;
    final int fueEntregado;
    final DateTime fechaEntrega;
    final double latitud;
    final double longitud;
    final dynamic direccionEntrega;
    final dynamic obs;
    final int codSucursalChofer;
    final int codCiudadChofer;
    final int audUsuario;
    final dynamic fechaNota;
    final dynamic nombreCompleto;
    final int diferenciaMinutos;
    final int codEmpleado;
    final int codSucursal;
    final dynamic cargo;
    final int flag;
    final int ord;
    final dynamic fechaEntregaCad;
    final int rutaDiaria;
    final dynamic fechaInicio;
    final dynamic fechaFin;
    final dynamic fechaInicioRutaCad;
    final dynamic fechaFinRutaCad;
    final dynamic estatusRuta;
    final int uchofer;

    EntregaModel({
        required this.idEntrega,
        required this.docEntry,
        required this.docNum,
        required this.docNumF,
        required this.factura,
        required this.docDate,
        required this.docTime,
        required this.cardCode,
        required this.cardName,
        required this.addressEntregaFac,
        required this.addressEntregaMat,
        required this.vendedor,
        required this.itemCode,
        required this.dscription,
        required this.whsCode,
        required this.quantity,
        required this.openQty,
        required this.db,
        required this.valido,
        required this.peso,
        required this.cochePlaca,
        required this.prioridad,
        required this.tipo,
        required this.obsF,
        required this.fueEntregado,
        required this.fechaEntrega,
        required this.latitud,
        required this.longitud,
        required this.direccionEntrega,
        required this.obs,
        required this.codSucursalChofer,
        required this.codCiudadChofer,
        required this.audUsuario,
        required this.fechaNota,
        required this.nombreCompleto,
        required this.diferenciaMinutos,
        required this.codEmpleado,
        required this.codSucursal,
        required this.cargo,
        required this.flag,
        required this.ord,
        required this.fechaEntregaCad,
        required this.rutaDiaria,
        required this.fechaInicio,
        required this.fechaFin,
        required this.fechaInicioRutaCad,
        required this.fechaFinRutaCad,
        required this.estatusRuta,
        required this.uchofer,
    });

    factory EntregaModel.fromJson(Map<String, dynamic> json) => EntregaModel(
        idEntrega: json["idEntrega"] ?? 0,
        docEntry: json["docEntry"] ?? 0,
        docNum: json["docNum"] ?? 0,
        docNumF: json["docNumF"] ?? 0,
        factura: json["factura"] ?? 0,
        docDate: json["docDate"] != null ? DateTime.parse(json["docDate"]) : DateTime.now(),
        docTime: json["docTime"] ?? "",
        cardCode: json["cardCode"] ?? "",
        cardName: json["cardName"] ?? "",
        addressEntregaFac: json["addressEntregaFac"] ?? "",
        addressEntregaMat: json["addressEntregaMat"] ?? "",
        vendedor: json["vendedor"] ?? "",
        itemCode: json["itemCode"] ?? "",
        dscription: json["dscription"] ?? "",
        whsCode: json["whsCode"] ?? "",
        quantity: json["quantity"] ?? 0,
        openQty: json["openQty"] ?? 0,
        db: json["db"] ?? "",
        valido: json["valido"] ?? "",
        peso: (json["peso"] ?? 0).toDouble(),
        cochePlaca: json["cochePlaca"],
        prioridad: json["prioridad"] ?? "-Prioridad Desconocida-",
        tipo: json["tipo"] ?? "",
        obsF: json["obsF"] ?? "",
        fueEntregado: json["fueEntregado"] ?? 0,
        fechaEntrega: json["fechaEntrega"] != null ? 
            (json["fechaEntrega"] is String ? 
                _parseFechaEntrega(json["fechaEntrega"]) : 
                DateTime.now()) : 
            DateTime.now(),
        latitud: (json["latitud"] ?? 0).toDouble(),
        longitud: (json["longitud"] ?? 0).toDouble(),
        direccionEntrega: json["direccionEntrega"] ?? "",
        obs: json["obs"] ?? "",
        codSucursalChofer: json["codSucursalChofer"] ?? 0,
        codCiudadChofer: json["codCiudadChofer"] ?? 0,
        audUsuario: json["audUsuario"] ?? 0,
        fechaNota: json["fechaNota"],
        nombreCompleto: json["nombreCompleto"] ?? "",
        diferenciaMinutos: json["diferenciaMinutos"] ?? 0,
        codEmpleado: json["codEmpleado"] ?? 0,
        codSucursal: json["codSucursal"] ?? 0,
        cargo: json["cargo"],
        flag: json["flag"] ?? 0,
        ord: json["ord"] ?? 0,
        fechaEntregaCad: json["fechaEntregaCad"],
        rutaDiaria: json["rutaDiaria"] ?? 0,
        fechaInicio: json["fechaInicio"],
        fechaFin: json["fechaFin"],
        fechaInicioRutaCad: json["fechaInicioRutaCad"],
        fechaFinRutaCad: json["fechaFinRutaCad"],
        estatusRuta: json["estatusRuta"],
        uchofer: json["uchofer"] ?? 0,
    );

    // Helper method to parse fechaEntrega with different formats
    static DateTime _parseFechaEntrega(String dateStr) {
      try {
        // Try parsing ISO format first
        return DateTime.parse(dateStr);
      } catch (e) {
        try {
          // Try parsing custom format "dd/MM/yyyy HH:mm:ss"
          final parts = dateStr.split(' ');
          if (parts.length >= 2) {
            final dateParts = parts[0].split('/');
            final timeParts = parts[1].split(':');
            
            if (dateParts.length == 3 && timeParts.length >= 2) {
              return DateTime(
                int.parse(dateParts[2]), // year
                int.parse(dateParts[1]), // month
                int.parse(dateParts[0]), // day
                int.parse(timeParts[0]), // hour
                int.parse(timeParts[1]), // minute
                timeParts.length > 2 ? int.parse(timeParts[2]) : 0, // second
              );
            }
          }
          // If custom parsing fails, return current time
          return DateTime.now();
        } catch (e) {
          // If all parsing fails, return current time
          return DateTime.now();
        }
      }
    }

    Map<String, dynamic> toJson() => {
        "idEntrega": idEntrega,
        "docEntry": docEntry,
        "docNum": docNum,
        "docNumF": docNumF,
        "factura": factura,
        "docDate": "${docDate.year.toString().padLeft(4, '0')}-${docDate.month.toString().padLeft(2, '0')}-${docDate.day.toString().padLeft(2, '0')}",
        "docTime": docTime,
        "cardCode": cardCode,
        "cardName": cardName,
        "addressEntregaFac": addressEntregaFac,
        "addressEntregaMat": addressEntregaMat,
        "vendedor": vendedor,
        "itemCode": itemCode,
        "dscription": dscription,
        "whsCode": whsCode,
        "quantity": quantity,
        "openQty": openQty,
        "db": db,
        "valido": valido,
        "peso": peso,
        "cochePlaca": cochePlaca,
        "prioridad": prioridad,
        "tipo": tipo,
        "obsF": obsF,
        "fueEntregado": fueEntregado,
        "fechaEntrega": fechaEntrega.toIso8601String(),
        "latitud": latitud,
        "longitud": longitud,
        "direccionEntrega": direccionEntrega,
        "obs": obs,
        "codSucursalChofer": codSucursalChofer,
        "codCiudadChofer": codCiudadChofer,
        "audUsuario": audUsuario,
        "fechaNota": fechaNota,
        "nombreCompleto": nombreCompleto,
        "diferenciaMinutos": diferenciaMinutos,
        "codEmpleado": codEmpleado,
        "codSucursal": codSucursal,
        "cargo": cargo,
        "flag": flag,
        "ord": ord,
        "fechaEntregaCad": fechaEntregaCad,
        "rutaDiaria": rutaDiaria,
        "fechaInicio": fechaInicio,
        "fechaFin": fechaFin,
        "fechaInicioRutaCad": fechaInicioRutaCad,
        "fechaFinRutaCad": fechaFinRutaCad,
        "estatusRuta": estatusRuta,
        "uchofer": uchofer,
    };

    /// Convert to Entity
    EntregaEntity toEntity() {
    return EntregaEntity(
      idEntrega: idEntrega,
      docEntry: docEntry,
      docNum: docNum,
      docNumF: docNumF,
      factura: factura,
      docDate: docDate,
      docTime: docTime,
      cardCode: cardCode,
      cardName: cardName,
      addressEntregaFac: addressEntregaFac,
      addressEntregaMat: addressEntregaMat,
      vendedor: vendedor,
      itemCode: itemCode,
      dscription: dscription,
      whsCode: whsCode,
      quantity: quantity,
      openQty: openQty,
      db: db,
      valido: valido,
      peso: peso,
      cochePlaca: cochePlaca,
      prioridad: prioridad,
      tipo: tipo,
      obsF: obsF,
      fueEntregado: fueEntregado,
      fechaEntrega: fechaEntrega,
      latitud: latitud,
      longitud: longitud,
      direccionEntrega: direccionEntrega,
      obs: obs,
      codSucursalChofer: codSucursalChofer,
      codCiudadChofer: codCiudadChofer,
      audUsuario: audUsuario,
      fechaNota: fechaNota,
      nombreCompleto: nombreCompleto,
      diferenciaMinutos: diferenciaMinutos,
      codEmpleado: codEmpleado,
      codSucursal: codSucursal,
      cargo: cargo,
      flag: flag,
      ord: ord,
      fechaEntregaCad: fechaEntregaCad,
      rutaDiaria: rutaDiaria,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      fechaInicioRutaCad: fechaInicioRutaCad,
      fechaFinRutaCad: fechaFinRutaCad,
      estatusRuta: estatusRuta,
      uchofer: uchofer,
    );
  }

  /// Convert from Entity
  factory EntregaModel.fromEntity(EntregaEntity entity) {
    return EntregaModel(
      idEntrega: entity.idEntrega,
      docEntry: entity.docEntry,
      docNum: entity.docNum,
      docNumF: entity.docNumF,
      factura: entity.factura,
      docDate: entity.docDate,
      docTime: entity.docTime,
      cardCode: entity.cardCode,
      cardName: entity.cardName,
      addressEntregaFac: entity.addressEntregaFac,
      addressEntregaMat: entity.addressEntregaMat,
      vendedor: entity.vendedor,
      itemCode: entity.itemCode,
      dscription: entity.dscription,
      whsCode: entity.whsCode,
      quantity: entity.quantity,
      openQty: entity.openQty,
      db: entity.db,
      valido: entity.valido,
      peso: entity.peso,
      cochePlaca: entity.cochePlaca,
      prioridad: entity.prioridad,
      tipo: entity.tipo,
      obsF: entity.obsF,
      fueEntregado: entity.fueEntregado,
      fechaEntrega: entity.fechaEntrega,
      latitud: entity.latitud,
      longitud: entity.longitud,
      direccionEntrega: entity.direccionEntrega,
      obs: entity.obs,
      codSucursalChofer: entity.codSucursalChofer,
      codCiudadChofer: entity.codCiudadChofer,
      audUsuario: entity.audUsuario,
      fechaNota: entity.fechaNota,
      nombreCompleto: entity.nombreCompleto,
      diferenciaMinutos: entity.diferenciaMinutos,
      codEmpleado: entity.codEmpleado,
      codSucursal: entity.codSucursal,
      cargo: entity.cargo,
      flag: entity.flag,
      ord: entity.ord,
      fechaEntregaCad: entity.fechaEntregaCad,
      rutaDiaria: entity.rutaDiaria,
      fechaInicio: entity.fechaInicio,
      fechaFin: entity.fechaFin,
      fechaInicioRutaCad: entity.fechaInicioRutaCad,
      fechaFinRutaCad: entity.fechaFinRutaCad,
      estatusRuta: entity.estatusRuta,
      uchofer: entity.uchofer,
    );
  }
}
