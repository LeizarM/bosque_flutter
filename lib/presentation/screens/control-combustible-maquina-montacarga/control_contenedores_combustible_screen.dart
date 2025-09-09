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

  // Método para filtrar contenedores por sucursal del usuario
  List<ContenedorEntity> _filtrarContenedoresPorSucursal(
    List<ContenedorEntity> contenedores,
  ) {
    // Mostrar todos los contenedores (sin filtro por sucursal para origen)
    // La lógica de negocio se aplicará en el filtro de destino
    final resultadoSinDuplicados = _eliminarContenedoresDuplicados(
      contenedores,
    );

    // Validar que las selecciones actuales estén en la lista filtrada
    if (_contenedorOrigenSeleccionado != null &&
        !resultadoSinDuplicados.contains(_contenedorOrigenSeleccionado)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _contenedorOrigenSeleccionado = null;
          _contenedorDestinoSeleccionado = null;
          _tipoMovimientoSeleccionado = null;
        });
      });
    }

    if (_contenedorDestinoSeleccionado != null &&
        !resultadoSinDuplicados.contains(_contenedorDestinoSeleccionado)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _contenedorDestinoSeleccionado = null;
          _tipoMovimientoSeleccionado = null;
        });
      });
    }

    return resultadoSinDuplicados;
  }

  // Método auxiliar para eliminar duplicados basado en idContenedor + codigo
  List<ContenedorEntity> _eliminarContenedoresDuplicados(
    List<ContenedorEntity> contenedores,
  ) {
    final Map<String, ContenedorEntity> mapaUnico = {};
    final Set<String> clavesVistas = {};

    for (final contenedor in contenedores) {
      // Crear clave única usando idContenedor + codigo
      final claveUnica = '${contenedor.idContenedor}_${contenedor.codigo}';

      // Solo agregar si no hemos visto esta clave antes
      if (!clavesVistas.contains(claveUnica)) {
        clavesVistas.add(claveUnica);
        mapaUnico[claveUnica] = contenedor;
      } else {
        print(
          'DEBUG: Duplicado ignorado - $claveUnica (${contenedor.descripcion})',
        );
      }
    }

    final resultado = mapaUnico.values.toList();
    print(
      'DEBUG: Contenedores únicos después de filtrado: ${resultado.length}',
    );

    return resultado;
  }

  // Método para filtrar contenedores de destino (permite traspasos entre sucursales)
  List<ContenedorEntity> _filtrarContenedoresDestino(
    List<ContenedorEntity> contenedores,
  ) {
    final user = ref.read(userProvider);
    if (user == null) {
      return _eliminarContenedoresDuplicados(
        contenedores,
      ); // Si no hay usuario, mostrar todos sin duplicados
    }

    List<ContenedorEntity> resultado = [];

    // Aplicar reglas de negocio según el tipo de origen
    if (_contenedorOrigenSeleccionado?.clase == 'CONTENEDOR') {
      // REGLA 2: CONTENEDOR → VEHICULO/MAQUINA/MONTACARGA = SALIDA
      // Mostrar vehículos, máquinas y montacargas de la MISMA SUCURSAL QUE EL CONTENEDOR ORIGEN
      resultado.addAll(
        contenedores.where(
          (contenedor) =>
              (contenedor.clase == 'VEHICULO' ||
                  contenedor.clase == 'MAQUINA' ||
                  contenedor.clase == 'MONTACARGA') &&
              contenedor.codSucursal ==
                  _contenedorOrigenSeleccionado!.codSucursal,
        ),
      );

      // REGLA 3: CONTENEDOR → CONTENEDOR = TRASPASO (solo diferentes sucursales)
      // Mostrar contenedores de OTRAS sucursales (no la misma que el contenedor origen)
      resultado.addAll(
        contenedores.where(
          (contenedor) =>
              contenedor.clase == 'CONTENEDOR' &&
              contenedor.codSucursal !=
                  _contenedorOrigenSeleccionado!.codSucursal,
        ),
      );
    } else if (_contenedorOrigenSeleccionado?.clase == 'VEHICULO') {
      // REGLA 1: VEHICULO → CONTENEDOR = ENTRADA
      // ⚠️ RESTRICCIÓN: NO permitir entradas de garrafas (unidades)
      // Las entradas de garrafas solo se permiten desde control_garrafas_registro_screen.dart
      resultado.addAll(
        contenedores.where(
          (contenedor) =>
              contenedor.clase == 'CONTENEDOR' &&
              contenedor.codSucursal ==
                  _contenedorOrigenSeleccionado!.codSucursal &&
              !_esGarrafa(contenedor), // BLOQUEAR garrafas
        ),
      );
    } else if (_contenedorOrigenSeleccionado?.clase == 'MAQUINA' ||
        _contenedorOrigenSeleccionado?.clase == 'MONTACARGA') {
      // REGLA ADICIONAL: MAQUINA/MONTACARGA → CONTENEDOR = ENTRADA
      // ⚠️ RESTRICCIÓN: NO permitir entradas de garrafas (unidades)
      // Las entradas de garrafas solo se permiten desde control_garrafas_registro_screen.dart
      resultado.addAll(
        contenedores.where(
          (contenedor) =>
              contenedor.clase == 'CONTENEDOR' &&
              contenedor.codSucursal ==
                  _contenedorOrigenSeleccionado!.codSucursal &&
              !_esGarrafa(contenedor), // BLOQUEAR garrafas
        ),
      );
    }
    // Si hay otras clases de origen, no se muestran destinos

    // Eliminar duplicados basados en idContenedor + codigo
    return _eliminarContenedoresDuplicados(resultado);
  }

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

  /// Método para determinar si un contenedor es una garrafa
  /// Las garrafas se identifican por tener unidadMedida que contiene "unidad" o "Unidad"
  bool _esGarrafa(ContenedorEntity contenedor) {
    return MovimientoBusinessLogic.esGarrafa(contenedor.unidadMedida);
  }

  // Método para construir widgets de saldo según tipo de movimiento
  List<Widget> _buildSaldosContenedores() {
    List<Widget> widgets = [];

    if (_tipoMovimientoSeleccionado == null) {
      return widgets;
    }

    // Entrada/Ingreso: Mostrar saldo del destino
    if (_tipoMovimientoSeleccionado == 'Entrada' &&
        _contenedorDestinoSeleccionado != null) {
      widgets.add(
        _buildSaldoWidget(
          contenedor: _contenedorDestinoSeleccionado!,
          titulo: 'INGRESO a ${_contenedorDestinoSeleccionado!.nombreSucursal}',
          descripcion: 'Se está realizando un ingreso de combustible',
          color: Colors.green,
          icono: Icons.input,
        ),
      );
    }
    // Salida: Mostrar saldo del origen
    else if (_tipoMovimientoSeleccionado == 'Salida' &&
        _contenedorOrigenSeleccionado != null) {
      widgets.add(
        _buildSaldoWidget(
          contenedor: _contenedorOrigenSeleccionado!,
          titulo: 'SALIDA de ${_contenedorOrigenSeleccionado!.nombreSucursal}',
          descripcion: 'Se está realizando una salida de combustible',
          color: Colors.orange,
          icono: Icons.output,
        ),
      );
    }
    // Traspaso: Mostrar saldo de origen y destino
    else if (_tipoMovimientoSeleccionado == 'Traspaso') {
      // Mensaje descriptivo del traspaso
      if (_contenedorOrigenSeleccionado != null &&
          _contenedorDestinoSeleccionado != null) {
        widgets.add(
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              border: Border.all(color: Colors.purple.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.swap_horiz, color: Colors.purple.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'TRASPASO: ${_contenedorOrigenSeleccionado!.nombreSucursal} → ${_contenedorDestinoSeleccionado!.nombreSucursal}',
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (_contenedorOrigenSeleccionado != null) {
        widgets.add(
          _buildSaldoWidget(
            contenedor: _contenedorOrigenSeleccionado!,
            titulo: 'Saldo Origen',
            descripcion:
                'Sucursal: ${_contenedorOrigenSeleccionado!.nombreSucursal}',
            color: Colors.red,
            icono: Icons.call_made,
          ),
        );
      }

      if (_contenedorDestinoSeleccionado != null) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(
          _buildSaldoWidget(
            contenedor: _contenedorDestinoSeleccionado!,
            titulo: 'Saldo Destino',
            descripcion:
                'Sucursal: ${_contenedorDestinoSeleccionado!.nombreSucursal}',
            color: Colors.blue,
            icono: Icons.call_received,
          ),
        );
      }
    }

    return widgets;
  }

  // Widget auxiliar para construir el contenedor de saldo
  Widget _buildSaldoWidget({
    required ContenedorEntity contenedor,
    required String titulo,
    required String descripcion,
    required MaterialColor color,
    required IconData icono,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: color.shade50,
        border: Border.all(color: color.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icono, color: color.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: color.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  descripcion,
                  style: TextStyle(
                    color: color.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Saldo: ${contenedor.saldoActualCombustible} ${contenedor.unidadMedida}',
                  style: TextStyle(
                    color: color.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Tipo: ${contenedor.idTipo}',
                  style: TextStyle(
                    color: color.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye mensajes informativos sobre restricciones de garrafas
  List<Widget> _buildMensajeRestriccionGarrafas() {
    // Solo mostrar el mensaje cuando hay un origen seleccionado que podría generar entradas
    if (_contenedorOrigenSeleccionado?.clase == 'VEHICULO' ||
        _contenedorOrigenSeleccionado?.clase == 'MAQUINA' ||
        _contenedorOrigenSeleccionado?.clase == 'MONTACARGA') {
      // Verificar si el contenedor destino filtrado está vacío debido a restricciones de garrafas
      final contenedoresAsync = ref.read(contenedoresProvider);
      return contenedoresAsync.when(
        data: (contenedores) {
          final contenedoresDestino = _filtrarContenedoresDestino(contenedores);

          // Verificar si hay contenedores de garrafas que fueron filtrados
          final garrafasDisponibles =
              contenedores
                  .where(
                    (c) =>
                        c.clase == 'CONTENEDOR' &&
                        c.codSucursal ==
                            _contenedorOrigenSeleccionado!.codSucursal &&
                        _esGarrafa(c),
                  )
                  .toList();

          if (contenedoresDestino.isEmpty && garrafasDisponibles.isNotEmpty) {
            return [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Las entradas de garrafas (unidades) solo se pueden registrar desde el formulario específico de registro de garrafas.',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ];
          }
          return [];
        },
        loading: () => [],
        error: (_, __) => [],
      );
    }
    return [];
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

                                // Fecha de Movimiento - Comentado, se manejará en el backend
                                // _buildDateField(),
                                // const SizedBox(height: 16),

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
        // Filtrar contenedores según la preferencia del usuario
        final contenedoresFiltrados = _filtrarContenedoresPorSucursal(
          contenedores,
        );

        // Debug detallado de todas las clases
        print('=== DEBUG CONTENEDORES DETALLADO ===');
        print('Total elementos originales: ${contenedores.length}');
        print('Total elementos filtrados: ${contenedoresFiltrados.length}');

        // Agrupar por clase para ver qué hay
        Map<String, int> clasesCounts = {};
        for (var contenedor in contenedoresFiltrados) {
          clasesCounts[contenedor.clase] =
              (clasesCounts[contenedor.clase] ?? 0) + 1;
        }

        print('Distribución por clases:');
        clasesCounts.forEach((clase, count) {
          print('  $clase: $count elementos');
        });

        // Mostrar algunos ejemplos de cada clase
        for (var clase in clasesCounts.keys) {
          var ejemplos = contenedoresFiltrados
              .where((c) => c.clase == clase)
              .take(2);
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
            // Información sobre el filtrado automático
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Origen: Solo de su sucursal • Destino: Incluye otras sucursales para traspasos',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenedor Origen - Siempre visible
            DropdownButtonFormField<String>(
              value:
                  _contenedorOrigenSeleccionado != null
                      ? '${_contenedorOrigenSeleccionado!.idContenedor}_${_contenedorOrigenSeleccionado!.codigo}'
                      : null,
              decoration: const InputDecoration(
                labelText: 'Origen',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
              isExpanded: true, // Resolver overflow
              items: () {
                // Asegurar que no hay duplicados en el dropdown de origen
                final contenedoresUnicos = _eliminarContenedoresDuplicados(
                  contenedoresFiltrados,
                );

                return contenedoresUnicos.map((ContenedorEntity contenedor) {
                  // Usar clave única como value
                  final claveUnica =
                      '${contenedor.idContenedor}_${contenedor.codigo}';
                  return DropdownMenuItem<String>(
                    value: claveUnica,
                    child: Tooltip(
                      message:
                          '${contenedor.codigo} - ${contenedor.descripcion}\nSaldo: ${contenedor.saldoActualCombustible} ${contenedor.unidadMedida}',
                      child: Text(
                        contenedor.descripcion,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  );
                }).toList();
              }(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  // Buscar el contenedor correspondiente a la clave única
                  final contenedorSeleccionado = contenedoresFiltrados
                      .firstWhere(
                        (c) => '${c.idContenedor}_${c.codigo}' == newValue,
                      );
                  setState(() {
                    _contenedorOrigenSeleccionado = contenedorSeleccionado;
                  });
                } else {
                  setState(() {
                    _contenedorOrigenSeleccionado = null;
                  });
                }
                _determinarTipoMovimiento();
              },
              validator: (value) {
                if (value == null) {
                  return 'Por favor seleccione un origen';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Contenedor Destino - Siempre visible
            Builder(
              builder: (context) {
                // Calcular items disponibles
                final itemsDisponibles =
                    (() {
                      try {
                        // Aplicar todos los filtros y eliminar duplicados al final
                        final contenedoresDestino = _filtrarContenedoresDestino(
                          contenedores,
                        );
                        final contenedoresValidos =
                            contenedoresDestino
                                .where((c) => _esContenedorDestinoValido(c))
                                .toList();

                        // Eliminar duplicados finales basado en idContenedor + codigo
                        final contenedoresUnicos =
                            _eliminarContenedoresDuplicados(
                              contenedoresValidos,
                            );

                        // Crear un mapa para garantizar valores únicos en el dropdown
                        final Map<String, ContenedorEntity> itemsUnicos = {};
                        final Set<String> clavesUsadas = {};

                        for (var contenedor in contenedoresUnicos) {
                          final claveUnica =
                              '${contenedor.idContenedor}_${contenedor.codigo}';

                          // Solo agregar si la clave no ha sido usada
                          if (!clavesUsadas.contains(claveUnica)) {
                            clavesUsadas.add(claveUnica);
                            itemsUnicos[claveUnica] = contenedor;
                          } else {
                            print(
                              'DUPLICADO ELIMINADO en dropdown: $claveUnica - ${contenedor.descripcion}',
                            );
                          }
                        }

                        print(
                          'DEBUG: Items únicos para dropdown destino: ${itemsUnicos.length}',
                        );
                        print('DEBUG: Claves: ${itemsUnicos.keys.toList()}');

                        return itemsUnicos.entries.map((entry) {
                          final claveUnica = entry.key;
                          final contenedor = entry.value;

                          // Debug específico para ver saldos
                          print(
                            'CONTENEDOR DESTINO: ${contenedor.descripcion}',
                          );
                          print('  - Código: ${contenedor.codigo}');
                          print('  - Sucursal: ${contenedor.codSucursal}');
                          print(
                            '  - Saldo: ${contenedor.saldoActualCombustible}',
                          );
                          print('  - Unidad: ${contenedor.unidadMedida}');

                          return DropdownMenuItem<String>(
                            value: claveUnica,
                            child: Tooltip(
                              message:
                                  '${contenedor.codigo} - ${contenedor.descripcion}\nSucursal: ${contenedor.nombreSucursal}\nSaldo: ${contenedor.saldoActualCombustible} ${contenedor.unidadMedida}',
                              child: Text(
                                contenedor.descripcion,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          );
                        }).toList();
                      } catch (e) {
                        print('ERROR creando items dropdown destino: $e');
                        return <DropdownMenuItem<String>>[];
                      }
                    })();

                // Calcular valor actual válido
                String? valorActual =
                    _contenedorDestinoSeleccionado != null
                        ? '${_contenedorDestinoSeleccionado!.idContenedor}_${_contenedorDestinoSeleccionado!.codigo}'
                        : null;

                // Verificar si el valor actual está en los items disponibles
                if (valorActual != null) {
                  final esValorValido = itemsDisponibles.any(
                    (item) => item.value == valorActual,
                  );
                  if (!esValorValido) {
                    print('VALOR INVÁLIDO detectado: $valorActual');
                    print(
                      'Items disponibles: ${itemsDisponibles.map((e) => e.value).toList()}',
                    );
                    // Limpiar selección si no está disponible
                    valorActual = null;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _contenedorDestinoSeleccionado = null;
                        });
                      }
                    });
                  }
                }

                return DropdownButtonFormField<String>(
                  value: valorActual,
                  decoration: const InputDecoration(
                    labelText: 'Destino',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                  isExpanded: true, // Resolver overflow
                  items: itemsDisponibles,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      try {
                        // Buscar el contenedor en los datos originales
                        ContenedorEntity? contenedorEncontrado;

                        // Buscar primero en contenedores filtrados para destino
                        final contenedoresDestino = _filtrarContenedoresDestino(
                          contenedores,
                        );

                        try {
                          contenedorEncontrado = contenedoresDestino.firstWhere(
                            (c) => '${c.idContenedor}_${c.codigo}' == newValue,
                          );
                        } catch (e) {
                          // Si no se encuentra, buscar en toda la lista
                          print(
                            'FALLBACK: Buscando en lista completa para clave: $newValue',
                          );
                          try {
                            contenedorEncontrado = contenedores.firstWhere(
                              (c) =>
                                  '${c.idContenedor}_${c.codigo}' == newValue,
                            );
                            print(
                              'ENCONTRADO en lista completa: ${contenedorEncontrado.descripcion}',
                            );
                          } catch (e2) {
                            print(
                              'ERROR: Contenedor no encontrado en ninguna lista: $newValue',
                            );
                            contenedorEncontrado = null;
                          }
                        }

                        setState(() {
                          _contenedorDestinoSeleccionado = contenedorEncontrado;
                        });

                        if (contenedorEncontrado != null) {
                          print(
                            'DESTINO SELECCIONADO: ${contenedorEncontrado.descripcion} (${contenedorEncontrado.idContenedor}_${contenedorEncontrado.codigo})',
                          );
                          print(
                            'SALDO POR SUCURSAL: ${contenedorEncontrado.saldoActualCombustible} ${contenedorEncontrado.unidadMedida} - Sucursal: ${contenedorEncontrado.codSucursal}',
                          );
                        }
                      } catch (e) {
                        print('ERROR GENERAL en onChanged destino: $e');
                        setState(() {
                          _contenedorDestinoSeleccionado = null;
                        });
                      }
                    } else {
                      setState(() {
                        _contenedorDestinoSeleccionado = null;
                      });
                    }
                    _determinarTipoMovimiento();
                  },
                  validator: (value) {
                    // Solo requerido para traspaso
                    if (_tipoMovimientoSeleccionado == 'Traspaso' &&
                        value == null) {
                      return 'Por favor seleccione un destino';
                    }
                    return null;
                  },
                );
              },
            ),

            // Mostrar saldos según tipo de movimiento
            ..._buildSaldosContenedores(),

            // Mostrar mensaje informativo sobre restricciones de garrafas
            ..._buildMensajeRestriccionGarrafas(),
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

  Widget _buildValoresSection(bool isMediumScreen) {
    // Determinar qué campos mostrar según el tipo de movimiento
    List<Widget> campos = [];

    // Obtener unidad de medida del contenedor origen
    final unidadMedida =
        _contenedorOrigenSeleccionado?.unidadMedida ?? 'Litros';

    // Campo Valor - Comentado, se calculará automáticamente en el backend
    // campos.add(
    //   Expanded(
    //     child: TextFormField(
    //       controller: _valorController,
    //       decoration: const InputDecoration(
    //         labelText: 'Valor',
    //         border: OutlineInputBorder(),
    //         prefixIcon: Icon(Icons.attach_money),
    //         suffixText: 'L',
    //       ),
    //       keyboardType: const TextInputType.numberWithOptions(decimal: true),
    //       inputFormatters: [
    //         FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
    //       ],
    //       validator: (value) {
    //         if (value == null || value.isEmpty) {
    //           return 'Ingrese un valor';
    //         }
    //         return null;
    //       },
    //     ),
    //   ),
    // );

    // Campos específicos según tipo de movimiento
    if (_tipoMovimientoSeleccionado != null) {
      final camposHabilitados = MovimientoBusinessLogic.camposHabilitados(
        tipoMovimiento: _tipoMovimientoSeleccionado!,
      );

      print('DEBUG: Tipo movimiento: $_tipoMovimientoSeleccionado');
      print('DEBUG: Campos habilitados: $camposHabilitados');

      // Campo de entrada
      if (camposHabilitados['valorEntrada'] == true) {
        String etiquetaEntrada;
        if (_tipoMovimientoSeleccionado == 'Traspaso') {
          etiquetaEntrada = 'Cantidad a Recibir (Destino)';
        } else {
          etiquetaEntrada = MovimientoBusinessLogic.obtenerEtiquetaCantidad(
            tipoMovimiento: _tipoMovimientoSeleccionado!,
            unidadMedida: unidadMedida,
          );
        }

        campos.add(
          Expanded(
            child: TextFormField(
              controller: _valorEntradaController,
              decoration: InputDecoration(
                labelText: etiquetaEntrada,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.input),
                suffixText: unidadMedida.contains('Litro') ? 'L' : 'U',
                helperText:
                    _tipoMovimientoSeleccionado == 'Traspaso'
                        ? 'Cantidad que ingresa al contenedor destino'
                        : null,
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

                // Validación de saldo para entrada en traspasos
                if (camposHabilitados['valorEntrada'] == true &&
                    value != null &&
                    value.isNotEmpty &&
                    _tipoMovimientoSeleccionado == 'Traspaso' &&
                    _contenedorOrigenSeleccionado != null) {
                  double? cantidad = double.tryParse(value);
                  if (cantidad != null && cantidad > 0) {
                    double saldoOrigen =
                        _contenedorOrigenSeleccionado!.saldoActualCombustible;
                    if (cantidad > saldoOrigen) {
                      return 'No puede exceder el saldo disponible ($saldoOrigen)';
                    }
                  }
                }

                return null;
              },
            ),
          ),
        );
      }

      // Campo de salida
      if (camposHabilitados['valorSalida'] == true) {
        String etiquetaSalida;
        if (_tipoMovimientoSeleccionado == 'Traspaso') {
          etiquetaSalida = 'Cantidad a Enviar (Origen)';
        } else {
          etiquetaSalida = MovimientoBusinessLogic.obtenerEtiquetaCantidad(
            tipoMovimiento: _tipoMovimientoSeleccionado!,
            unidadMedida: unidadMedida,
          ).replaceAll('Entrada', 'Salida');
        }

        // Agregar espaciado si ya hay campos
        if (campos.isNotEmpty) {
          campos.add(const SizedBox(width: 16));
        }

        campos.add(
          Expanded(
            child: TextFormField(
              controller: _valorSalidaController,
              decoration: InputDecoration(
                labelText: etiquetaSalida,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.output),
                suffixText: unidadMedida.contains('Litro') ? 'L' : 'U',
                helperText:
                    _tipoMovimientoSeleccionado == 'Traspaso'
                        ? 'Cantidad que sale del contenedor origen'
                        : null,
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

                // Validación de saldo para salidas y traspasos
                if (camposHabilitados['valorSalida'] == true &&
                    value != null &&
                    value.isNotEmpty &&
                    (_tipoMovimientoSeleccionado == 'Salida' ||
                        _tipoMovimientoSeleccionado == 'Traspaso') &&
                    _contenedorOrigenSeleccionado != null) {
                  double? cantidad = double.tryParse(value);
                  if (cantidad != null && cantidad > 0) {
                    double saldoOrigen =
                        _contenedorOrigenSeleccionado!.saldoActualCombustible;
                    if (cantidad > saldoOrigen) {
                      return 'No puede exceder el saldo disponible ($saldoOrigen)';
                    }
                  }
                }

                return null;
              },
            ),
          ),
        );
      }
    }

    print('DEBUG: Total campos creados: ${campos.length}');

    // Si no hay campos, mostrar un mensaje informativo
    if (campos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Seleccione origen y destino para habilitar campos de cantidad',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      );
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
              onPressed: _isLoading ? null : _mostrarConfirmacion,
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
            onPressed: _isLoading ? null : _mostrarConfirmacion,
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

  // Método para mostrar los datos preliminares antes de confirmar
  void _mostrarConfirmacion() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = ref.read(userProvider);

    // Calcular valores según el tipo de movimiento
    double valorEntrada = 0.0;
    double valorSalida = 0.0;
    double valorFinal = 0.0;

    if (_tipoMovimientoSeleccionado == 'Entrada') {
      valorEntrada = double.tryParse(_valorEntradaController.text) ?? 0.0;
      valorSalida = 0.0;
      valorFinal = valorEntrada;
    } else if (_tipoMovimientoSeleccionado == 'Salida') {
      valorEntrada = 0.0;
      valorSalida = double.tryParse(_valorSalidaController.text) ?? 0.0;
      valorFinal = valorSalida;
    } else if (_tipoMovimientoSeleccionado == 'Traspaso') {
      valorEntrada = double.tryParse(_valorEntradaController.text) ?? 0.0;
      valorSalida = double.tryParse(_valorSalidaController.text) ?? 0.0;
      valorFinal = valorSalida;
    }

    // VALIDACIONES DE SALDO: Verificar que no se excedan los saldos disponibles
    String? mensajeErrorSaldo =
        MovimientoBusinessLogic.validarSaldosSuficientes(
          tipoMovimiento: _tipoMovimientoSeleccionado!,
          cantidad: valorFinal,
          saldoOrigen:
              _contenedorOrigenSeleccionado?.saldoActualCombustible ?? 0.0,
          saldoDestino: _contenedorDestinoSeleccionado?.saldoActualCombustible,
        );

    // Si hay error de saldo, mostrar mensaje y cancelar operación
    if (mensajeErrorSaldo != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeErrorSaldo),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // VALIDACIÓN ESPECIAL: Bloquear entradas de garrafas
    if (_tipoMovimientoSeleccionado == 'Entrada' &&
        _contenedorDestinoSeleccionado != null &&
        _esGarrafa(_contenedorDestinoSeleccionado!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.block, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Las entradas de garrafas (unidades) solo se pueden registrar desde el formulario específico de registro de garrafas.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Determinar unidad de medida
    String unidadMedida = '';
    if (_tipoMovimientoSeleccionado == 'Entrada') {
      unidadMedida =
          _contenedorDestinoSeleccionado?.unidadMedida ??
          _contenedorOrigenSeleccionado!.unidadMedida;
    } else {
      unidadMedida = _contenedorOrigenSeleccionado!.unidadMedida;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Movimiento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Datos del movimiento a registrar:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildDatoConfirmacion(
                  'Tipo de Movimiento',
                  _tipoMovimientoSeleccionado ?? '',
                ),
                _buildDatoConfirmacion(
                  'Origen',
                  _contenedorOrigenSeleccionado?.descripcion ?? '',
                ),
                // Mostrar saldo actual del origen
                _buildDatoConfirmacion(
                  'Saldo Actual Origen',
                  '${_contenedorOrigenSeleccionado?.saldoActualCombustible ?? 0.0} ${_contenedorOrigenSeleccionado?.unidadMedida ?? ''}',
                ),
                if (_contenedorDestinoSeleccionado != null)
                  _buildDatoConfirmacion(
                    'Destino',
                    _contenedorDestinoSeleccionado!.descripcion,
                  ),
                // Mostrar saldo actual del destino si existe
                if (_contenedorDestinoSeleccionado != null)
                  _buildDatoConfirmacion(
                    'Saldo Actual Destino',
                    '${_contenedorDestinoSeleccionado!.saldoActualCombustible} ${_contenedorDestinoSeleccionado!.unidadMedida}',
                  ),
                _buildDatoConfirmacion('Valor', '$valorFinal $unidadMedida'),
                if (valorEntrada > 0)
                  _buildDatoConfirmacion(
                    'Cantidad Entrada',
                    '$valorEntrada $unidadMedida',
                  ),
                if (valorSalida > 0)
                  _buildDatoConfirmacion(
                    'Cantidad Salida',
                    '$valorSalida $unidadMedida',
                  ),
                if (_obsController.text.isNotEmpty)
                  _buildDatoConfirmacion('Observaciones', _obsController.text),
                const SizedBox(height: 16),
                const Text(
                  'Datos técnicos:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                _buildDatoConfirmacion(
                  'Usuario',
                  user?.nombreCompleto ?? 'N/A',
                  isSmall: true,
                ),
                _buildDatoConfirmacion(
                  'Sucursal Usuario',
                  '${user?.codSucursal ?? 0}',
                  isSmall: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _registrarMovimiento();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar Registro'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDatoConfirmacion(
    String label,
    String value, {
    bool isSmall = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isSmall ? 11 : 14,
                color: isSmall ? Colors.grey[600] : null,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmall ? 11 : 14,
                color: isSmall ? Colors.grey[600] : null,
              ),
            ),
          ),
        ],
      ),
    );
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

      // Determinar valorEntrada y valorSalida según el tipo de movimiento
      double valorEntrada = 0.0;
      double valorSalida = 0.0;
      double valorFinal =
          0.0; // Este será el valor que se asigna al campo "valor"

      if (_tipoMovimientoSeleccionado == 'Entrada') {
        valorEntrada = double.tryParse(_valorEntradaController.text) ?? 0.0;
        valorSalida = 0.0;
        valorFinal = valorEntrada; // En entrada, valor = valorEntrada
      } else if (_tipoMovimientoSeleccionado == 'Salida') {
        valorEntrada = 0.0;
        valorSalida = double.tryParse(_valorSalidaController.text) ?? 0.0;
        valorFinal = valorSalida; // En salida, valor = valorSalida
      } else if (_tipoMovimientoSeleccionado == 'Traspaso') {
        // Para traspaso usar los valores específicos de los campos
        valorEntrada = double.tryParse(_valorEntradaController.text) ?? 0.0;
        valorSalida = double.tryParse(_valorSalidaController.text) ?? 0.0;
        valorFinal = valorSalida; // En traspaso, valor = valorSalida
      }

      // VALIDACIÓN FINAL DE SALDO: Verificar nuevamente antes de registrar
      String? mensajeErrorSaldo =
          MovimientoBusinessLogic.validarSaldosSuficientes(
            tipoMovimiento: _tipoMovimientoSeleccionado!,
            cantidad: valorFinal,
            saldoOrigen:
                _contenedorOrigenSeleccionado?.saldoActualCombustible ?? 0.0,
            saldoDestino:
                _contenedorDestinoSeleccionado?.saldoActualCombustible,
          );

      // Si hay error de saldo, mostrar mensaje y cancelar operación
      if (mensajeErrorSaldo != null) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeErrorSaldo),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // VALIDACIÓN FINAL: Bloquear entradas de garrafas (doble verificación)
      if (_tipoMovimientoSeleccionado == 'Entrada' &&
          _contenedorDestinoSeleccionado != null &&
          _esGarrafa(_contenedorDestinoSeleccionado!)) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.block, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ERROR CRÍTICO: Intento de entrada de garrafa detectado. Las entradas de garrafas solo se permiten desde el formulario específico.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 6),
          ),
        );
        return;
      }

      // Determinar estado: 1 si es de vehículo a contenedor, 0 en otros casos
      int estado = 0;
      if (_contenedorOrigenSeleccionado?.clase == 'VEHICULO' &&
          _contenedorDestinoSeleccionado?.clase == 'CONTENEDOR') {
        estado = 1;
      }

      // Obtener codSucursal del usuario usando el método getCodSucursal
      final userNotifier = ref.read(userProvider.notifier);
      final codSucursalUsuario = await userNotifier.getCodSucursal();
      print(
        'DEBUG: codSucursal obtenido desde getCodSucursal(): $codSucursalUsuario',
      );

      // Determinar unidad de medida según el tipo de movimiento
      String unidadMedida = '';
      if (_tipoMovimientoSeleccionado == 'Entrada') {
        // En caso de entrada/ingreso: unidad de medida del contenedor destino
        unidadMedida =
            _contenedorDestinoSeleccionado?.unidadMedida ??
            _contenedorOrigenSeleccionado!.unidadMedida;
      } else if (_tipoMovimientoSeleccionado == 'Salida') {
        // En caso de salida: unidad de medida del contenedor origen (entrada)
        unidadMedida = _contenedorOrigenSeleccionado!.unidadMedida;
      } else if (_tipoMovimientoSeleccionado == 'Traspaso') {
        // En caso de traspaso: unidad de medida del contenedor origen (salida)
        unidadMedida = _contenedorOrigenSeleccionado!.unidadMedida;
      } else {
        // Por defecto usar el contenedor origen
        unidadMedida = _contenedorOrigenSeleccionado!.unidadMedida;
      }

      final movimiento = MovimientoEntity(
        idMovimiento: 0,
        tipoMovimiento: _tipoMovimientoSeleccionado!,
        idOrigen: _contenedorOrigenSeleccionado!.idContenedor,
        codigoOrigen: _contenedorOrigenSeleccionado!.codigo,
        sucursalOrigen: _contenedorOrigenSeleccionado!.codSucursal,
        idDestino: _contenedorDestinoSeleccionado?.idContenedor ?? 0,
        codigoDestino: _contenedorDestinoSeleccionado?.codigo ?? '',
        sucursalDestino: _contenedorDestinoSeleccionado?.codSucursal ?? 0,
        codSucursal: codSucursalUsuario, // codSucursal del usuario
        fechaMovimiento: _fechaMovimiento,
        valor:
            valorFinal, // Valor según tipo: valorEntrada (entrada), valorSalida (salida/traspaso)
        valorEntrada: valorEntrada,
        valorSalida: valorSalida,
        valorSaldo: 0.0, // Se mejorará en el backend
        unidadMedida: unidadMedida,
        estado: estado,
        obs: _obsController.text,
        codEmpleado: user?.codEmpleado ?? 0,
        idCompraGarrafa: 0, // En este caso es cero
        audUsuario: user?.codUsuario ?? 0,
        fechaMovimientoString: '',
        origen: '',
        destino: '',
        nombreCompleto: '',
        fechaInicio: DateTime.now(),
        fechaFin: DateTime.now(),
        idTipo: 0,
        nombreSucursal: '',
        tipo: '',
      );

      // Mostrar en consola para debug antes de enviar
      print('=== MOVIMIENTO A REGISTRAR ===');
      print('tipoMovimiento: ${movimiento.tipoMovimiento}');
      print('idOrigen: ${movimiento.idOrigen}');
      print('codigoOrigen: ${movimiento.codigoOrigen}');
      print('sucursalOrigen: ${movimiento.sucursalOrigen}');
      print('idDestino: ${movimiento.idDestino}');
      print('codigoDestino: ${movimiento.codigoDestino}');
      print('sucursalDestino: ${movimiento.sucursalDestino}');
      print('codSucursal: ${movimiento.codSucursal}');
      print('fechaMovimiento: ${movimiento.fechaMovimiento}');
      print('valor: ${movimiento.valor}');
      print('valorEntrada: ${movimiento.valorEntrada}');
      print('valorSalida: ${movimiento.valorSalida}');
      print('valorSaldo: ${movimiento.valorSaldo}');
      print('unidadMedida: ${movimiento.unidadMedida}');
      print('estado: ${movimiento.estado}');
      print('obs: ${movimiento.obs}');
      print('codEmpleado: ${movimiento.codEmpleado}');
      print('idCompraGarrafa: ${movimiento.idCompraGarrafa}');
      print('audUsuario: ${movimiento.audUsuario}');
      print('===============================');

      final result = await ref.read(
        registrarMovimientoProvider(movimiento).future,
      );

      if (result) {
        if (mounted) {
          // RECARGAR DATOS: Invalidar el provider para actualizar los saldos actuales
          // Esto es crucial porque después de un movimiento, los saldos de los contenedores cambian
          // y necesitamos mostrar la información actualizada en los dropdowns
          ref.invalidate(contenedoresProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Movimiento registrado exitosamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Limpiar formulario para permitir nuevos movimientos con datos frescos
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
