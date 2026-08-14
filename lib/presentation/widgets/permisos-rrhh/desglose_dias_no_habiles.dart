import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/domain/entities/dia_no_habil_entity.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// **Qué días del rango no se descuentan, uno por uno.**
///
/// El total ya lo decía el bloque de arriba, pero un número solo no se puede
/// verificar: «13 días corridos, se descuentan 8» obliga a confiar. Acá está la
/// resta escrita, con el motivo de cada día que se saltea.
///
/// Nace de un caso real: la función de cálculo cobraba medio día por sábados
/// que a la persona no le tocaba trabajar —36 permisos, 18 días— y nadie lo vio
/// hasta que alguien miró la pantalla y desconfió del número. Esto existe para
/// que desconfiar sea barato.
///
/// **Los domingos los pone esta pantalla, no el servidor.** Se deducen de la
/// fecha; mandarlos por la red sería llenar la respuesta con lo único que no
/// hace falta explicar.
class DesgloseDiasNoHabiles extends ConsumerWidget {
  const DesgloseDiasNoHabiles({
    super.key,
    required this.codEmpleado,
    required this.desde,
    required this.hasta,
  });

  final int codEmpleado;
  final DateTime desde;
  final DateTime hasta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (hasta.isBefore(desde)) return const SizedBox.shrink();

    final delServidor = ref.watch(
      diasNoHabilesProvider((
        codEmpleado: codEmpleado,
        desde: DateTime(desde.year, desde.month, desde.day),
        hasta: DateTime(hasta.year, hasta.month, hasta.day),
      )),
    );

    return delServidor.when(
      // Sin esqueleto ni error a la vista: es información de apoyo. Si no
      // llega, el número de arriba —que sí es el que se graba— sigue estando.
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (lista) => _cuerpo(context, [...lista, ..._domingos()]),
    );
  }

  /// Los domingos del rango. La función de cálculo los descarta siempre, sin
  /// mirar feriados ni rol.
  List<DiaNoHabilEntity> _domingos() {
    final dias = <DiaNoHabilEntity>[];
    var d = DateTime(desde.year, desde.month, desde.day);
    final fin = DateTime(hasta.year, hasta.month, hasta.day);
    while (!d.isAfter(fin)) {
      if (d.weekday == DateTime.sunday) {
        dias.add(
          DiaNoHabilEntity(
            fecha: d,
            tipo: DiaNoHabilEntity.domingo,
            motivo: 'Domingo',
          ),
        );
      }
      d = d.add(const Duration(days: 1));
    }
    return dias;
  }

  Widget _cuerpo(BuildContext context, List<DiaNoHabilEntity> dias) {
    final corridos =
        DateTime(hasta.year, hasta.month, hasta.day)
            .difference(DateTime(desde.year, desde.month, desde.day))
            .inDays +
        1;

    if (dias.isEmpty) {
      return AvisoDelDato(
        icono: Icons.check_circle_outline,
        texto:
            'Los $corridos día(s) del rango son hábiles: no hay feriados, '
            'domingos ni sábados libres en el medio.',
      );
    }

    dias.sort((a, b) => a.fecha.compareTo(b.fecha));

    return Bloque(
      icono: Icons.event_busy_outlined,
      titulo: 'Días que no se descuentan',
      explicacion:
          'De los $corridos día(s) del rango, ${dias.length} no cuentan. '
          'Es la misma regla con la que se graba.',
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final d in dias) _fila(context, d)],
      ),
    );
  }

  Widget _fila(BuildContext context, DiaNoHabilEntity d) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Esp.xs),
    child: Row(
      children: [
        Icon(_icono(d.tipo), size: 18, color: context.cs.outline),
        const SizedBox(width: Esp.s),
        SizedBox(
          width: 96,
          child: Text(
            fechaCorta(d.fecha),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontFeatures: cifrasTabulares),
          ),
        ),
        Expanded(child: Text(d.motivo, style: context.apagado())),
      ],
    ),
  );

  IconData _icono(String tipo) {
    switch (tipo) {
      case DiaNoHabilEntity.feriado:
        return Icons.flag_outlined;
      case DiaNoHabilEntity.sabadoLibre:
        return Icons.weekend_outlined;
      default:
        return Icons.brightness_2_outlined;
    }
  }
}
