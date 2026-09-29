/// Porcentajes de IVA e IT que entran en la formula de precio
/// (tabla tpr_costoIvaIt). Hoy iva = 15.476 e it = 3.57.
///
/// OJO, es un SINGLETON: en produccion la tabla tiene una sola fila. Los demas
/// procedimientos del modulo la leen con (SELECT TOP 1 iva FROM tpr_costoIvaIt)
/// sin ORDER BY, asi que una segunda fila volveria no determinista el calculo
/// de TODOS los precios. La pantalla debe tratar esto como una ficha de
/// configuracion que se edita, no como una lista donde se agregan filas:
/// p_abm_costoIvaIt rechaza el alta de una segunda fila y rechaza borrar la
/// ultima.
///
/// OJO con [idPropuesta]: la columna existe en la tabla, pero hoy esta en null
/// y ningun procedimiento la usa para filtrar el calculo. Queda mapeada porque
/// la columna existe, no porque se use.
///
/// OJO con la precision: en la BD iva e it son float(53) y el backend los
/// maneja en BigDecimal justamente para no arrastrar el error binario de
/// valores como 15.476. Dart no tiene BigDecimal, asi que aca viajan en double
/// y vuelve a existir ese error. No hacer cuentas de dinero con estos valores
/// en el cliente: el precio final lo calcula el backend.
class CostoIvaItEntity {
  /// PK IDENTITY. En la BD es int, no bigint como el resto del modulo.
  final int idCii;

  /// FK logica a tpr_propuesta, sin constraint en la BD. Hoy siempre null
  /// (llega como BigInt.zero) y ningun procedimiento la filtra.
  final BigInt idPropuesta;

  /// Porcentaje de IVA en puntos porcentuales. Para 15,476% vale 15.476.
  final double iva;

  /// Porcentaje de IT en puntos porcentuales. Para 3,57% vale 3.57.
  final double it;

  final BigInt audUsuario;

  /// Fecha de auditoria. Si se manda null, el SP graba GETDATE().
  final DateTime? audFecha;

  const CostoIvaItEntity({
    required this.idCii,
    required this.idPropuesta,
    required this.iva,
    required this.it,
    required this.audUsuario,
    this.audFecha,
  });

  /// Suma iva + it, la misma cuenta que el SP devuelve como totalIvaIt en la
  /// accion 'V'. Se calcula aca para que tambien exista en la accion 'L', que
  /// no trae esa columna. Es solo para mostrar.
  double get totalIvaIt => iva + it;

  /// Fila todavia no guardada: el SP asigna el idCII en el alta.
  bool get esNuevo => idCii == 0;

  /// Fila sin propuesta asociada. Es el caso normal hoy.
  bool get sinPropuesta => idPropuesta == BigInt.zero;

  /// Ninguno de los dos impuestos cargado. Deja el precio sin recargo y en
  /// general indica una fila mal cargada.
  bool get sinImpuestos => iva <= 0 && it <= 0;

  /// IVA listo para mostrar, por ejemplo "15,476 %".
  String get ivaLegible => _porcentaje(iva);

  /// IT listo para mostrar, por ejemplo "3,57 %".
  String get itLegible => _porcentaje(it);

  /// Total listo para mostrar, por ejemplo "19,046 %".
  String get totalIvaItLegible => _porcentaje(totalIvaIt);

  /// Resumen de una linea para tarjetas y encabezados en movil.
  String get resumen => 'IVA $ivaLegible + IT $itLegible = $totalIvaItLegible';

  /// Formatea sin ceros de relleno y con coma decimal.
  static String _porcentaje(double valor) {
    var texto = valor.toStringAsFixed(3);
    if (texto.contains('.')) {
      texto = texto.replaceAll(RegExp(r'0+$'), '');
      texto = texto.replaceAll(RegExp(r'\.$'), '');
    }
    return '${texto.replaceAll('.', ',')} %';
  }

  CostoIvaItEntity copyWith({
    int? idCii,
    BigInt? idPropuesta,
    double? iva,
    double? it,
    BigInt? audUsuario,
    DateTime? audFecha,
  }) => CostoIvaItEntity(
    idCii: idCii ?? this.idCii,
    idPropuesta: idPropuesta ?? this.idPropuesta,
    iva: iva ?? this.iva,
    it: it ?? this.it,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
  );
}
