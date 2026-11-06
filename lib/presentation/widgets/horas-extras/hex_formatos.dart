/// Constantes y formatos del módulo Horas Extras: botones, punto de quiebre,
/// cifras, montos, horas, días y fechas. El color de cada estado vive en
/// `hex_colores.dart`.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';

/// Botones del módulo en `tb_vistaBtn`, los mismos del contrato y del SQL.
abstract final class BotonHex {
  static const marcar = 'btnHexMarcar';
  static const anular = 'btnHexAnular';
  static const editarHora = 'btnHexEditarHora';
  static const vistoBueno = 'btnHexVistoBueno';
  static const rechazar = 'btnHexRechazar';
  static const aprobar = 'btnHexAprobar';
  static const aprobarGrupo = 'btnHexAprobarGrupo';
  static const rechazarJefe = 'btnHexRechazarJefe';
  static const ejecutarPlanilla = 'btnHexEjecutarPlanilla';
  static const pdfPlanilla = 'btnHexPdfPlanilla';
  static const anularPlanilla = 'btnHexAnularPlanilla';
  static const editarParametro = 'btnHexEditarParametro';
  static const editarAprobador = 'btnHexEditarAprobador';
}

/// El único punto de quiebre del módulo: desde este ancho de contenedor hay
/// tabla, leyenda a la vista y encabezado amplio; por debajo, lo compacto.
const double hexAnchoTabla = 720;

/// Alto de la espera, el error o el vacío de una lista dentro del
/// desplazamiento de la pantalla.
const double hexAltoEstado = 320;

/// En el ancho, la tabla de una pantalla conserva el alto de la ventana y al
/// menos este: lo que va debajo (la leyenda) no tapa las filas.
const double hexAltoMinimoLista = 420;

/// Cifras de ancho fijo para horas, montos y códigos: se leen como la planilla.
const String hexFuenteCifras = 'JetBrainsMono';

final NumberFormat _dosDecimales = NumberFormat('#,##0.00', 'es');
final NumberFormat _hastaDosDecimales = NumberFormat('#,##0.##', 'es');
final NumberFormat _hastaCuatroDecimales = NumberFormat('#,##0.####', 'es');
final NumberFormat _deDosACuatroDecimales = NumberFormat('#,##0.00##', 'es');
final NumberFormat _entero = NumberFormat('#,##0', 'es');

/// Una cantidad entera con miles a la boliviana: `1.234`. Para cuentas
/// («cuántos reportes»); un código o un número de planilla no se formatea.
String enteroHex(num? v) => v == null ? '—' : _entero.format(v);

/// Un valor que decide un pago (factor, divisor, valor de un parámetro) con
/// hasta 4 decimales, como lo guarda el SP: `1,125`, `240,125`.
String decimalHex(double? v) =>
    v == null ? '—' : _hastaCuatroDecimales.format(v);

/// Lo que se guardará de un número escrito, con al menos 2 decimales para
/// que no se confunda con miles: «1.500,00», «1,50», «1,125».
String decimalSinDudaHex(double? v) =>
    v == null ? '—' : _deDosACuatroDecimales.format(v);

/// Miles con punto y sin decimales, sin 0 adelante: «1.500», «12.345.678»
/// (nunca «0.500», que es un decimal).
final RegExp _soloMiles = RegExp(r'^[1-9]\d{0,2}(\.\d{3})+$');

/// La parte entera antes de la coma: sin puntos o con miles bien puestos.
final RegExp _enteraConComa = RegExp(r'^(\d*|[1-9]\d{0,2}(\.\d{3})+)$');
final RegExp _numeroLimpio = RegExp(r'^\d*\.?\d*$');
final RegExp _unDigito = RegExp(r'\d');

/// Un número escrito como en Bolivia. Con coma, los puntos son miles y la
/// coma es decimal; sin coma, el punto es decimal salvo que parezca miles
/// («1.500» = 1500, «1.5» = 1,5). Nulo si no hay cifras o no se entiende.
double? numeroEscritoHex(String texto) {
  final t = texto.trim();
  if (!_unDigito.hasMatch(t)) return null;
  final String limpio;
  if (t.contains(',')) {
    final partes = t.split(',');
    if (partes.length != 2 || !_enteraConComa.hasMatch(partes.first)) {
      return null;
    }
    limpio = '${partes.first.replaceAll('.', '')}.${partes.last}';
  } else {
    limpio = _soloMiles.hasMatch(t) ? t.replaceAll('.', '') : t;
  }
  if (!_numeroLimpio.hasMatch(limpio)) return null;
  // «15,» o «,5» a medio escribir valen 15 y 0,5.
  var n = limpio;
  if (n.endsWith('.')) n = '${n}0';
  if (n.startsWith('.')) n = '0$n';
  final v = double.tryParse(n);
  return v != null && v.isFinite ? v : null;
}

/// `Bs 1.234,50`; un guion si el SP aún no lo calculó.
String bsHex(double? v) => v == null ? '—' : 'Bs ${_dosDecimales.format(v)}';

/// `2,50 h`.
String horasHex(double? v) => v == null ? '—' : '${_dosDecimales.format(v)} h';

/// Un número sin ceros de más: `1,5`, `2`, `1.234,25`.
String numeroHex(double? v) => v == null ? '—' : _hastaDosDecimales.format(v);

