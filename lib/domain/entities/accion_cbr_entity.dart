/// Un evento en la vida de una garantia (tabla tcbr_accion).
///
/// Estados del catalogo v_tipos grupo 29:
/// - `REG` registrado: lo crea el alta de la garantia, nunca a mano.
/// - `TRASP` traspaso a custodia: lo crea el traspaso masivo, nunca a mano.
/// - `EXT` extension: lo crea el flujo de extension, que ademas mueve la fecha.
/// - `NOT` nota: libre, no exige traspaso.
/// - `CER` cerrado: da de baja la garantia; exige el traspaso previo.
///
/// Despues del alta solo se edita la [observacion].
class AccionCbrEntity {
  static const String registro = 'REG';
  static const String traspaso = 'TRASP';
  static const String extension = 'EXT';
  static const String nota = 'NOT';
  static const String cierre = 'CER';

  /// Los unicos estados que se cargan a mano. Los otros tres los crean sus
  /// propios flujos, y el procedimiento rechaza el intento.
  static const List<String> manuales = [nota, cierre];

  /// PK, IDENTITY. Cero en una accion que todavia no se guardo.
  final BigInt codAccion;
  final BigInt codGarantia;
  final DateTime? fecha;
  final String estado;
  final String? observacion;

  /// Solo lectura: el backend lo toma del token.
  final int audUsuario;
  final DateTime? audFecha;

  const AccionCbrEntity({
    required this.codAccion,
    required this.codGarantia,
    required this.fecha,
    required this.estado,
    required this.observacion,
    required this.audUsuario,
    required this.audFecha,
  });

  bool get esNueva => codAccion == BigInt.zero;

  /// REG y TRASP son la base del circuito: borrarlas descuadra el traspaso.
  bool get esBase => estado == registro || estado == traspaso;

  AccionCbrEntity copyWith({String? observacion}) => AccionCbrEntity(
    codAccion: codAccion,
    codGarantia: codGarantia,
    fecha: fecha,
    estado: estado,
    observacion: observacion ?? this.observacion,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );
}
