import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:intl/intl.dart';

// Coma de miles y punto decimal: 12,345.67 (pedido de RR.HH.).
final NumberFormat _monto = NumberFormat('#,##0.00', 'en_US');
final NumberFormat _entero = NumberFormat('#,##0', 'en_US');
final DateFormat _fechaHora = DateFormat('dd/MM/yy HH:mm');
final DateFormat _momento = DateFormat('dd/MM/yyyy HH:mm');

String montoIncapacidad(double v) => _monto.format(v);
String enteroIncapacidad(int v) => _entero.format(v);
String fechaHoraIncapacidad(DateTime f) => _fechaHora.format(f);

/// Inicio o fin de la baja, con la hora del permiso.
String momentoBaja(DateTime? f) => f == null ? '--' : _momento.format(f);

String periodoBaja(DateTime? desde, DateTime? hasta) =>
    '${momentoBaja(desde)} – ${momentoBaja(hasta)}';

/// Rango del filtro: solo días.
String rangoFiltro(DateTime desde, DateTime hasta) =>
    '${fechaCorta(desde)} – ${fechaCorta(hasta)}';

/// 'CORDES ESPPAPEL - LA PAZ · Nº 77-0304-HLB'. '0' es como queda el número
/// cuando la afiliación no lo tenía al cargar la baja.
String seguroBaja(String seguro, String numSeguro) {
  final nombre = seguro.isEmpty ? 'Sin seguro registrado' : seguro;
  final sinNumero = numSeguro.isEmpty || numSeguro == '0';
  return sinNumero ? '$nombre · sin Nº' : '$nombre · Nº $numSeguro';
}

typedef AtajoRango = ({String nombre, DateTime desde, DateTime hasta});

List<AtajoRango> atajosRangoIncapacidad(DateTime hoy) {
  final dia = DateTime(hoy.year, hoy.month, hoy.day);
  return [
    (nombre: 'Este mes', desde: DateTime(hoy.year, hoy.month), hasta: dia),
    (
      nombre: 'Mes anterior',
      desde: DateTime(hoy.year, hoy.month - 1),
      // El día 0 de un mes es el último del anterior.
      hasta: DateTime(hoy.year, hoy.month, 0),
    ),
    (nombre: 'Este año', desde: DateTime(hoy.year), hasta: dia),
    (
      nombre: 'Año anterior',
      desde: DateTime(hoy.year - 1),
      hasta: DateTime(hoy.year - 1, 12, 31),
    ),
  ];
}
