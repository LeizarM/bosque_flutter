/// Lo que quedo congelado al ejecutar el pago: `tcom_pagadoItem` y su corte.
///
/// Son tres lecturas del mismo hecho y viven juntas porque solas no se
/// entienden:
///
///   [PagadoItemEntity]        la linea: que articulo, cuanto, y si descontó.
///   [PagadoItemResumenEntity] el reparto por motivo, que es lo que dice de un
///                             vistazo cuanto quedo AFUERA del descuento.
///   [PagadoItemCorteEntity]   el sello del periodo. Es el unico que puede
///                             explicar un cero, y por eso nunca se muestra un
///                             conteo en cero sin el.
library;

/// Un item congelado al ejecutar el pago: una linea de `tcom_pagadoItem`.
///
/// [itemName] y [grpFam] llegan copiados y no referenciados a proposito: el
/// maestro de articulos y el de familias se editan, y dentro de un anio el
/// nombre de hoy puede no existir. Reconstruir el pasado con los nombres de
/// hoy seria reconstruir otro pasado.
class PagadoItemEntity {
  const PagadoItemEntity({
    required this.idPagadoItem,
    required this.idPagado,
    this.mesPago,
    this.anioPago,
    this.esInterno,
    this.docNum,
    this.origen,
    this.bd,
    this.fechaDoc,
    this.idVendedor,
    this.itemCode,
    this.itemName,
    this.itmsGrpCod,
    this.idGrpFamiliaSap,
    this.grpFam,
    this.cantidad,
    this.montoLineaBs,
    this.aplicaDescuento = true,
    this.porcentajePago,
    this.descuentoBs = 0,
    this.motivoExclusion,
    this.audFecha,
  });

  final int idPagadoItem;

  /// La fila de `tcom_pagado` de la que cuelga. Es la nota pagada.
  final int idPagado;

  final int? mesPago;
  final int? anioPago;

  /// 1 vendedores internos, 0 externos.
  final int? esInterno;

  /// Numero de documento en SAP. Es el unico identificador de nota que la
  /// aplicacion ya tiene a mano, asi que es por el que se agrupa.
  final int? docNum;

  /// Sistema del que viene: IMPEXPAP, ESPPAPEL, PRODUCTIVA PAPEL.
  final String? origen;
  final int? bd;

  /// Fecha de la factura. Es la que decide la vigencia de la politica, no la
  /// del pago: por eso una politica que hoy se ve activa puede no haber
  /// aplicado.
  final DateTime? fechaDoc;

  final int? idVendedor;

  final String? itemCode;
  final String? itemName;
  final int? itmsGrpCod;
  final int? idGrpFamiliaSap;
  final String? grpFam;
  final double? cantidad;
  final double? montoLineaBs;

  /// Si la linea descontó. Cuando es false, [motivoExclusion] dice por que.
  final bool aplicaDescuento;

  /// El porcentaje que regia el dia de la factura. Null si no aplicó.
  final double? porcentajePago;

  /// Lo descontado, en bolivianos. El SP lo escribe positivo; la pantalla es la
  /// que le pone el signo, porque es una resta.
  final double descuentoBs;

  /// Uno de los cinco motivos de [MotivoItemPagado], o null si descontó.
  final String? motivoExclusion;

  final DateTime? audFecha;

  /// Lo que quedo fuera del descuento. Es la mayoria de las lineas -15 de cada
  /// 19 medidas- y es la informacion que antes no quedaba registrada.
  bool get excluido => !aplicaDescuento;

  /// Como llamar a esta linea cuando no hay `itemName`.
  String get nombre => itemName ?? itemCode ?? 'Item $idPagadoItem';
}

/// Una fila del resumen por motivo: la rama 'R' del SP.
///
/// Responde la pregunta que el listado no responde de un vistazo: de todo lo
/// que se pago, cuanto descontó y cuanto no, y por que no.
class PagadoItemResumenEntity {
  const PagadoItemResumenEntity({
    required this.motivo,
    this.items = 0,
    this.montoBs = 0,
    this.descuentoBs = 0,
  });

  /// 'DESCONTO' o uno de los cuatro motivos de exclusion.
  final String motivo;

  final int items;
  final double montoBs;
  final double descuentoBs;

  /// La unica fila que NO es una exclusion.
  bool get descuenta => motivo == MotivoItemPagado.desconto;

  String get etiqueta => MotivoItemPagado.etiqueta(motivo);
  String get explicacion => MotivoItemPagado.explicacion(motivo);
}

