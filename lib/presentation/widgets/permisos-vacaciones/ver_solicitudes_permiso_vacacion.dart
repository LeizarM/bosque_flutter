import 'package:bosque_flutter/core/state/permisos_vacacion_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/domain/entities/solicitud_permiso_entity.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-vacaciones/solicitud_permiso_vacacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/domain/entities/tipo_permiso_vacacion_entity.dart';

/// Card para el Dashboard que muestra las solicitudes pendientes de aprobar.
/// El SP decide automáticamente qué ve un Jefe vs RRHH.
class SolicitudesPendientesWidget extends ConsumerWidget {
  const SolicitudesPendientesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user == null) return const SizedBox.shrink();

    final codUsuario = user.codUsuario;
    final pendientesAsync = ref.watch(
      solicitudesPendientesProvider(codUsuario),
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return pendientesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (lista) {
        // Si el SP retornó el registro bandera de "sin permisos", ocultamos el widget por completo.
        if (lista.isNotEmpty && lista.first.nombreEmpleado == 'SIN_PERMISOS') {
          return const SizedBox.shrink();
        }

        // De lo contrario, dibujamos el contenedor y su contenido normal
        return Container(
          decoration: BoxDecoration(
            color:
                isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 10, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.pending_actions_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solicitudes de vacación pendientes',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            lista.isEmpty
                                ? 'Sin pendientes'
                                : '${lista.length} por revisar',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  lista.isEmpty
                                      ? Colors.green[400]
                                      : Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      tooltip: 'Refrescar',
                      onPressed:
                          () => ref.invalidate(
                            solicitudesPendientesProvider(codUsuario),
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Contenido ───────────────────────────────────────────────────
              if (lista.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.green[400],
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'No hay solicitudes pendientes por revisar.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder:
                      (ctx, i) => _SolicitudCard(
                        item: lista[i],
                        codUsuario: codUsuario,
                        onAccionCompletada:
                            () => ref.invalidate(
                              solicitudesPendientesProvider(codUsuario),
                            ),
                      ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card individual — ahora usa SolicitudPermisoEntity directamente
// ─────────────────────────────────────────────────────────────────────────────
class _SolicitudCard extends ConsumerStatefulWidget {
  final SolicitudPermisoEntity item; // ← tipo unificado
  final int codUsuario;
  final VoidCallback onAccionCompletada;

  const _SolicitudCard({
    required this.item,
    required this.codUsuario,
    required this.onAccionCompletada,
  });

  @override
  ConsumerState<_SolicitudCard> createState() => _SolicitudCardState();
}

class _SolicitudCardState extends ConsumerState<_SolicitudCard> {
  bool _cargando = false;
  static final _fmt = DateFormat('dd/MM/yyyy');
  static final _timeFmt = DateFormat('HH:mm');

  // Los auxiliares vienen nullable → fallback a string vacío si no están
  String get _nombre => widget.item.nombreEmpleado ?? '—';
  String get _cargo => widget.item.cargoEmpleado ?? '—';
  String get _paso => widget.item.pasoActual ?? '';
  bool get _esRRHH => _paso.contains('RRHH');
  Color get _color => _esRRHH ? Colors.purple : Colors.blue;

  Widget get _tipoLabelWidget {
    return DisplayValue<TipoPermisoVacacionEntity>(
      code: widget.item.tipoPermiso,
      provider: tiposPermisoProvider,
      getCode: (e) => e.codTipos,
      getDescription: (e) => e.nombre,
      fallback: widget.item.tipoPermiso,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: _color,
      ),
    );
  }

  IconData get _tipoIcon {
    switch (widget.item.tipoPermiso.toUpperCase()) {
      case 'VAC':
        return Icons.beach_access_rounded;
      case 'PVA':
        return Icons.monetization_on_rounded;
      default:
        return Icons.event_note_rounded;
    }
  }

  String _formatearDiasYHoras(double? decimal) {
    if (decimal == null) return '0 días';
    bool isNegative = decimal < 0;
    double absVal = decimal.abs();
    int dias = absVal.truncate();
    double fraccionDia = absVal - dias;
    int horasTrabajoPorDia = 8;
    double horasTotales = fraccionDia * horasTrabajoPorDia;
    int horas = horasTotales.truncate();
    int minutos = ((horasTotales - horas) * 60).round();

    List<String> partes = [];
    if (dias > 0) partes.add('$dias día${dias != 1 ? 's' : ''}');
    if (horas > 0) partes.add('$horas hr${horas != 1 ? 's' : ''}');
    if (minutos > 0) partes.add('$minutos min');

    String texto = partes.isEmpty ? '0 días' : partes.join(' y ');
    return isNegative ? '- $texto' : texto;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // ══════════════════════════════════════════════════════════════════════════
    // EVALUACIÓN INTELIGENTE DEL RANGO TEMPORAL (Corregida)
    // ══════════════════════════════════════════════════════════════════════════

    // Simplificamos: Si es menor a 1, es por horas. ¡Ya no dependemos de variables extra!
    final bool esPorHoras = widget.item.cantidadDias < 1.0;

    final String textoFechas =
        esPorHoras
            // Sacamos la hora directamente de los objetos DateTime nativos
            ? "${_fmt.format(widget.item.desde)} (${_timeFmt.format(widget.item.desde)} a ${_timeFmt.format(widget.item.hasta)})"
            : "${_fmt.format(widget.item.desde)} al ${_fmt.format(widget.item.hasta)}";

    final String textoDias =
        esPorHoras
            ? "${(widget.item.cantidadDias * 8).toStringAsFixed(1)} hrs"
            : "${widget.item.cantidadDias.toStringAsFixed(1)} días";
    // ══════════════════════════════════════════════════════════════════════════

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _cargando ? 0.5 : 1.0,
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
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            _InfoChip(
                              icon: Icons.calendar_today_rounded,
                              label: textoFechas,
                              color: theme.colorScheme.primary,
                            ),
                            _InfoChip(
                              icon: Icons.timer_outlined,
                              label: textoDias,
                              color: Colors.orange[700]!,
                            ),
                          ],
                        ),
                        if (widget.item.diasDisponibles != null &&
                            (widget.item.tipoPermiso.toLowerCase() == 'vac' ||
                                widget.item.tipoPermiso.toLowerCase() ==
                                    'pva')) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _InfoChip(
                                icon: Icons.account_balance_wallet_outlined,
                                label:
                                    'Saldo: ${_formatearDiasYHoras(widget.item.diasDisponibles!)}',
                                color: Colors.green[600]!,
                              ),
                            ],
                          ),
                        ],
                        if (widget.item.autorizador != null &&
                            widget.item.autorizador != '—' &&
                            widget.item.autorizador!.trim().isNotEmpty) ...[
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
                                  'Autorizado por: ${widget.item.autorizador}',
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
                  _ChipPaso(color: _color, child: _tipoLabelWidget),
                ],
              ),
              const SizedBox(height: 12),

              // ── Motivo ─────────────────────────────────────────────────
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
                        widget.item.motivo,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Botones ────────────────────────────────────────────────
              if (_cargando)
                const Center(
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          SolicitudPermisoForm.mostrar(
                            context,
                            codEmpleado: widget.item.codEmpleado,
                            codRelEmplEmpr: widget.item.codRelEmplEmpr,
                            audUsuarioI: widget.codUsuario,
                            solicitudAEditar: widget.item,
                          );
                        },
                        icon: const Icon(
                          Icons.edit_calendar,
                          size: 15,
                          color: Colors.orange,
                        ),
                        label: const Text(
                          'Modificar',
                          style: TextStyle(color: Colors.orange, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.orange.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 9,
                            horizontal: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Rechazar',
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.red.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 9,
                            horizontal: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _mostrarDialogoRechazo(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Aprobar',
                          style: TextStyle(fontSize: 13, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          padding: const EdgeInsets.symmetric(
                            vertical: 9,
                            horizontal: 2,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _mostrarDialogoAprobacion(context),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _aprobar(BuildContext context) {
    setState(() => _cargando = true);
    ref
        .read(accionSolicitudProvider.notifier)
        .aprobar(
          codSolicitud: widget.item.codSolicitud!,
          audUsuarioI: widget.codUsuario,
          onSuccess: (mensaje) {
            if (mounted) setState(() => _cargando = false);
            widget.onAccionCompletada();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(mensaje),
                  backgroundColor: Colors.green[700],
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          onError: (e) {
            setState(() => _cargando = false);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e), backgroundColor: Colors.red),
              );
            }
          },
        );
  }

  void _mostrarDialogoAprobacion(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green),
                SizedBox(width: 8),
                Text('Aprobar solicitud'),
              ],
            ),
            content: Text(
              '¿Está seguro que desea aprobar la solicitud de $_nombre?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _aprobar(context);
                },
                child: const Text(
                  'Confirmar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _mostrarDialogoRechazo(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.cancel_outlined, color: Colors.red),
                SizedBox(width: 8),
                Text('Rechazar solicitud'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Empleado: $_nombre',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  maxLines: 3,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Motivo de rechazo *',
                    hintText: 'Ej: Fechas solapan con otro empleado...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  if (ctrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  setState(() => _cargando = true);
                  ref
                      .read(accionSolicitudProvider.notifier)
                      .rechazar(
                        codSolicitud: widget.item.codSolicitud!,
                        audUsuarioI: widget.codUsuario,
                        motivo: ctrl.text.trim(),
                        onSuccess: (mensaje) {
                          if (mounted) setState(() => _cargando = false);
                          widget.onAccionCompletada();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(mensaje),
                                backgroundColor: Colors.orange[700],
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        onError: (e) {
                          setState(() => _cargando = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      );
                },
                child: const Text(
                  'Confirmar rechazo',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}

// ─── Helpers visuales ────────────────────────────────────────────────────────
class _ChipPaso extends StatelessWidget {
  final Widget child;
  final Color color;
  const _ChipPaso({required this.child, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: child,
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
