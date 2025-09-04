/*import 'package:billing/application/auth/local_storage_service.dart';
import 'package:billing/application/lista-ficha-trabajador/empleado_dependientes_service.dart';
import 'package:billing/domain/listar-ficha-trabajador/ciudad.dart';
import 'package:billing/domain/listar-ficha-trabajador/empleado.dart';
import 'package:billing/domain/listar-ficha-trabajador/estCivil.dart';
import 'package:billing/domain/listar-ficha-trabajador/genero.dart';
import 'package:billing/domain/listar-ficha-trabajador/parentesco.dart';
import 'package:billing/domain/listar-ficha-trabajador/ciExpedido.dart';
import 'package:billing/domain/listar-ficha-trabajador/tipoTelefono.dart';

import 'package:billing/utils/validators.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

class DependienteScreen extends StatefulWidget {
  final int codEmpleado;
  const DependienteScreen({Key? key, required this.codEmpleado})
      : super(key: key);

  @override
  State<DependienteScreen> createState() => _DependienteScreenState();
}

class _DependienteScreenState extends State<DependienteScreen> {
  final TextEditingController _telefonoNuevoController =
      TextEditingController();

  final GlobalKey<FormState> _formTelefonoNuevoKey = GlobalKey<FormState>();
  List<TipoTelefono> listTipoTelefono = [];
  int? _tipoTelSeleccionado;

  List<Telefono> _telefonos = [];
  bool _isEditingTelefono = false;
  Telefono? _telefonoSeleccionado;

  bool _habilitarEdicion = false;
  bool _permisosVerificados = false;
  late final ObtenerEmpDepService _service;
  late int _codEmpleado;
  final LocalStorageService _localStorageService = LocalStorageService();

  //mostrar operaciones seleccionadas por seccion
  Map<String, String?> selectedOperation = {
    'dependiente': null,
  };

  Persona? _persona;
  List<Dependiente> _dependientes = [];
  List<Parentesco> _parentescos = [];
  List<CiExpedido> listCiExpedido = [];
  List<EstCivil> listEstCivil = [];
  List<Pais> listPaises = [];
  List<Ciudades> listCiudades = [];
  List<Zona> listZonas = [];
  List<Sexos> listGeneros = [];

  Map<int, Persona?> personasEdit = {};
  List<bool> _editingStates = [];
  String _datoPersona = '';
  bool _isLoading = true;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  final Map<int, Map<String, TextEditingController>> _controllers = {};

  // Selecciones para los dropdowns
  String? _ciExpedidoSeleccionado;
  String? _estadoCivilSeleccionado;
  int? _nacionalidadSeleccionado;
  int? _zonaSeleccionado;
  String? _generoSeleccionado;
  String? _parentescoSeleccionado;
  String? _esActivoSeleccionado;

// controlador de mapa
  final Map<int, MapController> _mapControllers = {};

  @override
  void initState() {
    super.initState();
    _codEmpleado = widget.codEmpleado;
    _service = ObtenerEmpDepService();
    _verificarPermisosEdicion();
    _initAllLoad();
  }

  Future<void> _initAllLoad() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await Future.wait([
        _cargarDatosEmpleado(),
        _cargarDependientes(),
        _cargarParentescos(),
        _cargarCiExpedido(),
        _cargarEstadoCivil(),
        _cargarPaises(),
        _cargarZonas(),
        _cargarGenero(),
        _cargarTelefonos(),
        _cargarTipoTelefono(),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar datos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarDatosEmpleado() async {
    final empleados = await _service.obtenerListaEmpleadoyDependientes();
    final empleado = empleados.firstWhere(
      (e) => e.codEmpleado == _codEmpleado,
      orElse: () => throw Exception("Empleado no encontrado"),
    );
    setState(() {
      _datoPersona = empleado.persona?.datoPersona ?? "Nombre desconocido";
    });
  }

  Future<void> _cargarDependientes() async {
    final dependientes = await _service.getDependientes(_codEmpleado);
    setState(() {
      _dependientes = dependientes;
      _editingStates = List.filled(dependientes.length, false);
    });
  }

  Future<void> _cargarParentescos() async {
    try {
      _parentescos = await ObtenerEmpDepService().obtenerParentesco();
    } catch (e) {}
  }

  Future<void> _cargarCiExpedido() async {
    try {
      listCiExpedido = await ObtenerEmpDepService().obtenerCiExp();
      setState(() {});
    } catch (e) {}
  }

  Future<void> _cargarEstadoCivil() async {
    try {
      listEstCivil = await ObtenerEmpDepService().obtenerEstadoCivil();
      setState(() {});
    } catch (e) {}
  }

  Future<void> _cargarPaises() async {
    try {
      listPaises = await ObtenerEmpDepService().obtenerPais();
      setState(() {});
    } catch (e) {}
  }

  Future<void> _cargarZonas({bool todas = false}) async {
    try {
      if (todas) {
        listZonas = await ObtenerEmpDepService().obtenerZona(0);
      } else if (_persona?.ciudad?.codCiudad != null) {
        listZonas = await ObtenerEmpDepService()
            .obtenerZona(_persona!.ciudad!.codCiudad!);
      } else {
        listZonas = [];
      }
      setState(() {});
    } catch (e) {}
  }

  Future<void> _cargarGenero() async {
    try {
      listGeneros = await ObtenerEmpDepService().obtenerGenero();
      setState(() {});
    } catch (e) {}
  }

  Future<void> _cargarTelefonos() async {
    try {
      final telefonos =
          await ObtenerEmpDepService().obtenerTelefono(_persona!.codPersona!);
      setState(() {
        _telefonos = telefonos;
      });
    } catch (e) {
      print('Error al cargar teléfonos: $e');
    }
  }

  void _initControllers(int index, Persona persona) {
    _controllers[index] ??= {};
    _controllers[index]!['nombres'] =
        TextEditingController(text: persona.nombres ?? '');
    _controllers[index]!['apPaterno'] =
        TextEditingController(text: persona.apPaterno ?? '');
    _controllers[index]!['apMaterno'] =
        TextEditingController(text: persona.apMaterno ?? '');
    _controllers[index]!['direccion'] =
        TextEditingController(text: persona.direccion ?? '');
    _controllers[index]!['ciNumero'] =
        TextEditingController(text: persona.ciNumero ?? '');
    _controllers[index]!['lugarNacimiento'] =
        TextEditingController(text: persona.lugarNacimiento ?? '');
    _controllers[index]!['nacionalidad'] =
        TextEditingController(text: persona.nacionalidad?.toString() ?? '');
    _controllers[index]!['sexo'] =
        TextEditingController(text: persona.sexo ?? '');
    _controllers[index]!['audUsuarioI'] =
        TextEditingController(text: persona.audUsuarioI?.toString() ?? '');
    _controllers[index]!['codZona'] =
        TextEditingController(text: persona.codZona?.toString() ?? '');
    _controllers[index]!['fechaNacimiento'] = TextEditingController(
      text: persona.fechaNacimiento != null
          ? DateFormat('dd-MM-yyyy').format(persona.fechaNacimiento!)
          : '',
    );
    _controllers[index]!['ciFechaVencimiento'] = TextEditingController(
      text: persona.ciFechaVencimiento != null
          ? DateFormat('dd-MM-yyyy').format(persona.ciFechaVencimiento!)
          : '',
    );
    _controllers[index]!['lat'] =
        TextEditingController(text: persona.lat?.toString() ?? '');
    _controllers[index]!['lng'] =
        TextEditingController(text: persona.lng?.toString() ?? '');
  }

  // --- PERMISOS DE EDICIÓN ---
  Future<void> _verificarPermisosEdicion() async {
    try {
      final int? codEmpleadoLocal = await _localStorageService.getCodEmpleado();
      bool habilitarEdicion = false;

      if (codEmpleadoLocal == null) {
        setState(() {
          _habilitarEdicion = false;
          _permisosVerificados = true;
        });
        return;
      }

      if (widget.codEmpleado == codEmpleadoLocal) {
        habilitarEdicion = true;
      }

      setState(() {
        _habilitarEdicion = habilitarEdicion;
        _permisosVerificados = true;
      });
    } catch (e) {
      setState(() {
        _habilitarEdicion = false;
        _permisosVerificados = true;
      });
    }
  }

  // --- FORMULARIO ---
  Widget _buildDependienteForm({
    required String title,
    required int index,
    required Dependiente dependiente,
    required Persona persona,
    required Future<void> Function() onSave,
    required VoidCallback onCancel,
  }) {
    _initControllers(index, persona);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _parentescos
                      .any((tipo) => tipo.codTipos == dependiente.parentesco)
                  ? dependiente.parentesco
                  : _parentescoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Parentesco',
                border: OutlineInputBorder(),
              ),
              items: _parentescos
                  .map((p) => DropdownMenuItem(
                        value: p.codTipos,
                        child: Text(p.nombre),
                      ))
                  .toList(),
              onChanged: (value) {
                dependiente.parentesco = value;
                _parentescoSeleccionado = value;
              },
              validator: (value) =>
                  validarDropdown(value, 'Seleccione parentesco'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: dependiente.esActivo ?? _esActivoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Activo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "SI", child: Text("SI")),
                DropdownMenuItem(value: "NO", child: Text("NO")),
              ],
              onChanged: (value) {
                dependiente.esActivo = value;
                _esActivoSeleccionado = value;
              },
              validator: (value) => validarDropdown(value, 'Seleccione estado'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controllers[index]!['nombres'],
              decoration: const InputDecoration(
                  labelText: 'NOMBRES', border: OutlineInputBorder()),
              validator: (value) =>
                  validarTextoOpcional(value, esObligatorio: true),
              inputFormatters: bloquearEspacios,
              // onChanged: (value) => persona.nombres = value,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controllers[index]!['apPaterno'],
              decoration: const InputDecoration(
                  labelText: 'APELLIDO PATERNO', border: OutlineInputBorder()),
              validator: (value) =>
                  validarTextoOpcional(value, esObligatorio: false),
              inputFormatters: bloquearEspacios,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controllers[index]!['apMaterno'],
              decoration: const InputDecoration(
                  labelText: 'APELLIDO MATERNO', border: OutlineInputBorder()),
              validator: (value) =>
                  validarTextoOpcional(value, esObligatorio: false),
              inputFormatters: bloquearEspacios,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: listCiExpedido
                      .any((tipo) => tipo.codTipos == persona.ciExpedido)
                  ? persona.ciExpedido
                  : _ciExpedidoSeleccionado,
              //persona.ciExpedido ?? (listCiExpedido.isNotEmpty ? listCiExpedido.first.codTipos : null),
              decoration: const InputDecoration(
                labelText: 'CI Expedido',
                border: OutlineInputBorder(),
              ),
              items: listCiExpedido
                  .map((tipo) => DropdownMenuItem(
                        value: tipo.codTipos,
                        child: Text(tipo.nombre),
                      ))
                  .toList(),
              onChanged: (value) {
                persona.ciExpedido = value;
                _ciExpedidoSeleccionado = value;
              },
              validator: (value) =>
                  validarDropdown(value, 'Seleccione Ci expedido'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controllers[index]!['ciFechaVencimiento'],
              decoration: const InputDecoration(
                  labelText: 'FECHA DE VENCIMIENTO C.I',
                  border: OutlineInputBorder()),
              validator: validarFecha,
              readOnly: true,
              onTap: () async {
                DateTime initialDate = DateTime.now();
                if (_controllers[index]!['ciFechaVencimiento']!
                    .text
                    .isNotEmpty) {
                  try {
                    initialDate = DateFormat('dd-MM-yyyy').parse(
                        _controllers[index]!['ciFechaVencimiento']!.text);
                  } catch (_) {}
                }
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  _controllers[index]!['ciFechaVencimiento']!.text =
                      DateFormat('dd-MM-yyyy').format(picked);
                  persona.ciFechaVencimiento = picked;
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controllers[index]!['direccion'],
              decoration: const InputDecoration(
                  labelText: 'DIRECCION', border: OutlineInputBorder()),
              validator: (value) =>
                  validarTextoMixto(value, esObligatorio: true),
              inputFormatters: bloquearEspacios,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controllers[index]!['ciNumero'],
              decoration: const InputDecoration(
                  labelText: 'NRO CARNET DE IDENTIDAD',
                  border: OutlineInputBorder()),
              validator: (value) =>
                  validarSoloNumeros(value, esObligatorio: true),
              inputFormatters: bloquearEspacios,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: listEstCivil
                      .any((tipo) => tipo.codTipos == persona.estadoCivil)
                  ? persona.estadoCivil
                  : _estadoCivilSeleccionado,
              // persona.estadoCivil ?? (listEstCivil.isNotEmpty ? listEstCivil.first.codTipos : null),
              decoration: const InputDecoration(
                labelText: 'ESTADO CIVIL',
                border: OutlineInputBorder(),
              ),
              items: listEstCivil
                  .map((tipo) => DropdownMenuItem(
                        value: tipo.codTipos,
                        child: Text(tipo.nombre),
                      ))
                  .toList(),
              onChanged: (value) {
                persona.estadoCivil = value;
                _estadoCivilSeleccionado = value;
              },
              validator: (value) =>
                  validarDropdown(value, 'Seleccione estado civil'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controllers[index]!['fechaNacimiento'],
              decoration: const InputDecoration(
                  labelText: 'Fecha de nacimiento',
                  border: OutlineInputBorder()),
              validator: validarFecha,
              readOnly: true,
              onTap: () async {
                DateTime initialDate = DateTime.now();
                if (_controllers[index]!['fechaNacimiento']!.text.isNotEmpty) {
                  try {
                    initialDate = DateFormat('dd-MM-yyyy')
                        .parse(_controllers[index]!['fechaNacimiento']!.text);
                  } catch (_) {}
                }
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  _controllers[index]!['fechaNacimiento']!.text =
                      DateFormat('dd-MM-yyyy').format(picked);
                  persona.fechaNacimiento = picked;
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controllers[index]!['lugarNacimiento'],
              decoration: const InputDecoration(
                  labelText: 'LUGAR DE NACIMIENTO',
                  border: OutlineInputBorder()),
              validator: (value) =>
                  validarTextoOpcional(value, esObligatorio: true),
              inputFormatters: bloquearEspacios,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value:
                  listPaises.any((pais) => pais.codPais == persona.nacionalidad)
                      ? persona.nacionalidad
                      : _nacionalidadSeleccionado,
              // persona.nacionalidad ?? (listPaises.isNotEmpty ? listPaises.first.codPais : null),
              decoration: const InputDecoration(
                labelText: 'NACIONALIDAD',
                border: OutlineInputBorder(),
              ),
              items: listPaises.map((Pais pais) {
                return DropdownMenuItem<int>(
                  value: pais.codPais,
                  child: Text(pais.pais.toString()),
                );
              }).toList(),
              onChanged: (value) {
                persona.nacionalidad = value;
                _nacionalidadSeleccionado = value;
              },
              validator: (value) =>
                  validarDropdown(value?.toString(), 'Seleccione nacionalidad'),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (BuildContext innerContext) {
                // Si la zona de la persona no está en la lista, agrégala temporalmente
                List<Zona> zonasDropdown = List.from(listZonas);
                final zonaActual = _zonaSeleccionado != null
                    ? listZonas.firstWhere(
                        (zona) => zona.codZona == _zonaSeleccionado,
                        orElse: () => Zona(codZona: 0, zona: ''),
                      )
                    : null;
                if (zonaActual != null &&
                    !zonasDropdown
                        .any((z) => z.codZona == zonaActual.codZona)) {
                  zonasDropdown.add(zonaActual);
                }
                return DropdownSearch<Zona>(
                  items: zonasDropdown,
                  itemAsString: (Zona? zona) => "${zona?.zona ?? ''}",
                  onChanged: (Zona? selectedZona) {
                    _zonaSeleccionado = selectedZona?.codZona;
                    _zonaSeleccionado = selectedZona?.codZona;
                  },
                  selectedItem: zonaActual,
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Buscar Zona",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  validator: validarSeleccionDropdownSearch,
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        labelText: "Buscar por nombre",
                        border: OutlineInputBorder(),
                      ),
                      inputFormatters: bloquearEspacios,
                    ),
                    emptyBuilder: (context, searchEntry) => const Center(
                      child: Text("No se encontraron resultados"),
                    ),
                    title: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Seleccionar zona",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: listGeneros.any((tipo) => tipo.codTipos == persona.sexo)
                  ? persona.sexo
                  : _generoSeleccionado,
              // persona.sexo ?? (listGeneros.isNotEmpty ? listGeneros.first.codTipos : null),
              decoration: const InputDecoration(
                labelText: 'GENERO',
                border: OutlineInputBorder(),
              ),
              items: listGeneros
                  .map((tipo) => DropdownMenuItem(
                        value: tipo.codTipos,
                        child: Text(tipo.nombre ?? ''),
                      ))
                  .toList(),
              onChanged: (value) {
                persona.sexo = value;
                _generoSeleccionado = value;
              },
              validator: (value) =>
                  validarDropdown(value, 'Seleccione género '),
            ),
            const SizedBox(height: 16),
            _buildMapSection(index, persona),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: onSave,
                  child: const Text('Guardar'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- AGREGAR NUEVO DEPENDIENTE ---
  void _mostrarDialogoAgregarDependiente() async {
    // Carga catálogos si es necesario
    await Future.wait([
      _cargarParentescos(),
      _cargarCiExpedido(),
      _cargarEstadoCivil(),
      _cargarPaises(),
      _cargarZonas(todas: true),
      _cargarGenero(),
    ]);

    final nuevoDependiente = Dependiente(
      parentesco: null,
      esActivo: null,
    );
    final nuevaPersona = Persona(
      nacionalidad: null,
      sexo: null,
      estadoCivil: null,
      ciExpedido: null,
      codZona: null,
    );
    const int nuevoIndex = -1;

    _controllers[nuevoIndex] = {
      'nombres': TextEditingController(),
      'apPaterno': TextEditingController(),
      'apMaterno': TextEditingController(),
      'direccion': TextEditingController(),
      'ciNumero': TextEditingController(),
      'lugarNacimiento': TextEditingController(),
      'nacionalidad': TextEditingController(),
      'sexo': TextEditingController(),
      'audUsuarioI': TextEditingController(),
      'codZona': TextEditingController(),
      'fechaNacimiento': TextEditingController(),
      'ciFechaVencimiento': TextEditingController(),
      'lat': TextEditingController(),
      'lng': TextEditingController(),
    };
    limpiarFormularioNuevoDependiente(nuevoIndex);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: _buildDependienteForm(
          title: 'AGREGAR DEPENDIENTE',
          index: nuevoIndex,
          dependiente: nuevoDependiente,
          persona: nuevaPersona,
          onSave: () async {
            final guardado = await _guardarNuevoDependiente(
                nuevoDependiente, nuevaPersona, nuevoIndex);
            if (guardado) {
              Navigator.pop(context);
            }
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // --- MAPA ---
  Widget _buildMapSection(int index, Persona? persona) {
    // Si no existen los controladores de lat/lng, inicialízalos
    _controllers[index] ??= {};
    _controllers[index]!['lat'] ??= TextEditingController(
      text: persona?.lat?.toString() ?? '',
    );
    _controllers[index]!['lng'] ??= TextEditingController(
      text: persona?.lng?.toString() ?? '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ubicación', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              final lat =
                  double.tryParse(_controllers[index]!['lat']?.text ?? '') ??
                      -16.5;
              final lng =
                  double.tryParse(_controllers[index]!['lng']?.text ?? '') ??
                      -68.1;

              return FlutterMap(
                options: MapOptions(
                  center: LatLng(lat, lng),
                  zoom: 13.0,
                  onTap: (tapPosition, point) {
                    setState(() {
                      // Actualiza controladores
                      _controllers[index]!['lat']!.text =
                          point.latitude.toString();
                      _controllers[index]!['lng']!.text =
                          point.longitude.toString();
                      // Actualiza el objeto persona si existe
                      if (persona != null) {
                        persona.lat = point.latitude;
                        persona.lng = point.longitude;
                      }
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        key: UniqueKey(),
                        width: 40.0,
                        height: 40.0,
                        point: LatLng(lat, lng),
                        builder: (ctx) {
                          return const Icon(Icons.location_pin,
                              color: Colors.red);
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // --- GUARDAR DATOS ---
  Future<void> _guardarDatosPersona(int index, Persona persona) async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final dependiente = _dependientes[index];
        final dependienteActualizado = Dependiente(
          codDependiente: dependiente.codDependiente,
          codEmpleado: _codEmpleado,
          codPersona: dependiente.codPersona,
          parentesco: _parentescoSeleccionado ?? dependiente.parentesco,
          esActivo: _esActivoSeleccionado ?? dependiente.esActivo,
          audUsuario: await _localStorageService.getCodUsuario(),
        );

        await ObtenerEmpDepService().editarDep(dependienteActualizado);

        final String ciExpedidoAEnviar =
            _ciExpedidoSeleccionado ?? persona.ciExpedido ?? '';
        final String estadoCivilAEnviar =
            _estadoCivilSeleccionado ?? persona.estadoCivil ?? '';
        final int? nacionalidadAEnviar =
            _nacionalidadSeleccionado ?? persona.nacionalidad;
        final String? sexoAEnviar = _generoSeleccionado ?? persona.sexo;
        final int zonaAEnviar = _zonaSeleccionado ?? persona.codZona ?? 0;

        final dependienteEditado = Persona(
          codPersona: persona.codPersona,
          codZona: zonaAEnviar,
          nombres: _controllers[index]!['nombres']?.text.trim(),
          apPaterno: _controllers[index]!['apPaterno']?.text.trim(),
          apMaterno: _controllers[index]!['apMaterno']?.text.trim(),
          ciExpedido: ciExpedidoAEnviar,
          ciFechaVencimiento: DateFormat('dd-MM-yyyy')
              .parse(_controllers[index]!['ciFechaVencimiento']!.text.trim()),
          ciNumero: _controllers[index]!['ciNumero']?.text.trim(),
          direccion: _controllers[index]!['direccion']?.text.trim(),
          estadoCivil: estadoCivilAEnviar,
          fechaNacimiento: DateFormat('dd-MM-yyyy')
              .parse(_controllers[index]!['fechaNacimiento']!.text.trim()),
          lugarNacimiento: _controllers[index]!['lugarNacimiento']?.text.trim(),
          nacionalidad: nacionalidadAEnviar,
          sexo: sexoAEnviar,
          lat: double.tryParse(_controllers[index]!['lat']?.text.trim() ?? ''),
          lng: double.tryParse(_controllers[index]!['lng']?.text.trim() ?? ''),
          audUsuarioI: await _localStorageService.getCodUsuario(),
        );
        await ObtenerEmpDepService().editarPersona(dependienteEditado);
        final personaActualizada =
            await ObtenerEmpDepService().obtenerPersona(persona.codPersona!);

        setState(() {
          personasEdit[index] = personaActualizada;
          _dependientes[index] = dependienteActualizado;
          _isLoading = false;
          _editingStates[index] = false;
        });
        await _cargarDependientes();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos guardados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar los datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _guardarNuevoDependiente(
      Dependiente dependiente, Persona persona, int index) async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final ctrl = _controllers[index]!;

        final nuevaPersona = Persona(
          nombres: ctrl['nombres']?.text.trim(),
          apPaterno: ctrl['apPaterno']?.text.trim(),
          apMaterno: ctrl['apMaterno']?.text.trim(),
          direccion: ctrl['direccion']?.text.trim(),
          ciNumero: ctrl['ciNumero']?.text.trim(),
          lugarNacimiento: ctrl['lugarNacimiento']?.text.trim(),
          nacionalidad: _nacionalidadSeleccionado,
          sexo: _generoSeleccionado,
          fechaNacimiento: ctrl['fechaNacimiento']!.text.isNotEmpty
              ? DateFormat('dd-MM-yyyy')
                  .parse(ctrl['fechaNacimiento']!.text.trim())
              : null,
          estadoCivil: _estadoCivilSeleccionado,
          ciExpedido: _ciExpedidoSeleccionado,
          ciFechaVencimiento: ctrl['ciFechaVencimiento']!.text.isNotEmpty
              ? DateFormat('dd-MM-yyyy')
                  .parse(ctrl['ciFechaVencimiento']!.text.trim())
              : null,
          codZona: _zonaSeleccionado,
          lat: double.tryParse(ctrl['lat']?.text ?? ''),
          lng: double.tryParse(ctrl['lng']?.text ?? ''),
          audUsuarioI: await _localStorageService.getCodUsuario(),
        );

        final personaRegistrada =
            await ObtenerEmpDepService().registrarPersona(nuevaPersona);

        final String parentescoAEnviar =
            _parentescoSeleccionado ?? dependiente.parentesco;
        final String esActivoAEnviar =
            _esActivoSeleccionado ?? dependiente.esActivo;
        final nuevoDependiente = Dependiente(
          codEmpleado: _codEmpleado,
          codPersona: personaRegistrada.codPersona,
          parentesco: parentescoAEnviar,
          esActivo: esActivoAEnviar,
        );

        await ObtenerEmpDepService().editarDep(nuevoDependiente);

        await _cargarDependientes();

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dependiente agregado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar dependiente: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_permisosVerificados) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Dependientes de: $_datoPersona'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cerrar", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _dependientes.isEmpty
                  ? const Center(
                      child: Text("El empleado no tiene dependientes"))
                  : Column(
                      children: [
                        // --- SpeedDial arriba de la lista ---
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: buildSpeedDial(
                              nombreSeccion: 'dependiente',
                              onAgregar: _mostrarDialogoAgregarDependiente,
                              updateOperation: (String? op) {
                                setState(() {
                                  selectedOperation['dependiente'] = op;
                                });
                              },
                              operacionHabilitada: _dependientes.isEmpty
                                  ? ['agregar']
                                  : ['agregar', 'editar', 'eliminar'],
                            ),
                          ),
                        ),
                        // --- Lista de dependientes ---
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            itemCount: _dependientes.length,
                            itemBuilder: (context, index) {
                              final dependiente = _dependientes[index];
                              if (!_editingStates[index]) {
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  elevation: 2,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(8),
                                    title: Text(
                                        "Nombre: ${dependiente.nombreCompleto ?? ""}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: dependiente.codEmpleado != 0
                                        ? const Text("Es empleado")
                                        : const Text("No es empleado"),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Botón de ver información siempre visible
                                        // En el IconButton de visibilidad
                                        IconButton(
                                          icon: const Icon(Icons.visibility),
                                          onPressed: () async {
                                            try {
                                              // Primero obtenemos los datos de la persona
                                              final personaData =
                                                  await _service.obtenerPersona(
                                                      dependiente.codPersona!);
                                              // Luego cargamos los teléfonos
                                              final telefonos =
                                                  await ObtenerEmpDepService()
                                                      .obtenerTelefono(
                                                          dependiente
                                                              .codPersona!);

                                              setState(() {
                                                personasEdit[index] =
                                                    personaData;
                                                _telefonos = telefonos;
                                                _persona = personaData;
                                              });

                                              // Mostramos el diálogo solo después de cargar los datos
                                              showDialog(
                                                context: context,
                                                builder: (context) => Dialog(
                                                  child: StatefulBuilder(
                                                    builder: (context,
                                                            setStateDialog) =>
                                                        SingleChildScrollView(
                                                      child:
                                                          _buildDependienteInfo(
                                                        dependiente,
                                                        personaData,
                                                        setStateDialog, // <-- pásalo aquí
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              print(
                                                  'Error al cargar datos: $e');
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Error al cargar los datos: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                        // Botones de edición y eliminación condicionados por _habilitarEdicion
                                        if (_habilitarEdicion &&
                                            selectedOperation['dependiente'] ==
                                                'editar')
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Colors.teal),
                                            onPressed: () async {
                                              if (personasEdit[index] == null) {
                                                try {
                                                  final persona = await _service
                                                      .obtenerPersona(
                                                          dependiente
                                                              .codPersona!);
                                                  setState(() {
                                                    personasEdit[index] =
                                                        persona;
                                                  });
                                                } catch (error) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            "Error al cargar datos de la persona: $error")),
                                                  );
                                                  return;
                                                }
                                              }
                                              await _cargarZonas(todas: true);
                                              setState(() {
                                                _zonaSeleccionado =
                                                    personasEdit[index]
                                                        ?.codZona;
                                                _nacionalidadSeleccionado =
                                                    personasEdit[index]
                                                        ?.nacionalidad;
                                                _generoSeleccionado =
                                                    personasEdit[index]?.sexo;
                                                _estadoCivilSeleccionado =
                                                    personasEdit[index]
                                                        ?.estadoCivil;
                                                _ciExpedidoSeleccionado =
                                                    personasEdit[index]
                                                        ?.ciExpedido;
                                                _parentescoSeleccionado =
                                                    dependiente.parentesco;
                                                _editingStates[index] = true;
                                              });
                                            },
                                          ),
                                        if (_habilitarEdicion &&
                                            selectedOperation['dependiente'] ==
                                                'eliminar')
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () async {
                                              final eliminado =
                                                  await eliminarDependiente(
                                                      dependiente
                                                          .codDependiente!);
                                              if (eliminado) {
                                                setState(() {
                                                  _dependientes.removeWhere(
                                                      (d) =>
                                                          d.codDependiente ==
                                                          dependiente
                                                              .codDependiente);
                                                });
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Dependiente eliminado correctamente.'),
                                                      backgroundColor:
                                                          Colors.green),
                                                );
                                              }
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                return _buildDependienteForm(
                                  title: 'EDITAR DEPENDIENTE',
                                  index: index,
                                  dependiente: dependiente,
                                  persona: personasEdit[index]!,
                                  onSave: () async {
                                    await _guardarDatosPersona(
                                        index, personasEdit[index]!);
                                  },
                                  onCancel: () {
                                    setState(() {
                                      _editingStates[index] = false;
                                    });
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  //ELIMINAR DEPENDIENTE
  Future<bool> eliminarDependiente(int codDependiente) async {
    // 🔹 Validar que el ID es válido antes de enviar la solicitud
    if (codDependiente <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Código de dependiente inválido.')),
      );
      return false;
    }

    final bool resultado =
        await ObtenerEmpDepService().eliminarDependiente(codDependiente);

    if (resultado) {
      try {
        setState(() {
          _dependientes.removeWhere((d) => d.codDependiente == codDependiente);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '✅ Dependiente eliminado correctamente: $codDependiente'),
              backgroundColor: Colors.green),
        );
      } catch (e) {
   
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar la lista: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return true;
    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '❌ Error al eliminar el dependiente. Código: $codDependiente'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  void limpiarFormularioNuevoDependiente(int index) {
    _controllers[index]?['nombres']?.clear();
    _controllers[index]?['apPaterno']?.clear();
    _controllers[index]?['apMaterno']?.clear();
    _controllers[index]?['direccion']?.clear();
    _controllers[index]?['ciNumero']?.clear();
    _controllers[index]?['lugarNacimiento']?.clear();
    _controllers[index]?['nacionalidad']?.clear();
    _controllers[index]?['sexo']?.clear();
    _controllers[index]?['audUsuarioI']?.clear();
    _controllers[index]?['codZona']?.clear();
    _controllers[index]?['fechaNacimiento']?.clear();
    _controllers[index]?['ciFechaVencimiento']?.clear();

    // Limpia también los valores seleccionados de los dropdowns si es necesario:
    _ciExpedidoSeleccionado = null;
    _estadoCivilSeleccionado = null;
    _nacionalidadSeleccionado = null;
    _zonaSeleccionado = null;
    _generoSeleccionado = null;
    _esActivoSeleccionado = null;
    _parentescoSeleccionado = null;
  }

  Widget _buildDependienteInfo(
    Dependiente dependiente,
    Persona persona,
    void Function(VoidCallback) setStateDialog,
  ) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Teléfonos',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                buildSpeedDial(
                  nombreSeccion: 'telefono',
                  onAgregar: () =>
                      _mostrarDialogoAgregarTelefono(setStateDialog),

                  /*onAgregar: _telefonos.length < 3
                    ? () => _mostrarDialogoAgregarTelefono(setStateDialog)
                    : null,*/
                  updateOperation: (String? op) {
                    setStateDialog(() {
                      selectedOperation['telefono'] = op;
                    });
                  },
                  operacionHabilitada: [
                    'agregar',
                    //if (_telefonos.length < 3) 'agregar',
                    if (_telefonos.isNotEmpty) 'editar',
                    if (_telefonos.isNotEmpty) 'eliminar',
                  ],
                ),
              ],
            ),
            Divider(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _telefonos.isEmpty
                  ? [const Text('No hay teléfonos registrados')]
                  : _telefonos
                      .map((telefono) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.phone),
                                const SizedBox(width: 8),
                                Text('${telefono.telefono} (${telefono.tipo})'),
                                if (_habilitarEdicion &&
                                    selectedOperation['telefono'] == 'editar')
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () =>
                                        _mostrarDialogoEditarTelefono(
                                            telefono, setStateDialog),
                                  ),
                                if (_habilitarEdicion &&
                                    selectedOperation['telefono'] == 'eliminar')
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _mostrarDialogoEliminarTelefono(
                                            telefono, setStateDialog),
                                  ),
                              ],
                            ),
                          ))
                      .toList(),
            ),
            SizedBox(height: 16),
            // Mapa de ubicación
            Container(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(
                    persona.lat ?? -16.5,
                    persona.lng ?? -68.1,
                  ),
                  zoom: 13.0,
                  interactiveFlags: InteractiveFlag.all, // Mapa no interactivo
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point:
                            LatLng(persona.lat ?? -16.5, persona.lng ?? -68.1),
                        builder: (ctx) =>
                            Icon(Icons.location_pin, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Agregar teléfono
  void _mostrarDialogoAgregarTelefono(
      void Function(VoidCallback) setStateDialog) {
    _limpiarFormularioTelefono();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Teléfono'),
          content: SingleChildScrollView(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (KeyEvent event) async {
                if (kIsWeb &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    event is! KeyUpEvent) {
                  final guardado = await _guardarNuevoTelefono();
                  if (guardado) {
                    await _cargarTelefonos();
                    setStateDialog(() {});
                    Navigator.pop(context);
                  }
                }
              },
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _telefonoNuevoController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Teléfono',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          validarSoloNumeros(value, esObligatorio: true),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: listTipoTelefono.any((tipo) =>
                              tipo.codTipoTel ==
                              _telefonoSeleccionado?.codTipoTel)
                          ? _telefonoSeleccionado?.codTipoTel
                          : _tipoTelSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Teléfono',
                        border: OutlineInputBorder(),
                      ),
                      items: listTipoTelefono
                          .map((tipo) => DropdownMenuItem<int>(
                                value: tipo.codTipoTel,
                                child: Text(tipo.tipo),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _tipoTelSeleccionado = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Seleccione un tipo de teléfono';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final guardado = await _guardarNuevoTelefono();
                if (guardado) {
                  await _cargarTelefonos();
                  setStateDialog(() {});
                  Navigator.pop(context);
                }
                // Si no se guardó, el formulario permanece abierto
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _limpiarFormularioTelefono() {
    _formTelefonoNuevoKey.currentState?.reset();
    _telefonoNuevoController.clear();
    _tipoTelSeleccionado = null;
    setState(() {});
  }

  Future<void> _cargarTipoTelefono() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final tipotelf = await ObtenerEmpDepService().obtenerTipoTelefono();
      setState(() {
        listTipoTelefono = tipotelf;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los datos del TipoTelefono: $e';
        _isLoading = false;
      });
    }
  }

  Future<bool> _guardarNuevoTelefono() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      // Si hay errores de validación, no continúa
      return false;
    }
    // Limite de 3 teléfonos
    /* if (_telefonos.length >= 3) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Solo se pueden registrar hasta 3 teléfonos.'),
        backgroundColor: Colors.orange,
      ),
    );
    return false;
  }*/
    if (!(_formKey.currentState?.validate() ?? false)) {
      // Si hay errores de validación, no continúa
      return false;
    }

    final nuevoTelefono = Telefono(
      codTelefono: 0, // Para indicar que es una nueva inserción
      codPersona: _persona?.codPersona, // Usar el codPersona actual
      codTipoTel:
          _tipoTelSeleccionado, // Convertir el tipo seleccionado a su código
      telefono: _telefonoNuevoController.text.trim(),
      audUsuario: await _localStorageService.getCodUsuario(),
    );

    try {
      await ObtenerEmpDepService().registrarTelefono(nuevoTelefono);
      final telefonoActualizado = await ObtenerEmpDepService().obtenerTelefono(
          _persona!.codPersona!); // Refrescar la lista de teléfonos
      setState(() {
        //_telefonos.add(telefonoRegistrado ?? nuevoTelefono);
        _telefonos = telefonoActualizado; // Actualizar la lista de teléfonos
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teléfono agregado correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
      return true; // Indica que se guardó correctamente
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar el teléfono: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false; // Indica que hubo un error al guardar
    }
  }

  void _mostrarDialogoEditarTelefono(
      Telefono telefono, void Function(VoidCallback) setStateDialog) {
    final TextEditingController telefonoController =
        TextEditingController(text: telefono.telefono);
    int? tipoSeleccionado = telefono.codTipoTel;
    final GlobalKey<FormState> _formEditTelefonoKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Teléfono'),
          content: SingleChildScrollView(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (kIsWeb &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    event is! KeyUpEvent) {
                  if (_formEditTelefonoKey.currentState?.validate() ?? false) {
                    _guardarTelefonoEditado(
                      telefonoOriginal: telefono,
                      nuevoNumero: telefonoController.text,
                      nuevoTipo: tipoSeleccionado,
                      setStateDialog: setStateDialog,
                      context: context,
                    );
                  }
                }
              },
              child: Form(
                key: _formEditTelefonoKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: telefonoController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Teléfono',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          validarSoloNumeros(value, esObligatorio: true),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: tipoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Teléfono',
                        border: OutlineInputBorder(),
                      ),
                      items: listTipoTelefono
                          .map((tipo) => DropdownMenuItem<int>(
                                value: tipo.codTipoTel,
                                child: Text(tipo.tipo),
                              ))
                          .toList(),
                      onChanged: (value) {
                        tipoSeleccionado = value;
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Seleccione un tipo de teléfono';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(_formEditTelefonoKey.currentState?.validate() ?? false)) {
                  return;
                }
                await _guardarTelefonoEditado(
                  telefonoOriginal: telefono,
                  nuevoNumero: telefonoController.text,
                  nuevoTipo: tipoSeleccionado,
                  setStateDialog: setStateDialog,
                  context: context,
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoEliminarTelefono(
      Telefono telefono, void Function(VoidCallback) setStateDialog) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Teléfono'),
        content:
            Text('¿Está seguro de eliminar el teléfono ${telefono.telefono}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ObtenerEmpDepService()
                    .eliminarTelefono(telefono.codTelefono!);
                await _cargarTelefonos();
                setStateDialog(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Teléfono eliminado correctamente.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar el teléfono: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

//guardartelefonoeditado
  Future<void> _guardarTelefonoEditado({
    required Telefono telefonoOriginal,
    required String nuevoNumero,
    required int? nuevoTipo,
    required void Function(VoidCallback) setStateDialog,
    required BuildContext context,
  }) async {
    try {
      final telefonoEditado = Telefono(
        codTelefono: telefonoOriginal.codTelefono,
        codPersona: telefonoOriginal.codPersona,
        codTipoTel: nuevoTipo,
        telefono: nuevoNumero.trim(),
        audUsuario: await _localStorageService.getCodUsuario(),
      );
      await ObtenerEmpDepService().registrarTelefono(telefonoEditado);
      await _cargarTelefonos();
      setStateDialog(() {});
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teléfono editado correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al editar el teléfono: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}*/
