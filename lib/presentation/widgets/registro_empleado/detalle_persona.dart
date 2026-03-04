import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/domain/entities/ciExpedido_entity.dart';
import 'package:bosque_flutter/domain/entities/estado_civil_entity.dart';
import 'package:bosque_flutter/domain/entities/persona_entity.dart';
import 'package:bosque_flutter/domain/entities/sexo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/form_persona.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/map_viewer.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// PROVIDERS
// ============================================================================

final detallePersonaMapControllerProvider = Provider.autoDispose<MapController>(
  (ref) => MapController(),
);

final detallePersonaEditingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

// ============================================================================
// MAIN WIDGET
// ============================================================================

class DetallePersona extends ConsumerWidget {
  final PersonaEntity persona;
  final String mode; // 'nuevo' o 'edicion'
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DetallePersona({
    Key? key,
    required this.persona,
    this.mode = 'nuevo',
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditing = ref.watch(detallePersonaEditingProvider);

    if (isEditing && mode == 'edicion') {
      return _EditingFormPersona(persona: persona);
    }

    return context.isMobile
        ? _buildMobileViewMode(context, ref)
        : _buildWebViewMode(context, ref);
  }

  // ============================================================================
  // MOBILE LAYOUT
  // ============================================================================

  Widget _buildMobileViewMode(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mode == 'edicion')
            Padding(
              padding: EdgeInsets.only(bottom: context.spacing),
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(detallePersonaEditingProvider.notifier).state = true;
                },
                icon: const Icon(Icons.edit),
                label: const Text('Editar Datos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  minimumSize: Size(double.infinity, 44),
                ),
              ),
            ),
          _buildIdentificacionSection(context, ref),
          SizedBox(height: context.largeSpacing),
          _buildNacimientoSection(context, ref),
          SizedBox(height: context.largeSpacing),
          _buildUbicacionSection(context, ref),
          SizedBox(height: context.largeSpacing),
          if (_hasValidCoordinates())
            _buildMapaSection(context, ref, isMobile: true),
        ],
      ),
    );
  }

  // ============================================================================
  // WEB LAYOUT
  // ============================================================================

  Widget _buildWebViewMode(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mode == 'edicion')
            Padding(
              padding: EdgeInsets.only(bottom: context.spacing),
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(detallePersonaEditingProvider.notifier).state = true;
                },
                icon: const Icon(Icons.edit),
                label: const Text('Editar Datos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacing * 2,
                    vertical: context.spacing * 1.5,
                  ),
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIdentificacionSection(context, ref),
                    SizedBox(height: context.largeSpacing),
                    _buildNacimientoSection(context, ref),
                    SizedBox(height: context.largeSpacing),
                    _buildUbicacionSection(context, ref),
                  ],
                ),
              ),
              SizedBox(width: context.largeSpacing * 2),
              if (_hasValidCoordinates())
                Expanded(
                  flex: 1,
                  child: _buildMapaSection(context, ref, isMobile: false),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SECCIONES DE CONTENIDO
  // ============================================================================

  Widget _buildIdentificacionSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Identificación y Cédula'),
        _buildDataRow(context, 'Nombres:', persona.nombres),
        _buildDataRow(context, 'Apellido Paterno:', persona.apPaterno),
        _buildDataRow(context, 'Apellido Materno:', persona.apMaterno),
        _buildDataRow(context, 'CI Número:', persona.ciNumero),
        _buildDataRowWithValue(
          context,
          'CI Expedido:',
          DisplayValue<CiExpedidoEntity>(
            code: persona.ciExpedido,
            provider: ciExpedidoProvider,
            getCode: (e) => e.codTipos,
            getDescription: (e) => e.nombre,
            fallback: persona.ciExpedido,
            style: context.bodyStyle.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        _buildDataRow(
          context,
          'Vencimiento CI:',
          FechaUtils.formatDate(persona.ciFechaVencimiento!),
        ),
      ],
    );
  }

  Widget _buildNacimientoSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Nacimiento y Estado'),
        _buildDataRow(
          context,
          'Fecha de Nacimiento:',
          FechaUtils.formatDate(persona.fechaNacimiento!),
        ),
        _buildDataRow(context, 'Lugar de Nacimiento:', persona.lugarNacimiento),
        _buildDataRowWithValue(
          context,
          'Sexo:',
          DisplayValue<SexoEntity>(
            code: persona.sexo,
            provider: sexoProvider,
            getCode: (e) => e.codTipos,
            getDescription: (e) => e.nombre,
            fallback: 'No especificado',
            style: context.bodyStyle.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        _buildDataRowWithValue(
          context,
          'Estado Civil:',
          DisplayValue<EstadoCivilEntity>(
            code: persona.estadoCivil,
            provider: estadoCivilProvider,
            getCode: (e) => e.codTipos,
            getDescription: (e) => e.nombre,
            fallback: persona.estadoCivil,
            style: context.bodyStyle.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        _buildDataRow(context, 'Nacionalidad:', persona.pais?.pais ?? 'N/A'),
      ],
    );
  }

  Widget _buildUbicacionSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Ubicación y Dirección'),
        _buildDataRow(context, 'Dirección:', persona.direccion),
        _buildDataRow(context, 'Ciudad:', persona.ciudad?.ciudad ?? 'N/A'),
        _buildDataRow(context, 'Zona:', persona.zona?.zona ?? 'N/A'),
      ],
    );
  }

  Widget _buildMapaSection(
    BuildContext context,
    WidgetRef ref, {
    required bool isMobile,
  }) {
    final mapController = ref.watch(detallePersonaMapControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Ubicación en Mapa'),
        SizedBox(height: context.spacing),
        ClipRRect(
          borderRadius: context.borderRadius,
          child: SizedBox(
            height: isMobile ? 250 : 500,
            width: double.infinity,
            child: MapViewer(
              latitude: persona.lat ?? -16.5160,
              longitude: persona.lng ?? -68.1354,
              height: isMobile ? 250 : 500,
              isInteractive: true,
              canChangeLocation: false,
              mapController: mapController,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // WIDGETS REUTILIZABLES
  // ============================================================================

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: context.smallSpacing,
        top: context.smallSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.subtitleStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          Divider(
            height: context.spacing * 1.5,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  /// Construye una fila de datos con valor String
  Widget _buildDataRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.smallSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Expanded(
            child: Text(
              value,
              style: context.bodyStyle.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una fila de datos con valor Widget (para DisplayValue, etc)
  Widget _buildDataRowWithValue(
    BuildContext context,
    String label,
    Widget value,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.smallSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Expanded(child: value),
        ],
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  bool _hasValidCoordinates() {
    return persona.lat != null &&
        persona.lng != null &&
        (persona.lat ?? 0) != 0 &&
        (persona.lng ?? 0) != 0;
  }
}

// ============================================================================
// EDITING MODE
// ============================================================================

class _EditingFormPersona extends ConsumerStatefulWidget {
  final PersonaEntity persona;

  const _EditingFormPersona({required this.persona});

  @override
  ConsumerState<_EditingFormPersona> createState() =>
      _EditingFormPersonaState();
}

class _EditingFormPersonaState extends ConsumerState<_EditingFormPersona> {
  late GlobalKey<FormState> _formKey;
  late GlobalKey _personaStateKey;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _personaStateKey = GlobalKey();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildForm(context),
          SizedBox(height: context.largeSpacing),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return FormPersona(
          key: _personaStateKey,
          formKey: _formKey,
          persona: widget.persona,
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        if (context.isMobile) {
          return Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleCancel(context, ref),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar'),
                ),
              ),
              SizedBox(width: context.spacing),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleSave(context, ref),
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                  ),
                ),
              ),
            ],
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _handleCancel(context, ref),
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
              ),
              SizedBox(width: context.spacing),
              ElevatedButton.icon(
                onPressed: () => _handleSave(context, ref),
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  void _handleCancel(BuildContext context, WidgetRef ref) {
    ref.read(detallePersonaEditingProvider.notifier).state = false;
  }

  Future<void> _handleSave(BuildContext context, WidgetRef ref) async {
    final personaFormState = _personaStateKey.currentState;
    if (personaFormState == null) return;

    try {
      final validado =
          await (personaFormState as dynamic).validarYGuardar();

      if (!validado) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor completa todos los campos requeridos'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final personaActualizada = ref.read(tempPersonaProvider);
      if (personaActualizada == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se pudo obtener los datos'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await executeABM(
        ref: ref,
        context: context,
        operation: () async {
          await ref.read(registrarPersonaProvider(personaActualizada).future);
        },
        providersToInvalidate: [
          obtenerPersonaProvider(personaActualizada.codPersona),
          getListaEmpleados,
        ],
        successMessage:
            ' Persona actualizada correctamente',
      );

      if (!context.mounted) return;
      ref.read(detallePersonaEditingProvider.notifier).state = false;
    } catch (e) {
      if (!context.mounted) return;
      debugPrint('❌ Error en _EditingFormPersona: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}