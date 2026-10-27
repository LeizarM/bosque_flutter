/// Estado público de un bingo: juego actual, su figura, premio, regla de
/// desempate y el último bolillo. Los ganadores van en el estado público.
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
  final String? premio;

  /// «Se está jugando por …» en curso o «Premio: …» con ganador (del SP).
  final String? textoPremio;
  final String? reglaEmpate;

  /// «Si hay empate: …» o, con más de un ganador, «¡Empate! …» (del SP).
  final String? textoEmpate;
  final int nroGanadores;
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
    this.premio,
    this.textoPremio,
    this.reglaEmpate,
    this.textoEmpate,
    this.nroGanadores = 0,
    this.mensaje = '',
  });
}
