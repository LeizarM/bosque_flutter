/// Lectura y escritura tolerantes de los campos JSON del módulo Tickets / Bingo:
/// las banderas llegan como 0/1, las PK como número y las fechas como texto o epoch.
library;

import 'package:intl/intl.dart';

BigInt? ttkBigInt(Object? v) {
  if (v == null) return null;
  if (v is BigInt) return v;
  if (v is int) return BigInt.from(v);
  if (v is num) return BigInt.from(v.toInt());
  return BigInt.tryParse(v.toString().trim());
}

int? ttkIntN(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is BigInt) return v.toInt();
  return int.tryParse(v.toString().trim());
}

int ttkInt(Object? v) => ttkIntN(v) ?? 0;

bool ttkBool(Object? v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final t = v.toString().trim().toLowerCase();
  return t == '1' || t == 'true' || t == 's';
}

String? ttkTextoN(Object? v) {
  if (v == null) return null;
  final t = v.toString();
  return t.trim().isEmpty ? null : t;
}

String ttkTexto(Object? v) => ttkTextoN(v) ?? '';

/// Acepta ISO (`yyyy-MM-ddTHH:mm:ss.SSS`), `yyyy-MM-dd HH:mm:ss` y epoch en ms.
DateTime? ttkFecha(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  final t = v.toString().trim();
  if (t.isEmpty) return null;
  return DateTime.tryParse(t.replaceFirst(' ', 'T'));
}

final DateFormat _formatoFecha = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS");

/// Formato de fecha que espera el backend en los cuerpos.
String? ttkFechaJson(DateTime? f) => f == null ? null : _formatoFecha.format(f);

/// Bandera para el backend: el SP la recibe como BIT/INT.
int? ttkBandera(bool? v) => v == null ? null : (v ? 1 : 0);

/// Quita los null y pasa los BigInt a int: el cuerpo que espera el backend.
Map<String, dynamic> ttkCuerpo(Map<String, Object?> datos) => {
  for (final e in datos.entries)
    if (e.value != null)
      e.key: e.value is BigInt ? (e.value as BigInt).toInt() : e.value,
};

/// Lista de mapas a partir de un valor JSON que puede faltar.
List<Map<String, dynamic>> ttkFilas(Object? v) => [
  if (v is List)
    for (final f in v)
      if (f is Map) Map<String, dynamic>.from(f),
];
