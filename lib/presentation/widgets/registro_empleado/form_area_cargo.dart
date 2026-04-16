// lib/presentation/widgets/registro_empleado/form_area_cargo.dart

import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_area_cargo.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/detalle_informacion_laboral.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/cargo_sucursal_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';

class FormAreaCargo extends ConsumerStatefulWidget {
  final int audUsuario;
  final CargoSucursalEntity? cargoInternoInicial;
  final CargoSucursalEntity? cargoPlanillaInicial;
  final Function(CargoSucursalEntity, CargoSucursalEntity) onSave;
  final VoidCallback onCancel;

  const FormAreaCargo({
    Key? key,
    required this.audUsuario,
    this.cargoInternoInicial,
    this.cargoPlanillaInicial,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  ConsumerState<FormAreaCargo> createState() => FormAreaCargoState();
}

class FormAreaCargoState extends ConsumerState<FormAreaCargo> {
  final _formKey = GlobalKey<FormState>();

  // CARGO INTERNO
  int? _codCargoInternoId;
  EmpleadoEntity? _selectedInterno;

  // CARGO PLANILLA
  int? _codEmpresaPlanilla;
  int? _codCargoPlanillaId;
  EmpleadoEntity? _selectedPlanilla;

  @override
  void initState() {
    super.initState();

    if (widget.cargoInternoInicial != null) {
      final cargo = widget.cargoInternoInicial!;
      _codCargoInternoId = cargo.codCargoSucursal;
      console('📌 INIT - Cargo Interno: codCargoSucursal=$_codCargoInternoId');
    }

    if (widget.cargoPlanillaInicial != null) {
      final cargo = widget.cargoPlanillaInicial!;
      _codCargoPlanillaId = cargo.codCargoSucursal;
      _codEmpresaPlanilla = cargo.cargo?.codEmpresa; // ✅ CORRECCIÓN
      console(
        '📌 INIT - Cargo Planilla: codCargoSucursal=$_codCargoPlanillaId, empresa=$_codEmpresaPlanilla',
      );
    }
  }

  Future<void> _preloadCargoInterno() async {
    if (widget.cargoInternoInicial != null && _selectedInterno == null) {
      try {
        final items = await ref.read(getCargoXEmpresa(('', 6)).future);

        // Buscar el cargo que coincida con el inicial
        EmpleadoEntity? cargo;
        try {
          cargo = items.firstWhere(
            (e) =>
                e.empleadoCargo.cargoSucursal?.codCargoSucursal ==
                _codCargoInternoId,
          );
        } catch (_) {
          cargo = null;
        }

        if (mounted) {
          setState(() {
            _selectedInterno = cargo;
            console(
              '✅ PRELOAD Cargo Interno: ${cargo?.empleadoCargo.cargoSucursal?.codCargoSucursal}',
            );
          });
        }
      } catch (e) {
        console('❌ Error precargando cargo interno: $e');
      }
    }
  }

  Future<void> _preloadCargoPlanilla() async {
    if (widget.cargoPlanillaInicial != null &&
        _codEmpresaPlanilla != null &&
        _selectedPlanilla == null) {
      try {
        final items = await ref.read(
          getCargoXEmpresa(('', _codEmpresaPlanilla)).future,
        );

        // Buscar el cargo que coincida con el inicial
        EmpleadoEntity? cargo;
        try {
          cargo = items.firstWhere(
            (e) =>
                e.empleadoCargo.cargoSucursal?.codCargoSucursal ==
                _codCargoPlanillaId,
          );
        } catch (_) {
          cargo = null;
        }

        if (mounted) {
          setState(() {
            _selectedPlanilla = cargo;
            console(
              '✅ PRELOAD Cargo Planilla: ${cargo?.empleadoCargo.cargoSucursal?.codCargoSucursal}',
            );
          });
        }
      } catch (e) {
        console('❌ Error precargando cargo planilla: $e');
      }
    }
  }

  void handleSave() {
    if (_formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();

      if (_selectedInterno != null && _selectedPlanilla != null) {
        final cargoInterno = _selectedInterno!.empleadoCargo.cargoSucursal;
        final cargoPlanilla = _selectedPlanilla!.empleadoCargo.cargoSucursal;

        console('✅ FormAreaCargo.handleSave - AMBOS CARGOS:');
        console(
          '   INTERNO - codCargoSucursal: ${cargoInterno?.codCargoSucursal}',
        );
        console(
          '   PLANILLA - codCargoSucursal: ${cargoPlanilla?.codCargoSucursal}',
        );

        if (cargoInterno != null && cargoPlanilla != null) {
          // Guardar en providers temporales
          ref.read(currentCargoInternoProvider.notifier).state = cargoInterno;
          ref.read(currentCargoPlanillaProvider.notifier).state = cargoPlanilla;

          // ✅ ACTUALIZAR CORRECTAMENTE - Serializar Entities a JSON
          final areaCargoMap = {
            'codCargoSucursal': cargoInterno.codCargoSucursal,
            'codCargoSucPlanilla': cargoPlanilla.codCargoSucursal,
            'fechaInicio': DateTime.now(),
            'cargoSucursal':
                cargoInterno, // Se serializa en _saveTemporaryProviders
            'cargoSucursalPlanilla':
                cargoPlanilla, // Se serializa en _saveTemporaryProviders
            'cargoPlanilla':
                cargoPlanilla.cargo?.descripcion ?? cargoPlanilla.datoCargo,
            'existe': 0,
            'audUsuario': widget.audUsuario,
          };
          ref.read(tempRegistroFuncionesListProvider.notifier).state = [
            areaCargoMap,
          ];

          // Callback con ambos cargos
          widget.onSave(cargoInterno, cargoPlanilla);
        }
      }
    }
  }

  String _formatCargoLabel(EmpleadoEntity e, {required String tipo}) {
    final cargo = e.empleadoCargo.cargoSucursal?.cargo;
    final cargoSuc = e.empleadoCargo.cargoSucursal;

    if (tipo == 'interno') {
      final desc = cargo?.descripcion ?? cargoSuc?.datoCargo ?? 'N/A';
      final suc = cargo?.sucursal ?? 'N/A';
      return '$desc — $suc';
    } else {
      final desc =
          cargo?.descripcionPlanilla.isNotEmpty == true
              ? cargo!.descripcionPlanilla
              : (cargo?.descripcion ?? cargoSuc?.datoCargo ?? 'N/A');
      final suc =
          cargo?.sucursalPlanilla.isNotEmpty == true
              ? cargo!.sucursalPlanilla
              : (cargo?.sucursal ?? 'N/A');
      return '$desc — $suc';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Precarga de datos después del primer build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadCargoInterno();
      _preloadCargoPlanilla();
    });

    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.all(context.spacing),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.03),
          borderRadius: context.borderRadius,
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
        ),
        child:
            context.isMobile
                ? _buildMobileLayout(context)
                : _buildWebLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCargoInternoDropdown(),
        SizedBox(height: context.spacing),
        _buildEmpresaPlanillaDropdown(),
        SizedBox(height: context.spacing),
        _buildCargoPlanillaDropdown(),
      ],
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCargoInternoDropdown(),
        SizedBox(height: context.spacing),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildEmpresaPlanillaDropdown()),
            SizedBox(width: context.spacing),
            Expanded(child: _buildCargoPlanillaDropdown()),
          ],
        ),
      ],
    );
  }

  Widget _buildCargoInternoDropdown() {
    return Row(
      children: [
        Expanded(
          child: DropdownSearch<EmpleadoEntity>(
            asyncItems: (text) async {
              final items = await ref.read(getCargoXEmpresa((text, 6)).future);
              return items;
            },
            selectedItem: _selectedInterno,
            itemAsString: (e) => _formatCargoLabel(e, tipo: 'interno'),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: 'Cargo Interno *',
                hintText: 'Seleccione cargo',
                labelStyle: TextStyle(fontSize: context.bodyFontSize),
                hintStyle: context.bodyLightStyle,
                border: OutlineInputBorder(borderRadius: context.borderRadius),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.smallSpacing,
                  vertical: context.spacing,
                ),
                isDense: true,
              ),
            ),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _codCargoInternoId =
                      val.empleadoCargo.cargoSucursal?.codCargoSucursal;
                  _selectedInterno = val;
                  console('🔵 Area Cargo interno: $_codCargoInternoId');
                });
              }
            },
            popupProps: const PopupProps.menu(
              showSearchBox: true,
              searchDelay: Duration(milliseconds: 300),
            ),
            validator: (val) => val == null ? 'Requerido' : null,
          ),
        ),
        SizedBox(width: context.smallSpacing),
        // ✅ AGREGAR BOTÓN DE NAVEGACIÓN
        CargoNavigationButton(
          empresaId:
              _selectedInterno
                  ?.empleadoCargo
                  .cargoSucursal
                  ?.cargo
                  ?.codEmpresa ??
              6,
          empresaNombre:
              _selectedInterno
                  ?.empleadoCargo
                  .cargoSucursal
                  ?.sucursal
                  ?.empresa
                  .nombre,
          ref: ref,
        ),
      ],
    );
  }

  Widget _buildEmpresaPlanillaDropdown() {
    final empresasAsync = ref.watch(empresasProvider);
    return empresasAsync.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (e, _) => Text('Error: $e', style: context.bodyLightStyle),
      data: (empresas) {
        final filtered = empresas.where((e) => e.codEmpresa != -1).toList();

        // Validar que el valor exista en la lista
        final valueExists =
            _codEmpresaPlanilla == null ||
            filtered.any((e) => e.codEmpresa == _codEmpresaPlanilla);
        final safeValue = valueExists ? _codEmpresaPlanilla : null;

        return DropdownButtonFormField<int>(
          value: safeValue,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Empresa Planilla *',
            hintText: 'Seleccione empresa',
            labelStyle: TextStyle(fontSize: context.bodyFontSize),
            border: OutlineInputBorder(borderRadius: context.borderRadius),
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.smallSpacing,
              vertical: context.spacing,
            ),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
          ),
          items:
              filtered
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.codEmpresa,
                      child: Text(e.nombre, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
          onChanged: (val) {
            console('🟡 Area Empresa planilla: $_codEmpresaPlanilla → $val');
            setState(() {
              _codEmpresaPlanilla = val;
              _codCargoPlanillaId = null;
              _selectedPlanilla = null;
            });
          },
          validator: (val) => val == null ? 'Requerido' : null,
        );
      },
    );
  }

  Widget _buildCargoPlanillaDropdown() {
    final empresasAsync = ref.watch(empresasProvider);
    return empresasAsync.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (e, _) => Text('Error: $e', style: context.bodyLightStyle),
      data: (empresas) {
        final empresaSeleccionada = empresas.firstWhere(
          (e) => e.codEmpresa == _codEmpresaPlanilla,
          orElse: () => empresas.first,
        );

        return Row(
          children: [
            Expanded(
              child: DropdownSearch<EmpleadoEntity>(
                enabled: _codEmpresaPlanilla != null,
                asyncItems:
                    (text) => ref.read(
                      getCargoXEmpresa((text, _codEmpresaPlanilla)).future,
                    ),
                selectedItem: _selectedPlanilla,
                itemAsString: (e) => _formatCargoLabel(e, tipo: 'planilla'),
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: 'Cargo Planilla *',
                    hintText:
                        _codEmpresaPlanilla == null
                            ? 'Primero empresa'
                            : 'Seleccione cargo',
                    labelStyle: TextStyle(fontSize: context.bodyFontSize),
                    hintStyle: context.bodyLightStyle,
                    border: OutlineInputBorder(
                      borderRadius: context.borderRadius,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.smallSpacing,
                      vertical: context.spacing,
                    ),
                    isDense: true,
                  ),
                ),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _codCargoPlanillaId =
                          val.empleadoCargo.cargoSucursal?.codCargoSucursal;
                      _selectedPlanilla = val;
                      console('🟠 Area Cargo planilla: $_codCargoPlanillaId');
                    });
                  }
                },
                popupProps: const PopupProps.menu(showSearchBox: true),
                validator: (val) => val == null ? 'Requerido' : null,
              ),
            ),
            SizedBox(width: context.smallSpacing),
            // ✅ AGREGAR BOTÓN DE NAVEGACIÓN
            CargoNavigationButton(
              empresaId: _codEmpresaPlanilla,
              empresaNombre: empresaSeleccionada.nombre,
              ref: ref,
            ),
          ],
        );
      },
    );
  }
}
