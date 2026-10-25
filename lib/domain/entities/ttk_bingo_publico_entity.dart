/// Estado público de un bingo: juego actual, su figura y el último bolillo.
/// Solo dice si ya hubo ganador (`hayGanador`), nunca quién.
class TtkBingoPublicoEntity {
  final BigInt? codBingo;
  final String nombreEvento;
  final String estado;
  final String estadoTexto;
  final int nroBolillos;
  final int filas;
  final int columnas;
  final String? letras;
  final bool conComodin;
  final int nroJuegos;
  final int? nroJuego;
  final String? nombreJuego;
  final String? figura;
  final String? estadoJuego;
  final int totalMarcados;
  final int? ultimoBolillo;
  final bool hayGanador;

  /// Juego en curso con el botón «¡Bingo!» prendido: solo avisa al encargado.
  final bool puedeAvisar;
  final String mensaje;

  const TtkBingoPublicoEntity({
    this.codBingo,
    this.nombreEvento = '',
    this.estado = '',
    this.estadoTexto = '',
    this.nroBolillos = 75,
    this.filas = 5,
    this.columnas = 5,
    this.letras,
    this.conComodin = true,
    this.nroJuegos = 0,
    this.nroJuego,
    this.nombreJuego,
    this.figura,
    this.estadoJuego,
    this.totalMarcados = 0,
    this.ultimoBolillo,
    this.hayGanador = false,
    this.puedeAvisar = false,
    this.mensaje = '',
  });
}
