import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/solicitud_permiso_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_permiso_vacacion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/core/state/permisos_vacacion_provider.dart';

class SolicitudPermisoCard extends ConsumerWidget {
  final SolicitudPermisoEntity item;
  final bool showEmployeeInfo;
  final Widget? actionButtons;
  final Widget? topTrailingWidget;
  final Widget? statusWidget;
  final bool isCargando;

  const SolicitudPermisoCard({
    super.key,
    required this.item,
    this.showEmployeeInfo = true,
    this.actionButtons,
    this.topTrailingWidget,
    this.statusWidget,
    this.isCargando = false,
  });

  String get _nombre => item.nombreEmpleado ?? '—';
  String get _cargo => item.cargoEmpleado ?? '—';
  String get _paso => item.pasoActual ?? '';
  bool get _esRRHH => _paso.contains('RRHH');
  Color get _color => _esRRHH ? Colors.purple : Colors.blue;

  IconData get _tipoIcon {
    switch (item.tipoPermiso.toUpperCase()) {
      case 'VAC':
        return Icons.beach_access_rounded;
      case 'PVA':
        return Icons.monetization_on_rounded;
      default:
        return Icons.event_note_rounded;
    }
  }

  Widget get _tipoLabelWidget {
    return DisplayValue<TipoPermisoVacacionEntity>(
      code: item.tipoPermiso,
      provider: tiposPermisoProvider,
      getCode: (e) => e.codTipos,
      getDescription: (e) => e.nombre,
      fallback: item.tipoPermiso,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: _color,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String textoFechas = item.fechasTxt ?? 'Sin fechas';
    final String textoDias = item.diasSolicitadosTxt ?? '0 días';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isCargando ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color:
              isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _color.withValues(alpha: 0.25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_tipoIcon, color: _color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showEmployeeInfo) ...[
                          Text(
                            _nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _cargo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (!showEmployeeInfo) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _tipoLabelWidget,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  textoDias,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (showEmployeeInfo)
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              InfoChip(
                                icon: Icons.calendar_today_rounded,
                                label: textoFechas,
                                color: theme.colorScheme.primary,
                              ),
                              InfoChip(
                                icon: Icons.timer_outlined,
                                label: textoDias,
                                color: Colors.orange[700]!,
                              ),
                            ],
                          )
                        else
                          Text(
                            textoFechas,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        if (item.diasDisponibles != null &&
                            (item.tipoPermiso.toLowerCase() == 'vac' ||
                                item.tipoPermiso.toLowerCase() == 'pva')) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              InfoChip(
                                icon: Icons.account_balance_wallet_outlined,
                                label:
                                    'Saldo: ${item.diasDisponiblesTxt ?? "0 días"}',
                                color: Colors.green[600]!,
                              ),
                            ],
                          ),
                        ],
                        if (item.autorizador != null &&
                            item.autorizador != '—' &&
                            item.autorizador!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.assignment_ind_outlined,
                                size: 14,
                                color:
                                    isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Autorizado por: ${item.autorizador}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (topTrailingWidget != null)
                    topTrailingWidget!
                  else if (showEmployeeInfo)
                    ChipPaso(color: _color, child: _tipoLabelWidget),
                ],
              ),
              const SizedBox(height: 12),

              // ── Motivo ──
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? theme.colorScheme.surfaceContainerHighest
                          : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.notes_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.motivo.isNotEmpty
                            ? item.motivo
                            : 'Sin motivo especificado',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (item.motivoRechazo != null &&
                  item.motivoRechazo!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Motivo rechazo: ${item.motivoRechazo}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (statusWidget != null) ...[
                const SizedBox(height: 8),
                statusWidget!,
              ],

              if (actionButtons != null) ...[
                const SizedBox(height: 14),
                actionButtons!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES REUTILIZABLES
// ─────────────────────────────────────────────────────────────────────────────

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChipPaso extends StatelessWidget {
  final Color color;
  final Widget child;

  const ChipPaso({super.key, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: child,
    );
  }
}
