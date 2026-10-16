import 'package:bosque_flutter/domain/entities/prestamo_documento_entity.dart';

class PrestamoDocumentoModel {
  final int codPrestamo;
  final int codEntrega;
  final int codCaja;
  final int? codContenido;
  final String? fechaDevolucion;
  final String? observacionDevolucion;
  final int audUsuario;
  final DateTime? audFecha;
  final int numeroCaja;
  final int codArchivo;
  final String? nombreArchivo;
  final String? nombreTipoDocumento;
  final String? detalle;
  final String? gestion;
  final int codEmpleado;
  final String? nombreEmpleado;
  final String? fechaEntrega;
  final String? observacionEntrega;
  final String? nombreUsuario;

  const PrestamoDocumentoModel({
    required this.codPrestamo,
    required this.codEntrega,
    required this.codCaja,
    this.codContenido,
    this.fechaDevolucion,
    this.observacionDevolucion,
    this.audUsuario = 0,
    this.audFecha,
    this.numeroCaja = 0,
    this.codArchivo = 0,
    this.nombreArchivo,
    this.nombreTipoDocumento,
    this.detalle,
    this.gestion,
    this.codEmpleado = 0,
    this.nombreEmpleado,
    this.fechaEntrega,
    this.observacionEntrega,
    this.nombreUsuario,
  });

  factory PrestamoDocumentoModel.fromJson(Map<String, dynamic> json) {
    int? entero(String clave) => (json[clave] as num?)?.toInt();
    return PrestamoDocumentoModel(
      codPrestamo: entero('codPrestamo') ?? 0,
      codEntrega: entero('codEntrega') ?? 0,
      codCaja: entero('codCaja') ?? 0,
      codContenido: entero('codContenido'),
      fechaDevolucion: json['fechaDevolucion'] as String?,
      observacionDevolucion: json['observacionDevolucion'] as String?,
      audUsuario: entero('audUsuario') ?? 0,
      audFecha: DateTime.tryParse(json['audFecha']?.toString() ?? ''),
      numeroCaja: entero('numeroCaja') ?? 0,
      codArchivo: entero('codArchivo') ?? 0,
      nombreArchivo: json['nombreArchivo'] as String?,
      nombreTipoDocumento: json['nombreTipoDocumento'] as String?,
      detalle: json['detalle'] as String?,
      gestion: json['gestion'] as String?,
      codEmpleado: entero('codEmpleado') ?? 0,
      nombreEmpleado: json['nombreEmpleado'] as String?,
      fechaEntrega: json['fechaEntrega'] as String?,
      observacionEntrega: json['observacionEntrega'] as String?,
      nombreUsuario: json['nombreUsuario'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'codPrestamo': codPrestamo,
    'codEntrega': codEntrega,
    'codCaja': codCaja,
    'codContenido': codContenido,
    'fechaDevolucion': fechaDevolucion,
    'observacionDevolucion': observacionDevolucion,
    'audUsuario': audUsuario,
    'audFecha': audFecha?.toIso8601String(),
    'numeroCaja': numeroCaja,
    'codArchivo': codArchivo,
    'nombreArchivo': nombreArchivo,
    'nombreTipoDocumento': nombreTipoDocumento,
    'detalle': detalle,
    'gestion': gestion,
    'codEmpleado': codEmpleado,
    'nombreEmpleado': nombreEmpleado,
    'fechaEntrega': fechaEntrega,
    'observacionEntrega': observacionEntrega,
    'nombreUsuario': nombreUsuario,
  };

  PrestamoDocumentoEntity toEntity() => PrestamoDocumentoEntity(
    codPrestamo: codPrestamo,
    codEntrega: codEntrega,
    codCaja: codCaja,
    codContenido: codContenido,
    fechaDevolucion: fechaDevolucion,
    observacionDevolucion: observacionDevolucion,
    audUsuario: audUsuario,
    audFecha: audFecha,
    numeroCaja: numeroCaja,
    codArchivo: codArchivo,
    nombreArchivo: nombreArchivo,
    nombreTipoDocumento: nombreTipoDocumento,
    detalle: detalle,
    gestion: gestion,
    codEmpleado: codEmpleado,
    nombreEmpleado: nombreEmpleado,
    fechaEntrega: fechaEntrega,
    observacionEntrega: observacionEntrega,
    nombreUsuario: nombreUsuario,
  );

  factory PrestamoDocumentoModel.fromEntity(PrestamoDocumentoEntity e) => PrestamoDocumentoModel(
    codPrestamo: e.codPrestamo,
    codEntrega: e.codEntrega,
    codCaja: e.codCaja,
    codContenido: e.codContenido,
    fechaDevolucion: e.fechaDevolucion,
    observacionDevolucion: e.observacionDevolucion,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    numeroCaja: e.numeroCaja,
    codArchivo: e.codArchivo,
    nombreArchivo: e.nombreArchivo,
    nombreTipoDocumento: e.nombreTipoDocumento,
    detalle: e.detalle,
    gestion: e.gestion,
    codEmpleado: e.codEmpleado,
    nombreEmpleado: e.nombreEmpleado,
    fechaEntrega: e.fechaEntrega,
    observacionEntrega: e.observacionEntrega,
    nombreUsuario: e.nombreUsuario,
  );
}
