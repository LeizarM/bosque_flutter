// lib/presentation/widgets/registro_empleado/form_relacion_cargo.dart
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/domain/entities/cargo_sucursal_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/relacion_laboral_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_relacion_laboral_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart'; // CHANGED: needed for DropdownSearch items
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_informacion_laboral.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:bosque_flutter/core/utils/console_log.dart'; // CHANGED: optional logging consistency
import 'package:dropdown_search/dropdown_search.dart'; // CHANGED: new selector widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// CHANGES SUMMARY:
/// - REPLACED: old 6-dropdown flow (empresa->sucursal->cargo x2) with a simpler flow:
///     * Cargo Interno: `DropdownSearch<EmpleadoEntity>` (getCargoXEmpresa((text, 6))) with dedup by codCargo
///     * Empresa Planilla: `DropdownButtonFormField<int>`
///     * Cargo Planilla: `DropdownSearch<EmpleadoEntity>` (getCargoXEmpresa((text, codEmpresaPlanilla)))
/// - KEPT: validation, Fecha, TipoRelacion, onSave/onCancel contract
/// - REMOVED (from flow): use of sucursalesProvider/cargoXsucursalProvider for selecting cargos (still present in file for backwards reference)
class FormRelacionConCargo extends ConsumerStatefulWidget {
  final int codEmpleado;
  final int audUsuario;
  final Function(RelacionLaboralEntity, CargoSucursalEntity, CargoSucursalEntity) onSave;
  final VoidCallback onCancel;

