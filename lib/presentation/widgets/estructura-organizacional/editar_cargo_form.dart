import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formulario unificado para editar todas las propiedades de un cargo
class EditarCargoForm extends StatefulWidget {
  final CargoEntity cargo;
  final List<CargoEntity> todosCargos;
  final Function(CargoEditData) onGuardar;

  const EditarCargoForm({
    super.key,
    required this.cargo,
    required this.todosCargos,
    required this.onGuardar,
  });

  @override
  State<EditarCargoForm> createState() => _EditarCargoFormState();
}

class _EditarCargoFormState extends State<EditarCargoForm>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Controladores
  late TextEditingController _posicionController;
  CargoEntity? _nuevoCargoPadre;
  bool _estadoActivo = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _posicionController = TextEditingController(
      text: widget.cargo.posicion.toString(),
    );
    _estadoActivo = widget.cargo.estado == 1;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _posicionController.dispose();
    super.dispose();
  }

  List<CargoEntity> _obtenerCargosDisponibles() {
    // Excluir: el mismo cargo, cargos ficticios, y descendientes
    final cargosDescendientes = _obtenerDescendientes(widget.cargo.codCargo);

    return widget.todosCargos.where((c) {
        return c.codCargo != widget.cargo.codCargo && // No el mismo
            c.esVisible == 1 && // No ficticios
            c.estado == 1 && // Solo activos
            !cargosDescendientes.contains(c.codCargo); // No descendientes
      }).toList()
      ..sort((a, b) {
        if (a.nivel != b.nivel) return a.nivel.compareTo(b.nivel);
        return a.posicion.compareTo(b.posicion);
      });
  }

  Set<int> _obtenerDescendientes(int codCargo) {
    Set<int> descendientes = {};

    void buscarDescendientes(int codPadre) {
      for (var cargo in widget.todosCargos) {
        if (cargo.codCargoPadre == codPadre && cargo.esVisible == 1) {
          descendientes.add(cargo.codCargo);
          buscarDescendientes(cargo.codCargo);
        }
      }
    }

    buscarDescendientes(codCargo);
    return descendientes;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.edit, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editar Cargo',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.cargo.descripcion,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(icon: Icon(Icons.toggle_on), text: 'Estado'),
                Tab(icon: Icon(Icons.format_list_numbered), text: 'Posición'),
                Tab(icon: Icon(Icons.account_tree), text: 'Reparentar'),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Content
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEstadoTab(),
                    _buildPosicionTab(),
                    _buildReparentarTab(),
                  ],
                ),
              ),
            ),

            // Botones de acción
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _guardarCambios,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Cambios'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoTab() {
    final tieneEmpleados = widget.cargo.tieneEmpleadosActivos > 0;
    final tieneSubordinados = widget.cargo.numHijosActivos > 0;
    final estaActivo = widget.cargo.estado == 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado actual
          Card(
            color: estaActivo ? Colors.green.shade50 : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    estaActivo ? Icons.check_circle : Icons.cancel,
                    color: estaActivo ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estado Actual',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          estaActivo ? 'ACTIVO' : 'INACTIVO',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: estaActivo ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Switch para cambiar estado
          SwitchListTile(
            value: _estadoActivo,
            onChanged: (value) {
              setState(() {
                _estadoActivo = value;
              });
            },
            title: Text(
              _estadoActivo ? 'Activar Cargo' : 'Desactivar Cargo',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _estadoActivo
                  ? 'El cargo estará disponible para asignaciones'
                  : 'El cargo no estará disponible',
            ),
            activeColor: Colors.green,
            inactiveThumbColor: Colors.red,
            secondary: Icon(
              _estadoActivo ? Icons.toggle_on : Icons.toggle_off,
              color: _estadoActivo ? Colors.green : Colors.red,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),

          // Advertencias
          if (!_estadoActivo) ...[
            // Advertencia por empleados
            if (tieneEmpleados) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Empleados Asignados',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Este cargo tiene ${widget.cargo.tieneEmpleadosActivos} empleado(s) activo(s). Deberás reasignarlos.',
                            style: TextStyle(color: Colors.orange.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Advertencia CRÍTICA por subordinados
            if (tieneSubordinados) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.deepOrange.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error,
                      color: Colors.deepOrange.shade700,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚠️ ADVERTENCIA CRÍTICA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.deepOrange.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Este cargo tiene ${widget.cargo.numHijosActivos} subordinado(s) que quedarán HUÉRFANOS.',
                            style: TextStyle(
                              color: Colors.deepOrange.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '⚠️ Los cargos subordinados perderán su conexión jerárquica. Considera reparentarlos primero.',
                              style: TextStyle(
                                color: Colors.deepOrange.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPosicionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info actual
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Posición Actual',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.format_list_numbered,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.cargo.posicion.toString(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Nivel: ${widget.cargo.nivel}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Input para nueva posición
          Text(
            'Nueva Posición',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _posicionController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Posición en el organigrama',
              hintText: 'Ingresa un número entero positivo',
              prefixIcon: const Icon(Icons.format_list_numbered),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              helperText:
                  'La posición determina el orden horizontal en el organigrama',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa una posición';
              }
              final pos = int.tryParse(value);
              if (pos == null || pos < 1) {
                return 'Debe ser un número mayor a 0';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Info adicional
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Información sobre la posición',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  '📊',
                  'Define el orden entre cargos del mismo nivel',
                ),
                _buildInfoRow('➡️', 'Menor número = más a la izquierda'),
                _buildInfoRow(
                  '🔢',
                  'Puedes usar el mismo número que otro cargo',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReparentarTab() {
    final cargosDisponibles = _obtenerCargosDisponibles();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info del padre actual
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: Colors.purple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Padre Actual',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.account_tree, color: Colors.purple.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.cargo.codCargoPadre == 0
                              ? 'Ninguno (Cargo Raíz)'
                              : widget.todosCargos
                                  .firstWhere(
                                    (c) =>
                                        c.codCargo ==
                                        widget.cargo.codCargoPadre,
                                    orElse: () => widget.cargo,
                                  )
                                  .descripcion,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Lista de cargos disponibles
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Seleccionar Nuevo Padre',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child:
              cargosDisponibles.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning,
                          size: 64,
                          color: Colors.orange.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text('No hay cargos disponibles para reparentar'),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cargosDisponibles.length,
                    itemBuilder: (context, index) {
                      final cargo = cargosDisponibles[index];
                      final esSeleccionado =
                          _nuevoCargoPadre?.codCargo == cargo.codCargo;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: esSeleccionado ? Colors.purple.shade50 : null,
                        elevation: esSeleccionado ? 4 : 1,
                        child: ListTile(
                          selected: esSeleccionado,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  esSeleccionado
                                      ? Colors.purple
                                      : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                cargo.nivel.toString(),
                                style: TextStyle(
                                  color:
                                      esSeleccionado
                                          ? Colors.white
                                          : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            cargo.descripcion,
                            style: TextStyle(
                              fontWeight:
                                  esSeleccionado
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            'Nivel: ${cargo.nivel} | Pos: ${cargo.posicion}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing:
                              esSeleccionado
                                  ? Icon(
                                    Icons.check_circle,
                                    color: Colors.purple.shade700,
                                  )
                                  : const Icon(Icons.radio_button_unchecked),
                          onTap: () {
                            setState(() {
                              _nuevoCargoPadre = cargo;
                            });
                          },
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }

  void _guardarCambios() {
    if (_formKey.currentState!.validate()) {
      final data = CargoEditData(
        codCargo: widget.cargo.codCargo,
        nuevoEstado: _estadoActivo ? 1 : 0,
        nuevaPosicion: int.parse(_posicionController.text),
        nuevoCargoPadre: _nuevoCargoPadre?.codCargo,
      );

      widget.onGuardar(data);
      Navigator.of(context).pop();
    }
  }
}

/// Clase para encapsular los datos editados
class CargoEditData {
  final int codCargo;
  final int nuevoEstado;
  final int nuevaPosicion;
  final int? nuevoCargoPadre;

  CargoEditData({
    required this.codCargo,
    required this.nuevoEstado,
    required this.nuevaPosicion,
    this.nuevoCargoPadre,
  });

  bool get cambioEstado => true;
  bool get cambioPosicion => true;
  bool get cambioParent => nuevoCargoPadre != null;
}
