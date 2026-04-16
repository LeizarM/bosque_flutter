import 'dart:convert';

import 'package:bosque_flutter/domain/entities/lote_produccion_entity.dart';

LoteProduccionModel loteProduccionModelFromJson(String str) =>
    LoteProduccionModel.fromJson(json.decode(str));

String loteProduccionModelToJson(LoteProduccionModel data) =>
    json.encode(data.toJson());

class LoteProduccionModel {
  final int idMa;
  final int idLp;
  final int numLote;
  final int anio;
  final DateTime fecha;
  final String hraInicioCorte;
  final String hraInicio;
  final String hraFin;
  final int cantBobinasIngresoTotal;
  final double pesoKilosTotalIngreso;
  final double pesoTotalSalida;
  final double pesoPaletaSalida;
  final double pesoMaterialSalida;
  final int cantResmaSalida;
  final double cantHojasSalida;
  final double mermaTotal;
  final double diferenciaProduccion;
  final double diferenciaProdResma;
  final double cantEstimadaResma;
  final double pesoBalanzaTotal;
  final int estado;
  final String obs;
  final int numCorte;
  final int anioCorte;
  final int docNumOrdFab;
  final int codEmpresa;
  final int audUsuario;
  final String codArticulo;
  final String datoArt;
  final String articulo;
  final double utm;
  final String codArtEntrada;
  final String codArtSalida;
  final String db;

  LoteProduccionModel({
    required this.idMa,
    required this.idLp,
    required this.numLote,
    required this.anio,
    required this.fecha,
    required this.hraInicioCorte,
    required this.hraInicio,
    required this.hraFin,
    required this.cantBobinasIngresoTotal,
    required this.pesoKilosTotalIngreso,
    required this.pesoTotalSalida,
    required this.pesoPaletaSalida,
    required this.pesoMaterialSalida,
    required this.cantResmaSalida,
    required this.cantHojasSalida,
    required this.mermaTotal,
    required this.diferenciaProduccion,
    required this.diferenciaProdResma,
    required this.cantEstimadaResma,
    required this.pesoBalanzaTotal,
    required this.estado,
    required this.obs,
    required this.numCorte,
    required this.anioCorte,
    required this.docNumOrdFab,
    required this.codEmpresa,
    required this.audUsuario,
    required this.codArticulo,
    required this.datoArt,
    required this.articulo,
    required this.utm,
    required this.codArtEntrada,
    required this.codArtSalida,
    required this.db,
  });

  factory LoteProduccionModel.fromJson(Map<String, dynamic> json) =>
      LoteProduccionModel(
        idMa: json['idMa'] ?? 0,
        idLp: json['idLp'] ?? 0,
        numLote: json['numLote'] ?? 0,
        anio: json['anio'] ?? 0,
        fecha:
            json['fecha'] != null && json['fecha'] != ''
                ? DateTime.tryParse(json['fecha']) ?? DateTime(2000)
                : DateTime(2000),
        hraInicioCorte: json['hraInicioCorte'] ?? '',
        hraInicio: json['hraInicio'] ?? '',
        hraFin: json['hraFin'] ?? '',
        cantBobinasIngresoTotal: json['cantBobinasIngresoTotal'] ?? 0,
        pesoKilosTotalIngreso: (json['pesoKilosTotalIngreso'] ?? 0).toDouble(),
        pesoTotalSalida: (json['pesoTotalSalida'] ?? 0).toDouble(),
        pesoPaletaSalida: (json['pesoPaletaSalida'] ?? 0).toDouble(),
        pesoMaterialSalida: (json['pesoMaterialSalida'] ?? 0).toDouble(),
        cantResmaSalida: json['cantResmaSalida'] ?? 0,
        cantHojasSalida: (json['cantHojasSalida'] ?? 0).toDouble(),
        mermaTotal: (json['mermaTotal'] ?? 0).toDouble(),
        diferenciaProduccion: (json['diferenciaProduccion'] ?? 0).toDouble(),
        diferenciaProdResma: (json['diferenciaProdResma'] ?? 0).toDouble(),
        cantEstimadaResma: (json['cantEstimadaResma'] ?? 0).toDouble(),
        pesoBalanzaTotal: (json['pesoBalanzaTotal'] ?? 0).toDouble(),
        estado: json['estado'] ?? 0,
        obs: json['obs'] ?? '',
        numCorte: json['numCorte'] ?? 0,
        anioCorte: json['anioCorte'] ?? 0,
        docNumOrdFab: json['docNumOrdFab'] ?? 0,
        codEmpresa: json['codEmpresa'] ?? 0,
        audUsuario: json['audUsuario'] ?? 0,
        codArticulo: json['codArticulo'] ?? '',
        datoArt: json['datoArt'] ?? '',
        articulo: json['articulo'] ?? '',
        utm: (json['utm'] ?? 0).toDouble(),
        codArtEntrada: json['codArtEntrada'] ?? '',
        codArtSalida: json['codArtSalida'] ?? '',
        db: json['db'] ?? '',
      );

