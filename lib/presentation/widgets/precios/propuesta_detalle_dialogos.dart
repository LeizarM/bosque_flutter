/// El lector de importes que comparten los campos de dinero del modulo.
///
/// Aca estaba tambien el formulario de la cabecera de una propuesta (titulo y
/// observaciones), que solo usaba la pantalla "Detalle de Propuesta". Esa
/// pantalla se quito el 2026-09-25: desde el menu se abria vacia y nada de la
/// app le pasaba una propuesta, asi que el formulario tampoco era alcanzable.
library;

/// Lee un importe escrito a mano, aceptando las dos formas en que la gente lo
/// escribe.
///
/// "1.234,56" es lo que la pantalla muestra y lo que alguien copia y pega;
/// "1234.56" es lo que sale del teclado numerico del telefono, que en varios
/// dispositivos solo ofrece el punto. Distinguirlos por cual aparece: si estan
/// los dos, el punto es el separador de miles.
double? importeDesdeTexto(String texto) {
  var limpio = texto.trim();
  if (limpio.isEmpty) return null;

  final tieneComa = limpio.contains(',');
  final tienePunto = limpio.contains('.');
  if (tieneComa && tienePunto) {
    limpio = limpio.replaceAll('.', '').replaceAll(',', '.');
  } else if (tieneComa) {
    limpio = limpio.replaceAll(',', '.');
  }
  return double.tryParse(limpio);
}
