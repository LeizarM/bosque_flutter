/// Un evento en la vida de un cheque (tabla tch_accion), con el nombre de su
/// estado. **No es la accion de garantias** (`AccionCbrEntity`).
///
/// Estados del catalogo v_tipos grupo 22 y quien los crea:
/// - `REC` recibido: el alta del cheque.
/// - `TRASP` traspaso: el traspaso masivo.
/// - `CUS` a cobranza: «A Custodio» / «Dar Custodia»; siempre con empleado.
/// - `DEV` devuelto; `VEN` / `ADE` nueva fecha de cobro (postergado /
///   adelantado).
/// - Cierres: `COB` cobrado (con verificacion); `CEF`, `CCH`, `PAP`, `DPR`
///   (sin verificacion). Cerrar pasa el cheque a CER.
/// - `DPB` y `VER` existen en el catalogo pero ningun boton de esta pantalla
///   los crea.
class AccionChequeEntity {
  static const String recibido = 'REC';
  static const String traspaso = 'TRASP';
  static const String custodia = 'CUS';
  static const String devuelto = 'DEV';
  static const String vencido = 'VEN';
  static const String adelantado = 'ADE';
  static const String cobrado = 'COB';
  static const String canjeadoEfectivo = 'CEF';
  static const String canjeadoCheque = 'CCH';
  static const String pagoParcial = 'PAP';
  static const String depositadoRechazado = 'DPR';

  /// PK, IDENTITY.
  final BigInt codAccion;

  /// Cheque al que pertenece. No hay FK en la base.
  final BigInt codCheque;

  /// Fecha y hora de la accion.
  final DateTime? fecha;

  final String estado;

  /// NULL en REC y TRASP; 0 en las acciones manuales; el responsable en CUS.
  final int? codEmpleado;

  /// Obligatorio al cerrar el cheque. En el JSON se llama `nroSAP`.
  final String? nroSAP;

  final String? observacion;

  /// Solo lectura: el backend lo toma del token.
  final int? audUsuario;
  final DateTime? audFecha;

  /// Nombre del estado («RECIBIDO», «A COBRANZA»...). Vacio si el codigo no
  /// esta en el catalogo: hay filas con estados fuera de el y el legacy las
  /// muestra igual.
  final String descripcion;

  /// Numero de fila, 1..n, dentro del historial del cheque.
  final int nro;

  const AccionChequeEntity({
    required this.codAccion,
    required this.codCheque,
    required this.fecha,
    required this.estado,
    required this.codEmpleado,
    required this.nroSAP,
    required this.observacion,
    required this.audUsuario,
    required this.audFecha,
    required this.descripcion,
    required this.nro,
  });

  /// Los estados que nacen de un boton y dejan huella en la rama K del
  /// detalle: borrarlos cambia lo que se puede hacer con el cheque.
  bool get esBase =>
      estado == recibido || estado == traspaso || estado == custodia;
}
