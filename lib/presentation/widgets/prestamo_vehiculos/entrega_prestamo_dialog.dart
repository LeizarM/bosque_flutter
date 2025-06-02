import 'package:bosque_flutter/domain/entities/estado_chofer_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/prestamo_vehiculos_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:intl/intl.dart';

class EntregaPrestamoDialog extends ConsumerStatefulWidget {
  final dynamic solicitud; // PrestamoChoferEntity

  const EntregaPrestamoDialog({super.key, required this.solicitud});

  @override
  ConsumerState<EntregaPrestamoDialog> createState() => _EntregaPrestamoDialogState();
}

class _EntregaPrestamoDialogState extends ConsumerState<EntregaPrestamoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _kmEntregaController = TextEditingController();

  // Estado seleccionado para cada parte
  List<String> _estadoLaterales = [];
  List<String> _estadoInterior = [];
  List<String> _estadoDelantera = [];
  List<String> _estadoTrasera = [];
  List<String> _estadoCapote = [];

  List<EstadoChoferEntity> _estadosDisponibles = []; // Cambiar a entidades completas
  bool _loadingEstados = false;
  String? _errorEstados;

  double _nivelCombustible = 0; // Slider value
  int? _selectedChofer; // Para almacenar el chofer seleccionado

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
        _estadosDisponibles = estados; // Guardar entidades completas
        _loadingEstados = false;
      });
    } catch (e) {
      setState(() {
        _errorEstados = 'Error al cargar estados';
        _loadingEstados = false;
      });
    }
  }

  Future<void> _registrarEntrega() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(userProvider);
    if (user == null) return;

    // Convertir estados seleccionados a IDs separados por comas
    String joinEstadosIds(List<String> estadosSeleccionados) {
      List<String> ids = [];
      for (String estadoLabel in estadosSeleccionados) {
        // Buscar el ID correspondiente al label
        final estado = _estadosDisponibles.firstWhere(
          (e) => e.estado == estadoLabel,
          orElse: () => throw Exception('Estado no encontrado: $estadoLabel'),
        );
        ids.add(estado.idEst.toString());
      }
      return ids.join(',');
    }

    final entrega = {
      "idPrestamo": 0, // Nuevo préstamo
      "idCoche": widget.solicitud.idCoche,
      "idSolicitud": widget.solicitud.idSolicitud,
      "codSucursal": user.codSucursal,
      "codEmpChoferSolicitado": widget.solicitud.requiereChofer == 1 ? _selectedChofer : 0,
      "codEmpEntregadoPor": user.codEmpleado,
      "kilometrajeEntrega": double.tryParse(_kmEntregaController.text) ?? 0.0,
      "nivelCombustibleEntrega": _nivelCombustible.round(),
      // Enviar IDs de estado en lugar de labels
      "estadoLateralesEntregaAux": joinEstadosIds(_estadoLaterales),
      "estadoInteriorEntregaAux": joinEstadosIds(_estadoInterior),
      "estadoDelanteraEntregaAux": joinEstadosIds(_estadoDelantera),
      "estadoTraseraEntregaAux": joinEstadosIds(_estadoTrasera),
      "estadoCapoteEntregaAux": joinEstadosIds(_estadoCapote),
      "audUsuario": user.codUsuario,
    };

    Navigator.of(context).pop(entrega);
  }

  Future<void> _showEstadosDialog(List<String> selected, ValueChanged<List<String>> onChanged) async {
    // Crear una copia mutable de la lista seleccionada
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
                        height: 300, // Altura fija para el scroll
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _estadosDisponibles.length,
                          itemBuilder: (context, index) {
                            final estado = _estadosDisponibles[index];
                            final isSelected = tempSelected.contains(estado.estado);
                            
                            return CheckboxListTile(
                              value: isSelected,
                              title: Text(estado.estado),
                              onChanged: (checked) {
                                setStateDialog(() {
                                  if (checked == true) {
                                    if (!tempSelected.contains(estado.estado)) {
                                      tempSelected.add(estado.estado);
                                    }
                                  } else {
                                    tempSelected.remove(estado.estado);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // Cancelar sin cambios
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(tempSelected), // Devolver selección
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
    
    // Solo actualizar si se devolvió un resultado (no se canceló)
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
                // Llamar al diálogo y esperar el resultado
                await _showEstadosDialog(selected, (newSelected) {
                  // Actualizar el estado cuando se seleccionen nuevos valores
                  onChanged(newSelected);
                  // Forzar rebuild del widget padre
                  setState(() {});
                });
              },
      ),
    );
  }

  Widget _buildChoferSelector(ColorScheme colorScheme) {
    final state = ref.watch(solicitudesPrestamosNotifierProvider);
    
    return DropdownButtonFormField<int>(
      value: _selectedChofer,
      decoration: InputDecoration(
        labelText: 'Chofer Asignado',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      isExpanded: true,
      items: state.choferes.map((chofer) {
        return DropdownMenuItem<int>(
          value: chofer.codEmpleado,
          child: Text(
            chofer.nombreCompleto,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: state.choferesStatus == FetchStatus.loading
          ? null
          : (value) {
              setState(() {
                _selectedChofer = value;
              });
            },
      validator: widget.solicitud.requiereChofer == 1
          ? (value) => value == null ? 'Seleccione un chofer' : null
          : null,
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
              const Text(
                'Registrar Entrega',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kmEntregaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kilometraje Entrega',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Ingrese el kilometraje' : null,
              ),
              const SizedBox(height: 16),
              
              // Mostrar selector de chofer solo si requiere chofer
              if (widget.solicitud.requiereChofer == 1) ...[
                _buildChoferSelector(colorScheme),
                const SizedBox(height: 16),
              ],
              
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
                  'Estado de la Carrocería',
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
                    child: ElevatedButton(
                      onPressed: _registrarEntrega,
                      child: const Text('Registrar Entrega'),
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
}
