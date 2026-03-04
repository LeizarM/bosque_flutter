// lib/presentation/widgets/registro_empleado/form_afiliacion_seguro.dart

import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/domain/entities/afiliacion_seguro_entity.dart';
import 'package:bosque_flutter/domain/entities/seguro_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_seguro.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/validadores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormAfiliacionSeguro extends ConsumerStatefulWidget {
  final int codEmpleado;
  final AfiliacionSeguroEntity? afiliacionInicial;
  final int audUsuario;
  final Function(AfiliacionSeguroEntity) onSave;
  final VoidCallback onCancel;

  const FormAfiliacionSeguro({
    Key? key,
    required this.codEmpleado,
    this.afiliacionInicial,
    required this.audUsuario,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  ConsumerState<FormAfiliacionSeguro> createState() =>
      _FormAfiliacionSeguroState();
}

class _FormAfiliacionSeguroState extends ConsumerState<FormAfiliacionSeguro> {
  late GlobalKey<FormState> _formKey;
  late TextEditingController _nroAfiliacionCtrl;
  late TextEditingController _fechaAfiliacionCtrl;
  late TextEditingController _fechaBajaCtrl;
  late int _codSeguroSeleccionado;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _nroAfiliacionCtrl =
        TextEditingController(text: widget.afiliacionInicial?.nroAfiliacion ?? '');
    _fechaAfiliacionCtrl = TextEditingController(
      text: widget.afiliacionInicial != null
          ? FechaUtils.formatDate(widget.afiliacionInicial!.fechaAfiliacion)
          : '',
    );
    _fechaBajaCtrl = TextEditingController(
      text: widget.afiliacionInicial?.fechaBaja != null
          ? FechaUtils.formatDate(widget.afiliacionInicial!.fechaBaja!)
          : '',
    );
    _codSeguroSeleccionado = widget.afiliacionInicial?.codSeguro ?? 0;
  }

  @override
  void dispose() {
    _nroAfiliacionCtrl.dispose();
    _fechaAfiliacionCtrl.dispose();
    _fechaBajaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final segurosAsync = ref.watch(obtenerSeguros);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.only(bottom: context.spacing),
            child: Text(
              widget.afiliacionInicial == null
                  ? 'Nueva Afiliación al Seguro'
                  : 'Editar Afiliación al Seguro',
              style: context.subtitleStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: context.spacing),

          // GRUPO 1: Seguro (Full Width)
          _buildSeguroDropdown(context, segurosAsync),
          SizedBox(height: context.largeSpacing),

          // GRUPO 2: Número y Fechas (Responsive)
          context.isMobile
              ? _buildMobileLayout()
              : _buildWebLayout(),

          SizedBox(height: context.largeSpacing),

          // Botones
          _buildActionButtons(context),
        ],
      ),
    );
  }

  // ============================================================================
  // LAYOUTS RESPONSIVE
  // ============================================================================

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Número de Afiliación
        _buildNroAfiliacionField(),
        SizedBox(height: context.largeSpacing),

        // Fecha de Afiliación
        _buildFechaAfiliacionField(),
        SizedBox(height: context.largeSpacing),

        // Fecha de Baja
        _buildFechaBajaField(),
      ],
    );
  }

  Widget _buildWebLayout() {
    return Column(
      children: [
        // Row 1: Número de Afiliación (Full Width)
        _buildNroAfiliacionField(),
        SizedBox(height: context.largeSpacing),

        // Row 2: Fechas en 2 columnas
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFechaAfiliacionField(),
            ),
            SizedBox(width: context.spacing),
            Expanded(
              child: _buildFechaBajaField(),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // DROPDOWN SEGUROS
  // ============================================================================

  Widget _buildSeguroDropdown(
    BuildContext context,
    AsyncValue<List<SeguroEntity>> segurosAsync,
  ) {
    return segurosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) {
        console('❌ Error al cargar seguros: $err');
        return Text('Error al cargar seguros: $err');
      },
      data: (seguros) {
        if (context.isMobile) {
          // Layout móvil: Dropdown full width, botón debajo
          return Column(
            children: [
              DropdownButtonFormField<int>(
                value: _codSeguroSeleccionado != 0 ? _codSeguroSeleccionado : null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Seguro',
                  hintText: 'Seleccione un seguro',
                  border: OutlineInputBorder(
                    borderRadius: context.borderRadius,
                  ),
                  prefixIcon: const Icon(Icons.shield),
                ),
                items: seguros
                    .map(
                      (seguro) => DropdownMenuItem<int>(
                        value: seguro.codSeguro,
                        child: Text(
                          '${seguro.nombre} - ${seguro.regional}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (codSeguro) {
                  setState(() => _codSeguroSeleccionado = codSeguro ?? 0);
                },
                validator: (value) {
                  if (value == null || value == 0) {
                    return 'El seguro es obligatorio';
                  }
                  return null;
                },
              ),
              SizedBox(height: context.spacing),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Ver Seguros'),
                  onPressed: () => _showSegurosDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue,
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                ),
              ),
            ],
          );
        } else {
          // Layout web: Dropdown + Botón en Row
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _codSeguroSeleccionado != 0 ? _codSeguroSeleccionado : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Seguro',
                    hintText: 'Seleccione un seguro',
                    border: OutlineInputBorder(
                      borderRadius: context.borderRadius,
                    ),
                    prefixIcon: const Icon(Icons.shield),
                  ),
                  items: seguros
                      .map(
                        (seguro) => DropdownMenuItem<int>(
                          value: seguro.codSeguro,
                          child: Text('${seguro.nombre} - ${seguro.regional}'),
                        ),
                      )
                      .toList(),
                  onChanged: (codSeguro) {
                    setState(() => _codSeguroSeleccionado = codSeguro ?? 0);
                  },
                  validator: (value) {
                    if (value == null || value == 0) {
                      return 'El seguro es obligatorio';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: context.spacing),
              Padding(
                padding: EdgeInsets.only(top: context.spacing),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Ver Seguros'),
                  onPressed: () => _showSegurosDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue,
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

    // ============================================================================
  // DIALOG DE SEGUROS
  // ============================================================================

  void _showSegurosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: context.isMobile ? context.spacing / 2 : 100,
          vertical: context.isMobile ? context.spacing : context.spacing,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        child: SizedBox(
          width: context.isMobile ? double.infinity : 800,
          height: context.isMobile ? 500 : 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Gestión de Seguros'),
                automaticallyImplyLeading: true,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(context.spacing),
                    child: const DetalleSeguro(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // CAMPOS DEL FORMULARIO
  // ============================================================================

  Widget _buildNroAfiliacionField() {
    return TextFormField(
      controller: _nroAfiliacionCtrl,
      decoration: InputDecoration(
        labelText: 'Número de Afiliación',
        hintText: 'Ej: 123456-A',
        border: OutlineInputBorder(
          borderRadius: context.borderRadius,
        ),
        prefixIcon: const Icon(Icons.badge),
      ),
      validator: validarNroAfiliacion,
    );
  }

  Widget _buildFechaAfiliacionField() {
    return CustomDatePicker(
      controller: _fechaAfiliacionCtrl,
      label: 'Fecha de Afiliación',
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      validator: (value) => validarFechaAfiliacion(
        value,
        fechaBajaText: _fechaBajaCtrl.text,
      ),
    );
  }

  Widget _buildFechaBajaField() {
    return CustomDatePicker(
      controller: _fechaBajaCtrl,
      label: 'Fecha de Baja (Opcional)',
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      validator: (value) => validarFechaBaja(
        value,
        fechaAfiliacionText: _fechaAfiliacionCtrl.text,
      ),
    );
  }

  // ============================================================================
  // BOTONES DE ACCIÓN
  // ============================================================================

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancelar'),
        ),
        SizedBox(width: context.spacing),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
          onPressed: _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // LÓGICA DE GUARDADO
  // ============================================================================

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      showErrorMessage(context, 'Por favor complete los campos obligatorios');
      return;
    }

    final fechaAfiliacion = FechaUtils.parseDate(_fechaAfiliacionCtrl.text);
    final fechaBaja = _fechaBajaCtrl.text.isNotEmpty
        ? FechaUtils.parseDate(_fechaBajaCtrl.text)
        : null;

    if (fechaAfiliacion == null) {
      showErrorMessage(context, 'Fecha de afiliación inválida');
      return;
    }

    // Obtener el seguro seleccionado desde el provider
    final segurosAsync = ref.read(obtenerSeguros);
    final seguro = segurosAsync.whenData((seguros) {
      return seguros.firstWhere((s) => s.codSeguro == _codSeguroSeleccionado);
    });

    seguro.when(
      data: (seguroEntity) {
        final afiliacion = AfiliacionSeguroEntity(
          codAfiliacion: widget.afiliacionInicial?.codAfiliacion ?? 0,
          codEmpleado: widget.codEmpleado,
          codSeguro: _codSeguroSeleccionado,
          nroAfiliacion: _nroAfiliacionCtrl.text.trim(),
          fechaAfiliacion: fechaAfiliacion,
          fechaBaja: fechaBaja,
          audUsuarioI: widget.audUsuario,
          codPersona: widget.afiliacionInicial?.codPersona ?? 0,
          nombreCompleto: widget.afiliacionInicial?.nombreCompleto ?? '',
          seguro: seguroEntity,
        );

        console('📝 Guardando afiliación: ${afiliacion.nroAfiliacion}');
        widget.onSave(afiliacion);
      },
      error: (err, stack) {
        showErrorMessage(context, 'Error al obtener datos del seguro');
      },
      loading: () {
        showErrorMessage(context, 'Cargando seguros...');
      },
    );
  }
}