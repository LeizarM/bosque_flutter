/*import 'package:billing/application/auth/local_storage_service.dart';
import 'package:billing/domain/listar-ficha-trabajador/TipoDuracion.dart';
import 'package:billing/domain/listar-ficha-trabajador/TipoFormacion.dart';
import 'package:billing/domain/listar-ficha-trabajador/ciudad.dart';

import 'package:billing/domain/listar-ficha-trabajador/ciExpedido.dart';
import 'package:billing/domain/listar-ficha-trabajador/estCivil.dart';
import 'package:billing/domain/listar-ficha-trabajador/genero.dart';
import 'package:billing/domain/listar-ficha-trabajador/tipoTelefono.dart';
import 'package:billing/domain/listar-ficha-trabajador/tipo_gar_ref.dart';
import 'package:billing/presentation/lista-ficha-trabajador/empleadoDep_screen.dart';
import 'package:billing/utils/image_picker_helper.dart';
import 'package:billing/utils/validators.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:billing/domain/listar-ficha-trabajador/empleado.dart';
import 'package:billing/application/lista-ficha-trabajador/empleado_dependientes_service.dart';

import 'dart:typed_data';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class InfoEmpleadoScreen extends StatefulWidget {
  final int codEmpleado;

  const InfoEmpleadoScreen({Key? key, required this.codEmpleado})
      : super(key: key);

  @override
  _InfoEmpleadoScreenState createState() => _InfoEmpleadoScreenState();
}

class _InfoEmpleadoScreenState extends State<InfoEmpleadoScreen> {
  int _imageTimestamp = DateTime.now().millisecondsSinceEpoch;
  List<TipoTelefono> listTipoTelefono = [];
  int? _tipoTelSeleccionado;
  bool _habilitarEdicion = false;
  Persona? _persona;
  //LISTA CI EXPEDIDO
  List<CiExpedido> listCiExpedido = [];
  String? _ciExpedidoSeleccionado;
  //LISTA ESTADO CIVIL
  List<EstCivil> listEstCivil = [];
  String? _estadoCivilSeleccionado;
  //LISTA PAIES
  List<Pais> listPaises = [];
  int? _nacionalidadSeleccionado;
  //LISTA CIUDADES
  List<Ciudades> listCiudades = [];
  Ciudad? _ciudad;
  int? _ciudadSeleccionado;
  //LISTA ZONAS
  List<Zona> listZonas = [];
  int? _zonaSeleccionado;
  //LISTA GENERO
  //List<Sexo> listSexo = [];
  String? _generoSeleccionado;
  //LISTA TIPO GARANTE
  List<TipoGarRef> listTipoGarRef = [];
  String? _tipoGarRefSeleccionado;
  GaranteReferencia? _garanteReferencia;

  //persona list
  List<Persona> listPersona = [];
  Persona? _personaSeleccionada;
  TextEditingController _searchController = TextEditingController();

  //garante referencia list
  List<GaranteReferencia> listGarRef = [];
  GaranteReferencia? _garanteSeleccionado;
  List<Empleado> _empleado = [];
  List<TipoDuracionFormacion> listTipoDuracionFor = [];
  Formaciones? _formacion;

  String? _tipoDuracionForSeleccionada;
  List<TipoFormacion> listTipoFormacion = [];
  String? _tipoFormacionSeleccionada;

//para controlar el despliegue de cada seccion
  Map<String, bool> estadoExpandido = {
    'empleado': true,
    'telefono': true,
    'correo': true,
    'formacion': true,
    'expLab': true,
    'garantes': true,
    'relacionLab': true,
  };

//mostrar operaciones seleccionadas por seccion
  Map<String, String?> selectedOperation = {
    'correo': null,
    'telefono': null,
    'expLaboral': null,
    'garantes': null,
    'formacion': null,
    'persona': null,
    'perGarante': null,
  };

  List<Sexos> listGeneros = [];
  List<Telefono> listTelefono = [];
  List<Email> listCorreo = [];
  List<Formaciones> listFormacion = [];
  List<ExperienciaLaboral> listExpLaboral = [];
  List<GaranteReferencia> listGaranteReferencia = [];
  List<RelEmpEmpr> listRelEmpEmpr = [];

  bool _isLoading = false;
  String? _errorMessage;

  bool _isEditing = false;
  bool _isEditingTelefono = false;
  Telefono? _telefonoSeleccionado;

  Email? _emailSeleccionado;
  bool _isEditingCorreo = false;

  bool _isEditingFormacion = false;
  Formaciones? _formacionSeleccionada;

  bool _isEditingExpLaboral = false;
  ExperienciaLaboral? _expLabSeleccionada;

  bool _isEditingGarRef = false;
  GaranteReferencia? _garanteRefSeleccionada;

  final _formKey = GlobalKey<FormState>();
  
  final Map<String, TextEditingController> controllers = {};

//formatear fecha
  String formatearFecha(DateTime fecha) {
    return DateFormat('dd-MM-yyyy').format(fecha); // Formato Día/Mes/Año
  }

  LocalStorageService _localStorageService = LocalStorageService();
  Uint8List? _imageBytes;

  @override
  void initState() {
    //print('entrando con codempleado: ${widget.codEmpleado}');
    super.initState();
    _verificarPermisosEdicion();
    _initialLoad();
    _inicializarControladores();
  }
Future<void> _initialLoad() async {
  if (!mounted) return;
  
  setState(() => _isLoading = true);

  try {
    // Primero cargar datos del empleado
    await _cargarDatosEmpleado();
    
    // Luego cargar el resto de datos que dependen de _persona
    if (_persona != null) {
      await Future.wait([
        _cargarDatosTelefono(),
        _cargarDatosCorreo(),
        _cargarDatosFormacion(),
         _cargarDatosTelefono(),
     _cargarDatosCorreo(),
     _cargarDatosFormacion(),
     _cargarDatosExpLaboral(),
     _cargarDatosGaranteReferencia(),
     _cargarDatosRelLaboral(),
     _cargarCiExpedido(),
     _cargarEstadoCivil(),
     _cargarGenero(),
     _cargarPaises(),
     _cargarCiudades(),
     _cargarZonas(),
     _cargarTipoDuracionFor(),
     _cargarTipoFormacion(),
     _cargarListaPersonas(),
     _cargarTipoGarRef(),
     _cargarListaGarRef(),
     _cargarTipoTelefono(),
      ]);
    }

  } catch (e) {
    print('Error en _initialLoad: $e');
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
  /*Future<void> _initialLoad() async {
    setState(() => _isLoading = true);
    await _cargarDatosEmpleado();
    await _cargarDatosTelefono();
    await _cargarDatosCorreo();
    await _cargarDatosFormacion();
    await _cargarDatosExpLaboral();
    await _cargarDatosGaranteReferencia();
    await _cargarDatosRelLaboral();
    await _cargarCiExpedido();
    await _cargarEstadoCivil();
    await _cargarGenero();
    await _cargarPaises();
    await _cargarCiudades();
    await _cargarZonas();
    await _cargarTipoDuracionFor();
    await _cargarTipoFormacion();
    await _cargarListaPersonas();
    await _cargarTipoGarRef();
    await _cargarListaGarRef();
    await _cargarTipoTelefono();

    setState(() => _isLoading = false);
  }*/


//CARGAR DATOS EMPLEADO
  Future<void> _cargarDatosEmpleado() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final empleados =
          await ObtenerEmpDepService().obtenerDatosEmp(widget.codEmpleado);

      if (empleados.isNotEmpty) {
        final empleado = empleados.first;
        final persona =
            await ObtenerEmpDepService().obtenerPersona(empleado.codPersona!);

        setState(() {
          _persona = persona;
          _isLoading = false;
        });
        
      } else {
        setState(() {
          _errorMessage =
              'No se encontraron datos para el empleado seleccionado.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los datos del empleado: $e';
        _isLoading = false;
      });
    }
    await _verificarPermisosEdicion();
  }

//CARGAR DATOS TELEFONO
  Future<void> _cargarDatosTelefono() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final telefono =
          await ObtenerEmpDepService().obtenerTelefono(_persona!.codPersona!);
      setState(() {
        listTelefono = telefono;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los datos del teléfono: $e';
        _isLoading = false;
      });
    }
  }

//GUARDAR DATOS TELEFONO
  Future<void> _guardarDatosTelefono() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Actualizar el objeto Telefono con los datos del controlador
      final telefonoEditado = Telefono(
        codTelefono: _telefonoSeleccionado!.codTelefono,
        codPersona: _telefonoSeleccionado!.codPersona,
        codTipoTel: _telefonoSeleccionado!.codTipoTel,
        telefono: controllers['telefono']
            ?.text
            .trim(), // Asegurarse de usar el valor actualizado
        tipo: _telefonoSeleccionado!.tipo,
        audUsuario: await _localStorageService.getCodUsuario(),
        //_telefonoSeleccionado!.audUsuario,
      );
      //log para ver el valor del telefonoEditado
      print('telefonoEditado: ${telefonoEditado.toJson()}');

      await ObtenerEmpDepService().registrarTelefono(telefonoEditado);
      final telefonoActualizado =
          await ObtenerEmpDepService().obtenerTelefono(_persona!.codPersona!);
      setState(() {
        /* final index = listTelefono.indexWhere(
            (t) => t.codTelefono == _telefonoSeleccionado!.codTelefono);
        if (index != -1) {
          listTelefono[index] = telefonoEditado;
        }*/
        listTelefono = telefonoActualizado; // Recargar la lista de teléfonos
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teléfono actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Log del error capturado
      print('Error al guardar el teléfono: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el teléfono: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _telefonoSeleccionado = null;
        _isEditingTelefono = false;
      });
    }
  }

//ACTUALIZAR CONTROLADORES TELEFONO
  void _actualizarControladores() {
    if (_telefonoSeleccionado == null) {
      //print("Error: _telefonoSeleccionado es NULL. No se pueden actualizar los controladores.");
      return;
    }

    controllers['telefono']?.text = _telefonoSeleccionado!.telefono ?? '';
    controllers['tipoTelefono']?.text = _telefonoSeleccionado!.tipo ?? '';
  }

//ACTUALIZAR CONTROLADORES CORREO
  void _actualizarControladoresCorreo() {
    if (_emailSeleccionado == null) {
      //print("Error: _emailSeleccionado es NULL. No se pueden actualizar los controladores.");
      return;
    }
    controllers['email']?.text = _emailSeleccionado!.email ?? '';
  }

//ACTUALIZAR CONTROLADORES FORMACION
  void _actualizarControladoresFormacion() {
    if (_formacionSeleccionada == null) {
      //print("Error: _formacionSeleccionada es NULL. No se pueden actualizar los controladores.");
      return;
    }
    controllers['descripcion']?.text =
        _formacionSeleccionada!.descripcion ?? '';
    controllers['duracion']?.text =
        _formacionSeleccionada!.duracion?.toString() ?? '';
    controllers['fechaFormacion']?.text =
        _formacionSeleccionada!.fechaFormacion != null
            ? DateFormat('dd-MM-yyyy')
                .format(_formacionSeleccionada!.fechaFormacion!)
            : '';
  }

//ACTUALIZAR CONTROLADORES EXPERIENCIA LABORAL
  void _actualizarControladoresExpLab() {
    if (_expLabSeleccionada == null) {
      //print("Error: _expLabSeleccionada es NULL. No se pueden actualizar los controladores.");
      return;
    }
    controllers['nombreEmpresa']?.text =
        _expLabSeleccionada!.nombreEmpresa ?? '';
    controllers['cargo']?.text = _expLabSeleccionada!.cargo ?? '';
    controllers['descripcionExpLab']?.text =
        _expLabSeleccionada!.descripcion ?? '';
    controllers['fechaInicio']?.text = _expLabSeleccionada!.fechaInicio != null
        ? DateFormat('dd-MM-yyyy').format(_expLabSeleccionada!.fechaInicio!)
        : '';
    controllers['fechaFin']?.text = _expLabSeleccionada!.fechaFin != null
        ? DateFormat('dd-MM-yyyy').format(_expLabSeleccionada!.fechaFin!)
        : '';
    controllers['nroReferencia']?.text =
        _expLabSeleccionada!.nroReferencia ?? '';
  }

//ACTUALIZAR CONTROLADORES GARANTE REFERENCIA
  void _actualizarControladoresGaranteRef() {
    if (_garanteRefSeleccionada == null) {
      //print("Error: _garanteRefSeleccionada es NULL. No se pueden actualizar los controladores.");
      return;
    }
    controllers['direccionTrabajo']?.text =
        _garanteRefSeleccionada!.direccionTrabajo ?? '';
    controllers['empresaTrabajo']?.text =
        _garanteRefSeleccionada!.empresaTrabajo ?? '';
    controllers['observacion']?.text =
        _garanteRefSeleccionada!.observacion ?? '';
    //considerar agregar telefonos
    //controllers['telefono']?.text = _garanteRefSeleccionada!.telefono ?? '';
  }

//ACTUALIZAR CONTROLADORES PERSONA
  void _actualizarControladoresPersona() {
    if (_persona == null) {
      //print("Error: _persona es NULL. No se pueden actualizar los controladores.");
      return;
    }
    controllers['nombres']?.text = _persona!.nombres ?? '';
    controllers['apPaterno']?.text = _persona!.apPaterno ?? '';
    controllers['apMaterno']?.text = _persona!.apMaterno ?? '';
    controllers['direccion']?.text = _persona!.direccion ?? '';
    controllers['ciExpedido']?.text = _persona!.ciExpedido ?? '';
    controllers['ciFechaVencimiento']?.text =
        _persona!.ciFechaVencimiento != null
            ? DateFormat('dd-MM-yyyy').format(_persona!.ciFechaVencimiento!)
            : '';
    controllers['ciNumero']?.text = _persona!.ciNumero ?? '';
    controllers['estadoCivil']?.text = _persona!.estadoCivil ?? '';
    controllers['fechaNacimiento']?.text = _persona!.fechaNacimiento != null
        ? DateFormat('dd-MM-yyyy').format(_persona!.fechaNacimiento!)
        : '';
    controllers['lugarNacimiento']?.text = _persona!.lugarNacimiento ?? '';
    controllers['nacionalidad']?.text =
        _persona!.nacionalidad?.toString() ?? '';
    controllers['sexo']?.text = _persona!.sexo ?? '';
    controllers['lat']?.text = _persona!.lat?.toString() ?? '';
    controllers['lng']?.text = _persona!.lng?.toString() ?? '';
  }

