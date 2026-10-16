/// Una línea de contenido de una caja (`tarc_contenido`): una fila del Excel original.
class ContenidoCajaEntity {
  /// Valores de [situacion]: en la caja, prestada (sola o con su caja) y
  /// destruida (sola o con su caja).
  static const String enLaCaja = 'C';
  static const String prestada = 'P';
  static const String destruida = 'X';

  final int codContenido;
  final int codCaja;
  final int codTipoDocumento;
  final int? codEmpresa;
  final String detalle;
  final String? gestion;

  /// Los deriva el servidor de [gestion]; el cliente no los envía.
  final int? anioDesde;
  final int? anioHasta;
  final String? observacion;
  final int audUsuario;
  final DateTime? audFecha;

  /// Solo lectura: nombres que trae el listado.
  final String? nombreTipoDocumento;
  final String? nombreEmpresa;

  /// Solo lectura: dónde está la línea ([enLaCaja], [prestada] o [destruida]),
  /// el préstamo abierto que la tiene afuera (el suyo o el de la caja
  /// completa) y las fechas como texto «dd/mm/aaaa hh:mm».
  final String situacion;
  final int? codPrestamo;
  final String? prestadoA;
  final String? fechaPrestamo;
  final String? fechaDestruccion;

  const ContenidoCajaEntity({
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
    this.situacion = enLaCaja,
    this.codPrestamo,
    this.prestadoA,
    this.fechaPrestamo,
    this.fechaDestruccion,
  });

  bool get estaEnLaCaja => situacion == enLaCaja;
  bool get estaPrestada => situacion == prestada;
  bool get estaDestruida => situacion == destruida;
}
