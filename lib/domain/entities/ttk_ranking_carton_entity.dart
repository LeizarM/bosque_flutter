/// Avance de un cartón en el juego en curso (ranking del panel o verificación
/// de un cartón gritado). `esNuevo` indica que completó con el último bolillo.
class TtkRankingCartonEntity {
  final BigInt? codCarton;
  final int nroCarton;
  final BigInt? codEmpleado;
  final String? nombreEmpleado;
  final int? nroJuego;
  final int aciertos;
  final int totalFigura;
  final int faltantes;
  final bool esBingo;
  final int? ordenBingo;
  final int? bolilloBingo;
  final bool esNuevo;
  final bool esGanadorConfirmado;
  final int puesto;

  /// El dueño juega con el cartón impreso.
  final bool impreso;
  final String mensaje;

  const TtkRankingCartonEntity({
    this.codCarton,
    this.nroCarton = 0,
    this.codEmpleado,
    this.nombreEmpleado,
    this.nroJuego,
    this.aciertos = 0,
    this.totalFigura = 0,
    this.faltantes = 0,
    this.esBingo = false,
    this.ordenBingo,
    this.bolilloBingo,
    this.esNuevo = false,
    this.esGanadorConfirmado = false,
    this.puesto = 0,
    this.impreso = false,
    this.mensaje = '',
  });

  /// Avance de 0 a 1 para dibujar la barra.
  double get avance =>
      totalFigura <= 0 ? 0 : (aciertos / totalFigura).clamp(0.0, 1.0);
}
