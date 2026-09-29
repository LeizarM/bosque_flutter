/// Detalle de precios de una propuesta de reprecio (tabla tpr_precioPropuesta).
/// Una fila = un precio (tpr_precio) incluido en una propuesta (tpr_propuesta),
/// con su valor actual, su valor propuesto y el porcentaje aplicado.
///
/// OJO con el nombre del id: la columna es [idPrecioPropuesto] (terminada en "o"),
/// no "...Propuesta". El ABM legacy lo recibe con un parametro alias, pero el JSON
/// viaja con el nombre de la columna.
///
/// OJO con los denormalizados: [vpp], [listNum], [codSucursal] y [nombrePrecio]
/// son copias guardadas en la fila y estan desfasadas. En la base hay 4013 filas
/// donde [vpp] NO concuerda con su clasificacion padre. Para MOSTRAR hay que usar
/// los datos de tpr_clasificacionPrecio (vpp, listNum, codSucursal, nombrePrecio),
/// alcanzables por JOIN tpr_precio -> tpr_clasificacionPrecio. Nunca filtrar ni
/// reportar por los campos de esta entidad; se conservan solo porque el proc
/// p_abm_precioPropuesta los recibe e inserta.
///
/// Dart no tiene BigDecimal: el dinero ([precioActual], [precioPropuesto]) y el
/// [porcentaje] viajan en double. En la base son float(53).
class PrecioPropuestaEntity {
  /// PK, bigint IDENTITY. Columna real: idPrecioPropuesto (no "...Propuesta").
  final BigInt idPrecioPropuesto;

  /// FK a tpr_propuesta.idPropuesta.
  final BigInt idPropuesta;

  /// FK a tpr_precio.idPrecio.
  final BigInt idPrecio;

  /// TRAMPA DE TIPO: aqui la columna es varchar(15), mientras que en el resto del
  /// modulo (tpr_producto, tpr_precio, tpr_porcentaje, tpr_costoSug, tpr_articulo)
  /// codigoFamilia es int. Se mantiene String para no perder valores no numericos
  /// ni ceros a la izquierda. No convertirlo a int para comparar con otras tablas.
  final String codigoFamilia;

  /// Precio vigente al momento de armar la propuesta. Dinero en double.
  final double precioActual;

  /// Precio que se propone. Dinero en double.
  final double precioPropuesto;

  /// Porcentaje aplicado sobre el costo sugerido.
  final double porcentaje;

  /// DENORMALIZADO Y CORRUPTO. El dato bueno es tpr_clasificacionPrecio.codSucursal.
  final BigInt codSucursal;

  /// DENORMALIZADO Y CORRUPTO. Codigo de lista de precios del SAP. El dato bueno
  /// es tpr_clasificacionPrecio.listNum.
  final BigInt listNum;

  /// DENORMALIZADO. Copia del nombre de la lista de precios, puede estar desfasada.
  /// El dato bueno es tpr_clasificacionPrecio.nombrePrecio.
  final String nombrePrecio;

  /// DENORMALIZADO Y CORRUPTO: mal cargado en 4013 filas. Para mostrar, usar
  /// tpr_clasificacionPrecio.vpp. Nunca confiar en este valor.
  final int vpp;

  /// Usuario que grabo la fila (tb_usuario).
  final BigInt audUsuario;

  /// Fecha de auditoria. Solo lectura: el proc la pisa con GETDATE() en I y en U.
  final DateTime? audFecha;

  const PrecioPropuestaEntity({
    required this.idPrecioPropuesto,
    required this.idPropuesta,
    required this.idPrecio,
    required this.codigoFamilia,
    required this.precioActual,
    required this.precioPropuesto,
    required this.porcentaje,
    required this.codSucursal,
    required this.listNum,
    required this.nombrePrecio,
    required this.vpp,
    required this.audUsuario,
    this.audFecha,
  });

  /// Fila todavia no grabada: sirve para decidir entre insertar y actualizar.
  bool get esNuevo => idPrecioPropuesto == BigInt.zero;

  /// Diferencia absoluta entre lo propuesto y lo vigente.
  double get variacion => precioPropuesto - precioActual;

  /// Variacion en puntos porcentuales sobre el precio actual. Devuelve 0 si el
  /// precio actual es cero para no dividir por cero.
  double get variacionPorcentual =>
      precioActual == 0 ? 0.0 : (variacion / precioActual) * 100;

  bool get esAumento => precioPropuesto > precioActual;
  bool get esRebaja => precioPropuesto < precioActual;
  bool get sinCambio => precioPropuesto == precioActual;

  /// Estado legible del cambio, para chips o etiquetas de la grilla.
  String get estadoCambio {
    if (esAumento) return 'Aumento';
    if (esRebaja) return 'Rebaja';
    return 'Sin cambio';
  }

  /// Variacion lista para mostrar, con signo y dos decimales.
  String get variacionLegible {
    final signo = variacion > 0 ? '+' : '';
    return '$signo${variacion.toStringAsFixed(2)} '
        '($signo${variacionPorcentual.toStringAsFixed(2)}%)';
  }

  /// Porcentaje aplicado, listo para mostrar.
  String get porcentajeLegible => '${porcentaje.toStringAsFixed(2)}%';

  /// Marca de fila con datos denormalizados sospechosos. Si la pantalla trae la
  /// clasificacion por JOIN, hay que preferir esos valores a los de esta fila.
  bool get tieneDenormalizadosSospechosos =>
      vpp == 0 || listNum == BigInt.zero || nombrePrecio.isEmpty;

  PrecioPropuestaEntity copyWith({
    BigInt? idPrecioPropuesto,
    BigInt? idPropuesta,
    BigInt? idPrecio,
    String? codigoFamilia,
    double? precioActual,
    double? precioPropuesto,
    double? porcentaje,
    BigInt? codSucursal,
    BigInt? listNum,
    String? nombrePrecio,
    int? vpp,
    BigInt? audUsuario,
    DateTime? audFecha,
  }) => PrecioPropuestaEntity(
    idPrecioPropuesto: idPrecioPropuesto ?? this.idPrecioPropuesto,
    idPropuesta: idPropuesta ?? this.idPropuesta,
    idPrecio: idPrecio ?? this.idPrecio,
    codigoFamilia: codigoFamilia ?? this.codigoFamilia,
    precioActual: precioActual ?? this.precioActual,
    precioPropuesto: precioPropuesto ?? this.precioPropuesto,
    porcentaje: porcentaje ?? this.porcentaje,
    codSucursal: codSucursal ?? this.codSucursal,
    listNum: listNum ?? this.listNum,
    nombrePrecio: nombrePrecio ?? this.nombrePrecio,
    vpp: vpp ?? this.vpp,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
  );
}
