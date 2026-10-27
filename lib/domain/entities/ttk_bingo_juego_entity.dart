/// Un juego (ronda) del bingo con su figura: máscara de 0/1 de filas×columnas,
/// recorrida fila por fila.
class TtkBingoJuegoEntity {
  final BigInt? codJuego;
  final BigInt? codBingo;
  final int nroJuego;
  final String nombre;
  final String figura;

  /// Lo que se gana en este juego: «Se está jugando por …».
  final String? premio;
  final int filas;
  final int columnas;
  final bool conComodin;
  final int casillasFigura;
  final String estado;
  final String estadoTexto;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int bolillosMarcados;
  final int ganadoresConfirmados;
  final bool puedeEditarFigura;

  /// Mientras el juego no terminó: el premio también cambia en curso.
  final bool puedeEditarPremio;
  final bool puedeComenzar;
  final bool puedeFinalizar;

  /// Dos o más ganadores sin desempate: el juego no se cierra todavía.
  final bool empatePendiente;
  final BigInt? audUsuario;
  final DateTime? audFecha;

  const TtkBingoJuegoEntity({
    this.codJuego,
    this.codBingo,
    this.nroJuego = 0,
    this.nombre = '',
    this.figura = '',
    this.premio,
    this.filas = 5,
    this.columnas = 5,
    this.conComodin = true,
    this.casillasFigura = 0,
    this.estado = '',
    this.estadoTexto = '',
    this.fechaInicio,
    this.fechaFin,
    this.bolillosMarcados = 0,
    this.ganadoresConfirmados = 0,
    this.puedeEditarFigura = false,
    this.puedeEditarPremio = false,
    this.puedeComenzar = false,
    this.puedeFinalizar = false,
    this.empatePendiente = false,
    this.audUsuario,
    this.audFecha,
  });

  bool get enCurso => estado == 'EN_CURSO';

  TtkBingoJuegoEntity copyWith({
    String? nombre,
    String? figura,
    String? premio,
  }) => TtkBingoJuegoEntity(
    codJuego: codJuego,
    codBingo: codBingo,
    nroJuego: nroJuego,
    nombre: nombre ?? this.nombre,
    figura: figura ?? this.figura,
    premio: premio ?? this.premio,
    filas: filas,
    columnas: columnas,
    conComodin: conComodin,
    casillasFigura: casillasFigura,
    estado: estado,
    estadoTexto: estadoTexto,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    bolillosMarcados: bolillosMarcados,
    ganadoresConfirmados: ganadoresConfirmados,
    puedeEditarFigura: puedeEditarFigura,
    puedeEditarPremio: puedeEditarPremio,
    puedeComenzar: puedeComenzar,
    puedeFinalizar: puedeFinalizar,
    empatePendiente: empatePendiente,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );
}
