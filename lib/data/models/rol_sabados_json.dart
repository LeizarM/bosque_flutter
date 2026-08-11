/// Conversores tolerantes a null, compartidos por los modelos del Rol de Sabados.
///
/// El backend devuelve wrappers (`Long`/`Integer`) en las columnas que admiten
/// NULL, asi que aca se colapsan a 0 o a cadena vacia. Un `?? 0` de mas no
/// molesta; uno de menos revienta en runtime con un tipo raro.
library;

int rsInt(dynamic v) => v is int ? v : (v is num ? v.toInt() : 0);
String rsStr(dynamic v) => v?.toString() ?? '';
DateTime? rsDate(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

/// Para los `float` de SQL. **No se puede usar [rsInt]**: los días de un permiso
/// vienen en fracciones —0.4375, 0.5, 0.625— y truncarlos a entero convertiría
/// medio día de vacación en cero.
double rsNum(dynamic v) => v is num ? v.toDouble() : 0;
