/// Costo de incremento por sucursal (tabla tpr_costoIncre): es el flete de
/// transporte que se suma dentro de una propuesta de precios segun la sucursal
/// que atiende al cliente.
///
/// OJO con el dinero: en la BD la columna es float(53) y el backend la mapea a
/// BigDecimal justamente porque el float binario no representa 0.01 exacto.
/// Dart no tiene BigDecimal, asi que aqui [valor] viaja como double: mostrarlo
/// siempre redondeado a 2 decimales y evitar acumular sumas sin redondear.
///
/// Esta entity mapea EXACTAMENTE las columnas de la tabla. Los campos de
/// display que salen de los JOIN de p_list_costoIncre (nombre de sucursal,
/// ciudad, codCiudad) viven en sus propios DTO del backend, nunca aqui.
class CostoIncrementoEntity {
  /// PK IDENTITY. En el alta vale BigInt.zero: el SP devuelve el definitivo.
  final BigInt idIncre;

  /// FK a tb_sucursal. La columna admite NULL; el null llega como BigInt.zero.
  final BigInt codSucursal;

  /// FK a tpr_propuesta. La columna admite NULL -> BigInt.zero.
  /// OJO: la rama 'L' del listado legacy devuelve esta columna al FINAL del
  /// SELECT (para no correr las posiciones que el JSF lee por indice), asi que
  /// puede faltar en respuestas viejas; el default defensivo la deja en cero.
  final BigInt idPropuesta;

  /// Monto del flete. Es dinero: float(53) en la BD, BigDecimal en el backend y
  /// double aqui porque Dart no tiene BigDecimal. Mostrar con 2 decimales.
  final double valor;

  /// Usuario que grabo el registro. bigint NULL en la BD -> BigInt.zero.
  final BigInt audUsuario;

  /// Solo lectura: la escribe el propio SP con GETDATE() en las acciones 'I' y
  /// 'U'. Se recibe en el listado pero nunca se envia de vuelta.
  final DateTime? audFecha;

  const CostoIncrementoEntity({
    required this.idIncre,
    required this.codSucursal,
    required this.idPropuesta,
    required this.valor,
    required this.audUsuario,
    this.audFecha,
  });

  /// Registro todavia sin grabar: el IDENTITY aun no fue asignado por el SP.
  bool get esNuevo => idIncre == BigInt.zero;

  /// Tiene sucursal asignada (la columna admite NULL).
  bool get tieneSucursal => codSucursal != BigInt.zero;

  /// Tiene propuesta asociada (la columna admite NULL).
  bool get tienePropuesta => idPropuesta != BigInt.zero;

  /// Flete en cero: la sucursal no carga costo de transporte.
  bool get sinCosto => valor <= 0;

  /// Monto listo para mostrar, siempre con 2 decimales.
  String get valorFormateado => 'Bs ${valor.toStringAsFixed(2)}';

  /// Texto corto para la celda o la tarjeta del listado.
  String get costoLegible => sinCosto ? 'Sin costo de flete' : valorFormateado;

  /// Fecha de auditoria en formato dd/MM/yyyy. Evita mostrar un null crudo.
  String get fechaRegistroLegible {
    final f = audFecha;
    if (f == null) return 'Sin registro';
    final dia = f.day.toString().padLeft(2, '0');
    final mes = f.month.toString().padLeft(2, '0');
    return '$dia/$mes/${f.year}';
  }

  /// [audFecha] no se puede limpiar con copyWith: es de solo lectura y la
  /// controla el SP.
  CostoIncrementoEntity copyWith({
    BigInt? idIncre,
    BigInt? codSucursal,
    BigInt? idPropuesta,
    double? valor,
    BigInt? audUsuario,
    DateTime? audFecha,
  }) => CostoIncrementoEntity(
    idIncre: idIncre ?? this.idIncre,
    codSucursal: codSucursal ?? this.codSucursal,
    idPropuesta: idPropuesta ?? this.idPropuesta,
    valor: valor ?? this.valor,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
  );
}
