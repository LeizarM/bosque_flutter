/// Lectura y escritura tolerantes de los campos JSON del módulo de exámenes:
/// fechas `yyyy-MM-dd HH:mm:ss`, `bit` como booleano o 0/1 y BIGINT como
/// número, para que un model nunca reviente por un tipo inesperado.
library;

BigInt? tcpeBigInt(Object? v) {
  if (v == null) return null;
  if (v is BigInt) return v;
  if (v is int) return BigInt.from(v);
  if (v is num) return BigInt.from(v.toInt());
  return BigInt.tryParse(v.toString().trim());
}

int? tcpeInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is BigInt) return v.toInt();
  return int.tryParse(v.toString().trim());
}

double? tcpeDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().trim().replaceAll(',', '.'));
}

bool? tcpeBool(Object? v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final t = v.toString().trim().toLowerCase();
  if (t == 'true' || t == '1' || t == 's') return true;
  if (t == 'false' || t == '0' || t == 'n') return false;
  return null;
}

String? tcpeTexto(Object? v) => v?.toString();

/// Acepta `yyyy-MM-dd`, `yyyy-MM-dd HH:mm:ss`, ISO y milisegundos epoch.
DateTime? tcpeFecha(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is num) {
    // Un epoch en segundos (el `exp` de un JWT) es mucho menor que uno en ms.
    final n = v.toInt();
    return DateTime.fromMillisecondsSinceEpoch(n < 100000000000 ? n * 1000 : n);
  }
  final t = v.toString().trim();
  if (t.isEmpty) return null;
  return DateTime.tryParse(t);
}

/// Una columna TIME: se normaliza a `HH:mm:ss`.
String? tcpeHora(Object? v) {
  if (v == null) return null;
  final t = v.toString().trim();
  if (t.isEmpty) return null;
  final partes = t.split(':');
  if (partes.length < 2) return t;
  final h = partes[0].padLeft(2, '0');
  final m = partes[1].padLeft(2, '0');
  final s = partes.length > 2 ? partes[2].split('.').first.padLeft(2, '0') : '00';
  return '$h:$m:$s';
}

String _dos(int n) => n.toString().padLeft(2, '0');

/// Una columna DATE en el body: `yyyy-MM-dd`. Es lo único que acepta un
/// `LocalDate` con `@FechaDiaJson` en el backend: con hora, Jackson lo rechaza.
String? tcpeFechaJson(DateTime? f) =>
    f == null ? null : '${f.year.toString().padLeft(4, '0')}-${_dos(f.month)}-${_dos(f.day)}';

/// Una columna DATETIME (`java.util.Date`) en el body, con la convención del
/// frontend: `yyyy-MM-ddTHH:mm:ss.SSS`. JacksonConfig la lee con su formato
/// `yyyy-MM-dd'T'HH:mm:ss` (los milisegundos sobran y se ignoran).
String? tcpeFechaHoraJson(DateTime? f) =>
    f == null
        ? null
        : '${tcpeFechaJson(f)}T${_dos(f.hour)}:${_dos(f.minute)}:${_dos(f.second)}'
            '.${f.millisecond.toString().padLeft(3, '0')}';