  const FormRelacionConCargo({
    Key? key,
    required this.codEmpleado,
    required this.audUsuario,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  ConsumerState<FormRelacionConCargo> createState() => _FormRelacionConCargoState();
}

class _FormRelacionConCargoState extends ConsumerState<FormRelacionConCargo> {
  final _formKey = GlobalKey<FormState>();

  // ========== CARGO INTERNO (NEW FLOW) ==========
  // CHANGED: we store the selected EmpleadoEntity (from getCargoXEmpresa) and extract its cargoSucursal
  EmpleadoEntity? _selectedInternoEmpleado;
  CargoSucursalEntity? _selectedCargoInterno;

  // ========== CARGO PLANILLA (NEW FLOW) ==========
  int? _selectedCodEmpresaPlanilla;
  EmpleadoEntity? _selectedPlanillaEmpleado;
  CargoSucursalEntity? _selectedCargoPlanilla;

  // ========== RELACIÓN LABORAL ==========
  late TextEditingController _fechaInicioController;
  String? _selectedTipoRelacion;

  @override
  void initState() {
    super.initState();
    _fechaInicioController = TextEditingController(
      text: FechaUtils.formatDate(DateTime.now()),
    );
    // FIJAR EMPRESA INTERNA EN 6 (kept requirement)
    // NOTE: previously there were explicit empresa->sucursal->cargo fields for interno; now fixed empresa=6
  }

  @override
  void dispose() {
    _fechaInicioController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _fechaInicioController.text = FechaUtils.formatDate(DateTime.now());
    setState(() {
      // CHANGED: reset new flow fields
      _selectedInternoEmpleado = null;
      _selectedCargoInterno = null;

      _selectedCodEmpresaPlanilla = null;
      _selectedPlanillaEmpleado = null;
      _selectedCargoPlanilla = null;

      _selectedTipoRelacion = null;
    });
  }

  void _handleSave() {
    // keep form-level validation plus require selected cargos from new flow
    if (_formKey.currentState!.validate() &&
        _selectedCargoInterno != null &&
        _selectedCargoPlanilla != null &&
        _selectedTipoRelacion != null) {
      FocusManager.instance.primaryFocus?.unfocus();

      final fechaIni = FechaUtils.parseDate(_fechaInicioController.text) ?? DateTime.now();

      final relacionGuardada = RelacionLaboralEntity(
        codRelEmplEmpr: 0,
        codEmpleado: widget.codEmpleado,
        esActivo: 1,
        tipoRel: _selectedTipoRelacion!,
        nombreFileContrato: '',
        fechaIni: fechaIni,
        fechaFin: null,
        motivoFin: '',
        audUsuario: widget.audUsuario,
        fechaInicioBeneficio: null,
        fechaInicioPlanilla: null,
        datoFechasBeneficio: null,
        cargo: '',
        sucursal: '',
        empresaFiscal: '',
        empresaInterna: '',
      );

      // call parent with CargoSucursalEntity extracted from selected EmpleadoEntity
      widget.onSave(relacionGuardada, _selectedCargoInterno!, _selectedCargoPlanilla!);
      _resetForm();
    } else {
      // If validation fails, keep the form open (no onCancel). User requested this behaviour.
      console('FormRelacionConCargo: validación fallida, formulario mantiene abierto.');
    }
  }

  void _handleCancel() {
    _resetForm();
    widget.onCancel();
  }

  void _navegarAEstructura() {
    Navigator.of(context).pop();
  }

  DropdownMenuItem<int> _buildGestionarItem() {
    return DropdownMenuItem<int>(
      value: -1,
      child: Row(
        children: [
          Icon(Icons.settings, size: 14, color: Colors.blue),
          const SizedBox(width: 6),
          const Text("Gestionar...", style: TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  // ========================================================================
  // KEPT/ADAPTED helpers (some original helpers kept for backward compatibility)
  // ========================================================================

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade600),
        SizedBox(width: context.smallSpacing),
        Text(
          title,
          style: context.subtitleStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------------
  // NEW: Interno selector using getCargoXEmpresa((text, 6)) with deduplication
  // ------------------------------------------------------------------------
Widget _buildCargoInternoSelector(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Cargo Interno', style: context.bodyStyle.copyWith(fontWeight: FontWeight.w600)),
      SizedBox(height: context.smallSpacing),
      Row(
        children: [
          Expanded(
            child: DropdownSearch<EmpleadoEntity>(
              asyncItems: (text) async {
                final items = await ref.read(getCargoXEmpresa((text, 6)).future);
                /*final seen = <int>{};
                final deduplicated = items.where((e) {
                  final codCargo = e.empleadoCargo.cargoSucursal?.codCargo;
                  if (codCargo == null) return false;
                  return seen.add(codCargo);
                }).toList();
                console('FormRelacionConCargo - INTERNO Items: ${items.length} → ${deduplicated.length}');*/
                return items;
              },
              selectedItem: _selectedInternoEmpleado,
              itemAsString: (e) {
                final cargo = e.empleadoCargo.cargoSucursal?.cargo;
                final cargoSuc = e.empleadoCargo.cargoSucursal;
                final desc = cargo?.descripcion ?? cargoSuc?.datoCargo ?? 'N/A';
                final suc = cargo?.sucursal ?? 'N/A';
                return "$desc — $suc";
              },
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Cargo Interno *',
                  hintText: 'Seleccione cargo',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _selectedInternoEmpleado = val;
                  _selectedCargoInterno = val?.empleadoCargo.cargoSucursal;
                });
                console('FormRelacionConCargo - selected interno codCargoSucursal: ${_selectedCargoInterno?.codCargoSucursal}');
              },
              popupProps: const PopupProps.menu(showSearchBox: true, searchDelay: Duration(milliseconds: 300)),
              validator: (val) => _selectedCargoInterno == null ? 'Requerido' : null,
            ),
          ),
          SizedBox(width: context.smallSpacing),
          CargoNavigationButton(
            empresaId: _selectedInternoEmpleado?.empleadoCargo.cargoSucursal?.cargo?.codEmpresa??6,
            empresaNombre: _selectedInternoEmpleado?.empleadoCargo.cargoSucursal?.cargo?.nombreEmpresa,
            ref: ref, // ✅ PASAR ref
          ),
        ],
      ),
    ],
  );
}

  // ------------------------------------------------------------------------
  // REUSE: empresa dropdown helper adapted for planilla (returns DropdownButtonFormField)
  // ------------------------------------------------------------------------
  Widget _buildEmpresaPlanillaSelector(BuildContext context) {
    final empresasAsync = ref.watch(empresasProvider);
    return empresasAsync.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (err, _) => Text('Error al cargar', style: TextStyle(color: Colors.red.shade300, fontSize: 10)),
      data: (data) {
        final empresas = (data as List?)?.cast<dynamic>() ?? [];
        //final filtered = empresas.where((e) => (e as dynamic).codEmpresa != -1 && (e as dynamic).codEmpresa != 6).toList();
        final items = empresas
            .map<DropdownMenuItem<int>>((e) => DropdownMenuItem<int>(
                  value: (e as dynamic).codEmpresa as int,
                  child: Text((e as dynamic).nombre as String, overflow: TextOverflow.ellipsis),
                ))
            .toList();

        final existeValor = items.any((item) => item.value == _selectedCodEmpresaPlanilla);
        final valorSeguro = existeValor ? _selectedCodEmpresaPlanilla : null;

        return DropdownButtonFormField<int>(
          value: valorSeguro,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Empresa Planilla *',
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: context.smallSpacing),
          ),
          items: items,
          onChanged: (val) {
            if (val == -1) {
              _navegarAEstructura();
              return;
            }
            setState(() {
              _selectedCodEmpresaPlanilla = val;
              _selectedPlanillaEmpleado = null;
              _selectedCargoPlanilla = null;
            });
            console('FormRelacionConCargo - Empresa Planilla selected: $val');
          },
          validator: (val) => val == null ? 'Requerido' : null,
        );
      },
    );
  }

  // ------------------------------------------------------------------------
  // NEW: Planilla selector using getCargoXEmpresa((text, codEmpresaPlanilla))
  // ------------------------------------------------------------------------
