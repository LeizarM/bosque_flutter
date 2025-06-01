import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/prestamo_vehiculos_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';

class RecepcionPrestamoDialog extends ConsumerStatefulWidget {
  final dynamic solicitud; // PrestamoChoferEntity

  const RecepcionPrestamoDialog({super.key, required this.solicitud});

  @override
  ConsumerState<RecepcionPrestamoDialog> createState() => _RecepcionPrestamoDialogState();
}

class _RecepcionPrestamoDialogState extends ConsumerState<RecepcionPrestamoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _kmRecepcionController = TextEditingController();

  // Estado seleccionado para cada parte (recepción)
  List<String> _estadoLaterales = [];
  List<String> _estadoInterior = [];
  List<String> _estadoDelantera = [];
  List<String> _estadoTrasera = [];
  List<String> _estadoCapote = [];

  List<String> _estadosDisponibles = [];
  bool _loadingEstados = false;
  String? _errorEstados;

  double _nivelCombustible = 0; // Slider value

  @override
  void initState() {
    super.initState();
    _cargarEstados();
  }

  Future<void> _cargarEstados() async {
    setState(() {
      _loadingEstados = true;
      _errorEstados = null;
    });
    try {
      final repo = ref.read(prestamoVehiculosProvider);
      final estados = await repo.lstEstados();
      setState(() {
        _estadosDisponibles = estados.map((e) => e.estado).toList();
        _loadingEstados = false;
      });
    } catch (e) {
      setState(() {
        _errorEstados = 'Error al cargar estados';
        _loadingEstados = false;
      });
    }
  }

  Future<void> _registrarRecepcion() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(userProvider);
    if (user == null) return;

    String joinEstados(List<String> estados) => estados.join(', ');

    final recepcion = {
      "idPrestamo": widget.solicitud.idPrestamo,
      "kilometrajeRecepcion": double.tryParse(_kmRecepcionController.text) ?? 0.0,
      "nivelCombustibleRecepcion": _nivelCombustible.round(),
      "estadoLateralRecepcionAux": joinEstados(_estadoLaterales),
      "estadoInteriorRecepcionAux": joinEstados(_estadoInterior),
      "estadoDelanteraRecepcionAux": joinEstados(_estadoDelantera),
      "estadoTraseraRecepcionAux": joinEstados(_estadoTrasera),
      "estadoCapoteRecepcionAux": joinEstados(_estadoCapote),
      "audUsuario": user.codUsuario,
    };

    Navigator.of(context).pop(recepcion);
  }

  Future<void> _showEstadosDialog(List<String> selected, ValueChanged<List<String>> onChanged) async {
    List<String> tempSelected = List<String>.from(selected);
    
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Seleccionar Estados'),
              content: _loadingEstados
                  ? const Center(child: CircularProgressIndicator())
                  : _errorEstados != null
                    ? Text(_errorEstados!)
                    : SizedBox(
                        width: double.maxFinite,
                        height: 300,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _estadosDisponibles.length,
                          itemBuilder: (context, index) {
                            final estado = _estadosDisponibles[index];
                            final isSelected = tempSelected.contains(estado);
                            
                            return CheckboxListTile(
                              value: isSelected,
                              title: Text(estado),
                              onChanged: (checked) {
                                setStateDialog(() {
                                  if (checked == true) {
                                    if (!tempSelected.contains(estado)) {
                                      tempSelected.add(estado);
                                    }
                                  } else {
                                    tempSelected.remove(estado);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(tempSelected),
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
    
    if (result != null) {
      onChanged(result);
    }
  }

  Widget _buildEstadoSelector(String label, List<String> selected, ValueChanged<List<String>> onChanged) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(label),
        subtitle: selected.isEmpty
            ? Text('Seleccionar $label')
            : Wrap(
                spacing: 4,
                runSpacing: 2,
                children: selected.map((e) => Chip(
                  label: Text(e, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                )).toList(),
              ),
        trailing: const Icon(Icons.chevron_right),
        onTap: _loadingEstados
            ? null
            : () async {
                await _showEstadosDialog(selected, (newSelected) {
                  onChanged(newSelected);
                  setState(() {});
                });
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.assignment_return,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Registrar Recepción',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Información del préstamo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información del Préstamo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Solicitante:', widget.solicitud.solicitante),
                    _buildInfoRow('Vehículo:', widget.solicitud.coche),
                    _buildInfoRow('Motivo:', widget.solicitud.motivo),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _kmRecepcionController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kilometraje Recepción',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.speed),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Ingrese el kilometraje' : null,
              ),
              const SizedBox(height: 16),
              
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nivel de Combustible (%)',
                  style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.primary),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _nivelCombustible,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '${_nivelCombustible.round()}%',
                      onChanged: (value) {
                        setState(() {
                          _nivelCombustible = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${_nivelCombustible.round()}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Estado de la Carrocería en Recepción',
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
              ),
              _buildEstadoSelector('Estado Lateral', _estadoLaterales, (v) => setState(() => _estadoLaterales = v)),
              _buildEstadoSelector('Estado Interior', _estadoInterior, (v) => setState(() => _estadoInterior = v)),
              _buildEstadoSelector('Estado Delantera', _estadoDelantera, (v) => setState(() => _estadoDelantera = v)),
              _buildEstadoSelector('Estado Trasera', _estadoTrasera, (v) => setState(() => _estadoTrasera = v)),
              _buildEstadoSelector('Estado Capote', _estadoCapote, (v) => setState(() => _estadoCapote = v)),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _registrarRecepcion,
                      icon: const Icon(Icons.assignment_turned_in),
                      label: const Text('Registrar Recepción'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
