import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/menu_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/banner_personalizado.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/ciExpedido_entity.dart';
import 'package:bosque_flutter/domain/entities/estado_civil_entity.dart';
import 'package:bosque_flutter/domain/entities/persona_entity.dart';
import 'package:bosque_flutter/domain/entities/sexo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/cronometro_bloqueo.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/formulario_persona.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/map_viewer.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/secccion__foto_docs.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/speed_dial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PersonaSection extends ConsumerStatefulWidget {
  final int codPersona; // Cambiamos persona por codPersona
  final int codEmpleado;
  final bool habilitarEdicion;
  final Map<String, bool> estadoExpandido;
  final Map<String, String?> selectedOperation;
  final Function(String) onToggleSeccion;
  final Function(String?) onUpdateOperation;
  final VoidCallback onEditar;
  static final MapController _mapController = MapController();

  const PersonaSection({
    super.key,
    required this.codPersona, // Actualizamos el constructor
    required this.codEmpleado,
    required this.habilitarEdicion,
    required this.estadoExpandido,
    required this.selectedOperation,
    required this.onToggleSeccion,
    required this.onUpdateOperation,
    required this.onEditar,
  });
  @override
  ConsumerState<PersonaSection> createState() => _PersonaSectionState();
}

class _PersonaSectionState extends ConsumerState<PersonaSection> {
    String? _advertenciaMensaje;
  Color? _advertenciaColor;
  IconData? _advertenciaIcon;
   bool _habilitarEdicion = false;
  //checkpoint
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _capitalizeWords(String text) {
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          final especiales = ['s.a.', 's.r.l.', 'ipx', 'esppapel'];
          if (especiales.contains(word.toLowerCase()))
            return word.toUpperCase();
          return _capitalize(word);
        })
        .join(' ');
  }

  String formatText(String text, bool isDesktop) {
    if (isDesktop) return text.toUpperCase();
    return _capitalizeWords(text);
  }
  Future<void> guardarFechaAdvertencia() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('fechaAdvertenciaDatos', DateTime.now().toIso8601String());
}

Future<DateTime?> obtenerFechaAdvertencia() async {
  final prefs = await SharedPreferences.getInstance();
  final fechaStr = prefs.getString('fechaAdvertenciaDatos');
  if (fechaStr == null) return null;
  return DateTime.tryParse(fechaStr);
}

