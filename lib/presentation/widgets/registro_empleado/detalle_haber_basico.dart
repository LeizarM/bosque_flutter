import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetalleHaberBasico extends ConsumerStatefulWidget {
  final int codEmpleado;

  const DetalleHaberBasico({
    Key? key,
    required this.codEmpleado,
  }) : super(key: key);

  @override
  ConsumerState<DetalleHaberBasico> createState() =>
      _DetalleHaberBasicoState();
}

class _DetalleHaberBasicoState extends ConsumerState<DetalleHaberBasico> {
  bool _isEditing = false;
  late TextEditingController _haberBasicoCtrl;
  late GlobalKey<FormState> _formKey;
  late int _audUsuario;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _haberBasicoCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _haberBasicoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    _audUsuario = user?.codUsuario ?? 0;

    console('🔍 DetalleHaberBasico - codEmpleado: ${widget.codEmpleado}');

    final empleadoAsync = ref.watch(detalleEmpleadoProvider(widget.codEmpleado));

    return empleadoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) {
        console('❌ Error al cargar empleado: $err');
        return Center(
          child: Text('Error al cargar empleado: $err'),
        );
      },
      data: (empleado) {
        return _buildUI(context, empleado);
      },
    );
  }

  // ============================================================================
  // UI PRINCIPAL
  // ============================================================================

  Widget _buildUI(BuildContext context, EmpleadoEntity empleado) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        SizedBox(height: context.smallSpacing),
        if (!_isEditing)
          _buildHaberBasicoCard(context, empleado)
        else
          _buildForm(context, empleado),
      ],
    );
  }

  // ============================================================================
  // HEADER
  // ============================================================================

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.smallSpacing),
      child: Row(
        children: [
          Icon(
            Icons.attach_money,
            size: context.smallIconSize,
            color: Colors.grey.shade600,
          ),
          SizedBox(width: context.smallSpacing),
          Text(
            'Haber Básico',
            style: context.subtitleStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TARJETA DE HABER BÁSICO (LECTURA)
  // ============================================================================

  Widget _buildHaberBasicoCard(
    BuildContext context,
    EmpleadoEntity empleado,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: context.borderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Haber Básico con mejor layout
            _buildDetailRow(
              context,
              'Haber Básico:',
              empleado.haberBasico,
            ),
            SizedBox(height: context.largeSpacing),

            // Botón editar mejorado
            _buildActionButton(context, empleado),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    double? value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: context.isMobile ? 120 : 150,
          child: Text(
            label,
            style: context.bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        SizedBox(width: context.spacing),
        Expanded(
          child: Text(
            value?.toString() ?? 'No registrado',
            style: context.bodyStyle.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Colors.grey.shade900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    EmpleadoEntity empleado,
  ) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            console('🔧 Btn editar haber básico presionado');
            _haberBasicoCtrl.text = empleado.haberBasico?.toStringAsFixed(2) ?? '';
            setState(() => _isEditing = true);
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.smallSpacing,
              vertical: context.smallSpacing / 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Colors.green,
                ),
                SizedBox(width: context.smallSpacing / 2),
                Text(
                  'Editar',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // FORMULARIO
  // ============================================================================

  Widget _buildForm(BuildContext context, EmpleadoEntity empleado) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: context.borderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacing),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar Haber Básico',
                style: context.subtitleStyle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: context.largeSpacing),

              // Campo Haber Básico
              _buildHaberBasicoField(),
              SizedBox(height: context.largeSpacing),

              // Botones
              _buildFormActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHaberBasicoField() {
    return TextFormField(
      controller: _haberBasicoCtrl,
      decoration: InputDecoration(
        labelText: 'Haber Básico *',
        hintText: 'Ingrese el haber básico',
        border: OutlineInputBorder(
          borderRadius: context.borderRadius,
        ),
        prefixIcon: const Icon(Icons.attach_money),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El haber básico es obligatorio';
        }
        if (double.tryParse(value.trim()) == null) {
          return 'Ingrese un valor numérico válido';
        }
        return null;
      },
    );
  }

  Widget _buildFormActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _isEditing = false);
          },
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

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final haberBasico = double.parse(_haberBasicoCtrl.text.trim());

    final empleadoAsync = ref.read(detalleEmpleadoProvider(widget.codEmpleado));

    final empleado = await empleadoAsync.maybeWhen(
      data: (emp) => Future.value(emp),
      orElse: () => Future.error('No se pudo cargar el empleado'),
    );

    final empleadoActualizado = empleado.copyWith(
      haberBasico: haberBasico,
      audUsuarioI: _audUsuario,
    );

    final success = await executeABM(
      ref: ref,
      context: context,
      operation: () =>
          ref.read(registrarEmpleadoProvider(empleadoActualizado).future),
      providersToInvalidate: [
        detalleEmpleadoProvider(widget.codEmpleado),
      ],
      successMessage: '✅ Haber básico actualizado correctamente',
    );

    if (success && mounted) {
      console('💾 Haber básico guardado: $haberBasico');
      setState(() => _isEditing = false);
    }
  }
}