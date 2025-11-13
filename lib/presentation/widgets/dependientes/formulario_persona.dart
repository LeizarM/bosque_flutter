import 'dart:async';
import 'dart:ui';

import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/core/utils/validators.dart';
import 'package:bosque_flutter/domain/entities/persona_entity.dart';
import 'package:bosque_flutter/domain/entities/zona_entity.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/formulario_ciudad.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/formulario_pais.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/formulario_zona.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/map_viewer.dart';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:latlong2/latlong.dart';

class FormularioPersona extends ConsumerStatefulWidget{
  final GlobalKey<FormState>? formKey;
  final String title;
  final PersonaEntity? persona;
  final int codPersona;
  final bool isEditing;
  final Function(PersonaEntity) onSave;
  final VoidCallback onCancel;
  final bool showActions;

  const FormularioPersona({
    Key? key,
    required this.title,
    this.formKey,
    this.persona,
    required this.codPersona,
    required this.isEditing,
    required this.onSave,
    required this.onCancel,
    this.showActions = true,

  }) : super(key: key);
  @override
  FormularioPersonaState createState() => FormularioPersonaState();
}
class FormularioPersonaState extends ConsumerState<FormularioPersona>{
  final FocusNode _focusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;
  final MapController _mapController = MapController();
  String? _ciExpedidoSeleccionado;
  String? _estadoCivilSeleccionado;
  int? _nacionalidadSeleccionado;
  int? _zonaSeleccionado;
  String? _generoSeleccionado;
  int? _ciudadSeleccionada;
  double? _currentLat;
  double? _currentLng;
  late PersonaEntity _personaTemp;
  // 🛑 NUEVOS CAMPOS PARA VALIDACIÓN EN TIEMPO REAL
  Timer? _debounce;
  String? _ciErrorMessage; 
  String? _initialCi; // Para evitar validar el CI original en modo edición
  bool _ciFound = false;
   @override
  void initState() {
    super.initState();
    _personaTemp = widget.persona ?? PersonaEntity.vacio();
    _initControllers();
    _initSelections();
    // Inicializar las coordenadas
    _currentLat = widget.persona?.lat ?? -16.516064598979447;
    _currentLng = widget.persona?.lng ?? -68.13540079367057;

    // 🛑 GUARDAR EL CI INICIAL
    _initialCi = widget.persona?.ciNumero;
  }

  void _initSelections() {
    _ciExpedidoSeleccionado = widget.persona?.ciExpedido;
    _estadoCivilSeleccionado = widget.persona?.estadoCivil;
    _nacionalidadSeleccionado = widget.persona?.nacionalidad;
    _ciudadSeleccionada = widget.persona?.ciudad?.codCiudad;
    _zonaSeleccionado = widget.persona?.codZona;
    _generoSeleccionado = widget.persona?.sexo;
    
  }

