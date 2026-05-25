import 'dart:convert';

import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart'; // Importado para executeABM
import 'package:bosque_flutter/data/models/Persona_model.dart';
import 'package:bosque_flutter/data/models/cargo_sucursal_model.dart';
import 'package:bosque_flutter/data/models/educacion_model.dart';
import 'package:bosque_flutter/data/models/email_model.dart';
import 'package:bosque_flutter/data/models/experiencia_laboral_model.dart';
import 'package:bosque_flutter/data/models/formacion_model.dart';
import 'package:bosque_flutter/data/models/nro_cuenta_bancaria_model.dart';
import 'package:bosque_flutter/data/models/relacion_laboral_model.dart';
import 'package:bosque_flutter/data/models/telefono_model.dart';
import 'package:bosque_flutter/domain/entities/cargo_sucursal_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/nro_cuenta_bancaria_entity.dart';
import 'package:bosque_flutter/domain/entities/relacion_laboral_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_area_cargo.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_educacion.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_email.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_exp_lab.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_formacion.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_informacion_bancaria.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_relacion_laboral.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_telefono.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/form_persona.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/resumen_registro_empleado.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart'; // Extensión responsiva
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:bosque_flutter/domain/entities/persona_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistroEmpleado extends ConsumerStatefulWidget {
  const RegistroEmpleado({Key? key}) : super(key: key);

  @override
  ConsumerState<RegistroEmpleado> createState() => _RegistroEmpleadoState();
}