final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');
final DateFormat _formatoReloj = DateFormat('HH:mm');
final DateFormat _formatoDiaMes = DateFormat('dd/MM');

/// `24/10/2026`; un guion si no hay fecha. Reemplaza a `fechaCorta` (del kit
/// compartido) con `DateFormat`, que no se puede cambiar desde el módulo.
String fechaHex(DateTime? f) => f == null ? '—' : _formatoFecha.format(f);

String _dosCifras(int n) => '$n'.padLeft(2, '0');

/// `19:40`, la hora de reloj tal como la guardó el backend.
String relojHex(DateTime? f) => f == null ? '—' : _formatoReloj.format(f);

/// `25/10`: el día de una hora que cae en otro día que su jornada.
String diaMesHex(DateTime f) => _formatoDiaMes.format(f);

/// `24/10/2026 19:40`.
String fechaHoraHex(DateTime? f) =>
    f == null ? '—' : '${fechaHex(f)} ${relojHex(f)}';

/// Respaldo del nombre del mes si los datos de fecha del idioma aún no se
/// cargaron (por ejemplo, en una prueba sin `MaterialApp`).
const List<String> _mesesRespaldo = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

final Map<int, String> _nombresMes = {};

/// El nombre del mes en español, de `DateFormat`.
String _nombreMes(int mes) => _nombresMes.putIfAbsent(mes, () {
  try {
    return DateFormat.MMMM('es').format(DateTime(2000, mes));
  } catch (_) {
    return _mesesRespaldo[mes - 1];
  }
});

/// `octubre de 2026`: el período de un grupo o de una planilla. Un guion si
/// el mes no existe.
String periodoHex(int anio, int mes) =>
    mes < 1 || mes > 12 ? '—' : '${_nombreMes(mes)} de $anio';

/// «1 reporte», «3 reportes»: una cantidad con su sustantivo.
String cuentaHex(int n, String uno, String varios) =>
    '${enteroHex(n)} ${n == 1 ? uno : varios}';

/// El nombre de la sucursal que manda el SP, o su código si no lo mandó.
String sucursalHex(String? nombre, BigInt? codigo) {
  final n = nombre?.trim() ?? '';
  return n.isNotEmpty ? n : 'Sucursal ${codigo ?? '—'}';
}

/// Títulos fijos de los tipos de día (el SP no manda texto para el tramo).
const Map<String, String> tiposDiaHex = {
  'HABIL': 'Día hábil',
  'DOMINGO': 'Domingo',
  'FERIADO': 'Feriado',
};

/// El título de un tipo de día; el código tal cual si no se conoce.
String tipoDiaHex(String codigo) => tiposDiaHex[codigo] ?? codigo;

/// `HH:mm` de una columna `TIME`; con [esFin], `00:00` son las 24:00 (el fin
/// de un tramo o de una ventana).
String horaTramoHex(String? hhmmss, {bool esFin = false}) {
  if (hhmmss == null || hhmmss.length < 5) return '—';
  final hhmm = hhmmss.substring(0, 5);
  return esFin && hhmm == '00:00' ? '24:00' : hhmm;
}

/// La hora de un selector como valor de una columna `TIME`: `08:05:00`.
String horaTimeHex(TimeOfDay h) =>
    '${_dosCifras(h.hour)}:${_dosCifras(h.minute)}:00';

/// El `HH:mm:ss` de una columna `TIME` como hora de un selector; lo que no
/// se entiende vale 0.
TimeOfDay horaDeTimeHex(String? hhmmss) {
  final partes = (hhmmss ?? '').split(':');
  return TimeOfDay(
    hour: int.tryParse(partes.first) ?? 0,
    minute: partes.length > 1 ? int.tryParse(partes[1]) ?? 0 : 0,
  );
}

/// El cambio de un evento: «antes → ahora», solo lo nuevo, o «antes: …» si
/// solo hay valor anterior (algo que se quitó); vacío si no hay ninguno.
String cambioHex(String? anterior, String? nuevo) {
  final antes = anterior?.trim() ?? '';
  final ahora = nuevo?.trim() ?? '';
  return switch ((antes.isEmpty, ahora.isEmpty)) {
    (true, true) => '',
    (false, false) => '$antes → $ahora',
    (true, false) => ahora,
    (false, true) => 'antes: $antes',
  };
}

/// Si [hora] cae en otro día que la [jornada]: una salida pasada la medianoche.
bool otroDiaHex(DateTime? hora, DateTime? jornada) =>
    hora != null && jornada != null && !DateUtils.isSameDay(hora, jornada);

/// El texto o un guion: nunca «null» ni un hueco en pantalla.
String oGuionHex(String? t) => textoUsableHex(t) ?? '—';

/// El texto limpio, o nulo si es nulo, vacío o la palabra «null»: para ocultar
/// lo que no tiene nada que mostrar en lugar de poner un guion.
String? textoUsableHex(String? t) {
  final limpio = t?.trim() ?? '';
  return (limpio.isEmpty || limpio == 'null') ? null : limpio;
}

/// [base] con cifras de ancho fijo, para columnas que se comparan.
TextStyle? estiloCifrasHex(TextStyle? base, {bool fuerte = false}) =>
    base?.copyWith(
      fontFamily: hexFuenteCifras,
      fontFeatures: cifrasTabulares,
      fontWeight: fuerte ? Peso.dato : null,
    );
