/// Un bingo visto por el empleado: cuántos cartones tiene, si puede elegir o
/// ver el en vivo, y el mensaje que le corresponde según el SP.
class TtkBingoParticipanteEntity {
  final BigInt? codBingo;
  final BigInt? codEvento;
  final String nombreEvento;
  final DateTime? fechaEvento;
  final String estado;
  final String estadoTexto;
  final int filas;
  final int columnas;
  final String? letras;
  final bool conComodin;
  final int nroJuegos;

  /// P en pantalla, I impreso, A ambos; [conAviso] si tiene el botón «¡Bingo!».
  final String modalidad;
  final bool conAviso;
  final int maxCartonesEmpleado;
  final int misCartones;
  final int cartonesDisponibles;
  final bool puedeElegir;
  final bool puedeVerEnVivo;
  final String mensaje;

  const TtkBingoParticipanteEntity({
    this.codBingo,
    this.codEvento,
    this.nombreEvento = '',
    this.fechaEvento,
    this.estado = '',
    this.estadoTexto = '',
    this.filas = 5,
    this.columnas = 5,
    this.letras,
    this.conComodin = true,
    this.nroJuegos = 0,
    this.modalidad = 'A',
    this.conAviso = false,
    this.maxCartonesEmpleado = 1,
    this.misCartones = 0,
    this.cartonesDisponibles = 0,
    this.puedeElegir = false,
    this.puedeVerEnVivo = false,
    this.mensaje = '',
  });
}
