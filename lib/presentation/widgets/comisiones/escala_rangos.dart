import 'package:flutter/material.dart';

import 'package:bosque_flutter/domain/entities/comision_por_rango_entity.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

/// Escala visual de comisión por días de pago: una banda continua donde cada
/// segmento ocupa el ancho de sus días y se pinta con intensidad proporcional al
/// porcentaje, de modo que se ven la pendiente y los huecos entre tramos.
///
/// Los centinelas («anticipado», tramo negativo, y «sin tope», hasta 1.000.000)
/// son extremos abiertos, no días: llevan ancho fijo en px y quedan FUERA del
/// reparto por flex, para que el ancho de los demás siga siendo la verdad.
class EscalaRangos extends StatelessWidget {
  const EscalaRangos({
    super.key,
    required this.rangos,
    this.alTocar,
    this.alto = 72,
  });

  final List<ComisionPorRangoEntity> rangos;
  final void Function(ComisionPorRangoEntity)? alTocar;

  /// Alto de la banda. 72 y no 60: a 60 el hueco interno queda en 44px contra 47px
  /// de contenido con textScale 1.3 y desborda (la app no clampea el textScaler);
  /// 72 aguanta hasta 1.5.
  final double alto;

  @override
  Widget build(BuildContext context) {
    if (rangos.isEmpty) return const SizedBox.shrink();

    final ordenados = [...rangos]..sort((a, b) => a.min.compareTo(b.min));
    final maxComision = ordenados
        .map((r) => r.comisionVisual)
        .fold<double>(0, (a, b) => a > b ? a : b);

    // Si TODOS son centinelas, sacarlos del flex dejaría la banda en ~61px de 797
    // con el resto en blanco. Caso real: el fixture del test de responsive
    // ('Contado' solo anticipado, 'Credito' solo sinTope).
    final soloCentinelas = ordenados.every(_esCentinela);

    return LayoutBuilder(
      builder: (context, c) {
        return SizedBox(
          height: alto,
          child: Row(
            children: [
              for (final r in ordenados)
                if (_esCentinela(r) && !soloCentinelas)
                  SizedBox(
                    width: _anchoCentinela(c.maxWidth),
                    child: _segmento(r, maxComision),
                  )
                else
                  Expanded(flex: _peso(r), child: _segmento(r, maxComision)),
            ],
          ),
        );
      },
    );
  }

  Widget _segmento(ComisionPorRangoEntity r, double maxComision) => _Segmento(
    rango: r,
    intensidad: maxComision == 0 ? 0 : r.comisionVisual / maxComision,
    alTocar: alTocar == null ? null : () => alTocar!(r),
  );

  static bool _esCentinela(ComisionPorRangoEntity r) =>
      r.esAnticipado || r.sinTope;

  /// Ancho del centinela, proporcional a la banda con piso y techo. No un
  /// `SizedBox(width: 64)` fijo: "Anticipado" mide 115px y en 64 el FittedBox lo
  /// baja a escala 0.426 (~4,7px de tipografía), ilegible.
  static double _anchoCentinela(double banda) =>
      (banda * 0.16).clamp(56.0, 120.0);

  /// Ancho relativo del segmento, en dias.
  static int _peso(ComisionPorRangoEntity r) {
    if (_esCentinela(r)) return 1;
    return (r.max - r.min + 1).clamp(1, 200);
  }
}

class _Segmento extends StatelessWidget {
  const _Segmento({
    required this.rango,
    required this.intensidad,
    this.alTocar,
  });

  final ComisionPorRangoEntity rango;
  final double intensidad;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // La intensidad codifica el porcentaje. Se parte de 0.18 para que el tramo
    // mas bajo siga siendo visible y no se confunda con un hueco.
    final opacidad = 0.18 + (intensidad * 0.62);
    final fondo = cs.primary.withValues(alpha: opacidad);
    final texto = opacidad > 0.55 ? cs.onPrimary : cs.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: Material(
        color: fondo,
        borderRadius: ComisionesTema.brChip,
        child: InkWell(
          onTap: alTocar,
          borderRadius: ComisionesTema.brChip,
          child: Tooltip(
            message:
                '${rango.tipo} · ${rango.rangoLegible}\n'
                '${rango.comisionVisual.toStringAsFixed(2)} %',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${rango.comisionVisual.toStringAsFixed(2)}%',
                      style: ComisionesTema.numeroTotal(
                        context,
                      )?.copyWith(color: texto),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      rango.esAnticipado
                          ? 'Anticipado'
                          : rango.sinTope
                          ? '${rango.min}+ d'
                          : '${rango.min}-${rango.max} d',
                      style: tt.labelSmall?.copyWith(
                        color: texto.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
