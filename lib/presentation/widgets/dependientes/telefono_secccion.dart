import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/banner_personalizado.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/telefono_entity.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/formulario_telefono.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/state/empleados_dependientes_provider.dart';
import 'speed_dial.dart';

class TelefonoSection extends ConsumerStatefulWidget {
  const TelefonoSection({
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

  final int codPersona;
  final bool habilitarEdicion;
  final Map<String, bool> estadoExpandido;
  final Map<String, String?> selectedOperation;
  final Function(String) onToggleSeccion;
  final Function(String?) onUpdateOperation;
  final VoidCallback onEditar;
  final VoidCallback onAgregar;
  final VoidCallback onEliminar;

  @override
  ConsumerState<TelefonoSection> createState() => _TelefonoSectionState();
}
class _TelefonoSectionState extends ConsumerState<TelefonoSection> {
  bool _advertenciaMostrada = false;
  String? _bannerMensaje;
  Color? _bannerColor;
  IconData? _bannerIcon;
  
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
  Widget build(BuildContext context) {
    final telefonosAsync = ref.watch(telefonoProvider(widget.codPersona));
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

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
          if (_bannerMensaje != null)
        BannerCustom(
          message: _bannerMensaje!,
          color: _bannerColor ?? Colors.red,
          icon: _bannerIcon ?? Icons.warning,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatText('Teléfono(s)', isDesktop),
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
                  nombreSeccion: 'telefono',
                  onEditar: widget.onEditar,
                  onAgregar: () => _mostrarDialogoAgregarTelefono(context, ref),
                  onEliminar: widget.onEliminar,
                  updateOperation: widget.onUpdateOperation,
                  operacionHabilitada: const ['editar', 'agregar', 'eliminar'],
                  selectedOperation: widget.selectedOperation,
                ),
            ],
          ),
          Divider(height: 20, color: Colors.grey.withOpacity(0.18)),
          telefonosAsync.when(
            data: (telefonos) {
               WidgetsBinding.instance.addPostFrameCallback((_) {
    _advertirSiSinTelefonos(context, ref, telefonos);
  });
              if (telefonos.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: autoText(
                      formatText('No hay teléfonos registrados', isDesktop),
                      TextStyle(
                        color: textoSecundario,
                        fontSize: isDesktop ? 15 : 14,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                );
              }
              final showScroll = telefonos.length > 5;
              final telefonoList = ListView.builder(
                shrinkWrap: true,
                physics: showScroll
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: telefonos.length,
                itemBuilder: (context, index) {
                  final telefono = telefonos[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          telefono.tipo == 'Móvil'
                              ? Icons.phone_android
                              : Icons.phone,
                          color: icono,
                          size: isDesktop ? 18 : 16,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                telefono.tipo??'',
                                style: TextStyle(
                                  fontSize: isDesktop ? 12 : 11,
                                  color: textoSecundario,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
  children: [
    Expanded(
      child: GestureDetector(
        onTap: () async {
          if (!isDesktop) {
            final uri = Uri(scheme: 'tel', path: telefono.telefono);
           
              await launchUrl(uri,mode: LaunchMode.externalApplication);
            
          }
        },
        child: autoText(
          telefono.telefono,
          TextStyle(
            fontSize: isDesktop ? 16 : 15,
            color: textoPrincipal,
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
            letterSpacing: 0.1,
            decoration: !isDesktop ? TextDecoration.underline : null,
          ),
          maxLines: 1,
        ),
      ),
    ),
    IconButton(
      icon: const Icon(Icons.copy, size: 18),
      tooltip: 'Copiar',
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: telefono.telefono));
        if (context.mounted) {
  AppSnackbarCustom.showSuccess(context, 'Teléfono copiado');
}
      },
    ),
    IconButton(
      icon: Image.asset(
        'assets/icon/whatsapp.png',
        width: 22,
        height: 22,
      ),
      tooltip: 'Enviar WhatsApp',
      onPressed: () async {
        final numero = telefono.telefono.replaceAll(RegExp(r'\D'), '');
        final url = Uri.parse('https://wa.me/$numero');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else if (context.mounted) {
          AppSnackbarCustom.showError(context, 'No se pudo abrir WhatsApp');
        }
      },
    ),
  ],
),
                            ],
                          ),
                        ),
                        if (widget.habilitarEdicion) ...[
                          if (widget.selectedOperation['telefono'] == 'editar')
                            IconButton(
                              icon: Icon(Icons.edit, color: icono),
                              tooltip: 'Editar',
                              onPressed: () => _mostrarDialogoEditarTelefono(context, ref, telefono),
                            ),
                          if (widget.selectedOperation['telefono'] == 'eliminar')
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Eliminar',
                              onPressed: () => ConfirmDialog.show(
                                context,
                                title: 'Eliminar Teléfono',
                                content: '¿Está seguro que desea eliminar este teléfono?',
                                confirmText: 'Eliminar',
                                cancelText: 'Cancelar',
                                confirmColor: Colors.red,
                              ).then((confirmed) async {
                                if (confirmed == true && context.mounted) {
                                  await ref.read(eliminarTelefonoProvider(telefono.codTelefono).future);
                                  final _ =ref.refresh(telefonoProvider(widget.codPersona));
                                  if (context.mounted) AppSnackbarCustom.showDelete(context, 'Teléfono eliminado correctamente');
                                }
                              }),
                            ),
                        ],
                      ],
                    ),
                  );
                },
              );

              return showScroll
                  ? SizedBox(
                      height: (4 * 48.0) + 16,
                      child: telefonoList,
                    )
                  : Column(
                      children: telefonos.map((telefono) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              telefono.tipo == 'Móvil'
                                  ? Icons.phone_android
                                  : Icons.phone,
                              color: icono,
                              size: isDesktop ? 18 : 16,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    telefono.tipo??'',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 12 : 11,
                                      color: textoSecundario,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Row(
  children: [
    Expanded(
      child: GestureDetector(
        onTap: () async {
          if (!isDesktop) {
            final uri = Uri(scheme: 'tel', path: telefono.telefono);
            
              await launchUrl(uri,mode: LaunchMode.externalApplication);
            
          }
        },
        child: autoText(
          telefono.telefono,
          TextStyle(
            fontSize: isDesktop ? 16 : 15,
            color: textoPrincipal,
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
            letterSpacing: 0.1,
            decoration: !isDesktop ? TextDecoration.underline : null,
          ),
          maxLines: 1,
        ),
      ),
    ),
    IconButton(
      icon: const Icon(Icons.copy, size: 18),
      tooltip: 'Copiar',
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: telefono.telefono));
       if (context.mounted) {
  AppSnackbarCustom.showSuccess(context, 'Teléfono copiado');
}
      },
    ),
    IconButton(
      icon: Image.asset(
        'assets/icon/whatsapp.png', // Asegúrate de tener este asset en tu proyecto
        width: 22,
        height: 22,
      ),
      tooltip: 'Enviar WhatsApp',
      onPressed: () async {
        final numero = telefono.telefono.replaceAll(RegExp(r'\D'), '');
        final url = Uri.parse('https://wa.me/$numero');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else if (context.mounted) {
          AppSnackbarCustom.showError(context, 'No se pudo abrir WhatsApp');
        }
      },
    ),
  ],
),
                                ],
                              ),
                            ),
                            if (widget.habilitarEdicion) ...[
                              if (widget.selectedOperation['telefono'] == 'editar')
                                IconButton(
                                  icon: Icon(Icons.edit, color: icono),
                                  tooltip: 'Editar',
                                  onPressed: () => _mostrarDialogoEditarTelefono(context, ref, telefono),
                                ),
                              if (widget.selectedOperation['telefono'] == 'eliminar')
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Eliminar',
                                  onPressed: () => ConfirmDialog.show(
                                    context,
                                    title: 'Eliminar Teléfono',
                                    content: '¿Está seguro que desea eliminar este teléfono?',
                                    confirmText: 'Eliminar',
                                    cancelText: 'Cancelar',
                                    confirmColor: Colors.red,
                                  ).then((confirmed) async {
                                    if (confirmed == true && context.mounted) {
                                      await ref.read(eliminarTelefonoProvider(telefono.codTelefono).future);
                                      final _ = ref.refresh(telefonoProvider(widget.codPersona));
                                      if (context.mounted) AppSnackbarCustom.showDelete(context, 'Teléfono eliminado correctamente');
                                    }
                                  }),
                                ),
                            ],
                          ],
                        ),
                      )).toList(),
                    );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error al cargar los teléfonos: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoAgregarTelefono(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            child: FormularioTelefono(
              title: 'Agregar Teléfono',
              codPersona: widget.codPersona,
              isEditing: false,
              onSave: (telefono) async {
                try {
                  await ref.read(registrarTelefonoProvider(telefono).future);
                  ref.invalidate(telefonoProvider(widget.codPersona));
                  
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                  rethrow;
                }
              },
              onCancel: () => Navigator.of(context).pop(),
            ),
          ),
    );
  }
  void _mostrarDialogoEditarTelefono(BuildContext context, WidgetRef ref, TelefonoEntity telefono) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: FormularioTelefono(
          title: 'Editar Teléfono',
          telefono: telefono,
          codPersona: widget.codPersona,
          isEditing: true,
          onSave: (telefonoActualizado) async {
            try {
              await ref.read(registrarTelefonoProvider(telefonoActualizado).future);
              ref.invalidate(telefonoProvider(widget.codPersona));
             
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
              rethrow;
            }
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
Future<void> _advertirSiSinTelefonos(BuildContext context, WidgetRef ref, List<TelefonoEntity> telefonos) async {
  final codEmpleadoActual = await ref.read(userProvider.notifier).getCodEmpleado();
  final codPersonaActual = await ref.read(empObtenerDatosEmpleados(codEmpleadoActual).future);

  if (widget.codPersona == codPersonaActual) {
    String? mensaje;
    Color color = Colors.red;
    IconData icon = Icons.warning;

    if (telefonos.isEmpty) {
      mensaje = 'Por favor, registre un teléfono.';
    } else if (telefonos.length < 2) {
      mensaje = 'Debe registrar al menos dos teléfonos.';
      color = Colors.orange;
    }

    if (mensaje != null) {
      // Mostrar advertencia si aplica
      if (!_advertenciaMostrada || _bannerMensaje != mensaje) {
        setState(() {
          _advertenciaMostrada = true;
          _bannerMensaje = mensaje;
          _bannerColor = color;
          _bannerIcon = icon;
        });
      }
    } else {
      // Ocultar banner si ya no aplica la advertencia
      if (_advertenciaMostrada || _bannerMensaje != null) {
        setState(() {
          _advertenciaMostrada = false;
          _bannerMensaje = null;
          _bannerColor = null;
          _bannerIcon = null;
        });
      }
    }
  } else {
    // Ocultar banner si no es la persona actual
    if (_advertenciaMostrada || _bannerMensaje != null) {
      setState(() {
        _advertenciaMostrada = false;
        _bannerMensaje = null;
        _bannerColor = null;
        _bannerIcon = null;
      });
    }
  }
}
}