//inicializar controladores
  void _inicializarControladores() {
    final campos = [
      'nombres', //controladores de persona
      'apPaterno',
      'apMaterno',
      'direccion',
      'ciExpedido',
      'ciFechaVencimiento',
      'ciNumero',
      'estadoCivil',
      'fechaNacimiento',
      'lugarNacimiento',
      'nacionalidad',
      'sexo',
      'lat',
      'lng',
      'telefono',
      'tipoTelefono',
      'email',
      'descripcion', //controladores de formacion
      'duracion',
      'tipoDuracion',
      'tipoFormacion',
      'fechaFormacion',
      'nombreEmpresa', //controladores de experiencia laboral
      'cargo',
      'descripcionExpLab',
      'fechaInicio',
      'fechaFin',
      'nroReferencia',
      'direccionTrabajo', //controladores de garante referencia
      'empresaTrabajo',
      'tipo',
      'observacion',
    ]; // 🔹 Lista de claves para los controladores

    for (var campo in campos) {
      controllers[campo] =
          TextEditingController(); // 🔹 Asignamos un controlador a cada campo
    }
  }

  Widget _buildEditTelfForm() {
    // Actualizar los controladores antes de mostrar el formulario
    _actualizarControladores();

    return AlertDialog(
      title: const Text('Editar Teléfono'),
      content: SingleChildScrollView(
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (KeyEvent event) {
            if (kIsWeb &&
                event.logicalKey == LogicalKeyboardKey.enter &&
                event is! KeyUpEvent) {
              validarYEnviarEnWeb(_formKey, _guardarDatosTelefono);
            }
          },
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controllers['telefono'],
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      validarSoloNumeros(value, esObligatorio: true),
                  inputFormatters: bloquearEspacios,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controllers['tipoTelefono'],
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Teléfono',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
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
          onPressed: () => _guardarDatosTelefono(),
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  // Mostrar AlertDialog para agregar un nuevo teléfono
  void _mostrarDialogoAgregarTelefono() {
    _limpiarFormularioTelefono();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Teléfono'),
          content: SingleChildScrollView(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (KeyEvent event) {
                if (kIsWeb &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    event is! KeyUpEvent) {
                  validarYEnviarEnWeb(_formKey, _guardarNuevoTelefono);
                }
              },
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: controllers['telefono'],
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
                _guardarNuevoTelefono();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void activarEdicion(String formulario,
      {int? codTelefono,
      int? codEmail,
      int? codFormacion,
      int? codExperienciaLaboral,
      int? codGarante}) {
    setState(() {
      // Desactivar todas las ediciones antes de activar la correcta
      _isEditing = false;
      _isEditingTelefono = false;
      _isEditingCorreo = false;
      _isEditingFormacion = false;
      _isEditingExpLaboral = false;
      _isEditingGarRef = false;
      //_isEditingRelEmp = false;

      // Activar solo la edición seleccionada
      switch (formulario) {
        case 'general':
          _isEditing = true;
          _actualizarControladoresPersona(); 
          break;
        case 'telefono':
          _isEditingTelefono = true;
          if (codTelefono != null) {
            _telefonoSeleccionado = listTelefono.firstWhere(
              (t) => t.codTelefono == codTelefono,
              orElse: () => Telefono(),
            );
          }
          break;
        case 'correo':
          _isEditingCorreo = true;
          if (codEmail != null) {
            _emailSeleccionado = listCorreo.firstWhere(
              (t) => t.codEmail == codEmail,
              orElse: () => Email(),
            );
          }
          break;
        case 'formacion':
          _isEditingFormacion = true;
          if (codFormacion != null) {
            _formacionSeleccionada = listFormacion.firstWhere(
              (t) => t.codFormacion == codFormacion,
              orElse: () => Formaciones(),
            );
          }
          break;
        case 'expLaboral':
          _isEditingExpLaboral = true;
          if (codExperienciaLaboral != null) {
            _expLabSeleccionada = listExpLaboral.firstWhere(
              (t) => t.codExperienciaLaboral == codExperienciaLaboral,
              orElse: () => ExperienciaLaboral(),
            );
          }
          break;
        case 'garRef':
          _isEditingGarRef = true;
          if (codExperienciaLaboral != null) {
            _garanteRefSeleccionada = listGaranteReferencia.firstWhere(
              (t) => t.codGarante == codGarante,
              orElse: () => GaranteReferencia(),
            );
          }
          break;
        // case 'relEmp':
        //   _isEditingRelEmp = true;
        //   break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información del Empleado'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
                  children: [
                    Expanded(child: _buildBody()),
                  ],
                ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildFotoSeccion(),
          _isEditing ? _buildEditForm() : _buildPersonaSection(),
          _isEditingTelefono && _telefonoSeleccionado != null
              ? _buildEditTelfForm()
              : _buildTelfSeccion(),
          _isEditingCorreo ? _buildEditCorreoForm() : _buildCorreo(),
          _isEditingFormacion ? _buildEditFormacionForm() : _buildFormacion(),
          _isEditingExpLaboral
              ? _buildEditExpLaboralForm()
              : _buildExpLaboral(),
          _isEditingGarRef ? _buildEditGaranteRefForm(context) : _buildGarRef(),
          _buildRelEmp(),
        ],
      ),
    );
  }

//CARGAR DATOS CORREO
  Future<void> _cargarDatosCorreo() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final correo =
          await ObtenerEmpDepService().obtenerEmail(_persona!.codPersona!);
      setState(() {
        listCorreo = correo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los datos del correo: $e';
        _isLoading = false;
      });
    }
  }

//EDIT CORREO
  Widget _buildEditCorreoForm() {
    _actualizarControladoresCorreo();
    return AlertDialog(
      title: const Text('Editar Correo'),
      content: SingleChildScrollView(
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (KeyEvent event) {
            if (kIsWeb &&
                event.logicalKey == LogicalKeyboardKey.enter &&
                event is! KeyUpEvent) {
              // Envolver la llamada en una función anónima async
              validarYEnviarEnWeb(_formKey, () async {
                await _guardarDatosCorreo(_emailSeleccionado!);
              });
            }
          },
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controllers['email'],
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: validarEmail,
                  inputFormatters: bloquearEspacios,
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
          onPressed: () => _guardarDatosCorreo(_emailSeleccionado!),
          child: const Text('Guardar'),
        ),
      ],
    );
  }

//GUARDAR DATOS CORREO
  Future<void> _guardarDatosCorreo(Email email) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Actualizar el objeto Email con los datos del controlador
      final emailEditado = Email(
        codEmail: _emailSeleccionado!.codEmail,
        codPersona: _emailSeleccionado!.codPersona,
        email: controllers['email']?.text.trim(),
        audUsuario: await _localStorageService.getCodUsuario(),
      );

      await ObtenerEmpDepService().registrarEmail(emailEditado);

      setState(() {
        final index =
            listCorreo.indexWhere((t) => t.codEmail == email.codEmail);
        if (index != -1) {
          listCorreo[index] = emailEditado;
        }
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correo actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el correo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  //CARGAR DATOS FORMACION
  Future<void> _cargarDatosFormacion() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final formacion =
          await ObtenerEmpDepService().obtenerFormacion(widget.codEmpleado);
      setState(() {
        listFormacion = formacion;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los datos de formación: $e';
        _isLoading = false;
      });
    }
  }

//EDIT FORMACION
  Widget _buildEditFormacionForm() {
    _actualizarControladoresFormacion();
    return AlertDialog(
      title: const Text('Editar Formación'),
      content: SingleChildScrollView(
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (KeyEvent event) {
            if (kIsWeb &&
                event.logicalKey == LogicalKeyboardKey.enter &&
                event is! KeyUpEvent) {
              validarYEnviarEnWeb(_formKey, _guardarDatosFormacion);
            }
          },
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controllers['descripcion'],
                  decoration: const InputDecoration(
                      labelText: 'Descripción', border: OutlineInputBorder()),
                  validator: (value) =>
                      validarTextoMixto(value, esObligatorio: true),
                  inputFormatters: bloquearEspacios,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _formacionSeleccionada?.tipoDuracion,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Duración',
                    border: OutlineInputBorder(),
                  ),
                  items: listTipoDuracionFor.map((tipo) {
                    return DropdownMenuItem<String>(
                      value: tipo.codTipos, // Código interno para selección
                      child: Text(tipo.nombre), // Texto que se muestra en la UI
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _tipoDuracionForSeleccionada = value;
                    });
                  },
                  validator: (value) =>
                      validarDropdown(value, 'Tipo de duración'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _formacionSeleccionada?.tipoFormacion,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Formacion',
                    border: OutlineInputBorder(),
                  ),
                  items: listTipoFormacion.map((tipo) {
                    return DropdownMenuItem<String>(
                      value: tipo.codTipos, // Código interno para selección
                      child: Text(tipo.nombre), // Texto que se muestra en la UI
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _tipoFormacionSeleccionada = value;
                    });
                  },
                  validator: (value) =>
                      validarDropdown(value, 'Tipo de formacion'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                    controller: controllers['duracion'],
                    decoration: const InputDecoration(
                        labelText: 'Duración', border: OutlineInputBorder()),
                    validator: (value) => validarDuracion(
                        value,
                        _tipoDuracionForSeleccionada ??
                            _formacionSeleccionada?.tipoDuracion ??
                            '',
                        esObligatorio: true),
                    inputFormatters: bloquearEspacios),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controllers['fechaFormacion'],
                  decoration: const InputDecoration(
                      labelText: 'Fecha finalizaicon de formación',
                      border: OutlineInputBorder()),
                  readOnly: true,
                  validator: validarFecha,
                  onTap: () => _seleccionarFecha(
                      context,
                      controllers[
                          'fechaFormacion']!), // ✅ Método para elegir fecha
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
          onPressed: () => _guardarDatosFormacion(),
          child: const Text('Guardar'),
        ),
      ],
    );
  }

