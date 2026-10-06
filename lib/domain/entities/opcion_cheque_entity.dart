/// Una opcion de un combo del modulo de cheques: el codigo que se guarda y el
/// texto que se muestra.
class OpcionChequeEntity {
  final String codigo;
  final String nombre;

  const OpcionChequeEntity({required this.codigo, required this.nombre});

  /// Nombre de [codigo] dentro de [opciones]; null si no esta.
  static String? nombreDe(List<OpcionChequeEntity> opciones, String? codigo) {
    if (codigo == null) return null;
    final buscado = codigo.trim();
    for (final o in opciones) {
      if (o.codigo.trim() == buscado) return o.nombre;
    }
    return null;
  }
}
