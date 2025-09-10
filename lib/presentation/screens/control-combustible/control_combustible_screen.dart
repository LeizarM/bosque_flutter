import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/control_combustible_provider.dart';
import 'package:bosque_flutter/core/state/control_combustible_maquina_montacarga_provider.dart';
import 'package:bosque_flutter/domain/entities/control_combustible_entity.dart';

import 'package:bosque_flutter/core/state/user_provider.dart';

enum FuelType { gasolina, diesel, electrico, gas }

extension FuelTypeExtension on FuelType {
  String get label {
    switch (this) {
      case FuelType.gasolina:
        return 'Gasolina';
      case FuelType.diesel:
        return 'Diesel';
      case FuelType.electrico:
        return 'Eléctrico';
      case FuelType.gas:
        return 'Gas';
    }
  }

  IconData get icon {
    switch (this) {
      case FuelType.gasolina:
        return Icons.local_gas_station;
      case FuelType.diesel:
        return Icons.local_shipping;
      case FuelType.electrico:
        return Icons.electric_bolt;
      case FuelType.gas:
        return Icons.propane_tank;
    }
  }

  MaterialColor get color {
    switch (this) {
      case FuelType.gasolina:
        return Colors.red;
      case FuelType.diesel:
        return Colors.orange;
      case FuelType.electrico:
        return Colors.blue;
      case FuelType.gas:
        return Colors.purple;
    }
  }
}

class ControlCombustibleScreen extends ConsumerStatefulWidget {
  const ControlCombustibleScreen({super.key});

  @override
  ConsumerState<ControlCombustibleScreen> createState() =>
      _ControlCombustibleScreenState();
}

