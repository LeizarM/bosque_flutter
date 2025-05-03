import 'package:bosque_flutter/core/state/control_combustible_maquina_montacarga_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/control_combustible_maquina_montacarga_entity.dart';

class ControlCombustibleMaquinaMontacargaScreen extends ConsumerStatefulWidget {
  const ControlCombustibleMaquinaMontacargaScreen({super.key});

  @override
  ConsumerState<ControlCombustibleMaquinaMontacargaScreen> createState() => _ControlCombustibleMaquinaMontacargaScreenState();
}

class _ControlCombustibleMaquinaMontacargaScreenState extends ConsumerState<ControlCombustibleMaquinaMontacargaScreen> {
  // Controladores para los campos del formulario
  final TextEditingController _maquinaController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  // Agrega más controladores según tus necesidades
  
  @override
  void dispose() {
    _maquinaController.dispose();
    _cantidadController.dispose();
    // Disponer de los demás controladores
    super.dispose();
  }
  
  void _registrarControlCombustible() {
    // Construir la entidad con los datos del formulario
    final controlCombustible = ControlCombustibleMaquinaMontacargaEntity(
      idCm: 0
      , idMaquina: 1
      , fecha: DateTime.now()
      , litrosIngreso: 0
      , litrosSalida: 0
      , saldoLitros: 0
      , horasUso: 0
      , horometro: 0
      , codEmpleado: 0
      , codAlmacen: ''
      , obs: ''
      , audUsuario: 5
      , whsCode: ''
      , whsName: '',
      
      
      
    );
    
    // Llamar al método del notifier para registrar
    ref.read(controlCombustibleMaquinaMontacargaNotifierProvider.notifier)
      .registrarControlCombustible(controlCombustible);
  }
  
  @override
  Widget build(BuildContext context) {
    // Observar el estado
    final state = ref.watch(controlCombustibleMaquinaMontacargaNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Combustible'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mostrar mensajes de error o éxito
            if (state.status == RegistroStatus.success)
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Registro completado con éxito',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            
            if (state.status == RegistroStatus.error)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Error: ${state.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            
            // Formulario
            TextField(
              controller: _maquinaController,
              decoration: const InputDecoration(labelText: 'Máquina/Montacarga'),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _cantidadController,
              decoration: const InputDecoration(labelText: 'Cantidad de Combustible'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            // Agregar más campos según sea necesario
            
            const SizedBox(height: 24),
            
            // Botón de registro
            ElevatedButton(
              onPressed: state.status == RegistroStatus.loading 
                ? null 
                : _registrarControlCombustible,
              child: state.status == RegistroStatus.loading
                ? const CircularProgressIndicator()
                : const Text('Registrar Control de Combustible'),
            ),
          ],
        ),
      ),
    );
  }
}