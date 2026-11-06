/// Pestañas del módulo Horas Extras: cada una con su ícono y, si hace falta,
/// un contador; la barra no se desplaza de lado y vibra al elegir.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_colores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formatos.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_haptica.dart';

/// Una pestaña de 48 px con [icono], [texto] y, si se da, el [cuenta] en una
/// ficha de [tonoCuenta]. El texto se acorta antes de desbordar.
Tab pestanaHex({
  required IconData icono,
  required String texto,
  int? cuenta,
  TonoHex tonoCuenta = TonoHex.neutro,
}) => Tab(
  height: 48,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icono, size: 18),
      const SizedBox(width: Esp.xs + 2),
      Flexible(
        child: Text(texto, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      if (cuenta != null) ...[
        const SizedBox(width: Esp.xs + 2),
        Semantics(
          label: cuenta == 1 ? '1 elemento' : '${enteroHex(cuenta)} elementos',
          excludeSemantics: true,
          child: ChipHex(texto: enteroHex(cuenta), tono: tonoCuenta),
        ),
      ],
    ],
  ),
);

/// La barra de pestañas de una pantalla: a la izquierda, de hasta
/// [anchoMaximo], con el alto de 48 px de [pestanaHex] y una vibración suave
/// al tocar una.
class BarraPestanasHex extends StatelessWidget {
  const BarraPestanasHex({
    super.key,
    required this.controlador,
    required this.pestanas,
    this.anchoMaximo = 520,
  });

  final TabController controlador;
  final List<Tab> pestanas;
  final double anchoMaximo;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: anchoMaximo),
      child: TabBar(
        controller: controlador,
        onTap: (_) => HapticaHex.seleccion(),
        // Con el relleno por defecto, «Parámetros» y su ícono se cortan en
        // un teléfono de 360 px con tres pestañas.
        labelPadding: const EdgeInsets.symmetric(horizontal: Esp.xs),
        tabs: pestanas,
      ),
    ),
  );
}
