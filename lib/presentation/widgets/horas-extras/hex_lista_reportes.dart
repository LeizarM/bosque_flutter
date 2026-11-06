/// Lo que comparten las pantallas con lista de reportes (Mis horas, Revisión
/// y Aprobación): la página pedida, el detalle y salir de una página vacía.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_detalle_reporte.dart';

/// Estado de una lista de reportes paginada por el servidor. En el angosto
/// las tarjetas van en el scroll de la pantalla, dentro de [claveLista].
mixin ListaReportesHex<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// La página que se pide al servidor; parte en 1.
  int numeroPagina = 1;

  /// La lista del angosto: al cambiar de página se vuelve a su inicio.
  final GlobalKey claveLista = GlobalKey();

  /// Aplica [cambio] a los filtros y vuelve a la primera página.
  void filtrar(VoidCallback cambio) => setState(() {
    cambio();
    numeroPagina = 1;
  });

  /// La página nueva se muestra desde su primera tarjeta.
  void cambiarPagina(int pagina) {
    setState(() => numeroPagina = pagina);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lista = claveLista.currentContext;
      if (mounted && lista != null) {
        Scrollable.ensureVisible(
          lista,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void verDetalle(HexReporteEntity r) {
    final id = r.idReporte;
    if (id != null) mostrarDetalleReporteHex(context, id);
  }

  /// Para `ref.listen` de una bandeja: si la acción vació la última página
  /// (los reportes salieron), vuelve a la primera, que tiene paginador.
  void siQuedoVacia(
    AsyncValue<PaginaHex<HexReporteEntity>>? _,
    AsyncValue<PaginaHex<HexReporteEntity>> s,
  ) {
    final p = s.valueOrNull;
    if (!s.isLoading && p != null && p.filas.isEmpty && numeroPagina > 1) {
      setState(() => numeroPagina = 1);
    }
  }
}