//GUARDAR DATOS FORMACION
  Future<void> _guardarDatosFormacion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      DateTime? fechaFormacion;
      try {
        fechaFormacion = DateFormat('dd-MM-yyyy')
            .parse(controllers['fechaFormacion']!.text.trim());
        print(
            "Fecha formateada correctamente: ${formatearFecha(fechaFormacion!)}");
      } catch (e) {
        print(
            "Error al parsear fecha: ${controllers['fechaFormacion']?.text.trim()} - $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error en el formato de la fecha')),
        );
        return;
      }
      final String tipoDuracionAEnviar = _tipoDuracionForSeleccionada ??
          _formacionSeleccionada?.tipoDuracion ??
          '';
      final String tipoFormacionAEnviar = _tipoFormacionSeleccionada ??
          _formacionSeleccionada?.tipoFormacion ??
          '';
      final formacionEditada = Formaciones(
        codFormacion: _formacionSeleccionada!.codFormacion,
        codEmpleado: _formacionSeleccionada!.codEmpleado,
        descripcion: controllers['descripcion']?.text.trim(),
        duracion: int.tryParse(controllers['duracion']?.text.trim() ?? ''),
        tipoDuracion: tipoDuracionAEnviar,
        tipoFormacion: tipoFormacionAEnviar,
        fechaFormacion: fechaFormacion,
        audUsuario: await _localStorageService.getCodUsuario(),
      );

      print("Enviando datos al backend: $formacionEditada");

      final response =
          await ObtenerEmpDepService().registrarFormacion(formacionEditada);
      print("Código de respuesta API: ${response.runtimeType}");
      print("Mensaje de respuesta API: $response");
      final formacionActualizada =
          await ObtenerEmpDepService().obtenerFormacion(widget.codEmpleado);

      setState(() {
        /*final index = listFormacion.indexWhere(
            (f) => f.codFormacion == _formacionSeleccionada!.codFormacion);
        if (index != -1) {
          listFormacion[index] = formacionEditada;
        }*/
        listFormacion = formacionActualizada;
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formación actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error al guardar la formación: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la formación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  //MOSTRAR DIALOGO DE EDICION FORMACION
  void _mostrarDialogoEdicionFormacion(int codFormacion) {
    _formacionSeleccionada = listFormacion.firstWhere(
      (f) => f.codFormacion == codFormacion,
      orElse: () => Formaciones(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildEditFormacionForm(); // ✅ Mostramos el formulario
      },
    );
  }

  //CARGAR DATOS EXP LABORAL
  Future<void> _cargarDatosExpLaboral() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final expLaboral = await ObtenerEmpDepService()
          .obtenerExperienciaLaboral(widget.codEmpleado);
      setState(() {
        listExpLaboral = expLaboral;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los datos de experiencia laboral: $e';
        _isLoading = false;
      });
    }
  }

  //EDIT EXPERIENCIA LABORAL
  Widget _buildEditExpLaboralForm() {
    _actualizarControladoresExpLab();
    return AlertDialog(
      title: const Text('Editar Experiencia Laboral'),
      content: SingleChildScrollView(
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (KeyEvent event) {
            if (kIsWeb &&
                event.logicalKey == LogicalKeyboardKey.enter &&
                event is! KeyUpEvent) {
              validarYEnviarEnWeb(_formKey, _guardarDatosExpLaboral);
            }
          },
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                TextFormField(
                  controller: controllers['nombreEmpresa'],
                  decoration: const InputDecoration(
                      labelText: 'Nombre de la Empresa',
                      border: OutlineInputBorder()),
                  validator: (value) =>
                      validarTextoMixto(value, esObligatorio: true),
                  inputFormatters: bloquearEspacios,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controllers['cargo'],
                  decoration: const InputDecoration(
                      labelText: 'Cargo', border: OutlineInputBorder()),
                  validator: (value) =>
                      validarTextoMixto(value, esObligatorio: true),
                  inputFormatters: bloquearEspacios,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controllers['descripcionExpLab'],
                  decoration: const InputDecoration(
                      labelText: 'Descripción', border: OutlineInputBorder()),
                  validator: (value) =>
                      validarTextoMixto(value, esObligatorio: false),
                  inputFormatters: bloquearEspacios,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controllers['fechaInicio'],
                  decoration: const InputDecoration(
                      labelText: 'Fecha de Inicio',
                      border: OutlineInputBorder()),
                  validator: validarFecha,
                  readOnly: true,
                  onTap: () => _seleccionarFecha(
                      context,
                      controllers[
                          'fechaInicio']!), // ✅ Método para elegir fecha
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controllers['fechaFin'],
                  decoration: const InputDecoration(
                      labelText: 'Fecha de Fin', border: OutlineInputBorder()),
                  readOnly: true,
                  validator: validarFecha,
                  onTap: () => _seleccionarFecha(context,
                      controllers['fechaFin']!), // ✅ Método para elegir fecha
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controllers['nroReferencia'],
                  decoration: const InputDecoration(
                      labelText: 'Número teléfono de Referencia',
                      border: OutlineInputBorder()),
                  validator: (value) =>
                      validarSoloNumeros(value, esObligatorio: false),
                  inputFormatters: bloquearEspacios,
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
          onPressed: () => _guardarDatosExpLaboral(),
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  // EDIT GARANTE REFERENCIA
  Widget _buildEditGaranteRefForm(BuildContext context) {
    _actualizarControladoresGaranteRef();
    return AlertDialog(
      title: const Text('Editar Garante - Referencia'),
      content: SingleChildScrollView(
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (KeyEvent event) {
            if (kIsWeb &&
                event.logicalKey == LogicalKeyboardKey.enter &&
                event is! KeyUpEvent) {
              // Envolver la llamada en una función anónima async
              validarYEnviarEnWeb(_formKey, () async {
                await _guardarDatosGaranteReferencia(widget.codEmpleado);
              });
            }
          },
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(
                  builder: (BuildContext innerContext) {
                    return DropdownSearch<Persona>(
                      items: listPersona,
                      itemAsString: (Persona? persona) =>
                          "${persona?.nombres ?? ''} ${persona?.apPaterno ?? ''} ${persona?.apMaterno ?? ''}",
                      onChanged: (Persona? selectedPersona) {
                        setState(() {
                          _personaSeleccionada = selectedPersona;
                        });
                      },
                      selectedItem: _personaSeleccionada ??
                          listPersona.firstWhere(
                            (persona) =>
                                persona.codPersona ==
                                _garanteRefSeleccionada?.codPersona,
                            orElse: () => listPersona
                                .first, // 🔹 Si no hay coincidencia, usa el primero de la lista
                          ),
                      dropdownDecoratorProps: const DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: "Buscar Persona",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      validator: validarSeleccionDropdownSearch,
                      popupProps: PopupProps.menu(
                        showSearchBox:
                            true, // Usa menú desplegable en lugar de bottomSheet
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
                            "Seleccionar Persona",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controllers['direccionTrabajo'],
                  decoration: const InputDecoration(
                      labelText: 'Dirección de Trabajo',
                      border: OutlineInputBorder()),
                  validator: (value) =>
                      validarTextoMixto(value, esObligatorio: true),
                  inputFormatters: bloquearEspacios,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controllers['empresaTrabajo'],
                  decoration: const InputDecoration(
                      labelText: 'Empresa de Trabajo',
                      border: OutlineInputBorder()),
                  validator: (value) =>
                      validarTextoMixto(value, esObligatorio: true),
                  inputFormatters: bloquearEspacios,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _garanteRefSeleccionada?.tipo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Garante - Referencia',
                    border: OutlineInputBorder(),
                  ),
                  items: listTipoGarRef.map((tipo) {
                    return DropdownMenuItem<String>(
                      value: tipo.codTipos, // Código interno para selección
                      child:
                          Text(tipo.nombre), // Muestra la descripción en la UI
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _tipoGarRefSeleccionado = value;
                    });
                  },
                  validator: (value) =>
                      validarDropdown(value, 'Seleccione una opción'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controllers['observacion'],
                  decoration: const InputDecoration(
                      labelText: 'Observación', border: OutlineInputBorder()),
                  validator: (value) =>
                      validarTextoMixto(value, esObligatorio: true),
                  inputFormatters: bloquearEspacios,
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
          onPressed: () => _guardarDatosGaranteReferencia(widget.codEmpleado),
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  //GUARDAR DATOS GARANTE REFERENCIA
  Future<void> _guardarDatosGaranteReferencia(int codEmpleado) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Validación: evitar duplicados (excepto el que se está editando)
    final int? personaId =
        _personaSeleccionada?.codPersona ?? _garanteRefSeleccionada?.codPersona;
    final int? codGaranteActual = _garanteRefSeleccionada?.codGarante;

    final existeDuplicado = listGaranteReferencia.any(
        (g) => g.codPersona == personaId && g.codGarante != codGaranteActual);

    if (existeDuplicado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Esta persona ya está registrada como garante o referencia.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    try {
      final garanteAEnviar =
          _tipoGarRefSeleccionado ?? _garanteRefSeleccionada?.tipo ?? '';
      final garanteRefEditada = GaranteReferencia(
        codGarante: _garanteRefSeleccionada!.codGarante,
        codPersona: _personaSeleccionada?.codPersona ??
            _garanteRefSeleccionada!.codPersona,
        codEmpleado: codEmpleado,
        direccionTrabajo: controllers['direccionTrabajo']?.text.trim(),
        empresaTrabajo: controllers['empresaTrabajo']?.text.trim(),
        tipo: garanteAEnviar,
        observacion: controllers['observacion']?.text.trim(),
        audUsuario: await _localStorageService.getCodUsuario(),
      );
// Log datos enviados al backend
      print('Datos enviados al backend:');
      print(garanteRefEditada.toJson());
      await ObtenerEmpDepService()
          .registrarGaranteReferencia(garanteRefEditada);
      final garanteActualizado =
          await ObtenerEmpDepService().obtenerGaranteReferencia(codEmpleado);
      setState(() {
        listGaranteReferencia = garanteActualizado;
        /*final index = listGaranteReferencia.indexWhere(
            (f) => f.codGarante == _garanteRefSeleccionada!.codGarante);
        if (index != -1) {
          listGaranteReferencia[index] = garanteRefEditada;
        }*/
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Garante referencia actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el garante referencia: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  //GUARDAR DATOS EXP LABORAL
  Future<void> _guardarDatosExpLaboral() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      DateTime? fechaInicio;
      DateTime? fechaFin;
      try {
        fechaInicio = DateFormat('dd-MM-yyyy')
            .parse(controllers['fechaInicio']!.text.trim());
        fechaFin = DateFormat('dd-MM-yyyy')
            .parse(controllers['fechaFin']!.text.trim());
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error en el formato de la fecha')),
        );
        return;
      }

      final expLabEditada = ExperienciaLaboral(
        codExperienciaLaboral: _expLabSeleccionada!.codExperienciaLaboral,
        codEmpleado: _expLabSeleccionada!.codEmpleado,
        nombreEmpresa: controllers['nombreEmpresa']?.text.trim(),
        cargo: controllers['cargo']?.text.trim(),
        descripcion: controllers['descripcionExpLab']?.text.trim(),
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        nroReferencia: controllers['nroReferencia']?.text.trim(),
        audUsuario: _expLabSeleccionada!.audUsuario,
      );

      await ObtenerEmpDepService().registrarExpLaboral(expLabEditada);

      setState(() {
        final index = listExpLaboral.indexWhere((f) =>
            f.codExperienciaLaboral ==
            _expLabSeleccionada!.codExperienciaLaboral);
        if (index != -1) {
          listExpLaboral[index] = expLabEditada;
        }
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Experiencia laboral actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la experiencia laboral: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  //CARGAR DATOS RELACION LABORAL
  Future<void> _cargarDatosRelLaboral() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final relLaboral =
          await ObtenerEmpDepService().obtenerRelEmp(widget.codEmpleado);
      setState(() {
        listRelEmpEmpr = relLaboral;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los datos de relación laboral: $e';
        _isLoading = false;
      });
    }
  }

  //CARGAR DATOS GARANTE REFERENCIA
  Future<void> _cargarDatosGaranteReferencia() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final garanteReferencia = await ObtenerEmpDepService()
          .obtenerGaranteReferencia(widget.codEmpleado);
      setState(() {
        listGaranteReferencia = garanteReferencia;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los datos de garante referencia: $e';
        _isLoading = false;
      });
    }
  }

  //GUARDAR DATOS PERSONA
  Future<void> _guardarDatosPersona() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Usa el valor seleccionado o, en caso de null, el valor de _persona.
        final String ciExpedidoAEnviar =
            _ciExpedidoSeleccionado ?? _persona?.ciExpedido ?? '';
        final String estadoCivilAEnviar =
            _estadoCivilSeleccionado ?? _persona?.estadoCivil ?? '';
        final int? nacionalidadAEnviar =
            _nacionalidadSeleccionado ?? _persona?.nacionalidad;
        final String? sexoAEnviar = _generoSeleccionado ?? _persona?.sexo;
        final int zonaAEnviar = _zonaSeleccionado ?? _persona?.codZona ?? 0;

        final personaEditada = Persona(
            codPersona: _persona?.codPersona,
            codZona: zonaAEnviar,
            nombres: controllers['nombres']?.text.trim(),
            apPaterno: controllers['apPaterno']?.text.trim(),
            apMaterno: controllers['apMaterno']?.text.trim(),
            ciExpedido: ciExpedidoAEnviar,
            ciFechaVencimiento: DateFormat('dd-MM-yyyy')
                .parse(controllers['ciFechaVencimiento']?.text.trim()??''),
            ciNumero: controllers['ciNumero']?.text.trim(),
            direccion: controllers['direccion']?.text.trim(),
            estadoCivil: estadoCivilAEnviar,
            fechaNacimiento:
                DateFormat('dd-MM-yyyy')
                .parse(controllers['fechaNacimiento']?.text.trim()??''),
            lugarNacimiento: controllers['lugarNacimiento']?.text.trim(),
            nacionalidad: nacionalidadAEnviar,
            sexo: sexoAEnviar,
            
            lat:double.tryParse(controllers['lat']?.text.trim() ?? ''),
            lng: double.tryParse(controllers['lng']?.text.trim() ?? ''),
          //  lat: double.tryParse(controllers['lat']?.text.trim() ?? ''),
           // lng: double.tryParse(controllers['lng']?.text.trim() ?? ''),
            audUsuarioI: await _localStorageService.getCodUsuario());
        print('Datos enviados al backend:');
        print('latitud:${controllers['lat']?.text}');
        print('lng:${controllers['lng']?.text}');
        //  print('Latitud: ${_latController.text}');
        //print('Longitud: ${_lngController.text}');
        print('codZona: ${_persona?.codZona}');
        print('audUsuarioI: ${await _localStorageService.getCodUsuario()}');

        await ObtenerEmpDepService().editarPersona(personaEditada);
        final personaActualizada =
            await ObtenerEmpDepService().obtenerPersona(_persona!.codPersona!);

        setState(() {
          //  _isEditing = false;
          _persona = personaActualizada;
          _isLoading = false;
          _isEditing = false;
        });

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

//para datos personales (empleado)
  Future<void> _seleccionarFecha(
      BuildContext context, TextEditingController controladorFecha) async {
    // Si el controlador tiene texto, intenta convertirlo a DateTime.
    // De lo contrario, usa DateTime.now() como respaldo.
    DateTime initialDate;
    if (controladorFecha.text.isNotEmpty) {
      try {
        initialDate = DateFormat('dd-MM-yyyy').parse(controladorFecha.text);
      } catch (e) {
        // En caso de error en el parse, se usa la fecha actual.
        initialDate = DateTime.now();
      }
    } else {
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate, // Se usa la fecha precargada (o la actual)
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controladorFecha.text = DateFormat('dd-MM-yyyy').format(picked);
    }
  }

  Future<void> _seleccionarUbicacion() async {
  LatLng posicionActual = LatLng(
    
    double.tryParse(controllers['lat']!.text) ?? -16.5,
    double.tryParse(controllers['lng']!.text) ?? -68.1,
  );

  LatLng? nuevaUbicacion = await showDialog<LatLng>(
    context: context,
    builder: (context) {
      LatLng marcador = posicionActual;
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Seleccionar Ubicación'),
            content: SizedBox(
              height: 400,
              width: 400,
              child: FlutterMap(
                options: MapOptions(
                  center: marcador,
                  zoom: 13.0,
                  onTap: (tapPosition, point) {
                    setState(() {
                      marcador = point;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: marcador,
                        width: 40,
                        height: 40,
                        builder: (ctx) =>
                            const Icon(Icons.location_pin, color: Colors.red, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, marcador),
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      );
    },
  );

  if (nuevaUbicacion != null) {
    setState(() {
      
      controllers['lat']!.text = nuevaUbicacion.latitude.toString();
      controllers['lng']!.text = nuevaUbicacion.longitude.toString();
    });
  }
}

//SECCION DATOS PERSONALES
  Widget _buildPersonaSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DATOS PERSONALES',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(estadoExpandido['empleado']!
                          ? Icons.expand_less
                          : Icons.expand_more),
                      tooltip: estadoExpandido['empleado']!
                          ? 'Contraer'
                          : 'Expandir',
                      onPressed: () => toggleSeccion('empleado'),
                    ),
                    buildSpeedDial(
                      nombreSeccion: 'persona',
                      onEditar: () => activarEdicion('general'),
                      updateOperation: (String? operation) {
                        setState(() {
                          selectedOperation['persona'] = operation;
                        });
                      },
                      operacionHabilitada: ['editar'],
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            if (estadoExpandido['empleado']!) ...[
              // Usar spread operator para la lista de widgets
              _buildInfoRow('NOMBRE:',
                  (_persona?.nombres ?? 'Sin registros').toUpperCase()),
              _buildInfoRow('APELLIDO PATERNO:',
                  (_persona?.apPaterno ?? 'Sin registros').toUpperCase()),
              _buildInfoRow('APELLIDO MATERNO:',
                  (_persona?.apMaterno ?? 'Sin registros').toUpperCase()),
              _buildInfoRow(
                'CI EXPEDIDO:',
                listCiExpedido
                    .firstWhere(
                      (tipo) => tipo.codTipos == _persona?.ciExpedido,
                      orElse: () => CiExpedido(
                          codTipos: '',
                          nombre: 'Sin registros',
                          codGrupo: 9,
                          listTipos: []),
                    )
                    .nombre
                    .toUpperCase(),
              ),
              _buildInfoRow(
                'FECHA DE VENCIMIENTO CI:',
                _persona?.ciFechaVencimiento != null
                    ? formatearFecha(_persona!.ciFechaVencimiento!)
                    : 'Sin registros',
              ),
              _buildInfoRow(
                  'CI NUMERO:', _persona?.ciNumero ?? 'Sin registros'),
              _buildInfoRow('DIRECCION:',
                  (_persona?.direccion ?? 'Sin registros').toUpperCase()),
              _buildInfoRow(
                'ESTADO CIVIL:',
                listEstCivil
                    .firstWhere(
                      (tipo) => tipo.codTipos == _persona?.estadoCivil,
                      orElse: () => EstCivil(
                          codTipos: '',
                          nombre: 'Sin registros',
                          codGrupo: 9,
                          listTipos: []),
                    )
                    .nombre
                    .toUpperCase(),
              ),
              _buildInfoRow(
                'FECHA DE NACIMIENTO:',
                _persona?.fechaNacimiento != null
                    ? formatearFecha(_persona!.fechaNacimiento!)
                    : 'Sin registros',
              ),
              _buildInfoRow('LUGAR DE NACIMIENTO:',
                  _persona?.lugarNacimiento ?? 'Sin registros'),
              _buildInfoRow(
                'NACIONALIDAD:',
                listPaises
                    .firstWhere(
                      (pais) => pais.codPais == _persona?.nacionalidad,
                      orElse: () => Pais(
                          codPais: 0, pais: 'Sin registros', audUsuario: 0),
                    )
                    .pais
                    .toString()
                    .toUpperCase(),
              ),
              _buildInfoRow(
                'GENERO:',
                listGeneros
                    .firstWhere(
                      (tipo) => tipo.codTipos == _persona?.sexo,
                      orElse: () => Sexos(
                          codTipos: '',
                          nombre: 'Sin registros',
                          codGrupo: 1,
                          listTipos: []),
                    )
                    .nombre!
                    .toUpperCase(),
              ),
              _buildInfoRow('ZONA:', _persona?.zona?.zona ?? 'Sin registros'),
              _buildInfoRow(
                  'CIUDAD:', _persona?.ciudad?.ciudad ?? 'Sin registros'),
              const SizedBox(height: 16),
              const Text(
                'UBICACION',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              SizedBox(
                height: 300,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: MapOptions(
                      center: LatLng(
                       _persona?.lat ?? 0.0,
                              _persona?.lng ?? 0.0,
                      ),
                      zoom: 13.0,
                      interactiveFlags: _isEditing
                          ? InteractiveFlag.all
                          : InteractiveFlag.all,
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
                            point: LatLng(
                              
                              _persona?.lat ?? 0.0,
                              _persona?.lng ?? 0.0,
                            ),
                            builder: (ctx) => const Icon(Icons.location_pin,
                                color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

// Función auxiliar para estructurar cada línea de datos de manera uniforme
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

// SECCION TELEFONO
  Widget _buildTelfSeccion() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TELEFONO (S)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    // 🔥 Botón para expandir/contraer
                    IconButton(
                      icon: Icon(estadoExpandido['telefono']!
                          ? Icons.expand_less
                          : Icons.expand_more),
                      tooltip: estadoExpandido['telefono']!
                          ? 'Contraer'
                          : 'Expandir',
                      onPressed: () => toggleSeccion('telefono'),
                    ),
                    buildSpeedDial(
                      nombreSeccion:
                          'telefono', //speed dial solo afecta a telefono
                      onAgregar: _mostrarDialogoAgregarTelefono,
                      onEditar: () => setState(
                          () => selectedOperation['telefono'] = 'editar'),
                      onEliminar: () => setState(
                          () => selectedOperation['telefono'] = 'eliminar'),
                      updateOperation: (String? operation) {
                        setState(() {
                          selectedOperation['telefono'] = operation;
                        });
                      },
                      operacionHabilitada: ['agregar', 'editar', 'eliminar'],
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            if (estadoExpandido['telefono']!)
              listTelefono.isNotEmpty
                  ? Column(
                      children: listTelefono.map((telefono) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow('TELEFONO:',
                                      telefono.telefono ?? 'Sin registros'),
                                  _buildInfoRow('TIPO:',
                                      telefono.tipo ?? 'Sin registros'),
                                  const Divider(),
                                ],
                              ),
                            ),
                            if (selectedOperation['telefono'] == 'editar')
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Editar telefono',
                                onPressed: () => _mostrarDialogoEdicionTelefono(
                                    telefono
                                        .codTelefono!), // 🔹 Usa codtelefono
                              ),
                            if (selectedOperation['telefono'] == 'eliminar')
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  print(
                                      "📤 Eliminando teleono con codTelefono: ${telefono.codTelefono}");
                                  final eliminado = await eliminarTelefono(
                                      telefono.codTelefono!);
                                  if (eliminado) {
                                    setState(() {
                                      listTelefono.removeWhere((t) =>
                                          t.codTelefono ==
                                          telefono.codTelefono);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Telefono eliminado correctamente.'),
                                          backgroundColor: Colors.green),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'No se pudo eliminar el telefono.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                          ],
                        );
                      }).toList(),
                    )
                  : const Text('Sin registros',
                      style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

//METODO PARA ELIMINAR TELEFONO
  Future<bool> eliminarTelefono(int codTelefono) async {
    // 🔹 Validar que el ID es válido antes de enviar la solicitud
    if (codTelefono <= 0) {
      print("⚠️ Error: codEmail es inválido ($codTelefono)");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Código de telefono inválido.')),
      );
      return false;
    }

    print(
        "📤 Enviando solicitud para eliminar telefono con codTelefono: $codTelefono");

    final bool resultado =
        await ObtenerEmpDepService().eliminarTelefono(codTelefono);

    print("📤 Resultado de eliminartelefono: $resultado");

    if (resultado) {
      try {
        setState(() {
          listTelefono.removeWhere((t) => t.codTelefono == codTelefono);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('✅ Telefono eliminado correctamente: $codTelefono'),
              backgroundColor: Colors.green),
        );
      } catch (e) {
        print("❌ Error en `setState()`: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al actualizar la lista: $e'),
              backgroundColor: Colors.red),
        );
      }
      return true;
    } else {
      print("❌ No se pudo eliminar el telefono con codTelefono: $codTelefono");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('❌ Error al eliminar el telefono. Código: $codTelefono'),
            backgroundColor: Colors.red),
      );
      return false;
    }
  }

//mostrar dialogo de edicion telefono
  void _mostrarDialogoEdicionTelefono(int codTelefono) {
    _telefonoSeleccionado = listTelefono.firstWhere(
      (t) => t.codTelefono == codTelefono,
      orElse: () => Telefono(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildEditTelfForm(); // 🔹 Ya no pasamos parámetros, porque usa _telefonoSeleccionado
      },
    );
  }

//mostrar dialogo de edicion correo
  void _mostrarDialogoEdicionCorreo(int codEmail) {
    _emailSeleccionado = listCorreo.firstWhere(
      (t) => t.codEmail == codEmail,
      orElse: () => Email(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildEditCorreoForm(); // 🔹 Ya no pasamos parámetros, porque usa _emailSeleccionado
      },
    );
  }

//SECCION CORREO
  Widget _buildCorreo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CORREO ELECTRÓNICO',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(estadoExpandido['correo']!
                          ? Icons.expand_less
                          : Icons.expand_more),
                      tooltip:
                          estadoExpandido['correo']! ? 'Contraer' : 'Expandir',
                      onPressed: () => toggleSeccion('correo'),
                    ),
                    buildSpeedDial(
                      nombreSeccion: 'correo', //speed dial solo afecta a correo
                      onAgregar: _mostrarDialogoAgregarCorreo,
                      onEditar: () => setState(
                          () => selectedOperation['correo'] = 'editar'),
                      onEliminar: () => setState(
                          () => selectedOperation['correo'] = 'eliminar'),
                      updateOperation: (String? operation) {
                        setState(() {
                          selectedOperation['correo'] = operation;
                        });
                      },
                      operacionHabilitada: ['agregar', 'editar', 'eliminar'],
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            if (estadoExpandido['correo']!)
              listCorreo.isNotEmpty
                  ? Column(
                      children: listCorreo.map((correo) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow('Correo:',
                                      correo.email ?? 'Sin registros'),
                                ],
                              ),
                            ),
                            if (selectedOperation['correo'] == 'editar')
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Editar Correo',
                                onPressed: () => _mostrarDialogoEdicionCorreo(
                                    correo.codEmail!), // 🔹 Usa codEmail
                              ),
                            if (selectedOperation['correo'] == 'eliminar')
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  print(
                                      "📤 Eliminando correo con codEmail: ${correo.codEmail}");
                                  final eliminado =
                                      await eliminarEmail(correo.codEmail!);
                                  if (eliminado) {
                                    setState(() {
                                      listCorreo.removeWhere(
                                          (c) => c.codEmail == correo.codEmail);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Correo eliminado correctamente.'),
                                          backgroundColor: Colors.green),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'No se pudo eliminar el correo.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                          ],
                        );
                      }).toList(),
                    )
                  : const Text('Sin registros',
                      style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  //metodo para eliminar correo
  Future<bool> eliminarEmail(int codEmail) async {
    // 🔹 Validar que el ID es válido antes de enviar la solicitud
    if (codEmail <= 0) {
      print("⚠️ Error: codEmail es inválido ($codEmail)");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Código de correo inválido.')),
      );
      return false;
    }

    print("📤 Enviando solicitud para eliminar correo con codEmail: $codEmail");

    final bool resultado = await ObtenerEmpDepService().eliminarEmail(codEmail);

    print("📤 Resultado de eliminarEmail: $resultado");

    if (resultado) {
      try {
        setState(() {
          listCorreo.removeWhere((c) => c.codEmail == codEmail);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('✅ Correo eliminado correctamente: $codEmail'),
              backgroundColor: Colors.green),
        );
      } catch (e) {
        print("❌ Error en `setState()`: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar la lista: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return true;
    } else {
      print("❌ No se pudo eliminar el correo con codEmail: $codEmail");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al eliminar el correo. Código: $codEmail'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

//Mostrar dialogo agregar correo
  void _mostrarDialogoAgregarCorreo() {
    _limpiarFormularioCorreo();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Correo Electrónico'),
          content: SingleChildScrollView(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (KeyEvent event) {
                if (kIsWeb &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    event is! KeyUpEvent) {
                  validarYEnviarEnWeb(_formKey, _guardarNuevoCorreo);
                }
              },
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: controllers['email'],
                      decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          border: OutlineInputBorder()),
                      validator: (value) =>
                          validarEmail(value, esObligatorio: true),
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
                _guardarNuevoCorreo();
              },
              child: const Text('Guardar'),
            ),
          ],
        ); // 🔹 Muestra el formulario para agregar un nuevo correo
      },
    );
  }

//SECCION FORMACION
  Widget _buildFormacion() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'FORMACION',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(estadoExpandido['formacion']!
                          ? Icons.expand_less
                          : Icons.expand_more),
                      tooltip: estadoExpandido['formacion']!
                          ? 'Contraer'
                          : 'Expandir',
                      onPressed: () => toggleSeccion('formacion'),
                    ),
                    buildSpeedDial(
                      nombreSeccion: 'formacion',
                      onAgregar: _mostrarDialogoAgregarFormacion,
                      onEditar: () => setState(
                          () => selectedOperation['formacion'] = 'editar'),
                      onEliminar: () => setState(
                          () => selectedOperation['formacion'] = 'eliminar'),
                      updateOperation: (String? operation) {
                        setState(() {
                          selectedOperation['formacion'] = operation;
                        });
                      },
                      operacionHabilitada: ['agregar', 'editar', 'eliminar'],
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            if (estadoExpandido['formacion']!)
              listFormacion.isNotEmpty
                  ? Column(
                      children: listFormacion
                          .map((formacion) => Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildInfoRow(
                                            'Descripción:',
                                            formacion.descripcion ??
                                                'Sin registros'),
                                        _buildInfoRow(
                                            'Duración:',
                                            formacion.duracion?.toString() ??
                                                'Sin registros'),
                                        _buildInfoRow(
                                          'Tipo:',
                                          listTipoDuracionFor
                                              .firstWhere(
                                                (tipo) =>
                                                    tipo.codTipos ==
                                                    formacion.tipoDuracion,
                                                orElse: () =>
                                                    TipoDuracionFormacion(
                                                  codTipos: '',
                                                  nombre: 'Sin registros',
                                                  codGrupo: 9,
                                                  listTipos: [],
                                                ),
                                              )
                                              .nombre
                                              .toUpperCase(),
                                        ),
                                        _buildInfoRow(
                                          'Tipo:',
                                          listTipoFormacion
                                              .firstWhere(
                                                (tipo) =>
                                                    tipo.codTipos ==
                                                    formacion.tipoFormacion,
                                                orElse: () => TipoFormacion(
                                                  codTipos: '',
                                                  nombre: 'Sin registros',
                                                  codGrupo: 9,
                                                  listTipos: [],
                                                ),
                                              )
                                              .nombre
                                              .toUpperCase(),
                                        ),
                                        _buildInfoRow(
                                            'Fecha:',
                                            formacion.fechaFormacion != null
                                                ? formatearFecha(
                                                    formacion.fechaFormacion!)
                                                : 'Sin registros'),
                                        const Divider(),
                                      ],
                                    ),
                                  ),
                                  if (selectedOperation['formacion'] ==
                                      'editar')
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      tooltip: 'Editar Formación',
                                      onPressed: () =>
                                          _mostrarDialogoEdicionFormacion(formacion
                                              .codFormacion!), // 🔹 Usa codFormaciones
                                    ),
                                  if (selectedOperation['formacion'] ==
                                      'eliminar')
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () async {
                                        eliminarFormacion(
                                            formacion.codFormacion!);
                                      },
                                    ),
                                ],
                              ))
                          .toList(),
                    )
                  : const Text('Sin registros',
                      style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

//METODO PARA ELIMINAR FORMACION
  Future<bool> eliminarFormacion(int codFormacion) async {
    // 🔹 Validar que el ID es válido antes de enviar la solicitud
    if (codFormacion <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Código de formacion inválido.')),
      );
      return false;
    }

    final bool resultado =
        await ObtenerEmpDepService().eliminarFormacion(codFormacion);

    if (resultado) {
      try {
        setState(() {
          listFormacion.removeWhere((f) => f.codFormacion == codFormacion);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Formación eliminada correctamente.'),
              backgroundColor: Colors.green),
        );
      } catch (e) {
        print("Error en `setState()`: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al actualizar la lista: $e'),
              backgroundColor: Colors.red),
        );
      }
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al eliminar formacion. Código: $codFormacion'),
            backgroundColor: Colors.red),
      );
      return false;
    }
  }

