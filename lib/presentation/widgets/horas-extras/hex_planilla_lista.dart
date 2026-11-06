/// La lista de planillas ejecutadas de las pantallas de RRHH (Planilla y
/// Anular planilla): el SP manda todas y aquí se paginan de a [planillasPorPaginaHex].
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_planilla_ejecutada.dart';

/// Planillas por página: la lista llega completa y se pagina en la pantalla.
const int planillasPorPaginaHex = 20;

/// Tabla desde [anchoMinimoTabla] y tarjetas por debajo. Con una sola página
/// no hay paginador. En el ancho va en una caja con el alto de sus filas.
class ListaPlanillasHex extends StatelessWidget {
  const ListaPlanillasHex({
    super.key,
    required this.planillas,
    required this.pagina,
    required this.alCambiarPagina,
    required this.anchoLista,
    required this.altoMaximo,
    required this.columnas,
    required this.tarjeta,
    required this.vacio,
    this.alTocarFila,
    this.anchoMinimoTabla = anchoTablaPlanillasHex,
    this.porFila,
  });

  /// Todas las planillas a mostrar; la página sale de aquí.
  final List<HexPlanillaEntity> planillas;
  final int pagina;
  final ValueChanged<int> alCambiarPagina;

  /// El ancho de la lista (sin el relleno de la pantalla) decide tabla o tarjetas.
  final double anchoLista;

  /// El alto que puede tomar la tabla en el ancho (el de la ventana).
  final double altoMaximo;
  final List<BosqueColumn<HexPlanillaEntity>> columnas;
  final Widget Function(HexPlanillaEntity) tarjeta;
  final Widget vacio;
  final ValueChanged<HexPlanillaEntity>? alTocarFila;
  final double anchoMinimoTabla;

  /// Alto de una fila si sus celdas son más altas que lo usual.
  final double? porFila;

  @override
  Widget build(BuildContext context) {
    final tabla = usaTablaHex(anchoLista, anchoMinimoTabla);
    final paginas = math.max(
      1,
      (planillas.length / planillasPorPaginaHex).ceil(),
    );
    final actual = pagina.clamp(1, paginas);
    final desde = (actual - 1) * planillasPorPaginaHex;
    final filas = planillas.sublist(
      desde,
      math.min(desde + planillasPorPaginaHex, planillas.length),
    );
    final lista = ListadoHex<HexPlanillaEntity>(
      filas: filas,
      pagina: actual,
      total: planillas.length,
      tamano: planillasPorPaginaHex,
      // Con una sola página no hay paginador.
      alCambiarPagina: paginas > 1 ? alCambiarPagina : null,
      anchoMinimoTabla: anchoMinimoTabla,
      desplazamientoExterno: !tabla,
      alTocarFila: alTocarFila,
      vacio: vacio,
      columnas: columnas,
      tarjeta: tarjeta,
    );
    return cajaTablaHex(
      tabla: tabla,
      filas: filas.length,
      maximo: altoMaximo,
      conPaginador: paginas > 1,
      porFila: porFila,
      lista: lista,
    );
  }
}
