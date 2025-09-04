import 'dart:ui';

import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/domain/entities/garante_referencia.dart';
import 'package:bosque_flutter/domain/entities/tipo_garante_referencia_entity.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/formulario_garante_referencia.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/speed_dial.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GaranteReferenciaSeccion extends ConsumerWidget {
  final int codEmpleado;
  final bool habilitarEdicion;
  final Map<String, bool> estadoExpandido;
  final Map<String, String?> selectedOperation;
  final Function(String) onToggleSeccion;
  final Function(String?) onUpdateOperation;
  final VoidCallback onEditar;
  final VoidCallback onAgregar;
  final VoidCallback onEliminar;
  final String filtroTipo; // <-- agrega esto
  const GaranteReferenciaSeccion({
    super.key,
    required this.codEmpleado,
    required this.habilitarEdicion,
    required this.estadoExpandido,
    required this.selectedOperation,
    required this.onToggleSeccion,
    required this.onUpdateOperation,
    required this.onEditar,
    required this.onAgregar,
    required this.onEliminar,
    required this.filtroTipo, // <-- agrega esto
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
    final cargarGarRef = ref.watch(obtenerGaranteReferenciaProvider(codEmpleado));
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
      child:SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatText('Garante/Referencia', isDesktop),
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
                  nombreSeccion: 'garanteReferencia',
                  onEditar: onEditar,
                  updateOperation: onUpdateOperation,
                  operacionHabilitada: const [
                    'editar',
                    'agregar',
                    'eliminar',
                  ],
                  onAgregar: () => _mostrarDialogoAgregarGarRef(context, ref),
                  onEliminar: onEliminar,
                  selectedOperation: selectedOperation,
                ),
            ],
          ),
          Divider(height: 20, color: Colors.grey.withOpacity(0.18)),
          cargarGarRef.when(
            // Dentro del cargarGarRef.when(data: ...)
data: (garanteRef) {
   print('GARANTE REF: $garanteRef');
  // Si quieres filtrar por tipo desde un filtro externo:
  List<GaranteReferenciaEntity> listaFiltrada = garanteRef;
  if (filtroTipo == 'gar') {
    listaFiltrada = garanteRef.where((g) => g.tipo == 'gar').toList();
  } else if (filtroTipo == 'ref') {
    listaFiltrada = garanteRef.where((g) => g.tipo == 'ref').toList();
  }

  // Si quieres mostrar ambos bloques separados:
  final garantes = garanteRef.where((g) => g.tipo == 'gar').toList();
  final referencias = garanteRef.where((g) => g.tipo == 'ref').toList();

   if (filtroTipo == 'gar') {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (garantes.isNotEmpty) ...[
          Text('GARANTES', style: TextStyle(fontWeight: FontWeight.bold)),
          ...garantes.map((garante) => _buildGaranteTile(
                context,
                ref,
                garante,
                isDesktop,
                icono,
                textoPrincipal,
                textoSecundario,
              )),
        ] else
          const Text('No hay garantes registrados.'),
      ],
    );
  } else if (filtroTipo == 'ref') {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (referencias.isNotEmpty) ...[
          Text('REFERENCIAS', style: TextStyle(fontWeight: FontWeight.bold)),
          ...referencias.map((referencia) => _buildGaranteTile(
                context,
                ref,
                referencia,
                isDesktop,
                icono,
                textoPrincipal,
                textoSecundario,
              )),
        ] else
          const Text('No hay referencias registradas.'),
      ],
    );
  } else {
    // Mostrar ambos si filtroTipo == 'todos'
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (garantes.isNotEmpty) ...[
          Text('GARANTES', style: TextStyle(fontWeight: FontWeight.bold)),
          ...garantes.map((garante) => _buildGaranteTile(
                context,
                ref,
                garante,
                isDesktop,
                icono,
                textoPrincipal,
                textoSecundario,
              )),
        ],
        if (referencias.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('REFERENCIAS', style: TextStyle(fontWeight: FontWeight.bold)),
          ...referencias.map((referencia) => _buildGaranteTile(
                context,
                ref,
                referencia,
                isDesktop,
                icono,
                textoPrincipal,
                textoSecundario,
              )),
        ],
        if (garantes.isEmpty && referencias.isEmpty)
          const Text('No hay garantes ni referencias registrados.'),
      ],
    );
  }
},
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error al cargar los datos: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildGaranteTile(
    BuildContext context,
    WidgetRef ref,
    GaranteReferenciaEntity garante,
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
            // Línea 1: Nombre completo (máx 2 líneas)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.person_rounded, color: icono, size: isDesktop ? 22 : 18),
                const SizedBox(width: 8),
                Expanded(
                  child: _datoConEtiqueta(
                    etiqueta: 'Nombre completo',
                    valor: garante.nombreCompleto ?? 'Sin registro',
                    colorValor: textoPrincipal,
                    colorIcono: icono,
                    textoSecundario: textoSecundario,
                    isDesktop: isDesktop,
                    maxLines: 2, // máximo 2 líneas para el nombre
                  ),
                ),
                if (habilitarEdicion) ...[
                  if (selectedOperation['garanteReferencia'] == 'editar')
                    IconButton(
                      icon: Icon(Icons.edit, color: icono),
                      tooltip: 'Editar',
                      onPressed: () => _mostrarDialogoEditarFGaranteRef(context, ref, garante),
                    ),
                  if (selectedOperation['garanteReferencia'] == 'eliminar')
                    PermissionWidget(
  buttonName: 'btnEliminarGaranteReferencia', // Usa el nombre exacto de tu BD
  child: IconButton(
    icon: const Icon(Icons.delete, color: Colors.red),
    tooltip: 'Eliminar',
    onPressed: () => ConfirmDialog.show(
      context,
      title: 'Eliminar Garante/Referencia',
      content: '¿Está seguro que desea eliminar esta Garante/Referencia?',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      confirmColor: Colors.red,
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        await ref.read(eliminarGaranteReferenciaProvider(garante.codGarante).future);
        final _ = await ref.refresh(obtenerGaranteReferenciaProvider(codEmpleado).future);
        if (context.mounted) AppSnackbarCustom.showDelete(context, 'Garante/Referencia eliminada correctamente');
      }
    }),
  ),
),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Línea 2: Domicilio y Dirección de trabajo
            Row(
              children: [
                Expanded(
                  child: _datoConEtiqueta(
                    icon: Icons.home,
                    etiqueta: 'Domicilio',
                    valor: garante.direccionDomicilio ?? 'Sin registro',
                    colorValor: textoPrincipal,
                    colorIcono: icono,
                    textoSecundario: textoSecundario,
                    isDesktop: isDesktop,
                    maxLines: 3
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _datoConEtiqueta(
                    icon: Icons.work_rounded,
                    etiqueta: 'Dirección de trabajo',
                    valor: garante.direccionTrabajo,
                    colorValor: textoPrincipal,
                    colorIcono: icono,
                    textoSecundario: textoSecundario,
                    isDesktop: isDesktop,
                    maxLines: 3
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Línea 3: Empresa y Tipo Garante/Referencia
            Row(
              children: [
                Expanded(
                  child: _datoConEtiqueta(
                    icon: Icons.business_rounded,
                    etiqueta: 'Empresa',
                    valor: garante.empresaTrabajo,
                    colorValor: textoPrincipal,
                    colorIcono: icono,
                    textoSecundario: textoSecundario,
                    isDesktop: isDesktop,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final tipoGarante = ref.watch(obtenerTipoGaranteReferenciaProvider);
                      return _datoConEtiqueta(
                        icon: Icons.group_rounded,
                        etiqueta: 'Tipo garante/referencia',
                        valor: tipoGarante.when(
                          data: (tipos) {
                            final tipoGarRef = tipos.firstWhere(
                              (t) => t.codTipos == garante.tipo,
                              orElse: () => TipoGaranteReferenciaEntity(
                                codTipos: '',
                                nombre: 'No encontrado',
                                codGrupo: 0,
                                listTipos: [],
                              ),
                            );
                            return tipoGarRef.nombre;
                          },
                          loading: () => 'Cargando...',
                          error: (_, __) => 'Error',
                        ),
                        colorValor: textoPrincipal,
                        colorIcono: icono,
                        textoSecundario: textoSecundario,
                        isDesktop: isDesktop,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Línea 4: Observación y Empleado
            Row(
              children: [
                Expanded(
                  child: _datoConEtiqueta(
                    icon: Icons.note_rounded,
                    etiqueta: 'Observación',
                    valor: garante.observacion,
                    colorValor: textoPrincipal,
                    colorIcono: icono,
                    textoSecundario: textoSecundario,
                    isDesktop: isDesktop,
                    maxLines: 5, 
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _datoConEtiqueta(
                    icon: Icons.person_rounded,
                    etiqueta: 'Empleado',
                    valor: garante.esEmpleado ?? 'Sin registro',
                    colorValor: textoPrincipal,
                    colorIcono: icono,
                    textoSecundario: textoSecundario,
                    isDesktop: isDesktop,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Línea 5: Teléfonos (máx 2 líneas)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.phone, color: icono, size: isDesktop ? 18 : 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teléfonos',
                        style: TextStyle(
                          fontSize: isDesktop ? 12 : 11,
                          color: textoSecundario,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        garante.telefonos ?? 'Sin registro',
                        style: TextStyle(
                          fontSize: isDesktop ? 14 : 13,
                          color: textoPrincipal,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _datoConEtiqueta({
    IconData? icon,
    required String etiqueta,
    required String valor,
    required Color colorValor,
    required Color colorIcono,
    required Color textoSecundario,
    required bool isDesktop,
    int maxLines = 1,
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
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _mostrarDialogoAgregarGarRef(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: FormularioGaranteReferencia(
        title: 'Agregar Garante/Referencia',
        codEmpleado: codEmpleado,
        isEditing: false,
        onSave: (garanteReferencia) async {
          try {
            await ref.read(
              registrarGaranteReferenciaProvider(
                garanteReferencia,
              ).future,
            );
            ref.invalidate(obtenerGaranteReferenciaProvider(codEmpleado));
            
           
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

void _mostrarDialogoEditarFGaranteRef(
  BuildContext context,
  WidgetRef ref,
  GaranteReferenciaEntity garanteReferencia,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: FormularioGaranteReferencia(
        title: 'Editar Garante/Referencia',
        codEmpleado: codEmpleado,
        isEditing: true,
        garanteReferencia: garanteReferencia,
        onSave: (garanteReferencia) async {
          try {
            await ref.read(
              registrarGaranteReferenciaProvider(
                garanteReferencia,
              ).future,
            );
            ref.invalidate(obtenerGaranteReferenciaProvider(codEmpleado));
            
            
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al editar garante/referencia: $e'),
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
