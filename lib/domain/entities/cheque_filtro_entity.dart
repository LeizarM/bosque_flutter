/// Orden de la grilla de cheques.
enum OrdenCheques {
  /// Por fecha de recepcion, el mas reciente primero. Es el defecto.
  recepcion('RECEPCION'),

  /// Por fecha de cobro, la mas proxima primero.
  cobro('COBRO');

  const OrdenCheques(this.codigo);

  /// Lo que viaja en el JSON.
  final String codigo;
}

/// Filtros y pagina de la grilla (`ChequeFiltro` del contrato, cuerpo de
/// `/cheque/listar`).
///
/// La sucursal es obligatoria; los demas criterios son opcionales y null no
/// filtra. [nroCheque] y [cliente] filtran por coincidencia parcial; [tipo],
/// [estado], [codBanco] y [fechaCobro] por igualdad; la recepcion (el dia de la
/// accion REC) por el rango [fechaRecepcionDesde]..[fechaRecepcionHasta], los
/// dos extremos incluidos y cada uno opcional: un solo dia es el rango con las
/// dos fechas iguales. La paginacion es del servidor.
class ChequeFiltroEntity {
  static const int tamanioPorDefecto = 20;

  /// El backend no devuelve mas de esto por pagina.
  static const int tamanioMaximo = 200;

  final int codSucursal;
  final String? nroCheque;
  final String? cliente;
  final String? tipo;
  final String? estado;
  final int? codBanco;
  final DateTime? fechaCobro;
  final DateTime? fechaRecepcionDesde;
  final DateTime? fechaRecepcionHasta;
  final OrdenCheques orden;

  /// Desde 1.
  final int pagina;
  final int tamanio;

  const ChequeFiltroEntity({
    required this.codSucursal,
    this.nroCheque,
    this.cliente,
    this.tipo,
    this.estado,
    this.codBanco,
    this.fechaCobro,
    this.fechaRecepcionDesde,
    this.fechaRecepcionHasta,
    this.orden = OrdenCheques.recepcion,
    this.pagina = 1,
    this.tamanio = tamanioPorDefecto,
  });

  /// Ningun criterio de busqueda (la sucursal, el orden y la pagina no cuentan).
  /// El rango de recepcion es un criterio: con el rango por defecto, la grilla
  /// ya esta acotada.
  bool get sinCriterios =>
      !tieneCriteriosSalvoRecepcion && !tieneRangoRecepcion;

  /// Hay alguna de las dos fechas de recepcion.
  bool get tieneRangoRecepcion =>
      fechaRecepcionDesde != null || fechaRecepcionHasta != null;

  /// Algun criterio que no es el rango de recepcion.
  bool get tieneCriteriosSalvoRecepcion =>
      nroCheque != null ||
      cliente != null ||
      tipo != null ||
      estado != null ||
      codBanco != null ||
      fechaCobro != null;

  /// Las dos fechas estan y «hasta» es anterior a «desde»: el servidor lo
  /// rechaza con un 400.
  bool get rangoRecepcionInvalido =>
      fechaRecepcionDesde != null &&
      fechaRecepcionHasta != null &&
      fechaRecepcionHasta!.isBefore(fechaRecepcionDesde!);

  /// Cambia sucursal, orden, pagina o tamanio y conserva los criterios.
  ChequeFiltroEntity copyWith({
    int? codSucursal,
    OrdenCheques? orden,
    int? pagina,
    int? tamanio,
  }) => ChequeFiltroEntity(
    codSucursal: codSucursal ?? this.codSucursal,
    nroCheque: nroCheque,
    cliente: cliente,
    tipo: tipo,
    estado: estado,
    codBanco: codBanco,
    fechaCobro: fechaCobro,
    fechaRecepcionDesde: fechaRecepcionDesde,
    fechaRecepcionHasta: fechaRecepcionHasta,
    orden: orden ?? this.orden,
    pagina: pagina ?? this.pagina,
    tamanio: tamanio ?? this.tamanio,
  );

  /// **Reemplaza** todos los criterios por los que se pasan (un null los
  /// quita) y vuelve a la pagina 1: una busqueda nueva empieza arriba. Sin
  /// argumentos limpia la busqueda.
  ChequeFiltroEntity conCriterios({
    String? nroCheque,
    String? cliente,
    String? tipo,
    String? estado,
    int? codBanco,
    DateTime? fechaCobro,
    DateTime? fechaRecepcionDesde,
    DateTime? fechaRecepcionHasta,
  }) => ChequeFiltroEntity(
    codSucursal: codSucursal,
    nroCheque: _texto(nroCheque),
    cliente: _texto(cliente),
    tipo: _texto(tipo),
    estado: _texto(estado),
    codBanco: (codBanco == null || codBanco <= 0) ? null : codBanco,
    fechaCobro: fechaCobro,
    fechaRecepcionDesde: fechaRecepcionDesde,
    fechaRecepcionHasta: fechaRecepcionHasta,
    orden: orden,
    pagina: 1,
    tamanio: tamanio,
  );

  static String? _texto(String? t) =>
      (t == null || t.trim().isEmpty) ? null : t.trim();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChequeFiltroEntity &&
          other.codSucursal == codSucursal &&
          other.nroCheque == nroCheque &&
          other.cliente == cliente &&
          other.tipo == tipo &&
          other.estado == estado &&
          other.codBanco == codBanco &&
          other.fechaCobro == fechaCobro &&
          other.fechaRecepcionDesde == fechaRecepcionDesde &&
          other.fechaRecepcionHasta == fechaRecepcionHasta &&
          other.orden == orden &&
          other.pagina == pagina &&
          other.tamanio == tamanio;

  @override
  int get hashCode => Object.hash(
    codSucursal,
    nroCheque,
    cliente,
    tipo,
    estado,
    codBanco,
    fechaCobro,
    fechaRecepcionDesde,
    fechaRecepcionHasta,
    orden,
    pagina,
    tamanio,
  );
}
