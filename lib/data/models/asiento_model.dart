import 'package:bosque_flutter/domain/entities/asiento_entity.dart';

class AsientoModel {
  BigInt idAsiento;
  BigInt idTransaccion;
  int numero;
  String tipoAsiento;
  int codBancoRef;
  String banco;
  String cuentaDebe;
  String cuentaHaber;
  String descripcion;
  double debitoUs;
  double creditoUs;
  double debitoBs;
  double creditoBs;
  double tcAplicado;
  String estadoTransaccion;
  DateTime? fechaTransaccion;
  double totalDebitoUs;
  double totalCreditoUs;
  double totalDebitoBs;
  double totalCreditoBs;
  double diferenciaBs;
  String estadoCuadre;
  int audUsuario;
  DateTime? audFecha;

  AsientoModel({
    required this.idAsiento,
    required this.idTransaccion,
    required this.numero,
    required this.tipoAsiento,
    required this.codBancoRef,
    required this.banco,
    required this.cuentaDebe,
    required this.cuentaHaber,
    required this.descripcion,
    required this.debitoUs,
    required this.creditoUs,
    required this.debitoBs,
    required this.creditoBs,
    required this.tcAplicado,
    required this.estadoTransaccion,
    this.fechaTransaccion,
    required this.totalDebitoUs,
    required this.totalCreditoUs,
    required this.totalDebitoBs,
    required this.totalCreditoBs,
    required this.diferenciaBs,
    required this.estadoCuadre,
    required this.audUsuario,
    this.audFecha,
  });

  factory AsientoModel.fromJson(Map<String, dynamic> json) => AsientoModel(
    idAsiento:
        json['idAsiento'] != null
            ? BigInt.from(json['idAsiento'])
            : BigInt.zero,
    idTransaccion:
        json['idTransaccion'] != null
            ? BigInt.from(json['idTransaccion'])
            : BigInt.zero,
    numero: json['numero'] ?? 0,
    tipoAsiento: json['tipoAsiento'] ?? '',
    codBancoRef: json['codBancoRef'] ?? 0,
    banco: json['banco'] ?? '',
    cuentaDebe: json['cuentaDebe'] ?? '',
    cuentaHaber: json['cuentaHaber'] ?? '',
    descripcion: json['descripcion'] ?? '',
    debitoUs: (json['debitoUs'] ?? 0).toDouble(),
    creditoUs: (json['creditoUs'] ?? 0).toDouble(),
    debitoBs: (json['debitoBs'] ?? 0).toDouble(),
    creditoBs: (json['creditoBs'] ?? 0).toDouble(),
    tcAplicado: (json['tcAplicado'] ?? 0).toDouble(),
    estadoTransaccion: json['estadoTransaccion'] ?? '',
    fechaTransaccion:
        json['fechaTransaccion'] != null
            ? DateTime.tryParse(json['fechaTransaccion'])
            : null,
    totalDebitoUs: (json['totalDebitoUs'] ?? 0).toDouble(),
    totalCreditoUs: (json['totalCreditoUs'] ?? 0).toDouble(),
    totalDebitoBs: (json['totalDebitoBs'] ?? 0).toDouble(),
    totalCreditoBs: (json['totalCreditoBs'] ?? 0).toDouble(),
    diferenciaBs: (json['diferenciaBs'] ?? 0).toDouble(),
    estadoCuadre: json['estadoCuadre'] ?? '',
    audUsuario: json['audUsuario'] ?? 0,
    audFecha:
        json['audFecha'] != null ? DateTime.tryParse(json['audFecha']) : null,
  );

  Map<String, dynamic> toJson() => {
    'idAsiento': idAsiento.toInt(),
    'idTransaccion': idTransaccion.toInt(),
    'numero': numero,
    'tipoAsiento': tipoAsiento,
    'codBancoRef': codBancoRef,
    'cuentaDebe': cuentaDebe,
    'cuentaHaber': cuentaHaber,
    'descripcion': descripcion,
    'debitoUs': debitoUs,
    'creditoUs': creditoUs,
    'debitoBs': debitoBs,
    'creditoBs': creditoBs,
    'tcAplicado': tcAplicado,
    'audUsuario': audUsuario,
  };

  AsientoEntity toEntity() => AsientoEntity(
    idAsiento: idAsiento,
    idTransaccion: idTransaccion,
    numero: numero,
    tipoAsiento: tipoAsiento,
    codBancoRef: codBancoRef,
    banco: banco,
    cuentaDebe: cuentaDebe,
    cuentaHaber: cuentaHaber,
    descripcion: descripcion,
    debitoUs: debitoUs,
    creditoUs: creditoUs,
    debitoBs: debitoBs,
    creditoBs: creditoBs,
    tcAplicado: tcAplicado,
    estadoTransaccion: estadoTransaccion,
    fechaTransaccion: fechaTransaccion,
    totalDebitoUs: totalDebitoUs,
    totalCreditoUs: totalCreditoUs,
    totalDebitoBs: totalDebitoBs,
    totalCreditoBs: totalCreditoBs,
    diferenciaBs: diferenciaBs,
    estadoCuadre: estadoCuadre,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );
}
