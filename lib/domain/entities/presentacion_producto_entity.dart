/// Catalogo de presentaciones de producto (tabla tpr_presentacion).
///
/// Contiene EXACTAMENTE las cinco columnas de la tabla, ni una mas: el SP de
/// ABM recibe cada campo del model como parametro y un campo extra de display
/// haria fallar el EXEC. Los nombres que vienen de JOIN (por ejemplo el del
/// usuario de auditoria) viven en un DTO aparte, no aca.
///
/// OJO con [estado]: 1 = activa, 0 = inactiva. Es int y no bool porque la
/// columna es int y nada garantiza que solo existan esos dos valores; los
/// combos deben filtrar con [esActiva] antes de listar.
///
/// Este catalogo lo referencia tpr_producto.idPresentacion: una presentacion
/// en uso no se puede eliminar, el SP responde con error y hay que desactivarla.
class PresentacionProductoEntity {
  /// PK (bigint IDENTITY). En el alta va en cero: el SP genera el id y lo
  /// devuelve en idGenerado.
  final BigInt idPresentacion;

  /// Nombre de la presentacion. La columna admite hasta 150 caracteres; el
  /// parametro del SP fue ampliado a 150 porque antes truncaba en silencio.
  final String presentacion;

  /// 1 = activa, 0 = inactiva. En el alta el SP lo fuerza a 1 e ignora lo que
  /// se mande: solo tiene efecto real en la edicion.
  final int estado;

  final BigInt audUsuario;

  /// Fecha de auditoria. La sella el SP con GETDATE(), el cliente no la manda.
  final DateTime? audFecha;

  const PresentacionProductoEntity({
    required this.idPresentacion,
    required this.presentacion,
    required this.estado,
    required this.audUsuario,
    required this.audFecha,
  });

  /// Presentacion habilitada. Es el filtro que deben aplicar los combos.
  bool get esActiva => estado == 1;

  /// Estado en texto, listo para mostrar en tabla o tarjeta.
  String get estadoLegible => esActiva ? 'Activa' : 'Inactiva';

  /// Registro todavia no grabado: sirve para decidir entre alta y edicion.
  bool get esNueva => idPresentacion == BigInt.zero;

  /// Nombre para mostrar. Evita dejar la celda vacia cuando el campo es null
  /// en la base.
  String get nombreLegible =>
      presentacion.trim().isEmpty ? 'Sin nombre' : presentacion.trim();

  PresentacionProductoEntity copyWith({
    BigInt? idPresentacion,
    String? presentacion,
    int? estado,
    BigInt? audUsuario,
    DateTime? audFecha,
  }) => PresentacionProductoEntity(
    idPresentacion: idPresentacion ?? this.idPresentacion,
    presentacion: presentacion ?? this.presentacion,
    estado: estado ?? this.estado,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
  );
}