//mostrar dialogo agregar formacion
  void _mostrarDialogoAgregarFormacion() {
    _limpiarFormularioFormacion();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Formación'),
          content: SingleChildScrollView(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (KeyEvent event) {
                if (kIsWeb &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    event is! KeyUpEvent) {
                  validarYEnviarEnWeb(_formKey, _guardarNuevaFormacion);
                }
              },
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: controllers['descripcion'],
                      decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder()),
                      validator: (value) =>
                          validarTextoMixto(value, esObligatorio: true),
                      inputFormatters: bloquearEspacios,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: listTipoDuracionFor.any((tipo) =>
                              tipo.codTipos == _formacion?.tipoDuracion)
                          ? _formacion?.tipoDuracion
                          : _tipoDuracionForSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Duración',
                        border: OutlineInputBorder(),
                      ),
                      items: listTipoDuracionFor.map((tipo) {
                        return DropdownMenuItem<String>(
                          value: tipo
                              .codTipos, // Este es el código que se maneja internamente
                          child: Text(tipo
                              .nombre), // Este es el valor que se muestra en la UI
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _tipoDuracionForSeleccionada = value;
                        });
                      },
                      validator: (value) =>
                          validarDropdown(value, 'Tipo de duracion'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: listTipoFormacion.any((tipo) =>
                              tipo.codTipos == _formacion?.tipoFormacion)
                          ? _formacion?.tipoFormacion
                          : _tipoFormacionSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de formacion',
                        border: OutlineInputBorder(),
                      ),
                      items: listTipoFormacion.map((tipo) {
                        return DropdownMenuItem<String>(
                          value: tipo
                              .codTipos, // Este es el código que se maneja internamente
                          child: Text(tipo
                              .nombre), // Este es el valor que se muestra en la UI
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _tipoFormacionSeleccionada = value;
                        });
                      },
                      validator: (value) =>
                          validarDropdown(value, 'Tipo de formacion'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllers['duracion'],
                      decoration: const InputDecoration(
                          labelText: 'Duración', border: OutlineInputBorder()),
                      validator: (value) => validarDuracion(
                          value, _tipoDuracionForSeleccionada ?? '',
                          esObligatorio: true),
                      inputFormatters: bloquearEspacios,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllers['fechaFormacion'],
                      decoration: const InputDecoration(
                          labelText: 'Fecha de finalizacion de formación',
                          border: OutlineInputBorder()),
                      readOnly: true,
                      validator: validarFecha,
                      onTap: () => _seleccionarFecha(context,
                          controllers['fechaFormacion']!), // Selección de fecha
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
                _guardarNuevaFormacion();
              },
              child: const Text('Guardar'),
            ),
          ],
        ); // 🔹 Muestra el formulario para agregar un nuevo correo
      },
    );
  }

