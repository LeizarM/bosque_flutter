/// Lector de importes que comparten los campos de dinero del módulo.
library;

/// Lee un importe escrito a mano: acepta "1.234,56" (lo que muestra la pantalla)
/// y "1234.56" (teclado numérico del teléfono, que a veces solo ofrece el
/// punto). Si aparecen los dos, el punto es el separador de miles.
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
