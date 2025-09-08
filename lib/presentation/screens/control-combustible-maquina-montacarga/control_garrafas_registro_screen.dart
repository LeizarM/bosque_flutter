import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/control_combustible_maquina_montacarga_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/compra_garrafa_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';

class ControlGarrafasRegistroScreen extends ConsumerStatefulWidget {
  const ControlGarrafasRegistroScreen({super.key});

  @override
  ConsumerState<ControlGarrafasRegistroScreen> createState() =>
      _ControlGarrafasRegistroScreenState();
}

class _ControlGarrafasRegistroScreenState
    extends ConsumerState<ControlGarrafasRegistroScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final _descripcionController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _montoController = TextEditingController();

  // Variables del formulario
  SucursalEntity? _sucursalSeleccionada;
  bool _isLoading = false;

  @override
  void dispose() {
    _descripcionController.dispose();
    _cantidadController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sucursalesAsync = ref.watch(sucursalesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Garrafas'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context),
          vertical: ResponsiveUtilsBosque.getVerticalPadding(context),
        ),
        child: sucursalesAsync.when(
          data: (sucursales) => _buildForm(context, sucursales),
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar sucursales',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(sucursalesProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, List<SucursalEntity> sucursales) {
    return Form(
      key: _formKey,
      child:
          ResponsiveUtilsBosque.isDesktop(context)
              ? _buildDesktopLayout(context, sucursales)
              : _buildMobileLayout(context, sucursales),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    List<SucursalEntity> sucursales,
  ) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registrar Nueva Garrafa',
                    style: ResponsiveUtilsBosque.getTitleStyle(context),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildSucursalDropdown(sucursales)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDescripcionField()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildCantidadField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildMontoField()),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    List<SucursalEntity> sucursales,
  ) {
    return SingleChildScrollView(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registrar Nueva Garrafa',
                style: ResponsiveUtilsBosque.getTitleStyle(context),
              ),
              const SizedBox(height: 24),
              _buildSucursalDropdown(sucursales),
              const SizedBox(height: 16),
              _buildDescripcionField(),
              const SizedBox(height: 16),
              _buildCantidadField(),
              const SizedBox(height: 16),
              _buildMontoField(),
              const SizedBox(height: 32),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSucursalDropdown(List<SucursalEntity> sucursales) {
    // Filtrar sucursales válidas (excluyendo la opción "-- Defina Nueva Sucursal --")
    final sucursalesValidas =
        sucursales.where((s) => s.codSucursal > 0).toList();

    return DropdownButtonFormField<SucursalEntity>(
      value: _sucursalSeleccionada,
      decoration: const InputDecoration(
        labelText: 'Sucursal *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.business),
      ),
      hint: const Text('Seleccione una sucursal'),
      isExpanded: true,
      items:
          sucursalesValidas.map((sucursal) {
            return DropdownMenuItem<SucursalEntity>(
              value: sucursal,
              child: Text(
                '${sucursal.nombre} - ${sucursal.nombreCiudad}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
      onChanged: (SucursalEntity? newValue) {
        setState(() {
          _sucursalSeleccionada = newValue;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Debe seleccionar una sucursal';
        }
        return null;
      },
    );
  }

  Widget _buildDescripcionField() {
    return TextFormField(
      controller: _descripcionController,
      decoration: const InputDecoration(
        labelText: 'Descripción *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
        hintText: 'Ingrese la descripción de la garrafa',
      ),
      maxLength: 100,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'La descripción es obligatoria';
        }
        if (value.trim().length < 3) {
          return 'La descripción debe tener al menos 3 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildCantidadField() {
    return TextFormField(
      controller: _cantidadController,
      decoration: const InputDecoration(
        labelText: 'Cantidad *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.inventory),
        hintText: 'Ingrese la cantidad',
        suffixText: 'unidades',
      ),
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'La cantidad es obligatoria';
        }
        final cantidad = int.tryParse(value);
        if (cantidad == null || cantidad <= 0) {
          return 'Ingrese una cantidad válida mayor a 0';
        }
        if (cantidad > 10000) {
          return 'La cantidad no puede ser mayor a 10,000';
        }
        return null;
      },
    );
  }

  Widget _buildMontoField() {
    return TextFormField(
      controller: _montoController,
      decoration: const InputDecoration(
        labelText: 'Monto *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.attach_money),
        hintText: 'Ingrese el monto',
        suffixText: 'Bs.',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El monto es obligatorio';
        }
        final monto = double.tryParse(value);
        if (monto == null || monto <= 0) {
          return 'Ingrese un monto válido mayor a 0';
        }
        if (monto > 1000000) {
          return 'El monto no puede ser mayor a 1,000,000';
        }
        return null;
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (ResponsiveUtilsBosque.isDesktop(context)) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _isLoading ? null : _resetForm,
            child: const Text('Limpiar'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _registrarGarrafa,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text('Registrar Garrafa'),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _resetForm,
              child: const Text('Limpiar Formulario'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _registrarGarrafa,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text('Registrar Garrafa'),
            ),
          ),
        ],
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _sucursalSeleccionada = null;
    });
    _descripcionController.clear();
    _cantidadController.clear();
    _montoController.clear();
  }

  Future<void> _registrarGarrafa() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(userProvider);

      // Obtener audUsuario del usuario logueado
      int audUsuario = user?.codUsuario ?? 0;
      if (audUsuario == 0) {
        final userNotifier = ref.read(userProvider.notifier);
        audUsuario = await userNotifier.getCodUsuario();
      }

      final compraGarrafa = CompraGarrafaEntity(
        idCG: 0, // Se genera automáticamente en el backend
        codSucursal: _sucursalSeleccionada!.codSucursal,
        descripcion: _descripcionController.text.trim(),
        cantidad: int.parse(_cantidadController.text),
        monto: double.parse(_montoController.text),
        audUsuario: audUsuario,
      );

      // Mostrar datos para debug
      print('=== GARRAFA A REGISTRAR ===');
      print('codSucursal: ${compraGarrafa.codSucursal}');
      print('descripcion: ${compraGarrafa.descripcion}');
      print('cantidad: ${compraGarrafa.cantidad}');
      print('monto: ${compraGarrafa.monto}');
      print('audUsuario: ${compraGarrafa.audUsuario}');
      print('===============================');

      // Registrar garrafa usando el provider
      final result = await ref.read(
        registrarGarrafaProvider(compraGarrafa).future,
      );

      if (result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Garrafa registrada exitosamente\nSucursal: ${_sucursalSeleccionada!.nombre}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        _resetForm();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al registrar la garrafa'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
