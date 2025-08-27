import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/control_combustible_maquina_montacarga_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/utils/movimiento_business_logic.dart';
import 'package:bosque_flutter/domain/entities/contenedor_entity.dart';
import 'package:bosque_flutter/domain/entities/movimiento_entity.dart';

class ControlContenedoresCombustibleScreen extends ConsumerStatefulWidget {
  const ControlContenedoresCombustibleScreen({super.key});

  @override
  ConsumerState<ControlContenedoresCombustibleScreen> createState() =>
      _ControlContenedoresCombustibleScreenState();
}

class _ControlContenedoresCombustibleScreenState
    extends ConsumerState<ControlContenedoresCombustibleScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final _valorController = TextEditingController();
  final _valorEntradaController = TextEditingController();
  final _valorSalidaController = TextEditingController();
  final _valorSaldoController = TextEditingController();
  final _obsController = TextEditingController();

  // Variables del formulario
  String? _tipoMovimientoSeleccionado;
  ContenedorEntity? _contenedorOrigenSeleccionado;
  ContenedorEntity? _contenedorDestinoSeleccionado;
  DateTime _fechaMovimiento = DateTime.now();
  bool _isLoading = false;

  // Opciones de tipo de movimiento
  final List<String> _tiposMovimiento = ['Entrada', 'Traspaso', 'Salida'];

  // Método para determinar automáticamente el tipo de movimiento
  void _determinarTipoMovimiento() {
    if (_contenedorOrigenSeleccionado != null) {
      // Validar si la combinación es válida
      final esValida = MovimientoBusinessLogic.esCombinacionValida(
        claseOrigen: _contenedorOrigenSeleccionado!.clase,
        claseDestino: _contenedorDestinoSeleccionado?.clase,
        sucursalOrigen: _contenedorOrigenSeleccionado!.codSucursal,
        sucursalDestino: _contenedorDestinoSeleccionado?.codSucursal,
        unidadMedidaOrigen: _contenedorOrigenSeleccionado!.unidadMedida,
        unidadMedidaDestino: _contenedorDestinoSeleccionado?.unidadMedida,
      );

      if (!esValida) {
        // Mostrar mensaje de error y limpiar selección de destino
        final mensajeError = MovimientoBusinessLogic.obtenerMensajeError(
          claseOrigen: _contenedorOrigenSeleccionado!.clase,
          claseDestino: _contenedorDestinoSeleccionado?.clase,
          sucursalOrigen: _contenedorOrigenSeleccionado!.codSucursal,
          sucursalDestino: _contenedorDestinoSeleccionado?.codSucursal,
          unidadMedidaOrigen: _contenedorOrigenSeleccionado!.unidadMedida,
          unidadMedidaDestino: _contenedorDestinoSeleccionado?.unidadMedida,
        );

        if (mensajeError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensajeError),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }

        setState(() {
          _contenedorDestinoSeleccionado = null;
          _tipoMovimientoSeleccionado = null;
        });
        return;
      }

      final tipoMovimiento = MovimientoBusinessLogic.determinarTipoMovimiento(
        claseOrigen: _contenedorOrigenSeleccionado!.clase,
        claseDestino: _contenedorDestinoSeleccionado?.clase,
      );

      if (tipoMovimiento != _tipoMovimientoSeleccionado) {
        setState(() {
          _tipoMovimientoSeleccionado = tipoMovimiento;
          // Limpiar campos cuando cambia automáticamente
          _valorController.clear();
          _valorEntradaController.clear();
          _valorSalidaController.clear();
        });
      }
    }
  }

  // Método para validar si un contenedor puede ser seleccionado como destino
  bool _esContenedorDestinoValido(ContenedorEntity contenedor) {
    // No permitir seleccionar el mismo contenedor que el origen usando llave compuesta
    if (_contenedorOrigenSeleccionado != null &&
        contenedor.idContenedor ==
            _contenedorOrigenSeleccionado!.idContenedor &&
        contenedor.codigo == _contenedorOrigenSeleccionado!.codigo) {
      return false;
    }

    // Si no hay origen seleccionado, permitir todos
    if (_contenedorOrigenSeleccionado == null) {
      return true;
    }

    // Aplicar validaciones de negocio
    return MovimientoBusinessLogic.esCombinacionValida(
      claseOrigen: _contenedorOrigenSeleccionado!.clase,
      claseDestino: contenedor.clase,
      sucursalOrigen: _contenedorOrigenSeleccionado!.codSucursal,
      sucursalDestino: contenedor.codSucursal,
      unidadMedidaOrigen: _contenedorOrigenSeleccionado!.unidadMedida,
      unidadMedidaDestino: contenedor.unidadMedida,
    );
  }

  @override
  void dispose() {
    _valorController.dispose();
    _valorEntradaController.dispose();
    _valorSalidaController.dispose();
    _valorSaldoController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contenedoresAsync = ref.watch(contenedoresProvider);
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final isTablet = ResponsiveUtilsBosque.isTablet(context);
    final isMediumOrLarge = isTablet || isDesktop;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Control de Contenedores',
          style: ResponsiveUtilsBosque.getTitleStyle(context),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context),
                vertical: ResponsiveUtilsBosque.getVerticalPadding(context),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveUtilsBosque.getResponsiveValue<double>(
                      context: context,
                      defaultValue: double.infinity,
                      tablet: 800,
                      desktop: 1000,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation:
                              ResponsiveUtilsBosque.getResponsiveValue<double>(
                                context: context,
                                defaultValue: 2,
                                desktop: 4,
                              ),
                          child: Padding(
                            padding: EdgeInsets.all(
                              ResponsiveUtilsBosque.getResponsiveValue<double>(
                                context: context,
                                defaultValue: 16.0,
                                tablet: 20.0,
                                desktop: 24.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Registro de Movimiento',
                                  style: ResponsiveUtilsBosque.getTitleStyle(
                                    context,
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      ResponsiveUtilsBosque.getResponsiveValue<
                                        double
                                      >(
                                        context: context,
                                        defaultValue: 20,
                                        desktop: 24,
                                      ),
                                ),

                                // Tipo de Movimiento
                                _buildDropdownField(),

                                // Descripción del movimiento (si hay contenedores seleccionados)
                                if (_contenedorOrigenSeleccionado != null &&
                                    _tipoMovimientoSeleccionado != null)
                                  _buildDescripcionMovimiento(),

                                const SizedBox(height: 16),

                                // Contenedores en layout responsivo
                                _buildContenedoresSection(
                                  contenedoresAsync,
                                  isMediumOrLarge,
                                ),
                                const SizedBox(height: 16),

                                // Fecha de Movimiento
                                _buildDateField(),
                                const SizedBox(height: 16),

                                // Campos de valores responsivos
                                _buildValoresSection(isMediumOrLarge),
                                const SizedBox(height: 16),

                                // Observaciones
                                _buildObservacionesField(),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height:
                              ResponsiveUtilsBosque.getResponsiveValue<double>(
                                context: context,
                                defaultValue: 20,
                                desktop: 32,
                              ),
                        ),

                        // Botones
                        _buildButtonsSection(isMediumOrLarge),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    final bool tipoAutoDetectado = _contenedorOrigenSeleccionado != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _tipoMovimientoSeleccionado,
          decoration: InputDecoration(
            labelText: 'Tipo de Movimiento',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.swap_horiz),
            suffixIcon:
                tipoAutoDetectado
                    ? const Icon(Icons.auto_fix_high, color: Colors.green)
                    : null,
          ),
          isExpanded: true,
          items:
              _tiposMovimiento.map((String tipo) {
                return DropdownMenuItem<String>(value: tipo, child: Text(tipo));
              }).toList(),
          onChanged:
              tipoAutoDetectado
                  ? null // Deshabilitar cuando se autodetecta
                  : (String? newValue) {
                    setState(() {
                      _tipoMovimientoSeleccionado = newValue;
                      // Limpiar campos cuando cambia el tipo
                      _valorController.clear();
                      _valorEntradaController.clear();
                      _valorSalidaController.clear();
                    });
                  },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor seleccione un tipo de movimiento';
            }
            return null;
          },
        ),
        if (tipoAutoDetectado && _tipoMovimientoSeleccionado != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Tipo determinado automáticamente basado en contenedores',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDescripcionMovimiento() {
    if (_contenedorOrigenSeleccionado == null ||
        _tipoMovimientoSeleccionado == null) {
      return const SizedBox.shrink();
    }

    final descripcion = MovimientoBusinessLogic.obtenerDescripcionMovimiento(
      claseOrigen: _contenedorOrigenSeleccionado!.clase,
      claseDestino: _contenedorDestinoSeleccionado?.clase,
      tipoMovimiento: _tipoMovimientoSeleccionado!,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              descripcion,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenedoresSection(
    AsyncValue<List<ContenedorEntity>> contenedoresAsync,
    bool isMediumScreen,
  ) {
    return contenedoresAsync.when(
      data: (contenedores) {
        // Debug detallado de todas las clases
        print('=== DEBUG CONTENEDORES DETALLADO ===');
        print('Total elementos: ${contenedores.length}');

        // Agrupar por clase para ver qué hay
        Map<String, int> clasesCounts = {};
        for (var contenedor in contenedores) {
          clasesCounts[contenedor.clase] =
              (clasesCounts[contenedor.clase] ?? 0) + 1;
        }

        print('Distribución por clases:');
        clasesCounts.forEach((clase, count) {
          print('  $clase: $count elementos');
        });

        // Mostrar algunos ejemplos de cada clase
        for (var clase in clasesCounts.keys) {
          var ejemplos = contenedores.where((c) => c.clase == clase).take(2);
          print('Ejemplos de $clase:');
          for (var ejemplo in ejemplos) {
            print(
              '  - ${ejemplo.descripcion} (ID: ${ejemplo.idContenedor}, Código: ${ejemplo.codigo})',
            );
          }
        }
        print('=====================================');

        return Column(
          children: [
            // Contenedor Origen - Siempre visible
            DropdownButtonFormField<ContenedorEntity>(
              value: _contenedorOrigenSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Contenedor Origen',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
              isExpanded: true, // Resolver overflow
              items:
                  contenedores
                      .fold<Map<String, ContenedorEntity>>({}, (
                        map,
                        contenedor,
                      ) {
                        // Crear clave única combinando ID y código para mayor consistencia
                        String claveUnica =
                            '${contenedor.idContenedor}_${contenedor.codigo}';
                        map[claveUnica] = contenedor;
                        return map;
                      })
                      .values
                      .map((ContenedorEntity contenedor) {
                        return DropdownMenuItem<ContenedorEntity>(
                          value: contenedor,
                          child: Tooltip(
                            message:
                                '${contenedor.codigo} - ${contenedor.descripcion}',
                            child: Text(
                              contenedor.descripcion,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        );
                      })
                      .toList(),
              onChanged: (ContenedorEntity? newValue) {
                setState(() {
                  _contenedorOrigenSeleccionado = newValue;
                });
                _determinarTipoMovimiento();
              },
              validator: (value) {
                if (value == null) {
                  return 'Por favor seleccione un contenedor origen';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Contenedor Destino - Siempre visible
            DropdownButtonFormField<ContenedorEntity>(
              value: _contenedorDestinoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Contenedor Destino',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
              ),
              isExpanded: true, // Resolver overflow
              items:
                  contenedores
                      .where((c) => _esContenedorDestinoValido(c))
                      .fold<Map<String, ContenedorEntity>>({}, (
                        map,
                        contenedor,
                      ) {
                        // Crear clave única combinando ID y código para mayor consistencia
                        String claveUnica =
                            '${contenedor.idContenedor}_${contenedor.codigo}';
                        map[claveUnica] = contenedor;
                        return map;
                      })
                      .values
                      .map((ContenedorEntity contenedor) {
                        return DropdownMenuItem<ContenedorEntity>(
                          value: contenedor,
                          child: Tooltip(
                            message:
                                '${contenedor.codigo} - ${contenedor.descripcion}',
                            child: Text(
                              contenedor.descripcion,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        );
                      })
                      .toList(),
              onChanged: (ContenedorEntity? newValue) {
                setState(() {
                  _contenedorDestinoSeleccionado = newValue;
                });
                _determinarTipoMovimiento();
              },
              validator: (value) {
                // Solo requerido para traspaso
                if (_tipoMovimientoSeleccionado == 'Traspaso' &&
                    value == null) {
                  return 'Por favor seleccione un contenedor destino';
                }
                return null;
              },
            ),
          ],
        );
      },
      loading: () {
        print('=== CARGANDO CONTENEDORES ===');
        return DropdownButtonFormField<String>(
          items: const [],
          onChanged: null,
          decoration: const InputDecoration(
            labelText: 'Cargando contenedores...',
            border: OutlineInputBorder(),
            prefixIcon: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        print('=== ERROR CARGANDO CONTENEDORES ===');
        print('Error: $error');
        return DropdownButtonFormField<String>(
          items: const [],
          onChanged: null,
          decoration: InputDecoration(
            labelText: 'Error al cargar contenedores',
            border: const OutlineInputBorder(),
            errorText: error.toString(),
          ),
        );
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha de Movimiento',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_fechaMovimiento.day.toString().padLeft(2, '0')}/${_fechaMovimiento.month.toString().padLeft(2, '0')}/${_fechaMovimiento.year}',
        ),
      ),
    );
  }

  Widget _buildValoresSection(bool isMediumScreen) {
    // Determinar qué campos mostrar según el tipo de movimiento
    List<Widget> campos = [];

    // Obtener unidad de medida del contenedor origen
    final unidadMedida =
        _contenedorOrigenSeleccionado?.unidadMedida ?? 'Litros';

    // Campo Valor siempre visible
    campos.add(
      Expanded(
        child: TextFormField(
          controller: _valorController,
          decoration: const InputDecoration(
            labelText: 'Valor',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
            suffixText: 'L',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingrese un valor';
            }
            return null;
          },
        ),
      ),
    );

    // Campos específicos según tipo de movimiento
    if (_tipoMovimientoSeleccionado != null) {
      final camposHabilitados = MovimientoBusinessLogic.camposHabilitados(
        tipoMovimiento: _tipoMovimientoSeleccionado!,
      );

      // Campo de entrada
      if (camposHabilitados['valorEntrada'] == true) {
        final etiquetaEntrada = MovimientoBusinessLogic.obtenerEtiquetaCantidad(
          tipoMovimiento: _tipoMovimientoSeleccionado!,
          unidadMedida: unidadMedida,
        );

        campos.add(const SizedBox(width: 16));
        campos.add(
          Expanded(
            child: TextFormField(
              controller: _valorEntradaController,
              decoration: InputDecoration(
                labelText: etiquetaEntrada,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.input),
                suffixText: unidadMedida.contains('Litro') ? 'L' : 'U',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (camposHabilitados['valorEntrada'] == true &&
                    (value == null || value.isEmpty)) {
                  return 'Ingrese ${etiquetaEntrada.toLowerCase()}';
                }
                return null;
              },
            ),
          ),
        );
      }

      // Campo de salida
      if (camposHabilitados['valorSalida'] == true) {
        final etiquetaSalida = MovimientoBusinessLogic.obtenerEtiquetaCantidad(
          tipoMovimiento: _tipoMovimientoSeleccionado!,
          unidadMedida: unidadMedida,
        ).replaceAll('Entrada', 'Salida');

        campos.add(const SizedBox(width: 16));
        campos.add(
          Expanded(
            child: TextFormField(
              controller: _valorSalidaController,
              decoration: InputDecoration(
                labelText: etiquetaSalida,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.output),
                suffixText: unidadMedida.contains('Litro') ? 'L' : 'U',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (camposHabilitados['valorSalida'] == true &&
                    (value == null || value.isEmpty)) {
                  return 'Ingrese ${etiquetaSalida.toLowerCase()}';
                }
                return null;
              },
            ),
          ),
        );
      }
    }

    // En pantallas pequeñas, usar columna en lugar de fila
    if (!isMediumScreen && campos.length > 2) {
      return Column(
        children: [
          Row(children: [campos.first]),
          const SizedBox(height: 16),
          if (campos.length > 2) Row(children: [campos[2]]),
          if (campos.length > 4) ...[
            const SizedBox(height: 16),
            Row(children: [campos[4]]),
          ],
        ],
      );
    }

    return Row(children: campos);
  }

  Widget _buildObservacionesField() {
    return TextFormField(
      controller: _obsController,
      decoration: const InputDecoration(
        labelText: 'Observaciones',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.note),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
      maxLength: 500,
    );
  }

  Widget _buildButtonsSection(bool isMediumOrLargeScreen) {
    if (isMediumOrLargeScreen) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 120,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _resetForm,
              child: const Text('Limpiar'),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _registrarMovimiento,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
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
                      : const Text('Registrar'),
            ),
          ),
        ],
      );
    }

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
            onPressed: _isLoading ? null : _registrarMovimiento,
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text('Registrar Movimiento'),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaMovimiento,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _fechaMovimiento) {
      setState(() {
        _fechaMovimiento = picked;
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _tipoMovimientoSeleccionado = null;
      _contenedorOrigenSeleccionado = null;
      _contenedorDestinoSeleccionado = null;
      _fechaMovimiento = DateTime.now();
    });
    _valorController.clear();
    _valorEntradaController.clear();
    _valorSalidaController.clear();
    _valorSaldoController.clear();
    _obsController.clear();
  }

  Future<void> _registrarMovimiento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(userProvider);

      final movimiento = MovimientoEntity(
        idMovimiento: 0,
        tipoMovimiento: _tipoMovimientoSeleccionado!,
        idOrigen: _contenedorOrigenSeleccionado!.idContenedor,
        codigoOrigen: _contenedorOrigenSeleccionado!.codigo,
        sucursalOrigen: _contenedorOrigenSeleccionado!.codSucursal,
        idDestino: _contenedorDestinoSeleccionado?.idContenedor ?? 0,
        codigoDestino: _contenedorDestinoSeleccionado?.codigo ?? '',
        sucursalDestino: _contenedorDestinoSeleccionado?.codSucursal ?? 0,
        codSucursal: _contenedorOrigenSeleccionado!.codSucursal,
        fechaMovimiento: _fechaMovimiento,
        valor: double.tryParse(_valorController.text) ?? 0.0,
        valorEntrada: double.tryParse(_valorEntradaController.text) ?? 0.0,
        valorSalida: double.tryParse(_valorSalidaController.text) ?? 0.0,
        valorSaldo: double.tryParse(_valorSaldoController.text) ?? 0.0,
        unidadMedida: _contenedorOrigenSeleccionado!.unidadMedida,
        estado: 1,
        obs: _obsController.text,
        codEmpleado: user?.codEmpleado ?? 0,
        idCompraGarrafa: 0,
        audUsuario: user?.codUsuario ?? 0,
      );

      final result = await ref.read(
        registrarMovimientoProvider(movimiento).future,
      );

      if (result) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Movimiento registrado exitosamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _resetForm();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al registrar el movimiento'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
