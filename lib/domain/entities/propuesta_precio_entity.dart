/// Cabecera de una propuesta de precios (tabla tpr_propuesta). De ella cuelgan
/// la autorizacion, los precios propuestos y el resto del detalle del modulo.
///
/// Espeja 1 a 1 las 10 columnas del POJO Propuesta del backend, ni una mas: ese
/// POJO se serializa completo y cada campo viaja como parametro de
/// p_abm_propuesta. Los campos de presentacion que llegan por JOIN o subconsulta
/// (el esAprobada de la rama C de p_list_propuesta) viven en el DTO, nunca aca.
///
/// OJO con [estado]: NO es el estado del flujo de aprobacion aunque el nombre lo
/// sugiera. Es una columna muerta. El estado real vive en la autorizacion
/// (AutorizacionPrecioEntity.esAprobada). Leer el comentario del campo antes de
/// mostrarlo o filtrar por el.
///
/// OJO con las fechas de auditoria: [audFecha] y [audFecGenerado] las escribe el
/// servidor con GETDATE(); lo que se mande desde el cliente se ignora en el alta
/// y en la modificacion.
class PropuestaPrecioEntity {
  /// bigint IDENTITY, PK. Vale cero mientras la propuesta no se inserta: el ABM
  /// devuelve el id real en @idGenerado.
  final BigInt idPropuesta;

  /// Empresa a la que pertenece la propuesta. Admite NULL en la base, por eso
  /// puede llegar en cero.
  final BigInt codEmpresa;

  /// tinyint. Tipo de propuesta: es un dominio de codigos, no una bandera.
  /// Se modela como int a proposito, nunca como bool.
  final int tipo;

  /// varchar(200). OJO al archivar historicos: tpr_propuestaEliminado.titulo es
  /// varchar(50) y trunca. Ver [tituloTruncaEnHistorico].
  final String titulo;

  /// varchar(250). OJO al archivar historicos: tpr_propuestaEliminado.obs es
  /// varchar(150) y trunca. Ver [obsTruncaEnHistorico].
  final String obs;

  /// tinyint. COLUMNA PRACTICAMENTE MUERTA: en la base de prueba 1121 de 1123
  /// filas la tienen en cero y los procedimientos la ignoran. El alta de
  /// p_abm_propuesta graba el literal 0 sin mirar el parametro y la
  /// modificacion ni siquiera la toca.
  ///
  /// El estado real del flujo NO esta aqui: vive en tpr_autorizacion.esAprobada
  /// (dominio v_tipos grupo 38: 0 en proceso, 1, 2, 3). Para saber como va una
  /// propuesta hay que leer su autorizacion.
  ///
  /// Se conserva porque la columna existe y el parametro sigue en el
  /// procedimiento. NO usar para decidir nada del negocio ni pintar estados.
  final int estado;

  /// Usuario que genero (exporto) la propuesta. Lo setea la accion B del ABM.
  /// Cero mientras no se genero.
  final BigInt audUsGenerado;

  /// Fecha de generacion. La accion B la pisa con GETDATE() del servidor.
  /// Null mientras la propuesta no se genero.
  final DateTime? audFecGenerado;

  /// Usuario que dio de alta o modifico la propuesta.
  final BigInt audUsuario;

  /// Fecha de auditoria. El procedimiento la escribe siempre con GETDATE() en
  /// las acciones I y U: lo que se mande desde el cliente se ignora. Sirve como
  /// filtro en el listado. Null si la base la tiene en NULL.
  final DateTime? audFecha;

  const PropuestaPrecioEntity({
    required this.idPropuesta,
    required this.codEmpresa,
    required this.tipo,
    required this.titulo,
    required this.obs,
    required this.estado,
    required this.audUsGenerado,
    required this.audFecGenerado,
    required this.audUsuario,
    required this.audFecha,
  });

  /// Todavia no existe en la base: el id lo asigna el IDENTITY en el alta.
  bool get esNueva => idPropuesta == BigInt.zero;

  /// Tiene empresa asignada. La columna admite NULL, asi que puede venir en cero.
  bool get tieneEmpresa => codEmpresa > BigInt.zero;

  /// Titulo listo para mostrar, sin dejar la celda vacia.
  String get tituloLegible =>
      titulo.trim().isEmpty ? 'Sin titulo' : titulo.trim();

  /// Hay observacion cargada.
  bool get tieneObs => obs.trim().isNotEmpty;

  /// Observacion lista para mostrar.
  String get obsLegible => tieneObs ? obs.trim() : 'Sin observaciones';

  /// El titulo supera los 50 caracteres que soporta tpr_propuestaEliminado y se
  /// va a truncar si la propuesta se archiva. Bandera para avisar en el form.
  bool get tituloTruncaEnHistorico => titulo.trim().length > 50;

  /// Idem para la observacion, que en el historico es varchar(150).
  bool get obsTruncaEnHistorico => obs.trim().length > 150;

  /// La propuesta ya fue generada (exportada) por alguien.
  bool get fueGenerada => audFecGenerado != null && audUsGenerado > BigInt.zero;

  /// Hay dato de auditoria de alta o modificacion para mostrar.
  bool get tieneAuditoria => audFecha != null && audUsuario > BigInt.zero;

  /// Fecha de generacion en dd/MM/yyyy, o guion si todavia no se genero.
  String get fecGeneradoLegible =>
      audFecGenerado != null ? _fechaCorta(audFecGenerado!) : '-';

  /// Fecha de auditoria en dd/MM/yyyy, o guion si no hay.
  String get audFechaLegible => audFecha != null ? _fechaCorta(audFecha!) : '-';

  /// Etiqueta corta del estado de generacion, para la tarjeta en movil.
  String get etiquetaGeneracion =>
      fueGenerada ? 'Generada el $fecGeneradoLegible' : 'Sin generar';

  static String _fechaCorta(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/'
      '${f.month.toString().padLeft(2, '0')}/'
      '${f.year}';

  PropuestaPrecioEntity copyWith({
    BigInt? idPropuesta,
    BigInt? codEmpresa,
    int? tipo,
    String? titulo,
    String? obs,
    int? estado,
    BigInt? audUsGenerado,
    DateTime? audFecGenerado,
    BigInt? audUsuario,
    DateTime? audFecha,
  }) => PropuestaPrecioEntity(
    idPropuesta: idPropuesta ?? this.idPropuesta,
    codEmpresa: codEmpresa ?? this.codEmpresa,
    tipo: tipo ?? this.tipo,
    titulo: titulo ?? this.titulo,
    obs: obs ?? this.obs,
    estado: estado ?? this.estado,
    audUsGenerado: audUsGenerado ?? this.audUsGenerado,
    audFecGenerado: audFecGenerado ?? this.audFecGenerado,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
  );
}
