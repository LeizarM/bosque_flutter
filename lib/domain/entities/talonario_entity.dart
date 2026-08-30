/// Un talonario físico. Tabla tmto_talonario.
///
/// [numeracionInicial]..[numeracionFinal] es el rango de folios; los lotes
/// generan bloques de 50. [nroTalonario] es ÚNICO A NIVEL GLOBAL, no por
/// tipo ni por empresa.
///
/// OJO con [estado]: está MUERTO, los 1035 registros de producción tienen '1'.
/// El campo útil es [codEstadoActual] / [estadoActual], que NO están guardados
/// en ninguna columna: el backend los deriva contando el log de eventos.
///
///   cierres  >= 1              -> Cerrado (terminal)
///   entregas == devoluciones   -> disponible, se puede entregar
///   entregas >  devoluciones   -> en poder de alguien, devolver o cerrar
class TalonarioEntity {
  BigInt codTalonario;
  BigInt codTipoRecibo;
  String nroTalonario;
  double costoBs;
  int numeracionInicial;
  int numeracionFinal;

  /// Vestigial: siempre '1'. Usar [estadoActual].
  String estado;
  BigInt codEmpresa;
  String observacion;
  BigInt audUsuario;
  DateTime? audFecha;

  // ---- solo lectura ----
  String sigla;
  String datoTipoNombre;
  String datoTipo;
  String datoEmpresa;
  String datoTalonario;

  /// Conteos del log de eventos, de los que sale el estado.
  int entregas;
  int devoluciones;
  int cierres;

  /// 1 Adquirido, 2 Entregado, 3 Devuelto, 4 Cerrado.
  int codEstadoActual;
  String estadoActual;

  /// Reemplazan la máscara de 4 caracteres del JSF ('0100', '0011', '0000').
  bool puedeEntregar;
  bool puedeDevolver;
  bool puedeCerrar;

  /// Quién lo tiene AHORA. Vacío si está disponible o cerrado.
  String datoDestinatario;

  TalonarioEntity({
    required this.codTalonario,
    required this.codTipoRecibo,
    required this.nroTalonario,
    required this.costoBs,
    required this.numeracionInicial,
    required this.numeracionFinal,
    required this.estado,
    required this.codEmpresa,
    required this.observacion,
    required this.audUsuario,
    this.audFecha,
    this.sigla = '',
    this.datoTipoNombre = '',
    this.datoTipo = '',
    this.datoEmpresa = '',
    this.datoTalonario = '',
    this.entregas = 0,
    this.devoluciones = 0,
    this.cierres = 0,
    this.codEstadoActual = 1,
    this.estadoActual = '',
    this.puedeEntregar = false,
    this.puedeDevolver = false,
    this.puedeCerrar = false,
    this.datoDestinatario = '',
  });

  /// Cantidad de recibos que cubre el talonario.
  int get cantidadRecibos => numeracionFinal - numeracionInicial + 1;

  bool get estaCerrado => codEstadoActual == 4;
  bool get estaEntregado => codEstadoActual == 2;

  /// No admite ninguna acción más.
  bool get sinAcciones => !puedeEntregar && !puedeDevolver && !puedeCerrar;
}
