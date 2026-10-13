/// Una línea de contenido de una caja (`tarc_contenido`): una fila del Excel original.
class ContenidoCajaEntity {
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
  });
}
