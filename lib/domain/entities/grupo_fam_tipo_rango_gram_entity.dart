/// Puente entre grupo de familia SAP y tipo de papel
/// (tabla tpr_grupoFamTipoRangoGram). Dice que rango de gramaje le corresponde
/// a cada par (grupo de familia, tipo).
///
/// OJO: la tabla es un HEAP, no tiene PRIMARY KEY ni columna IDENTITY. La fila
/// se identifica por su clave natural ([idGrpFamiliaSap], [idTipo]), unica en
/// la base. Por eso esta entity NO tiene campo id: no hay ninguno que traer y
/// el ABM tampoco devuelve un id generado. Para listas use [claveNatural].
///
/// OJO 2: las tres columnas de id son int NULL en esta tabla, aunque en sus
/// tablas padre (tpr_grupoFamiliaSap, tpr_tipo, tpr_RangoGramaje) las llaves
/// son bigint. El tipo sigue a la columna real, por eso aca son int y no
/// BigInt; quien traiga un id del padre como BigInt debe estrecharlo antes.
class GrupoFamTipoRangoGramEntity {
  /// Parte 1 de la clave natural. int NULL en la tabla, bigint en el padre
  /// tpr_grupoFamiliaSap.idGrpFamiliaSap.
  final int idGrpFamiliaSap;

  /// Parte 2 de la clave natural. Tipo de papel: Liviano, Mediano o Pesado.
  /// int NULL en la tabla, bigint en el padre tpr_tipo.idTipo.
  final int idTipo;

  /// Unico dato editable de la fila: el rango de gramaje asignado al par.
  /// int NULL en la tabla, bigint en el padre tpr_RangoGramaje.idRangoGram.
  final int idRangoGram;

  /// Usuario que hizo el ultimo movimiento.
  final BigInt audUsuario;

  /// Solo lectura: el SP de ABM ignora lo que se le mande y siempre estampa
  /// GETDATE(). Puede venir null porque la columna admite NULL.
  final DateTime? audFecha;

  const GrupoFamTipoRangoGramEntity({
    required this.idGrpFamiliaSap,
    required this.idTipo,
    required this.idRangoGram,
    required this.audUsuario,
    this.audFecha,
  });

  /// Clave natural en texto. Sirve como Key de widget en listas y tablas,
  /// justamente porque la tabla no tiene PK.
  String get claveNatural => '$idGrpFamiliaSap-$idTipo';

  /// La fila apunta a un grupo y a un tipo validos.
  bool get claveNaturalValida => idGrpFamiliaSap > 0 && idTipo > 0;

  /// El par ya tiene un rango de gramaje asignado.
  bool get tieneRangoAsignado => idRangoGram > 0;

  /// Estado legible de la asignacion, para chips o columnas de estado.
  String get estadoAsignacion =>
      tieneRangoAsignado ? 'Rango asignado' : 'Sin rango asignado';

  /// Fecha de auditoria lista para mostrar. Devuelve '-' cuando viene null.
  String get audFechaLegible {
    final f = audFecha;
    if (f == null) return '-';
    final dia = f.day.toString().padLeft(2, '0');
    final mes = f.month.toString().padLeft(2, '0');
    final hora = f.hour.toString().padLeft(2, '0');
    final min = f.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${f.year} $hora:$min';
  }

  GrupoFamTipoRangoGramEntity copyWith({
    int? idGrpFamiliaSap,
    int? idTipo,
    int? idRangoGram,
    BigInt? audUsuario,
    DateTime? audFecha,
  }) => GrupoFamTipoRangoGramEntity(
    idGrpFamiliaSap: idGrpFamiliaSap ?? this.idGrpFamiliaSap,
    idTipo: idTipo ?? this.idTipo,
    idRangoGram: idRangoGram ?? this.idRangoGram,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
  );
}
