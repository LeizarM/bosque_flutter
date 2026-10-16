import 'package:bosque_flutter/domain/entities/entrega_documento_entity.dart';

class EntregaDocumentoModel {
  final int codEntrega;
  final int codEmpleado;
  final String? fechaEntrega;
  final String? observacion;
  final int audUsuario;
  final DateTime? audFecha;
  final String? nombreEmpleado;
  final int cajas;
  final int documentos;
  final int pendientes;
  final String? fechaDevolucion;
  final String? nombreUsuario;

  const EntregaDocumentoModel({
    required this.codEntrega,
    required this.codEmpleado,
    this.fechaEntrega,
    this.observacion,
    this.audUsuario = 0,
    this.audFecha,
    this.nombreEmpleado,
    this.cajas = 0,
    this.documentos = 0,
    this.pendientes = 0,
    this.fechaDevolucion,
    this.nombreUsuario,
  });

  factory EntregaDocumentoModel.fromJson(Map<String, dynamic> json) {
    int? entero(String clave) => (json[clave] as num?)?.toInt();
    return EntregaDocumentoModel(
      codEntrega: entero('codEntrega') ?? 0,
      codEmpleado: entero('codEmpleado') ?? 0,
      fechaEntrega: json['fechaEntrega'] as String?,
      observacion: json['observacion'] as String?,
      audUsuario: entero('audUsuario') ?? 0,
      audFecha: DateTime.tryParse(json['audFecha']?.toString() ?? ''),
      nombreEmpleado: json['nombreEmpleado'] as String?,
      cajas: entero('cajas') ?? 0,
      documentos: entero('documentos') ?? 0,
      pendientes: entero('pendientes') ?? 0,
      fechaDevolucion: json['fechaDevolucion'] as String?,
      nombreUsuario: json['nombreUsuario'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'codEntrega': codEntrega,
    'codEmpleado': codEmpleado,
    'fechaEntrega': fechaEntrega,
    'observacion': observacion,
    'audUsuario': audUsuario,
    'audFecha': audFecha?.toIso8601String(),
    'nombreEmpleado': nombreEmpleado,
    'cajas': cajas,
    'documentos': documentos,
    'pendientes': pendientes,
    'fechaDevolucion': fechaDevolucion,
    'nombreUsuario': nombreUsuario,
  };

  EntregaDocumentoEntity toEntity() => EntregaDocumentoEntity(
    codEntrega: codEntrega,
    codEmpleado: codEmpleado,
    fechaEntrega: fechaEntrega,
    observacion: observacion,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreEmpleado: nombreEmpleado,
    cajas: cajas,
    documentos: documentos,
    pendientes: pendientes,
    fechaDevolucion: fechaDevolucion,
    nombreUsuario: nombreUsuario,
  );

  factory EntregaDocumentoModel.fromEntity(EntregaDocumentoEntity e) => EntregaDocumentoModel(
    codEntrega: e.codEntrega,
    codEmpleado: e.codEmpleado,
    fechaEntrega: e.fechaEntrega,
    observacion: e.observacion,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreEmpleado: e.nombreEmpleado,
    cajas: e.cajas,
    documentos: e.documentos,
    pendientes: e.pendientes,
    fechaDevolucion: e.fechaDevolucion,
    nombreUsuario: e.nombreUsuario,
  );
}
