// lib/presentation/widgets/registro_empleado/detalle_area_cargo.dart

import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/domain/entities/cargo_sucursal_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'form_area_cargo.dart';

// ============================================================================
// PROVIDERS
// ============================================================================

final currentCargoInternoProvider = StateProvider<CargoSucursalEntity?>(
  (ref) => null,
);
final currentCargoPlanillaProvider = StateProvider<CargoSucursalEntity?>(
  (ref) => null,
);

// ============================================================================
// MAIN WIDGET
// ============================================================================

class DetalleAreaCargo extends ConsumerStatefulWidget {
  const DetalleAreaCargo({Key? key}) : super(key: key);

  @override
  ConsumerState<DetalleAreaCargo> createState() => _DetalleAreaCargoState();
}

class _DetalleAreaCargoState extends ConsumerState<DetalleAreaCargo> {
  late int _audUsuario;
  bool _isAddingCargo = false;

  final _formCargoKey = GlobalKey<FormAreaCargoState>();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    _audUsuario = user?.codUsuario ?? 0;

    final cargoInterno = ref.watch(currentCargoInternoProvider);
    final cargoPlanilla = ref.watch(currentCargoPlanillaProvider);

    final ambosGuardados = cargoInterno != null && cargoPlanilla != null;

    return Container(
      padding: EdgeInsets.all(context.spacing),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: context.borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: context.largeSpacing),
          if (!_isAddingCargo && ambosGuardados)
            _buildCargoDisplay(context, cargoInterno, cargoPlanilla)
          else
            _buildForm(context, cargoInterno, cargoPlanilla),
          SizedBox(height: context.largeSpacing),
          _buildActionButtons(context, ambosGuardados),
        ],
      ),
    );
  }

  // ============================================================================
  // HEADER
  // ============================================================================

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.work,
          size: context.smallIconSize,
          color: Colors.blue.shade600,
        ),
        SizedBox(width: context.smallSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Información de Cargo y Área',
                style: context.subtitleStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: context.smallSpacing / 2),
              Text(
                'Asigne el cargo interno y de planilla para el empleado',
                style: context.bodyLightStyle.copyWith(
                  fontSize: context.smallFontSize,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // CARGO DISPLAY (LECTURA)
  // ============================================================================

  Widget _buildCargoDisplay(
    BuildContext context,
    CargoSucursalEntity cargoInterno,
    CargoSucursalEntity cargoPlanilla,
  ) {
    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCargoCard(context, 'Cargo Interno', cargoInterno, Colors.blue),
          SizedBox(height: context.largeSpacing),
          _buildCargoCard(
            context,
            'Cargo Planilla',
            cargoPlanilla,
            Colors.orange,
          ),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildCargoCard(
              context,
              'Cargo Interno',
              cargoInterno,
              Colors.blue,
            ),
          ),
          SizedBox(width: context.largeSpacing),
          Expanded(
            child: _buildCargoCard(
              context,
              'Cargo Planilla',
              cargoPlanilla,
              Colors.orange,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildCargoCard(
    BuildContext context,
    String titulo,
    CargoSucursalEntity cargo,
    Color colorPrimario,
  ) {
    // Mapeo correcto de datos
    final cargoDesc = cargo.cargo?.descripcion ?? cargo.datoCargo;
    final empresa =
        cargo.cargo?.nombreEmpresa ??
        cargo.sucursal?.empresa.nombre ??
        'Desconocida';
    final sucursal = cargo.cargo?.sucursal ?? cargo.sucursal?.nombre ?? 'N/A';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorPrimario.withOpacity(0.5)),
        borderRadius: context.borderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  titulo.contains('Interno')
                      ? Icons.business_center
                      : Icons.description,
                  size: context.smallIconSize,
                  color: colorPrimario,
                ),
                SizedBox(width: context.smallSpacing),
                Expanded(
                  child: Text(
                    titulo,
                    style: context.bodyStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorPrimario,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.spacing),
            Row(
              children: [
                CircleAvatar(
                  radius: context.spacing / 2,
                  backgroundColor: colorPrimario.withOpacity(0.15),
                  child: Icon(
                    Icons.check_circle,
                    size: context.smallIconSize,
                    color: colorPrimario,
                  ),
                ),
                SizedBox(width: context.spacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cargoDesc,
                        style: context.bodyStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: context.bodyFontSize,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: context.smallSpacing / 2),
                      Text(
                        '$empresa • $sucursal',
                        style: context.bodyLightStyle.copyWith(
                          fontSize: context.smallFontSize,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // FORM (UN ÚNICO FORMULARIO CON 3 DROPDOWNS)
  // ============================================================================

  Widget _buildForm(
    BuildContext context,
    CargoSucursalEntity? cargoInterno,
    CargoSucursalEntity? cargoPlanilla,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.work,
              size: context.smallIconSize,
              color: Colors.blue.shade600,
            ),
            SizedBox(width: context.smallSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seleccionar Cargo',
                    style: context.bodyStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacing),
        FormAreaCargo(
          key: _formCargoKey,
          audUsuario: _audUsuario,
          cargoInternoInicial: cargoInterno,
          cargoPlanillaInicial: cargoPlanilla,
          onSave:
              (cargoInt, cargoPlan) => _handleCargoSave(cargoInt, cargoPlan),
          onCancel: () {
            setState(() => _isAddingCargo = false);
          },
        ),
        SizedBox(height: context.spacing),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() => _isAddingCargo = false);
              },
              child: const Text('Cancelar'),
            ),
            SizedBox(width: context.spacing),
            ElevatedButton.icon(
              onPressed: () {
                _formCargoKey.currentState?.handleSave();
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // ACTION BUTTONS
  // ============================================================================

  Widget _buildActionButtons(BuildContext context, bool ambosGuardados) {
    final cargoInterno = ref.watch(currentCargoInternoProvider);
    final cargoPlanilla = ref.watch(currentCargoPlanillaProvider);
    final ambosGuardadosActual = cargoInterno != null && cargoPlanilla != null;

    if (ambosGuardadosActual && !_isAddingCargo) {
      return Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: () {
            setState(() => _isAddingCargo = true);
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing * 1.5,
              vertical: context.spacing,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ============================================================================
  // HANDLER
  // ============================================================================

  void _handleCargoSave(
    CargoSucursalEntity cargoInterno,
    CargoSucursalEntity cargoPlanilla,
  ) {
    // Actualizar providers
    ref.read(currentCargoInternoProvider.notifier).state = cargoInterno;
    ref.read(currentCargoPlanillaProvider.notifier).state = cargoPlanilla;

    // Actualizar tempRegistroFuncionesListProvider
    final areaCargoMap = {
      'codCargoSucursal': cargoInterno.codCargoSucursal,
      'codCargoSucPlanilla': cargoPlanilla.codCargoSucursal,
      'fechaInicio': DateTime.now(),
      'cargoSucursal': cargoInterno,
      'cargoSucursalPlanilla': cargoPlanilla,
      'cargoPlanilla':
          cargoPlanilla.cargo?.descripcion ?? cargoPlanilla.datoCargo,
      'existe': 0,
      'audUsuario': _audUsuario,
    };
    ref.read(tempRegistroFuncionesListProvider.notifier).state = [areaCargoMap];

    showSuccessMessage(context, '✅ Cargos seleccionados correctamente');
    setState(() => _isAddingCargo = false);
  }
}
