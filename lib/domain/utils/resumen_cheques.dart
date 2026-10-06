import 'package:bosque_flutter/core/utils/formato_moneda.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/utils/situacion_cheque.dart';

/// Los numeros del resumen sobre la tabla. **Se calculan solo con la pagina
/// cargada**: la paginacion es del servidor y no hay totales globales, asi que
/// [pendientes], [atrasados] y [montos] describen estas filas y no todos los
/// cheques del filtro. La pantalla lo rotula asi cuando hay mas de una pagina.
class ResumenPaginaCheques {
  const ResumenPaginaCheques({
    required this.filas,
    required this.pendientes,
    required this.atrasados,
    required this.cobranHoy,
    required this.montos,
  });

  /// Cuantas filas tiene la pagina.
  final int filas;

  /// Los que no estan cerrados.
  final int pendientes;

  /// Pendientes con la fecha de cobro anterior a hoy.
  final int atrasados;

  /// Pendientes que se cobran hoy.
  final int cobranHoy;

  /// El monto de las filas de la pagina, **una suma por moneda** («Bs», «$us»):
  /// nunca se mezclan. Bs primero, $us despues y cualquier otra al final, en el
  /// orden en que aparecio.
  final Map<String, double> montos;

  static const vacio = ResumenPaginaCheques(
    filas: 0,
    pendientes: 0,
    atrasados: 0,
    cobranHoy: 0,
    montos: <String, double>{},
  );
}

/// Resume [filas] con el dia [hoy]. Un cheque sin monto no suma; la moneda sale
/// de `descMoneda` y, si falta, del codigo (`BS` y `SUS`), como el monto de la
/// tabla.
ResumenPaginaCheques resumirPaginaCheques(
  List<ChequeFilaEntity> filas,
  DateTime hoy,
) {
  var pendientes = 0;
  var atrasados = 0;
  var cobranHoy = 0;
  final sumas = <String, double>{};

  for (final f in filas) {
    final s = situacionDeCheque(
      estado: f.cheque.estado,
      fechaCobrar: f.cheque.fechaCobrar,
      hoy: hoy,
    );
    if (s.situacion != SituacionCheque.cerrado) pendientes++;
    if (s.situacion == SituacionCheque.atrasado) atrasados++;
    if (s.situacion == SituacionCheque.cobraHoy) cobranHoy++;

    final monto = f.cheque.monto;
    if (monto != null) {
      final unidad = unidadDeMonedaCheque(f);
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

  return ResumenPaginaCheques(
    filas: filas.length,
    pendientes: pendientes,
    atrasados: atrasados,
    cobranHoy: cobranHoy,
    montos: {for (final u in orden) u: sumas[u]!},
  );
}

/// «Bs», «$us» o el codigo tal cual cuando no es ninguna de las dos.
String unidadDeMonedaCheque(ChequeFilaEntity c) {
  final desc = c.descMoneda.trim();
  // Pasa por `unidad` tambien cuando viene la descripcion: «BS» y «Bs» son la
  // misma moneda y no pueden dar dos sumas.
  return FormatoMoneda.unidad(desc.isNotEmpty ? desc : c.cheque.moneda);
}
