import 'package:bosque_flutter/domain/entities/maquina_montacarga_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/control_combustible_maquina_montacarga_provider.dart';
import 'package:bosque_flutter/domain/entities/control_combustible_maquina_montacarga_entity.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:intl/intl.dart';

class ControlCombustibleMaquinaMontacargaScreen extends ConsumerStatefulWidget {
  const ControlCombustibleMaquinaMontacargaScreen({super.key});

  @override
  ConsumerState<ControlCombustibleMaquinaMontacargaScreen> createState() =>
      _ControlCombustibleMaquinaMontacargaScreenState();
}

class _ControlCombustibleMaquinaMontacargaScreenState
    extends ConsumerState<ControlCombustibleMaquinaMontacargaScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for text fields
  final _fechaController = TextEditingController();
  final _litrosIngresoController = TextEditingController();
  final _litrosSalidaController = TextEditingController();
  final _obsController = TextEditingController();

  // Dropdown values
  String? _selectedMaquinaOrigen;
  String? _selectedMaquinaDestino;
  String? _selectedAlmacen;

  // Add a variable to store the actual DateTime
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Format the initial date in dd/MM/yyyy format
    _fechaController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(controlCombustibleMaquinaMontacargaNotifierProvider.notifier)
          .cargarMaquinasMontacargas();
      ref.read(controlCombustibleMaquinaMontacargaNotifierProvider.notifier)
          .cargarAlmacenes();
    });
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _litrosIngresoController.dispose();
    _litrosSalidaController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(controlCombustibleMaquinaMontacargaNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Registro de Entradas y Salidas de Combustible por Bidones',
          style: ResponsiveUtilsBosque.getTitleStyle(context),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: ResponsiveUtilsBosque.isDesktop(context) ? 2 : 4,
        actions: [
          IconButton(
            onPressed: () => _mostrarInstrucciones(context, colorScheme),
            icon: const Icon(Icons.info_outline),
            tooltip: 'Ver instrucciones',
          ),
        ],
      ),
      body: ResponsiveUtilsBosque.isDesktop(context)
          ? _buildDesktopLayout(context, state, colorScheme)
          : _buildMobileLayout(context, state, colorScheme),
    );
  }

  void _mostrarInstrucciones(BuildContext context, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Instrucciones de Uso',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstruccionItem(
                  '1.',
                  'Traspasos entre un Vehículo a Bidón es un Ingreso',
                  colorScheme,
                  Icons.arrow_forward,
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildInstruccionItem(
                  '2.',
                  'Traspaso entre bidones es un "Traspaso"',
                  colorScheme,
                  Icons.swap_horiz,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildInstruccionItem(
                  '3.',
                  'Traspaso a una máquina o montacarga es una "Salida"',
                  colorScheme,
                  Icons.arrow_back,
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildInstruccionItem(
                  '4.',
                  'Para hacer un traspaso entre un bidón de una sucursal X a una sucursal Y primero se debe hacer o registrar una salida y luego una entrada',
                  colorScheme,
                  Icons.location_on,
                  Colors.purple,
                ),
                const SizedBox(height: 12),
                _buildInstruccionItem(
                  '5.',
                  'No existe un traspaso entre Vehículo a montacarga o máquina o viceversa',
                  colorScheme,
                  Icons.block,
                  Colors.red,
                ),
                const SizedBox(height: 12),
                _buildInstruccionItem(
                  '6.',
                  'Los bidones pueden transferir a cualquier sucursal',
                  colorScheme,
                  Icons.location_city,
                  Colors.teal,
                ),
                const SizedBox(height: 12),
                _buildInstruccionItem(
                  '7.',
                  'Los vehículos solo pueden transferir dentro de la misma sucursal',
                  colorScheme,
                  Icons.local_shipping,
                  Colors.indigo,
                ),
                const SizedBox(height: 12),
                _buildInstruccionItem(
                  '8.',
                  'Complete los litros de ingreso y salida según corresponda',
                  colorScheme,
                  Icons.local_gas_station,
                  Colors.brown,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tip: Seleccione primero la máquina origen para habilitar las opciones de destino disponibles.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onPrimaryContainer,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Importante: Para traspasos entre sucursales, registre primero una SALIDA en la sucursal origen y luego un INGRESO en la sucursal destino.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Entendido',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  Widget _buildInstruccionItem(
    String numero,
    String texto,
    ColorScheme colorScheme,
    IconData icon,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: iconColor.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              numero,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, RegistroState state, ColorScheme colorScheme) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: EdgeInsets.all(ResponsiveUtilsBosque.getHorizontalPadding(context)),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Registro de Control de Combustible',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildForm(context, state, colorScheme),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, RegistroState state, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveUtilsBosque.getHorizontalPadding(context)),
      child: _buildForm(context, state, colorScheme),
    );
  }

  Widget _buildForm(BuildContext context, RegistroState state, ColorScheme colorScheme) {
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fecha - Convert to a simple read-only display field
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surfaceVariant.withOpacity(0.3),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: isDesktop ? 24 : 16),
          
          // Row for dropdowns on desktop, column on mobile
          if (isDesktop)
            Row(
              children: [
                Expanded(child: _buildMaquinaOrigenDropdown(state, colorScheme)),
                const SizedBox(width: 16),
                Expanded(child: _buildMaquinaDestinoDropdown(state, colorScheme)),
              ],
            )
          else ...[
            _buildMaquinaOrigenDropdown(state, colorScheme),
            SizedBox(height: isDesktop ? 24 : 16),
            _buildMaquinaDestinoDropdown(state, colorScheme),
          ],
          
          SizedBox(height: isDesktop ? 24 : 16),
          
          // Almacén
          _buildAlmacenDropdown(state, colorScheme),
          
          SizedBox(height: isDesktop ? 24 : 16),
          
          // Row for liters on desktop, column on mobile
          if (isDesktop)
            Row(
              children: [
                Expanded(child: _buildLitrosIngresoField(colorScheme)),
                const SizedBox(width: 16),
                Expanded(child: _buildLitrosSalidaField(colorScheme)),
              ],
            )
          else ...[
            _buildLitrosIngresoField(colorScheme),
            SizedBox(height: isDesktop ? 24 : 16),
            _buildLitrosSalidaField(colorScheme),
          ],
          
          SizedBox(height: isDesktop ? 24 : 16),
          
          // Observaciones
          _buildObservacionesField(colorScheme),
          
          SizedBox(height: isDesktop ? 32 : 24),
          
          // Botón de registro
          _buildSubmitButton(state, colorScheme, isDesktop),
          
          // Mostrar mensaje de error
          if (state.errorMessage != null)
            Padding(
              padding: EdgeInsets.only(top: isDesktop ? 24 : 16),
              child: _buildErrorMessage(state.errorMessage!, colorScheme),
            ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ColorScheme colorScheme,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    String? suffixText,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        suffixIcon: Icon(icon, color: colorScheme.primary),
        suffixText: suffixText,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      style: TextStyle(color: colorScheme.onSurface),
    );
  }

  Widget _buildMaquinaOrigenDropdown(RegistroState state, ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      value: _selectedMaquinaOrigen,
      decoration: InputDecoration(
        labelText: 'Máquina/Vehículo Origen',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      isExpanded: true,
      items: state.maquinasMontacarga.asMap().entries.map((entry) {
        int index = entry.key;
        var maquina = entry.value;
        String uniqueId = '${index}_${maquina.idMaquina}_${maquina.codigo}';
        
        String displayText = maquina.maquinaOVehiculo.isNotEmpty 
            ? maquina.maquinaOVehiculo 
            : '${maquina.codigo} - ${maquina.nombreSucursal}';
        
        return DropdownMenuItem<String>(
          value: uniqueId,
          child: Tooltip(
            message: displayText,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                displayText,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSurface),
                maxLines: 1,
              ),
            ),
          ),
        );
      }).toList(),
      onChanged: state.maquinasStatus == FetchStatus.loading 
          ? null 
          : (value) {
              setState(() {
                _selectedMaquinaOrigen = value;
                _selectedMaquinaDestino = null;
              });
            },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor seleccione una máquina origen';
        }
        return null;
      },
      dropdownColor: colorScheme.surface,
      style: TextStyle(color: colorScheme.onSurface),
    );
  }

  Widget _buildMaquinaDestinoDropdown(RegistroState state, ColorScheme colorScheme) {
    List<MaquinaMontacargaEntity> availableMachines = [];
    
    if (_selectedMaquinaOrigen != null) {
      final origenParts = _selectedMaquinaOrigen!.split('_');
      final origenIndex = int.parse(origenParts[0]);
      final maquinaOrigen = state.maquinasMontacarga[origenIndex];
      
      // Verificar si la máquina origen es un bidón
      final esBidonOrigen = _esBidon(maquinaOrigen.codigo);
      
      availableMachines = state.maquinasMontacarga.where((maquina) {
        // Si es bidón, puede transferir a cualquier máquina de cualquier sucursal (incluido a sí mismo)
        if (esBidonOrigen) {
          return true; // Sin restricción de sucursal para bidones
        }
        // Si no es bidón, solo puede transferir a máquinas de la misma sucursal (excluyendo a sí mismo)
        return maquina.codSucursal == maquinaOrigen.codSucursal && 
               maquina.idMaquina != maquinaOrigen.idMaquina;
      }).toList();
      
      if (_selectedMaquinaDestino != null) {
        bool isStillValid = false;
        for (final maquina in availableMachines) {
          String uniqueId = '${state.maquinasMontacarga.indexOf(maquina)}_${maquina.idMaquina}_${maquina.codigo}';
          if (uniqueId == _selectedMaquinaDestino) {
            isStillValid = true;
            break;
          }
        }
        
        if (!isStillValid) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedMaquinaDestino = null;
            });
          });
        }
      }
    }
    
    return DropdownButtonFormField<String>(
      value: _selectedMaquinaDestino,
      decoration: InputDecoration(
        labelText: 'Máquina/Vehículo Destino (Opcional)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        helperText: _selectedMaquinaOrigen == null 
            ? 'Seleccione primero la máquina origen' 
            : _esBidon(_selectedMaquinaOrigen!.split('_')[2])
                ? 'Bidones pueden transferir a cualquier sucursal'
                : 'Solo máquinas de la misma sucursal',
        helperStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      isExpanded: true,
      items: availableMachines.asMap().entries.map((entry) {
        var maquina = entry.value;
        int originalIndex = state.maquinasMontacarga.indexOf(maquina);
        String uniqueId = '${originalIndex}_${maquina.idMaquina}_${maquina.codigo}';
        
        String displayText = maquina.maquinaOVehiculo.isNotEmpty 
            ? maquina.maquinaOVehiculo 
            : '${maquina.codigo} - ${maquina.nombreSucursal}';
        
        return DropdownMenuItem<String>(
          value: uniqueId,
          child: Tooltip(
            message: displayText,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                displayText,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSurface),
                maxLines: 1,
              ),
            ),
          ),
        );
      }).toList(),
      onChanged: (state.maquinasStatus == FetchStatus.loading || _selectedMaquinaOrigen == null)
          ? null 
          : (value) {
              setState(() {
                _selectedMaquinaDestino = value;
              });
            },
      dropdownColor: colorScheme.surface,
      style: TextStyle(color: colorScheme.onSurface),
    );
  }

  Widget _buildAlmacenDropdown(RegistroState state, ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      value: _selectedAlmacen,
      decoration: InputDecoration(
        labelText: 'Almacén',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      isExpanded: true,
      items: state.almacenes.map((almacen) {
        String displayText = '${almacen.whsCode} - ${almacen.whsName}';
        return DropdownMenuItem<String>(
          value: almacen.whsCode,
          child: Tooltip(
            message: displayText,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                displayText,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSurface),
                maxLines: 1,
              ),
            ),
          ),
        );
      }).toList(),
      onChanged: state.almacenesStatus == FetchStatus.loading 
          ? null 
          : (value) {
              setState(() {
                _selectedAlmacen = value;
              });
            },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor seleccione un almacén';
        }
        return null;
      },
      dropdownColor: colorScheme.surface,
      style: TextStyle(color: colorScheme.onSurface),
    );
  }

  Widget _buildLitrosIngresoField(ColorScheme colorScheme) {
    return _buildFormField(
      controller: _litrosIngresoController,
      label: 'Litros Ingreso',
      icon: Icons.local_gas_station,
      colorScheme: colorScheme,
      keyboardType: TextInputType.number,
      suffixText: 'L',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese los litros de ingreso';
        }
        final litros = double.tryParse(value);
        if (litros == null) {
          return 'Ingrese un número válido';
        }
        if (litros < 0) {
          return 'Los litros de ingreso deben ser mayor o igual a 0';
        }
        return null;
      },
    );
  }

  Widget _buildLitrosSalidaField(ColorScheme colorScheme) {
    return _buildFormField(
      controller: _litrosSalidaController,
      label: 'Litros Salida',
      icon: Icons.local_gas_station_outlined,
      colorScheme: colorScheme,
      keyboardType: TextInputType.number,
      suffixText: 'L',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese los litros de salida';
        }
        final litros = double.tryParse(value);
        if (litros == null) {
          return 'Ingrese un número válido';
        }
        if (litros < 0) {
          return 'Los litros de salida deben ser mayor o igual a 0';
        }
        return null;
      },
    );
  }

  Widget _buildObservacionesField(ColorScheme colorScheme) {
    return _buildFormField(
      controller: _obsController,
      label: 'Observaciones',
      icon: Icons.notes,
      colorScheme: colorScheme,
      maxLines: 3,
    );
  }

  Widget _buildSubmitButton(RegistroState state, ColorScheme colorScheme, bool isDesktop) {
    return SizedBox(
      height: isDesktop ? 56 : 48,
      child: ElevatedButton(
        onPressed: state.registroStatus == RegistroStatus.loading 
            ? null 
            : _registrarControl,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: EdgeInsets.symmetric(
            vertical: isDesktop ? 16 : 12,
            horizontal: isDesktop ? 32 : 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: state.registroStatus == RegistroStatus.loading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: colorScheme.onPrimary,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Registrar Control',
                style: TextStyle(
                  fontSize: isDesktop ? 16 : 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildErrorMessage(String message, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método auxiliar para verificar si una máquina es un bidón
  bool _esBidon(String codigo) {
    final codigoUpper = codigo.toUpperCase();
    return codigoUpper.contains('BIDON') || 
           codigoUpper.contains('BIDONES') || 
           codigoUpper.contains('BID');
  }

  void _registrarControl() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Use the stored _selectedDate directly since the field is read-only
    DateTime fechaSeleccionada = _selectedDate;

    // Parse the selected machine origen from unique identifier
    final origenParts = _selectedMaquinaOrigen!.split('_');
    final origenIndex = int.parse(origenParts[0]);
    
    final maquinaOrigen = ref.read(controlCombustibleMaquinaMontacargaNotifierProvider)
        .maquinasMontacarga[origenIndex];

    // Obtener máquina destino si está seleccionada
    String codigoDestino = '';
    int codSucursalDestino = 0;
    int idMaquinaDestino = 0;
    
    if (_selectedMaquinaDestino != null && _selectedMaquinaDestino!.isNotEmpty) {
      final destinoParts = _selectedMaquinaDestino!.split('_');
      final destinoIndex = int.parse(destinoParts[0]);
      
      final maquinaDestino = ref.read(controlCombustibleMaquinaMontacargaNotifierProvider)
          .maquinasMontacarga[destinoIndex];
      
      // Validación modificada: permitir misma máquina solo si es bidón
      if (maquinaOrigen.idMaquina == maquinaDestino.idMaquina) {
        final esBidonOrigen = _esBidon(maquinaOrigen.codigo);
        
        if (!esBidonOrigen) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('La máquina origen y destino no pueden ser la misma, excepto para bidones'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          return;
        }
      }
      
      codigoDestino = maquinaDestino.codigo;
      codSucursalDestino = maquinaDestino.codSucursal;
      idMaquinaDestino = maquinaDestino.idMaquina;
    }

    // Obtener datos del usuario
    final userNotifier = ref.read(userProvider.notifier);
    final codUsuario = await userNotifier.getCodUsuario();
    final codEmpleado = await userNotifier.getCodEmpleado();

    final entity = ControlCombustibleMaquinaMontacargaEntity(
      idCM: 0,
      idMaquinaVehiculoOrigen: maquinaOrigen.idMaquina,
      idMaquinaVehiculoDestino: idMaquinaDestino,
      codSucursalMaqVehiOrigen: maquinaOrigen.codSucursal,
      codSucursalMaqVehiDestino: codSucursalDestino,
      codigoOrigen: maquinaOrigen.codigo,
      codigoDestino: codigoDestino,
      fecha: fechaSeleccionada,
      litrosIngreso: double.parse(_litrosIngresoController.text),
      litrosSalida: double.parse(_litrosSalidaController.text),
      saldoLitros: 0.0,
      codEmpleado: codEmpleado,
      codAlmacen: _selectedAlmacen!,
      obs: _obsController.text,
      tipoTransaccion: '',
      estado: 0,
      audUsuario: codUsuario,
      whsCode: _selectedAlmacen!,
      whsName: ref.read(controlCombustibleMaquinaMontacargaNotifierProvider)
          .almacenes
          .firstWhere((a) => a.whsCode == _selectedAlmacen)
          .whsName,
      maquina: maquinaOrigen.maquinaOVehiculo.isNotEmpty 
          ? maquinaOrigen.maquinaOVehiculo 
          : '${maquinaOrigen.codigo} - ${maquinaOrigen.nombreSucursal}',
      nombreCompleto: '',
      nombreMaquinaOrigen: '', 
      nombreMaquinaDestino: '', 
      nombreSucursal: '', 
      fechaInicio: DateTime.now(), 
      fechaFin: DateTime.now() 
      
    );

    await ref
        .read(controlCombustibleMaquinaMontacargaNotifierProvider.notifier)
        .registrarControlCombustible(entity);

    if (ref.read(controlCombustibleMaquinaMontacargaNotifierProvider).registroStatus == 
        RegistroStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Control de combustible registrado exitosamente'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      
      // Limpiar formulario y resetear provider
      _limpiarFormulario();
      
      // Resetear completamente el estado del provider
      ref.invalidate(controlCombustibleMaquinaMontacargaNotifierProvider);
      
      // Recargar datos
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(controlCombustibleMaquinaMontacargaNotifierProvider.notifier)
            .cargarMaquinasMontacargas();
        ref.read(controlCombustibleMaquinaMontacargaNotifierProvider.notifier)
            .cargarAlmacenes();
      });
    }
  }

  void _limpiarFormulario() {
    // Reset date to current date in dd/MM/yyyy format
    _selectedDate = DateTime.now();
    _fechaController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _litrosIngresoController.clear();
    _litrosSalidaController.clear();
    _obsController.clear();
    
    setState(() {
      _selectedMaquinaOrigen = null;
      _selectedMaquinaDestino = null;
      _selectedAlmacen = null;
    });
  }
}