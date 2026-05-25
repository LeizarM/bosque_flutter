import 'package:bosque_flutter/domain/entities/cargo_pago_entity.dart';

class TransaccionesEntity {
  BigInt idTransaccion;
  String numeroTransaccion;
  BigInt idSolicitud;
  BigInt idCotizacion;
  BigInt idTipoTransaccion;
  int codBanco;
  int idCanal;
  int codEmpresa;
  String cardCode;
  DateTime fechaTransaccion;
  DateTime fechaValor;
  double montoOrigen;
  int idMonedaOrigen;
  double tipoCambioAplicado;
  double montoConvertido;
  int idMonedaDestino;
  double totalCargos;
  double totalFinal;
  String numeroContrato;
  DateTime fechaPactado;
  DateTime fechaVencimiento;
  double tipoCambioForward;
  double tipoCambioReferencia;
  double equivalenteUsdRef;
  double diferenciaDeMas;
  double porcentajeDiferencia;
  String nombreExportadora;
  double tcNegociadoExportadora;
  double comisionExportadora;
  String metodoExportadora;
  String estado;
  String observaciones;
  int audUsuario;
  String? rutaVoucher;
  bool tieneVoucher;
  // campos de JOIN (devueltos por el SP, solo lectura)
  String proveedor;
  String banco;
  String empresa;
  String monedaOrigen;
  String monedaDestino;
  List<CargoPagoEntity> cargos;

  TransaccionesEntity({
    required this.idTransaccion,
    required this.numeroTransaccion,
    required this.idSolicitud,
    required this.idCotizacion,
    required this.idTipoTransaccion,
    required this.codBanco,
    required this.idCanal,
    required this.codEmpresa,
    required this.cardCode,
    required this.fechaTransaccion,
    required this.fechaValor,
    required this.montoOrigen,
    required this.idMonedaOrigen,
    required this.tipoCambioAplicado,
    required this.montoConvertido,
    required this.idMonedaDestino,
    required this.totalCargos,
    required this.totalFinal,
    required this.numeroContrato,
    required this.fechaPactado,
    required this.fechaVencimiento,
    required this.tipoCambioForward,
    required this.tipoCambioReferencia,
    required this.equivalenteUsdRef,
    required this.diferenciaDeMas,
    required this.porcentajeDiferencia,
    required this.nombreExportadora,
    required this.tcNegociadoExportadora,
    required this.comisionExportadora,
    required this.metodoExportadora,
    required this.estado,
    required this.observaciones,
    required this.audUsuario,
    this.rutaVoucher,
    this.tieneVoucher = false,
    this.proveedor = '',
    this.banco = '',
    this.empresa = '',
    this.monedaOrigen = '',
    this.monedaDestino = '',
    this.cargos = const [],
  });
}
