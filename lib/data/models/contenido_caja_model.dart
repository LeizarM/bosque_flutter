import 'package:bosque_flutter/domain/entities/contenido_caja_entity.dart';

class ContenidoCajaModel {
  final int codContenido;
  final int codCaja;
  final int codTipoDocumento;
  final int? codEmpresa;
  final String detalle;
  final String? gestion;
  final int? anioDesde;
  final int? anioHasta;
  final String? observacion;
  final int audUsuario;
  final DateTime? audFecha;
  final String? nombreTipoDocumento;
  final String? nombreEmpresa;

  const ContenidoCajaModel({
    required this.codContenido,
    required this.codCaja,
    required this.codTipoDocumento,
    this.codEmpresa,
    required this.detalle,
    this.gestion,
    this.anioDesde,
    this.anioHasta,
    this.observacion,
    this.audUsuario = 0,
    this.audFecha,
    this.nombreTipoDocumento,
    this.nombreEmpresa,
  });

  factory ContenidoCajaModel.fromJson(Map<String, dynamic> json) {
    int? entero(String clave) => (json[clave] as num?)?.toInt();
    return ContenidoCajaModel(
      codContenido: entero('codContenido') ?? 0,
      codCaja: entero('codCaja') ?? 0,
      codTipoDocumento: entero('codTipoDocumento') ?? 0,
      codEmpresa: entero('codEmpresa'),
      detalle: (json['detalle'] ?? '').toString(),
      gestion: json['gestion'] as String?,
      anioDesde: entero('anioDesde'),
      anioHasta: entero('anioHasta'),
      observacion: json['observacion'] as String?,
      audUsuario: entero('audUsuario') ?? 0,
      audFecha: DateTime.tryParse(json['audFecha']?.toString() ?? ''),
      nombreTipoDocumento: json['nombreTipoDocumento'] as String?,
      nombreEmpresa: json['nombreEmpresa'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'codContenido': codContenido,
    'codCaja': codCaja,
    'codTipoDocumento': codTipoDocumento,
    'codEmpresa': codEmpresa,
    'detalle': detalle,
    'gestion': gestion,
    'anioDesde': anioDesde,
    'anioHasta': anioHasta,
    'observacion': observacion,
    'audUsuario': audUsuario,
    'audFecha': audFecha?.toIso8601String(),
    'nombreTipoDocumento': nombreTipoDocumento,
    'nombreEmpresa': nombreEmpresa,
  };

  /// Sin los años: el SP los deriva de la gestión.
  Map<String, dynamic> toRegistroJson() => {
    'codContenido': codContenido,
    'codCaja': codCaja,
    'codTipoDocumento': codTipoDocumento,
    'codEmpresa': codEmpresa,
    'detalle': detalle,
    'gestion': gestion,
    'observacion': observacion,
    'audUsuario': audUsuario,
  };

  ContenidoCajaEntity toEntity() => ContenidoCajaEntity(
    codContenido: codContenido,
    codCaja: codCaja,
    codTipoDocumento: codTipoDocumento,
    codEmpresa: codEmpresa,
    detalle: detalle,
    gestion: gestion,
    anioDesde: anioDesde,
    anioHasta: anioHasta,
    observacion: observacion,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreTipoDocumento: nombreTipoDocumento,
    nombreEmpresa: nombreEmpresa,
  );

  factory ContenidoCajaModel.fromEntity(ContenidoCajaEntity e) =>
      ContenidoCajaModel(
        codContenido: e.codContenido,
        codCaja: e.codCaja,
        codTipoDocumento: e.codTipoDocumento,
        codEmpresa: e.codEmpresa,
        detalle: e.detalle,
        gestion: e.gestion,
        anioDesde: e.anioDesde,
        anioHasta: e.anioHasta,
        observacion: e.observacion,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
        nombreTipoDocumento: e.nombreTipoDocumento,
        nombreEmpresa: e.nombreEmpresa,
      );
}