//SECCION EXPERIENCIA LABORAL
  Widget _buildExpLaboral() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'EXPERIENCIA LABORAL',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(estadoExpandido['expLab']!
                          ? Icons.expand_less
                          : Icons.expand_more),
                      tooltip:
                          estadoExpandido['expLab']! ? 'Contraer' : 'Expandir',
                      onPressed: () => toggleSeccion('expLab'),
                    ),
                    buildSpeedDial(
                      nombreSeccion: 'expLaboral',
                      onAgregar: _mostrarDialogoAgregarExpLaboral,
                      onEditar: () => setState(
                          () => selectedOperation['expLaboral'] = 'editar'),
                      onEliminar: () => setState(
                          () => selectedOperation['expLaboral'] = 'eliminar'),
                      updateOperation: (String? operation) {
                        setState(() {
                          selectedOperation['expLaboral'] = operation;
                        });
                      },
                      operacionHabilitada: ['agregar', 'editar', 'eliminar'],
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            if (estadoExpandido['expLab']!)
              listExpLaboral.isNotEmpty
                  ? Column(
                      children: listExpLaboral.map((experienciaLaboral) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                      'Empresa:',
                                      experienciaLaboral.nombreEmpresa ??
                                          'Sin registros'),
                                  _buildInfoRow(
                                      'Cargo:',
                                      experienciaLaboral.cargo ??
                                          'Sin registros'),
                                  _buildInfoRow(
                                      'Descripción:',
                                      experienciaLaboral.descripcion ??
                                          'Sin registros'),
                                  _buildInfoRow(
                                      'Fecha Inicio:',
                                      experienciaLaboral.fechaInicio != null
                                          ? formatearFecha(
                                              experienciaLaboral.fechaInicio!)
                                          : 'Sin registros'),
                                  _buildInfoRow(
                                      'Fecha Finalización:',
                                      experienciaLaboral.fechaFin != null
                                          ? formatearFecha(
                                              experienciaLaboral.fechaFin!)
                                          : 'Sin registros'),
                                  _buildInfoRow(
                                      'Teléfono de Referencia:',
                                      experienciaLaboral.nroReferencia ??
                                          'Sin registros'),
                                  const Divider(),
                                ],
                              ),
                            ),
                            if (selectedOperation['expLaboral'] == 'editar')
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Editar Experiencia Laboral',
                                onPressed: () => _mostrarDialogoEdicionExpLaboral(
                                    experienciaLaboral
                                        .codExperienciaLaboral!), // 🔹 Usa codExperienciaLaboral
                              ),
                            if (selectedOperation['expLaboral'] == 'eliminar')
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  print(
                                      "📤 Eliminando experienciaLaboral con codExplab: ${experienciaLaboral.codExperienciaLaboral}");
                                  final eliminado = await eliminarExpLab(
                                      experienciaLaboral
                                          .codExperienciaLaboral!);
                                  if (eliminado) {
                                    setState(() {
                                      listExpLaboral.removeWhere((e) =>
                                          e.codExperienciaLaboral ==
                                          experienciaLaboral
                                              .codExperienciaLaboral);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'experienciaLaboral eliminada correctamente.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'No se pudo eliminar la experienciaLaboral.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                          ],
                        );
                      }).toList(),
                    )
                  : const Text('Sin registros',
                      style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

//METODO PARA ELIMINAR EXPLAB
  Future<bool> eliminarExpLab(int codExperienciaLaboral) async {
    // 🔹 Validar que el ID es válido antes de enviar la solicitud
    if (codExperienciaLaboral <= 0) {
      print("⚠️ Error: explab es inválido ($codExperienciaLaboral)");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Código de formacion inválido.')),
      );
      return false;
    }

    print(
        "📤 Enviando solicitud para eliminar correo con codFormacion: $codExperienciaLaboral");

    final bool resultado =
        await ObtenerEmpDepService().eliminarExpLab(codExperienciaLaboral);

    print("📤 Resultado de eliminarFormacion: $resultado");

    if (resultado) {
      try {
        setState(() {
          listExpLaboral.removeWhere(
              (e) => e.codExperienciaLaboral == codExperienciaLaboral);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '✅ Correo eliminado correctamente: $codExperienciaLaboral'),
              backgroundColor: Colors.green),
        );
      } catch (e) {
        print("❌ Error en `setState()`: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar la lista: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return true;
    } else {
      print(
          "❌ No se pudo eliminar el FORMACION con codFormacion: $codExperienciaLaboral");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '❌ Error al eliminar FORMACION. Código: $codExperienciaLaboral'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

//MOSTRAR DIALOGO DE NUEVA EXPERIENCIA LABORAL
  void _mostrarDialogoAgregarExpLaboral() {
    _limpiarFormularioExpLab();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Experiencia Laboral'),
          content: SingleChildScrollView(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (KeyEvent event) {
                if (kIsWeb &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    event is! KeyUpEvent) {
                  validarYEnviarEnWeb(_formKey, _guardarNuevaExpLab);
                }
              },
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllers['nombreEmpresa'],
                      decoration: const InputDecoration(
                          labelText: 'NOMBRE DE LA EMPRESA',
                          border: OutlineInputBorder()),
                      validator: (value) =>
                          validarTextoMixto(value, esObligatorio: true),
                      inputFormatters: bloquearEspacios,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllers['cargo'],
                      decoration: const InputDecoration(
                          labelText: 'CARGO', border: OutlineInputBorder()),
                      validator: (value) =>
                          validarTextoMixto(value, esObligatorio: true),
                      inputFormatters: bloquearEspacios,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllers['descripcionExpLab'],
                      decoration: const InputDecoration(
                          labelText: 'DESCRIPCION',
                          border: OutlineInputBorder()),
                      validator: (value) =>
                          validarTextoMixto(value, esObligatorio: false),
                      inputFormatters: bloquearEspacios,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllers['fechaInicio'],
                      decoration: const InputDecoration(
                          labelText: 'FECHA DE INICIO',
                          border: OutlineInputBorder()),
                      readOnly: true,
                      validator: validarFecha,
                      onTap: () => _seleccionarFecha(context,
                          controllers['fechaInicio']!), // Selección de fecha
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllers['fechaFin'],
                      decoration: const InputDecoration(
                          labelText: 'FECHA DE FINALIZACION',
                          border: OutlineInputBorder()),
                      readOnly: true,
                      validator: validarFecha,
                      onTap: () => _seleccionarFecha(context,
                          controllers['fechaFin']!), // Selección de fecha
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllers['nroReferencia'],
                      decoration: const InputDecoration(
                          labelText: 'NRO TELEFONO DE REFERENCIA',
                          border: OutlineInputBorder()),
                      validator: (value) =>
                          validarSoloNumeros(value, esObligatorio: false),
                      inputFormatters: bloquearEspacios,
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
                if (!_formKey.currentState!.validate()) {
                  return;
                }
                // Aquí puedes agregar la lógica para guardar el nuevo teléfono
                final nuevaExpLaboral = ExperienciaLaboral(
                  codExperienciaLaboral: 0,
                  codEmpleado: widget.codEmpleado,
                  nombreEmpresa:
                      controllers['nombreEmpresa']?.text.trim() ?? '',
                  cargo: controllers['cargo']?.text.trim() ?? '',
                  descripcion: controllers['descripcion']?.text.trim() ?? '',
                  fechaInicio: DateFormat('dd-MM-yyyy')
                      .parse(controllers['fechaInicio']?.text.trim() ?? ''),
                  fechaFin: DateFormat('dd-MM-yyyy')
                      .parse(controllers['fechaFin']?.text.trim() ?? ''),
                  nroReferencia:
                      controllers['nroReferencia']?.text.trim() ?? '',
                  audUsuario: await _localStorageService.getCodUsuario(),
                );
                print(nuevaExpLaboral.toJson());
                // Llama a tu método para guardar el nuevo teléfono
                try {
                  await ObtenerEmpDepService()
                      .registrarExpLaboral(nuevaExpLaboral);
                  final expLabActualizada = await ObtenerEmpDepService()
                      .obtenerExperienciaLaboral(widget.codEmpleado);

                  setState(() {
                    listExpLaboral = expLabActualizada;
                  });
                  Navigator.pop(context); // Cierra el diálogo
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Experiencia Laboral guardada correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Error al guardar la experiencia laboral: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                // _guardarDatosCorreo(nuevoCorreo); // 🔹 Método para guardar el nuevo correo
              },
              child: const Text('Guardar'),
            ),
          ],
        ); // 🔹 Muestra el formulario para agregar un nuevo correo
      },
    );
  }

//MOSTRAR DIALOGO DE EDICION EXP LABORAL
  void _mostrarDialogoEdicionExpLaboral(int codExpLaboral) {
    _expLabSeleccionada = listExpLaboral.firstWhere(
      (t) => t.codExperienciaLaboral == codExpLaboral,
      orElse: () => ExperienciaLaboral(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildEditExpLaboralForm(); // 🔹 Ya no pasamos parámetros, porque usa _expLabSeleccionada
      },
    );
  }

