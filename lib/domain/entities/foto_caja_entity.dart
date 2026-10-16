/// Una foto o un PDF de caja (`tarc_cajaFoto`). Son opcionales: de 0 a
/// [maximo] por caja, entre fotos y PDF.
class FotoCajaEntity {
  static const int maximo = 3;

  final int codFoto;
  final int codCaja;

  /// Posición 1, 2 o 3.
  final int orden;

  /// Ruta en el servidor: cambia con cada reemplazo, así que sirve de clave de caché.
  final String? ruta;
  final int audUsuario;
  final DateTime? audFecha;

  const FotoCajaEntity({
    required this.codFoto,
    required this.codCaja,
    required this.orden,
    this.ruta,
    this.audUsuario = 0,
    this.audFecha,
  });

  /// El servidor nombra el archivo con la extensión de su formato real.
  bool get esPdf => (ruta ?? '').toLowerCase().endsWith('.pdf');
}
