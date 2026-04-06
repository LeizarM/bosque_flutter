import 'package:bosque_flutter/domain/entities/cargo_pago_entity.dart';

class CotizacionesEntity {
  BigInt idCotizacion;
  BigInt idSolicitud;
  DateTime fechaCotizacion;
  double montoCompra;
  int idMoneda;
  int nroGiros;
  int codBanco;
  double tipoCambioOfrecido;
  double montoConvertido;
  double totalBolivianos;
  int esGanadora;
  String estado;
  String observaciones;
  int audUsuario;
  List<CargoPagoEntity> cargos;
  DateTime fechaInicio;
  DateTime fechaFin;

  CotizacionesEntity({
    required this.idCotizacion,
    required this.idSolicitud,
    required this.fechaCotizacion,
    required this.montoCompra,
    required this.idMoneda,
    required this.nroGiros,
    required this.codBanco,
    required this.tipoCambioOfrecido,
    required this.montoConvertido,
    required this.totalBolivianos,
    required this.esGanadora,
    required this.estado,
    required this.observaciones,
    required this.audUsuario,
    this.cargos = const [],
    required this.fechaInicio,
    required this.fechaFin,
  });
}
