import 'package:bosque_flutter/core/state/anticipo_provider.dart';
import 'package:bosque_flutter/domain/entities/anticipo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ══════════════════════════════════════════════════════════════════════════════
// DIÁLOGO MODO ASIGNACIÓN
// ══════════════════════════════════════════════════════════════════════════════
class ModoAsignacionDialog extends ConsumerWidget {
  final AnticipoEntity cabecera;
  final VoidCallback onTigo;
  final VoidCallback onManual;
  const ModoAsignacionDialog({
    super.key,
    required this.cabecera,
    required this.onTigo,
    required this.onManual,
  });

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final cs = Theme.of(ctx).colorScheme;
    final tigoSt = ref.watch(asignacionAnticipoProvider(cabecera.codEmpresa));
    final esTigo =
        cabecera.moduloOrigen != null
            ? cabecera.moduloOrigen!.toUpperCase() == 'TIGO'
            : cabecera.concepto.toUpperCase().contains('TIGO') ||
                cabecera.concepto.toUpperCase().contains('SERVICIO CELULAR');
    ;

    final tigoSub =
        !esTigo
            ? 'El concepto no corresponde a un anticipo de Tigo.'
            : tigoSt.cargando
            ? 'Verificando anticipos Tigo pendientes...'
            : tigoSt.totalRegistros > 0
            ? '${tigoSt.totalRegistros} anticipo(s) sin asignar para esta empresa.'
            : 'Sin anticipos Tigo pendientes para esta empresa.';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 36,
                color: cs.primary,
              ),
              const SizedBox(height: 12),
              const Text(
                '¿Cómo desea asignar?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${cabecera.numAsiento} · Bs. ${fmtAnticipo.format(cabecera.debe)}',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 20),
              ModoOption(
                icon: Icons.phone_android_rounded,
                color: cs.primary,
                titulo: 'Módulo Tigo',
                subtitulo: tigoSub,
                badge:
                    (esTigo && !tigoSt.cargando && tigoSt.totalRegistros > 0)
                        ? '${tigoSt.totalRegistros}'
                        : null,
                habilitado: esTigo,
                onTap: onTigo,
              ),
              const SizedBox(height: 10),
              ModoOption(
                icon: Icons.group_add_rounded,
                color: Colors.deepPurple,
                titulo: 'Distribución Manual',
                subtitulo: 'Selecciona empleados y define montos manualmente.',
                habilitado: true,
                onTap: onManual,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModoOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String titulo;
  final String subtitulo;
  final String? badge;
  final bool habilitado;
  final VoidCallback? onTap;
  const ModoOption({
    super.key,
    required this.icon,
    required this.color,
    required this.titulo,
    required this.subtitulo,
    required this.habilitado,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext ctx) {
    final ef = habilitado ? color : Colors.grey.shade400;
    return InkWell(
      onTap: habilitado ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ef.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: habilitado ? ef.withOpacity(0.4) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ef.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: ef, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: habilitado ? null : Colors.grey.shade500,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            if (habilitado)
              Icon(Icons.arrow_forward_ios_rounded, color: ef, size: 14),
          ],
        ),
      ),
    );
  }
}