class _ControlCombustibleScreenState
    extends ConsumerState<ControlCombustibleScreen> {
  FuelType? _selectedFuelType = FuelType.gasolina;
  final _formKey = GlobalKey<FormState>();
  final _estacionController = TextEditingController();
  final _nroFacturaController = TextEditingController();
  final _importeController = TextEditingController();
  final _kilometrajeController = TextEditingController();
  final _litrosController = TextEditingController();
  final _obsController = TextEditingController();

  int? _selectedCocheId;
  List<Map<String, dynamic>> _coches = [];
  bool _loadingCoches = true;

  @override
  void initState() {
    super.initState();
    _fetchCoches();
  }

  Future<void> _fetchCoches() async {
    setState(() => _loadingCoches = true);
    try {
      final repo = ref.read(controlCombustibleRepositoryProvider);
      final coches = await repo.getCoches();
      final ids = <int>{};
      final cochesList =
          coches
              .where((e) => ids.add(e.idCoche)) // solo ids únicos
              .map(
                (e) => {
                  'id': e.idCoche,
                  'label': e.coche,
                  'codSucursal': e.codSucursalCoche,
                },
              )
              .toList();

      setState(() {
        _coches = cochesList;
        _selectedCocheId =
            _coches.any((c) => c['id'] == _selectedCocheId)
                ? _selectedCocheId
                : (_coches.isNotEmpty ? _coches.first['id'] : null);
        _loadingCoches = false;
      });
    } catch (_) {
      setState(() => _loadingCoches = false);
    }
  }

  @override
  void dispose() {
    _estacionController.dispose();
    _nroFacturaController.dispose();
    _importeController.dispose();
    _kilometrajeController.dispose();
    _litrosController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<int?> _confirmBidonSelection(dynamic bidon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('Confirmar selección'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Está seguro de que desea seleccionar este bidón?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bidon.codigoDestino ?? 'Sin código',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fecha: ${_formatDate(bidon.fechaMovimiento?.toString())}',
                    ),
                    Text('Litros: ${bidon.valorEntrada ?? 0} L'),
                    Text('Origen: ${bidon.nombreCoche ?? 'N/A'}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Al confirmar, se usará este bidón y se procederá automáticamente con el registro de combustible.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Confirmar y Registrar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        );
      },
    );

    // If confirmed, return the bidon ID
    if (confirmed == true) {
      return bidon.idMovimiento;
    }
    return null;
  }

  Future<int?> _showBidonSelectionDialog() async {
    final selectedCoche = _coches.firstWhere(
      (c) => c['id'] == _selectedCocheId,
      orElse: () => <String, Object>{'id': 0, 'label': '', 'codSucursal': 1},
    );

    final codSucursalMaqVehiDestino = selectedCoche['codSucursal'] as int;

    // Obtener los datos de consumo para mostrar la diferencia
    final kilometraje = double.tryParse(_kilometrajeController.text) ?? 0;
    List<dynamic> consumoData = [];
    try {
      consumoData = await ref.read(
        listConsumoProvider({
          'kilometraje': kilometraje,
          'idCoche': _selectedCocheId!,
        }).future,
      );
    } catch (e) {
      // Si hay error, continuar sin datos de consumo
    }

    return showDialog<int?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.85,
            constraints: const BoxConstraints(maxWidth: 600, minHeight: 400),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_gas_station,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Selección de Bidón',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Debe seleccionar un bidón para justificar su bajo consumo.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Mostrar información del recorrido/diferencia
                        if (consumoData.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.speed,
                                      color: Colors.blue.shade700,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Información del Recorrido',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildRecorridoInfo(
                                        '🛣️ Diferencia',
                                        '${consumoData.first.diferencia?.toStringAsFixed(1) ?? '0.0'} km',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildRecorridoInfo(
                                        '📍 Km actual',
                                        '${kilometraje.toStringAsFixed(1)} km',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                _buildRecorridoInfo(
                                  '🚗 Vehículo',
                                  (selectedCoche['label'] ?? 'N/A').toString(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        Text(
                          'Bidones disponibles (Sucursal: $codSucursalMaqVehiDestino)',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Container with fixed height for bidon list
                        Container(
                          height: 300, // Fixed height to prevent overflow
                          child: _BidonListWidget(
                            codSucursalMaqVehiDestino:
                                codSucursalMaqVehiDestino,
                            onBidonSelected: _confirmBidonSelection,
                            buildBidonInfo: _buildBidonInfo,
                            formatDate: _formatDate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(null),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Cancelar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecorridoInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBidonInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  void _registrarCombustible() async {
    if (!_formKey.currentState!.validate() ||
        _selectedFuelType == null ||
        _selectedCocheId == null)
      return;

    try {
      // Validar primero si se puede registrar verificando el consumo
      final kilometraje = double.tryParse(_kilometrajeController.text) ?? 0;
      final consumoData = await ref.read(
        listConsumoProvider({
          'kilometraje': kilometraje,
          'idCoche': _selectedCocheId!,
        }).future,
      );

      int selectedMovimiento = 0; // Valor por defecto

      // Verificar si hay datos y si esMenor es 1
      if (consumoData.isNotEmpty) {
        final primerRegistro = consumoData.first;
        if (primerRegistro.esMenor == 1) {
          // Mostrar diálogo para seleccionar bidón
          final selectedBidonIdMovimiento = await _showBidonSelectionDialog();

          if (selectedBidonIdMovimiento == null) {
            // Usuario canceló la selección
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Debe seleccionar un bidón para continuar con el registro',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }

          selectedMovimiento = selectedMovimiento;

          // IMPORTANTE: Proceder inmediatamente con el registro
          await _proceedWithRegistration(selectedMovimiento, consumoData);
          return;
        }
      }

      // Si no necesita bidón, proceder directamente con el registro
      await _proceedWithRegistration(selectedMovimiento, consumoData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al validar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _proceedWithRegistration(
    int selectedIdMovimiento,
    List<dynamic> consumoData,
  ) async {
    if (!mounted) return;

    try {
      // Mostrar mensaje de procesamiento
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              const Text('Registrando combustible...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 5),
        ),
      );

      // Preparar datos para el registro
      final selectedCoche = _coches.firstWhere(
        (c) => c['id'] == _selectedCocheId,
        orElse: () => <String, Object>{'label': '', 'codSucursal': 1},
      );
      final cocheLabel = (selectedCoche['label'] ?? '') as String;
      final codSucursalCoche = (selectedCoche['codSucursal'] ?? 1) as int;

      final codEmpleado =
          await ref.read(userProvider.notifier).getCodEmpleado();
      final codUsuario = await ref.read(userProvider.notifier).getCodUsuario();
      final kilometraje = double.tryParse(_kilometrajeController.text) ?? 0;

      final entity = CombustibleControlEntity(
        idC: 0,
        idCoche: _selectedCocheId!,
        estacionServicio: _estacionController.text,
        nroFactura: _nroFacturaController.text,
        importe: double.tryParse(_importeController.text) ?? 0,
        kilometraje: kilometraje,
        codEmpleado: codEmpleado,
        codSucursalCoche: codSucursalCoche,
        obs: _obsController.text,
        litros: double.tryParse(_litrosController.text) ?? 0,
        tipoCombustible: _selectedFuelType!.toString().split('.').last,
        audUsuario: codUsuario,
        coche: cocheLabel,
        fecha: DateTime.now(),
        diferencia: 0,
        kilometrajeAnterior: 0,
        idMovimiento: selectedIdMovimiento,
        esMenor: consumoData.isNotEmpty ? consumoData.first.esMenor ?? 0 : 0,
        nombreCompleto: '',
      );

      // Realizar el registro
      await ref
          .read(controlCombustibleProvider.notifier)
          .createControlCombustible(entity);

      if (!mounted) return;

      // Verificar el resultado
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Esperar un poco para que se complete
      final result = ref.read(controlCombustibleProvider);

      ScaffoldMessenger.of(context).clearSnackBars();

      if (result is AsyncData) {
        if (result.value == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 24),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Registro de combustible completado exitosamente',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Limpiar el formulario
          _clearForm();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white, size: 24),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text('Error: No se pudo completar el registro'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else if (result is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 24),
                const SizedBox(width: 16),
                Expanded(child: Text('Error en el registro: ${result.error}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // AsyncLoading o estado desconocido
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El registro está siendo procesado...'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 24),
                const SizedBox(width: 16),
                Expanded(child: Text('Error durante el registro: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _clearForm() {
    _formKey.currentState!.reset();
    // Limpiar controladores
    _estacionController.clear();
    _nroFacturaController.clear();
    _importeController.clear();
    _kilometrajeController.clear();
    _litrosController.clear();
    _obsController.clear();
    setState(() {
      _selectedFuelType = FuelType.gasolina;
      _selectedCocheId = _coches.isNotEmpty ? _coches.first['id'] : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoading = ref.watch(controlCombustibleProvider).isLoading;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(
      context,
    );
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);

    Widget formFields() {
      // Campos principales
      final fields = [
        // Vehículo
        _loadingCoches
            ? const Center(child: CircularProgressIndicator())
            : DropdownButtonFormField<int>(
              value:
                  _coches.any((c) => c['id'] == _selectedCocheId)
                      ? _selectedCocheId
                      : null,
              items:
                  _coches
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c['id'],
                          child: Text(c['label'] ?? ''),
                        ),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _selectedCocheId = v),
              decoration: const InputDecoration(labelText: 'Vehículo'),
              validator: (v) => v == null ? 'Seleccione un vehículo' : null,
            ),
        _buildFuelTypeSelector(colorScheme),
        _buildStyledTextField(
          controller: _estacionController,
          label: 'Estación de Servicio',
          icon: Icons.local_gas_station,
          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
        _buildStyledTextField(
          controller: _nroFacturaController,
          label: 'Nro. Factura',
          icon: Icons.confirmation_number,
          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
        _buildStyledTextField(
          controller: _importeController,
          label: 'Importe',
          icon: Icons.attach_money,
          keyboardType: TextInputType.number,
          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
        _buildStyledTextField(
          controller: _kilometrajeController,
          label: 'Kilometraje',
          icon: Icons.speed,
          keyboardType: TextInputType.number,
          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
        _buildStyledTextField(
          controller: _litrosController,
          label: 'Litros',
          icon: Icons.local_gas_station,
          keyboardType: TextInputType.number,
          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
      ];

      if (isDesktop) {
        // Dos columnas en desktop
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: fields.sublist(0, (fields.length / 2).ceil()),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                children: fields.sublist((fields.length / 2).ceil()),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
              ),
            ),
          ],
        );
      } else {
        // Una columna en móvil/tablet
        return Column(
          children: fields,
          crossAxisAlignment: CrossAxisAlignment.stretch,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Combustible')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints:
                    isDesktop
                        ? const BoxConstraints(maxWidth: 900)
                        : const BoxConstraints(),
                child: Card(
                  elevation: isDesktop ? 6 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isDesktop ? 24 : 12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 32 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.local_gas_station,
                              color: colorScheme.primary,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Registro Compra de Combustible',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        formFields(),
                        const SizedBox(height: 16),
                        _buildStyledTextField(
                          controller: _obsController,
                          label: 'Observaciones',
                          icon: Icons.note_alt,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child:
                              isLoading
                                  ? Center(
                                    child: CircularProgressIndicator(
                                      key: ValueKey('loading'),
                                    ),
                                  )
                                  : SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton.icon(
                                      key: const ValueKey('button'),
                                      onPressed: _registrarCombustible,
                                      icon: const Icon(Icons.save),
                                      label: const Text(
                                        'Registrar',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Selector visual de tipo de combustible usando el theme
  Widget _buildFuelTypeSelector(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de Combustible',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children:
                FuelType.values.map((type) {
                  final isSelected = _selectedFuelType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFuelType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient:
                            isSelected
                                ? LinearGradient(
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.primary.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                                : null,
                        color: isSelected ? null : colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(
                                      0.25,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                    spreadRadius: 1,
                                  ),
                                ]
                                : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? colorScheme.onPrimary.withOpacity(0.2)
                                      : colorScheme.primaryContainer
                                          .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              type.icon,
                              color:
                                  isSelected
                                      ? colorScheme.onPrimary
                                      : colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            type.label,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                              fontSize: 14,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // Campo de texto estilizado usando el theme
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: colorScheme.primary),
          filled: true,
          fillColor: colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _BidonListWidget extends ConsumerWidget {
  final int codSucursalMaqVehiDestino;
  final Future<int?> Function(dynamic) onBidonSelected;
  final Widget Function(String, String) buildBidonInfo;
  final String Function(String?) formatDate;

  const _BidonListWidget({
    required this.codSucursalMaqVehiDestino,
    required this.onBidonSelected,
    required this.buildBidonInfo,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<dynamic>>(
      future: () async {
        final repo = ref.read(controlCombustibleMaquinaMontacargaProvider);
        return await repo.listBidonesPendientes(codSucursalMaqVehiDestino);
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 12),
                Text(
                  'Cargando bidones...',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 32,
                    color: Colors.red[400],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Error al cargar bidones',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No se pudieron cargar los bidones',
                  style: TextStyle(fontSize: 12, color: Colors.red[400]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final bidones = snapshot.data ?? [];

        if (bidones.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.inbox_outlined,
                    size: 32,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No hay bidones disponibles',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'No se encontraron bidones pendientes\npara esta sucursal',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: bidones.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            final bidon = bidones[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Material(
                  color: Colors.white,
                  child: InkWell(
                    onTap: () async {
                      final selectedBidonId = await onBidonSelected(bidon);
                      if (selectedBidonId != null && context.mounted) {
                        Navigator.of(context).pop(selectedBidonId);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.local_gas_station,
                              color: Theme.of(context).primaryColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  bidon.codigoDestino ?? 'Sin código',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                buildBidonInfo(
                                  '📅',
                                  formatDate(bidon.fechaMovimiento.toString()),
                                ),
                                buildBidonInfo(
                                  '⛽',
                                  '${bidon.valorEntrada ?? 0} L / U',
                                ),
                                buildBidonInfo(
                                  '🚚',
                                  bidon.nombreCoche ?? 'N/A',
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Seleccionar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
