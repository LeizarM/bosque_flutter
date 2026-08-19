import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/state/permisos_vacacion_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/solicitud_permiso_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PermisosDashboardWidget extends ConsumerWidget {
  const PermisosDashboardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user == null) return const SizedBox.shrink();

    final proximosAsync = ref.watch(
      proximosPermisosDashboardProvider(user.codUsuario),
    );

    return proximosAsync.when(
      data: (permisos) {
        if (permisos.isEmpty) {
          // Si no hay permisos o no tiene el rol, simplemente no mostramos nada
          return const SizedBox.shrink();
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = Theme.of(context).colorScheme.primary;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : primaryColor.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.flight_takeoff_rounded,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal ausente en los próximos 30 días',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${permisos.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.sync_rounded,
                      size: 20,
                      color: primaryColor,
                    ),
                    tooltip: 'Refrescar',
                    onPressed: () {
                      ref.invalidate(
                        proximosPermisosDashboardProvider(user.codUsuario),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // List/Grid
              Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final crossAxis = ResponsiveUtilsBosque.getResponsiveValue<
                    int
                  >(
                    context: context,
                    defaultValue: 1,
                    mobile: 1,
                    tablet:
                        1, // En tablet mejor 1 columna por lo ancho de la tarjeta
                    desktop:
                        screenWidth > 1500
                            ? 3
                            : 2, // 2 columnas en desktop normal
                  );

                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 350),
                    child:
                        crossAxis > 1
                            ? _buildGrid(
                              context,
                              permisos,
                              primaryColor,
                              isDark,
                              crossAxis,
                            )
                            : _buildList(
                              context,
                              permisos,
                              primaryColor,
                              isDark,
                            ),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    List<SolicitudPermisoEntity> permisos,
    Color primaryColor,
    bool isDark,
    int crossAxisCount,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisExtent:
            88, // Altura reducida ya que la caja de fechas es más compacta
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: permisos.length,
      itemBuilder: (context, index) {
        return _buildPermisoItem(
          context,
          permisos[index],
          primaryColor,
          isDark,
        );
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    List<SolicitudPermisoEntity> permisos,
    Color primaryColor,
    bool isDark,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: permisos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _buildPermisoItem(
          context,
          permisos[index],
          primaryColor,
          isDark,
        );
      },
    );
  }

  Widget _buildPermisoItem(
    BuildContext context,
    SolicitudPermisoEntity permiso,
    Color primaryColor,
    bool isDark,
  ) {
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    IconData icon;
    Color iconColor;
    Color iconBgColor;

    switch (permiso.tipoPermiso.toLowerCase()) {
      case 'vac':
      case 'pva':
        icon = Icons.beach_access_rounded;
        iconColor = Colors.orange;
        iconBgColor = Colors.orange.withValues(alpha: 0.15);
        break;
      case 'baja':
        icon = Icons.local_hospital_rounded;
        iconColor = Colors.red;
        iconBgColor = Colors.red.withValues(alpha: 0.15);
        break;
      case 'sinsuel':
        icon = Icons.money_off_rounded;
        iconColor = Colors.grey.shade600;
        iconBgColor = Colors.grey.withValues(alpha: 0.15);
        break;
      case 'libre':
        icon = Icons.event_available_rounded;
        iconColor = Colors.green;
        iconBgColor = Colors.green.withValues(alpha: 0.15);
        break;
      case 'def':
        icon = Icons.local_florist_rounded;
        iconColor = Colors.purple;
        iconBgColor = Colors.purple.withValues(alpha: 0.15);
        break;
      case 'clb':
        icon = Icons.business_center_rounded;
        iconColor = Colors.blue;
        iconBgColor = Colors.blue.withValues(alpha: 0.15);
        break;
      case 'pcr':
        icon = Icons.update_rounded;
        iconColor = Colors.teal;
        iconBgColor = Colors.teal.withValues(alpha: 0.15);
        break;
      case 'otro':
      default:
        icon = Icons.event_busy_rounded;
        iconColor = primaryColor;
        iconBgColor = primaryColor.withValues(alpha: 0.15);
        break;
    }

    final iconWidget = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 22),
    );

    final infoWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          permiso.nombreEmpleado ?? 'Empleado',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          permiso.sucursalEmpleado != null &&
                  permiso.sucursalEmpleado!.isNotEmpty
              ? '${permiso.cargoEmpleado ?? 'Cargo'} • ${permiso.sucursalEmpleado} • ${permiso.motivo}'
              : '${permiso.cargoEmpleado ?? 'Cargo'} • ${permiso.motivo}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white60 : Colors.grey.shade600,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
    final datesWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 4,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 14,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                permiso.fechasTxt ?? '-',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          if (permiso.diasSolicitadosTxt != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                permiso.diasSolicitadosTxt!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade200,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child:
          isMobile
              ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  iconWidget,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        infoWidget,
                        const SizedBox(height: 10),
                        // La cajita de fechas alineada a la izquierda y abrazando su contenido
                        datesWidget,
                      ],
                    ),
                  ),
                ],
              )
              : Row(
                children: [
                  iconWidget,
                  const SizedBox(width: 14),
                  Expanded(child: infoWidget),
                  const SizedBox(width: 10),
                  datesWidget,
                ],
              ),
    );
  }
}
