/// Una caja física (`tarc_caja`). El número solo es único dentro de su archivo.
class CajaArchivoEntity {
  final int codCaja;
  final int codArchivo;
  final int numero;
  final String? estante;
  final String? fila;
  final String? observacion;
  final int audUsuario;
  final DateTime? audFecha;

  /// Solo lectura: lo calcula el listado a partir del contenido y las fotos.
  final String? nombreArchivo;
  final int lineas;
  final int fotos;
  final int? anioDesde;
  final int? anioHasta;

  /// La foto de menor orden, para la miniatura del listado (null sin fotos).
  final int? codFotoPortada;
  final String? rutaPortada;

  const CajaArchivoEntity({
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

  bool get tieneUbicacion =>
      (estante?.trim().isNotEmpty ?? false) || (fila?.trim().isNotEmpty ?? false);
}
