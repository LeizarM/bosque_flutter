/// Familia de producto (tabla tpr_producto). Es el nucleo del catalogo del
/// modulo de Precios: de ella cuelgan los precios, los porcentajes y los
/// costos sugeridos.
///
/// OJO con la llave: [codigoFamilia] es la PK, es int y NO es autogenerada.
/// El usuario la escribe al dar de alta y el ABM rechaza el alta si viene en 0
/// o si el codigo ya existe.
///
/// Los nombres legibles (proveedor SAP, grupo de familia, presentacion, color,
/// tipo, rango de gramaje) NO estan aca: viven en el listado con descripciones
/// del backend. Esta entity es el reflejo crudo de las 14 columnas de la tabla.
class ProductoFamiliaEntity {
  /// PK de tpr_producto. NO es autogenerada: la carga el usuario en el alta.
  final int codigoFamilia;

  /// FK -> tpr_grupoFamiliaSap. 0 significa sin grupo de familia SAP asignado.
  final BigInt idGrpFamiliaSap;

  /// FK -> tpr_proveedorExtSap. 0 significa sin proveedor SAP asignado.
  final BigInt idProveedorSap;

  /// FK -> tpr_presentacion.
  final BigInt idPresentacion;

  /// FK -> tpr_tipo.
  final BigInt idTipo;

  /// FK -> tpr_RangoGramaje.
  ///
  /// OJO con el nombre: la columna y el parametro del SP se llaman
  /// `idRangoGram`, NO `idRangoGramaje`. El modelo viejo usaba el nombre largo
  /// y por eso nunca coincidia con el parametro.
  final BigInt idRangoGram;

  /// varchar(50). Hoy esta 100% vacia en la base de produccion: la pantalla la
  /// va a mostrar siempre en blanco y eso NO es un error de mapeo.
  final String formato;

  /// varchar(50). Texto, no numero. Igual que [formato], hoy esta 100% vacia
  /// en la base de produccion.
  final String gramaje;

  /// FK -> tpr_color.
  final BigInt idColor;

  /// 1 = activa, 0 = inactiva. Se deja como entero y no como bool porque en
  /// este modulo todos los estados son enteros y el ABM los compara contra 1.
  final int estado;

  /// Costo por tonelada metrica. Es dinero.
  ///
  /// OJO con la precision: en Java es BigDecimal y Dart no tiene BigDecimal, asi
  /// que el dinero viaja en double y puede perder centavos por representacion
  /// binaria. Mostrarlo siempre redondeado a 2 decimales, nunca crudo.
  ///
  /// Es de SOLO LECTURA desde esta pantalla: ninguna rama del ABM lo escribe
  /// (el alta lo fuerza a 0 y la modificacion no lo toca). Lo mueven las
  /// propuestas de precio.
  final double costoTM;

  /// FK -> tpr_propuesta. Ultima propuesta aprobada de la familia. 0 significa
  /// que todavia no tiene ninguna.
  ///
  /// Tambien es de SOLO LECTURA desde esta pantalla: el alta lo deja en null y
  /// la modificacion no lo toca.
  final BigInt idPropuestaAprobada;

  /// Usuario que hizo el ultimo movimiento.
  final BigInt audUsuario;

  /// Fecha del ultimo movimiento. La pisa siempre el SP con GETDATE(), por eso
  /// solo sirve para mostrar.
  final DateTime? audFecha;

  const ProductoFamiliaEntity({
    required this.codigoFamilia,
    required this.idGrpFamiliaSap,
    required this.idProveedorSap,
    required this.idPresentacion,
    required this.idTipo,
    required this.idRangoGram,
    required this.formato,
    required this.gramaje,
    required this.idColor,
    required this.estado,
    required this.costoTM,
    required this.idPropuestaAprobada,
    required this.audUsuario,
    this.audFecha,
  });

  /// Familia habilitada para operar.
  bool get esActiva => estado == 1;

  /// Estado listo para mostrar en la tabla o en el chip de la tarjeta.
  String get estadoLegible => esActiva ? 'Activa' : 'Inactiva';

  /// Codigo de familia listo para mostrar.
  String get codigoLegible => codigoFamilia.toString();

  /// Costo por tonelada redondeado a 2 decimales. Evita mostrar la basura
  /// binaria del double.
  String get costoTmLegible => costoTM.toStringAsFixed(2);

  /// La familia todavia no tiene costo cargado por una propuesta.
  bool get sinCosto => costoTM <= 0;

  /// La familia ya tiene una propuesta de precio aprobada.
  bool get tienePropuestaAprobada => idPropuestaAprobada > BigInt.zero;

  /// El grupo de familia SAP quedo sin asignar (acciones F del ABM).
  bool get sinGrupoFamiliaSap => idGrpFamiliaSap <= BigInt.zero;

  /// El proveedor extranjero SAP quedo sin asignar (accion G del ABM).
  bool get sinProveedorSap => idProveedorSap <= BigInt.zero;

  /// Formato listo para mostrar. La columna esta vacia en toda la base, asi que
  /// se muestra un guion en lugar de una celda en blanco.
  String get formatoLegible => formato.trim().isEmpty ? '-' : formato;

  /// Gramaje listo para mostrar. Mismo caso que [formatoLegible].
  String get gramajeLegible => gramaje.trim().isEmpty ? '-' : gramaje;

  ProductoFamiliaEntity copyWith({
    int? codigoFamilia,
    BigInt? idGrpFamiliaSap,
    BigInt? idProveedorSap,
    BigInt? idPresentacion,
    BigInt? idTipo,
    BigInt? idRangoGram,
    String? formato,
    String? gramaje,
    BigInt? idColor,
    int? estado,
    double? costoTM,
    BigInt? idPropuestaAprobada,
    BigInt? audUsuario,
    DateTime? audFecha,
  }) => ProductoFamiliaEntity(
    codigoFamilia: codigoFamilia ?? this.codigoFamilia,
    idGrpFamiliaSap: idGrpFamiliaSap ?? this.idGrpFamiliaSap,
    idProveedorSap: idProveedorSap ?? this.idProveedorSap,
    idPresentacion: idPresentacion ?? this.idPresentacion,
    idTipo: idTipo ?? this.idTipo,
    idRangoGram: idRangoGram ?? this.idRangoGram,
    formato: formato ?? this.formato,
    gramaje: gramaje ?? this.gramaje,
    idColor: idColor ?? this.idColor,
    estado: estado ?? this.estado,
    costoTM: costoTM ?? this.costoTM,
    idPropuestaAprobada: idPropuestaAprobada ?? this.idPropuestaAprobada,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
  );
}