//SECCION GARANTE REFERENCIA
  Widget _buildGarRef() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'GARANTE-REFERENCIA',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(estadoExpandido['garantes']!
                          ? Icons.expand_less
                          : Icons.expand_more),
                      tooltip: estadoExpandido['garantes']!
                          ? 'Contraer'
                          : 'Expandir',
                      onPressed: () => toggleSeccion('garantes'),
                    ),
                    buildSpeedDial(
                      nombreSeccion: 'perGarante',
                      onAgregar: _mostrarDialogoAgregarGarRef,
                      onEditar: () => setState(
                          () => selectedOperation['perGarante'] = 'editar'),
                      onEliminar: () => setState(
                          () => selectedOperation['perGarante'] = 'eliminar'),
                      updateOperation: (String? operation) {
                        setState(() {
                          selectedOperation['perGarante'] = operation;
                        });
                      },
                      operacionHabilitada: ['agregar', 'editar', 'eliminar'],
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            if (estadoExpandido['garantes']!)
              listGaranteReferencia.isNotEmpty
                  ? Column(
                      children: listGaranteReferencia.map((garanteReferencia) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                      'Nombre completo:',
                                      garanteReferencia.nombreCompleto ??
                                          'Sin registros'),
                                  _buildInfoRow(
                                      'Domicilio:',
                                      garanteReferencia.direccionDomicilio ??
                                          'Sin registros'),
                                  _buildInfoRow(
                                      'Dirección Trabajo:',
                                      garanteReferencia.direccionTrabajo ??
                                          'Sin registros'),
                                  _buildInfoRow(
                                      'Empresa:',
                                      garanteReferencia.empresaTrabajo ??
                                          'Sin registros'),
                                  _buildInfoRow(
                                      'Tipo garante-referencia:',
                                      listTipoGarRef
                                          .firstWhere(
                                            (tipo) =>
                                                tipo.codTipos ==
                                                garanteReferencia.tipo,
                                            orElse: () => TipoGarRef(
                                                codTipos: '',
                                                nombre: 'Sin registros',
                                                codGrupo: 12,
                                                listTipos: []),
                                          )
                                          .nombre
                                          .toUpperCase()),
                                  _buildInfoRow(
                                      'Observación:',
                                      garanteReferencia.observacion ??
                                          'Sin registros'),
                                  _buildInfoRow(
                                      'Empleado:',
                                      garanteReferencia.esEmpleado ??
                                          'Sin registros'),
                                  _buildInfoRow(
                                    'Telefonos:',
                                    garanteReferencia.telefonos?.isNotEmpty ==
                                            true
                                        ? garanteReferencia.telefonos!.join(
                                            '\n') // 🔹 Muestra cada número en una nueva línea
                                        : 'Sin registros',
                                  ),
                                  const Divider(),
                                ],
                              ),
                            ),
                            if (selectedOperation['perGarante'] == 'editar')
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Editar Garante-Referencia',
                                onPressed: () => _mostrarDialogoEdicionGarRef(
                                    garanteReferencia
                                        .codGarante!), // 🔹 Usa codGarante
                              ),
                            if (selectedOperation['perGarante'] == 'eliminar')
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  print(
                                      "📤 Eliminando garante con codGarante: ${garanteReferencia.codGarante}");
                                  final eliminado = await eliminarGarRef(
                                      garanteReferencia.codGarante!);
                                  if (eliminado) {
                                    setState(() {
                                      listGaranteReferencia.removeWhere((g) =>
                                          g.codGarante ==
                                          garanteReferencia.codGarante);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Garante eliminado correctamente.'),
                                          backgroundColor: Colors.green),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'No se pudo eliminar el garante.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                          ],
                        );
                      }).toList(),
                    )
                  : const Text('Sin registros',
                      style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  //metodo para eliminar GARANTE
  Future<bool> eliminarGarRef(int codGarante) async {
    // 🔹 Validar que el ID es válido antes de enviar la solicitud
    if (codGarante <= 0) {
      print("⚠️ Error: codGarante es inválido ($codGarante)");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Código de GARANTE inválido.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    print(
        "📤 Enviando solicitud para eliminar correo con codGarante: $codGarante");

    final bool resultado =
        await ObtenerEmpDepService().eliminarGarRef(codGarante);

    print("📤 Resultado de codGarante: $resultado");

    if (resultado) {
      try {
        setState(() {
          listGaranteReferencia.removeWhere((g) => g.codGarante == codGarante);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('✅ Garante eliminado correctamente: $codGarante'),
              backgroundColor: Colors.green),
        );
      } catch (e) {
        print("❌ Error en `setState()`: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar la lista: $e')),
        );
      }
      return true;
    } else {
      print("❌ No se pudo eliminar el garante con codGarante: $codGarante");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al eliminar el garante. Código: $codGarante'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

//MOSTRAR DIALOGO DE AGREGAR GARANTE REFERENCIA
  void _mostrarDialogoAgregarGarRef() {
    const int maxGarantes = 4; // establecer limite de gar/ref
    if (listGaranteReferencia.length >= maxGarantes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Solo se permite un máximo de $maxGarantes garantes/referencias.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    _limpiarFormularioGarRef();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('AGREGAR GARANTE REFERENCIA'),
          content: SingleChildScrollView(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (KeyEvent event) {
                if (kIsWeb &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    event is! KeyUpEvent) {
                  // Envolver la llamada en una función anónima async
                  validarYEnviarEnWeb(_formKey, () async {
                    await _guardarNuevoGaranteRef();
                  });
                }
              },
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //Botón para registrar nueva persona
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              "Registra una nueva persona si no está en la lista.",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.person_add, size: 20),
                            tooltip: 'Agregar nueva persona',
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _mostrarDialogoAgregarNuevaPersona(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (BuildContext innerContext) {
                        return DropdownSearch<Persona>(
                          items: listPersona,
                          itemAsString: (Persona? persona) =>
                              "${persona?.nombres ?? ''} ${persona?.apPaterno ?? ''} ${persona?.apMaterno ?? ''}",
                          onChanged: (Persona? selectedPersona) {
                            setState(() {
                              _personaSeleccionada = selectedPersona;
                            });
                          },
                          selectedItem: _personaSeleccionada,
                          dropdownDecoratorProps: const DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: "Buscar Persona",
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
                            emptyBuilder: (context, searchEntry) =>
                                const Center(
                              child: Text("No se encontraron resultados"),
                            ),
                            title: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Seleccionar Persona",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: controllers['direccionTrabajo'],
                      decoration: const InputDecoration(
                          labelText: 'Dirección Trabajo',
                          border: OutlineInputBorder()),
                      validator: (value) =>
                          validarTextoMixto(value, esObligatorio: true),
                      inputFormatters: bloquearEspacios,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllers['empresaTrabajo'],
                      decoration: const InputDecoration(
                          labelText: 'Empresa Trabajo',
                          border: OutlineInputBorder()),
                      validator: (value) =>
                          validarTextoMixto(value, esObligatorio: true),
                      inputFormatters: bloquearEspacios,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: listTipoGarRef.any((tipo) =>
                              tipo.codTipos == _garanteReferencia?.tipo)
                          ? _garanteReferencia?.tipo
                          : _tipoGarRefSeleccionado,
                      /* _tipoGarRefSeleccionado ??
                        _garanteReferencia?.tipo ??
                        (listTipoGarRef.isNotEmpty
                            ? listTipoGarRef.first.codTipos
                            : ""), // 🔥 Solución dentro del `value`*/
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Garante - Referencia',
                        border: OutlineInputBorder(),
                      ),
                      items: listTipoGarRef.map((tipo) {
                        return DropdownMenuItem<String>(
                          value: tipo.codTipos,
                          child: Text(tipo.nombre),
                        );
                      }).toList(),
                      onChanged: (value) {
                        _tipoGarRefSeleccionado = value;
                      },
                      validator: (value) =>
                          validarDropdown(value, 'Seleccione una opción'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controllers['observacion'],
                      decoration: const InputDecoration(
                          labelText: 'Observación',
                          border: OutlineInputBorder()),
                      validator: (value) =>
                          validarTextoOpcional(value, esObligatorio: true),
                      inputFormatters: bloquearEspacios,
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
                // Validación: no permitir duplicados de persona+tipo
                final personaId = _personaSeleccionada?.codPersona;
                final tipoSeleccionado = _tipoGarRefSeleccionado;
                final existeDuplicado = listGaranteReferencia.any((g) =>
                    g.codPersona == personaId && g.tipo == tipoSeleccionado);
                if (existeDuplicado) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Esta persona ya está registrada con este tipo de garante/referencia.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                _guardarNuevoGaranteRef();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

//MOSTRAR DIALOGO DE EDICION GARANTE REFERENCIA
  void _mostrarDialogoEdicionGarRef(int codGarante) {
    _garanteRefSeleccionada = listGaranteReferencia.firstWhere(
      (t) => t.codGarante == codGarante,
      orElse: () => GaranteReferencia(),
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildEditGaranteRefForm(
            context); // 🔹 Pass the required 'context' argument
      },
    );
  }

//SECCION RELACION LABORAL
  Widget _buildRelEmp() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RELACION LABORAL',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            // Mostrar formacion disponible
            listRelEmpEmpr.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: listRelEmpEmpr.map((relEmpEmpr) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                                'Cargo:',
                                relEmpEmpr.empleadoCargo?.cargoSucursal?.cargo
                                        ?.descripcion ??
                                    'Sin registros'),
                            _buildInfoRow(
                                'Fecha Inicio:',
                                relEmpEmpr.fechaIni != null
                                    ? formatearFecha(relEmpEmpr.fechaIni!)
                                    : 'Sin registros'),
                            _buildInfoRow(
                                'Tipo:', relEmpEmpr.tipoRel ?? 'Sin registros'),
                            const Divider(), // Separador entre registros
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : const Text('Sin registros',
                    style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

//editar datos personales
  Widget _buildEditForm() {
    //_actualizarControladoresPersona();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (KeyEvent event) {
          if (kIsWeb &&
              event.logicalKey == LogicalKeyboardKey.enter &&
              event is! KeyUpEvent) {
            validarYEnviarEnWeb(_formKey, _guardarDatosPersona);
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EDITAR DATOS PERSONALES',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controllers['nombres'],
                decoration: const InputDecoration(
                    labelText: 'NOMBRES', border: OutlineInputBorder()),
                validator: (value) =>
                    validarTextoOpcional(value, esObligatorio: true),
                inputFormatters: bloquearEspacios,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controllers['apPaterno'],
                decoration: const InputDecoration(
                    labelText: 'APELLIDO PATERNO',
                    border: OutlineInputBorder()),
                validator: (value) =>
                    validarTextoOpcional(value, esObligatorio: false),
                inputFormatters: bloquearEspacios,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controllers['apMaterno'],
                decoration: const InputDecoration(
                    labelText: 'APELLIDO MATERNO',
                    border: OutlineInputBorder()),
                validator: (value) =>
                    validarTextoOpcional(value, esObligatorio: false),
                inputFormatters: bloquearEspacios,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: listCiExpedido
                        .any((tipo) => tipo.codTipos == _persona?.ciExpedido)
                    ? _persona?.ciExpedido
                    : _ciExpedidoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'C.I EXPEDIDO',
                  border: OutlineInputBorder(),
                ),
                items: listCiExpedido.map((tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo.codTipos, // Código interno para selección
                    child: Text(tipo.nombre), // Muestra la descripción en la UI
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _ciExpedidoSeleccionado = value;
                  });
                },
                validator: (value) =>
                    validarDropdown(value, 'Seleccione una opción'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controllers['ciFechaVencimiento'],
                decoration: const InputDecoration(
                    labelText: 'FECHA DE VENCIMIENTO C.I',
                    border: OutlineInputBorder()),
                readOnly: true,
                onTap: () =>
                    _seleccionarFecha(context, controllers['ciFechaVencimiento']!),
                validator: validarFecha,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controllers['ciNumero'],
                decoration: const InputDecoration(
                    labelText: ' NRO CARNET DE IDENTIDAD',
                    border: OutlineInputBorder()),
                validator: (value) =>
                    validarSoloNumeros(value, esObligatorio: true),
                inputFormatters: bloquearEspacios,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controllers['direccion'],
                decoration: const InputDecoration(
                    labelText: 'DIRECCION', border: OutlineInputBorder()),
                validator: validarTextoMixto,
                inputFormatters: bloquearEspacios,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: listEstCivil
                        .any((tipo) => tipo.codTipos == _persona?.estadoCivil)
                    ? _persona?.estadoCivil
                    : _estadoCivilSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'ESTADO CIVIL',
                  border: OutlineInputBorder(),
                ),
                items: listEstCivil.map((tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo.codTipos, // Código interno para selección
                    child: Text(tipo.nombre), // Muestra la descripción en la UI
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _estadoCivilSeleccionado =
                        value; // Guarda solo el código en `_persona`
                  });
                },
                validator: (value) =>
                    validarDropdown(value, 'Seleccione una opción'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controllers['fechaNacimiento'],
                decoration: const InputDecoration(
                    labelText: 'FECHA DE  NACIMIENTO',
                    border: OutlineInputBorder()),
                readOnly: true,
                onTap: () =>
                    _seleccionarFecha(context, controllers['fechaNacimiento']!),
                validator: validarFecha,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controllers['lugarNacimiento'],
                decoration: const InputDecoration(
                    labelText: 'LUGAR DE NACIMIENTO',
                    border: OutlineInputBorder()),
                validator: (value) =>
                    validarTextoOpcional(value, esObligatorio: true),
                inputFormatters: bloquearEspacios,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: listPaises
                        .any((pais) => pais.codPais == _persona?.nacionalidad)
                    ? _persona?.nacionalidad
                    : _nacionalidadSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'NACIONALIDAD',
                  border: OutlineInputBorder(),
                ),
                items: listPaises.map((Pais pais) {
                  return DropdownMenuItem<int>(
                    value: pais.codPais, // Se usa el código del país
                    child: Text(pais.pais
                        .toString()), // Muestra el nombre del país (asegúrate de que 'pais' no sea nulo)
                  );
                }).toList(),
                onChanged: (int? value) {
                  setState(() {
                    _nacionalidadSeleccionado =
                        value; // Actualiza el valor seleccionado
                  });
                },
                validator: (value) =>
                    validarDropdown(value?.toString(), 'Seleccione una opción'),
              ),
              /*const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: listCiudades.any((ciudad) =>
                        ciudad.codCiudad == _persona?.ciudad?.codCiudad)
                    ? _persona?.ciudad?.codCiudad
                    : _nacionalidadSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'CIUDAD',
                  border: OutlineInputBorder(),
                ),
                items: listCiudades.map((Ciudades ciudad) {
                  return DropdownMenuItem<int>(
                    value: ciudad.codPais, // Se usa el código del país
                    child: Text(ciudad.ciudad
                        .toString()), // Muestra el nombre del país (asegúrate de que 'pais' no sea nulo)
                  );
                }).toList(),
                onChanged: (int? value) {
                  setState(() {
                    _ciudadSeleccionado =
                        value; // Actualiza el valor seleccionado
                  });
                },
              ),*/
              const SizedBox(height: 16),
              Builder(
                builder: (BuildContext innerContext) {
                  return DropdownSearch<Zona>(
                    items: listZonas,
                    itemAsString: (Zona? zona) => "${zona?.zona ?? ''}",
                    onChanged: (Zona? selectedZona) {
                      setState(() {
                        _zonaSeleccionado = selectedZona?.codZona;
                      });
                    },
                    selectedItem: listZonas.firstWhere(
                      (zona) =>
                          zona.codZona ==
                          (_zonaSeleccionado ?? _persona?.zona?.codZona),
                      orElse: () =>
                          Zona(codZona: 0, zona: _persona?.zona?.zona),
                    ),
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: "Buscar Zona",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    validator: (value) => validarSeleccionDropdownSearch(value),
                    popupProps: PopupProps.menu(
                      showSearchBox:
                          true, // Usa menú desplegable en lugar de bottomSheet
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
                value: _persona?.sexo,
                decoration: const InputDecoration(
                  labelText: 'GENERO',
                  border: OutlineInputBorder(),
                ),
                items: listGeneros.map((tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo.codTipos, // Código interno para selección
                    child: Text(
                        tipo.nombre ?? ''), // Muestra la descripción en la UI
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _generoSeleccionado = value;
                  });
                },
                validator: (value) =>
                    validarDropdown(value, 'Seleccione una opción'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _seleccionarUbicacion,
                child: const Text('SELECCIONE UNA UBICACION EN EL MAPA'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          // Opcional: reestablecer los controladores con los datos originales de _persona
                        });
                      },
                      child: const Text('CANCELAR'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _guardarDatosPersona,
                      child: const Text('GUARDAR'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

//SECCION FOTO
  Widget _buildFotoSeccion() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'FOTO',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_imageBytes != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.memory(
                      _imageBytes!,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _imageBytes = null),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.close, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(getImageUrl(
                    widget.codEmpleado)), // 🔹 Aquí se llama a `getImageUrl`
                onBackgroundImageError: (_, __) {
                  setState(() {
                    _imageBytes = null; // Si hay un error, se establece a null
                  });
                },
              ),
            const SizedBox(height: 16),
            if (_habilitarEdicion) // Solo muestra los botones si tiene permisos
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galería'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _uploadImage,
                    child: const Text('Subir Foto'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

//OBTENER IMAGEN DEL SERVIDOR
  String getImageUrl(int codEmpleado) {
    return "http://localhost:9223/fichaTrabajador/uploads/img/$codEmpleado.jpg?timestamp=$_imageTimestamp";
  }

//METODO PARA SUBIR UNA IMAGEN DE LA GALERIA
  Future<void> _pickImage() async {
    final result = await ImagePickerHelper.pickImage();
    if (result != null) {
      setState(() {
        _imageBytes = result.bytes;
      });
    }
  }

// Método para capturar una imagen con la cámara
  /* Future<void> _captureImage() async {
    final result = await ImagePickerHelper.captureImage();
    if (result != null) {
      setState(() {
        _imageBytes = result.bytes;
      });
    }
  }*/
// METODO PARA SUBIR IMAGEN AL SERVIDOR
  Future<void> _uploadImage() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, seleccione una imagen antes de subirla.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ObtenerEmpDepService().uploadImg(widget.codEmpleado, _imageBytes!);
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _imageTimestamp =
            DateTime.now().millisecondsSinceEpoch; // <-- Solo aquí
        _imageBytes =
            null; // Si quieres limpiar la imagen seleccionada, descomenta esto
      });
      EmpleadosDependientesViewState.imageVersion.value++;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagen subida exitosamente.'),
          backgroundColor: Colors.green,
        ),
      );
     
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir la imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

//CARGAR CIEXPEDIDO
  Future<void> _cargarCiExpedido() async {
    try {
      listCiExpedido = await ObtenerEmpDepService().obtenerCiExp();
      setState(() {}); // Actualiza la UI después de cargar los datos
    } catch (e) {
      // Manejo de errores si es necesario
    }
  }

//CARGAR ESTADO CIVIL
  Future<void> _cargarEstadoCivil() async {
    try {
      listEstCivil = await ObtenerEmpDepService().obtenerEstadoCivil();
      setState(() {}); // Actualiza la UI después de cargar los datos
    } catch (e) {
      // Manejo de errores si es necesario
    }
  }

//CARGAR PAISES
  Future<void> _cargarPaises() async {
    try {
      listPaises = await ObtenerEmpDepService().obtenerPais();
      setState(() {}); // Actualiza la UI después de cargar los datos
    } catch (e) {
      // Manejo de errores si es necesario
    }
  }

//CARGAR GENEROS
  Future<void> _cargarGenero() async {
    try {
      listGeneros = await ObtenerEmpDepService().obtenerGenero();
      setState(() {}); // Actualiza la UI después de cargar los datos
    } catch (e) {
      // Manejo de errores si es necesario
    }
  }

//CARGAR CIUDADES
  Future<void> _cargarCiudades() async {
    try {
      listCiudades =
          await ObtenerEmpDepService().obtenerCiudad(_persona!.pais!.codPais!);
      setState(() {}); // Actualiza la UI después de cargar los datos
    } catch (e) {
      // Manejo de errores si es necesario
    }
  }

//CARGAR ZONAS
  Future<void> _cargarZonas() async {
    try {
      listZonas = await ObtenerEmpDepService()
          .obtenerZona(_persona!.ciudad!.codCiudad!);
      setState(() {}); // Actualiza la UI después de cargar los datos
    } catch (e) {
      // Manejo de errores si es necesario
    }
  }

//CARGAR TIPO FORMACION
  Future<void> _cargarTipoFormacion() async {
    try {
      listTipoFormacion = await ObtenerEmpDepService().obtenerTipoFormacion();
      setState(() {}); // Actualiza la UI después de cargar los datos
    } catch (e) {
      // Manejo de errores si es necesario
    }
  }

//CARGAR TIPO DURACION FORMACION
  Future<void> _cargarTipoDuracionFor() async {
    try {
      listTipoDuracionFor =
          await ObtenerEmpDepService().obtenerTipoDuracionFor();
      setState(() {}); // Actualiza la UI después de cargar los datos
    } catch (e) {
      // Manejo de errores si es necesario
    }
  }

//CARGAR TIPO GARANTE REFERENCIA
  Future<void> _cargarTipoGarRef() async {
    try {
      listTipoGarRef = await ObtenerEmpDepService().obtenerTipoGaranteRef();
      setState(() {}); // Actualiza la UI después de cargar los datos
    } catch (e) {
      // Manejo de errores si es necesario
    }
  }

//CARGAR LISTA PERSONAS
  Future<void> _cargarListaPersonas() async {
    try {
      listPersona = await ObtenerEmpDepService().obtenerListaPersonas();
      setState(() {}); // Actualiza la UI después de cargar los datos
    } catch (e) {
      // Manejo de errores si es necesario
    }
  }

//CARGAR LISTA GARANTES REFERENCIA
  Future<void> _cargarListaGarRef() async {
    try {
      listGarRef = await ObtenerEmpDepService().obtenerListaGarRef();
      setState(() {}); // Actualiza la UI después de cargar los datos
    } catch (e) {
      // Manejo de errores si es necesario
    }
  }

//LIMPIAR FORMULARIO FORMACION
  void _limpiarFormularioFormacion() {
    // Reinicia el estado del formulario (esto limpia validaciones, etc.)
    _formKey.currentState?.reset();
    // Limpia cada TextEditingController
    controllers['descripcion']?.clear();
    controllers['duracion']?.clear();
    controllers['fechaFormacion']?.clear();
    // Reinicia las variables de los dropdowns
    _tipoDuracionForSeleccionada = null;
    _tipoFormacionSeleccionada = null;
    setState(() {}); // Refresca la UI si es necesario
  }

//LIMPIAR FORMULARIO TELEFONO
  void _limpiarFormularioTelefono() {
    // Reinicia el estado del formulario (esto limpia validaciones, etc.)
    _formKey.currentState?.reset();
    // Limpia cada TextEditingController
    controllers['telefono']?.clear();
    //dropdowns
    _tipoTelSeleccionado = null;
    setState(() {}); // Refresca la UI si es necesario
  }

  //LIMPIAR FORMULARIO CORREO
  void _limpiarFormularioCorreo() {
    // Reinicia el estado del formulario (esto limpia validaciones, etc.)
    _formKey.currentState?.reset();
    // Limpia cada TextEditingController
    controllers['email']?.clear();
    setState(() {}); // Refresca la UI si es necesario
  }

//LIMPIAR FORMULARIO EXPERIENCIA LABORAL
  void _limpiarFormularioExpLab() {
    // Reinicia el estado del formulario (esto limpia validaciones, etc.)
    _formKey.currentState?.reset();
    // Limpia cada TextEditingController
    controllers['descripcionExpLab']?.clear();
    controllers['nombreEmpresa']?.clear();
    controllers['cargo']?.clear();
    controllers['fechaInicio']?.clear();
    controllers['fechaFin']?.clear();
    controllers['nroReferencia']?.clear();
    setState(() {}); // Refresca la UI si es necesario
  }

//LIMPIAR FORMULARIO GARANTE REFERENCIA
  void _limpiarFormularioGarRef() {
    // Reinicia el estado del formulario (esto limpia validaciones, etc.)
    _formKey.currentState?.reset();
    // Limpia cada TextEditingController
    controllers['direccionTrabajo']?.clear();
    controllers['empresaTrabajo']?.clear();
    controllers['observacion']?.clear();
    //DROPDOWNS
    _tipoGarRefSeleccionado = null;
    _personaSeleccionada = null;
    setState(() {}); // Refresca la UI si es necesario
  }

//DESPLEGAR/OCULTAR SECCIONES
  void toggleSeccion(String seccion) {
    setState(() {
      estadoExpandido[seccion] = !estadoExpandido[seccion]!;
    });
  }

//BUILD SPEED DIAL
  Widget buildSpeedDial(
      {required String nombreSeccion,
      VoidCallback? onAgregar,
      VoidCallback? onEditar,
      VoidCallback? onEliminar,
      required void Function(String?)
          updateOperation, // 🔹 Permite actualizar `selectedOperation`
      List<String> operacionHabilitada = const ['editar']}) {
    return SpeedDial(
      visible: _habilitarEdicion,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) {
          return Transform.rotate(
            angle: value * 2 * 3.1416, // 🔹 Rota el icono completamente
            child: const Icon(Icons.settings, size: 26),
          );
        },
      ),
      buttonSize: const Size(38, 38),
      childrenButtonSize: const Size(32, 32),
      backgroundColor: Colors.teal,
      foregroundColor: Colors.white,
      overlayOpacity: 0.2,
      direction: SpeedDialDirection.down, //direccion de despliegue
      children: [
        if (operacionHabilitada.contains('agregar')) //solo muestra editar
          SpeedDialChild(
            child: const Icon(Icons.add, size: 24),
            //label: 'Agregar',
            backgroundColor: Colors.green,
            onTap: () {
              updateOperation((selectedOperation[nombreSeccion] == 'agregar')
                  ? null
                  : 'agregar'); // 🔹 Activa solo los botones de agregar
              onAgregar!();
            },
          ),
        if (operacionHabilitada.contains('editar'))
          SpeedDialChild(
            child: const Icon(Icons.edit, size: 24),
            //label: 'Editar',
            backgroundColor: Colors.blue,
            onTap: () {
              updateOperation((selectedOperation[nombreSeccion] == 'editar')
                  ? null
                  : 'editar'); // 🔹 Activa solo los botones de edición
              onEditar!();
            },
          ),
        if (operacionHabilitada.contains('eliminar'))
          SpeedDialChild(
            child: const Icon(Icons.delete, size: 24),
            //label: 'Eliminar',
            backgroundColor: Colors.redAccent,
            onTap: () {
              updateOperation((selectedOperation[nombreSeccion] == 'eliminar')
                  ? null
                  : 'eliminar'); // 🔹 Activa solo los botones de eliminación
              onEliminar!();
            },
          ),
        SpeedDialChild(
            child: const Icon(Icons.cancel, size: 24),
            backgroundColor: Colors.grey,
            onTap: () {
              updateOperation(null);
            }),
      ],
    );
  }

//MOSTRAR DIALOGO AGREGAR NUEVA PERSONA
  void _mostrarDialogoAgregarNuevaPersona(context) {
    _limpiarFormularioPersona();
    final nuevaPersonaFormKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Nueva Persona'),
          content: SingleChildScrollView(
            child: Form(
              key: nuevaPersonaFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: controllers['nombres'],
                    decoration: const InputDecoration(
                        labelText: 'Nombres', border: OutlineInputBorder()),
                    validator: (value) =>
                        validarTextoOpcional(value, esObligatorio: true),
                    inputFormatters: bloquearEspacios,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controllers['apPaterno'],
                    decoration: const InputDecoration(
                        labelText: 'Apellido Paterno',
                        border: OutlineInputBorder()),
                    validator: (value) =>
                        validarTextoOpcional(value, esObligatorio: false),
                    inputFormatters: bloquearEspacios,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controllers['apMaterno'],
                    decoration: const InputDecoration(
                        labelText: 'Apellido Materno',
                        border: OutlineInputBorder()),
                    validator: (value) =>
                        validarTextoOpcional(value, esObligatorio: false),
                    inputFormatters: bloquearEspacios,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controllers['ciNumero'],
                    decoration: const InputDecoration(
                        labelText: 'CI Número', border: OutlineInputBorder()),
                    validator: (value) =>
                        validarSoloNumeros(value, esObligatorio: true),
                    inputFormatters: bloquearEspacios,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _ciExpedidoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'CI Expedido',
                      border: OutlineInputBorder(),
                    ),
                    items: listCiExpedido.map((tipo) {
                      return DropdownMenuItem<String>(
                        value: tipo.codTipos,
                        child: Text(tipo.nombre),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _ciExpedidoSeleccionado = value;
                      });
                    },
                    validator: (value) =>
                        validarDropdown(value, 'Seleccione CI Expedido'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controllers['direccion'],
                    decoration: const InputDecoration(
                        labelText: 'Dirección', border: OutlineInputBorder()),
                    validator: (value) =>
                        validarTextoMixto(value, esObligatorio: true),
                    inputFormatters: bloquearEspacios,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controllers['fechaNacimiento'],
                    decoration: const InputDecoration(
                        labelText: 'Fecha de Nacimiento',
                        border: OutlineInputBorder()),
                    readOnly: true,
                    onTap: () =>
                        _seleccionarFecha(context, controllers['fechaNacimiento']!),
                    validator: validarFecha,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controllers['lugarNacimiento'],
                    decoration: const InputDecoration(
                        labelText: 'Lugar de Nacimiento',
                        border: OutlineInputBorder()),
                    validator: (value) =>
                        validarTextoOpcional(value, esObligatorio: true),
                    inputFormatters: bloquearEspacios,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controllers['ciFechaVencimiento'],
                    decoration: const InputDecoration(
                        labelText: 'Ci Fecha Vencimiento',
                        border: OutlineInputBorder()),
                    readOnly: true,
                    onTap: () => _seleccionarFecha(
                        context, controllers['ciFechaVencimiento']!),
                    validator: validarFecha,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _nacionalidadSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Nacionalidad',
                      border: OutlineInputBorder(),
                    ),
                    items: listPaises.map((Pais pais) {
                      return DropdownMenuItem<int>(
                        value: pais.codPais,
                        child: Text(pais.pais.toString()),
                      );
                    }).toList(),
                    onChanged: (int? value) {
                      setState(() {
                        _nacionalidadSeleccionado = value;
                      });
                    },
                    validator: (value) => validarDropdown(
                        value?.toString(), 'Seleccione nacionalidad'),
                  ),
                  const SizedBox(height: 16),

                  // Agregar DropdownSearch para Zona
                  Builder(
                    builder: (BuildContext innerContext) {
                      return DropdownSearch<Zona>(
                        items: listZonas,
                        itemAsString: (Zona? zona) => "${zona?.zona ?? ''}",
                        onChanged: (Zona? selectedZona) {
                          setState(() {
                            _zonaSeleccionado = selectedZona?.codZona;
                          });
                        },
                        dropdownDecoratorProps: const DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: "Buscar Zona",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        validator: (value) =>
                            validarSeleccionDropdownSearch(value),
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              labelText: "Buscar",
                              border: OutlineInputBorder(),
                            ),
                            inputFormatters: bloquearEspacios,
                          ),
                          emptyBuilder: (context, searchEntry) => const Center(
                            child: Text("No se encontraron resultados"),
                          ),
                          title: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Seleccionar Zona"),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _estadoCivilSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Estado civil',
                      border: OutlineInputBorder(),
                    ),
                    items: listEstCivil.map((tipo) {
                      return DropdownMenuItem<String>(
                        value: tipo.codTipos, // Código interno para selección
                        child: Text(
                            tipo.nombre), // Muestra la descripción en la UI
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _estadoCivilSeleccionado =
                            value; // Guarda solo el código en `_persona`
                      });
                    },
                    validator: (value) =>
                        validarDropdown(value, 'Seleccione estado civil'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _generoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Género',
                      border: OutlineInputBorder(),
                    ),
                    items: listGeneros.map((sexo) {
                      return DropdownMenuItem<String>(
                        value: sexo.codTipos,
                        child: Text(sexo.nombre ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _generoSeleccionado = value;
                      });
                    },
                    validator: (value) =>
                        validarDropdown(value, 'Seleccione una opción'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _seleccionarUbicacion,
                    child: const Text('Seleccionar Ubicación en el Mapa'),
                  ),
                  const SizedBox(height: 16),
                ],
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
                if (nuevaPersonaFormKey.currentState?.validate() ?? false) {
                  _guardarNuevaPersona();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

//VERIFICAR PERMISOS DE EDICION
  Future<void> _verificarPermisosEdicion() async {
    try {
      final int? codEmpleadoLocal = await _localStorageService.getCodEmpleado();
      bool habilitarEdicion = false;

      if (codEmpleadoLocal == null) {
        setState(() {
          _habilitarEdicion = false;
        });
        return;
      }

      // 1. Obtener el codPersona del usuario autenticado
      //final empleadosLocal = await ObtenerEmpDepService().obtenerDatosEmp(widget.codEmpleado);
      // int? codPersonaLocal = empleadosLocal.isNotEmpty ? empleadosLocal.first.codPersona : null;

      // 2. Obtener el codPersona del empleado de la ventana
      // final empleadosVentana = await ObtenerEmpDepService().obtenerPersona(_persona!.codPersona!);
      //int? codPersonaVentana = empleadosVentana.codPersona;

      // ---- AQUI VAN LOS PRINTS ----
      print(await _localStorageService.getCodEmpleado());
      print('widget.codEmpleado: ${widget.codEmpleado}');
      print('codEmpleadoLocal: $codEmpleadoLocal');
      //print('codPersonaLocal: $codPersonaLocal');
      //print('codPersonaVentana: $codPersonaVentana');
      // -----------------------------

      // 3. Comparar codEmpleado y codPersona
      if (widget.codEmpleado == codEmpleadoLocal
          // ||(codPersonaLocal != null && codPersonaVentana != null && codPersonaLocal == codPersonaVentana)
          ) {
        habilitarEdicion = true;
      }

      setState(() {
        _habilitarEdicion = habilitarEdicion;
      });
    } catch (e) {
      print('Error al verificar permisos de edición: $e');
      setState(() {
        _habilitarEdicion = false;
      });
    }
  }

  Future<void> _guardarNuevaFormacion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Aquí puedes agregar la lógica para guardar el nuevo teléfono
    final nuevaFormacion = Formaciones(
      codFormacion: 0,
      codEmpleado: widget
          .codEmpleado, // Asigna un valor por defecto o maneja esto según tu lógica
      descripcion: controllers['descripcion']?.text.trim() ?? '',
      duracion: int.tryParse(controllers['duracion']?.text.trim() ?? ''),
      tipoDuracion: _tipoDuracionForSeleccionada,
      tipoFormacion: _tipoFormacionSeleccionada,
      fechaFormacion: DateFormat('dd-MM-yyyy')
          .parse(controllers['fechaFormacion']?.text.trim() ?? ''),
      audUsuario: await _localStorageService.getCodUsuario(),
    );
    // Llama a tu método para guardar el nuevo teléfono
    try {
      await ObtenerEmpDepService().registrarFormacion(nuevaFormacion);
      final formacionActualizada = await ObtenerEmpDepService()
          .obtenerFormacion(
              widget.codEmpleado); //refrescar lista sin afectar a la pantalla

      setState(() {
        listFormacion = formacionActualizada;
      });
      Navigator.pop(context); // Cierra el diálogo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formación guardada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la formación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

//guardar nuevo garante refencia
  Future<void> _guardarNuevoGaranteRef() async {
    if (!_formKey.currentState!.validate()) return;

    final nuevoGaranteReferencia = GaranteReferencia(
      codGarante: 0,
      codPersona: _personaSeleccionada?.codPersona ??
          _garanteRefSeleccionada!.codPersona,
      codEmpleado: widget.codEmpleado,
      direccionTrabajo: controllers['direccionTrabajo']?.text.trim(),
      empresaTrabajo: controllers['empresaTrabajo']?.text.trim(),
      tipo: _tipoGarRefSeleccionado,
      observacion: controllers['observacion']?.text.trim(),
      audUsuario: await _localStorageService.getCodUsuario(),
    );

    try {
      await ObtenerEmpDepService()
          .registrarGaranteReferencia(nuevoGaranteReferencia);
      final garanteActualizado = await ObtenerEmpDepService()
          .obtenerGaranteReferencia(widget.codEmpleado);

      setState(() {
        listGaranteReferencia =
            garanteActualizado; // 🔥 Refresca la lista sin recargar toda la UI
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Garante-Referencia guardado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el Garante-Referencia: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

//guardar nuevo Correo
  Future<void> _guardarNuevoCorreo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Aquí puedes agregar la lógica para guardar el nuevo correo
    final nuevoCorreo = Email(
      codEmail: 0, // Asigna un valor por defecto o maneja esto según tu lógica
      email: controllers['email']?.text.trim(),
      codPersona: _persona?.codPersona,
      audUsuario: await _localStorageService.getCodUsuario(),
    );
    // Llama a tu método para guardar el nuevo correo
    try {
      await ObtenerEmpDepService().registrarEmail(nuevoCorreo);
      //await _cargarDatosCorreo(); // Carga los datos actualizados

      final correoActualizado = await ObtenerEmpDepService().obtenerEmail(_persona!
          .codPersona!); // 🔹 Solo refrescamos la lista sin afectar el resto de la pantalla

      setState(() {
        listCorreo = correoActualizado; // Agrega el nuevo correo a la lista
      });
      Navigator.pop(context); // Cierra el diálogo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correo guardado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el correo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // _guardarDatosCorreo(nuevoCorreo); // 🔹 Método para guardar el nuevo correo
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

  //guardar nuevo telefono
  Future<void> _guardarNuevoTelefono() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      // Si hay errores de validación, no continúa
      return;
    }

    final nuevoTelefono = Telefono(
      codTelefono: 0, // Para indicar que es una nueva inserción
      codPersona: _persona?.codPersona, // Usar el codPersona actual
      codTipoTel:
          _tipoTelSeleccionado, // Convertir el tipo seleccionado a su código
      telefono: controllers['telefono']?.text.trim(),
      audUsuario: await _localStorageService.getCodUsuario(),
    );

    try {
      await ObtenerEmpDepService().registrarTelefono(nuevoTelefono);
      final telefonoActualizado = await ObtenerEmpDepService().obtenerTelefono(
          _persona!.codPersona!); // Refrescar la lista de teléfonos
      setState(() {
        listTelefono = telefonoActualizado; // Actualizar la lista de teléfonos
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teléfono agregado correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar el teléfono: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  //GUARDAR NUEVA EXPERIENCIA LABORAL
  Future<void> _guardarNuevaExpLab() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Aquí puedes agregar la lógica para guardar el nuevo teléfono
    final nuevaExpLaboral = ExperienciaLaboral(
      codExperienciaLaboral: 0,
      codEmpleado: widget.codEmpleado,
      nombreEmpresa: controllers['nombreEmpresa']?.text.trim() ?? '',
      cargo: controllers['cargo']?.text.trim() ?? '',
      descripcion: controllers['descripcion']?.text.trim() ?? '',
      fechaInicio: DateFormat('dd-MM-yyyy')
          .parse(controllers['fechaInicio']?.text.trim() ?? ''),
      fechaFin: DateFormat('dd-MM-yyyy')
          .parse(controllers['fechaFin']?.text.trim() ?? ''),
      nroReferencia: controllers['nroReferencia']?.text.trim() ?? '',
      audUsuario: await _localStorageService.getCodUsuario(),
    );
    print(nuevaExpLaboral.toJson());
    // Llama a tu método para guardar el nuevo teléfono
    try {
      await ObtenerEmpDepService().registrarExpLaboral(nuevaExpLaboral);
      final expLabActualizada = await ObtenerEmpDepService()
          .obtenerExperienciaLaboral(widget.codEmpleado);

      setState(() {
        listExpLaboral = expLabActualizada;
      });
      Navigator.pop(context); // Cierra el diálogo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Experiencia Laboral guardada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la experiencia laboral: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  //guardar nueva persona
  Future<void> _guardarNuevaPersona() async {
    /*if (!_formKey.currentState!.validate()) {
      return;
    }*/
    
    final nuevaPersona = Persona(
      codPersona: 0,
      codZona:
          _zonaSeleccionado, 
      nombres: controllers['nombres']?.text.trim(),
      apPaterno: controllers['apPaterno']?.text.trim(),
      apMaterno: controllers['apMaterno']?.text.trim(),
      ciExpedido: controllers['ciExpedido']?.text.trim(),
      ciFechaVencimiento: DateFormat('dd-MM-yyyy')
                .parse(controllers['ciFechaVencimiento']?.text.trim()??''),
      ciNumero: controllers['ciNumero']?.text.trim(),
      direccion: controllers['direccion']?.text.trim(),
      estadoCivil: _estadoCivilSeleccionado,
      fechaNacimiento: DateFormat('dd-MM-yyyy')
                .parse(controllers['fechaNacimiento']?.text.trim()??''),
      lugarNacimiento: controllers['lugarNacimiento']?.text.trim(),
      nacionalidad:
          _nacionalidadSeleccionado, 
      sexo: _generoSeleccionado,
      //lat: double.tryParse(controllers['lat']?.text.trim() ?? ''),
      //lng: double.tryParse(controllers['lng']?.text.trim() ?? ''),
      lat:double.tryParse(controllers['lat']?.text.trim() ?? '0.0') ?? 0.0,
      lng: double.tryParse(controllers['lng']?.text.trim() ?? '0.0') ?? 0.0,
      audUsuarioI: await _localStorageService.getCodUsuario(),
    );
    print(nuevaPersona.toJson());

    // Llama a tu método para guardar el nuevo correo
    try {
      await ObtenerEmpDepService().registrarPersona(nuevaPersona);
      

      final personaActualizada = await ObtenerEmpDepService().obtenerListaPersonas(); // 🔹 Solo refrescamos la lista sin afectar el resto de la pantalla

      setState(() {
        listPersona = personaActualizada; // Agrega el nuevo correo a la lista
      });
      Navigator.pop(context); // Cierra el diálogo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Persona registrada correctamente'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar persona: $e'),
        ),
      );
    }

    // _guardarDatosCorreo(nuevoCorreo); // 🔹 Método para guardar el nuevo correo
  }

  //LIMPIAR FORMULARIO PERSONA
  void _limpiarFormularioPersona() {
    // Reinicia el estado del formulario (esto limpia validaciones, etc.)
    //_formKey.currentState?.reset();
    // Limpia cada TextEditingController
    controllers['nombres']?.clear();
    controllers['apPaterno']?.clear();
    controllers['apMaterno']?.clear();
    controllers['ciNumero']?.clear();
    controllers['direccion']?.clear();
    controllers['lugarNacimiento']?.clear();
    controllers['fechaNacimiento']?.clear();
    controllers['ciFechaVencimiento']?.clear();
    controllers['lat']?.clear();
    controllers['lng']?.clear();
    // Reinicia las variables de los dropdowns
    _ciExpedidoSeleccionado = null;
    _nacionalidadSeleccionado = null;
    _generoSeleccionado = null;
    _estadoCivilSeleccionado = null;
    _zonaSeleccionado = null;
    setState(() {}); // Refresca la UI si es necesario
  }
}*/