  Map<String, dynamic> toJson() => {
    'idMa': idMa,
    'idLp': idLp,
    'numLote': numLote,
    'anio': anio,
    'fecha': fecha.toIso8601String(),
    'hraInicioCorte': hraInicioCorte,
    'hraInicio': hraInicio,
    'hraFin': hraFin,
    'cantBobinasIngresoTotal': cantBobinasIngresoTotal,
    'pesoKilosTotalIngreso': pesoKilosTotalIngreso,
    'pesoTotalSalida': pesoTotalSalida,
    'pesoPaletaSalida': pesoPaletaSalida,
    'pesoMaterialSalida': pesoMaterialSalida,
    'cantResmaSalida': cantResmaSalida,
    'cantHojasSalida': cantHojasSalida,
    'mermaTotal': mermaTotal,
    'diferenciaProduccion': diferenciaProduccion,
    'diferenciaProdResma': diferenciaProdResma,
    'cantEstimadaResma': cantEstimadaResma,
    'pesoBalanzaTotal': pesoBalanzaTotal,
    'estado': estado,
    'obs': obs,
    'numCorte': numCorte,
    'anioCorte': anioCorte,
    'docNumOrdFab': docNumOrdFab,
    'codEmpresa': codEmpresa,
    'audUsuario': audUsuario,
    'codArticulo': codArticulo,
    'datoArt': datoArt,
    'articulo': articulo,
    'utm': utm,
    'codArtEntrada': codArtEntrada,
    'codArtSalida': codArtSalida,
    'db': db,
  };

  LoteProduccionEntity toEntity() => LoteProduccionEntity(
    idMa: idMa,
    idLp: idLp,
    numLote: numLote,
    anio: anio,
    fecha: fecha,
    hraInicioCorte: hraInicioCorte,
    hraInicio: hraInicio,
    hraFin: hraFin,
    cantBobinasIngresoTotal: cantBobinasIngresoTotal,
    pesoKilosTotalIngreso: pesoKilosTotalIngreso,
    pesoTotalSalida: pesoTotalSalida,
    pesoPaletaSalida: pesoPaletaSalida,
    pesoMaterialSalida: pesoMaterialSalida,
    cantResmaSalida: cantResmaSalida,
    cantHojasSalida: cantHojasSalida,
    mermaTotal: mermaTotal,
    diferenciaProduccion: diferenciaProduccion,
    diferenciaProdResma: diferenciaProdResma,
    cantEstimadaResma: cantEstimadaResma,
    pesoBalanzaTotal: pesoBalanzaTotal,
    estado: estado,
    obs: obs,
    numCorte: numCorte,
    anioCorte: anioCorte,
    docNumOrdFab: docNumOrdFab,
    codEmpresa: codEmpresa,
    audUsuario: audUsuario,
    codArticulo: codArticulo,
    datoArt: datoArt,
    articulo: articulo,
    utm: utm,
    codArtEntrada: codArtEntrada,
    codArtSalida: codArtSalida,
    db: db,
  );

  factory LoteProduccionModel.fromEntity(LoteProduccionEntity entity) =>
      LoteProduccionModel(
        idMa: entity.idMa,
        idLp: entity.idLp,
        numLote: entity.numLote,
        anio: entity.anio,
        fecha: entity.fecha,
        hraInicioCorte: entity.hraInicioCorte,
        hraInicio: entity.hraInicio,
        hraFin: entity.hraFin,
        cantBobinasIngresoTotal: entity.cantBobinasIngresoTotal,
        pesoKilosTotalIngreso: entity.pesoKilosTotalIngreso,
        pesoTotalSalida: entity.pesoTotalSalida,
        pesoPaletaSalida: entity.pesoPaletaSalida,
        pesoMaterialSalida: entity.pesoMaterialSalida,
        cantResmaSalida: entity.cantResmaSalida,
        cantHojasSalida: entity.cantHojasSalida,
        mermaTotal: entity.mermaTotal,
        diferenciaProduccion: entity.diferenciaProduccion,
        diferenciaProdResma: entity.diferenciaProdResma,
        cantEstimadaResma: entity.cantEstimadaResma,
        pesoBalanzaTotal: entity.pesoBalanzaTotal,
        estado: entity.estado,
        obs: entity.obs,
        numCorte: entity.numCorte,
        anioCorte: entity.anioCorte,
        docNumOrdFab: entity.docNumOrdFab,
        codEmpresa: entity.codEmpresa,
        audUsuario: entity.audUsuario,
        codArticulo: entity.codArticulo,
        datoArt: entity.datoArt,
        articulo: entity.articulo,
        utm: entity.utm,
        codArtEntrada: entity.codArtEntrada,
        codArtSalida: entity.codArtSalida,
        db: entity.db,
      );
}
