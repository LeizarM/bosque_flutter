import 'package:bosque_flutter/domain/entities/transaccion_participante_entity.dart';

class TransaccionParticipanteModel {
  BigInt idParticipante;
  BigInt idTransaccion;
  String tipoParticipante;
  String nombre;
  double porcentaje;
  double montoUs;
  double montoBs;
  double itfUs;
  double itfBs;
  String observaciones;
  String estadoTransaccion;
  DateTime? fechaTransaccion;
  double montoOrigen;
  double montoConvertido;
  int cantidadParticipantes;
  double totalPorcentaje;
  double totalMontoUs;
  double totalMontoBs;
  double totalItfUs;
  double totalItfBs;
  double diferenciaUs;
  String estadoCuadre;
  int audUsuario;
  DateTime? audFecha;

  TransaccionParticipanteModel({
    required this.idParticipante,
    required this.idTransaccion,
    required this.tipoParticipante,
    required this.nombre,
    required this.porcentaje,
    required this.montoUs,
    required this.montoBs,
    required this.itfUs,
    required this.itfBs,
    required this.observaciones,
    required this.estadoTransaccion,
    this.fechaTransaccion,
    required this.montoOrigen,
    required this.montoConvertido,
    required this.cantidadParticipantes,
    required this.totalPorcentaje,
    required this.totalMontoUs,
    required this.totalMontoBs,
    required this.totalItfUs,
    required this.totalItfBs,
    required this.diferenciaUs,
    required this.estadoCuadre,
    required this.audUsuario,
    this.audFecha,
  });

  factory TransaccionParticipanteModel.fromJson(Map<String, dynamic> json) =>
      TransaccionParticipanteModel(
        idParticipante:
            json['idParticipante'] != null
                ? BigInt.from(json['idParticipante'])
                : BigInt.zero,
        idTransaccion:
            json['idTransaccion'] != null
                ? BigInt.from(json['idTransaccion'])
                : BigInt.zero,
        tipoParticipante: json['tipoParticipante'] ?? '',
        nombre: json['nombre'] ?? '',
        porcentaje: (json['porcentaje'] ?? 0).toDouble(),
        montoUs: (json['montoUs'] ?? 0).toDouble(),
        montoBs: (json['montoBs'] ?? 0).toDouble(),
        itfUs: (json['itfUs'] ?? 0).toDouble(),
        itfBs: (json['itfBs'] ?? 0).toDouble(),
        observaciones: json['observaciones'] ?? '',
        estadoTransaccion: json['estadoTransaccion'] ?? '',
        fechaTransaccion:
            json['fechaTransaccion'] != null
                ? DateTime.tryParse(json['fechaTransaccion'])
                : null,
        montoOrigen: (json['montoOrigen'] ?? 0).toDouble(),
        montoConvertido: (json['montoConvertido'] ?? 0).toDouble(),
        cantidadParticipantes: json['cantidadParticipantes'] ?? 0,
        totalPorcentaje: (json['totalPorcentaje'] ?? 0).toDouble(),
        totalMontoUs: (json['totalMontoUs'] ?? 0).toDouble(),
        totalMontoBs: (json['totalMontoBs'] ?? 0).toDouble(),
        totalItfUs: (json['totalItfUs'] ?? 0).toDouble(),
        totalItfBs: (json['totalItfBs'] ?? 0).toDouble(),
        diferenciaUs: (json['diferenciaUs'] ?? 0).toDouble(),
        estadoCuadre: json['estadoCuadre'] ?? '',
        audUsuario: json['audUsuario'] ?? 0,
        audFecha:
            json['audFecha'] != null
                ? DateTime.tryParse(json['audFecha'])
                : null,
      );

  Map<String, dynamic> toJson() => {
    'idParticipante': idParticipante.toInt(),
    'idTransaccion': idTransaccion.toInt(),
    'tipoParticipante': tipoParticipante,
    'nombre': nombre,
    'porcentaje': porcentaje,
    'montoUs': montoUs,
    'montoBs': montoBs,
    'itfUs': itfUs,
    'itfBs': itfBs,
    'observaciones': observaciones,
    'audUsuario': audUsuario,
  };

  TransaccionParticipanteEntity toEntity() => TransaccionParticipanteEntity(
    idParticipante: idParticipante,
    idTransaccion: idTransaccion,
    tipoParticipante: tipoParticipante,
    nombre: nombre,
    porcentaje: porcentaje,
    montoUs: montoUs,
    montoBs: montoBs,
    itfUs: itfUs,
    itfBs: itfBs,
    observaciones: observaciones,
    estadoTransaccion: estadoTransaccion,
    fechaTransaccion: fechaTransaccion,
    montoOrigen: montoOrigen,
    montoConvertido: montoConvertido,
    cantidadParticipantes: cantidadParticipantes,
    totalPorcentaje: totalPorcentaje,
    totalMontoUs: totalMontoUs,
    totalMontoBs: totalMontoBs,
    totalItfUs: totalItfUs,
    totalItfBs: totalItfBs,
    diferenciaUs: diferenciaUs,
    estadoCuadre: estadoCuadre,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory TransaccionParticipanteModel.fromEntity(
    TransaccionParticipanteEntity entity,
  ) => TransaccionParticipanteModel(
    idParticipante: entity.idParticipante,
    idTransaccion: entity.idTransaccion,
    tipoParticipante: entity.tipoParticipante,
    nombre: entity.nombre,
    porcentaje: entity.porcentaje,
    montoUs: entity.montoUs,
    montoBs: entity.montoBs,
    itfUs: entity.itfUs,
    itfBs: entity.itfBs,
    observaciones: entity.observaciones,
    estadoTransaccion: entity.estadoTransaccion,
    fechaTransaccion: entity.fechaTransaccion,
    montoOrigen: entity.montoOrigen,
    montoConvertido: entity.montoConvertido,
    cantidadParticipantes: entity.cantidadParticipantes,
    totalPorcentaje: entity.totalPorcentaje,
    totalMontoUs: entity.totalMontoUs,
    totalMontoBs: entity.totalMontoBs,
    totalItfUs: entity.totalItfUs,
    totalItfBs: entity.totalItfBs,
    diferenciaUs: entity.diferenciaUs,
    estadoCuadre: entity.estadoCuadre,
    audUsuario: entity.audUsuario,
    audFecha: entity.audFecha,
  );
}