Widget _buildCargoPlanillaSelector(BuildContext context) {
  // Obtener el nombre de la empresa seleccionada
  final empresasAsync = ref.watch(empresasProvider);
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Cargo Planilla', style: context.bodyStyle.copyWith(fontWeight: FontWeight.w600)),
      SizedBox(height: context.smallSpacing),
      empresasAsync.when(
        loading: () => const LinearProgressIndicator(minHeight: 2),
        error: (e, _) => Text('Error: $e', style: context.bodyLightStyle),
        data: (empresas) {
          final empresaSeleccionada = empresas.firstWhere(
            (e) => e.codEmpresa == _selectedCodEmpresaPlanilla,
            orElse: () => empresas.isNotEmpty ? empresas.first : EmpresaEntity(codEmpresa: 0, nombre: 'N/A', codPadre: 0,sigla: '',audUsuario: 0),
          );

          return Row(
            children: [
              Expanded(
                child: DropdownSearch<EmpleadoEntity>(
                  enabled: _selectedCodEmpresaPlanilla != null,
                  asyncItems: (text) {
                    return ref.read(getCargoXEmpresa((text, _selectedCodEmpresaPlanilla)).future);
                  },
                  selectedItem: _selectedPlanillaEmpleado,
                  itemAsString: (e) {
                    final cargo = e.empleadoCargo.cargoSucursal?.cargo;
                    final cargoSuc = e.empleadoCargo.cargoSucursal;
                    final desc = cargo?.descripcionPlanilla?.isNotEmpty == true
                        ? cargo!.descripcionPlanilla
                        : (cargo?.descripcion ?? cargoSuc?.datoCargo ?? 'N/A');
                    final suc = cargo?.sucursalPlanilla?.isNotEmpty == true ? cargo!.sucursalPlanilla : (cargo?.sucursal ?? 'N/A');
                    return "$desc — $suc";
                  },
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'Cargo Planilla *',
                      hintText: _selectedCodEmpresaPlanilla == null ? 'Primero empresa' : 'Seleccione cargo',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _selectedPlanillaEmpleado = val;
                      _selectedCargoPlanilla = val?.empleadoCargo.cargoSucursal;
                    });
                    console('FormRelacionConCargo - selected planilla codCargoSucursal: ${_selectedCargoPlanilla?.codCargoSucursal}');
                  },
                  popupProps: const PopupProps.menu(showSearchBox: true),
                  validator: (val) => _selectedCargoPlanilla == null ? 'Requerido' : null,
                ),
              ),
              SizedBox(width: context.smallSpacing),
              CargoNavigationButton(
                empresaId: _selectedCodEmpresaPlanilla,
                empresaNombre: empresaSeleccionada.nombre,
                ref: ref, // ✅ PASAR ref
              ),
            ],
          );
        },
      ),
    ],
  );
}

  // ------------------------------------------------------------------------
  // los dropdowns para empresa,sucursal y cargo se mantienen pero ya no se usan en el nuevo flujo. Se dejan para referencia y posible reutilización futura.
  // ------------------------------------------------------------------------

  Widget _buildEmpresaDropdown(
    BuildContext context,
    String tipo,
    int? selectedValue,
    Function(int?) onChanged,
  ) {
    // KEPT: original helper (used previously by old flow). Not used in new flow.
    final empresasAsync = ref.watch(empresasProvider);

    return empresasAsync.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (err, _) => Text(
        'Error al cargar',
        style: TextStyle(color: Colors.red.shade300, fontSize: 10),
      ),
      data: (data) {
        final empresas = (data as List?)?.cast<dynamic>() ?? [];
        final filteredEmpresas = tipo == 'interno'
            ? empresas.where((e) => (e as dynamic).codEmpresa == 6).toList()
            : empresas.where((e) => (e as dynamic).codEmpresa != -1 && (e as dynamic).codEmpresa != 6).toList();

        final items = filteredEmpresas
            .map<DropdownMenuItem<int>>(
              (e) => DropdownMenuItem<int>(
                value: (e as dynamic).codEmpresa as int,
                child: Text((e as dynamic).nombre as String, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList();
        items.insert(0, _buildGestionarItem());

        final existeValor = items.any((item) => item.value == selectedValue);
        final valorSeguro = existeValor ? selectedValue : null;

        return IgnorePointer(
          ignoring: tipo == 'interno',
          child: Opacity(
            opacity: tipo == 'interno' ? 0.6 : 1.0,
            child: DropdownButtonFormField<int>(
              value: valorSeguro,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Empresa *',
                labelStyle: context.bodyStyle.copyWith(fontSize: 11),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: context.smallSpacing),
              ),
              items: items,
              onChanged: (val) {
                if (val == -1) {
                  _navegarAEstructura();
                } else {
                  onChanged(val);
                }
              },
              validator: (val) => val == null ? 'Requerido' : null,
            ),
          ),
        );
      },
    );
  }

  // KEPT: old sucursal & cargo helpers (not used by new flow)
  Widget _buildSucursalDropdown(
    BuildContext context,
    int? selectedEmpresa,
    int? selectedValue,
    Function(int?) onChanged,
  ) {
    final sucursalesAsync = selectedEmpresa != null
        ? ref.watch(sucursalesProvider(selectedEmpresa))
        : const AsyncValue.data([]);

    return IgnorePointer(
      ignoring: selectedEmpresa == null,
      child: Opacity(
        opacity: selectedEmpresa == null ? 0.5 : 1.0,
        child: sucursalesAsync.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (err, _) => Text(
            'Error al cargar',
            style: TextStyle(color: Colors.red.shade300, fontSize: 10),
          ),
          data: (data) {
            final sucursales = (data as List?)?.cast<dynamic>() ?? [];
            final filteredSucursales = sucursales.where((s) => (s as dynamic).codSucursal != -1).toList();

            final items = filteredSucursales
                .map<DropdownMenuItem<int>>(
                  (s) => DropdownMenuItem<int>(
                    value: (s as dynamic).codSucursal as int,
                    child: Text((s as dynamic).nombre as String, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList();
            items.insert(0, _buildGestionarItem());

            final existeValor = items.any((item) => item.value == selectedValue);
            final valorSeguro = existeValor ? selectedValue : null;

            return DropdownButtonFormField<int>(
              value: valorSeguro,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Sucursal *',
                labelStyle: context.bodyStyle.copyWith(fontSize: 11),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: context.smallSpacing),
              ),
              items: items,
              onChanged: (val) {
                if (val == -1) {
                  _navegarAEstructura();
                } else {
                  onChanged(val);
                }
              },
              validator: (val) => val == null ? 'Requerido' : null,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCargoDropdown(
    BuildContext context,
    int? selectedSucursal,
    int? selectedValue,
    Function(int?) onChanged,
    Function(CargoSucursalEntity?) onCargoSelected,
  ) {
    final cargosAsync = selectedSucursal != null
        ? ref.watch(cargoXsucursalProvider(selectedSucursal))
        : const AsyncValue.data([]);

    return IgnorePointer(
      ignoring: selectedSucursal == null,
      child: Opacity(
        opacity: selectedSucursal == null ? 0.5 : 1.0,
        child: cargosAsync.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (err, _) => Text(
            'Error al cargar',
            style: TextStyle(color: Colors.red.shade300, fontSize: 10),
          ),
          data: (data) {
            final cargos = (data as List?)?.cast<CargoSucursalEntity>() ?? [];
            final filteredCargos = cargos.where((c) => c.codCargoSucursal != -1).toList();

            final items = filteredCargos
                .map<DropdownMenuItem<int>>(
                  (c) => DropdownMenuItem<int>(
                    value: c.codCargoSucursal,
                    child: Text(c.datoCargo, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList();
            items.insert(0, _buildGestionarItem());

            final existeValor = items.any((item) => item.value == selectedValue);
            final valorSeguro = existeValor ? selectedValue : null;

            return DropdownButtonFormField<int>(
              value: valorSeguro,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Cargo *',
                labelStyle: context.bodyStyle.copyWith(fontSize: 11),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: context.smallSpacing),
              ),
              items: items,
              onChanged: (val) {
                if (val == -1) {
                  _navegarAEstructura();
                } else {
                  onChanged(val);
                  try {
                    final cargo = cargos.firstWhere((c) => c.codCargoSucursal == val);
                    onCargoSelected(cargo);
                  } catch (_) {
                    onCargoSelected(null);
                  }
                }
              },
              validator: (val) => val == null ? 'Requerido' : null,
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------------------
  // Layout composition: replace old cargo section calls with new selectors
  // ------------------------------------------------------------------------

  Widget _buildCargosSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Seleccionar Cargos', Icons.work),
        SizedBox(height: context.spacing),
        context.isMobile ? _buildCargosMobileView(context) : _buildCargosWebView(context),
      ],
    );
  }

  Widget _buildCargosMobileView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CHANGED: use new internal selector
        _buildCargoInternoSelector(context),
        SizedBox(height: context.largeSpacing),
        // CHANGED: planilla flow = empresa + cargo search
        _buildEmpresaPlanillaSelector(context),
        SizedBox(height: context.smallSpacing),
        _buildCargoPlanillaSelector(context),
      ],
    );
  }

  Widget _buildCargosWebView(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildCargoInternoSelector(context),
        ),
        SizedBox(width: context.largeSpacing * 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEmpresaPlanillaSelector(context),
              SizedBox(height: context.smallSpacing),
              _buildCargoPlanillaSelector(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRelacionLaboralSection(BuildContext context) {
    final tiposRelacionAsync = ref.watch(getTipoRelacionLaboral);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Información de Relación Laboral', Icons.link),
        SizedBox(height: context.spacing),
        tiposRelacionAsync.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (err, _) => Text('Error', style: TextStyle(color: Colors.red.shade300, fontSize: 10)),
          data: (tiposRelacion) {
            return CustomDropdown<TipoRelacionLaboralEntity>(
              asyncValue: AsyncValue.data(tiposRelacion),
              label: 'Tipo de Relación *',
              currentValue: _selectedTipoRelacion,
              onChanged: (newValue) {
                setState(() => _selectedTipoRelacion = newValue);
              },
              getName: (e) => e.nombre,
              getCode: (e) => e.codTipos,
            );
          },
        ),
        SizedBox(height: context.spacing),
        CustomDatePicker(
          controller: _fechaInicioController,
          label: 'Fecha de Inicio *',
          validator: (val) => (val == null || val.isEmpty) ? 'Requerido' : null,
          lastDate: DateTime(2050),
          firstDate: DateTime(1900),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (context.isMobile) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _handleCancel,
              icon: const Icon(Icons.close),
              label: const Text('Cancelar'),
            ),
          ),
          SizedBox(width: context.spacing),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _handleSave,
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: _handleCancel,
          icon: const Icon(Icons.close),
          label: const Text('Cancelar'),
        ),
        SizedBox(width: context.spacing),
        ElevatedButton.icon(
          onPressed: _handleSave,
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        margin: EdgeInsets.only(bottom: context.smallSpacing),
        padding: EdgeInsets.all(context.spacing),
        decoration: BoxDecoration(
          color: Colors.lightBlue.withOpacity(0.05),
          borderRadius: context.borderRadius,
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCargosSection(context),
              SizedBox(height: context.largeSpacing),
              _buildRelacionLaboralSection(context),
              SizedBox(height: context.largeSpacing),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }
}