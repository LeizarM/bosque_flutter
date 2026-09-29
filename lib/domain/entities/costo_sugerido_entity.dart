/// Costo sugerido en USD por tonelada de una familia, dentro de una propuesta
/// de precios (tabla tpr_costoSug).
///
/// Es el piso de costo con el que despues se arma el precio de la propuesta:
/// hay una fila por par (propuesta, familia). El ABM trata la accion I como un
/// upsert sobre ese par, asi que volver a registrar la misma familia no duplica
/// la fila, la pisa.
///
/// OJO con el dinero: en la base la columna es float(53) y el backend la expone
/// como BigDecimal. Dart no tiene BigDecimal, aca viaja en [double], que es el
/// mismo flotante binario de la base: no comparar por igualdad y redondear a 2
/// decimales recien al momento de mostrar.
class CostoSugeridoEntity {
  /// PK. Vale BigInt.zero mientras la fila todavia no se inserto.
  final BigInt idCosSug;

  /// FK logica a tpr_propuesta.idPropuesta.
  final BigInt idPropuesta;

  /// FK a tpr_producto.codigoFamilia. En esta tabla es int, pero ojo: en
  /// tpr_precioPropuesta la misma columna es varchar(15).
  final int codigoFamilia;

  /// Costo sugerido en USD por tonelada. Ver la nota de precision de la clase.
  final double costoSug;

  /// Inicio de vigencia del costo.
  ///
  /// Trampa: en la accion I el procedimiento pisa esta columna con GETDATE(),
  /// tanto cuando inserta como cuando el upsert cae en update. Solo la accion U
  /// respeta el valor que se manda.
  final DateTime? fechaI;

  /// Usuario de auditoria.
  final BigInt audUsuario;

  /// Fecha de auditoria. La escribe siempre el procedimiento con GETDATE();
  /// desde la app es de solo lectura.
  final DateTime? audFecha;

  const CostoSugeridoEntity({
    required this.idCosSug,
    required this.idPropuesta,
    required this.codigoFamilia,
    required this.costoSug,
    this.fechaI,
    required this.audUsuario,
    this.audFecha,
  });

  /// Fila que todavia no se guardo en la base.
  bool get esNuevo => idCosSug == BigInt.zero;

  /// El costo ya esta colgado de una propuesta.
  bool get tienePropuesta => idPropuesta != BigInt.zero;

  /// Costo cargado. Un cero se trata como "todavia sin costo".
  bool get tieneCosto => costoSug > 0;

  /// Costo listo para mostrar, con la unidad del modulo.
  String get costoFormateado =>
      tieneCosto ? 'USD ${costoSug.toStringAsFixed(2)} /t' : 'Sin costo';

  /// Familia legible cuando todavia no se resolvio el nombre por JOIN.
  String get familiaLegible =>
      codigoFamilia > 0 ? 'Familia $codigoFamilia' : 'Sin familia';

  /// Inicio de vigencia en formato dd/mm/aaaa.
  String get vigenciaLegible =>
      fechaI != null ? _fechaCorta(fechaI!) : 'Sin fecha de vigencia';

  /// Ultima auditoria en formato dd/mm/aaaa.
  String get auditoriaLegible =>
      audFecha != null ? _fechaCorta(audFecha!) : 'Sin registro';

  static String _fechaCorta(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/'
      '${f.month.toString().padLeft(2, '0')}/'
      '${f.year}';

  CostoSugeridoEntity copyWith({
    BigInt? idCosSug,
    BigInt? idPropuesta,
    int? codigoFamilia,
    double? costoSug,
    DateTime? fechaI,
    BigInt? audUsuario,
    DateTime? audFecha,
  }) => CostoSugeridoEntity(
    idCosSug: idCosSug ?? this.idCosSug,
    idPropuesta: idPropuesta ?? this.idPropuesta,
    codigoFamilia: codigoFamilia ?? this.codigoFamilia,
    costoSug: costoSug ?? this.costoSug,
    fechaI: fechaI ?? this.fechaI,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
  );
}
