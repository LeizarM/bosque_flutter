/// El rango de recepcion con el que abre la grilla de cheques y el texto que lo
/// dice. Logica pura, sin Flutter ni Riverpod.
///
/// La grilla pide por defecto los cheques recibidos en los ultimos
/// [mesesPorDefectoGrillaCheques] meses: una sucursal puede tener miles y
/// traerlos todos no le sirve a nadie. El usuario puede cambiar o quitar el
/// rango; quitarlo pide todos.
library;

/// Cuantos meses hacia atras abre la grilla.
const int mesesPorDefectoGrillaCheques = 3;

/// Desde y hasta, los dos incluidos, sin hora.
typedef RangoRecepcionCheques = ({DateTime desde, DateTime hasta});

/// [fecha] menos [meses] meses de calendario, sin hora. Si el dia no existe en
/// el mes de destino se queda en el ultimo (31/05 menos 3 meses es 28/02, o
/// 29/02 en un ano bisiesto). `DateTime(y, m - 3, d)` no sirve: desborda al mes
/// siguiente (31/05 -> 03/03).
DateTime restarMesesCalendario(DateTime fecha, int meses) {
  final indice = fecha.year * 12 + (fecha.month - 1) - meses;
  final anio = indice ~/ 12;
  final mes = indice % 12 + 1;
  // El dia 0 del mes siguiente es el ultimo de este.
  final ultimoDia = DateTime(anio, mes + 1, 0).day;
  return DateTime(anio, mes, fecha.day < ultimoDia ? fecha.day : ultimoDia);
}

/// El rango por defecto de la grilla: de hace [mesesPorDefectoGrillaCheques]
/// meses hasta [hoy]. [hoy] se recibe, no se lee del reloj, para que las pruebas
/// lo fijen.
RangoRecepcionCheques rangoRecepcionPorDefecto(DateTime hoy) {
  final dia = DateTime(hoy.year, hoy.month, hoy.day);
  return (
    desde: restarMesesCalendario(dia, mesesPorDefectoGrillaCheques),
    hasta: dia,
  );
}

String _dmy(DateTime f) =>
    '${f.day.toString().padLeft(2, '0')}/'
    '${f.month.toString().padLeft(2, '0')}/'
    '${f.year.toString().padLeft(4, '0')}';

/// Lo que dice la linea «que rango esta activo» bajo los filtros, para que nadie
/// piense que faltan los cheques viejos.
String textoRangoRecepcion(DateTime? desde, DateTime? hasta) {
  if (desde == null && hasta == null) {
    return 'Mostrando todos los cheques recibidos';
  }
  if (desde != null && hasta != null) {
    if (desde == hasta) return 'Mostrando cheques recibidos el ${_dmy(desde)}';
    return 'Mostrando cheques recibidos del ${_dmy(desde)} al ${_dmy(hasta)}';
  }
  if (desde != null) {
    return 'Mostrando cheques recibidos desde el ${_dmy(desde)}';
  }
  return 'Mostrando cheques recibidos hasta el ${_dmy(hasta!)}';
}
