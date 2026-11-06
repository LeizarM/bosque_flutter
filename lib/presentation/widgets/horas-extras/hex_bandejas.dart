/// Piezas de las bandejas de quien revisa y de quien aprueba: la franja de
/// cuántos reportes esperan y la explicación que siempre está a la vista.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_colores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formatos.dart';

/// La franja de arriba de una bandeja: «12 por revisar», con el total que
/// manda el servidor y una línea de [ayuda] que dice qué hacer. Sin reportes
/// (o sin total) no se dibuja: el estado vacío ya lo explica.
class FranjaPorRevisarHex extends StatelessWidget {
  const FranjaPorRevisarHex({
    super.key,
    required this.total,
    required this.ayuda,
    this.verbo = 'por revisar',
  });

  /// El total de reportes que espera la bandeja, tal como lo manda el SP.
  final int? total;

  /// Qué hacer con ellos; en una línea.
  final String ayuda;

  /// Lo que falta hacer: «por revisar» o «por aprobar».
  final String verbo;

  @override
  Widget build(BuildContext context) {
    final n = total;
    if (n == null || n <= 0) return const SizedBox.shrink();
    return AvisoHex(
      tono: TonoHex.pendiente,
      icono: Icons.pending_actions_outlined,
      titulo: '${enteroHex(n)} $verbo',
      texto: ayuda,
    );
  }
}

/// La explicación de una bandeja, siempre a la vista (también en el teléfono):
/// qué muestra y qué se puede hacer con lo que muestra.
class ExplicacionBandejaHex extends StatelessWidget {
  const ExplicacionBandejaHex(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) =>
      AvisoHex(tono: TonoHex.neutro, icono: Icons.info_outline, texto: texto);
}
