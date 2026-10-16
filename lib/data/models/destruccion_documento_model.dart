import 'package:bosque_flutter/domain/entities/destruccion_documento_entity.dart';

class DestruccionDocumentoModel {
  final int codDestruccion;
  final int codCaja;
  final int? codContenido;
  final String? fechaDestruccion;
  final String? observacion;
  final int audUsuario;
  final DateTime? audFecha;
  final int numeroCaja;
  final int codArchivo;
  final String? nombreArchivo;
  final String? nombreTipoDocumento;
  final String? detalle;
  final String? gestion;
  final String? nombreUsuario;

  const DestruccionDocumentoModel({
    required this.codDestruccion,
    required this.codCaja,
    this.codContenido,
    this.fechaDestruccion,
    this.observacion,
    this.audUsuario = 0,
    this.audFecha,
    this.numeroCaja = 0,
    this.codArchivo = 0,
    this.nombreArchivo,
    this.nombreTipoDocumento,
    this.detalle,
    this.gestion,
    this.nombreUsuario,
  });

  factory DestruccionDocumentoModel.fromJson(Map<String, dynamic> json) {
    int? entero(String clave) => (json[clave] as num?)?.toInt();
    return DestruccionDocumentoModel(
      codDestruccion: entero('codDestruccion') ?? 0,
      codCaja: entero('codCaja') ?? 0,
      codContenido: entero('codContenido'),
      fechaDestruccion: json['fechaDestruccion'] as String?,
      observacion: json['observacion'] as String?,
      audUsuario: entero('audUsuario') ?? 0,
      audFecha: DateTime.tryParse(json['audFecha']?.toString() ?? ''),
      numeroCaja: entero('numeroCaja') ?? 0,
      codArchivo: entero('codArchivo') ?? 0,
      nombreArchivo: json['nombreArchivo'] as String?,
      nombreTipoDocumento: json['nombreTipoDocumento'] as String?,
      detalle: json['detalle'] as String?,
      gestion: json['gestion'] as String?,
      nombreUsuario: json['nombreUsuario'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'codDestruccion': codDestruccion,
    'codCaja': codCaja,
    'codContenido': codContenido,
    'fechaDestruccion': fechaDestruccion,
    'observacion': observacion,
    'audUsuario': audUsuario,
    'audFecha': audFecha?.toIso8601String(),
    'numeroCaja': numeroCaja,
    'codArchivo': codArchivo,
    'nombreArchivo': nombreArchivo,
    'nombreTipoDocumento': nombreTipoDocumento,
    'detalle': detalle,
    'gestion': gestion,
    'nombreUsuario': nombreUsuario,
  };

  DestruccionDocumentoEntity toEntity() => DestruccionDocumentoEntity(
    codDestruccion: codDestruccion,
    codCaja: codCaja,
    codContenido: codContenido,
    fechaDestruccion: fechaDestruccion,
    observacion: observacion,
    audUsuario: audUsuario,
    audFecha: audFecha,
    numeroCaja: numeroCaja,
    codArchivo: codArchivo,
    nombreArchivo: nombreArchivo,
    nombreTipoDocumento: nombreTipoDocumento,
    detalle: detalle,
    gestion: gestion,
    nombreUsuario: nombreUsuario,
  );

  factory DestruccionDocumentoModel.fromEntity(DestruccionDocumentoEntity e) =>
      DestruccionDocumentoModel(
        codDestruccion: e.codDestruccion,
        codCaja: e.codCaja,
        codContenido: e.codContenido,
        fechaDestruccion: e.fechaDestruccion,
        observacion: e.observacion,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
        numeroCaja: e.numeroCaja,
        codArchivo: e.codArchivo,
        nombreArchivo: e.nombreArchivo,
        nombreTipoDocumento: e.nombreTipoDocumento,
        detalle: e.detalle,
        gestion: e.gestion,
        nombreUsuario: e.nombreUsuario,
      );
}
