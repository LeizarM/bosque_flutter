// Destino final: lib/core/utils/fecha_sql.dart

/// Fechas que vienen del backend de Bosque.
///
/// El backend serializa toda fecha como `yyyy-MM-dd HH:mm:ss` en
/// America/La_Paz (JacksonConfig), también las columnas DATE, que llegan con
/// `00:00:00`.
library;

/// Una columna DATE como fecha local, sin hora.
///
/// Se toma la parte `yyyy-MM-dd` del texto y no el instante completo: si
/// alguna vez el texto trae zona, convertir el instante a la del teléfono
/// puede mover el día cuando el teléfono está configurado en otra.
DateTime? soloFecha(dynamic valor) {
  if (valor == null) return null;
  if (valor is num) {
    final d = DateTime.fromMillisecondsSinceEpoch(valor.toInt());
    return DateTime(d.year, d.month, d.day);
  }
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(valor.toString());
  if (m == null) return null;
  return DateTime(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  );
}

/// Una columna DATETIME con su hora, tal como la escribió el servidor.
DateTime? fechaHora(dynamic valor) {
  if (valor == null) return null;
  if (valor is num) return DateTime.fromMillisecondsSinceEpoch(valor.toInt());
  return DateTime.tryParse(valor.toString());
}

/// `yyyy-MM-dd`, que es lo que el backend acepta sin ambigüedad para un DATE.
String fechaParaSql(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-'
    '${fecha.month.toString().padLeft(2, '0')}-'
    '${fecha.day.toString().padLeft(2, '0')}';
