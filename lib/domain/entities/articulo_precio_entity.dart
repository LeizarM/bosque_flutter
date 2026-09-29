/// Articulo del catalogo de precios (tabla tpr_articulo).
///
/// Son EXACTAMENTE las 10 columnas de la tabla, ni una mas: el backend
/// serializa este objeto y cada campo viaja como un parametro del
/// procedimiento p_abm_articulo, de modo que un campo inventado rompe el EXEC
/// entero. Los datos de solo lectura que llegan de los JOIN (precio,
/// disponible, codCiudad, grupo de familia SAP) pertenecen a otra entidad y
/// nunca a esta.
class ArticuloPrecioEntity {
  /// PK varchar(50) y NO es autonumerica. El codigo lo entrega el usuario o la
  /// sincronizacion con SAP, asi que en el alta viaja siempre lleno y el
  /// backend devuelve idGenerado en 0. Nunca tratarlo como numerico.
  ///
  /// OJO: el parametro del procedimiento esta declarado varchar(100), mas ancho
  /// que la columna varchar(50). Un codigo de mas de 50 caracteres pasa la
  /// validacion del procedimiento y explota recien en el INSERT; validar en la
  /// pantalla con [codigoExcedeLargo].
  final String codArticulo;

  /// FK logica hacia tpr_producto.codigoFamilia. No hay constraint declarada en
  /// la base: puede quedar apuntando a un producto que ya no existe.
  final int codigoFamilia;

  /// Descripcion del articulo. Es el campo por el que busca el listado con LIKE.
  final String datoArt;

  /// Descripcion extendida o alterna del articulo.
  final String datoArtExt;

  /// Cantidad con decimales (puede haber fracciones de resma). En el backend es
  /// BigDecimal para no perder precision; Dart no tiene BigDecimal, aqui va
  /// como double.
  final double stock;

  /// Unidad tecnica de medida usada en el calculo de precios. Mismo caso que
  /// [stock]: BigDecimal en el backend, double aqui.
  final double utm;

  /// La alimenta la sincronizacion con SAP, no la pantalla de ABM.
  ///
  /// OJO: el listado principal (rama 'L') NO devuelve esta columna, asi que
  /// llega vacia aunque la base tenga valor. El procedimiento la conserva con
  /// ISNULL solo cuando recibe NULL, por eso el model manda null en vez de
  /// cadena vacia al guardar.
  final String unidadMedida;

  /// Gramaje que trae SAP. Es NUMERICO, no texto: el modelo viejo lo declaraba
  /// String y eso rompia cualquier comparacion numerica. BigDecimal en el
  /// backend, double aqui.
  ///
  /// Mismo cuidado que [unidadMedida]: el listado 'L' no lo devuelve y el model
  /// manda null cuando vale cero, para no pisar lo que dejo SAP.
  final double gramajeSap;

  /// Usuario de auditoria. La columna es bigint, por eso BigInt y no int.
  final BigInt audUsuario;

  /// Fecha de auditoria. Es de SOLO LECTURA: el procedimiento la escribe
  /// siempre con GETDATE() e ignora lo que se le mande. Puede venir nula.
  final DateTime? audFecha;

  const ArticuloPrecioEntity({
    required this.codArticulo,
    required this.codigoFamilia,
    required this.datoArt,
    required this.datoArtExt,
    required this.stock,
    required this.utm,
    required this.unidadMedida,
    required this.gramajeSap,
    required this.audUsuario,
    required this.audFecha,
  });

  /// Largo maximo real de la columna codArticulo.
  static const int largoMaximoCodigo = 50;

  /// El codigo supera el ancho de la columna. El procedimiento lo deja pasar y
  /// el INSERT falla despues, asi que conviene frenarlo en la pantalla.
  bool get codigoExcedeLargo => codArticulo.trim().length > largoMaximoCodigo;

  /// Codigo utilizable para grabar: no vacio y dentro del ancho de la columna.
  bool get codigoValido => codArticulo.trim().isNotEmpty && !codigoExcedeLargo;

  /// Etiqueta para listas y combos. Cae a la descripcion extendida y, en ultimo
  /// caso, al propio codigo, porque las dos descripciones admiten NULL.
  String get descripcion {
    if (datoArt.trim().isNotEmpty) return datoArt.trim();
    if (datoArtExt.trim().isNotEmpty) return datoArtExt.trim();
    return codArticulo;
  }

  /// Texto corto para la tarjeta del movil: codigo mas descripcion.
  String get codigoConDescripcion => '$codArticulo - $descripcion';

  /// Tiene familia asignada. Cero o negativo significa que no se cargo.
  bool get tieneFamilia => codigoFamilia > 0;

  /// Hay existencia para vender.
  bool get tieneStock => stock > 0;

  /// Stock listo para mostrar, con la unidad cuando SAP la mando.
  String get stockLegible {
    final valor = stock.toStringAsFixed(2);
    return unidadMedida.trim().isEmpty
        ? valor
        : '$valor ${unidadMedida.trim()}';
  }

  /// Unidad de medida legible. Evita la celda vacia cuando el listado no la trae.
  String get unidadLegible =>
      unidadMedida.trim().isEmpty ? 'Sin unidad' : unidadMedida.trim();

  /// Gramaje legible. Cero se trata como ausente: SAP todavia no lo informo.
  String get gramajeLegible =>
      gramajeSap <= 0 ? 'Sin gramaje' : '${gramajeSap.toStringAsFixed(2)} g/m2';

  /// UTM legible para la columna de la tabla en web.
  String get utmLegible => utm.toStringAsFixed(2);

  /// Bandera de sincronizacion: SAP ya completo unidad o gramaje. En el listado
  /// 'L' siempre da false porque esas dos columnas no vienen en el resultado.
  bool get sincronizadoConSap =>
      unidadMedida.trim().isNotEmpty || gramajeSap > 0;

  /// Fecha de auditoria en formato dd/MM/yyyy, sin depender de intl.
  String get audFechaLegible {
    final fecha = audFecha;
    if (fecha == null) return 'Sin fecha';
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  ArticuloPrecioEntity copyWith({
    String? codArticulo,
    int? codigoFamilia,
    String? datoArt,
    String? datoArtExt,
    double? stock,
    double? utm,
    String? unidadMedida,
    double? gramajeSap,
    BigInt? audUsuario,
    DateTime? audFecha,
  }) => ArticuloPrecioEntity(
    codArticulo: codArticulo ?? this.codArticulo,
    codigoFamilia: codigoFamilia ?? this.codigoFamilia,
    datoArt: datoArt ?? this.datoArt,
    datoArtExt: datoArtExt ?? this.datoArtExt,
    stock: stock ?? this.stock,
    utm: utm ?? this.utm,
    unidadMedida: unidadMedida ?? this.unidadMedida,
    gramajeSap: gramajeSap ?? this.gramajeSap,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
  );
}
