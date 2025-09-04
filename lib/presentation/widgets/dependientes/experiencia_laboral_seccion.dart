import 'dart:ui';

import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/domain/entities/experiencia_laboral_entity.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/formulario_experiencia_laboral.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/speed_dial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ExperienciaLaboralSeccion extends ConsumerWidget {
  final int codEmpleado;
  final bool habilitarEdicion;
  final Map<String, bool> estadoExpandido;
  final Map<String, String?> selectedOperation;
  final Function(String) onToggleSeccion;
  final Function(String?) onUpdateOperation;
  final VoidCallback onEditar;
  final VoidCallback onAgregar; // Nueva función
  final VoidCallback onEliminar; // Nueva función
  const ExperienciaLaboralSeccion({
    super.key,
    required this.codEmpleado,
    required this.habilitarEdicion,
    required this.estadoExpandido,
    required this.selectedOperation,
    required this.onToggleSeccion,
    required this.onUpdateOperation,
    required this.onEditar,
    required this.onAgregar, // Nueva función
    required this.onEliminar, // Nueva función
  });
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      final especiales = ['s.a.', 's.r.l.', 'ipx', 'esppapel'];
      if (especiales.contains(word.toLowerCase())) return word.toUpperCase();
      return _capitalize(word);
    }).join(' ');
  }

  String formatText(String text, bool isDesktop) {
    if (isDesktop) return text.toUpperCase();
    return _capitalizeWords(text);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cargarExpLaboral = ref.watch(experienciaLaboralProvider(codEmpleado));
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color icono = isDark ? colorScheme.primary : Colors.teal.shade700;
    final Color textoPrincipal = isDark ? colorScheme.onSurface : Colors.grey.shade900;
    final Color textoSecundario = isDark ? colorScheme.onSurfaceVariant : Colors.grey.shade600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 8,
        vertical: isDesktop ? 16 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatText('Experiencia Laboral', isDesktop),
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: textoPrincipal,
                  fontFamily: 'Montserrat',
                  letterSpacing: 0.5,
                ),
              ),
              if (habilitarEdicion)
                CustomSpeedDial(
                  visible: habilitarEdicion,
                  nombreSeccion: 'experienciaLaboral',
                  onEditar: onEditar,
                  onAgregar: () => _mostrarDialogoAgregarExpLaboral(context, ref),
                  onEliminar: onEliminar,
                  updateOperation: onUpdateOperation,
                  operacionHabilitada: const ['editar', 'agregar', 'eliminar'],
                  selectedOperation: selectedOperation,
                ),
            ],
          ),
          Divider(height: 20, color: Colors.grey.withOpacity(0.18)),
          cargarExpLaboral.when(
            data: (expLaboral) {
              if (expLaboral.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      formatText('No hay experiencia laboral registrada', isDesktop),
                      style: TextStyle(
                        color: textoSecundario,
                        fontSize: isDesktop ? 15 : 14,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                );
              }
              final showScroll = expLaboral.length > 4;
              final expList = ListView.builder(
                shrinkWrap: true,
                physics: showScroll
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: expLaboral.length,
                itemBuilder: (context, index) {
                  final experiencia = expLaboral[index];
                  return _buildExperienciaTile(
                    context,
                    ref,
                    experiencia,
                    isDesktop,
                    icono,
                    textoPrincipal,
                    textoSecundario,
                  );
                },
              );

              return showScroll
                  ? SizedBox(
                      height: (4 * 150.0) + 16,
                      child: expList,
                    )
                  : Column(
                      children: expLaboral
                          .map((experiencia) => _buildExperienciaTile(
                                context,
                                ref,
                                experiencia,
                                isDesktop,
                                icono,
                                textoPrincipal,
                                textoSecundario,
                              ))
                          .toList(),
                    );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error al cargar Experiencia Laboral: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienciaTile(
    BuildContext context,
    WidgetRef ref,
    ExperienciaLaboralEntity exp,
    bool isDesktop,
    Color icono,
    Color textoPrincipal,
    Color textoSecundario,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Línea 1: Empresa (etiqueta + valor)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.business_rounded, color: icono, size: isDesktop ? 22 : 18),
                const SizedBox(width: 8),
                Expanded(
                  child: _datoConEtiqueta(
                    context,
                    etiqueta: 'Empresa',
                    valor: formatText(exp.nombreEmpresa, isDesktop),
                    colorValor: textoPrincipal,
                    colorIcono: icono,
                    textoSecundario: textoSecundario,
                    isDesktop: isDesktop,
                  ),
                ),
                if (habilitarEdicion) ...[
                  if (selectedOperation['experienciaLaboral'] == 'editar')
                    IconButton(
                      icon: Icon(Icons.edit, color: icono),
                      tooltip: 'Editar',
                      onPressed: () => _mostrarDialogoEditarExpLaboral(context, ref, exp),
                    ),
                  if (selectedOperation['experienciaLaboral'] == 'eliminar')
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Eliminar',
                      onPressed: () => ConfirmDialog.show(
                        context,
                        title: 'Eliminar Experiencia Laboral',
                        content: '¿Está seguro que desea eliminar esta Experiencia Laboral?',
                        confirmText: 'Eliminar',
                        cancelText: 'Cancelar',
                        confirmColor: Colors.red,
                      ).then((confirmed) async {
                        if (confirmed == true && context.mounted) {
                          await ref.read(eliminarExperienciaLaboralProvider(exp.codExperienciaLaboral).future);
                          final _ = await ref.refresh(experienciaLaboralProvider(codEmpleado).future);
                          if (context.mounted) AppSnackbarCustom.showDelete(context, 'Experiencia Laboral eliminada correctamente');
                        }
                      }),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Línea 2: Cargo y Teléfono de referencia
            Row(
              children: [
                Expanded(
                  child: _datoConEtiqueta(
                    context,
                    icon: Icons.work_rounded,
                    etiqueta: 'Cargo',
                    valor: formatText(exp.cargo, isDesktop),
                    colorValor: textoPrincipal,
                    colorIcono: icono,
                    textoSecundario: textoSecundario,
                    isDesktop: isDesktop,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _datoConEtiqueta(
                    context,
                    icon: Icons.phone,
                    etiqueta: 'Teléfono referencia',
                    valor: exp.nroReferencia,
                    colorValor: textoPrincipal,
                    colorIcono: icono,
                    textoSecundario: textoSecundario,
                    isDesktop: isDesktop,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Línea 3: Descripción (máx 2 líneas)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description, color: icono, size: isDesktop ? 18 : 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: isDesktop ? 12 : 11,
                          color: textoSecundario,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        formatText(exp.descripcion, isDesktop),
                        style: TextStyle(
                          fontSize: isDesktop ? 14 : 13,
                          color: textoPrincipal,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Línea 4: Fechas
            Row(
              children: [
                Expanded(
                  child: _datoConEtiqueta(
                    context,
                    icon: Icons.calendar_today,
                    etiqueta: 'Fecha de inicio',
                    valor: exp.fechaInicio != null
                        ? DateFormat('dd-MM-yyyy').format(exp.fechaInicio!)
                        : '',
                    colorValor: textoPrincipal,
                    colorIcono: icono,
                    textoSecundario: textoSecundario,
                    isDesktop: isDesktop,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _datoConEtiqueta(
                    context,
                    icon: Icons.calendar_today,
                    etiqueta: 'Fecha de finalización',
                    valor: exp.fechaFin != null
                        ? DateFormat('dd-MM-yyyy').format(exp.fechaFin!)
                        : '',
                    colorValor: textoPrincipal,
                    colorIcono: icono,
                    textoSecundario: textoSecundario,
                    isDesktop: isDesktop,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _datoConEtiqueta(
    BuildContext context, {
    IconData? icon,
    required String etiqueta,
    required String valor,
    required Color colorValor,
    required Color colorIcono,
    required Color textoSecundario,
    required bool isDesktop,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, color: colorIcono, size: isDesktop ? 18 : 16),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: TextStyle(
                  fontSize: isDesktop ? 12 : 11,
                  color: textoSecundario,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                valor,
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 13,
                  color: colorValor,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _mostrarDialogoAgregarExpLaboral(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: FormularioExperienciaLaboral(
        title: 'Agregar Experiencia Laboral',
        codEmpleado: codEmpleado,
        isEditing: false,
        onSave: (expLaboral) async {
          try {
            await ref.read(registrarExperienciaLaboralProvider(expLaboral).future);
            ref.invalidate(experienciaLaboralProvider(codEmpleado));
            
           
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
            rethrow;
          }
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    ),
  );
}

void _mostrarDialogoEditarExpLaboral(
  BuildContext context,
  WidgetRef ref,
  ExperienciaLaboralEntity expLaboral,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: FormularioExperienciaLaboral(
        title: 'Editar Experiencia Laboral',
        codEmpleado: codEmpleado,
        isEditing: true,
        experienciaLaboral: expLaboral,
        onSave: (expLaboral) async {
          try {
            await ref.read(registrarExperienciaLaboralProvider(expLaboral).future);
            ref.invalidate(experienciaLaboralProvider(codEmpleado));
            
           
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al editar experiencia laboral: $e'),
                backgroundColor: Colors.red,
              ),
            );
            rethrow;
          }
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    ),
  );
}
}
