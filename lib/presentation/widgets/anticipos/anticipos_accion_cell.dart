import 'package:bosque_flutter/core/state/anticipo_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/domain/entities/anticipo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_asignacion_manual_sheet.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_constants.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CELDA DE ACCIÓN
// ══════════════════════════════════════════════════════════════════════════════
class AnticiposAccionCell extends ConsumerWidget {
  final AnticipoEntity anticipo;
  final VoidCallback onAsignar;
  final VoidCallback onVerDetalle;
  final int uid;

  const AnticiposAccionCell({
    super.key,
    required this.anticipo,
    required this.onAsignar,
    required this.onVerDetalle,
    required this.uid,
  });

  void _confirmarAnulacion(BuildContext ctx, WidgetRef ref) {
    final cs = Theme.of(ctx).colorScheme;
    showDialog(
      context: ctx,
      builder:
          (dCtx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: Icon(Icons.warning_amber_rounded, color: cs.error, size: 36),
            title: const Text('Anular Anticipo', textAlign: TextAlign.center),
            content: Text(
              '¿Confirma la anulación de ${anticipo.numAsiento}?\n\n'
              'Los detalles serán devueltos o anulados según el módulo origen.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(dCtx),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: cs.error),
                onPressed: () {
                  Navigator.pop(dCtx);
                  final emp = ref.read(codEmpresaAnticiposProvider);
                  ref
                      .read(anticipoProvider(emp).notifier)
                      .anularAnticipo(
                        anticipo.codAnticipo,
                        ref.read(userProvider)?.codUsuario ?? 0,
                      );
                },
                child: const Text('Sí, Anular'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final cs = Theme.of(ctx).colorScheme;
    if (anticipo.fechaAsiento.year < DateTime.now().year) {
      return const SizedBox.shrink();
    }
    final estado = anticipo.estado.toUpperCase();

    if (estado == 'NO ASIGNADO') {
      final anioAnticipo = anticipo.fechaAsiento.year;
      if (anioAnticipo < DateTime.now().year) {
        return AnticiposIconBtn(
          icon: Icons.visibility_outlined,
          color: cs.primary,
          tip: 'Ver (Gestión pasada)',
          onTap: onVerDetalle,
        );
      }
      return PermissionWidget(
        buttonName: 'btnAsignarAnticipo',
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            textStyle: const TextStyle(fontSize: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.assignment_ind_outlined, size: 14),
          label: const Text('Asignar'),
          onPressed: onAsignar,
        ),
      );
    }

    final esManual = anticipo.moduloOrigen?.toUpperCase() != 'TIGO';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnticiposIconBtn(
          icon: Icons.visibility_outlined,
          color: cs.primary,
          tip: 'Ver detalle',
          onTap: onVerDetalle,
        ),
        if (estado == 'ASIGNADO')
          ref
              .watch(restriccionAccionesProvider(anticipo.codAnticipo))
              .when(
                data: (tieneRestriccion) {
                  if (tieneRestriccion) return const SizedBox.shrink();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (esManual)
                        PermissionWidget(
                          buttonName: 'btnEditarAnticipo',
                          child: AnticiposIconBtn(
                            icon: Icons.edit_rounded,
                            color: Colors.orange.shade700,
                            tip: 'Editar distribución',
                            onTap:
                                () => showModalBottomSheet(
                                  context: ctx,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder:
                                      (_) => AsignacionManualSheet(
                                        cabecera: anticipo,
                                        audUsuarioI:
                                            ref
                                                .read(userProvider)
                                                ?.codUsuario ??
                                            0,
                                        esEdicion: true,
                                      ),
                                ),
                          ),
                        ),
                      PermissionWidget(
                        buttonName: 'btnAnularAnticipo',
                        child: AnticiposIconBtn(
                          icon: Icons.cancel_outlined,
                          color: cs.error,
                          tip: 'Anular',
                          onTap: () => _confirmarAnulacion(ctx, ref),
                        ),
                      ),
                    ],
                  );
                },
                loading:
                    () => SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: cs.outline,
                      ),
                    ),
                error: (_, __) => const SizedBox.shrink(),
              ),
      ],
    );
  }
}

/// Botón icono compacto con tooltip
class AnticiposIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tip;
  final VoidCallback? onTap;
  const AnticiposIconBtn({
    super.key,
    required this.icon,
    required this.color,
    required this.tip,
    this.onTap,
  });

  @override
  Widget build(BuildContext ctx) => Tooltip(
    message: tip,
    child: InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
      ),
    ),
  );
}
