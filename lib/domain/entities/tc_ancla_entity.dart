/// Configuracion del reprecio nocturno por empresa (tabla tpr_tcAncla).
/// Guarda con que tipo de cambio se repreciaron los precios por ultima vez
/// (el "ancla") y cuanta variacion debe acumular el tipo de cambio para
/// disparar un nuevo reprecio (el "umbral").
///
/// ALCANCE: esta entity es de CONSULTA. La logica del reprecio (calcular el
/// delta contra el ancla, decidir si dispara, repreciar tpr_precio, leer el
/// tipo de cambio de SAP) esta FUERA DE ALCANCE de esta migracion y no vive
/// aca. La pantalla solo muestra la fila de configuracion; no la ejecuta.
///
/// OJO con la llave: [companyDB] es la PK y es un String (nvarchar(100)), no
/// un bigint. La tabla no tiene columna IDENTITY, asi que el alta nunca
/// devuelve un id generado: la clave la define el negocio (es el nombre de la
/// base de datos de la empresa en SAP, por ejemplo SBO_IMPEXPAP).
///
/// OJO con la escala de [umbral]: es una proporcion, no un porcentaje.
/// 0.10 significa 10 %. Para mostrarlo usar [umbralPorcentaje].
///
/// OJO con los tipos de cambio: en la base son float(53) y en el backend Java
/// son BigDecimal. Dart no tiene BigDecimal, por eso viajan en double y
/// arrastran el error binario del float: hay que redondear al mostrarlos
/// (ver [tcAnclaLegible] y [tcUltimoLegible]), nunca compararlos con ==.
class TcAnclaEntity {
  /// PK. nvarchar(100) NOT NULL, NO identity. Nombre de la base de datos de
  /// la empresa en SAP. Vacio significa "fila nueva sin empresa elegida".
  final String companyDB;

  /// Tipo de cambio con el que se repreciaron los precios por ultima vez.
  /// float(53) NOT NULL en la base, BigDecimal en el backend: aca es double.
  /// Ojo con el nombre: el parametro del ABM se llama tc, no tcAncla.
  final double tcAncla;

  /// Fecha en la que se fijo el ancla. datetime NOT NULL.
  /// En un alta nueva el backend la siembra a proposito con 1900-01-01 y no
  /// con la fecha del dia, porque el job cuenta como "precios pendientes"
  /// todo tpr_precio con audFecha mayor a fechaAncla. Ver [esAnclaSembrada].
  final DateTime? fechaAncla;

  /// Ultimo tipo de cambio observado, haya disparado reprecio o no.
  /// float(53) NULL en la base: cuando viene NULL aca queda en 0.0, que se
  /// lee como "todavia no hubo lectura". Confirmarlo con [tieneLecturaTc].
  final double tcUltimo;

  /// Fecha de la ultima lectura del tipo de cambio. datetime NULL.
  final DateTime? fechaUltimo;

  /// Variacion minima del tipo de cambio que habilita un nuevo reprecio.
  /// float(53) NOT NULL, DEFAULT 0.10 en la base. Es una proporcion: 0.10 es 10 %.
  final double umbral;

  const TcAnclaEntity({
    required this.companyDB,
    required this.tcAncla,
    required this.fechaAncla,
    required this.tcUltimo,
    required this.fechaUltimo,
    required this.umbral,
  });

  /// El umbral en puntos porcentuales, listo para mostrar. 0.10 devuelve 10.0.
  double get umbralPorcentaje => umbral * 100;

  /// Umbral legible, por ejemplo "10.0 %".
  String get umbralLegible => '${umbralPorcentaje.toStringAsFixed(1)} %';

  /// Tipo de cambio ancla redondeado para pantalla: el float de la base trae
  /// cola binaria y no se muestra crudo.
  String get tcAnclaLegible => tcAncla.toStringAsFixed(4);

  /// Ultimo tipo de cambio observado, redondeado para pantalla.
  String get tcUltimoLegible =>
      tieneLecturaTc ? tcUltimo.toStringAsFixed(4) : 'Sin lectura';

  /// La fila trae el ancla real y no la semilla 1900-01-01 del alta.
  bool get esAnclaSembrada => fechaAncla != null && fechaAncla!.year > 1900;

  /// Ya hubo al menos una lectura del tipo de cambio registrada.
  bool get tieneLecturaTc => fechaUltimo != null && tcUltimo > 0;

  /// Fecha del ancla legible. Muestra el caso semilla en palabras en vez del
  /// 01/01/1900, que al usuario no le dice nada.
  String get fechaAnclaLegible =>
      esAnclaSembrada ? _formatearFecha(fechaAncla) : 'Nunca repreciado';

  /// Fecha de la ultima lectura del tipo de cambio, legible.
  String get fechaUltimoLegible =>
      fechaUltimo != null ? _formatearFecha(fechaUltimo) : 'Sin lectura';

  /// Diferencia entre el ultimo tipo de cambio observado y el ancla.
  /// Cero mientras no haya lectura.
  double get variacionAbsoluta => tieneLecturaTc ? tcUltimo - tcAncla : 0.0;

  /// La misma diferencia como proporcion del ancla, en la misma escala que
  /// [umbral]. Cero si no hay lectura o si el ancla es cero (evita dividir por 0).
  double get variacionRelativa =>
      (tieneLecturaTc && tcAncla != 0) ? variacionAbsoluta / tcAncla : 0.0;

  /// La variacion en puntos porcentuales, lista para mostrar.
  double get variacionPorcentaje => variacionRelativa * 100;

  /// Variacion legible con signo, por ejemplo "+2.5 %".
  String get variacionLegible {
    if (!tieneLecturaTc) return 'Sin lectura';
    final signo = variacionPorcentaje >= 0 ? '+' : '';
    return '$signo${variacionPorcentaje.toStringAsFixed(2)} %';
  }

  /// Bandera SOLO DE PANTALLA: la variacion acumulada ya alcanza el umbral.
  /// No es la decision del reprecio: esa la toma el job nocturno, que esta
  /// fuera del alcance de esta migracion. Aca es un semaforo informativo.
  bool get superaUmbralVisual =>
      tieneLecturaTc && variacionRelativa.abs() >= umbral;

  /// Estado legible de la fila para la grilla o la tarjeta.
  String get estadoLegible {
    if (!esAnclaSembrada) return 'Ancla sin fijar';
    if (!tieneLecturaTc) return 'Sin lectura de tipo de cambio';
    return superaUmbralVisual
        ? 'Variacion sobre el umbral'
        : 'Dentro del umbral';
  }

  /// La empresa ya tiene ancla cargada en la base.
  bool get tieneEmpresa => companyDB.trim().isNotEmpty;

  /// dd/MM/yyyy sin dependencias externas: las entities no usan intl.
  static String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '';
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  TcAnclaEntity copyWith({
    String? companyDB,
    double? tcAncla,
    DateTime? fechaAncla,
    double? tcUltimo,
    DateTime? fechaUltimo,
    double? umbral,
  }) => TcAnclaEntity(
    companyDB: companyDB ?? this.companyDB,
    tcAncla: tcAncla ?? this.tcAncla,
    fechaAncla: fechaAncla ?? this.fechaAncla,
    tcUltimo: tcUltimo ?? this.tcUltimo,
    fechaUltimo: fechaUltimo ?? this.fechaUltimo,
    umbral: umbral ?? this.umbral,
  );
}
