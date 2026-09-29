/// Catalogo de tipos de papel / tipos de familia del modulo de precios
/// (tabla tpr_tipo). Espejo de la clase Java Tipo: exactamente las cinco
/// columnas de la tabla y ninguna mas.
///
/// OJO CON EL NOMBRE: en la base y en el backend esto se llama solo "Tipo".
/// En Flutter se nombra TipoProducto porque ya hay 19 archivos tipo_*.dart de
/// otros modulos y "tipo" a secas no dice nada. Es la misma tabla tpr_tipo.
///
/// NO CONFUNDIR con la clase Java utils.Tipos, que es otra cosa: constantes de
/// los grupos de la vista v_tipos para listas desplegables.
///
/// OJO: no hay campos de display. El ABM serializa el objeto completo y manda
/// cada campo como parametro de p_abm_tipo; un campo que no exista como
/// parametro del procedimiento hace fallar el EXEC entero. Cualquier dato que
/// venga de un JOIN va en un DTO aparte.
///
/// Procedimientos asociados: ABM p_abm_tipo (acciones I, U, D) y listado
/// p_list_tipo (acciones L y A).
class TipoProductoEntity {
  /// tpr_tipo.idTipo - bigint NOT NULL IDENTITY, PK. En un alta todavia no
  /// existe: viaja en BigInt.zero y el SP devuelve el id generado.
  final BigInt idTipo;

  /// tpr_tipo.tipo - varchar(150) NULL. Nombre del tipo.
  ///
  /// OJO: el procedimiento declaraba el parametro como VARCHAR(50) y truncaba
  /// en silencio; el script tpr_Tipo.sql lo lleva a VARCHAR(150). Validar
  /// contra 150 en la pantalla, no contra 50.
  ///
  /// El SP rechaza el alta y la modificacion si llega vacio (error 1).
  final String tipo;

  /// tpr_tipo.estado - int NULL. 1 = activo, 0 = inactivo.
  ///
  /// Es int y NO bool a proposito: en la base es int, el legacy lo trata como
  /// numero y la columna admite NULL. Ademas en el alta el SP fuerza 1 e
  /// ignora lo que se le mande, o sea que todo tipo nace activo.
  final int estado;

  /// tpr_tipo.audUsuario - bigint NULL. Usuario del ultimo movimiento.
  final BigInt audUsuario;

  /// tpr_tipo.audFecha - datetime NULL. Solo lectura: el SP declara el
  /// parametro pero lo ignora y sella GETDATE() en el alta y en la
  /// modificacion.
  ///
  /// OJO: hoy esta en NULL en el 100% de las filas historicas porque el ABM
  /// nunca se ejecuto desde el sistema viejo (el catalogo se cargo por fuera).
  /// Las filas que toque la pantalla nueva si van a quedar con fecha, asi que
  /// la UI tiene que aguantar el null. Ver [audFechaLegible].
  final DateTime? audFecha;

  const TipoProductoEntity({
    required this.idTipo,
    required this.tipo,
    required this.estado,
    required this.audUsuario,
    this.audFecha,
  });

  /// Fila todavia no grabada: el id lo asigna el IDENTITY en el alta.
  bool get esNuevo => idTipo == BigInt.zero;

  /// El tipo esta habilitado para usarse.
  bool get esActivo => estado == 1;

  /// Estado legible, para chips y columnas de grilla.
  String get estadoLegible => esActivo ? 'Activo' : 'Inactivo';

  /// Nombre listo para mostrar. La columna admite NULL y hay filas viejas
  /// grabadas en blanco antes de que el SP validara el nombre.
  String get nombreLegible => tipo.trim().isEmpty ? '(sin nombre)' : tipo;

  /// El nombre pasa la validacion del SP (obligatorio, hasta 150 caracteres).
  /// Sirve para habilitar el boton de guardar antes de llamar al backend.
  bool get nombreValido {
    final n = tipo.trim();
    return n.isNotEmpty && n.length <= 150;
  }

  /// Fecha de auditoria lista para mostrar. Devuelve '-' cuando viene null,
  /// que es el caso de todas las filas historicas.
  String get audFechaLegible {
    final f = audFecha;
    if (f == null) return '-';
    final dia = f.day.toString().padLeft(2, '0');
    final mes = f.month.toString().padLeft(2, '0');
    final hora = f.hour.toString().padLeft(2, '0');
    final min = f.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${f.year} $hora:$min';
  }

  TipoProductoEntity copyWith({
    BigInt? idTipo,
    String? tipo,
    int? estado,
    BigInt? audUsuario,
    DateTime? audFecha,
  }) => TipoProductoEntity(
    idTipo: idTipo ?? this.idTipo,
    tipo: tipo ?? this.tipo,
    estado: estado ?? this.estado,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
  );
}