  void _initControllers() {
    _controllers = {
      'nombres': TextEditingController(text: widget.persona?.nombres??''),
      'apPaterno': TextEditingController(text: widget.persona?.apPaterno??''),
      'apMaterno': TextEditingController(text: widget.persona?.apMaterno??''),
      'direccion': TextEditingController(text: widget.persona?.direccion??''),
      'ciNumero': TextEditingController(text: widget.persona?.ciNumero??''),
      'ciFechaVencimiento': TextEditingController(
    text: widget.persona?.ciFechaVencimiento != null 
      ? FormatearFecha.formatearFecha(widget.persona!.ciFechaVencimiento!)
      : ''
  ),
  'fechaNacimiento': TextEditingController(
    text: widget.persona?.fechaNacimiento != null 
      ? FormatearFecha.formatearFecha(widget.persona!.fechaNacimiento!)
      : ''
  ),   
      
      'lugarNacimiento': TextEditingController(
        text: widget.persona?.lugarNacimiento??'',
      ),
    };
  }
  // 🛑 CANCELAR EL TIMER EN DISPOSE
  @override
  void dispose() {
    _debounce?.cancel(); 
    _focusNode.dispose();
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }
  // 🛑 FUNCIÓN DE VALIDACIÓN EN TIEMPO REAL (DEBOUNCED)
  void _validateCiOnType(String ciNumero) {
    // 🛑 1. Lógica de Modo Edición (sin cambios)
    if (widget.isEditing) {
      if (ciNumero == _initialCi) {
        setState(() => _ciErrorMessage = null);
      }
      return; 
    }
    
    // 2. Limpiar el estado
    setState(() {
      _ciErrorMessage = null; 
      _ciFound = false; 
    });
    
    // 3. Cancelar el timer y verificación de longitud (sin cambios)
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (ciNumero.isEmpty || ciNumero.length < 5) { 
      return;
    }

    // 4. Iniciar debounce
    _debounce = Timer(const Duration(milliseconds: 700), () async { 
      try {
        final PersonaEntity personaExistente =
            await ref.read(obtenerPersonaXCarnet(ciNumero).future);

        // 5. Caso 1: CI ENCONTRADO (EXISTE - codPersona != 0)
        if (personaExistente.codPersona != 0) {
          if (mounted) {
            setState(() {
              if (_controllers['ciNumero']?.text == ciNumero) {
                  _ciErrorMessage = 
                      //'❌ Este C.I. ya está registrado (${personaExistente.nombres} ${personaExistente.apPaterno}).';
                      'Este C.I. ya está registrado.';
                  _ciFound = true; 
                  _personaTemp = personaExistente; 
              }
            });
          }
        } else {
          // 6. Caso 2: CI NO ENCONTRADO (DISPONIBLE - codPersona es 0, sin excepción)
          if (mounted) {
            setState(() {
              if (_controllers['ciNumero']?.text == ciNumero) {
                _ciErrorMessage = '✅ C.I. disponible para nuevo registro.'; 
              }
            });
          }
        }

      } catch (e) {
        // 7. Manejo de error
        final errorString = e.toString().toLowerCase();

        // 1. Caso 3a: ERROR 409 (CI DE OTRA PERSONA) - Bloquea el uso.
        if (errorString.contains('409') || errorString.contains('ya se encuentra registrada')) {
           if (mounted) {
              setState(() {
                _ciErrorMessage = '❌ Este C.I. ya pertenece a otra persona. No se puede usar.';
              });
            }
        }
        // 🛑 2. CATCH-ALL: CUALQUIER otra excepción (incluyendo el 404, 500, o fallo de red).
        // Si no es un error de duplicidad (409), asumimos que es disponibilidad (404)
        // para evitar mostrar un error de sistema.
        else {
            if (mounted) {
              setState(() {
                // Aquí el error puede ser el 404/No Encontrado, o un fallo de red real.
                // Priorizamos mostrar disponibilidad para no frustrar al usuario con un CI nuevo.
                _ciErrorMessage = '✅ C.I. disponible para nuevo registro.'; 
              });
            }
        }
      }
    });
}
  void loadPersona(PersonaEntity persona) {
  if (!mounted) return;
  setState(() {
    // 1. 🚨 CRUCIAL: Guarda la persona (¡contiene el codPersona existente!)
    _personaTemp = persona; 

    // 2. Actualizar los controladores de texto
    _controllers['nombres']?.text = persona.nombres ?? '';
    _controllers['apPaterno']?.text = persona.apPaterno ?? '';
    _controllers['apMaterno']?.text = persona.apMaterno ?? '';
    _controllers['direccion']?.text = persona.direccion ?? '';
    _controllers['ciNumero']?.text = persona.ciNumero ?? '';
    _controllers['lugarNacimiento']?.text = persona.lugarNacimiento ?? '';

    // Formato de fechas
    _controllers['ciFechaVencimiento']?.text = persona.ciFechaVencimiento != null
        ? FormatearFecha.formatearFecha(persona.ciFechaVencimiento!)
        : '';
    _controllers['fechaNacimiento']?.text = persona.fechaNacimiento != null
        ? FormatearFecha.formatearFecha(persona.fechaNacimiento!)
        : '';

    // 3. Actualizar los Dropdowns y variables de estado
    _ciExpedidoSeleccionado = persona.ciExpedido;
    _estadoCivilSeleccionado = persona.estadoCivil;
    _nacionalidadSeleccionado = persona.nacionalidad;
    _ciudadSeleccionada = persona.codZona; // Asumo que codZona también tiene el codCiudad asociado si lo necesitas para repopular la ciudad
    _zonaSeleccionado = persona.codZona; 
    _generoSeleccionado = persona.sexo;

    // 4. Actualizar el mapa
    _currentLat = persona.lat ?? -16.516064598979447;
    _currentLng = persona.lng ?? -68.13540079367057;
    _mapController.move(LatLng(_currentLat!, _currentLng!), 13.0); // Mueve el mapa a la ubicación
    
    // Si la Ciudad/Zona se actualizan, debes invalidar sus providers
    ref.invalidate(ciudadProvider(_nacionalidadSeleccionado!));
    if (_ciudadSeleccionada != null) {
      ref.invalidate(zonaProvider(_ciudadSeleccionada!));
    }
  });
}
  Future<int> getCodUsuario() async {
    return await ref.read(userProvider.notifier).getCodUsuario();
  }
  Future<PersonaEntity> getPersona() async {
  final codUsuario = await getCodUsuario();
  // 🚨 CORRECCIÓN CRUCIAL: Usar _personaTemp.codPersona si existe, sino 0.
  final codPersonaFinal = widget.isEditing 
                          ? widget.persona?.codPersona ?? _personaTemp.codPersona 
                          : _personaTemp.codPersona; // Si fue autocompletado, _personaTemp.codPersona != 0
  return PersonaEntity(
    //codPersona: widget.isEditing ? widget.persona?.codPersona ?? 0 : 0,
    codPersona: codPersonaFinal,
    nombres: _controllers['nombres']?.text ?? '',
    apPaterno: _controllers['apPaterno']?.text ?? '',
    apMaterno: _controllers['apMaterno']?.text ?? '',
    direccion: _controllers['direccion']?.text ?? '',
    ciNumero: _controllers['ciNumero']?.text ?? '',
    ciExpedido: _ciExpedidoSeleccionado!,
    estadoCivil: _estadoCivilSeleccionado!,
    nacionalidad: _nacionalidadSeleccionado!,
    codZona: _zonaSeleccionado!,
    sexo: _generoSeleccionado!,
    ciFechaVencimiento: FormatearFecha.parseFecha(_controllers['ciFechaVencimiento']!.text),
    fechaNacimiento: FormatearFecha.parseFecha(_controllers['fechaNacimiento']!.text),
    lugarNacimiento: _controllers['lugarNacimiento']?.text ?? '',
    lat: _currentLat ?? -16.5,
    lng: _currentLng ?? -68.1,
    audUsuarioI: codUsuario,
  );
}
bool validate() {
  return _formKey.currentState?.validate() ?? false;
}
  //checkpoint
  @override
Widget build(BuildContext context) {
  final isDesktopOrWeb = kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

  Widget formWidget = Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _buildResponsiveSection(
          true,
          title: 'Datos Personales',
          children: _buildDatosPersonalesFields(true),
        ),
        const SizedBox(height: 8),
        _buildResponsiveSection(
          true,
          title: 'Documentos',
          children: _buildDocumentosFields(true),
        ),
        const SizedBox(height: 8),
        _buildResponsiveSection(
          true,
          title: 'Datos Adicionales',
          children: _buildDatosAdicionalesFields(true),
        ),
        const SizedBox(height: 8),
        _buildResponsiveSection(
          true,
          title: 'Ubicación',
          children: [
            SizedBox(
              height: 200,
              child: MapViewer(
                mapController: _mapController,
                latitude: _currentLat!,
                longitude: _currentLng!,
                height: 200,
                isInteractive: true,
                canChangeLocation: true,
                onTap: (LatLng point) {
                  setState(() {
                    _currentLat = point.latitude;
                    _currentLng = point.longitude;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8), // Espacio para que los campos no queden tapados por los botones
      ],
    ),
  );

  if (isDesktopOrWeb) {
    formWidget = KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
             event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
          _handleSubmit();
        }
      },
      child: formWidget,
    );
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final isLargeScreen = constraints.maxWidth >= 600;
      return Center(
        child: Container(
          width: isLargeScreen ? 600 : constraints.maxWidth,
          margin: EdgeInsets.symmetric(
            vertical: 16,
            horizontal: isLargeScreen ? 8 : 0,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // Formulario con scroll
              Padding(
                padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
                child: SingleChildScrollView(
                  child: formWidget,
                ),
              ),
              // Botones fijos abajo
              if (widget.showActions)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: widget.onCancel,
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _handleSubmit,
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
//checkpoint
  Widget _buildResponsiveSection(
  bool isLargeScreen, {
  required String title,
  required List<Widget> children,
}) {
  // Índices de país, ciudad y zona (ajusta si cambia el orden)
  final int idxPais = 4;
  final int idxCiudad = 5;
  final int idxZona = 6;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          // WEB/ESCRITORIO: SIEMPRE grid de 2 columnas
          if (isLargeScreen && constraints.maxWidth > 700) {
            // Los campos de país, ciudad y zona van fuera del grid
            List<Widget> gridChildren = [];
            List<Widget> fullWidthChildren = [];
            for (int i = 0; i < children.length; i++) {
              if (i == idxPais || i == idxCiudad || i == idxZona) {
                fullWidthChildren.add(Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: children[i],
                ));
              } else {
                gridChildren.add(children[i]);
              }
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: gridChildren.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 2.8,
                  ),
                  itemBuilder: (context, index) => Align(
                    alignment: Alignment.topCenter,
                    child: gridChildren[index],
                  ),
                ),
                ...fullWidthChildren,
              ],
            );
          } else {
            // MOVIL: todos en dos columnas menos país, ciudad y zona (que van en fila completa)
            List<Widget> rowChildren = [];
            int i = 0;
            while (i < children.length) {
              if (i == idxPais || i == idxCiudad || i == idxZona) {
                rowChildren.add(children[i]);
                rowChildren.add(const SizedBox(height: 16));
                i++;
              } else {
                // Agrupa de a dos en una fila
                if (i + 1 < children.length &&
                    (i + 1 != idxPais && i + 1 != idxCiudad && i + 1 != idxZona)) {
                  rowChildren.add(Row(
                    children: [
                      Expanded(child: children[i]),
                      const SizedBox(width: 16),
                      Expanded(child: children[i + 1]),
                    ],
                  ));
                  rowChildren.add(const SizedBox(height: 16));
                  i += 2;
                } else {
                  rowChildren.add(children[i]);
                  rowChildren.add(const SizedBox(height: 16));
                  i++;
                }
              }
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rowChildren,
            );
          }
        },
      ),
      const SizedBox(height: 16),
    ],
  );
}

  List<Widget> _buildDatosPersonalesFields(bool isLargeScreen) {
    return [
      _buildFormField(
        controller: _controllers['nombres']!,
        label: 'NOMBRES',
        validator: (value) => validarTextoOpcional(value, esObligatorio: true),
        flex: isLargeScreen ? 2 : 1,
      ),
      _buildFormField(
        controller: _controllers['apPaterno']!,
        label: 'APELLIDO PATERNO',
        validator: (value) => validarTextoOpcional(value, esObligatorio: false),
        flex: isLargeScreen ? 1 : 1,
      ),
      _buildFormField(
        controller: _controllers['apMaterno']!,
        label: 'APELLIDO MATERNO',
        validator: (value) => validarTextoOpcional(value, esObligatorio: false),
        flex: isLargeScreen ? 1 : 1,
      ),
    ];
  }

  List<Widget> _buildDocumentosFields(bool isLargeScreen) {
  
  // 🛑 1. Definir el campo CI como un widget local, incluyendo los nuevos parámetros.
  Widget ciField = _buildFormField(
    controller: _controllers['ciNumero']!,
    label: 'NRO CARNET DE IDENTIDAD',
    validator: (value) => validarCI(value, esObligatorio: true),
    onChanged: _validateCiOnType, // <-- Llama a la validación debounced
    errorText: _ciErrorMessage,   // <-- Muestra el mensaje de error
    flex: isLargeScreen ? 2 : 1,
  );

  // 🛑 2. LÓGICA CONDICIONAL: Si el CI fue encontrado y NO estamos en modo edición,
  //      envolvemos el campo en un Column y añadimos el botón.
  if (_ciFound && !widget.isEditing) {
    ciField = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ciField, // El campo de texto con el error
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft, // Alineación del botón
          child: TextButton.icon(
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Autocompletar Campos Ahora'),
            onPressed: () {
              // 🚨 AL PRESIONAR EL BOTÓN: 
              // 1. Carga los datos de la persona encontrada (_personaTemp).
              loadPersona(_personaTemp); 
              
              // 2. Oculta el mensaje y el botón para que el usuario pueda guardar.
              setState(() {
                _ciFound = false; 
                _ciErrorMessage = null; 
              });
            },
          ),
        ),
      ],
    );
  }

  // 3. Retornar la lista final de widgets.
  return [
    _buildDropdownField<String>(
      value: _ciExpedidoSeleccionado,
      label: 'C.I EXPEDIDO',
      items: ref.watch(ciExpedidoProvider).when(
        data: (items) => items.map((item) =>
          DropdownMenuItem(
            value: item.codTipos,
            child: Text(item.nombre),
          ),
        ).toList(),
        loading: () => [],
        error: (_, __) => [],
      ),
      onChanged: (value) => setState(() => _ciExpedidoSeleccionado = value),
      validator: (value) => validarDropdown(value, 'C.I expedido'),
      flex: 1,
    ),
    ciField, // <-- Usamos el widget de CI (que ahora puede incluir el botón)
    _buildDateField(
      controller: _controllers['ciFechaVencimiento']!,
      label: 'FECHA DE VENCIMIENTO C.I',
      permitirFechaFutura: true,
      flex: 1,
    ),
    
  ];
}

  List<Widget> _buildDatosAdicionalesFields(bool isLargeScreen) {
    return [
      _buildDropdownField<String>(
        value: _estadoCivilSeleccionado,
        label: 'ESTADO CIVIL',
        items: ref.watch(estadoCivilProvider).when(
          data: (items) => items.map((item) =>
            DropdownMenuItem(
              value: item.codTipos,
              child: Text(item.nombre),
            ),
          ).toList(),
          loading: () => [],
          error: (_, __) => [],
        ),
        onChanged: (value) => setState(() => _estadoCivilSeleccionado = value),
        validator: (value) => validarDropdown(value, 'estado civil'),
        flex: 1,
      ),
      _buildDateField(
        controller: _controllers['fechaNacimiento']!,
        label: 'FECHA DE NACIMIENTO',
        flex: 1,
      ),
      _buildFormField(
        controller: _controllers['lugarNacimiento']!,
        label: 'LUGAR DE NACIMIENTO',
        validator: (value) => validarTextoMixto(value, esObligatorio: true),
        flex: isLargeScreen ? 2 : 1,
      ),
      _buildFormField(
        controller: _controllers['direccion']!,
        label: 'DIRECCIÓN',
        validator: (value) => validarTextoMixto(value, esObligatorio: true),
        flex: isLargeScreen ? 2 : 1,
      ),
      // NACIONALIDAD + botón agregar país
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: _buildNacionalidadField(flex: isLargeScreen ? 1 : 1),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Agregar País',
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  content: FormularioPais(
                    title: 'Agregar País',
                    isEditing: false,
                    onSave: (pais) async {
                await ref.read(registrarPaisProvider(pais).future);
                ref.invalidate(paisProvider);
                
              },
                    onCancel: () => Navigator.of(ctx).pop(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      // CIUDAD + botón agregar ciudad
      if (_nacionalidadSeleccionado != null)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: _buildCiudadField(flex: isLargeScreen ? 1 : 1),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Agregar Ciudad',
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    content: FormularioCiudad(
                      title: 'Agregar Ciudad',
                      codPais: _nacionalidadSeleccionado!,
                      isEditing: false,
                      onSave: (ciudad) async {
                  await ref.read(registrarCiudadProvider(ciudad).future);
                  ref.invalidate(ciudadProvider(_nacionalidadSeleccionado!));
                  
                },
                      onCancel: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      // ZONA + botón agregar zona
      if (_ciudadSeleccionada != null)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: _buildZonaField(flex: isLargeScreen ? 2 : 1),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Agregar Zona',
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    content: FormularioZona(
                      title: 'Agregar Zona',
                      codCiudad: _ciudadSeleccionada!,
                      codPersona: widget.codPersona,
                      isEditing: false,
                      onSave: (zona) async {
                  await ref.read(registrarZonaProvider(zona).future);
                  ref.invalidate(zonaProvider(_ciudadSeleccionada!));
                  
                },
                      onCancel: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      _buildGeneroField(flex: isLargeScreen ? 1 : 1),
    ];
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?)? validator,
    required int flex,
    String? errorText, // 🛑 NUEVO
    void Function(String)? onChanged, // 🛑 NUEVO
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 200,
        maxWidth: flex == 2 ? 400 : 250,
      ),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          errorText: errorText, // 🛑 AÑADIR errorText
          // Compatibilidad con modo oscuro
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          fillColor: Theme.of(context).colorScheme.surface,
          filled: true,
          errorMaxLines: 5
        ),
        validator: validator,
        inputFormatters: bloquearEspacios,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required String? Function(T?)? validator,
    required int flex,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 200,
        maxWidth: flex == 2 ? 600 : 300,
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          fillColor: Theme.of(context).colorScheme.surface,
          filled: true,
        ),
        items: items,
        onChanged: onChanged,
        validator: validator,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        dropdownColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    bool permitirFechaFutura = false,
    required int flex,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 200,
        maxWidth: flex == 2 ? 600 : 300,
      ),
      child: DatePickerField(
        controller: controller,
        labelText: label,
        permitirFechaFutura: permitirFechaFutura,
        // Puedes personalizar el DatePickerField si lo necesitas para modo oscuro
      ),
    );
  }

  Widget _buildNacionalidadField({required int flex}) {
    return _buildDropdownField<int>(
      value: _nacionalidadSeleccionado,
      label: 'NACIONALIDAD',
      items: ref.watch(paisProvider).when(
        data: (items) => items.map((item) =>
          DropdownMenuItem(
            value: item.codPais,
            child: Text(item.pais),
          ),
        ).toList(),
        loading: () => [],
        error: (_, __) => [],
      ),
      onChanged: (value) {
        setState(() {
          _nacionalidadSeleccionado = value;
          _ciudadSeleccionada = null;
          _zonaSeleccionado = null;
        });
      },
      validator: (value) => validarDropdown(
        value?.toString(),
        'nacionalidad',
      ),
      flex: flex,
    );
  }

 Widget _buildCiudadField({required int flex}) {
  final int? nacionalidad = _nacionalidadSeleccionado;
  final ciudadesSeleccionadas = ref.watch(ciudadProvider(nacionalidad!)).when(
    data: (ciudades) => ciudades,
    loading: () => <dynamic>[],
    error: (_, __) => <dynamic>[],
  );

  // Si la nacionalidad seleccionada NO es Bolivia, también agrega las ciudades de Bolivia
  List<dynamic> ciudadesFinal = ciudadesSeleccionadas;
  if (nacionalidad != 1) {
    final ciudadesBolivia = ref.watch(ciudadProvider(1)).when(
      data: (ciudades) => ciudades,
      loading: () => <dynamic>[],
      error: (_, __) => <dynamic>[],
    );
    // Combina y elimina duplicados por codCiudad
    ciudadesFinal = [
      ...ciudadesSeleccionadas,
      ...ciudadesBolivia.where((ciudadB) =>
        !ciudadesSeleccionadas.any((c) => c.codCiudad == ciudadB.codCiudad)
      ),
    ];
  }
   // Solo limpiar si la lista está cargada y el valor no existe
  if (ciudadesFinal.isNotEmpty &&
      _ciudadSeleccionada != null &&
      !ciudadesFinal.any((c) => c.codCiudad == _ciudadSeleccionada)) {
    _ciudadSeleccionada = null;
  }

  return _buildDropdownField<int>(
    value: _ciudadSeleccionada,
    label: 'CIUDAD',
    items: ciudadesFinal.map<DropdownMenuItem<int>>((ciudad) =>
      DropdownMenuItem(
        value: ciudad.codCiudad,
        child: Text(ciudad.ciudad),
      ),
    ).toList(),
    onChanged: (value) {
      setState(() {
        _ciudadSeleccionada = value;
        _zonaSeleccionado = null;
      });
    },
    validator: (value) => validarDropdown(
      value?.toString(),
      'ciudad',
    ),
    flex: flex,
  );
}

  Widget _buildZonaField({required int flex}) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 200,
        maxWidth: flex == 2 ? 600 : 300,
      ),
      child: DropdownSearch<ZonaEntity>(
        selectedItem: ref.watch(zonaProvider(_ciudadSeleccionada!)).whenOrNull(
          data: (zonas) => zonas.firstWhere(
            (z) => z.codZona == _zonaSeleccionado,
            orElse: () => ZonaEntity(
              codZona: 0,
              zona: '',
              codCiudad: _ciudadSeleccionada!,
              audUsuario: 0,
            ),
          ),
        ),
        items: ref.watch(zonaProvider(_ciudadSeleccionada!)).when(
          data: (zonas) => zonas,
          loading: () => [],
          error: (_, __) => [],
        ),
        itemAsString: (ZonaEntity? zona) => zona?.zona ?? '',
        onChanged: (ZonaEntity? selectedZona) {
          setState(() => _zonaSeleccionado = selectedZona?.codZona);
        },
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: "Buscar Zona",
            border: const OutlineInputBorder(),
            labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            fillColor: Theme.of(context).colorScheme.surface,
            filled: true,
          ),
        ),
        validator: (value) => value == null ? 'zona' : null,
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: const TextFieldProps(
            decoration: InputDecoration(
              labelText: "Buscar por nombre",
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneroField({required int flex}) {
    return _buildDropdownField<String>(
      value: _generoSeleccionado,
      label: 'GÉNERO',
      items: ref.watch(sexoProvider).when(
        data: (items) => items.map((item) =>
          DropdownMenuItem(
            value: item.codTipos,
            child: Text(item.nombre),
          ),
        ).toList(),
        loading: () => [],
        error: (_, __) => [],
      ),
      onChanged: (value) => setState(() => _generoSeleccionado = value),
      validator: (value) => validarDropdown(value, 'género'),
      flex: flex,
    );
  }

  void _handleSubmit() async {
  if (_formKey.currentState?.validate() ?? false) {
    try {
      if (_ciFound && !widget.isEditing) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este CI ya está registrado'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final persona = await getPersona();
      
      try {
        await widget.onSave(persona);
        ref.invalidate(obtenerPersonaProvider(persona.codPersona));
        ref.invalidate(empleadosDependientesProvider);
        ref.invalidate(empleadoXJerarquiaProvider);
      } catch (e) {
        if (!mounted) return;

        // Extraer solo el mensaje relevante del error
        String mensajeError = 'El CI ya se encuentra registrado';
        
        // Si no es un error 409, usar mensaje genérico
        if (!e.toString().contains('409')) {
          mensajeError = 'No se pudo completar el registro';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeError),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo completar el registro'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

}