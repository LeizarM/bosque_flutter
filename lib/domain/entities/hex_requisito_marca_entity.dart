/// Un requisito para marcar en la app (`p_list_thex_Reporte` S): si se cumple,
/// si impide marcar y los textos del SP. No es un permiso: el SP vuelve a
/// validar al marcar.
class HexRequisitoMarcaEntity {
  /// `RELACION`, `CARGO`, `INICIO` u `HORARIO`.
  final String requisito;
  final bool cumple;
  final bool bloquea;
  final String titulo;
  final String detalle;
  final int orden;

  const HexRequisitoMarcaEntity({
    this.requisito = '',
    this.cumple = false,
    this.bloquea = false,
    this.titulo = '',
    this.detalle = '',
    this.orden = 0,
  });

  /// No se cumple y el SP dice que eso deja las teclas sin efecto.
  bool get impideMarcar => !cumple && bloquea;
}
