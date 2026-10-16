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

  /// Fotos y PDF juntos: los tres lugares son compartidos.
  final int fotos;
  final int? anioDesde;
  final int? anioHasta;

  /// La foto de menor orden, para la miniatura del listado (null sin fotos;
  /// un PDF nunca es portada).
  final int? codFotoPortada;
  final String? rutaPortada;

  /// Solo lectura: el préstamo abierto de la caja completa y a quién, la fecha
  /// de destrucción de la caja completa (texto «dd/mm/aaaa hh:mm») y cuántas
  /// líneas están afuera o destruidas.
  final int? codPrestamoCaja;
  final String? prestadaA;
  final String? fechaPrestamo;
  final String? fechaDestruccion;
  final int prestados;
  final int destruidos;

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
    this.codPrestamoCaja,
    this.prestadaA,
    this.fechaPrestamo,
    this.fechaDestruccion,
    this.prestados = 0,
    this.destruidos = 0,
  });

  bool get tieneUbicacion =>
      (estante?.trim().isNotEmpty ?? false) || (fila?.trim().isNotEmpty ?? false);

  /// La caja entera salió con un préstamo que todavía no volvió.
  bool get prestadaCompleta => codPrestamoCaja != null;

  /// La caja entera figura en la bitácora de destrucción.
  bool get destruida => (fechaDestruccion ?? '').isNotEmpty;
}
