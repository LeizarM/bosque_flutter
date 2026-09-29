/// Color del catalogo de productos (tabla tpr_color). Es un catalogo simple:
/// nombre, estado y auditoria, nada mas. tpr_producto referencia esta tabla por
/// clave foranea, asi que un color asignado a un producto no se puede eliminar:
/// el SP devuelve el error de negocio 5 en lugar de reventar con el 547 de FK.
///
/// El nombre de la clase lleva "Producto" a proposito: Color ya existe en
/// material.dart y chocaria en cualquier pantalla que importe Flutter. En el
/// backend la clase Java si se llama Color, y tampoco es java.awt.Color.
class ColorProductoEntity {
  /// tpr_color.idColor - bigint IDENTITY, PK. Vale BigInt.zero mientras el
  /// color todavia no se grabo.
  final BigInt idColor;

  /// tpr_color.color - varchar(100). Obligatorio y unico entre los activos:
  /// el SP rechaza el nombre vacio y el duplicado.
  final String color;

  /// tpr_color.estado - 1 = activo, 0 = inactivo.
  ///
  /// Es int y no bool porque en la base es un int y el legacy lo usa como
  /// numero. Dos trampas: en el alta el SP fuerza 1 e ignora lo que se mande
  /// (todo color nace activo), y en la modificacion un null significa "no
  /// cambiar", no "poner en cero".
  final int estado;

  /// tpr_color.audUsuario - bigint NULL.
  final BigInt audUsuario;

  /// tpr_color.audFecha - datetime NULL. Solo lectura: el SP la sella con
  /// GETDATE() tanto en el alta como en la modificacion. Tambien llega null en
  /// el listado de colores activos, que solo devuelve id y nombre.
  final DateTime? audFecha;

  const ColorProductoEntity({
    required this.idColor,
    required this.color,
    required this.estado,
    required this.audUsuario,
    this.audFecha,
  });

  /// El color esta habilitado para usarse en productos.
  bool get esActivo => estado == 1;

  /// Estado legible, para chips o columnas de estado.
  String get estadoLegible => esActivo ? 'Activo' : 'Inactivo';

  /// Fila todavia no grabada: el formulario esta en modo alta.
  bool get esNuevo => idColor == BigInt.zero;

  /// Nombre listo para mostrar. Evita la celda en blanco cuando el listado de
  /// colores activos o un dato viejo traen el nombre vacio.
  String get nombreVisible {
    final n = color.trim();
    return n.isEmpty ? '(sin nombre)' : n;
  }

  /// Fecha de auditoria lista para mostrar. Devuelve '-' cuando viene null.
  String get audFechaLegible {
    final f = audFecha;
    if (f == null) return '-';
    final dia = f.day.toString().padLeft(2, '0');
    final mes = f.month.toString().padLeft(2, '0');
    final hora = f.hour.toString().padLeft(2, '0');
    final min = f.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${f.year} $hora:$min';
  }

  ColorProductoEntity copyWith({
    BigInt? idColor,
    String? color,
    int? estado,
    BigInt? audUsuario,
    DateTime? audFecha,
  }) => ColorProductoEntity(
    idColor: idColor ?? this.idColor,
    color: color ?? this.color,
    estado: estado ?? this.estado,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
  );
}
