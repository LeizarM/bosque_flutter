/// Un valor que admite un parámetro con lista (por ejemplo, la empresa del
/// organigrama): [valor] es lo que se guarda; [texto] y [detalle] los redacta
/// el SP para que nadie tenga que saber qué significa un código.
class HexParametroOpcionEntity {
  final double valor;
  final String texto;
  final String? detalle;

  const HexParametroOpcionEntity({
    this.valor = 0,
    this.texto = '',
    this.detalle,
  });
}
