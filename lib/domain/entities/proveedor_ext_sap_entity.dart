/// Proveedor externo que llega desde SAP (tabla tpr_proveedorExtSap, modulo de
/// Precios). Es un catalogo: tpr_producto.idProveedorSap lo referencia, asi que
/// un proveedor asignado a productos no se puede eliminar y el backend responde
/// con un mensaje en lugar de borrarlo.
///
/// La tabla tiene EXACTAMENTE cinco columnas y aqui estan las cinco, ni una
/// mas. Cualquier dato de display que venga de un JOIN va en otra entity: estos
/// campos viajan uno a uno como parametros del procedimiento
/// p_abm_proveedorExtSap y un campo de sobra hace fallar la ejecucion.
class ProveedorExtSapEntity {
  /// bigint IDENTITY, PK. En el alta todavia no existe y vale BigInt.zero: el
  /// procedimiento ignora el parametro en la rama de insercion y devuelve el id
  /// real por separado. En modificacion y baja es obligatorio.
  final BigInt idProveedorSap;

  /// TRAMPA. El codigo SAP es varchar(20), o sea TEXTO, no un numero. Nunca
  /// convertirlo a int para buscar ni para mostrar: se pierden los ceros a la
  /// izquierda ('0042') y los codigos con letras. La columna admite nulos, por
  /// eso puede llegar vacio.
  final String codProvExtSap;

  /// Nombre del proveedor. La columna es varchar(50) aunque el parametro del
  /// procedimiento sea varchar(200): un nombre mas largo NO se trunca, lo
  /// rechaza el backend. Usar [nombreExcedeLargo] para avisar en el formulario
  /// antes de enviar.
  final String proveedorExtSap;

  /// Usuario de auditoria.
  final BigInt audUsuario;

  /// Solo lectura. El procedimiento la graba siempre con la hora del servidor y
  /// descarta lo que se le mande, por eso el model no la incluye en el toJson.
  /// Puede venir nula en filas historicas.
  final DateTime? audFecha;

  const ProveedorExtSapEntity({
    required this.idProveedorSap,
    required this.codProvExtSap,
    required this.proveedorExtSap,
    required this.audUsuario,
    this.audFecha,
  });

  /// Todavia no fue grabado: no tiene id asignado por la base.
  bool get esNuevo => idProveedorSap == BigInt.zero;

  /// El codigo SAP es opcional en la tabla.
  bool get tieneCodigo => codProvExtSap.trim().isNotEmpty;

  /// Codigo listo para la grilla, sin celdas en blanco.
  String get codigoLegible => tieneCodigo ? codProvExtSap.trim() : 'Sin código';

  /// Nombre listo para mostrar.
  String get nombreLegible =>
      proveedorExtSap.trim().isNotEmpty ? proveedorExtSap.trim() : 'Sin nombre';

  /// Etiqueta para combos y buscadores: "0042 - Papelera del Sur".
  String get etiquetaCompleta =>
      tieneCodigo ? '$codigoLegible - $nombreLegible' : nombreLegible;

  /// El backend rechaza nombres de mas de 50 caracteres porque la columna es
  /// varchar(50). Sirve para marcar el campo antes de enviar.
  bool get nombreExcedeLargo => proveedorExtSap.trim().length > 50;

  /// Mismo caso para el codigo: la columna admite 20 caracteres.
  bool get codigoExcedeLargo => codProvExtSap.trim().length > 20;

  /// El formulario esta listo para grabar: el nombre es obligatorio y ninguno
  /// de los dos textos pasa el largo de su columna.
  bool get datosValidos =>
      proveedorExtSap.trim().isNotEmpty &&
      !nombreExcedeLargo &&
      !codigoExcedeLargo;

  /// Fecha de auditoria en formato dd/mm/aaaa hh:mm.
  String get audFechaLegible {
    final f = audFecha;
    if (f == null) return 'Sin registro';
    final dia = f.day.toString().padLeft(2, '0');
    final mes = f.month.toString().padLeft(2, '0');
    final hora = f.hour.toString().padLeft(2, '0');
    final minuto = f.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${f.year} $hora:$minuto';
  }

  ProveedorExtSapEntity copyWith({
    BigInt? idProveedorSap,
    String? codProvExtSap,
    String? proveedorExtSap,
    BigInt? audUsuario,
    DateTime? audFecha,
  }) => ProveedorExtSapEntity(
    idProveedorSap: idProveedorSap ?? this.idProveedorSap,
    codProvExtSap: codProvExtSap ?? this.codProvExtSap,
    proveedorExtSap: proveedorExtSap ?? this.proveedorExtSap,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
  );
}
