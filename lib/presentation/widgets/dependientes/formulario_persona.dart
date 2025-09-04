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
   @override
  void initState() {
    super.initState();
    _initControllers();
    _initSelections();
    // Inicializar las coordenadas
    _currentLat = widget.persona?.lat ?? -16.516064598979447;
    _currentLng = widget.persona?.lng ?? -68.13540079367057;
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
      ? FormatearFecha.formatearFecha(widget.persona!.ciFechaVencimiento)
      : ''
  ),
  'fechaNacimiento': TextEditingController(
    text: widget.persona?.fechaNacimiento != null 
      ? FormatearFecha.formatearFecha(widget.persona!.fechaNacimiento)
      : ''
  ),   
      
      'lugarNacimiento': TextEditingController(
        text: widget.persona?.lugarNacimiento??'',
      ),
    };
  }
  Future<int> getCodUsuario() async {
    return await ref.read(userProvider.notifier).getCodUsuario();
  }
  Future<PersonaEntity> getPersona() async {
  final codUsuario = await getCodUsuario();
  return PersonaEntity(
    codPersona: widget.isEditing ? widget.persona?.codPersona ?? 0 : 0,
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
      _buildFormField(
        controller: _controllers['ciNumero']!,
        label: 'NRO CARNET DE IDENTIDAD',
        validator: (value) => validarSoloNumeros(value, esObligatorio: true),
        flex: isLargeScreen ? 2 : 1,
      ),
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
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 200,
        maxWidth: flex == 2 ? 400 : 250,
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          // Compatibilidad con modo oscuro
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          fillColor: Theme.of(context).colorScheme.surface,
          filled: true,
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
      // Crear la persona basado en si estamos editando o creando
      final persona = PersonaEntity(
        codPersona: widget.isEditing ? widget.persona!.codPersona : 0, // Mantener ID si es edición
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
        audUsuarioI: await getCodUsuario(), 
        
      );


      await widget.onSave(persona);
      ref.invalidate(obtenerPersonaProvider(persona.codPersona));
      ref.invalidate(empleadosDependientesProvider);
      if (mounted) {
        // Mostrar mensaje según la operación
        if (widget.isEditing) {
          AppSnackbarCustom.showEdit(
            context, 
            'Datos actualizados correctamente'
          );
        } else {
          AppSnackbarCustom.showAdd(
            context, 
            'Datos registrados correctamente'
          );
        }
      }
      
    } catch (e) {
      if (mounted) {
        AppSnackbarCustom.show(
          context: context,
          message: 'Error: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }
}

}