class _RegistroEmpleadoState extends ConsumerState<RegistroEmpleado> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  Timer? _debounce;

  int _currentStep = 0;
  String? _errorMessage;
  bool _isSaving = false; // Nueva variable para controlar el estado de guardado
  PersonaEntity? _selectedPersona;
  final _datosPersonalesFormKey = GlobalKey<FormState>();
  final _personaFormStateKey = GlobalKey<PersonaFormState>();
  // Claves para SharedPreferences
  static const String _prefsCurrentStepKey = 'registroEmpleado_currentStep';
  static const String _prefsSelectedPersonaCodKey =
      'registroEmpleado_selectedPersonaCod';
  static const String _prefsNewPersonaDataKey =
      'registroEmpleado_newPersonaData';
  static const String _prefsTelefonosKey = 'registroEmpleado_telefonos';
  static const String _prefsEmailsKey = 'registroEmpleado_emails';
  static const String _prefsEducacionKey = 'registroEmpleado_educacion';
  static const String _prefsFormacionKey = 'registroEmpleado_formacion';
  static const String _prefsExperienciaKey = 'registroEmpleado_experiencia';
  static const String _prefsRelacionLaboralKey =
      'registroEmpleado_relacion_laboral';
  static const String _prefsRegistroFuncionesKey =
      'registroEmpleado_registro_funciones';
  static const String _prefsCuentasBancariasKey =
      'registroEmpleado_cuentas_bancarias';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadProgressFromLocal();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchTerm != _searchController.text) {
        setState(() {
          _searchTerm = _searchController.text;
        });
      }
    });
  }

  void _limpiarProvidersTemporales() {
    ref.read(tempPersonaProvider.notifier).state = null;
    ref.read(tempTelefonoListProvider.notifier).state = [];
    ref.read(tempEmailListProvider.notifier).state = [];
    ref.read(tempEducacionListProvider.notifier).state = [];
    ref.read(tempFormacionListProvider.notifier).state = [];
    ref.read(tempExperienciaListProvider.notifier).state = [];
    ref.read(tempRelacionLaboralListProvider.notifier).state = [];
    ref.read(tempRegistroFuncionesListProvider.notifier).state = [];
    ref.read(tempCuentasBancariasProvider.notifier).state = [];
    ref.read(currentCargoInternoProvider.notifier).state = null;
    ref.read(currentCargoPlanillaProvider.notifier).state = null;
    _clearProgressFromLocal();
  }

  void _agregarNuevaPersona() {
    _limpiarProvidersTemporales();
    setState(() {
      _selectedPersona = PersonaEntity.vacio();
      _currentStep = 1;
    });
  }

  Future<void> _clearProgressFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsCurrentStepKey);
    await prefs.remove(_prefsSelectedPersonaCodKey);
    await prefs.remove(_prefsNewPersonaDataKey);
    // Limpiar todos los providers temporales
    await prefs.remove(_prefsTelefonosKey);
    await prefs.remove(_prefsEmailsKey);
    await prefs.remove(_prefsEducacionKey);
    await prefs.remove(_prefsFormacionKey);
    await prefs.remove(_prefsExperienciaKey);
    await prefs.remove(_prefsRelacionLaboralKey);
    await prefs.remove(_prefsRegistroFuncionesKey);
    await prefs.remove(_prefsCuentasBancariasKey);
  }

  Future<void> _saveProgressToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsCurrentStepKey, _currentStep);

    final persona = ref.read(tempPersonaProvider);
    if (persona == null) {
      await prefs.remove(_prefsSelectedPersonaCodKey);
      await prefs.remove(_prefsNewPersonaDataKey);
      return;
    }

    if (persona.codPersona != 0) {
      await prefs.setInt(_prefsSelectedPersonaCodKey, persona.codPersona);
      await prefs.remove(_prefsNewPersonaDataKey);
    } else {
      await prefs.setString(
        _prefsNewPersonaDataKey,
        personaModelToJson(PersonaModel.fromEntity(persona)),
      );
      await prefs.remove(_prefsSelectedPersonaCodKey);
    }

    // Guardar todos los providers temporales
    await _saveTemporaryProviders(prefs);
  }

  Future<void> _saveTemporaryProviders(SharedPreferences prefs) async {
    try {
      // 1. TELEFONOS
      final telefonos = ref.read(tempTelefonoListProvider);
      if (telefonos.isNotEmpty) {
        final telefonosJson = jsonEncode(
          telefonos.map((t) => TelefonoModel.fromEntity(t).toJson()).toList(),
        );
        await prefs.setString(_prefsTelefonosKey, telefonosJson);
      } else {
        await prefs.remove(_prefsTelefonosKey);
      }

      // 2. EMAILS
      final emails = ref.read(tempEmailListProvider);
      if (emails.isNotEmpty) {
        final emailsJson = jsonEncode(
          emails.map((e) => EmailModel.fromEntity(e).toJson()).toList(),
        );
        await prefs.setString(_prefsEmailsKey, emailsJson);
      } else {
        await prefs.remove(_prefsEmailsKey);
      }

      // 3. EDUCACION
      final educaciones = ref.read(tempEducacionListProvider);
      if (educaciones.isNotEmpty) {
        final educacionJson = jsonEncode(
          educaciones
              .map((e) => EducacionModel.fromEntity(e).toJson())
              .toList(),
        );
        await prefs.setString(_prefsEducacionKey, educacionJson);
      } else {
        await prefs.remove(_prefsEducacionKey);
      }

      // 4. FORMACION
      final formaciones = ref.read(tempFormacionListProvider);
      if (formaciones.isNotEmpty) {
        final formacionJson = jsonEncode(
          formaciones
              .map((f) => FormacionModel.fromEntity(f).toJson())
              .toList(),
        );
        await prefs.setString(_prefsFormacionKey, formacionJson);
      } else {
        await prefs.remove(_prefsFormacionKey);
      }

      // 5. EXPERIENCIA
      final experiencias = ref.read(tempExperienciaListProvider);
      if (experiencias.isNotEmpty) {
        final experienciaJson = jsonEncode(
          experiencias
              .map((e) => ExperienciaLaboralModel.fromEntity(e).toJson())
              .toList(),
        );
        await prefs.setString(_prefsExperienciaKey, experienciaJson);
      } else {
        await prefs.remove(_prefsExperienciaKey);
      }

      // 6. RELACION LABORAL
      final relaciones = ref.read(tempRelacionLaboralListProvider);
      if (relaciones.isNotEmpty) {
        final relacionJson = jsonEncode(
          relaciones
              .map((r) => RelacionLaboralModel.fromEntity(r).toJson())
              .toList(),
        );
        await prefs.setString(_prefsRelacionLaboralKey, relacionJson);
      } else {
        await prefs.remove(_prefsRelacionLaboralKey);
      }

      // 7. REGISTRO DE FUNCIONES (CARGOS) - ✅ SERIALIZAR CORRECTAMENTE
      final registroFunciones = ref.read(tempRegistroFuncionesListProvider);
      if (registroFunciones.isNotEmpty) {
        final cargosSerializados =
            registroFunciones.map((cargo) {
              return {
                'codCargoSucursal': cargo['codCargoSucursal'],
                'codCargoSucPlanilla': cargo['codCargoSucPlanilla'],
                'fechaInicio':
                    (cargo['fechaInicio'] as DateTime).toIso8601String(),
                'cargoSucursal':
                    cargo['cargoSucursal'] is CargoSucursalEntity
                        ? CargoSucursalModel.fromEntity(
                          cargo['cargoSucursal'],
                        ).toJson()
                        : cargo['cargoSucursal'],
                'cargoSucursalPlanilla':
                    cargo['cargoSucursalPlanilla'] is CargoSucursalEntity
                        ? CargoSucursalModel.fromEntity(
                          cargo['cargoSucursalPlanilla'],
                        ).toJson()
                        : cargo['cargoSucursalPlanilla'],
                'cargoPlanilla': cargo['cargoPlanilla'],
                'existe': cargo['existe'],
                'audUsuario': cargo['audUsuario'],
              };
            }).toList();

        final registroJson = jsonEncode(cargosSerializados);
        await prefs.setString(_prefsRegistroFuncionesKey, registroJson);
      } else {
        await prefs.remove(_prefsRegistroFuncionesKey);
      }

      // 8. CUENTAS BANCARIAS
      final cuentas = ref.read(tempCuentasBancariasProvider);
      if (cuentas.isNotEmpty) {
        final cuentasJson = jsonEncode(
          cuentas
              .map((c) => NroCuentaBancariaModel.fromEntity(c).toJson())
              .toList(),
        );
        await prefs.setString(_prefsCuentasBancariasKey, cuentasJson);
      } else {
        await prefs.remove(_prefsCuentasBancariasKey);
      }
    } catch (e) {
      debugPrint('❌ Error guardando providers temporales: $e');
    }
  }

  Future<void> _loadProgressFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStep = prefs.getInt(_prefsCurrentStepKey);

    if (savedStep == null || savedStep <= 0 || !mounted) return;

    setState(() => _currentStep = savedStep);

    final savedCod = prefs.getInt(_prefsSelectedPersonaCodKey);
    if (savedCod != null && savedCod > 0) {
      try {
        final persona = await ref.read(obtenerPersonaProvider(savedCod).future);
        ref.read(tempPersonaProvider.notifier).state = persona;
        setState(() => _selectedPersona = persona);

        // Cargar providers temporales
        await _loadTemporaryProviders(prefs);
      } catch (e) {
        _showErrorSnackBar(
          'No se pudo restaurar la persona. Selecciona de nuevo.',
        );
        _limpiarProvidersTemporales();
        setState(() => _currentStep = 0);
      }
      return;
    }

    final savedJson = prefs.getString(_prefsNewPersonaDataKey);
    if (savedJson != null && savedJson.isNotEmpty) {
      try {
        final persona = personaModelFromJson(savedJson).toEntity();
        ref.read(tempPersonaProvider.notifier).state = persona;
        setState(() => _selectedPersona = persona);

        // Cargar providers temporales
        await _loadTemporaryProviders(prefs);
      } catch (e) {
        _showErrorSnackBar(
          'No se pudieron restaurar los datos. Comienza de nuevo.',
        );
        _limpiarProvidersTemporales();
        setState(() => _currentStep = 0);
      }
    }
  }

  Future<void> _loadTemporaryProviders(SharedPreferences prefs) async {
    try {
      // 1. TELEFONOS
      final telefonosJson = prefs.getString(_prefsTelefonosKey);
      if (telefonosJson != null && telefonosJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(telefonosJson) as List<dynamic>;
          final telefonos =
              decoded
                  .map(
                    (e) =>
                        TelefonoModel.fromJson(
                          Map<String, dynamic>.from(e as Map),
                        ).toEntity(),
                  )
                  .toList();
          ref.read(tempTelefonoListProvider.notifier).state = telefonos;
        } catch (e) {
          debugPrint('⚠️ Error deserializando telefonos: $e');
        }
      }

      // 2. EMAILS
      final emailsJson = prefs.getString(_prefsEmailsKey);
      if (emailsJson != null && emailsJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(emailsJson) as List<dynamic>;
          final emails =
              decoded
                  .map(
                    (e) =>
                        EmailModel.fromJson(
                          Map<String, dynamic>.from(e as Map),
                        ).toEntity(),
                  )
                  .toList();
          ref.read(tempEmailListProvider.notifier).state = emails;
        } catch (e) {
          debugPrint('⚠️ Error deserializando emails: $e');
        }
      }

      // 3. EDUCACION
      final educacionJson = prefs.getString(_prefsEducacionKey);
      if (educacionJson != null && educacionJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(educacionJson) as List<dynamic>;
          final educaciones =
              decoded
                  .map(
                    (e) =>
                        EducacionModel.fromJson(
                          Map<String, dynamic>.from(e as Map),
                        ).toEntity(),
                  )
                  .toList();
          ref.read(tempEducacionListProvider.notifier).state = educaciones;
        } catch (e) {
          debugPrint('⚠️ Error deserializando educacion: $e');
        }
      }

      // 4. FORMACION
      final formacionJson = prefs.getString(_prefsFormacionKey);
      if (formacionJson != null && formacionJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(formacionJson) as List<dynamic>;
          final formaciones =
              decoded
                  .map(
                    (e) =>
                        FormacionModel.fromJson(
                          Map<String, dynamic>.from(e as Map),
                        ).toEntity(),
                  )
                  .toList();
          ref.read(tempFormacionListProvider.notifier).state = formaciones;
        } catch (e) {
          debugPrint('⚠️ Error deserializando formacion: $e');
        }
      }

      // 5. EXPERIENCIA
      final experienciaJson = prefs.getString(_prefsExperienciaKey);
      if (experienciaJson != null && experienciaJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(experienciaJson) as List<dynamic>;
          final experiencias =
              decoded
                  .map(
                    (e) =>
                        ExperienciaLaboralModel.fromJson(
                          Map<String, dynamic>.from(e as Map),
                        ).toEntity(),
                  )
                  .toList();
          ref.read(tempExperienciaListProvider.notifier).state = experiencias;
        } catch (e) {
          debugPrint('⚠️ Error deserializando experiencia: $e');
        }
      }

      // 6. RELACION LABORAL
      final relacionJson = prefs.getString(_prefsRelacionLaboralKey);
      if (relacionJson != null && relacionJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(relacionJson) as List<dynamic>;
          final relaciones =
              decoded
                  .map(
                    (e) =>
                        RelacionLaboralModel.fromJson(
                          Map<String, dynamic>.from(e as Map),
                        ).toEntity(),
                  )
                  .toList();
          ref.read(tempRelacionLaboralListProvider.notifier).state = relaciones;
        } catch (e) {
          debugPrint('⚠️ Error deserializando relacion laboral: $e');
        }
      }

      // 7. REGISTRO DE FUNCIONES (CARGOS) - ✅ RECONSTRUIR CORRECTAMENTE
      final registroFuncionesJson = prefs.getString(_prefsRegistroFuncionesKey);
      if (registroFuncionesJson != null && registroFuncionesJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(registroFuncionesJson) as List<dynamic>;
          final rawList =
              decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();

          // Reconstruir los campos que la UI espera como entidades/DateTime
          final List<Map<String, dynamic>> cargosConverted =
              rawList.map((raw) {
                final Map<String, dynamic> item = Map<String, dynamic>.from(
                  raw,
                );

                // cargoSucursal: Map → Entity
                final csRaw = item['cargoSucursal'];
                if (csRaw is Map) {
                  item['cargoSucursal'] =
                      CargoSucursalModel.fromJson(
                        Map<String, dynamic>.from(csRaw),
                      ).toEntity();
                }

                // cargoSucursalPlanilla: Map → Entity
                final csPlanRaw = item['cargoSucursalPlanilla'];
                if (csPlanRaw is Map) {
                  item['cargoSucursalPlanilla'] =
                      CargoSucursalModel.fromJson(
                        Map<String, dynamic>.from(csPlanRaw),
                      ).toEntity();
                }

                // fechaInicio: String ISO → DateTime
                final fechaRaw = item['fechaInicio'];
                if (fechaRaw is String) {
                  item['fechaInicio'] =
                      DateTime.tryParse(fechaRaw) ?? DateTime.now();
                }

                return item;
              }).toList();

          ref.read(tempRegistroFuncionesListProvider.notifier).state =
              cargosConverted;

          // Restaurar los providers individuales (cargo interno y planilla)
          if (cargosConverted.isNotEmpty) {
            final primerCargo = cargosConverted.first;
            final cargoInterno =
                primerCargo['cargoSucursal'] as CargoSucursalEntity?;
            final cargoPlanilla =
                primerCargo['cargoSucursalPlanilla'] as CargoSucursalEntity?;

            if (cargoInterno != null) {
              ref.read(currentCargoInternoProvider.notifier).state =
                  cargoInterno;
            }
            if (cargoPlanilla != null) {
              ref.read(currentCargoPlanillaProvider.notifier).state =
                  cargoPlanilla;
            }
          }
        } catch (e) {
          debugPrint('❌ Error deserializando registro funciones: $e');
        }
      }

      // 8. CUENTAS BANCARIAS
      final cuentasJson = prefs.getString(_prefsCuentasBancariasKey);
      if (cuentasJson != null && cuentasJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(cuentasJson) as List<dynamic>;
          final cuentas =
              decoded
                  .map(
                    (e) =>
                        NroCuentaBancariaModel.fromJson(
                          Map<String, dynamic>.from(e as Map),
                        ).toEntity(),
                  )
                  .toList();
          ref.read(tempCuentasBancariasProvider.notifier).state = cuentas;
        } catch (e) {
          debugPrint('⚠️ Error deserializando cuentas bancarias: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error cargando providers temporales: $e');
    }
  }

  // ===========================================================================
  // BUILDERS RESPONSIVOS
  // ===========================================================================

  Widget _buildSelectPersonStep() {
    final personasAsync = ref.watch(getLstPersona(_searchTerm));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Buscador responsivo (mismo estilo que ListaEmpleados)
        Container(
          constraints: BoxConstraints(
            maxWidth: context.isMobile ? double.infinity : 600,
          ),
          child: TextField(
            controller: _searchController,
            style: context.bodyStyle,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o apellido',
              hintStyle: context.bodyLightStyle,
              prefixIcon: const Icon(Icons.search, color: Colors.green),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: context.borderRadius,
                borderSide: BorderSide(color: Colors.green.shade100),
              ),
            ),
          ),
        ),
        SizedBox(height: context.spacing),
        ElevatedButton.icon(
          onPressed: _agregarNuevaPersona,
          icon: const Icon(Icons.person_add),
          label: const Text('Agregar Nueva Persona'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: context.padding,
            shape: RoundedRectangleBorder(borderRadius: context.borderRadius),
          ),
        ),
        const Divider(height: 32),
        Text("Resultados", style: context.subtitleStyle),
        SizedBox(height: context.smallSpacing),
        SizedBox(
          height: 400, // Altura fija controlada para el listado interno
          child: personasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (err, stack) => Center(
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            data: (personas) {
              if (personas.isEmpty) {
                return const Center(
                  child: Text('No se encontraron personas disponibles.'),
                );
              }
              return ListView.separated(
                itemCount: personas.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final persona = personas[index];
                  final isSelected =
                      persona.codPersona == _selectedPersona?.codPersona;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Colors.green.shade50,
                    leading: CircleAvatar(
                      backgroundColor:
                          isSelected ? Colors.green : Colors.grey.shade200,
                      child: Icon(
                        Icons.person_outline,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                    ),
                    title: Text(
                      '${persona.datoPersona}',
                      style: context.bodyStyle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'CI: ${persona.ciNumero} ${persona.ciExpedido.toUpperCase()}',
                      style: context.bodyLightStyle,
                    ),
                    trailing:
                        isSelected
                            ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            )
                            : const Icon(Icons.chevron_right),
                    onTap: () => _seleccionarPersona(persona, isSelected),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _seleccionarPersona(
    PersonaEntity persona,
    bool isSelected,
  ) async {
    if (isSelected) {
      setState(() => _selectedPersona = null);
      _clearProgressFromLocal();
      return;
    }

    setState(() => _selectedPersona = persona);
    final cod = persona.codPersona;
    if (cod != 0) {
      try {
        final personaFull = await ref.read(obtenerPersonaProvider(cod).future);
        _limpiarProvidersTemporales();
        ref.read(tempPersonaProvider.notifier).state = personaFull;
        setState(() => _selectedPersona = personaFull);
        _saveProgressToLocal();
      } catch (e) {
        _showErrorSnackBar('No se pudo cargar datos completos: $e');
        _limpiarProvidersTemporales();
        setState(() => _currentStep = 0);
      }
    } else {
      _saveProgressToLocal();
    }
  }

  List<Step> get _steps => [
    Step(
      title: Text('Persona', style: TextStyle(fontSize: context.smallFontSize)),
      content: _buildSelectPersonStep(),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
    ),
    Step(
      title: Text('Datos', style: TextStyle(fontSize: context.smallFontSize)),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content:
          _currentStep == 1
              ? _buildDatosPersonalesContent()
              : const SizedBox.shrink(),
    ),
    Step(
      title: Text(
        'Contacto',
        style: TextStyle(fontSize: context.smallFontSize),
      ),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content:
          _currentStep == 2
              ? Column(
                children: [
                  DetalleTelefono(
                    codPersona: _selectedPersona?.codPersona ?? 0,
                  ),
                  const Divider(height: 40),
                  DetalleEmail(codPersona: _selectedPersona?.codPersona ?? 0),
                ],
              )
              : const SizedBox.shrink(),
    ),
    Step(
      title: Text(
        'Educación',
        style: TextStyle(fontSize: context.smallFontSize),
      ),
      isActive: _currentStep >= 3,
      state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      content:
          _currentStep == 3
              ? DetalleEducacion(codEmpleado: 0)
              : const SizedBox.shrink(),
    ),
    Step(
      title: Text(
        'Formación',
        style: TextStyle(fontSize: context.smallFontSize),
      ),
      isActive: _currentStep >= 4,
      state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      content:
          _currentStep == 4
              ? DetalleFormacion(codEmpleado: 0)
              : const SizedBox.shrink(),
    ),
    Step(
      title: Text(
        'Experiencia',
        style: TextStyle(fontSize: context.smallFontSize),
      ),
      isActive: _currentStep >= 5,
      state: _currentStep > 5 ? StepState.complete : StepState.indexed,
      content:
          _currentStep == 5
              ? DetalleExperienciaLaboral(codEmpleado: 0)
              : const SizedBox.shrink(),
    ),
    Step(
      title: Text('Laboral', style: TextStyle(fontSize: context.smallFontSize)),
      isActive: _currentStep >= 6,
      state: _currentStep > 6 ? StepState.complete : StepState.indexed,
      content:
          _currentStep == 6
              ? Column(
                children: [
                  DetalleAreaCargo(),
                  const Divider(height: 32),
                  DetalleRelacionLaboral(codEmpleado: 0),
                  const Divider(height: 32),
                  DetalleInformacionBancaria(codEmpleado: 0),
                ],
              )
              : const SizedBox.shrink(),
    ),
    Step(
      title: Text('Resumen', style: TextStyle(fontSize: context.smallFontSize)),
      isActive: _currentStep >= 7,
      state: _currentStep > 7 ? StepState.complete : StepState.indexed,
      // ✅ PROTECCIÓN: Verificar que _selectedPersona no sea null
      content:
          _currentStep == 7 && _selectedPersona != null
              ? ResumenRegistroEmpleado(selectedPersona: _selectedPersona!)
              : const SizedBox.shrink(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Empleado'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          width: context.maxContainerWidth,
          padding: EdgeInsets.symmetric(vertical: context.spacing),
          child: Stepper(
            type:
                context.isMobile
                    ? StepperType.vertical
                    : StepperType.horizontal,
            currentStep: _currentStep,
            onStepTapped: null,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            controlsBuilder: (context, details) => const SizedBox.shrink(),
            steps: _steps,
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botones de acciones PRIMERO
          _buildBottomActions(),
          // MaterialBanner ABAJO (después de los botones)
          if (_errorMessage != null)
            MaterialBanner(
              content: Text(_errorMessage!),
              backgroundColor: Colors.red.shade600,
              contentTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),

              leading: const Icon(Icons.error, color: Colors.white),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _errorMessage = null),
                  child: const Text(
                    'CERRAR',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: context.padding,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_currentStep > 0)
              TextButton(
                onPressed: _isSaving ? null : _onStepCancel,
                child: const Text('Anterior'),
              ),
            SizedBox(width: context.spacing),
            ElevatedButton(
              onPressed: _isSaving ? null : _onStepContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing * 2,
                  vertical: 12,
                ),
              ),
              child:
                  _isSaving
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        _currentStep == _steps.length - 1
                            ? 'Finalizar Registro'
                            : 'Continuar',
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatosPersonalesContent() {
    final codPersona = _selectedPersona?.codPersona;
    final tempPersona = ref.watch(tempPersonaProvider);

    // Si no hay persona seleccionada, mostrar mensaje de espera
    if (_selectedPersona == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Si tenemos persona temporal con el mismo código, usar esa
    if (tempPersona != null &&
        tempPersona.codPersona == _selectedPersona!.codPersona) {
      return FormPersona(
        key: _personaFormStateKey,
        formKey: _datosPersonalesFormKey,
        persona: tempPersona,
        onSaveProgress: null,
      );
    }

    // Si es una persona nueva (codPersona == 0), usar _selectedPersona
    if (codPersona == 0) {
      return FormPersona(
        key: _personaFormStateKey,
        formKey: _datosPersonalesFormKey,
        persona: _selectedPersona!,
        onSaveProgress: null,
      );
    }

    // Si es una persona existente, cargar desde BD
    final personaDataAsync = ref.watch(obtenerPersonaProvider(codPersona!));
    return personaDataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data:
          (persona) => FormPersona(
            key: _personaFormStateKey,
            formKey: _datosPersonalesFormKey,
            persona: persona,
            onSaveProgress: null,
          ),
    );
  }

  Future<void> _onStepContinue() async {
    if (_isSaving) return; // Protección adicional

    // PASO 0: Persona (OBLIGATORIO)
    if (_currentStep == 0) {
      if (_selectedPersona == null) {
        _showErrorSnackBar('Por favor selecciona o agrega una persona');
        return;
      }
      ref.read(tempPersonaProvider.notifier).state = _selectedPersona;
      setState(() => _currentStep++);
      _saveProgressToLocal();
      return;
    }

    // PASO 1: Datos Personales (OBLIGATORIO - Validación de formulario y CI)
    if (_currentStep == 1) {
      final personaFormState = _personaFormStateKey.currentState;
      final guardarExitoso = await personaFormState?.validarYGuardar();
      if (guardarExitoso != true) {
        return;
      }

      setState(() => _currentStep++);
      _saveProgressToLocal();
      return;
    }

    // PASO 2: Contacto (OPCIONAL - se puede saltar)
    if (_currentStep == 2) {
      setState(() => _currentStep++);
      _saveProgressToLocal();
      return;
    }

    // PASO 3: Educación (OBLIGATORIO - al menos una entrada)
    if (_currentStep == 3) {
      final listaEducacion = ref.read(tempEducacionListProvider);
      if (listaEducacion.isEmpty) {
        _showErrorSnackBar('Debe registrar al menos un nivel de educación');
        return;
      }
      setState(() => _currentStep++);
      _saveProgressToLocal();
      return;
    }

    // PASO 4: Formación (OPCIONAL)
    // PASO 5: Experiencia Laboral (OPCIONAL)
    if (_currentStep == 4 || _currentStep == 5) {
      setState(() => _currentStep++);
      _saveProgressToLocal();
      return;
    }

    // PASO 6: Laboral (OBLIGATORIO - Cargo y Relación Laboral)
    if (_currentStep == 6) {
      final tieneCargo = ref.read(currentCargoInternoProvider) != null;
      final tieneRelacion =
          ref.read(tempRelacionLaboralListProvider).isNotEmpty;

      if (!tieneCargo) {
        _showErrorSnackBar('Debe seleccionar el Área y Cargo del empleado');
        return;
      }
      if (!tieneRelacion) {
        _showErrorSnackBar(
          'Debe completar la información de la Relación Laboral',
        );
        return;
      }
      setState(() => _currentStep++);
      _saveProgressToLocal();
      return;
    }

    // PASO FINAL O GUARDADO
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _saveProgressToLocal();
    } else {
      await _guardarRegistroCompleto();
    }
  }

  // ===========================================================================
  // MANEJO DE ABM CENTRALIZADO
  // ===========================================================================

  Future<void> _guardarRegistroCompleto() async {
    if (_isSaving) return;

    final personaCompleta = ref.read(tempPersonaProvider);
    if (personaCompleta == null) return;

    setState(() => _isSaving = true);

    try {
      final exito = await executeABM(
        ref: ref,
        context: context,
        successMessage: '✅ Empleado registrado exitosamente en el sistema',
        providersToInvalidate: [
          getListaEmpleados,
          empObtenerDatosEmpleado,
          getLstPersona,
          telefonoProvider,
          emailProvider,
          // Agrega otros providers que necesites refrescar aquí
        ],
        operation: () async {
          final user = ref.read(userProvider);
          final codUsuario = user?.codUsuario ?? 0;

          // 1. Registrar/Actualizar Persona
          final personaRegistrada = await ref.read(
            registrarPersonaProvider(personaCompleta).future,
          );
          final codPersona = personaRegistrada.codPersona;

          // 2. Preparar y Registrar Empleado
          // EmpleadoEntity sí tiene .copyWith()
          final empleadoEntityBase = EmpleadoEntity(
            codPersona: 0, // se llenará con personaRegistrada.codPersona
            codZona: 0, // se llenará con personaRegistrada.codZona
            nombres: '',
            apPaterno: '',
            apMaterno: '',
            ciExpedido: '',
            ciFechaVencimiento: DateTime.now(),
            ciNumero: '',
            direccion: '',
            estadoCivil: '',
            fechaNacimiento: DateTime.now(),
            lugarNacimiento: '',
            nacionalidad: 0,
            sexo: '',
            lat: 0,
            lng: 0,
            audUsuarioI: 0,
            datoPersona: '',
            codEmpleado: 0,
            numCuenta: '',
            codRelBeneficios: 0,
            codRelPlanilla: 0,
            codDependiente: 0,
            esActivoString: '',
            persona: PersonaEntity.vacio(), // Entidad base para el constructor
            empleadoCargo: EmpleadoCargoEntity(
              codCargoSucursal: 0,
              codCargoSucPlanilla: 0,
              fechaInicio: DateTime.now(),
              cargoSucursal: CargoSucursalEntity(
                codCargoSucursal: 0,
                codSucursal: 0,
                codCargo: 0,
                audUsuario: 0,
                datoCargo: '',
              ),
              cargoPlanilla: '',
              existe: 0,
              audUsuario: 0,
              codEmpleado: 0,
            ),
            dependiente: null,
            empresa: EmpresaEntity(
              codEmpresa: 0,
              nombre: '',
              codPadre: 0,
              sigla: '',
              audUsuario: 0,
            ),
            sucursal: SucursalEntity(
              codSucursal: 0,
              nombre: '',
              codEmpresa: 0,
              codCiudad: 0,
              audUsuarioI: 0,
              nombreCiudad: '',
              codSucursalPlanilla: 0,
              nombrePlanilla: '',
              empresa: EmpresaEntity(
                codEmpresa: 0,
                nombre: '',
                codPadre: 0,
                sigla: '',
                audUsuario: 0,
              ),
            ),
            relEmpEmpr: RelacionLaboralEntity(
              codRelEmplEmpr: 0,
              codEmpleado: 0,
              esActivo: 1,
              tipoRel: '',
              nombreFileContrato: '',
              fechaIni: DateTime.now(),
              motivoFin: '',
              audUsuario: 0,
              cargo: '',
              sucursal: '',
              empresaFiscal: '',
              empresaInterna: '',
            ),
          );

          final empleadoEntity = empleadoEntityBase.copyWith(
            codPersona: codPersona,
            codZona: personaRegistrada.codZona,
            nombres: personaRegistrada.nombres,
            apPaterno: personaRegistrada.apPaterno,
            apMaterno: personaRegistrada.apMaterno,
            ciExpedido: personaRegistrada.ciExpedido,
            ciFechaVencimiento: personaRegistrada.ciFechaVencimiento,
            ciNumero: personaRegistrada.ciNumero,
            direccion: personaRegistrada.direccion,
            estadoCivil: personaRegistrada.estadoCivil,
            fechaNacimiento: personaRegistrada.fechaNacimiento,
            lugarNacimiento: personaRegistrada.lugarNacimiento,
            nacionalidad: personaRegistrada.nacionalidad,
            sexo: personaRegistrada.sexo,
            lat: personaRegistrada.lat,
            lng: personaRegistrada.lng,
            audUsuarioI: codUsuario,
            datoPersona: personaRegistrada.datoPersona,
            // Las siguientes propiedades pueden necesitar valores por defecto o ser manejadas en su propia lógica de registro
            empleadoCargo: EmpleadoCargoEntity(
              codCargoSucursal: 0,
              codCargoSucPlanilla: 0,
              fechaInicio: DateTime.now(),
              cargoSucursal: CargoSucursalEntity(
                codCargoSucursal: 0,
                codSucursal: 0,
                codCargo: 0,
                audUsuario: 0,
                datoCargo: '',
              ),
              cargoPlanilla: '',
              existe: 0,
              audUsuario: 0,
              codEmpleado: 0,
            ),
            empresa: EmpresaEntity(
              codEmpresa: 0,
              nombre: '',
              codPadre: 0,
              sigla: '',
              audUsuario: 0,
            ),
            sucursal: SucursalEntity(
              codSucursal: 0,
              nombre: '',
              codEmpresa: 0,
              codCiudad: 0,
              audUsuarioI: 0,
              nombreCiudad: '',
              codSucursalPlanilla: 0,
              nombrePlanilla: '',
              empresa: EmpresaEntity(
                codEmpresa: 0,
                nombre: '',
                codPadre: 0,
                sigla: '',
                audUsuario: 0,
              ),
            ),
            relEmpEmpr: RelacionLaboralEntity(
              codRelEmplEmpr: 0,
              codEmpleado: 0,
              esActivo: 1,
              tipoRel: '',
              nombreFileContrato: '',
              fechaIni: DateTime.now(),
              motivoFin: '',
              audUsuario: 0,
              cargo: '',
              sucursal: '',
              empresaFiscal: '',
              empresaInterna: '',
            ),
          );

          final empleadoRegistrado = await ref.read(
            registrarEmpleadoProvider(empleadoEntity).future,
          );
          final codEmpleado = empleadoRegistrado.codEmpleado;

          // 3. Registrar Cargos (Obligatorio)
          final areaCargoList = ref.read(tempRegistroFuncionesListProvider);
          final relacionPrimera =
              ref.read(tempRelacionLaboralListProvider).firstOrNull;
          final fechaInicioCargo = relacionPrimera?.fechaIni ?? DateTime.now();

          for (var area in areaCargoList) {
            // Asegurar que cargoSucursal sea una Entity
            final cargoSucEntity =
                area['cargoSucursal'] is CargoSucursalEntity
                    ? area['cargoSucursal'] as CargoSucursalEntity
                    : (area['cargoSucursal'] is Map
                        ? CargoSucursalModel.fromJson(
                          Map<String, dynamic>.from(
                            area['cargoSucursal'] as Map,
                          ),
                        ).toEntity()
                        : null);

            final cargEntity = EmpleadoCargoEntity(
              codCargoSucursal: (area['codCargoSucursal'] as int?) ?? 0,
              codCargoSucPlanilla: (area['codCargoSucPlanilla'] as int?) ?? 0,
              fechaInicio: fechaInicioCargo,
              cargoPlanilla: (area['cargoPlanilla'] as String?) ?? '',
              audUsuario: codUsuario,
              codEmpleado: codEmpleado,
              existe: 0,
              cargoSucursal: cargoSucEntity,
            );
            await ref.read(registrarEmpleadoCargoProvider(cargEntity).future);
          }

          // 4. Registrar Relación Laboral (Obligatorio) + Obtener codRelEmplEmpr
          debugPrint('➡️ [4] Iniciando registro de Relaciones Laborales...');
          final relaciones = ref.read(tempRelacionLaboralListProvider);
          debugPrint(
            '📋 [4] Total de relaciones a registrar: ${relaciones.length}',
          );

          int codRelEmplEmpr = 0;

          for (var i = 0; i < relaciones.length; i++) {
            final rel = relaciones[i];
            debugPrint('➡️ [4.${i + 1}] Registrando Relación Laboral');

            try {
              // Registrar la relación
              await ref.read(
                registrarRelacionLaboral(
                  rel.copyWith(
                    codEmpleado: codEmpleado,
                    audUsuario: codUsuario,
                  ),
                ).future,
              );
              debugPrint('✅ [4.${i + 1}] Relación registrada correctamente');

              // Esperar un poco para que se procese en BD
              await Future.delayed(const Duration(milliseconds: 500));

              // Invalidar y obtener el codRelEmplEmpr
              ref.invalidate(obtenerUltimaRelacionLaboralProvider(codEmpleado));

              try {
                final ultimaRelacion = await ref.read(
                  obtenerUltimaRelacionLaboralProvider(codEmpleado).future,
                );
                codRelEmplEmpr = ultimaRelacion.codRelEmplEmpr;
                debugPrint(
                  '✅ [4.${i + 1}] codRelEmplEmpr obtenido: $codRelEmplEmpr',
                );
              } catch (eInner) {
                debugPrint(
                  '⚠️ [4.${i + 1}] Error al obtener codRelEmplEmpr: $eInner',
                );
              }
            } catch (e) {
              debugPrint('❌ [4.${i + 1}] Error registrando relación: $e');
            }
          }

          // 4.2 Actualizar Empleado con codRelEmplEmpr si se obtuvo
          if (codRelEmplEmpr > 0) {
            debugPrint(
              '➡️ [4.2] Actualizando Empleado con codRelEmplEmpr=$codRelEmplEmpr',
            );
            try {
              final empleadoActualizado = empleadoEntity.copyWith(
                codEmpleado: codEmpleado,
                codRelBeneficios: codRelEmplEmpr,
                codRelPlanilla: codRelEmplEmpr,
              );
              await ref.read(
                registrarEmpleadoProvider(empleadoActualizado).future,
              );
              debugPrint(
                '✅ [4.2] Empleado actualizado correctamente con codRelEmplEmpr=$codRelEmplEmpr',
              );
            } catch (e) {
              debugPrint('❌ [4.2] Error actualizando empleado: $e');
            }
          } else {
            debugPrint(
              '⚠️ [4.2] codRelEmplEmpr no se obtuvo (=0), no se actualiza empleado',
            );
          }

          // 5. Registrar Educación (Obligatorio)
          debugPrint('➡️ [5] Iniciando registro de Educación...');

          // 5. Registrar Educación (Obligatorio)
          final educaciones = ref.read(tempEducacionListProvider);
          for (var edu in educaciones) {
            await ref.read(
              registrarEducacionProvider(
                edu.copyWith(codEmpleado: codEmpleado, audUsuario: codUsuario),
              ).future,
            );
          }

          // 6. Registros Opcionales (Solo si existen en los providers)

          // Cuentas Bancarias (NroCuentaBancariaEntity NO tiene .copyWith())
          final cuentas = ref.read(tempCuentasBancariasProvider);
          for (var cuenta in cuentas) {
            final cuentaEntity = NroCuentaBancariaEntity(
              codCuenta: cuenta.codCuenta,
              codEmpleado: codEmpleado,
              codBanco: cuenta.codBanco,
              nroCuentaBancaria: cuenta.nroCuentaBancaria,
              estado: cuenta.estado,
              audUsuarioI: codUsuario,
            );
            await ref.read(registroCuentaBancaria(cuentaEntity).future);
          }

          // Formación
          final formaciones = ref.read(tempFormacionListProvider);
          for (var frm in formaciones) {
            await ref.read(
              registrarFormacionProvider(
                frm.copyWith(codEmpleado: codEmpleado, audUsuario: codUsuario),
              ).future,
            );
          }

          // Experiencia
          final experiencias = ref.read(tempExperienciaListProvider);
          for (var exp in experiencias) {
            await ref.read(
              registrarExperienciaLaboralProvider(
                exp.copyWith(codEmpleado: codEmpleado, audUsuario: codUsuario),
              ).future,
            );
          }

          // Teléfonos y Emails (vinculados a codPersona)
          final telefonos = ref.read(tempTelefonoListProvider);
          for (var tel in telefonos) {
            await ref.read(
              registrarTelefonoProvider(
                tel.copyWith(codPersona: codPersona, audUsuario: codUsuario),
              ).future,
            );
          }
          final emails = ref.read(tempEmailListProvider);
          for (var mail in emails) {
            await ref.read(
              registrarEmailProvider(
                mail.copyWith(codPersona: codPersona, audUsuario: codUsuario),
              ).future,
            );
          }

          // No se retorna 'true' aquí, ya que executeABM espera Future<void>
        },
      );

      if (exito && mounted) {
        _limpiarProvidersTemporales();
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _saveProgressToLocal();
    }
  }

  void _showErrorSnackBar(String message) {
    setState(() => _errorMessage = message);
    // Auto-ocultar después de 4 segundos
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _errorMessage = null);
      }
    });
  }
}
