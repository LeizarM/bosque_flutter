import 'package:bosque_flutter/data/models/entregas_model.dart';

class EntregaEntity {
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
    final int peso;
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

    EntregaEntity({
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

    EntregaEntity copyWith({
        int? idEntrega,
        int? docEntry,
        int? docNum,
        int? docNumF,
        int? factura,
        DateTime? docDate,
        String? docTime,
        String? cardCode,
        String? cardName,
        String? addressEntregaFac,
        String? addressEntregaMat,
        String? vendedor,
        String? itemCode,
        String? dscription,
        String? whsCode,
        int? quantity,
        int? openQty,
        String? db,
        String? valido,
        int? peso,
        dynamic cochePlaca,
        dynamic prioridad,
        String? tipo,
        String? obsF,
        int? fueEntregado,
        DateTime? fechaEntrega,
        double? latitud,
        double? longitud,
        dynamic direccionEntrega,
        dynamic obs,
        int? codSucursalChofer,
        int? codCiudadChofer,
        int? audUsuario,
        dynamic fechaNota,
        dynamic nombreCompleto,
        int? diferenciaMinutos,
        int? codEmpleado,
        int? codSucursal,
        dynamic cargo,
        int? flag,
        int? ord,
        dynamic fechaEntregaCad,
        int? rutaDiaria,
        dynamic fechaInicio,
        dynamic fechaFin,
        dynamic fechaInicioRutaCad,
        dynamic fechaFinRutaCad,
        dynamic estatusRuta,
        int? uchofer,
    }) => 
        EntregaEntity(
            idEntrega: idEntrega ?? this.idEntrega,
            docEntry: docEntry ?? this.docEntry,
            docNum: docNum ?? this.docNum,
            docNumF: docNumF ?? this.docNumF,
            factura: factura ?? this.factura,
            docDate: docDate ?? this.docDate,
            docTime: docTime ?? this.docTime,
            cardCode: cardCode ?? this.cardCode,
            cardName: cardName ?? this.cardName,
            addressEntregaFac: addressEntregaFac ?? this.addressEntregaFac,
            addressEntregaMat: addressEntregaMat ?? this.addressEntregaMat,
            vendedor: vendedor ?? this.vendedor,
            itemCode: itemCode ?? this.itemCode,
            dscription: dscription ?? this.dscription,
            whsCode: whsCode ?? this.whsCode,
            quantity: quantity ?? this.quantity,
            openQty: openQty ?? this.openQty,
            db: db ?? this.db,
            valido: valido ?? this.valido,
            peso: peso ?? this.peso,
            cochePlaca: cochePlaca ?? this.cochePlaca,
            prioridad: prioridad ?? this.prioridad,
            tipo: tipo ?? this.tipo,
            obsF: obsF ?? this.obsF,
            fueEntregado: fueEntregado ?? this.fueEntregado,
            fechaEntrega: fechaEntrega ?? this.fechaEntrega,
            latitud: latitud ?? this.latitud,
            longitud: longitud ?? this.longitud,
            direccionEntrega: direccionEntrega ?? this.direccionEntrega,
            obs: obs ?? this.obs,
            codSucursalChofer: codSucursalChofer ?? this.codSucursalChofer,
            codCiudadChofer: codCiudadChofer ?? this.codCiudadChofer,
            audUsuario: audUsuario ?? this.audUsuario,
            fechaNota: fechaNota ?? this.fechaNota,
            nombreCompleto: nombreCompleto ?? this.nombreCompleto,
            diferenciaMinutos: diferenciaMinutos ?? this.diferenciaMinutos,
            codEmpleado: codEmpleado ?? this.codEmpleado,
            codSucursal: codSucursal ?? this.codSucursal,
            cargo: cargo ?? this.cargo,
            flag: flag ?? this.flag,
            ord: ord ?? this.ord,
            fechaEntregaCad: fechaEntregaCad ?? this.fechaEntregaCad,
            rutaDiaria: rutaDiaria ?? this.rutaDiaria,
            fechaInicio: fechaInicio ?? this.fechaInicio,
            fechaFin: fechaFin ?? this.fechaFin,
            fechaInicioRutaCad: fechaInicioRutaCad ?? this.fechaInicioRutaCad,
            fechaFinRutaCad: fechaFinRutaCad ?? this.fechaFinRutaCad,
            estatusRuta: estatusRuta ?? this.estatusRuta,
            uchofer: uchofer ?? this.uchofer,
        );

    
}
