/// Articulo congelado dentro de una propuesta de precios
/// (tabla tpr_articuloPropuesto). Nueve columnas, ni una mas.
///
/// OJO: aca NO hay campos de display. Titulo, obs, proveedor, familia, nombre
/// de sucursal, precios calculados, codCad y filaCod vienen por JOIN y viven en
/// los DTO ArticuloPropuesto*Dto del backend, nunca en esta entidad. El motivo:
/// el backend serializa el POJO completo y cada campo viaja como parametro de
/// p_abm_ArticuloProp; un campo de mas hace fallar el EXEC entero.
///
/// Ocho de las nueve columnas admiten NULL en la base, por eso el model llena
/// todo con valores por defecto antes de construir esta entidad.
class ArticuloPropuestoEntity {
  /// bigint IDENTITY, PK. La genera la base: en un alta vale BigInt.zero.
  final BigInt idArticulo;

  /// FK -> tpr_propuesta.idPropuesta.
  final BigInt idPropuesta;

  /// FK logica -> tpr_articulo.codArticulo. Es texto, no numero.
  final String codArticulo;

  /// FK logica -> tpr_producto.codigoFamilia. Es int, no bigint.
  final int codigoFamilia;

  /// Descripcion del articulo, varchar(150) en la base.
  ///
  /// Trampa historica: el parametro @datoArticulo del procedimiento estaba en
  /// varchar(100) y truncaba en silencio; el script tpr_ArticuloPropuesto.sql
  /// lo lleva a varchar(150). No mandar textos mas largos.
  final String datoArticulo;

  /// Cantidad de inventario. En la base es float(53) y en el backend
  /// BigDecimal; Dart no tiene BigDecimal, asi que viaja como double y puede
  /// arrastrar error de redondeo en comparaciones exactas.
  final double stock;

  /// Unidad tecnica de medida: toneladas por unidad. Divide precios, por eso
  /// un cero es peligroso. Tambien BigDecimal en el backend, double aca.
  final double utm;

  /// Usuario de auditoria.
  final BigInt audUsuario;

  /// Fecha de auditoria. El procedimiento la pisa siempre con GETDATE() en las
  /// acciones I/U/C/G: sirve para lectura y como filtro en la accion 'L'.
  final DateTime? audFecha;

  const ArticuloPropuestoEntity({
    required this.idArticulo,
    required this.idPropuesta,
    required this.codArticulo,
    required this.codigoFamilia,
    required this.datoArticulo,
    required this.stock,
    required this.utm,
    required this.audUsuario,
    this.audFecha,
  });

  /// Todavia no tiene IDENTITY asignado: es un alta sin guardar.
  bool get esNuevo => idArticulo == BigInt.zero;

  /// Ya quedo enganchado a una propuesta.
  bool get tienePropuesta => idPropuesta != BigInt.zero;

  /// Hay existencia disponible.
  bool get tieneStock => stock > 0;

  /// Etiqueta corta para chips y listas de movil.
  String get estadoStock => tieneStock ? 'Con stock' : 'Sin stock';

  /// Stock listo para mostrar, con dos decimales.
  String get stockLegible => stock.toStringAsFixed(2);

  /// La UTM sirve para dividir precios. En cero o negativa no se puede usar.
  bool get utmValida => utm > 0;

  /// UTM con cuatro decimales: suele ser una fraccion muy chica.
  String get utmLegible => utmValida ? utm.toStringAsFixed(4) : 'Sin UTM';

  /// Codigo mas descripcion en una sola linea, para tarjetas y encabezados.
  String get etiqueta {
    if (codArticulo.isEmpty) return datoArticulo;
    if (datoArticulo.isEmpty) return codArticulo;
    return '$codArticulo - $datoArticulo';
  }

  ArticuloPropuestoEntity copyWith({
    BigInt? idArticulo,
    BigInt? idPropuesta,
    String? codArticulo,
    int? codigoFamilia,
    String? datoArticulo,
    double? stock,
    double? utm,
    BigInt? audUsuario,
    DateTime? audFecha,
  }) => ArticuloPropuestoEntity(
    idArticulo: idArticulo ?? this.idArticulo,
    idPropuesta: idPropuesta ?? this.idPropuesta,
    codArticulo: codArticulo ?? this.codArticulo,
    codigoFamilia: codigoFamilia ?? this.codigoFamilia,
    datoArticulo: datoArticulo ?? this.datoArticulo,
    stock: stock ?? this.stock,
    utm: utm ?? this.utm,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
  );
}
