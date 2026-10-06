/// Lo que responde `POST /cheque/talonario/validar` sobre un par talonario /
/// recibo manual. Es una consulta de apoyo del formulario de cheque: avisa antes
/// de guardar, pero quien decide es el servidor al guardar.
class TalonarioValidacionEntity {
  /// `false` solo cuando el par no corresponde a un talonario de la empresa.
  final bool valido;

  /// El motivo completo cuando [valido] es `false`, una o varias lineas
  /// separadas por `\n`. Se muestra tal cual.
  final String? mensaje;

  /// El dato util cuando el par es correcto (a que empresa pertenece el
  /// talonario y de que a que numero va). Puede faltar.
  final String? detalle;

  const TalonarioValidacionEntity({
    required this.valido,
    this.mensaje,
    this.detalle,
  });

  /// Sin nada que decir: es lo que se asume ante un 204 o un `data` nulo.
  static const TalonarioValidacionEntity sinObjeciones =
      TalonarioValidacionEntity(valido: true);
}
