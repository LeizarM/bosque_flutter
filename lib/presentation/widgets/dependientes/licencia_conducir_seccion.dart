import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/banner_personalizado.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/domain/entities/licencia_conducir_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_licencia_entity.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/formulario_licencia_conducir.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/registro_empleado_provider.dart';
import 'speed_dial.dart';

class LicenciaConducirSeccion extends ConsumerStatefulWidget {
  final int codPersona;
  final bool habilitarEdicion;
  final Map<String, bool> estadoExpandido;
  final Map<String, String?> selectedOperation;
  final Function(String) onToggleSeccion;
  final Function(String?) onUpdateOperation;
  final VoidCallback onEditar;
  final VoidCallback onAgregar;
  final VoidCallback onEliminar;

  const LicenciaConducirSeccion({
    super.key,
    required this.codPersona,
    required this.habilitarEdicion,
    required this.estadoExpandido,
    required this.selectedOperation,
    required this.onToggleSeccion,
    required this.onUpdateOperation,
    required this.onEditar,
    required this.onAgregar,
    required this.onEliminar,
  });

  @override
  ConsumerState<LicenciaConducirSeccion> createState() =>
      _LicenciaConducirSeccionState();
}

class _LicenciaConducirSeccionState
    extends ConsumerState<LicenciaConducirSeccion> {
  String? _bannerMensaje;
  Color? _bannerColor;
  IconData? _bannerIcon;

  Widget autoText(
    String text,
    TextStyle style, {
    int maxLines = 1,
    TextAlign? textAlign,
  }) {
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
  Widget build(BuildContext context) {
    final licenciasAsync =
        ref.watch(obtenerLicenciasConducirProvider(widget.codPersona));
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    final Color icono = isDark ? colorScheme.primary : Colors.teal.shade700;
    final Color textoPrincipal =
        isDark ? colorScheme.onSurface : Colors.grey.shade900;
    final Color textoSecundario =
        isDark ? colorScheme.onSurfaceVariant : Colors.grey.shade600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 8,
        vertical: isDesktop ? 16 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (_bannerMensaje != null)
            BannerCustom(
              message: _bannerMensaje!,
              color: _bannerColor ?? Colors.red,
              icon: _bannerIcon ?? Icons.warning,
              maxLines: 2,
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LICENCIA(S) DE CONDUCIR',
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: textoPrincipal,
                  fontFamily: 'Montserrat',
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.habilitarEdicion)
                CustomSpeedDial(
                  visible: widget.habilitarEdicion,
                  nombreSeccion: 'licenciaConducir',
                  onEditar: widget.onEditar,
                  onAgregar: () => _mostrarDialogoAgregarLicencia(context),
                  onEliminar: widget.onEliminar,
                  updateOperation: widget.onUpdateOperation,
                  operacionHabilitada: const ['editar', 'agregar', 'eliminar'],
                  selectedOperation: widget.selectedOperation,
                ),
            ],
          ),
          Divider(height: 20, color: Colors.grey.withValues(alpha: 0.18)),
          licenciasAsync.when(
            data: (licencias) {
              if (licencias.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'No hay licencias de conducir registradas',
                      style: TextStyle(
                        color: textoSecundario,
                        fontSize: isDesktop ? 15 : 14,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: licencias
                    .map(
                      (licencia) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _buildLicenciaCard(
                          context,
                          licencia,
                          icono,
                          textoPrincipal,
                          textoSecundario,
                        ),
                      ),
                    )
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
                'Error al cargar las licencias: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenciaCard(
    BuildContext context,
    LicenciaConducirEntity licencia,
    Color icono,
    Color textoPrincipal,
    Color textoSecundario,
  ) {
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final estaVencida = licencia.fechaCaducidad.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: estaVencida ? Colors.red.withValues(alpha: 0.05) : null,
        border: Border.all(
          color: estaVencida ? Colors.red.shade300 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard,
            color: estaVencida ? Colors.red.shade700 : icono,
            size: isDesktop ? 24 : 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: DisplayValue<TipoLicenciaEntity>(
                        code: licencia.categoria,
                        provider: obtenerTipoLicenciaConducirProvider,
                        getCode: (tipo) => tipo.codTipos,
                        getDescription: (tipo) => tipo.nombre,
                        fallback: licencia.categoria,
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 15,
                          fontWeight: FontWeight.w600,
                          color: textoPrincipal,
                        ),
                      ),
                    ),
                    if (estaVencida)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Chip(
                          label: const Text(
                            'Vencida',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.redAccent,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
                Text(
                  'Vence: ${FechaUtils.formatDate(licencia.fechaCaducidad)}',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 13,
                    color: estaVencida
                        ? Colors.red.shade600
                        : textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          if (widget.habilitarEdicion) ...[
            if (widget.selectedOperation['licenciaConducir'] == 'editar')
              IconButton(
                icon: Icon(Icons.edit, color: icono),
                tooltip: 'Editar',
                onPressed: () => _mostrarDialogoEditarLicencia(
                  context,
                  licencia,
                ),
              ),
            if (widget.selectedOperation['licenciaConducir'] == 'eliminar')
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Eliminar',
                onPressed: () => ConfirmDialog.show(
                  context,
                  title: 'Eliminar Licencia',
                  content:
                      '¿Está seguro que desea eliminar esta licencia de conducir?',
                  confirmText: 'Eliminar',
                  cancelText: 'Cancelar',
                  confirmColor: Colors.red,
                ).then((confirmed) async {
                  if (confirmed == true && context.mounted) {
                    await executeABM(
                      ref: ref,
                      context: context,
                      operation: () => ref.read(
                        eliminarLicenciaConducirProvider(
                          licencia.codLicencia,
                        ).future,
                      ),
                      providersToInvalidate: [
                        obtenerLicenciasConducirProvider(widget.codPersona),
                      ],
                      successMessage: 'Licencia eliminada correctamente',
                    );
                  }
                }),
              ),
          ],
        ],
      ),
    );
  }

  void _mostrarDialogoAgregarLicencia(BuildContext context) {
  final user = ref.read(userProvider);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      child: FormularioLicenciaConducir(
        title: 'Agregar Licencia de Conducir',
        codPersona: widget.codPersona,
        audUsuario: user?.codUsuario ?? 0,
        isEditing: false,
        onSave: (licencia) async {
          await executeABM(
            ref: ref,
            context: context,
            operation: () => ref.read(
              registrarLicenciaConducirProvider(licencia).future,
            ),
            providersToInvalidate: [
              obtenerLicenciasConducirProvider(widget.codPersona),
            ],
            successMessage: 'Licencia registrada correctamente',
          );
          // ✅ Cerrar diálogo después de guardar exitosamente
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
        onCancel: () {
          // No hacer nada aquí
        },
      ),
    ),
  );
}

void _mostrarDialogoEditarLicencia(
  BuildContext context,
  LicenciaConducirEntity licencia,
) {
  final user = ref.read(userProvider);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      child: FormularioLicenciaConducir(
        title: 'Editar Licencia de Conducir',
        licenciaInicial: licencia,
        codPersona: widget.codPersona,
        audUsuario: user?.codUsuario ?? 0,
        isEditing: true,
        onSave: (licencia) async {
          await executeABM(
            ref: ref,
            context: context,
            operation: () => ref.read(
              registrarLicenciaConducirProvider(licencia).future,
            ),
            providersToInvalidate: [
              obtenerLicenciasConducirProvider(widget.codPersona),
            ],
            successMessage: 'Licencia actualizada correctamente',
          );
          // ✅ Cerrar diálogo después de guardar exitosamente
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
        onCancel: () {
          // No hacer nada aquí
        },
      ),
    ),
  );
}
}