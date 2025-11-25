import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/data/repositories/rrhh_repository_impl.dart';
import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/cargo_sucursal_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Formulario unificado para editar todas las propiedades de un cargo
class EditarCargoForm extends ConsumerStatefulWidget {
  final CargoEntity cargo;
  final List<CargoEntity> todosCargos;
  final int codEmpresa; // Código de la empresa para cargar sucursales
  final Function(CargoEditData) onGuardar;

  const EditarCargoForm({
    super.key,
    required this.cargo,
    required this.todosCargos,
    required this.codEmpresa,
    required this.onGuardar,
  });

  @override
  ConsumerState<EditarCargoForm> createState() => _EditarCargoFormState();
}

class _EditarCargoFormState extends ConsumerState<EditarCargoForm>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Controladores
  late TextEditingController _nombreController;
  late TextEditingController _posicionController;
  late TextEditingController _buscarPadreController; // 🆕 Buscador
  CargoEntity? _nuevoCargoPadre;
  bool _estadoActivo = true;
  int? _nivelJerarquicoSeleccionado; // Nivel jerárquico seleccionado
  String _busquedaPadre = ''; // 🆕 Query de búsqueda

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _nombreController = TextEditingController(text: widget.cargo.descripcion);
    _posicionController = TextEditingController(
      text: widget.cargo.posicion.toString(),
    );
    _buscarPadreController = TextEditingController(); // 🆕 Inicializar buscador
    _buscarPadreController.addListener(() {
      setState(() {
        _busquedaPadre = _buscarPadreController.text.toLowerCase();
      });
    });
    _estadoActivo = widget.cargo.estado == 1;
    // Inicializar nivel jerárquico solo si es mayor a 0
    _nivelJerarquicoSeleccionado =
        widget.cargo.codNivel > 0 ? widget.cargo.codNivel : null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreController.dispose();
    _posicionController.dispose();
    _buscarPadreController.dispose(); // 🆕 Dispose del buscador
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
                Tab(icon: Icon(Icons.location_city), text: 'Sucursales'),
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
                    _buildSucursalesTab(),
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
          // 🆕 CAMPO PARA EDITAR NOMBRE DEL CARGO
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.badge, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Nombre del Cargo',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del cargo *',
                      hintText: 'Ej: Gerente de Ventas',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre del cargo es obligatorio';
                      }
                      if (value.trim().length < 3) {
                        return 'El nombre debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                    maxLength: 100,
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

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
    final nivelesAsync = ref.watch(nivelesJerarquicosProvider);

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
                    'Información Actual',
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Posición: ${widget.cargo.posicion}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            'Nivel Jerárquico: ${widget.cargo.codNivel}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 🆕 Dropdown de Nivel Jerárquico
          Text(
            'Nivel Jerárquico',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          nivelesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, _) =>
                    Text('Error: $error', style: TextStyle(color: Colors.red)),
            data: (niveles) {
              if (niveles.isEmpty) {
                return const Text('No hay niveles jerárquicos disponibles');
              }

              // Filtrar solo niveles activos
              final nivelesActivos =
                  niveles.where((n) => n.activo == 1).toList();

              if (nivelesActivos.isEmpty) {
                return const Text('No hay niveles jerárquicos activos');
              }

              // Verificar si el valor actual está en la lista de activos
              final valorValido = nivelesActivos.any(
                (n) => n.codNivel == _nivelJerarquicoSeleccionado,
              );

              // Si el valor no es válido, establecerlo en null
              if (!valorValido && _nivelJerarquicoSeleccionado != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _nivelJerarquicoSeleccionado = null;
                  });
                });
              }

              return DropdownButtonFormField<int>(
                value: valorValido ? _nivelJerarquicoSeleccionado : null,
                decoration: InputDecoration(
                  labelText: 'Selecciona el nivel jerárquico',
                  prefixIcon: const Icon(Icons.stairs),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  helperText: 'Nivel de la estructura organizacional',
                ),
                hint: const Text('Selecciona un nivel'),
                items:
                    nivelesActivos.map((nivel) {
                      return DropdownMenuItem<int>(
                        value: nivel.codNivel,
                        child: Text(
                          'Nivel ${nivel.nivel} - Bs. ${nivel.haberBasico.toStringAsFixed(0)}',
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _nivelJerarquicoSeleccionado = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Debes seleccionar un nivel jerárquico';
                  }
                  return null;
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // Input para nueva posición
          Text(
            'Posición en Organigrama',
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

              // Validar que la posición sea mayor o igual a la del padre
              final padreSeleccionado = _nuevoCargoPadre;
              if (padreSeleccionado != null &&
                  pos < padreSeleccionado.posicion) {
                return 'La posición debe ser >= ${padreSeleccionado.posicion} (posición del padre)';
              }

              // Si no hay nuevo padre, verificar con el padre original
              if (padreSeleccionado == null &&
                  widget.cargo.codCargoPadreOriginal != 0) {
                final padreOriginal = widget.todosCargos.firstWhere(
                  (c) => c.codCargo == widget.cargo.codCargoPadreOriginal,
                  orElse: () => widget.cargo,
                );
                if (padreOriginal.codCargo != widget.cargo.codCargo &&
                    pos < padreOriginal.posicion) {
                  return 'La posición debe ser >= ${padreOriginal.posicion} (posición del padre)';
                }
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

    // 🆕 Filtrar cargos según búsqueda
    final cargosFiltrados =
        _busquedaPadre.isEmpty
            ? cargosDisponibles
            : cargosDisponibles.where((cargo) {
              return cargo.descripcion.toLowerCase().contains(_busquedaPadre) ||
                  cargo.codCargo.toString().contains(_busquedaPadre) ||
                  cargo.nivel.toString().contains(_busquedaPadre);
            }).toList();

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
                          widget.cargo.codCargoPadreOriginal == 0
                              ? 'Ninguno (Cargo Raíz)'
                              : widget.todosCargos
                                  .firstWhere(
                                    (c) =>
                                        c.codCargo ==
                                        widget.cargo.codCargoPadreOriginal,
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

        // 🆕 Campo de búsqueda
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _buscarPadreController,
            decoration: InputDecoration(
              labelText: 'Buscar cargo padre',
              hintText: 'Nombre, código o nivel...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _busquedaPadre.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _buscarPadreController.clear();
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Contador de resultados
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Seleccionar Nuevo Padre',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_busquedaPadre.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cargosFiltrados.length} resultado(s)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child:
              cargosFiltrados.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _busquedaPadre.isEmpty
                              ? Icons.warning
                              : Icons.search_off,
                          size: 64,
                          color: Colors.orange.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _busquedaPadre.isEmpty
                              ? 'No hay cargos disponibles para reparentar'
                              : 'No se encontraron resultados',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        if (_busquedaPadre.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              _buscarPadreController.clear();
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Limpiar búsqueda'),
                          ),
                        ],
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cargosFiltrados.length,
                    itemBuilder: (context, index) {
                      final cargo = cargosFiltrados[index];
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
                            'Cód: ${cargo.codCargo} | Nivel: ${cargo.nivel} | Pos: ${cargo.posicion}',
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

  // ============================================================================
  // TAB DE SUCURSALES - Listar y asignar sucursales al cargo
  // ============================================================================
  Widget _buildSucursalesTab() {
    // Providers para las sucursales asignadas y las sucursales disponibles
    final sucursalesAsignadasAsync = ref.watch(
      sucursalesXCargoProvider(widget.cargo.codCargo),
    );
    final sucursalesEmpresaAsync = ref.watch(
      sucursalesProvider(widget.codEmpresa),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con información del cargo
          Card(
            color: Colors.teal.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.location_city, color: Colors.teal.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sucursales Asignadas',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          widget.cargo.descripcion,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botón para refrescar
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.teal.shade700),
                    onPressed: () {
                      ref
                          .read(
                            sucursalesXCargoProvider(
                              widget.cargo.codCargo,
                            ).notifier,
                          )
                          .refresh();
                    },
                    tooltip: 'Refrescar lista',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sección para asignar nueva sucursal
          Text(
            'Asignar a Nueva Sucursal',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Dropdown de sucursales disponibles
          sucursalesEmpresaAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, _) => Text(
                  'Error cargando sucursales: $error',
                  style: const TextStyle(color: Colors.red),
                ),
            data: (sucursalesEmpresa) {
              return sucursalesAsignadasAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) => Text(
                      'Error: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                data: (sucursalesAsignadas) {
                  // Filtrar sucursales que ya están asignadas
                  final sucursalesYaAsignadas =
                      sucursalesAsignadas.map((cs) => cs.codSucursal).toSet();
                  final sucursalesDisponibles =
                      sucursalesEmpresa
                          .where(
                            (s) =>
                                !sucursalesYaAsignadas.contains(s.codSucursal),
                          )
                          .toList();

                  if (sucursalesDisponibles.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'El cargo ya está asignado a todas las sucursales de la empresa.',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildAsignarSucursalSection(sucursalesDisponibles);
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // Lista de sucursales asignadas
          Text(
            'Sucursales Actuales',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Necesitamos ambos providers para poder editar
          sucursalesEmpresaAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Error: $error'),
            data: (sucursalesEmpresa) {
              return sucursalesAsignadasAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Error: $error',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                data: (sucursalesAsignadas) {
                  if (sucursalesAsignadas.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 48,
                            color: Colors.orange.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sin Asignaciones',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Este cargo no está asignado a ninguna sucursal.',
                            style: TextStyle(color: Colors.orange.shade700),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildListaSucursalesAsignadas(
                    sucursalesAsignadas,
                    sucursalesEmpresa,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Widget para la sección de asignar nueva sucursal
  Widget _buildAsignarSucursalSection(
    List<SucursalEntity> sucursalesDisponibles,
  ) {
    // Usamos un ValueNotifier para mantener el estado
    final sucursalSeleccionada = ValueNotifier<SucursalEntity?>(null);
    final isLoading = ValueNotifier<bool>(false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<SucursalEntity?>(
              valueListenable: sucursalSeleccionada,
              builder: (context, selectedValue, _) {
                return DropdownButtonFormField<SucursalEntity>(
                  value: selectedValue,
                  decoration: InputDecoration(
                    labelText: 'Seleccionar sucursal',
                    prefixIcon: const Icon(Icons.store),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  hint: const Text('Selecciona una sucursal'),
                  items:
                      sucursalesDisponibles.map((sucursal) {
                        return DropdownMenuItem<SucursalEntity>(
                          value: sucursal,
                          child: Text(sucursal.nombre),
                        );
                      }).toList(),
                  onChanged: (value) {
                    sucursalSeleccionada.value = value;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<SucursalEntity?>(
              valueListenable: sucursalSeleccionada,
              builder: (context, selectedValue, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: isLoading,
                  builder: (context, loading, _) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            selectedValue == null || loading
                                ? null
                                : () async {
                                  isLoading.value = true;
                                  await _asignarSucursal(selectedValue);
                                  isLoading.value = false;
                                  // Limpiar selección después de asignar
                                  sucursalSeleccionada.value = null;
                                },
                        icon:
                            loading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.add),
                        label: Text(
                          loading ? 'Asignando...' : 'Asignar Sucursal',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar la lista de sucursales asignadas
  Widget _buildListaSucursalesAsignadas(
    List<CargoSucursalEntity> sucursales,
    List<SucursalEntity> todasLasSucursales,
  ) {
    return Column(
      children:
          sucursales.map((cargoSucursal) {
            final nombreSucursal =
                cargoSucursal.sucursal?.nombre ?? 'Sucursal desconocida';
            final nombreEmpresa = cargoSucursal.sucursal?.empresa.nombre ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.store, color: Colors.teal.shade700),
                ),
                title: Text(
                  nombreSucursal,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle:
                    nombreEmpresa.isNotEmpty
                        ? Text(
                          'Empresa: $nombreEmpresa',
                          style: const TextStyle(fontSize: 12),
                        )
                        : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón de editar
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed:
                          () => _mostrarDialogoEditarAsignacion(
                            cargoSucursal,
                            todasLasSucursales,
                            sucursales,
                          ),
                      tooltip: 'Cambiar sucursal',
                    ),
                    // Botón de eliminar
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed:
                          () => _confirmarEliminarAsignacion(cargoSucursal),
                      tooltip: 'Eliminar asignación',
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  // Diálogo para editar/cambiar la sucursal de una asignación existente
  void _mostrarDialogoEditarAsignacion(
    CargoSucursalEntity asignacionActual,
    List<SucursalEntity> todasLasSucursales,
    List<CargoSucursalEntity> sucursalesAsignadas,
  ) {
    // Filtrar sucursales disponibles (excluir las ya asignadas, excepto la actual)
    final sucursalesDisponibles =
        todasLasSucursales.where((s) {
          // Permitir la sucursal actual
          if (s.codSucursal == asignacionActual.codSucursal) return true;
          // Excluir otras ya asignadas
          return !sucursalesAsignadas.any(
            (cs) => cs.codSucursal == s.codSucursal,
          );
        }).toList();

    SucursalEntity? nuevaSucursalSeleccionada = todasLasSucursales.firstWhere(
      (s) => s.codSucursal == asignacionActual.codSucursal,
      orElse: () => todasLasSucursales.first,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isLoading = false;

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  const Text('Cambiar Sucursal'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sucursal actual: ${asignacionActual.sucursal?.nombre ?? "Desconocida"}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<SucursalEntity>(
                    value: nuevaSucursalSeleccionada,
                    decoration: InputDecoration(
                      labelText: 'Nueva sucursal',
                      prefixIcon: const Icon(Icons.store),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items:
                        sucursalesDisponibles.map((sucursal) {
                          final esActual =
                              sucursal.codSucursal ==
                              asignacionActual.codSucursal;
                          return DropdownMenuItem<SucursalEntity>(
                            value: sucursal,
                            child: Text(
                              esActual
                                  ? '${sucursal.nombre} (actual)'
                                  : sucursal.nombre,
                              style: TextStyle(
                                fontWeight:
                                    esActual
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        nuevaSucursalSeleccionada = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed:
                      isLoading ||
                              nuevaSucursalSeleccionada == null ||
                              nuevaSucursalSeleccionada!.codSucursal ==
                                  asignacionActual.codSucursal
                          ? null
                          : () async {
                            setDialogState(() => isLoading = true);

                            final success = await _actualizarAsignacion(
                              asignacionActual,
                              nuevaSucursalSeleccionada!,
                            );

                            if (success && dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }

                            setDialogState(() => isLoading = false);
                          },
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.save),
                  label: Text(isLoading ? 'Guardando...' : 'Guardar Cambios'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Método para actualizar una asignación existente (cambiar sucursal)
  Future<bool> _actualizarAsignacion(
    CargoSucursalEntity asignacionActual,
    SucursalEntity nuevaSucursal,
  ) async {
    try {
      final repository = ref.read(rrhhRepositoryProvider);
      final user = ref.read(userProvider);

      // Crear la nueva asignación con el codCargoSucursal existente para actualizar
      final cargoSucursalActualizado = CargoSucursalEntity(
        codCargoSucursal:
            asignacionActual.codCargoSucursal, // Mantener el ID para actualizar
        codSucursal: nuevaSucursal.codSucursal,
        codCargo: widget.cargo.codCargo,
        audUsuario: user?.codUsuario ?? 0,
        datoCargo: widget.cargo.descripcion,
      );

      final success = await repository.registrarCargoSucursal(
        cargoSucursalActualizado,
      );

      if (success) {
        // Refrescar la lista
        ref
            .read(sucursalesXCargoProvider(widget.cargo.codCargo).notifier)
            .refresh();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sucursal cambiada a "${nuevaSucursal.nombre}" correctamente',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // Método para asignar una sucursal al cargo
  Future<void> _asignarSucursal(SucursalEntity sucursal) async {
    try {
      final repository = ref.read(rrhhRepositoryProvider);
      final user = ref.read(userProvider);

      final cargoSucursal = CargoSucursalEntity(
        codCargoSucursal: 0, // Nuevo registro
        codSucursal: sucursal.codSucursal,
        codCargo: widget.cargo.codCargo,
        audUsuario: user?.codUsuario ?? 0,
        datoCargo: widget.cargo.descripcion,
      );

      final success = await repository.registrarCargoSucursal(cargoSucursal);

      if (success) {
        // Refrescar la lista
        ref
            .read(sucursalesXCargoProvider(widget.cargo.codCargo).notifier)
            .refresh();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sucursal "${sucursal.nombre}" asignada correctamente',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Diálogo de confirmación para eliminar asignación
  void _confirmarEliminarAsignacion(CargoSucursalEntity cargoSucursal) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Confirmar Eliminación'),
              ],
            ),
            content: Text(
              '¿Estás seguro de eliminar la asignación del cargo a la sucursal "${cargoSucursal.sucursal?.nombre ?? 'desconocida'}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _eliminarAsignacion(cargoSucursal);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  // Método para eliminar una asignación
  Future<void> _eliminarAsignacion(CargoSucursalEntity cargoSucursal) async {
    try {
      final repository = ref.read(rrhhRepositoryProvider);

      final success = await repository.eliminarCargoSucursal(
        cargoSucursal.codCargoSucursal,
      );

      if (success) {
        // Refrescar la lista
        ref
            .read(sucursalesXCargoProvider(widget.cargo.codCargo).notifier)
            .refresh();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Asignación a "${cargoSucursal.sucursal?.nombre}" eliminada',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _guardarCambios() {
    if (_formKey.currentState!.validate()) {
      final nombreActualizado = _nombreController.text.trim();
      final nombreCambio =
          nombreActualizado != widget.cargo.descripcion
              ? nombreActualizado
              : null;

      final data = CargoEditData(
        codCargo: widget.cargo.codCargo,
        nuevoNombre: nombreCambio,
        nuevoEstado: _estadoActivo ? 1 : 0,
        nuevaPosicion: int.parse(_posicionController.text),
        nuevoNivelJerarquico: _nivelJerarquicoSeleccionado,
        // Usar codCargo del cargo seleccionado como nuevo padre
        nuevoCargoPadre: _nuevoCargoPadre?.codCargo,
        esNuevo: false,
      );

      widget.onGuardar(data);
      // NO cerrar el diálogo para poder seguir editando
      // Navigator.of(context).pop();
    }
  }
}

/// Clase para encapsular los datos editados
class CargoEditData {
  final int codCargo; // 0 para nuevos cargos
  final String? nuevoNombre; // Nuevo nombre (null si no cambió)
  final int nuevoEstado;
  final int nuevaPosicion;
  final int? nuevoCargoPadre;
  final int? nuevoNivelJerarquico; // Nuevo nivel jerárquico (codNivel)
  final bool esNuevo; // true si es un cargo nuevo

  CargoEditData({
    required this.codCargo,
    this.nuevoNombre,
    required this.nuevoEstado,
    required this.nuevaPosicion,
    this.nuevoCargoPadre,
    this.nuevoNivelJerarquico,
    this.esNuevo = false,
  });

  bool get cambioEstado => true;
  bool get cambioPosicion => true;
  bool get cambioParent => nuevoCargoPadre != null;
  bool get cambioNombre => nuevoNombre != null && nuevoNombre!.isNotEmpty;
  bool get cambioNivel => nuevoNivelJerarquico != null;
}
