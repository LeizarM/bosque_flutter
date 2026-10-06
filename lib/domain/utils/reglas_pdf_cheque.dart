/// Reglas del documento PDF de un cheque que la pantalla comprueba **antes de
/// enviar**, para no mandar al servidor un archivo que ya se sabe que va a
/// rechazar. Son las del legacy (`ChequeManagedBean`, «Cargar Documento PDF»);
/// el servidor las repite al recibir el archivo.
///
/// Logica pura, sin Flutter ni Riverpod.
library;

/// El mayor tamano que acepta el legacy: 2.010.000 bytes. Su mensaje decia
/// «menos de 2 MegaByte»; el limite exacto lleva un poco de holgura sobre los
/// 2.000.000.
const int maxBytesPdfCheque = 2010000;

/// Los bytes en decimal (1 KB = 1.000 bytes, 1 MB = 1.000.000), como cuenta el
/// legacy su limite de «2 MegaByte».
const int _kb = 1000;
const int _mb = 1000000;

/// El tamano para leer de un vistazo: «850 bytes», «120 KB» o «1,4 MB» (coma
/// decimal, como se escribe en espanol).
String textoTamanoPdf(int bytes) {
  if (bytes < _kb) return '$bytes ${bytes == 1 ? 'byte' : 'bytes'}';
  final kb = (bytes / _kb).round();
  // 999.600 bytes redondean a 1000 KB: ya se lee mejor como megabytes.
  if (kb < 1000) return '$kb KB';
  return '${_megas(bytes, 1)} MB';
}

String _megas(int bytes, int decimales) =>
    (bytes / _mb).toStringAsFixed(decimales).replaceAll('.', ',');

/// El tamano de un archivo que se pasa del limite, junto al limite, en MB con un
/// decimal. Con un decimal el archivo y el limite podrian verse iguales
/// («2,0 MB» y «2,0 MB» cuando pesa 2.044.000 y el tope es 2.010.000): en ese
/// caso se agregan decimales hasta que se distingan, y si ni asi, bytes. Un
/// mensaje que dice «pesa 2,0 MB y el limite es 2,0 MB» no explica nada.
({String archivo, String limite}) tamanosParaExceso(int bytes) {
  for (var d = 1; d <= 3; d++) {
    final a = _megas(bytes, d);
    final l = _megas(maxBytesPdfCheque, d);
    if (a != l) return (archivo: '$a MB', limite: '$l MB');
  }
  return (archivo: '$bytes bytes', limite: '$maxBytesPdfCheque bytes');
}

/// El motivo por el que [nombre] / [tamanoBytes] no se puede cargar como PDF del
/// cheque, listo para mostrar, o null si sirve. Dice que paso y que hacer.
///
/// El orden es el del legacy: primero que sea un PDF, despues su tamano. La
/// extension no distingue mayusculas («FACTURA.PDF» sirve). Un archivo vacio no
/// esta en el legacy, pero un PDF de 0 bytes no abre nunca y cargarlo borraria
/// el anterior.
String? errorDeArchivoPdfCheque({
  required String nombre,
  required int tamanoBytes,
}) {
  final n = nombre.trim().isEmpty ? 'sin nombre' : nombre.trim();
  if (!n.toLowerCase().endsWith('.pdf')) {
    return 'El archivo «$n» no es un PDF. Elige un archivo con extensión .pdf.';
  }
  if (tamanoBytes <= 0) {
    return 'El archivo «$n» está vacío (0 bytes). Elige otro PDF.';
  }
  if (tamanoBytes > maxBytesPdfCheque) {
    final t = tamanosParaExceso(tamanoBytes);
    return 'El archivo «$n» pesa ${t.archivo} y el límite es ${t.limite}. '
        'Comprímelo o elige un PDF más liviano.';
  }
  return null;
}
