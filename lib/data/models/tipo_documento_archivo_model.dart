import 'package:bosque_flutter/domain/entities/tipo_documento_archivo_entity.dart';

class TipoDocumentoArchivoModel {
  final int codTipoDocumento;
  final String nombre;
  final int estado;
  final int audUsuario;
  final DateTime? audFecha;
  final int usos;

  const TipoDocumentoArchivoModel({
    required this.codTipoDocumento,
    required this.nombre,
    this.estado = TipoDocumentoArchivoEntity.activo,
    this.audUsuario = 0,
    this.audFecha,
    this.usos = 0,
  });

  factory TipoDocumentoArchivoModel.fromJson(Map<String, dynamic> json) {
    int? entero(String clave) => (json[clave] as num?)?.toInt();
    return TipoDocumentoArchivoModel(
      codTipoDocumento: entero('codTipoDocumento') ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
      estado: entero('estado') ?? TipoDocumentoArchivoEntity.activo,
      audUsuario: entero('audUsuario') ?? 0,
      audFecha: DateTime.tryParse(json['audFecha']?.toString() ?? ''),
      usos: entero('usos') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'codTipoDocumento': codTipoDocumento,
    'nombre': nombre,
    'estado': estado,
    'audUsuario': audUsuario,
    'audFecha': audFecha?.toIso8601String(),
    'usos': usos,
  };

  Map<String, dynamic> toRegistroJson() => {
    'codTipoDocumento': codTipoDocumento,
    'nombre': nombre,
    'estado': estado,
    'audUsuario': audUsuario,
  };

  TipoDocumentoArchivoEntity toEntity() => TipoDocumentoArchivoEntity(
    codTipoDocumento: codTipoDocumento,
    nombre: nombre,
    estado: estado,
    audUsuario: audUsuario,
    audFecha: audFecha,
    usos: usos,
  );

  factory TipoDocumentoArchivoModel.fromEntity(TipoDocumentoArchivoEntity e) =>
      TipoDocumentoArchivoModel(
        codTipoDocumento: e.codTipoDocumento,
        nombre: e.nombre,
        estado: e.estado,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
        usos: e.usos,
      );
}
