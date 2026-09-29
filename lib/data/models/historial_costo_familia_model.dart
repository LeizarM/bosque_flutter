import 'package:bosque_flutter/domain/entities/historial_costo_familia_entity.dart';

/// Lo que devuelve /price/familia/historialCosto por fila. Es de solo
/// lectura: no hay camino de vuelta a la API, pero se respeta el molde del
/// modulo (fromJson, toJson, toEntity, fromEntity).
class HistorialCostoFamiliaModel {
  int codigoFamilia;
  DateTime? fecha;
  String usuario;
  BigInt audUsuario;
  BigInt propuestaAnterior;
  BigInt propuestaNueva;
  double? costoAnterior;
  double? costoNuevo;
  double costoActual;
  BigInt propuestaActual;

  HistorialCostoFamiliaModel({
    required this.codigoFamilia,
    required this.fecha,
    required this.usuario,
    required this.audUsuario,
    required this.propuestaAnterior,
    required this.propuestaNueva,
    required this.costoAnterior,
    required this.costoNuevo,
    required this.costoActual,
    required this.propuestaActual,
  });

  static BigInt _id(Object? v) => switch (v) {
    int n => BigInt.from(n),
    num n => BigInt.from(n.toInt()),
    String t => BigInt.tryParse(t.trim()) ?? BigInt.zero,
    _ => BigInt.zero,
  };

  static double? _numero(Object? v) => switch (v) {
    num n => n.toDouble(),
    String t => double.tryParse(t.trim()),
    _ => null,
  };

  factory HistorialCostoFamiliaModel.fromJson(Map<String, dynamic> json) =>
      HistorialCostoFamiliaModel(
        codigoFamilia: (json['codigoFamilia'] as num?)?.toInt() ?? 0,
        // Spring serializa java.util.Date como ISO o como milisegundos segun
        // la configuracion de Jackson: se aceptan los dos.
        fecha: switch (json['fecha']) {
          String t => DateTime.tryParse(t)?.toLocal(),
          int ms => DateTime.fromMillisecondsSinceEpoch(ms),
          _ => null,
        },
        usuario: (json['usuario'] as String?)?.trim() ?? '',
        audUsuario: _id(json['audUsuario']),
        propuestaAnterior: _id(json['propuestaAnterior']),
        propuestaNueva: _id(json['propuestaNueva']),
        costoAnterior: _numero(json['costoAnterior']),
        costoNuevo: _numero(json['costoNuevo']),
        costoActual: _numero(json['costoActual']) ?? 0,
        propuestaActual: _id(json['propuestaActual']),
      );

  Map<String, dynamic> toJson() => {
    'codigoFamilia': codigoFamilia,
    'fecha': fecha?.toIso8601String(),
    'usuario': usuario,
    'audUsuario': audUsuario.toInt(),
    'propuestaAnterior': propuestaAnterior.toInt(),
    'propuestaNueva': propuestaNueva.toInt(),
    'costoAnterior': costoAnterior,
    'costoNuevo': costoNuevo,
    'costoActual': costoActual,
    'propuestaActual': propuestaActual.toInt(),
  };

  HistorialCostoFamiliaEntity toEntity() => HistorialCostoFamiliaEntity(
    codigoFamilia: codigoFamilia,
    fecha: fecha,
    usuario: usuario,
    audUsuario: audUsuario,
    propuestaAnterior: propuestaAnterior,
    propuestaNueva: propuestaNueva,
    costoAnterior: costoAnterior,
    costoNuevo: costoNuevo,
    costoActual: costoActual,
    propuestaActual: propuestaActual,
  );

  factory HistorialCostoFamiliaModel.fromEntity(
    HistorialCostoFamiliaEntity e,
  ) => HistorialCostoFamiliaModel(
    codigoFamilia: e.codigoFamilia,
    fecha: e.fecha,
    usuario: e.usuario,
    audUsuario: e.audUsuario,
    propuestaAnterior: e.propuestaAnterior,
    propuestaNueva: e.propuestaNueva,
    costoAnterior: e.costoAnterior,
    costoNuevo: e.costoNuevo,
    costoActual: e.costoActual,
    propuestaActual: e.propuestaActual,
  );
}
