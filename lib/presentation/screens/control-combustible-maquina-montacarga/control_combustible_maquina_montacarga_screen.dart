import 'package:bosque_flutter/core/state/control_combustible_maquina_montacarga_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bosque_flutter/domain/entities/control_combustible_maquina_montacarga_entity.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';

class ControlCombustibleMaquinaMontacargaScreen extends ConsumerStatefulWidget {
  const ControlCombustibleMaquinaMontacargaScreen({super.key});

  @override
  ConsumerState<ControlCombustibleMaquinaMontacargaScreen> createState() =>
      _ControlCombustibleMaquinaMontacargaScreenState();
}

class _ControlCombustibleMaquinaMontacargaScreenState
    extends ConsumerState<ControlCombustibleMaquinaMontacargaScreen> {
  // Controladores para los campos del formulario
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _litrosIngresoController =
      TextEditingController();
  final TextEditingController _litrosSalidaController = TextEditingController();
  final TextEditingController _saldoLitrosController = TextEditingController();
  final TextEditingController _obsController = TextEditingController();
  final TextEditingController _horometroController = TextEditingController();

  // Variables para almacenar las selecciones de dropdown
  ControlCombustibleMaquinaMontacargaEntity? _selectedMaquina;
  ControlCombustibleMaquinaMontacargaEntity? _selectedAlmacen;

  // Fecha seleccionada
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Inicializar la fecha con la fecha actual
    _fechaController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Inicializar campos numéricos con ceros
    _litrosIngresoController.text = '0.0';
    _litrosSalidaController.text = '0.0';
    _saldoLitrosController.text = '0.0';

    // Cargar datos al iniciar la pantalla
    Future.microtask(
      () =>
          ref
              .read(
                controlCombustibleMaquinaMontacargaNotifierProvider.notifier,
              )
              .cargarDatosIniciales(),
    );
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _litrosIngresoController.dispose();
    _litrosSalidaController.dispose();
    _saldoLitrosController.dispose();
    _obsController.dispose();
    _horometroController.dispose();
    super.dispose();
  }



  void _registrarControlCombustible() async {
    // Validaciones del formulario
    if (_selectedMaquina == null || _selectedAlmacen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar máquina y almacén')),
      );
      return;
    }

    // Validación para litros ingreso (debe ser mayor a cero)
    double litrosIngreso = double.tryParse(_litrosIngresoController.text) ?? 0.0;
    if (litrosIngreso <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Litros de ingreso debe ser mayor a cero')),
      );
      return;
    }

    // Validación para litros salida (puede ser cero o mayor)
    double litrosSalida = double.tryParse(_litrosSalidaController.text) ?? 0.0;
    if (litrosSalida < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Litros de salida no puede ser negativo')),
      );
      return;
    }

    // Validación para horómetro (puede ser cero o mayor)
    double horometro = double.tryParse(_horometroController.text) ?? 0.0;
    if (horometro < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horómetro no puede ser negativo')),
      );
      return;
    }

    // Obtener codEmpleado y codUsuario del UserProvider
    final userNotifier = ref.read(userProvider.notifier);
    final codEmpleado = await userNotifier.getCodEmpleado();
    final codUsuario = await userNotifier.getCodUsuario();

    // Construir la entidad con los datos del formulario
    // Construir la entidad con los datos del formulario
  final controlCombustible = ControlCombustibleMaquinaMontacargaEntity(
    idCM: 0,
    idMaquina: _selectedMaquina!.idMaquina,
    fecha: _selectedDate,
    litrosIngreso: double.tryParse(_litrosIngresoController.text) ?? 0.0,
    litrosSalida: double.tryParse(_litrosSalidaController.text) ?? 0.0,
    saldoLitros: 0.0,
    horasUso: 0.0,
    horometro: double.tryParse(_horometroController.text) ?? 0.0,
    codEmpleado: codEmpleado,
    codAlmacen: _selectedAlmacen!.whsCode, // Usamos whsCode directamente como String
    obs: _obsController.text,
    audUsuario: codUsuario,
    whsCode: _selectedAlmacen!.whsCode,
    whsName: _selectedAlmacen!.whsName,
    maquina: "",
    nombreCompleto: "",
  );
  

    // Llamar al método del notifier para registrar
    ref
        .read(controlCombustibleMaquinaMontacargaNotifierProvider.notifier)
        .registrarControlCombustible(controlCombustible);
  }

  // Función para resetear el formulario
  void _resetForm() {
    setState(() {
      _litrosIngresoController.text = '0.0';
      _litrosSalidaController.text = '0.0';
      _horometroController.text = '0.0';
      _obsController.text = '';
      _selectedMaquina = null;
      _selectedAlmacen = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Observar el estado
    final state = ref.watch(
      controlCombustibleMaquinaMontacargaNotifierProvider,
    );

    // Determinar si está cargando cualquier dato
    final isLoading =
        state.almacenesStatus == FetchStatus.loading ||
        state.maquinasStatus == FetchStatus.loading ||
        state.registroStatus == RegistroStatus.loading;
    
    // Verificar si el registro fue exitoso para resetear el formulario y mostrar SnackBar
    if (state.registroStatus == RegistroStatus.success) {
      Future.microtask(() {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro completado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
        ref.read(controlCombustibleMaquinaMontacargaNotifierProvider.notifier).resetRegistroStatus();
      });
    } else if (state.registroStatus == RegistroStatus.error && state.errorMessage != null) {
      Future.microtask(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(controlCombustibleMaquinaMontacargaNotifierProvider.notifier).resetRegistroStatus();
      });
    }

    // Obtener dimensiones responsivas
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final isTablet = ResponsiveUtilsBosque.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Combustible Máquina/Montacarga'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding, 
            vertical: verticalPadding
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Cambiado de max a min para evitar error de constraints
            children: [
              // Tarjeta para el formulario
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Cambiado de max a min
                    children: [
                      Text(
                        'Registro de Control de Combustible',
                        style: ResponsiveUtilsBosque.getTitleStyle(context),
                      ),
                      SizedBox(height: verticalPadding),

                      // Mostrar mensajes de éxito
                      if (state.registroStatus == RegistroStatus.success)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Registro completado con éxito',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Mostrar mensajes de error de manera más amigable
                      if (state.errorMessage != null &&
                          (state.registroStatus == RegistroStatus.error ||
                              state.almacenesStatus == FetchStatus.error ||
                              state.maquinasStatus == FetchStatus.error))
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade300, width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  state.errorMessage?.contains('Error al obtener') == true
                                    ? 'No se encontraron resultados. Intente con otra selección.'
                                    : 'Error: ${state.errorMessage}',
                                  style: TextStyle(color: Colors.orange[800]),
                                ),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(height: verticalPadding),

                      // Dropdown para selección de máquina/montacarga
                      DropdownButtonFormField<
                        ControlCombustibleMaquinaMontacargaEntity
                      >(
                        decoration: InputDecoration(
                          labelText: 'Máquina/Montacarga',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.engineering),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding * 0.75, 
                            vertical: 16
                          ),
                        ),
                        value: _selectedMaquina,
                        items: state.maquinasMontacarga.map((maquina) {
                          return DropdownMenuItem(
                            value: maquina,
                            child: Text('${maquina.idMaquina} - ${maquina.whsCode} (${maquina.whsName})'),
                          );
                        }).toList(),
                        onChanged: isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedMaquina = value;
                                });
                              },
                        isExpanded: true,
                        hint: const Text('Seleccione una máquina'),
                      ),
                      
                      SizedBox(height: verticalPadding),

                      // Fila para litros de ingreso y salida con diseño responsivo
                      Flex(
                        direction: (isDesktop || isTablet) ? Axis.horizontal : Axis.vertical,
                        mainAxisSize: MainAxisSize.min, // Cambiado de max a min
                        children: [
                          Flexible(
                            fit: FlexFit.loose,
                            child: TextField(
                              controller: _litrosIngresoController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Litros Ingreso',
                                border: OutlineInputBorder(),
                                suffixText: 'L',
                              ),
                            ),
                          ),
                          SizedBox(width: (isDesktop || isTablet) ? 16 : 0, height: (isDesktop || isTablet) ? 0 : 16),
                          Flexible(
                            fit: FlexFit.loose,
                            child: TextField(
                              controller: _litrosSalidaController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Litros Salida',
                                border: OutlineInputBorder(),
                                suffixText: 'L',
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: verticalPadding),
                      
                      // Campo de horómetro
                      TextField(
                        controller: _horometroController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Horómetro',
                          border: OutlineInputBorder(),
                          suffixText: 'hrs',
                        ),
                      ),
                      
                      SizedBox(height: verticalPadding),

                      // Dropdown para selección de almacén
                      DropdownButtonFormField<
                        ControlCombustibleMaquinaMontacargaEntity
                      >(
                        decoration: InputDecoration(
                          labelText: 'Almacén',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.warehouse),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding * 0.75, 
                            vertical: 16
                          ),
                        ),
                        value: _selectedAlmacen,
                        items: state.almacenes.map((almacen) {
                          return DropdownMenuItem(
                            value: almacen,
                            child: Text('${almacen.whsCode} - ${almacen.whsName}'),
                          );
                        }).toList(),
                        onChanged: isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedAlmacen = value;
                                });
                              },
                        isExpanded: true,
                        hint: const Text('Seleccione un almacén'),
                      ),
                      
                      SizedBox(height: verticalPadding),

                      // Observaciones
                      TextField(
                        controller: _obsController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      
                      SizedBox(height: verticalPadding * 1.5),

                      // Indicador de carga para cargar datos iniciales
                      if (state.almacenesStatus == FetchStatus.loading ||
                          state.maquinasStatus == FetchStatus.loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),

                      // Botón de registro
                      SizedBox(
                        width: double.infinity,
                        height: isDesktop ? 52 : 48,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _registrarControlCombustible,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: state.registroStatus == RegistroStatus.loading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'REGISTRAR CONTROL DE COMBUSTIBLE',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: ResponsiveUtilsBosque.getResponsiveValue<double>(
                                    context: context,
                                    defaultValue: 14.0,
                                    mobile: 13.0,
                                    desktop: 15.0,
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
