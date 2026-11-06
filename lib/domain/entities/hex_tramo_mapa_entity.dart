/// Un pedazo del día 00:00–24:00 de un tipo de día: un tramo que paga, un
/// hueco que nadie paga o un cruce de dos tramos. Lo arma el SP; la app solo
/// lo dibuja.
class HexTramoMapaEntity {
  final String tipoDia;

  /// «Días hábiles», «Domingos» o «Feriados».
  final String textoTipoDia;
  final int orden;

  /// Minutos desde las 00:00 (0..1440), medio abierto: [desde, hasta).
  final int desdeMin;
  final int hastaMin;

  /// `HH:MM`; el fin del día llega como `24:00`.
  final String horaDesde;
  final String horaHasta;

  /// `TRAMO`, `HUECO`, `CRUCE` o `COMIDA` (la ventana de una comida, que va
  /// aparte de la barra de tramos).
  final String clase;
  final String? codigo;
  final String? leyenda;
  final double? multiplicador;

  /// Si es el tramo que se está proponiendo en el diálogo.
  final bool esPropuesto;

  /// En un hueco o un cruce: qué pasa y cómo arreglarlo; en una comida, cómo
  /// se paga. En palabras del SP.
  final String? texto;

  const HexTramoMapaEntity({
    this.tipoDia = '',
    this.textoTipoDia = '',
    this.orden = 0,
    this.desdeMin = 0,
    this.hastaMin = 0,
    this.horaDesde = '',
    this.horaHasta = '',
    this.clase = '',
    this.codigo,
    this.leyenda,
    this.multiplicador,
    this.esPropuesto = false,
    this.texto,
  });

  bool get esProblema => clase == 'HUECO' || clase == 'CRUCE';

  bool get esComida => clase == 'COMIDA';

  int get minutos => hastaMin - desdeMin;
}
