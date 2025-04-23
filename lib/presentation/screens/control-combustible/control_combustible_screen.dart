import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/control_combustible_provider.dart';
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
      final cochesList = coches
          .where((e) => ids.add(e.idCoche)) // solo ids únicos
          .map((e) => {'id': e.idCoche, 'label': e.coche})
          .toList();
      setState(() {
        _coches = cochesList;
        // Solo asignar si hay coches y el id existe
        _selectedCocheId = _coches.any((c) => c['id'] == _selectedCocheId)
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

  void _registrarCombustible() async {
    if (!_formKey.currentState!.validate() ||
        _selectedFuelType == null ||
        _selectedCocheId == null)
      return;
    final cocheLabel = (_coches.firstWhere(
      (c) => c['id'] == _selectedCocheId,
      orElse: () => <String, Object>{'label': ''},
    )['label'] ?? '') as String;
    final codEmpleado = await ref.read(userProvider.notifier).getCodEmpleado();
    final codUsuario = await ref.read(userProvider.notifier).getCodUsuario();
    final entity = CombustibleControlEntity(
      idC: 0,
      idCoche: _selectedCocheId!,
      estacionServicio: _estacionController.text,
      nroFactura: _nroFacturaController.text,
      importe: double.tryParse(_importeController.text) ?? 0,
      kilometraje: double.tryParse(_kilometrajeController.text) ?? 0,
      codEmpleado: codEmpleado,
      codSucursalCoche: 1, // Debes obtener el id real de la sucursal si aplica
      obs: _obsController.text,
      litros: double.tryParse(_litrosController.text) ?? 0,
      tipoCombustible: _selectedFuelType!.toString().split('.').last,
      audUsuario: codUsuario,
      coche: cocheLabel,
      
      fecha: DateTime.now(), //esto es solo para poner un dato
      diferencia: 0,
      kilometrajeAnterior: 0,
    );
    await ref
        .read(controlCombustibleProvider.notifier)
        .createControlCombustible(entity);
    if (mounted) {
      final result = ref.read(controlCombustibleProvider);
      if (result is AsyncData && result.value == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Registro exitoso')));
        _formKey.currentState!.reset();
      } else if (result is AsyncError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${result.error}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoading = ref.watch(controlCombustibleProvider).isLoading;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);

    Widget formFields() {
      // Campos principales
      final fields = [
        // Vehículo
        _loadingCoches
            ? const Center(child: CircularProgressIndicator())
            : DropdownButtonFormField<int>(
                value: _coches.any((c) => c['id'] == _selectedCocheId) ? _selectedCocheId : null,
                items: _coches
                    .map((c) => DropdownMenuItem<int>(
                          value: c['id'],
                          child: Text(c['label'] ?? ''),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCocheId = v),
                decoration: const InputDecoration(labelText: 'Vehículo'),
                validator: (v) => v == null ? 'Seleccione un vehículo' : null,
              ),
        // Tipo de combustible
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipo de Combustible',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...FuelType.values.map(
              (type) => RadioListTile<FuelType>(
                title: Text(type.label),
                value: type,
                groupValue: _selectedFuelType,
                onChanged: (value) {
                  setState(() {
                    _selectedFuelType = value;
                  });
                },
                activeColor: colorScheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        // Estación de servicio
        TextFormField(
          controller: _estacionController,
          decoration: const InputDecoration(
            labelText: 'Estación de Servicio',
          ),
          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
        // Nro. Factura
        TextFormField(
          controller: _nroFacturaController,
          decoration: const InputDecoration(labelText: 'Nro. Factura'),
          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
        // Importe
        TextFormField(
          controller: _importeController,
          decoration: const InputDecoration(labelText: 'Importe'),
          keyboardType: TextInputType.number,
          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
        // Kilometraje
        TextFormField(
          controller: _kilometrajeController,
          decoration: const InputDecoration(labelText: 'Kilometraje'),
          keyboardType: TextInputType.number,
          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
        // Litros
        TextFormField(
          controller: _litrosController,
          decoration: const InputDecoration(labelText: 'Litros'),
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
                constraints: isDesktop
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
                        Text(
                          'Registro de Combustible',
                          style: ResponsiveUtilsBosque.getTitleStyle(context),
                          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        formFields(),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _obsController,
                          decoration: const InputDecoration(labelText: 'Observaciones'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: isDesktop ? Alignment.centerRight : Alignment.center,
                          child: SizedBox(
                            width: isDesktop ? 220 : double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _registrarCombustible,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 18),
                                textStyle: const TextStyle(fontSize: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(isDesktop ? 16 : 8),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('Registrar'),
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
}
