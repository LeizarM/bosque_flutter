/// Lo que responde `POST /cheque/pdf/subir` cuando el PDF quedo guardado.
class PdfChequeSubidaEntity {
  /// «18129.pdf»: el nombre con el que quedo en el servidor.
  final String nombreArchivo;

  /// Lo que pesa el archivo guardado.
  final int tamanoBytes;

  /// El cheque ya tenia un PDF y este lo sustituyo. Lo dice el servidor, que es
  /// quien lo sabe: la pantalla pudo haber consultado antes de que otro usuario
  /// cargara uno.
  final bool reemplazo;

  const PdfChequeSubidaEntity({
    required this.nombreArchivo,
    required this.tamanoBytes,
    required this.reemplazo,
  });
}
