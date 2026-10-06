import 'package:bosque_flutter/domain/entities/verificacion_fila_entity.dart';

/// Los numeros del resumen sobre la lista de verificaciones. **Se calculan solo
/// con la pagina cargada**: la paginacion es del servidor y no hay totales
/// globales, asi que [validas], [anuladas] y [montos] describen estas filas y no
/// todas las del dia. La pantalla lo rotula asi cuando hay mas de una pagina.
class ResumenPaginaVerificaciones {
  const ResumenPaginaVerificaciones({
    required this.filas,
    required this.validas,
    required this.anuladas,
    required this.montos,
    required this.sinMoneda,
  });

  /// Cuantas filas tiene la pagina.
  final int filas;

  /// Verificaciones que valen (`Y`).
  final int validas;

  /// Verificaciones anuladas (`N`).
  final int anuladas;

  /// El monto de los cheques de las verificaciones **validas**, una suma por
  /// moneda («Bs», «$us»): nunca se mezclan. Una anulada no suma: su deposito no
  /// quedo verificado. Bs primero, $us despues y cualquier otra al final.
  final Map<String, double> montos;

  /// Cheques validos con monto cuya moneda el servidor no pudo completar: no se
  /// pueden sumar a ninguna moneda y se avisa cuantos son.
  final int sinMoneda;

  static const vacio = ResumenPaginaVerificaciones(
    filas: 0,
    validas: 0,
    anuladas: 0,
    montos: <String, double>{},
    sinMoneda: 0,
  );
}

/// Resume [filas]. La moneda sale de `descMoneda` y, si falta, del codigo (`BS` y
/// `SUS`), como el importe de la lista; sin ninguna de las dos el monto no se
/// suma a nada y se cuenta en [ResumenPaginaVerificaciones.sinMoneda].
ResumenPaginaVerificaciones resumirPaginaVerificaciones(
  List<VerificacionFilaEntity> filas,
) {
  var validas = 0;
  var anuladas = 0;
  var sinMoneda = 0;
  final sumas = <String, double>{};

  for (final f in filas) {
    if (f.estaAnulada) {
      anuladas++;
      continue;
    }
    if (f.esValida) validas++;
    final monto = f.cheque.montoCheque;
    if (!f.esValida || monto == null) continue;
    final unidad = f.cheque.unidadMoneda;
    if (unidad.isEmpty) {
      sinMoneda++;
    } else {
      sumas[unidad] = (sumas[unidad] ?? 0) + monto;
    }
  }

  // Bs y $us siempre en el mismo orden, para que la cifra no salte de lugar
  // entre una pagina y otra.
  final orden = <String>[
    for (final u in const ['Bs', r'$us'])
      if (sumas.containsKey(u)) u,
    for (final u in sumas.keys)
      if (u != 'Bs' && u != r'$us') u,
  ];

  return ResumenPaginaVerificaciones(
    filas: filas.length,
    validas: validas,
    anuladas: anuladas,
    montos: {for (final u in orden) u: sumas[u]!},
    sinMoneda: sinMoneda,
  );
}
