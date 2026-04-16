import 'dart:async';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/ciExpedido_entity.dart';
import 'package:bosque_flutter/domain/entities/estado_civil_entity.dart';
import 'package:bosque_flutter/domain/entities/pais_entity.dart';
import 'package:bosque_flutter/domain/entities/sexo_entity.dart';
import 'package:bosque_flutter/domain/entities/zona_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/map_viewer.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/validadores.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/persona_entity.dart';

class FormPersona extends ConsumerStatefulWidget {
  final GlobalKey<FormState> formKey;
  final GlobalKey<PersonaFormState>? stateKey;
  final PersonaEntity persona;
  final VoidCallback? onSaveProgress;

  const FormPersona({
    Key? key,
    required this.formKey,
    this.stateKey,
    required this.persona,
    this.onSaveProgress,
  }) : super(key: key);

  @override
  ConsumerState<FormPersona> createState() => PersonaFormState();
}

class PersonaFormState extends ConsumerState<FormPersona> {
  final double _vSpacing = 12.0;
  final double _hSpacing = 8.0;

  late final TextEditingController _nombresController;
  late final TextEditingController _apPaternoController;
  late final TextEditingController _apMaternoController;
  late final TextEditingController _ciNumeroController;
  late final TextEditingController _vencimientoCIController;
  late final TextEditingController _fechaNacimientoController;
  late final TextEditingController _lugarNacimientoController;
  late final TextEditingController _direccionController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final MapController _mapController;

  late double _currentLat;
  late double _currentLng;
  String? _currentSexo;
  String? _currentCiExpedido;
  String? _currentEstadoCivil;
  int? _currentNacionalidad;
  int? _currentCiudad;
  int? _currentZona;

  PaisEntity? _paisEntity;
  CiudadEntity? _ciudadEntity;
  ZonaEntity? _zonaEntity;
  PersonaEntity? _ultimaPersonaSync;

  String? _initialCi;
  String? _ciValidationError; // Para almacenar el error de CI del backend

  @override
  void initState() {
    super.initState();
    _nombresController = TextEditingController();
    _apPaternoController = TextEditingController();
    _apMaternoController = TextEditingController();
    _ciNumeroController = TextEditingController();
    _vencimientoCIController = TextEditingController();
    _fechaNacimientoController = TextEditingController();
    _lugarNacimientoController = TextEditingController();
    _direccionController = TextEditingController();
    _latController = TextEditingController();
    _lngController = TextEditingController();
    _mapController = MapController();

    _initialCi = widget.persona.ciNumero;
    _cargarDatos(widget.persona);
    // 🔄 IMPORTANTE: Limpiar error de CI cuando el usuario modifique el campo
    // Esto asegura que no se "pegue" el error anterior al probar otro CI
    _ciNumeroController.addListener(() {
      if (_ciValidationError != null) {
        setState(() => _ciValidationError = null);
      }
    });
  }

  void _cargarDatos(PersonaEntity persona) {
    if (!mounted) return;
    setState(() {
      _nombresController.text = persona.nombres;
      _apPaternoController.text = persona.apPaterno;
      _apMaternoController.text = persona.apMaterno;
      _ciNumeroController.text = persona.ciNumero;
      _vencimientoCIController.text = FechaUtils.formatDate(
        persona.ciFechaVencimiento,
      ); // ✅
      _fechaNacimientoController.text = FechaUtils.formatDate(
        persona.fechaNacimiento,
      );
      _lugarNacimientoController.text = persona.lugarNacimiento;
      _direccionController.text = persona.direccion;

      _currentLat = persona.lat ?? -16.5160;
      _currentLng = persona.lng ?? -68.1354;
      _latController.text = _currentLat.toString();
      _lngController.text = _currentLng.toString();

      _currentSexo = persona.sexo;
      _currentCiExpedido = persona.ciExpedido;
      _currentEstadoCivil = persona.estadoCivil;
      _currentNacionalidad =
          persona.nacionalidad != 0 ? persona.nacionalidad : null;
      _currentCiudad = persona.ciudad?.codCiudad;
      _currentZona = persona.codZona != 0 ? persona.codZona : null;

      _paisEntity = persona.pais;
      _ciudadEntity = persona.ciudad;
      _zonaEntity = persona.zona;
      _ciValidationError = null; // Limpiar error previo

      Future.microtask(
        () =>
            ref.read(currentNacionalidadProvider.notifier).state =
                _currentNacionalidad,
      );
    });
  }