Future<void> limpiarFechaAdvertencia() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.remove('fechaAdvertenciaDatos');
}
 Future<void> _verificarPermisosEdicion() async {
    try {
      final permissionService = ref.read(permissionServiceProvider);
      final hasPermission = await permissionService.verificarPermisosEdicion(
        widget.codEmpleado,
      );
      if (mounted) {
        setState(() {
          _habilitarEdicion = hasPermission;
        });
      }
    } catch (e) {
      debugPrint('Error al verificar permisos: $e');
      if (mounted) {
        setState(() {
          _habilitarEdicion = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext BuildContext) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final personaAsync = ref.watch(obtenerPersonaProvider(widget.codPersona));
    
final warningCount = ref.watch(warningCounterProvider);
final warningLimit = ref.watch(warningLimitProvider);
    // MapController persistente para evitar reinicialización en cada build
    // Puedes declararlo como variable de instancia en la clase si lo prefieres
    // Aquí lo hacemos estático para mantenerlo entre builds
    // static final MapController mapController = MapController();
    // Si tu clase es StatefulWidget, usa: final MapController _mapController = MapController();
    // Si es ConsumerWidget, puedes hacer:

    return personaAsync.when(
      data: (persona) {
        final bool ciVencido =
            persona.ciFechaVencimiento != null &&
            persona.ciFechaVencimiento!.isBefore(DateTime.now());
        bool _isLatLngDefecto(double? lat, double? lng) {
          const latDefecto = -16.516064;
          const lngDefecto = -68.1354;
          const margen = 0.0001;
          if (lat == null || lng == null) return true;
          return (lat - latDefecto).abs() < margen &&
              (lng - lngDefecto).abs() < margen;
        }

        // Mueve el mapa a la ubicación de la persona después de construir el widget
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final codEmpleadoActual =
      await ref.read(userProvider.notifier).getCodEmpleado();
  final codPersonaActual = await ref.read(
    empObtenerDatosEmpleados(codEmpleadoActual).future,
  );
if (!mounted) return; // <-- Agrega esto aquí
  if (widget.codPersona == codPersonaActual) {
  // Prioridad: CI vencido > Ubicación por defecto
  if (ciVencido) {
    if (_advertenciaMensaje != 'Su carnet de identidad está vencido. Por favor, actualice sus datos.') {
      setState(() {
        _advertenciaMensaje = 'Su carnet de identidad está vencido. Por favor, actualice sus datos.';
        _advertenciaColor = Colors.red;
        _advertenciaIcon = Icons.warning;
      });
      // INCREMENTA EL CONTADOR SOLO SI ES NUEVA
      
      if (warningCount < ref.read(warningLimitProvider)) {
        await ref.read(warningCounterProvider.notifier).increment();
      }
    }
  } else {
    final ubicacionPorDefecto = _isLatLngDefecto(persona.lat, persona.lng);
    if (ubicacionPorDefecto) {
      if (_advertenciaMensaje != 'Por favor, actualice su ubicación.') {
        setState(() {
          _advertenciaMensaje = 'Por favor, actualice su ubicación.';
          _advertenciaColor = Colors.red;
          _advertenciaIcon = Icons.location_on;
        });
        // INCREMENTA EL CONTADOR SOLO SI ES NUEVA
       
if (warningCount < warningLimit) {
 await ref.read(warningCounterProvider.notifier).increment();
   print('Advertencia sumada. Nuevo valor: ${ref.read(warningCounterProvider)}');
  // Mostrar advertencia especial si solo queda una antes del bloqueo
  if (warningCount + 1 == warningLimit) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Atención! Su usuario será bloqueado si no actualiza sus datos.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    });
  }
}
      }
    } else {
      if (_advertenciaMensaje != null) {
        setState(() {
          _advertenciaMensaje = null;
          _advertenciaColor = null;
          _advertenciaIcon = null;
        });
      }
    }
  }
} else {
  if (_advertenciaMensaje != null) {
    setState(() {
      _advertenciaMensaje = null;
      _advertenciaColor = null;
      _advertenciaIcon = null;
    });
  }
}

          // Mueve el mapa si la ubicación es válida
          if (persona.lat != null && persona.lng != null) {
            PersonaSection._mapController.move(
              LatLng(persona.lat!, persona.lng!),
              13.0,
            );
          }
        });

        final camposCol1 = <Widget>[
          _infoField(
            theme,
            'NOMBRES',
            formatText(persona.nombres, isDesktop),
            Icons.person,
            isDesktop,
          ),
          _infoField(
            theme,
            'APELLIDO PATERNO',
            formatText(persona.apPaterno, isDesktop),
            Icons.person_outline,
            isDesktop,
          ),
          _infoField(
            theme,
            'APELLIDO MATERNO',
            formatText(persona.apMaterno, isDesktop),
            Icons.person_outline,
            isDesktop,
          ),
          _infoField(
            theme,
            'C.I NÚMERO',
            persona.ciNumero,
            Icons.pin,
            isDesktop,
          ),
          Consumer(
            builder:
                (context, ref, _) => _infoField(
                  theme,
                  'C.I EXPEDIDO',
                  formatText(_getCiExpedido(ref, persona), isDesktop),
                  Icons.badge,
                  isDesktop,
                ),
          ),
          _infoField(
            theme,
            'FECHA DE NACIMIENTO',
            persona.fechaNacimiento != null
                ? DateFormat('dd-MM-yyyy').format(persona.fechaNacimiento!)
                : 'Sin registros',
            Icons.cake,
            isDesktop,
          ),
          _infoField(
            theme,
            'LUGAR DE NACIMIENTO',
            formatText(persona.lugarNacimiento, isDesktop),
            Icons.place,
            isDesktop,
          ),
        ];

        final camposCol2 = <Widget>[
          _infoField(
            theme,
            'FECHA DE VENCIMIENTO C.I',
            persona.ciFechaVencimiento != null
                ? DateFormat('dd-MM-yyyy').format(persona.ciFechaVencimiento!)
                : 'Sin registros',
            Icons.event,
            isDesktop,
            valueColor:
                ciVencido ? Colors.red : null, // <-- agrega este parámetro
          ),
          Consumer(
            builder:
                (context, ref, _) => _infoField(
                  theme,
                  'ESTADO CIVIL',
                  formatText(_getEstadoCivil(ref, persona), isDesktop),
                  Icons.people,
                  isDesktop,
                ),
          ),
          Consumer(
            builder:
                (context, ref, _) => _infoField(
                  theme,
                  'GÉNERO',
                  formatText(_getGenero(ref, persona), isDesktop),
                  Icons.wc,
                  isDesktop,
                ),
          ),
          _infoField(
            theme,
            'NACIONALIDAD',
            persona.pais?.pais != null
                ? formatText(persona.pais!.pais, isDesktop)
                : 'Sin registros',
            Icons.flag,
            isDesktop,
          ),
          _infoField(
            theme,
            'CIUDAD',
            persona.ciudad?.ciudad != null
                ? formatText(persona.ciudad!.ciudad, isDesktop)
                : 'Sin registros',
            Icons.location_city,
            isDesktop,
          ),
          _infoField(
            theme,
            'ZONA',
            persona.zona?.zona != null
                ? formatText(persona.zona!.zona, isDesktop)
                : 'Sin registros',
            Icons.location_on,
            isDesktop,
          ),
          _infoField(
            theme,
            'DIRECCIÓN',
            formatText(persona.direccion, isDesktop),
            Icons.home,
            isDesktop,
          ),
        ];

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 16 : 4,
            vertical: isDesktop ? 12 : 4,
          ),
          child: Column(
    children: [
      if (_advertenciaMensaje != null)
        BannerCustom(
          message: _advertenciaMensaje!,
          color: _advertenciaColor ?? Colors.red,
          icon: _advertenciaIcon ?? Icons.warning,
          maxLines: 2,
          
        ),
         
        // BOTÓN DE PRUEBA PARA RESETEAR ADVERTENCIAS
  /*if (warningCount > 0)
    Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.refresh),
        label: const Text('Resetear advertencias'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
        ),
        onPressed: () async {
          await ref.read(warningCounterProvider.notifier).reset();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contador de advertencias reseteado'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    ),*/
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 18 : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatText('DATOS PERSONALES', isDesktop),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Row(
                        children: [
                         if(widget.habilitarEdicion)
                          if (isDesktop)
  TextButton.icon(
    icon: Icon(
      Icons.folder_shared_rounded,
      color: theme.colorScheme.primary,
      size: 20,
    ),
    label: Text(
      'Ver Documentos',
      style: TextStyle(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
    onPressed: () => _mostrarGaleriaTodosDocumentos(
      context,
      widget.codEmpleado,
    ),
  )
else // Si es móvil (isDesktop: false), usa IconButton con tooltip
  IconButton(
    tooltip: 'Ver documentos adjuntos',
    icon: Icon(
      Icons.folder_shared_rounded,
      color: theme.colorScheme.primary,
    ),
    onPressed: () => _mostrarGaleriaTodosDocumentos(
      context,
      widget.codEmpleado,
    ),
  ),
                          CustomSpeedDial(
                            visible: widget.habilitarEdicion,
                            nombreSeccion: 'persona',
                            onEditar:
                                () => _mostrarDialogoEditarPersona(
                                  context,
                                  persona,
                                  ref,
                                ),
                            updateOperation: widget.onUpdateOperation,
                            operacionHabilitada: const ['editar'],
                            selectedOperation: widget.selectedOperation,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Divider(color: theme.colorScheme.outline.withOpacity(0.2)),
                  if (widget.estadoExpandido['empleado'] ?? true)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dos columnas para desktop, una para mobile
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide =
                                isDesktop || constraints.maxWidth > 700;
                            if (isWide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: camposCol1,
                                    ),
                                  ),
                                  const SizedBox(width: 32),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: camposCol2,
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              // Mobile: una sola columna
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [...camposCol1, ...camposCol2],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          formatText('UBICACIÓN', isDesktop),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: double.infinity,
                            height: isDesktop ? 340 : 220,
                            child: MapViewer(
                              mapController: PersonaSection._mapController,
                              latitude: persona.lat ?? -16.516064598979447,
                              longitude: persona.lng ?? -68.13540079367057,
                              isInteractive: true,
                              canChangeLocation: false,
                            ),
                          ),
                        ),
                        if (persona.lat != null && persona.lng != null) ...[
                          const SizedBox(height: 6),
                          Center(
                            child: TextButton.icon(
                              onPressed: () async {
                                final Uri uri = Uri.parse(
                                  '${AppConstants.googleMapsSearchBaseUrl}=${persona.lat},${persona.lng}',
                                );
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                              icon: Icon(
                                Icons.map,
                                color: theme.colorScheme.primary,
                              ),
                              label: Text(
                                formatText('VER EN GOOGLE MAPS', isDesktop),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
    ],
          ),//aqui
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) =>
              Center(child: Text('Error al cargar los datos: $error')),
    );
  }

  Widget _infoField(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    bool isDesktop, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatText(label, isDesktop),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty
                      ? (isDesktop ? 'SIN REGISTROS' : 'Sin registros')
                      : value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: valueColor, // <-- aquí
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCiExpedido(WidgetRef ref, PersonaEntity persona) {
    final ciExpedido = ref.watch(ciExpedidoProvider);
    return ciExpedido.when(
      data: (tipos) {
        final tipo = tipos.firstWhere(
          (t) => t.codTipos == persona.ciExpedido,
          orElse:
              () => CiExpedidoEntity(
                codTipos: '',
                nombre: 'No encontrado',
                codGrupo: 0,
                listTipos: [],
              ),
        );
        return tipo.nombre.toUpperCase(); // Convertir a minúsculas
      },
      loading: () => 'cargando...',
      error: (_, __) => 'error',
    );
  }

  String _getEstadoCivil(WidgetRef ref, PersonaEntity persona) {
    final estadoCivil = ref.watch(estadoCivilProvider);
    return estadoCivil.when(
      data: (tipos) {
        final tipo = tipos.firstWhere(
          (t) => t.codTipos == persona.estadoCivil,
          orElse:
              () => EstadoCivilEntity(
                codTipos: '',
                nombre: 'No encontrado',
                codGrupo: 0,
                listTipos: [],
              ),
        );
        return tipo.nombre.toUpperCase(); // Convertir a minúsculas
      },
      loading: () => 'cargando...',
      error: (_, __) => 'error',
    );
  }

  String _getGenero(WidgetRef ref, PersonaEntity persona) {
    final genero = ref.watch(sexoProvider);
    return genero.when(
      data: (tipos) {
        final tipo = tipos.firstWhere(
          (t) => t.codTipos == persona.sexo,
          orElse:
              () => SexoEntity(
                codTipos: '',
                nombre: 'No encontrado',
                codGrupo: 0,
                listTipos: [],
              ),
        );
        return tipo.nombre.toUpperCase(); // Convertir a minúsculas
      },
      loading: () => 'cargando...',
      error: (_, __) => 'error',
    );
  }

  Future<void> _mostrarDialogoEditarPersona(
    BuildContext context,
    PersonaEntity persona,
    WidgetRef ref,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: FormularioPersona(
            title: 'Editar Persona',
            isEditing: true,
            codPersona: persona.codPersona,
            persona: persona,
            onCancel: () => Navigator.pop(context),
            onSave: (personaActualizada) async {
              try {
                await ref.read(
                  registrarPersonaProvider(personaActualizada).future,
                );
                ref.invalidate(obtenerPersonaProvider);
                // Verifica si el CI ya no está vencido
    final ciVencido = personaActualizada.ciFechaVencimiento != null &&
      personaActualizada.ciFechaVencimiento!.isBefore(DateTime.now());

    // Verifica si la ubicación ya no es la de defecto
    bool isLatLngDefecto(double? lat, double? lng) {
      const latDefecto = -16.516064;
      const lngDefecto = -68.1354;
      const margen = 0.0001;
      if (lat == null || lng == null) return true;
      return (lat - latDefecto).abs() < margen &&
          (lng - lngDefecto).abs() < margen;
    }
    final ubicacionPorDefecto = isLatLngDefecto(personaActualizada.lat, personaActualizada.lng);

    // Solo desbloquea y resetea si el CI ya no está vencido y la ubicación ya no es la de defecto
    if (!ciVencido && !ubicacionPorDefecto) {
      await ref.read(warningCounterProvider.notifier).reset();
      final codUsuario = await ref.read(userProvider.notifier).getCodUsuario();
      await ref.read(desbloquearUsuarioProvider(codUsuario).future);
      await ref.read(menuProvider.notifier).fetchAndSaveMenu(codUsuario);
      ref.invalidate(warningCounterProvider);
      ref.invalidate(usuarioBloqueadoProvider(codUsuario));
    }
                if (!context.mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Persona actualizada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al actualizar: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  void _mostrarGaleriaTodosDocumentos(BuildContext context, int codEmpleado) async {
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final userNotifier = ref.read(userProvider.notifier);
    final cargo = (await userNotifier.getCargo()).toLowerCase();
    
    String? advertenciaMensaje;
    Color? advertenciaColor;
    IconData? advertenciaIcon;

    try {
      final docsData = await ref.read(todosLosDocumentosProvider(codEmpleado).future);
      if (cargo.contains('chofer')) {
        final tieneLicencia = docsData['LICENCIA'] != null && docsData['LICENCIA']!.isNotEmpty;
        if (!tieneLicencia) {
          advertenciaMensaje = 'Para el cargo CHOFER es obligatorio adjuntar la Licencia de Conducir.';
          advertenciaColor = Colors.red;
          advertenciaIcon = Icons.warning;
        }
      }
    } catch (e) {
      debugPrint("Error al verificar documentos para advertencia: $e");
    }

    // Se muestra el diálogo de la galería.
    showDialog(
      context: context,
      barrierDismissible: false,
      // Usamos el context del builder para el nuevo diálogo, que es seguro.
      builder: (galleryDialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final docsAsync = ref.watch(todosLosDocumentosProvider(codEmpleado));
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 48, vertical: isMobile ? 12 : 48),
              child: Container(
                width: isMobile ? double.infinity : 540,
                height: isMobile ? MediaQuery.of(context).size.height * 0.85 : 650,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  children: [
                    if (advertenciaMensaje != null)
                      BannerCustom(
                        message: advertenciaMensaje,
                        color: advertenciaColor ?? Colors.red,
                        icon: advertenciaIcon ?? Icons.warning,
                        maxLines: 3,
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: advertenciaMensaje == null
                            ? const BorderRadius.vertical(top: Radius.circular(18))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.folder_shared_rounded, color: Colors.blue[700], size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Documentos adjuntos',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 17 : 20,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Cerrar',
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => Navigator.of(galleryDialogContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 10 : 18),
                        child: docsAsync.when(
                          data: (mapaDeDocumentos) {
                            // Mapa con todos los tipos de documentos que queremos mostrar.
                            final Map<String, String> todosLosTipos = {
                              'carnet': 'Carnet de Identidad',
                              'pasaporte': 'Pasaporte',
                              'licencia': 'Licencia de Conducir',
                            };

                            // Creamos la lista de widgets iterando sobre TODOS los tipos posibles.
                            final widgetsDeDocumentos = todosLosTipos.entries.map((entry) {
                              final tipoClave = entry.key;
                              final tipoDisplay = entry.value;
                              
                              // Obtenemos los archivos para este tipo, o una lista vacía si no existen.
                              final archivos = mapaDeDocumentos[tipoClave] ?? [];
                              final tieneArchivos = archivos.isNotEmpty;

                              return Column(
                                key: ValueKey(tipoClave), // Key para evitar problemas de estado
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Row(
                                      children: [
                                        Icon(Icons.label_important, color: Colors.blue[400], size: 20),
                                        const SizedBox(width: 6),
                                        Text(
                                          tipoDisplay.toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: isMobile ? 15 : 17,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!tieneArchivos)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 26, bottom: 12),
                                      child: Text('No hay documentos.', style: TextStyle(color: Colors.grey[600])),
                                    )
                                  else
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isMobile ? 2 : 3,
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 10,
                                        childAspectRatio: 0.9,
                                      ),
                                      itemCount: archivos.length,
                                      itemBuilder: (context, index) {
                                        final nombreArchivo = archivos[index];
                                        final url = '${AppConstants.baseUrl}${AppConstants.getDocImageUrl}$codEmpleado/$tipoClave/$nombreArchivo?ts=${DateTime.now().millisecondsSinceEpoch}';
                                        final lado = (archivos.length > 1) ? (index == 0 ? 'Anverso' : 'Reverso') : 'Documento';
                                        return _buildDocumentoItem(context, url, nombreArchivo, lado);
                                      },
                                    ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                                      label: Text(tieneArchivos ? 'Añadir o Reemplazar' : 'Subir $tipoDisplay'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: tieneArchivos ? Colors.green[700] : Colors.blue[600],
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () {
                                        // 1. Cierra el diálogo de la galería.
                                        Navigator.of(galleryDialogContext).pop();
                                        
                                        // 2. Inmediatamente abre el diálogo de carga de archivos.
                                        // Usamos el 'context' principal que es seguro.
                                        showDialog(
                                          context: context,
                                          builder: (uploadDialogContext) => Dialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            child: Padding(
                                              padding: const EdgeInsets.all(24),
                                              child: SizedBox(
                                                width: isMobile ? double.infinity : 400,
                                                child: SeccionFotoDocsDropdown(
                                                  habilitarEdicion: true,
                                                  codEmpleado: codEmpleado,
                                                  tipoDocumentoPreseleccionado: tipoDisplay,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const Divider(height: 24, thickness: 1),
                                ],
                              );
                            }).toList();

                            return SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: widgetsDeDocumentos,
                              ),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Error: $e')),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentoItem(BuildContext context, String url, String tag, String lado) {
   return GestureDetector(
     onTap: () => _mostrarImagenCompletaGaleria(context, url, tag),
     child: Card(
       clipBehavior: Clip.antiAlias,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
       elevation: 3,
       child: GridTile( // Eliminamos la propiedad 'footer' para quitar la etiqueta.
         child: Hero(
           tag: tag,
           child: Image.network(
             url,
             fit: BoxFit.cover,
             loadingBuilder: (context, child, progress) {
               return progress == null ? child : const Center(child: CircularProgressIndicator());
             },
             errorBuilder: (context, error, stackTrace) {
               // ignore: avoid_print
               print('Error al cargar imagen: $url, Error: $error');
               return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
             },
           ),
         ),
       ),
     ),
   );
 }

  void _mostrarImagenCompletaGaleria(BuildContext context, String url, String tag) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Hero(
                tag: tag,
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
          ),
        );
      },
    );
  }
}
