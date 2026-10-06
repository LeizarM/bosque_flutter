/// Lo que responde `POST /cheque/pdf/estado`: si el cheque tiene un PDF cargado
/// y, si lo tiene, como se llama, cuanto pesa y cuando se cargo.
///
/// Es un dato de apoyo del servidor, no una tabla: el archivo vive en el disco
/// del servidor y nada lo registra en `tch_cheque`.
class PdfChequeEstadoEntity {
  final bool existe;

  /// «18129.pdf»: como lo guarda el servidor. Se descarga como `18129_.pdf`.
  final String nombreArchivo;

  /// Null si no hay archivo o el servidor no lo informo.
  final int? tamanoBytes;

  /// Cuando se cargo el archivo vigente; null si no hay archivo o no se informo.
  final DateTime? fechaModificacion;

  const PdfChequeEstadoEntity({
    required this.existe,
    this.nombreArchivo = '',
    this.tamanoBytes,
    this.fechaModificacion,
  });

  /// El cheque no tiene PDF: lo que se asume ante un 204 o un `data` nulo.
  static const PdfChequeEstadoEntity sinArchivo = PdfChequeEstadoEntity(
    existe: false,
  );
}
