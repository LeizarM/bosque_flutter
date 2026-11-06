/// Lectura y escritura tolerantes de los campos JSON del módulo Horas Extras.
/// Las fechas son hora de reloj de La Paz sin zona: nunca se convierten.
library;

import 'package:intl/intl.dart';

BigInt? hexBigInt(Object? v) {
  if (v == null) return null;
  if (v is BigInt) return v;
  if (v is int) return BigInt.from(v);
  if (v is num) return BigInt.from(v.toInt());
  return BigInt.tryParse(v.toString().trim());
}

int? hexIntN(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is BigInt) return v.toInt();
  return int.tryParse(v.toString().trim());
}

int hexInt(Object? v) => hexIntN(v) ?? 0;

/// Bandera `BIT`: llega como `true`, `1`, `'1'` o `'true'`.
bool hexBool(Object? v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final t = v.toString().trim().toLowerCase();
  return t == '1' || t == 'true';
}

String? hexTextoN(Object? v) {
  if (v == null) return null;
  final t = v.toString();
  return t.trim().isEmpty ? null : t;
}

String hexTexto(Object? v) => hexTextoN(v) ?? '';

/// Montos, horas y multiplicadores: número JSON o texto (`BigDecimal`).
double? hexDecimalN(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().trim());
}

double hexDecimal(Object? v) => hexDecimalN(v) ?? 0;

/// Lee `yyyy-MM-dd HH:mm:ss`, ISO y `yyyy-MM-dd` como hora local, sin convertir.
DateTime? hexFecha(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  final t = v.toString().trim();
  return t.isEmpty ? null : DateTime.tryParse(t.replaceFirst(' ', 'T'));
}

final DateFormat _formatoDia = DateFormat('yyyy-MM-dd');
final DateFormat _formatoFechaHora = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS");

/// Columna `DATE` para el backend.
String? hexDiaJson(DateTime? f) => f == null ? null : _formatoDia.format(f);

/// Columna `DATETIME` para el backend: la hora de reloj tal cual, sin zona.
/// Con `toUtc()` o una `Z` el SP la correría 4 horas.
String? hexFechaHoraJson(DateTime? f) =>
    f == null ? null : _formatoFechaHora.format(f);

final RegExp _hora = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?(?:\.\d+)?$');

/// Columna `TIME` como `HH:mm:ss`: quita la fracción y completa `HH:mm`.
String? hexHoraN(Object? v) {
  final m = v == null ? null : _hora.firstMatch(v.toString().trim());
  if (m == null) return null;
  return [m[1]!, m[2]!, m[3] ?? '00'].map((p) => p.padLeft(2, '0')).join(':');
}

/// Quita los null y pasa los BigInt a int: el cuerpo que espera el backend.
Map<String, dynamic> hexCuerpo(Map<String, Object?> datos) => {
  for (final MapEntry(:key, :value) in datos.entries)
    if (value != null) key: value is BigInt ? value.toInt() : value,
};

/// Lista de mapas a partir de un valor JSON que puede faltar.
List<Map<String, dynamic>> hexFilas(Object? v) => [
  if (v is List)
    for (final f in v)
      if (f is Map) Map<String, dynamic>.from(f),
];
