/// Una casilla de un juego de un cartón, con lo necesario para dibujarla o
/// imprimirla: posición, número, comodín, si cae en la figura y si salió.
class TtkBingoCeldaEntity {
  final BigInt? codCarton;
  final BigInt? codBingo;
  final int nroCarton;
  final BigInt? codEmpleado;
  final String? nombreEmpleado;
  final int nroJuego;
  final String nombreJuego;
  final int posicion;
  final int fila;
  final int columna;
  final int numero;
  final bool esComodin;
  final bool enFigura;
  final bool marcado;

  const TtkBingoCeldaEntity({
    this.codCarton,
    this.codBingo,
    this.nroCarton = 0,
    this.codEmpleado,
    this.nombreEmpleado,
    this.nroJuego = 0,
    this.nombreJuego = '',
    this.posicion = 0,
    this.fila = 0,
    this.columna = 0,
    this.numero = 0,
    this.esComodin = false,
    this.enFigura = false,
    this.marcado = false,
  });
}
