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
  final String situacion;
  final int? codPrestamo;
  final String? prestadoA;
  final String? fechaPrestamo;
  final String? fechaDestruccion;

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
    this.situacion = ContenidoCajaEntity.enLaCaja,
    this.codPrestamo,
    this.prestadoA,
    this.fechaPrestamo,
    this.fechaDestruccion,
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
      situacion: (json['situacion'] as String?) ?? ContenidoCajaEntity.enLaCaja,
      codPrestamo: entero('codPrestamo'),
      prestadoA: json['prestadoA'] as String?,
      fechaPrestamo: json['fechaPrestamo'] as String?,
      fechaDestruccion: json['fechaDestruccion'] as String?,
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
    'situacion': situacion,
    'codPrestamo': codPrestamo,
    'prestadoA': prestadoA,
    'fechaPrestamo': fechaPrestamo,
    'fechaDestruccion': fechaDestruccion,
  };

  /// Sin los años ni la situación: el SP deriva unos de la gestión y la otra
  /// de los préstamos y la bitácora de destrucción.
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
    situacion: situacion,
    codPrestamo: codPrestamo,
    prestadoA: prestadoA,
    fechaPrestamo: fechaPrestamo,
    fechaDestruccion: fechaDestruccion,
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
        situacion: e.situacion,
        codPrestamo: e.codPrestamo,
        prestadoA: e.prestadoA,
        fechaPrestamo: e.fechaPrestamo,
        fechaDestruccion: e.fechaDestruccion,
      );
}
