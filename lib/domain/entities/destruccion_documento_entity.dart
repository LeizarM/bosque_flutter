/// Un registro de la bitácora de destrucción (`tarc_destruccion`): documentos
/// que cumplieron su plazo de guarda y se trituraron. Una línea de la caja, o
/// la caja completa si [codContenido] es null. La fecha la pone el servidor.
class DestruccionDocumentoEntity {
  final int codDestruccion;
  final int codCaja;
  final int? codContenido;
  final String? fechaDestruccion;
  final String? observacion;
  final int audUsuario;
  final DateTime? audFecha;

  /// Solo lectura: la caja, el documento y quién lo registró.
  final int numeroCaja;
  final int codArchivo;
  final String? nombreArchivo;
  final String? nombreTipoDocumento;
  final String? detalle;
  final String? gestion;
  final String? nombreUsuario;

  const DestruccionDocumentoEntity({
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

  bool get cajaCompleta => codContenido == null;
}
