import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';

class CajaArchivoModel {
  final int codCaja;
  final int codArchivo;
  final int numero;
  final String? estante;
  final String? fila;
  final String? observacion;
  final int audUsuario;
  final DateTime? audFecha;
  final String? nombreArchivo;
  final int lineas;
  final int fotos;
  final int? anioDesde;
  final int? anioHasta;
  final int? codFotoPortada;
  final String? rutaPortada;

  const CajaArchivoModel({
    required this.codCaja,
    required this.codArchivo,
    required this.numero,
    this.estante,
    this.fila,
    this.observacion,
    this.audUsuario = 0,
    this.audFecha,
    this.nombreArchivo,
    this.lineas = 0,
    this.fotos = 0,
    this.anioDesde,
    this.anioHasta,
    this.codFotoPortada,
    this.rutaPortada,
  });

  factory CajaArchivoModel.fromJson(Map<String, dynamic> json) {
    int? entero(String clave) => (json[clave] as num?)?.toInt();
    return CajaArchivoModel(
      codCaja: entero('codCaja') ?? 0,
      codArchivo: entero('codArchivo') ?? 0,
      numero: entero('numero') ?? 0,
      estante: json['estante'] as String?,
      fila: json['fila'] as String?,
      observacion: json['observacion'] as String?,
      audUsuario: entero('audUsuario') ?? 0,
      audFecha: DateTime.tryParse(json['audFecha']?.toString() ?? ''),
      nombreArchivo: json['nombreArchivo'] as String?,
      lineas: entero('lineas') ?? 0,
      fotos: entero('fotos') ?? 0,
      anioDesde: entero('anioDesde'),
      anioHasta: entero('anioHasta'),
      codFotoPortada: entero('codFotoPortada'),
      rutaPortada: json['rutaPortada'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'codCaja': codCaja,
    'codArchivo': codArchivo,
    'numero': numero,
    'estante': estante,
    'fila': fila,
    'observacion': observacion,
    'audUsuario': audUsuario,
    'audFecha': audFecha?.toIso8601String(),
    'nombreArchivo': nombreArchivo,
    'lineas': lineas,
    'fotos': fotos,
    'anioDesde': anioDesde,
    'anioHasta': anioHasta,
    'codFotoPortada': codFotoPortada,
    'rutaPortada': rutaPortada,
  };

  Map<String, dynamic> toRegistroJson() => {
    'codCaja': codCaja,
    'codArchivo': codArchivo,
    'numero': numero,
    'estante': estante,
    'fila': fila,
    'observacion': observacion,
    'audUsuario': audUsuario,
  };

  CajaArchivoEntity toEntity() => CajaArchivoEntity(
    codCaja: codCaja,
    codArchivo: codArchivo,
    numero: numero,
    estante: estante,
    fila: fila,
    observacion: observacion,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreArchivo: nombreArchivo,
    lineas: lineas,
    fotos: fotos,
    anioDesde: anioDesde,
    anioHasta: anioHasta,
    codFotoPortada: codFotoPortada,
    rutaPortada: rutaPortada,
  );

  factory CajaArchivoModel.fromEntity(CajaArchivoEntity e) => CajaArchivoModel(
    codCaja: e.codCaja,
    codArchivo: e.codArchivo,
    numero: e.numero,
    estante: e.estante,
    fila: e.fila,
    observacion: e.observacion,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreArchivo: e.nombreArchivo,
    lineas: e.lineas,
    fotos: e.fotos,
    anioDesde: e.anioDesde,
    anioHasta: e.anioHasta,
    codFotoPortada: e.codFotoPortada,
    rutaPortada: e.rutaPortada,
  );
}
