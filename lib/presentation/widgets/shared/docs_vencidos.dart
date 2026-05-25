import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/docs_vencidos_entity.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget? _buildStatusBadge(String estado) {
  // Color: cualquier valor con 'VENCIDO' → rojo | 'POR VENCER' → naranja
  final isRed = estado.contains('VENCIDO') || estado.contains('VENCIDA');
  final isOrange = estado.contains('POR VENCER');
  if (!isRed && !isOrange) return null;

  final bg = isRed ? Colors.red.shade100 : Colors.orange.shade100;
  final fg = isRed ? Colors.red.shade800 : Colors.orange.shade800;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    margin: const EdgeInsets.only(
      right: 8,
    ), // Fix #3: espacio al campo siguiente
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      estado,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        color: fg,
        letterSpacing: 0.2,
      ),
    ),
  );
}

class DocsVencidosDashboardWidget extends ConsumerWidget {
  const DocsVencidosDashboardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(docsVencidosProvider);
    // Si no hay datos, no hay error y no está cargando → invisible
    if (!state.cargando && state.mensajeError == null && state.items.isEmpty) {
      return const SizedBox.shrink();
    }
    return PermissionWidget(
      buttonName: 'btnDocsVencidos',
      child: const _DocsVencidosCard(),
    );
  }
}

// ─── Card contenedor ──────────────────────────────────────────────────────────
class _DocsVencidosCard extends ConsumerWidget {
  const _DocsVencidosCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(docsVencidosProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final vencidos =
        state.items.where((e) => e.estadoDocumentos == 'VENCIDO').length;
    final proximos = state.items.length - vencidos;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? const Color(0xFF1E2430) : Colors.white,
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 8),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Colors.orange.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  'DOCUMENTOS VENCIDOS / POR VENCER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(width: 6),
                if (vencidos > 0) _Pill(label: '$vencidos', color: Colors.red),
                if (proximos > 0) ...[
                  const SizedBox(width: 3),
                  _Pill(label: '$proximos', color: Colors.orange),
                ],
                const Spacer(),
                // Botón refresh
                state.cargando
                    ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                    )
                    : IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                      ),
                      onPressed:
                          () =>
                              ref
                                  .read(docsVencidosProvider.notifier)
                                  .recargar(),
                    ),
              ],
            ),
          ),

          // ── Divisor ─────────────────────────────────────────────
          Divider(
            height: 1,
            thickness: 1,
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.shade100,
          ),

          // ── Contenido ───────────────────────────────────────────
          if (state.cargando && state.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (state.mensajeError != null && state.items.isEmpty)
            _buildMessage(
              icon: Icons.wifi_off_rounded,
              text: 'No se pudieron cargar los datos',
              isDark: isDark,
              action: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed:
                    () => ref.read(docsVencidosProvider.notifier).recargar(),
                child: const Text('Reintentar', style: TextStyle(fontSize: 11)),
              ),
            )
          else if (state.items.isEmpty)
            _buildMessage(
              icon: Icons.check_circle_outline_rounded,
              iconColor: Colors.green.shade400,
              text: 'Sin documentos críticos',
              isDark: isDark,
            )
          else
            (ResponsiveUtilsBosque.isDesktop(context) ||
                    ResponsiveUtilsBosque.isTablet(context))
                ? _buildDesktopTable(state.items, isDark)
                : ConstrainedBox(
                  // Límite de altura para que no invada la pantalla
                  constraints: const BoxConstraints(maxHeight: 350),
                  child: ListView.separated(
                    shrinkWrap: true,
                    // Habilitamos el scroll internamente
                    physics: const BouncingScrollPhysics(),
                    itemCount: state.items.length,
                    separatorBuilder:
                        (_, __) => Divider(
                          height: 1,
                          thickness: 1,
                          indent: 12,
                          endIndent: 12,
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.grey.shade100,
                        ),
                    itemBuilder:
                        (_, i) =>
                            _ItemRow(item: state.items[i], isDark: isDark),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String text,
    required bool isDark,
    Color? iconColor,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color:
                iconColor ?? (isDark ? Colors.white38 : Colors.grey.shade400),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.grey.shade500,
            ),
          ),
          if (action != null) ...[const SizedBox(width: 4), action],
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<DocsVencidosEntity> items, bool isDark) {
    final headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: isDark ? Colors.white38 : Colors.grey.shade500,
      letterSpacing: 0.4,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Encabezados Fijos ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('EMPLEADO', style: headerStyle)),
              SizedBox(width: 110, child: Text('N° CI', style: headerStyle)),
              SizedBox(width: 100, child: Text('VENC. CI', style: headerStyle)),
              SizedBox(
                width: 120,
                child: Text('VENC. LIC.', style: headerStyle),
              ),
              Expanded(flex: 2, child: Text('ESTADO', style: headerStyle)),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade100,
        ),

        // ── Filas con Scroll ─────────────────────────────────────────────
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300), // Límite de altura
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children:
                  items.asMap().entries.map((e) {
                    final item = e.value;
                    final isEven = e.key % 2 == 0;
                    final textStyle = TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    );
                    return Container(
                      color:
                          isEven
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.025)
                                  : Colors.grey.shade50)
                              : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              item.nombreCompleto,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark
                                        ? Colors.white
                                        : Colors.grey.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            child: Text(item.ciNumero, style: textStyle),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              item.ciFechaVencimiento,
                              style: textStyle,
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Text(
                              item.licenciaVencimiento,
                              style: textStyle,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child:
                                _buildStatusBadge(item.estadoDocumentos) ??
                                Text(
                                  '—',
                                  style: textStyle.copyWith(
                                    color:
                                        isDark
                                            ? Colors.white24
                                            : Colors.grey.shade300,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    );
                  }).toList(), // Transformamos el map a lista para el Column
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─── Fila por empleado: 2 líneas compactas ────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final DocsVencidosEntity item;
  final bool isDark;
  const _ItemRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Línea 1 — Nombre · CI número
          Row(
            children: [
              Flexible(
                child: Text(
                  item.nombreCompleto,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  '·',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white30 : Colors.grey.shade400,
                  ),
                ),
              ),
              Text(
                item.ciNumero,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Línea 2 — CI info + separador + Licencia info
          Wrap(
            spacing: 4,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                children: [
                  _InlineDoc(
                    label: 'CI',
                    fecha: item.ciFechaVencimiento,
                    isDark: isDark,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      width: 1,
                      height: 10,
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.grey.shade300,
                    ),
                  ),
                  _InlineDoc(
                    label: 'LIC',
                    fecha: item.licenciaVencimiento,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  // Badge único al final
                  _buildStatusBadge(item.estadoDocumentos) ??
                      const SizedBox.shrink(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Documento inline: "CI  25/03/2026  [VENCIDO]" ───────────────────────────
class _InlineDoc extends StatelessWidget {
  final String label;
  final String fecha;
  final bool isDark;
  const _InlineDoc({
    required this.label,
    required this.fecha,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: isDark ? Colors.white38 : Colors.grey.shade400,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          fecha,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white60 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// ─── Pill de conteo en el header ──────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final MaterialColor color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color.shade700,
        ),
      ),
    );
  }
}