  @override
  void didUpdateWidget(covariant FormPersona oldWidget) {
    super.didUpdateWidget(oldWidget);
    final PersonaEntity personaActual =
        ref.read(tempPersonaProvider) ?? widget.persona;
    if (_ultimaPersonaSync?.codPersona != personaActual.codPersona ||
        oldWidget.persona != widget.persona) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarDatos(personaActual);
        _ultimaPersonaSync = personaActual;
        _initialCi = personaActual.ciNumero;
      });
    }
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apPaternoController.dispose();
    _apMaternoController.dispose();
    _ciNumeroController.dispose();
    _vencimientoCIController.dispose();
    _fechaNacimientoController.dispose();
    _lugarNacimientoController.dispose();
    _direccionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<String?> _validarCiBackend(String ciNumero) async {
    final currentCi = ciNumero.trim();

    // No validar si es el mismo CI en modo edición
    if (widget.persona.codPersona != 0 && currentCi == _initialCi) {
      return null; // El CI no ha cambiado, se considera válido
    }

    try {
      // Hacer la llamada al backend
      final personaExistente = await ref.read(
        obtenerPersonaXCarnet(currentCi).future,
      );

      if (personaExistente.codPersona != 0) {
        return 'Este C.I. ya está registrado por otra persona';
      }
    } catch (e) {
      // Error (404) significa CI no existe y está disponible
      // No retornar error, es lo esperado
    }
    return null;
  }

  Future<bool> validarYGuardar() async {
    // 🔄 PASO 1: Invalidar TODOS los providers de CI para limpiar cache
    // Esto asegura que la siguiente lectura sea fresca desde el backend
    ref.invalidate(obtenerPersonaXCarnet);

    // Primero validar localmente todos los campos
    if (!widget.formKey.currentState!.validate()) {
      // Si hay algún error local, no continuar
      return false;
    }

    // Ahora validar CI contra el backend (con cache limpio)
    final currentCi = _ciNumeroController.text.trim();
    final ciError = await _validarCiBackend(currentCi);

    if (ciError != null) {
      // Mostrar el error en el campo CI
      setState(() => _ciValidationError = ciError);
      // Hacer que el formulario sea inválido para que se muestre el error
      widget.formKey.currentState?.validate();
      return false;
    }

    // Limpiar error si todo pasó
    setState(() => _ciValidationError = null);

    FocusManager.instance.primaryFocus?.unfocus();

    final personaGuardada = widget.persona.copyWith(
      nombres: _nombresController.text.trim(),
      apPaterno: _apPaternoController.text.trim(),
      apMaterno: _apMaternoController.text.trim(),
      ciNumero: _ciNumeroController.text.trim(),
      ciFechaVencimiento: FechaUtils.parseDate(
        _vencimientoCIController.text,
      ), // ✅
      fechaNacimiento: FechaUtils.parseDate(
        _fechaNacimientoController.text,
      ), // ✅
      lugarNacimiento: _lugarNacimientoController.text.trim(),
      direccion: _direccionController.text.trim(),
      lat: double.tryParse(_latController.text) ?? _currentLat,
      lng: double.tryParse(_lngController.text) ?? _currentLng,
      sexo: _currentSexo ?? '',
      ciExpedido: _currentCiExpedido ?? '',
      estadoCivil: _currentEstadoCivil ?? '',
      nacionalidad: _currentNacionalidad ?? 0,
      codZona: _currentZona ?? 0,
      pais: _paisEntity,
      ciudad: _ciudadEntity,
      zona: _zonaEntity,
    );

    ref.read(tempPersonaProvider.notifier).state = personaGuardada;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = context.isMobile;
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing),
      child: Form(
        key: widget.formKey,
        // ✅ AGREGAR FocusTraversalGroup
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child:
              isMobile ? _buildMobileLayout(isKeyboardOpen) : _buildWebLayout(),
        ),
      ),
    );
  }

  Widget _buildWebLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Column(children: _buildFormFields()),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: _buildMapSection(false)),
      ],
    );
  }

  Widget _buildMobileLayout(bool keyboardOpen) {
    return Column(
      children: [
        FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Column(children: _buildFormFields()),
        ),
        if (!keyboardOpen) ...[
          const SizedBox(height: 16),
          _buildMapSection(true),
        ],
        if (keyboardOpen)
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
      ],
    );
  }

  List<Widget> _buildFormFields() {
    return [
      _sectionTitle('Identificación y Cédula'),
      _row([
        _textInput(
          _nombresController,
          'Nombres',
          true,
          'Ingresa tu nombre completo',
          false,
          validarNombres,
        ),
        _textInput(
          _apPaternoController,
          'Ap. Paterno',
          false,
          'Opcional',
          false,
          (v) {
            if (v == null || v.trim().isEmpty) return null;
            return validarNombres(v);
          },
        ),
      ]),
      _row([
        _textInput(
          _apMaternoController,
          'Ap. Materno',
          false,
          'Opcional',
          false,
          (v) {
            if (v == null || v.trim().isEmpty) return null;
            return validarNombres(v);
          },
        ),
        _buildCiField(),
      ]),
      _row([
        CustomDropdown<CiExpedidoEntity>(
          asyncValue: ref.watch(ciExpedidoProvider),
          label: 'Expedido',
          currentValue: _currentCiExpedido,
          getName: (e) => e.nombre,
          getCode: (e) => e.codTipos,
          onChanged: (val) => setState(() => _currentCiExpedido = val),
          validator:
              (value) =>
                  value?.isEmpty ?? true
                      ? 'Selecciona dónde fue expedido'
                      : null,
        ),
        _buildVencimientoCIField(),
      ]),
      const SizedBox(height: 12),
      _sectionTitle('Nacimiento y Estado'),
      _row([
        _buildFechaNacimientoField(),
        _textInput(
          _lugarNacimientoController,
          'Lugar Nac.',
          true,
          'Ciudad o región de nacimiento',
          false,
          validarLugarNacimiento,
        ),
      ]),
      _row([
        CustomDropdown<SexoEntity>(
          asyncValue: ref.watch(sexoProvider),
          label: 'Sexo',
          currentValue: _currentSexo,
          getName: (e) => e.nombre,
          getCode: (e) => e.codTipos,
          onChanged: (val) => setState(() => _currentSexo = val),
          validator:
              (value) => value?.isEmpty ?? true ? 'Selecciona tu sexo' : null,
        ),
        CustomDropdown<EstadoCivilEntity>(
          asyncValue: ref.watch(estadoCivilProvider),
          label: 'Estado Civil',
          currentValue: _currentEstadoCivil,
          getName: (e) => e.nombre,
          getCode: (e) => e.codTipos,
          onChanged: (val) => setState(() => _currentEstadoCivil = val),
          validator:
              (value) =>
                  value?.isEmpty ?? true ? 'Selecciona tu estado civil' : null,
        ),
      ]),
      _fullWidth(
        CustomDropdown<PaisEntity>(
          asyncValue: ref.watch(paisProvider),
          label: 'Nacionalidad (País)',
          currentValue: _currentNacionalidad?.toString(),
          getName: (e) => e.pais,
          getCode: (e) => e.codPais.toString(),
          onChanged: (val) {
            final id = int.tryParse(val ?? '0');
            ref.read(paisProvider).whenData((list) {
              _paisEntity = list.firstWhere(
                (p) => p.codPais == id,
                orElse: () => PaisEntity.vacio(),
              );
              setState(() => _currentNacionalidad = id);
              ref.read(currentNacionalidadProvider.notifier).state = id;
            });
          },
          validator:
              (value) =>
                  value?.isEmpty ?? true ? 'Selecciona tu nacionalidad' : null,
        ),
      ),
      const SizedBox(height: 12),
      _sectionTitle('Dirección'),
      _fullWidth(
        _textInput(
          _direccionController,
          'Dirección Completa',
          true,
          'Calle, número, edificio, etc.',
          false,
          validarDireccion,
        ),
      ),
      _row([_buildCiudadField(), _buildZonaField()]),
    ];
  }

  /// Campo CI con validación del backend integrada
  Widget _buildCiField() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _ciNumeroController,
          keyboardType: TextInputType.text,
          inputFormatters: [
            LengthLimitingTextInputFormatter(10), // ✅ AUMENTADO A 10
            FilteringTextInputFormatter.allow(
              RegExp(r'[a-zA-Z0-9\-]'),
            ), // ✅ PERMITIR GUION
          ],
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: 'CI Número',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            border: const OutlineInputBorder(),
            hintText: 'Ej: 9154499-A',
          ),
          validator: (v) {
            return validarCI(v, ciBackendError: _ciValidationError);
          },
        ),
      ],
    );
  }

  // ...existing code...

  /// Campo de Vencimiento del CI con validación de fecha
  Widget _buildVencimientoCIField() {
    return CustomDatePicker(
      controller: _vencimientoCIController,
      label: 'Vencimiento CI',
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      validator: validarFechaVencimientoCi,
    );
  }

  /// Campo de Fecha de Nacimiento con validación
  Widget _buildFechaNacimientoField() {
    return CustomDatePicker(
      controller: _fechaNacimientoController,
      label: 'Fecha Nac.',
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(
        const Duration(days: 365 * 18),
      ), // -18 años
      validator: validarFechaNacimiento,
    );
  }

  Widget _buildCiudadField() {
    final ciudadesAsync = ref.watch(ciudadesCombinadasProvider);
    return CustomDropdown<CiudadEntity>(
      asyncValue: ciudadesAsync,
      label: 'Ciudad',
      currentValue: _currentCiudad?.toString(),
      getName: (e) => e.ciudad,
      getCode: (e) => e.codCiudad.toString(),
      onChanged: (val) {
        final id = int.tryParse(val ?? '0');
        ciudadesAsync.whenData((list) {
          setState(() {
            _currentCiudad = id;
            _ciudadEntity = list.firstWhere(
              (c) => c.codCiudad == id,
              orElse: () => CiudadEntity.vacio(),
            );
            _currentZona = null;
            _zonaEntity = null;
          });
        });
      },
      validator:
          (value) => value?.isEmpty ?? true ? 'Selecciona tu ciudad' : null,
    );
  }

  Widget _buildZonaField() {
    final zonasAsync = ref.watch(zonaProvider(_currentCiudad ?? 0));
    return CustomDropdown<ZonaEntity>(
      asyncValue: zonasAsync,
      label: 'Zona',
      currentValue: _currentZona?.toString(),
      getName: (e) => e.zona,
      getCode: (e) => e.codZona.toString(),
      onChanged: (val) {
        final id = int.tryParse(val ?? '0');
        zonasAsync.whenData((list) {
          setState(() {
            _currentZona = id;
            _zonaEntity = list.firstWhere(
              (z) => z.codZona == id,
              orElse: () => ZonaEntity.vacio(),
            );
          });
        });
      },
      validator:
          (value) => value?.isEmpty ?? true ? 'Selecciona tu zona' : null,
    );
  }

  Widget _row(List<Widget> children) {
    return Padding(
      padding: EdgeInsets.only(bottom: _vSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            children
                .map(
                  (c) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: _hSpacing / 2),
                      child: c,
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _fullWidth(Widget child) => Padding(
    padding: EdgeInsets.only(
      bottom: _vSpacing,
      left: _hSpacing / 2,
      right: _hSpacing / 2,
    ),
    child: child,
  );

  Widget _sectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const Divider(height: 16),
      ],
    );
  }

  Widget _textInput(
    TextEditingController controller,
    String label,
    bool required, [
    String? hint,
    bool isNum = false,
    String? Function(String?)? customValidator,
  ]) {
    return TextFormField(
      controller: controller,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      inputFormatters: isNum ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
        border: const OutlineInputBorder(),
        hintText: hint,
      ),
      validator: (v) {
        if (customValidator != null) return customValidator(v);
        if (required && (v == null || v.isEmpty)) {
          return 'Este campo es obligatorio';
        }
        return null;
      },
    );
  }

  Widget _buildMapSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Ubicación en Mapa'),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: isMobile ? 220 : 500,
            child: MapViewer(
              mapController: _mapController,
              latitude: _currentLat,
              longitude: _currentLng,
              canChangeLocation: true,
              isInteractive: true,
              onTap: (point) {
                setState(() {
                  _currentLat = point.latitude;
                  _currentLng = point.longitude;
                  _latController.text = point.latitude.toString();
                  _lngController.text = point.longitude.toString();
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
