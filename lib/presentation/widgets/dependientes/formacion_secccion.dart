import 'dart:ui';

import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/domain/entities/formacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_duracion_formacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_formacion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/formulario_formacion.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/speed_dial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FormacionSecccion extends ConsumerWidget {
  final int codEmpleado;
  final bool habilitarEdicion;
  final Map<String, bool> estadoExpandido;
  final Map<String, String?> selectedOperation;
  final Function(String) onToggleSeccion;
  final Function(String?) onUpdateOperation;
  final VoidCallback onEditar;
  final VoidCallback onAgregar; // Nueva propiedad
  final VoidCallback onEliminar; // Nueva propiedad
  const FormacionSecccion({
    super.key,
    required this.codEmpleado,
    required this.habilitarEdicion,
    required this.estadoExpandido,
    required this.selectedOperation,
    required this.onToggleSeccion,
    required this.onUpdateOperation,
    required this.onEditar,
    required this.onAgregar, // Nuevo requerimiento
    required this.onEliminar, // Nuevo requerimiento
  });
//checkpoint
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

  Widget autoText(String text, TextStyle style, {int maxLines = 1, TextAlign? textAlign}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
        softWrap: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formacionAsync = ref.watch(formacionProvider(codEmpleado));
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
              autoText(
                formatText('Formación', isDesktop),
                TextStyle(
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
                  nombreSeccion: 'formaciones',
                  onEditar: onEditar,
                  onAgregar: () => _mostrarDialogoAgregarFormacion(context, ref),
                  onEliminar: onEliminar,
                  updateOperation: onUpdateOperation,
                  operacionHabilitada: const ['editar', 'agregar', 'eliminar'],
                  selectedOperation: selectedOperation,
                ),
            ],
          ),
          Divider(height: 20, color: Colors.grey.withOpacity(0.18)),
          formacionAsync.when(
            data: (formaciones) {
              if (formaciones.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: autoText(
                      formatText('No hay formaciones registradas', isDesktop),
                      TextStyle(
                        color: textoSecundario,
                        fontSize: isDesktop ? 15 : 14,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                );
              }
              final showScroll = formaciones.length > 4;
              final formacionList = ListView.builder(
                shrinkWrap: true,
                physics: showScroll
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: formaciones.length,
                itemBuilder: (context, index) {
                  final formacion = formaciones[index];
                  return _buildFormacionTile(
                    context,
                    ref,
                    formacion,
                    isDesktop,
                    icono,
                    textoPrincipal,
                    textoSecundario,
                  );
                },
              );

              return showScroll
                  ? SizedBox(
                      height: (4 * 130.0) + 16,
                      child: formacionList,
                    )
                  : Column(
                      children: formaciones
                          .map((formacion) => _buildFormacionTile(
                                context,
                                ref,
                                formacion,
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
                'Error al cargar formaciones: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormacionTile(
    BuildContext context,
    WidgetRef ref,
    FormacionEntity formacion,
    bool isDesktop,
    Color icono,
    Color textoPrincipal,
    Color textoSecundario,
  ) {
    // Diseño tipo ficha clara y simple, con campos agrupados y etiquetas
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Línea 1: Descripción con etiqueta
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school, color: icono, size: isDesktop ? 22 : 18),
                const SizedBox(width: 8),
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
        formatText(formacion.descripcion, isDesktop),
        style: TextStyle(
          fontSize: isDesktop ? 17 : 15,
          color: textoPrincipal,
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
          letterSpacing: 0.1,
        ),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
      ),
    ],
  ),
),
                if (habilitarEdicion) ...[
                  if (selectedOperation['formacion'] == 'editar')
                    IconButton(
                      icon: Icon(Icons.edit, color: icono),
                      tooltip: 'Editar',
                      onPressed: () => _mostrarDialogoEditarFormacion(context, ref, formacion),
                    ),
                  if (selectedOperation['formacion'] == 'eliminar')
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Eliminar',
                      onPressed: () => ConfirmDialog.show(
                        context,
                        title: 'Eliminar Formación',
                        content: '¿Está seguro que desea eliminar esta Formación?',
                        confirmText: 'Eliminar',
                        cancelText: 'Cancelar',
                        confirmColor: Colors.red,
                      ).then((confirmed) async {
                        if (confirmed == true && context.mounted) {
                          await ref.read(eliminarFormacionProvider(formacion.codFormacion).future);
                          final _ = await ref.refresh(formacionProvider(codEmpleado).future);
                          if (context.mounted) AppSnackbarCustom.showDelete(context, 'Formación eliminada correctamente');
                        }
                      }),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            // Línea 2: Dos columnas de datos principales
            Row(
              children: [
                Expanded(
                  child: _datoConEtiqueta(
                    context,
                    icon: Icons.timer,
                    etiqueta: 'Duración',
                    valor: '${formacion.duracion}',
                    color: icono,
                    textoPrincipal: textoPrincipal,
                    textoSecundario: textoSecundario,
                    isDesktop: isDesktop,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final tipoDuracionAsync = ref.watch(obtenerTipoDuracionFormacionProvider);
                      return _datoConEtiqueta(
                        context,
                        icon: Icons.timelapse,
                        etiqueta: 'Tipo duración',
                        valor: tipoDuracionAsync.when(
                          data: (tipos) {
                            final tipoDuracion = tipos.firstWhere(
                              (t) => t.codTipos == formacion.tipoDuracion,
                              orElse: () => TipoDuracionFormacionEntity(
                                codTipos: '',
                                nombre: '',
                                codGrupo: 0,
                                listTipos: [],
                              ),
                            );
                            return tipoDuracion.nombre.isNotEmpty
                                ? formatText(tipoDuracion.nombre, isDesktop)
                                : '';
                          },
                          loading: () => '...',
                          error: (_, __) => 'Error',
                        ),
                        color: icono,
                        textoPrincipal: textoPrincipal,
                        textoSecundario: textoSecundario,
                        isDesktop: isDesktop,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Línea 3: Dos columnas de datos secundarios
            Row(
              children: [
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final tipoFormacionAsync = ref.watch(obtenerTipoFormacionProvider);
                      return _datoConEtiqueta(
                        context,
                        icon: Icons.category,
                        etiqueta: 'Tipo formación',
                        valor: tipoFormacionAsync.when(
                          data: (tipos) {
                            final tipoFormacion = tipos.firstWhere(
                              (t) => t.codTipos == formacion.tipoFormacion,
                              orElse: () => TipoFormacionEntity(
                                codTipos: '',
                                nombre: '',
                                codGrupo: 0,
                                listTipos: [],
                              ),
                            );
                            return tipoFormacion.nombre.isNotEmpty
                                ? formatText(tipoFormacion.nombre, isDesktop)
                                : '';
                          },
                          loading: () => '...',
                          error: (_, __) => 'Error',
                        ),
                        color: icono,
                        textoPrincipal: textoPrincipal,
                        textoSecundario: textoSecundario,
                        isDesktop: isDesktop,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _datoConEtiqueta(
                    context,
                    icon: Icons.calendar_today,
                    etiqueta: 'Fecha de finalización',
                    valor: formacion.fechaFormacion != null
                        ? DateFormat('dd-MM-yyyy').format(formacion.fechaFormacion)
                        : '',
                    color: icono,
                    textoPrincipal: textoPrincipal,
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
    required IconData icon,
    required String etiqueta,
    required String valor,
    required Color color,
    required Color textoPrincipal,
    required Color textoSecundario,
    required bool isDesktop,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: isDesktop ? 18 : 16),
        const SizedBox(width: 4),
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
              autoText(
                valor,
                TextStyle(
                  fontSize: isDesktop ? 14 : 13,
                  color: textoPrincipal,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
//checkpoint
  void _mostrarDialogoAgregarFormacion(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: FormularioFormacion(
        title: 'Agregar Formación',
        codEmpleado: codEmpleado,
        isEditing: false,
        onSave: (formacion) async {
          try {
            await ref.read(registrarFormacionProvider(formacion).future);
            ref.invalidate(formacionProvider(codEmpleado));
            
          
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

  void _mostrarDialogoEditarFormacion(
  BuildContext context,
  WidgetRef ref,
  FormacionEntity formacion,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: FormularioFormacion(
        title: 'Editar Formación',
        codEmpleado: codEmpleado,
        isEditing: true,
        formacion: formacion,
        onSave: (formacion) async {
          try {
            await ref.read(registrarFormacionProvider(formacion).future);
            ref.invalidate(formacionProvider(codEmpleado));
            
            
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al editar la formación: $e'),
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
