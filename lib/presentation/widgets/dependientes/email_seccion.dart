import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/banner_personalizado.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/email_entity.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/formulario_email.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/state/empleados_dependientes_provider.dart';
import 'speed_dial.dart';

class EmailSeccion extends ConsumerStatefulWidget {
  final int codPersona;
  final bool habilitarEdicion;
  final Map<String, bool> estadoExpandido;
  final Map<String, String?> selectedOperation;
  final Function(String) onToggleSeccion;
  final Function(String?) onUpdateOperation;
  final VoidCallback onEditar;
  final VoidCallback onAgregar; 
  final VoidCallback onEliminar; 

  const EmailSeccion({
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
  ConsumerState<EmailSeccion> createState() => _EmailSeccionState();
}
class _EmailSeccionState extends ConsumerState<EmailSeccion> {
  String? _bannerMensaje;
  Color? _bannerColor;
  IconData? _bannerIcon;
  bool _advertenciaMostrada = false;

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
    final emailAsync = ref.watch(emailProvider(widget.codPersona));
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    //final isTablet = ResponsiveUtilsBosque.isTablet(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    // Colores igual que en relacion_laboral_seccion.dart
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EMAIL(S)',
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
                  nombreSeccion: 'email',
                  onEditar: widget.onEditar,
                  onAgregar: () => _mostrarDialogoAgregarEmail(context, ref),
                  onEliminar: widget.onEliminar,
                  updateOperation: widget.onUpdateOperation,
                  operacionHabilitada: const ['editar', 'agregar', 'eliminar'],
                  selectedOperation: widget.selectedOperation,
                ),
            ],
          ),
          Divider(height: 20, color: Colors.grey.withOpacity(0.18)),
          emailAsync.when(
            data: (emails) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
  _advertirSiSinEmails(ref, emails);
});
              if (emails.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'No hay correos registrados',
                      style: TextStyle(
                        color: textoSecundario,
                        fontSize: isDesktop ? 15 : 14,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                );
              }
              final showScroll = emails.length > 4;
              final emailList = ListView.builder(
                shrinkWrap: true,
                physics: showScroll
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: emails.length,
                itemBuilder: (context, index) {
                  final email = emails[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.email, color: icono, size: isDesktop ? 18 : 16),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 7),
                            child: Row(
  children: [
    Expanded(
      child: GestureDetector(
        onTap: () async {
          final emailAddress = email.email;
          final gmailUrl = Uri.parse('googlegmail://co?to=$emailAddress');
          if (await canLaunchUrl(gmailUrl)) {
            await launchUrl(gmailUrl);
            return;
          }
          final gmailWeb = Uri.parse('https://mail.google.com/mail/?view=cm&to=$emailAddress');
          if (await canLaunchUrl(gmailWeb)) {
            await launchUrl(gmailWeb, mode: LaunchMode.externalApplication);
            return;
          }
          final mailtoUri = Uri(
            scheme: 'mailto',
            path: emailAddress,
          );
          if (await canLaunchUrl(mailtoUri)) {
            await launchUrl(mailtoUri);
          }
        },
        child: autoText(
          email.email,
          TextStyle(
            fontSize: isDesktop ? 16 : 15,
            color: textoPrincipal,
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
            letterSpacing: 0.1,
            decoration: TextDecoration.underline,
          ),
          maxLines: 1,
        ),
      ),
    ),
    IconButton(
      icon: const Icon(Icons.copy, size: 18),
      tooltip: 'Copiar',
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: email.email));
        if (context.mounted) {
  AppSnackbarCustom.showSuccess(context, 'Email copiado');
}
      },
    ),
  ],
),
                          ),
                        ),
                        if (widget.habilitarEdicion) ...[
                          if (widget.selectedOperation['email'] == 'editar')
                            IconButton(
                              icon: Icon(Icons.edit, color: icono),
                              tooltip: 'Editar',
                              onPressed: () => _mostrarDialogoEditarEmail(context, ref, email),
                            ),
                          if (widget.selectedOperation['email'] == 'eliminar')
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Eliminar',
                              onPressed: () => ConfirmDialog.show(
                                context,
                                title: 'Eliminar Email',
                                content: '¿Está seguro que desea eliminar este Email?',
                                confirmText: 'Eliminar',
                                cancelText: 'Cancelar',
                                confirmColor: Colors.red,
                              ).then((confirmed) async {
                                if (confirmed == true && context.mounted) {
                                  await ref.read(eliminarEmailProvider(email.codEmail).future);
                                  final _ = await ref.refresh(emailProvider(widget.codPersona).future);
                                  if (context.mounted) AppSnackbarCustom.showDelete(context, 'Email eliminado correctamente');
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
                      child: emailList,
                    )
                  : Column(
                      children: emails.map((email) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.email, color: icono, size: isDesktop ? 18 : 16),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 7),
                                child: Row(
  children: [
    Expanded(
      child: GestureDetector(
        onTap: () async {
          final emailAddress = email.email;
          final gmailUrl = Uri.parse('googlegmail://co?to=$emailAddress');
          if (await canLaunchUrl(gmailUrl)) {
            await launchUrl(gmailUrl);
            return;
          }
          final gmailWeb = Uri.parse('https://mail.google.com/mail/?view=cm&to=$emailAddress');
          if (await canLaunchUrl(gmailWeb)) {
            await launchUrl(gmailWeb, mode: LaunchMode.externalApplication);
            return;
          }
          final mailtoUri = Uri(
            scheme: 'mailto',
            path: emailAddress,
          );
          if (await canLaunchUrl(mailtoUri)) {
            await launchUrl(mailtoUri);
          }
        },
        child: autoText(
          email.email,
          TextStyle(
            fontSize: isDesktop ? 16 : 15,
            color: textoPrincipal,
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
            letterSpacing: 0.1,
            decoration: TextDecoration.underline,
          ),
          maxLines: 1,
        ),
      ),
    ),
    IconButton(
      icon: const Icon(Icons.copy, size: 18),
      tooltip: 'Copiar',
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: email.email));
       if (context.mounted) {
  AppSnackbarCustom.showSuccess(context, 'Email copiado');
}
      },
    ),
  ],
),
                              ),
                            ),
                            if (widget.habilitarEdicion) ...[
                              if (widget.selectedOperation['email'] == 'editar')
                                IconButton(
                                  icon: Icon(Icons.edit, color: icono),
                                  tooltip: 'Editar',
                                  onPressed: () => _mostrarDialogoEditarEmail(context, ref, email),
                                ),
                              if (widget.selectedOperation['email'] == 'eliminar')
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Eliminar',
                                  onPressed: () => ConfirmDialog.show(
                                    context,
                                    title: 'Eliminar Email',
                                    content: '¿Está seguro que desea eliminar este Email?',
                                    confirmText: 'Eliminar',
                                    cancelText: 'Cancelar',
                                    confirmColor: Colors.red,
                                  ).then((confirmed) async {
                                    if (confirmed == true && context.mounted) {
                                      await ref.read(eliminarEmailProvider(email.codEmail).future);
                                      final _ = await ref.refresh(emailProvider(widget.codPersona).future);
                                      if (context.mounted) AppSnackbarCustom.showDelete(context, 'Email eliminado correctamente');
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
                'Error al cargar los correos: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoAgregarEmail(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            child: FormularioEmail(
              title: 'Agregar Email',
              codPersona: widget.codPersona,
              isEditing: false,
              onSave: (email) async {
                try {
                  await ref.read(registrarEmailProvider(email).future);
                  ref.invalidate(emailProvider(widget.codPersona));
                  
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
  void _mostrarDialogoEditarEmail(BuildContext context, WidgetRef ref, EmailEntity email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: FormularioEmail(
          title: 'Editar Email',
          email: email,
          codPersona: widget.codPersona,
          isEditing: true,
          onSave: (email) async {
            try {
              await ref.read(registrarEmailProvider(email).future);
              ref.invalidate(emailProvider(widget.codPersona));
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al actualizar el email: $e')),
              );
            }
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
  Future<void> _advertirSiSinEmails(WidgetRef ref, List<EmailEntity> emails) async {
  final codEmpleadoActual = await ref.read(userProvider.notifier).getCodEmpleado();
  final codPersonaActual = await ref.read(empObtenerDatosEmpleados(codEmpleadoActual).future);

  if (widget.codPersona == codPersonaActual) {
    String? mensaje;
    Color color = Colors.red;
    IconData icon = Icons.warning;

    if (emails.isEmpty) {
      mensaje = 'Por favor, registre un email.';
    } else if (emails.length < 2) {
      mensaje = 'Debe registrar al menos dos emails.';
      color = Colors.orange;
    }

    if (mensaje != null) {
      if (!_advertenciaMostrada || _bannerMensaje != mensaje) {
        setState(() {
          _advertenciaMostrada = true;
          _bannerMensaje = mensaje;
          _bannerColor = color;
          _bannerIcon = icon;
        });
      }
    } else {
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