/// El sello de un periodo congelado: una fila de `tcom_pagadoItemCorte`.
///
/// Existe para una sola cosa, y es la que hace que esta pantalla pueda mostrar
/// un cero: sin el corte, cero items no se distingue de «el congelado no
/// corrio». El SP ya redacta esa distincion en [lectura], asi que la pantalla
/// no la deduce.
class PagadoItemCorteEntity {
  const PagadoItemCorteEntity({
    required this.idCorte,
    required this.mesPago,
    required this.anioPago,
    required this.esInterno,
    this.items = 0,
    this.itemsExcluidos = 0,
    this.notasPagadas = 0,
    this.notasConItems = 0,
    this.notasSinItems = 0,
    this.politicaDesde,
    this.politicasActivas = 0,
    this.audFecha,
    this.lectura,
  });

  final int idCorte;
  final int mesPago;
  final int anioPago;
  final int esInterno;

  final int items;
  final int itemsExcluidos;

  final int notasPagadas;
  final int notasConItems;

  /// Notas que se pagaron y de las que no quedo detalle. Es el numero que hay
  /// que mirar: si es alto y no se explica por la vigencia, algo se perdio
  /// entre la captura y el pago.
  final int notasSinItems;

  /// La ventana de politica vigente al momento del corte, copiada porque la
  /// politica se edita y el cero de hoy dejaria de tener explicacion.
  final DateTime? politicaDesde;
  final int politicasActivas;

  final DateTime? audFecha;

  /// Como leer el cero, redactado por el propio SP. Es lo que se muestra en
  /// lugar del conteo cuando no hay items.
  final String? lectura;

  String get periodo =>
      '${mesPago.toString().padLeft(2, '0')}/${anioPago.toString().padLeft(4, '0')}';

  /// El corte corrio y no habia nada que congelar. No es un fallo.
  bool get vacioExplicado => items == 0;

  /// Lo que descontó, por diferencia. El SP no lo manda: guarda el total y lo
  /// excluido, que son los dos que no se pueden derivar.
  int get itemsQueDescuentan => items - itemsExcluidos;
}

/// Los motivos por los que una linea entra o no al descuento.
///
/// Se traducen aca y no en cada widget porque el mismo codigo se muestra en
/// dos lugares -la ficha del item y el resumen de arriba- y con dos tablas de
/// traduccion terminan diciendo cosas distintas.
///
/// El orden de precedencia lo decide el SP, no la pantalla: VENDEDOR_EXENTO
/// exime la nota entera y gana sobre todo lo demas.
class MotivoItemPagado {
  const MotivoItemPagado._();

  /// No es un motivo de exclusion: es la fila del resumen que agrupa lo que si
  /// descontó. El SP lo escribe asi, sin U, y se respeta tal cual llega.
  static const String desconto = 'DESCONTO';

  static const String vendedorExento = 'VENDEDOR_EXENTO';
  static const String sinFamilia = 'SIN_FAMILIA';
  static const String familiaSinPolitica = 'FAMILIA_SIN_POLITICA';
  static const String fueraDeVigencia = 'FUERA_DE_VIGENCIA';

  /// Rotulo corto, para un chip.
  static String etiqueta(String? codigo) => switch (codigo) {
    desconto => 'Descontó',
    vendedorExento => 'Vendedor exento',
    sinFamilia => 'Sin familia',
    familiaSinPolitica => 'Familia sin política',
    fueraDeVigencia => 'Fuera de vigencia',
    null => 'Descontó',
    // Un motivo nuevo en el SP no puede dejar la celda en blanco: se muestra
    // el codigo crudo, que al menos se puede buscar.
    _ => codigo,
  };

  /// Por que, en una linea. Es lo que convierte un rotulo en una respuesta.
  static String explicacion(String? codigo) => switch (codigo) {
    desconto => 'La política de la familia aplicó a la fecha de la factura.',
    vendedorExento =>
      'El vendedor estaba exento a la fecha de la nota: exime la nota entera.',
    sinFamilia =>
      'El artículo no está mapeado a ninguna familia. No siempre es un error: '
          'hay artículos que no pertenecen a ninguna.',
    familiaSinPolitica =>
      'La familia existe, pero nadie le definió un descuento.',
    fueraDeVigencia =>
      'Hay política activa, pero la fecha de la factura cae fuera de su '
          'ventana. Es el que más confunde: la política se ve activa en '
          'pantalla y la nota igual no descuenta.',
    null => 'La política de la familia aplicó a la fecha de la factura.',
    _ => 'Motivo registrado por el procedimiento: $codigo.',
  };
}
