import 'package:bosque_flutter/core/state/indemnizacion_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/domain/entities/indemnizacion_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:intl/intl.dart';

class IndemnizacionDialog extends ConsumerStatefulWidget {
  final IndemnizacionEntity? indemnizacion;
  final int audUsuarioI;

  const IndemnizacionDialog({
    Key? key,
    this.indemnizacion,
    required this.audUsuarioI,
  }) : super(key: key);

  @override
  ConsumerState<IndemnizacionDialog> createState() =>
      _IndemnizacionDialogState();
}

class _IndemnizacionDialogState extends ConsumerState<IndemnizacionDialog> {
  final _formKey = GlobalKey<FormState>();
  EmpleadoEntity? _empleadoSeleccionado;
  bool _isCleared = false;
  late TextEditingController _montoController;
  late TextEditingController _descripcionController;
  DateTime? _fechaSeleccionada;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Si ya existe la indemnizacion (modo edición), cargamos el empleado completo
    if (widget.indemnizacion != null &&
        widget.indemnizacion!.codEmpleado != null) {
      Future.microtask(() async {
        try {
          final emp = await ref.read(
            detalleEmpleadoProvider(widget.indemnizacion!.codEmpleado!).future,
          );
          if (mounted) {
            setState(() {
              _empleadoSeleccionado = emp;
            });
          }
        } catch (e) {
          debugPrint('Error cargando empleado: $e');
        }
      });
    }
    _montoController = TextEditingController(
      text: widget.indemnizacion?.montoIndemnizacion?.toString() ?? '',
    );
    _descripcionController = TextEditingController(
      text: widget.indemnizacion?.descripcion ?? '',
    );
    _fechaSeleccionada =
        widget.indemnizacion?.fechaIndemnizacion ?? DateTime.now();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  Future<void> _guardar() async {
    if (_isSubmitting) return;
    if (_formKey.currentState!.validate() && _fechaSeleccionada != null) {
      if (_empleadoSeleccionado == null &&
          widget.indemnizacion?.codEmpleado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe seleccionar un empleado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      setState(() {
        _isSubmitting = true;
      });
      final nuevaIndemnizacion = IndemnizacionEntity(
        codIndemnizacion: widget.indemnizacion?.codIndemnizacion,
        codEmpleado:
            _empleadoSeleccionado?.codEmpleado ??
            widget.indemnizacion!.codEmpleado,
        montoIndemnizacion: double.tryParse(_montoController.text),
        fechaIndemnizacion: _fechaSeleccionada,
        descripcion: _descripcionController.text,
        estado: 1,
      );
      final codEmpresa = ref.read(codEmpresaIndemnizacionProvider);
      await ref
          .read(indemnizacionProvider(codEmpresa).notifier)
          .guardar(nuevaIndemnizacion, widget.audUsuarioI);
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.indemnizacion != null;

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 450,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_document : Icons.add_card,
                      color: cs.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? 'Editar Indemnización'
                              : 'Nueva Indemnización',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEditing
                              ? 'Modifica los detalles del registro'
                              : 'Registra una nueva indemnización',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Selector de Empleado
                      DropdownSearch<EmpleadoEntity>(
                        selectedItem: _empleadoSeleccionado,
                        asyncItems: (text) async {
                          return await ref.read(
                            getListaEmpleados((
                              text.isEmpty ? null : text,
                              1,
                              1,
                              200,
                              null,
                            )).future,
                          );
                        },
                        itemAsString: (e) {
                          final name =
                              (e.persona.datoPersona ?? e.datoPersona).trim();
                          if (name.isNotEmpty) return name;
                          return '${e.nombres} ${e.apPaterno} ${e.apMaterno}'
                              .trim();
                        },
                        compareFn: (a, b) => a.codEmpleado == b.codEmpleado,
                        dropdownBuilder: (context, selectedItem) {
                          String displayName = '';
                          if (selectedItem != null) {
                            displayName =
                                (selectedItem.persona.datoPersona ??
                                        selectedItem.datoPersona)
                                    .trim();
                            if (displayName.isEmpty) {
                              displayName =
                                  '${selectedItem.nombres} ${selectedItem.apPaterno} ${selectedItem.apMaterno}'
                                      .trim();
                            }
                          }
                          if (displayName.isEmpty &&
                              widget.indemnizacion != null &&
                              !_isCleared) {
                            final ind = widget.indemnizacion!;
                            displayName =
                                (ind.empleadoNombres ?? '').trim().isNotEmpty
                                    ? '${ind.empleadoNombres} ${ind.empleadoApellidos ?? ''}'
                                        .trim()
                                    : (ind.apellidos ?? '').trim();
                          }
                          if (displayName.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            displayName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, color: cs.onSurface),
                          );
                        },
                        onChanged:
                            (emp) => setState(() {
                              _empleadoSeleccionado = emp;
                              if (emp == null) _isCleared = true;
                            }),
                        validator: (val) {
                          if (val == null &&
                              (widget.indemnizacion == null || _isCleared)) {
                            return 'Requerido';
                          }
                          return null;
                        },
                        clearButtonProps: const ClearButtonProps(
                          isVisible: true,
                        ),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: inputDecoration.copyWith(
                            labelText: 'Empleado',
                            prefixIcon: Icon(Icons.person, color: cs.primary),
                          ),
                        ),
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          menuProps: const MenuProps(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                          searchFieldProps: TextFieldProps(
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ResponsiveUtilsBosque.isMobile(context)
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _montoController,
                                decoration: inputDecoration.copyWith(
                                  labelText: 'Monto (Bs.)',
                                  prefixIcon: Icon(
                                    Icons.attach_money,
                                    color: cs.primary,
                                  ),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator:
                                    (value) =>
                                        value!.isEmpty ? 'Requerido' : null,
                              ),
                              const SizedBox(height: 20),
                              InkWell(
                                onTap: () => _seleccionarFecha(context),
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: inputDecoration.copyWith(
                                    labelText: 'Fecha',
                                    prefixIcon: Icon(
                                      Icons.calendar_month,
                                      color: cs.primary,
                                    ),
                                  ),
                                  child: Text(
                                    _fechaSeleccionada != null
                                        ? dateFormat.format(_fechaSeleccionada!)
                                        : 'Seleccionar...',
                                    style: TextStyle(
                                      color:
                                          _fechaSeleccionada != null
                                              ? cs.onSurface
                                              : cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                          : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _montoController,
                                  decoration: inputDecoration.copyWith(
                                    labelText: 'Monto (Bs.)',
                                    prefixIcon: Icon(
                                      Icons.attach_money,
                                      color: cs.primary,
                                    ),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  validator:
                                      (value) =>
                                          value!.isEmpty ? 'Requerido' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _seleccionarFecha(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: InputDecorator(
                                    decoration: inputDecoration.copyWith(
                                      labelText: 'Fecha',
                                      prefixIcon: Icon(
                                        Icons.calendar_month,
                                        color: cs.primary,
                                      ),
                                    ),
                                    child: Text(
                                      _fechaSeleccionada != null
                                          ? dateFormat.format(
                                            _fechaSeleccionada!,
                                          )
                                          : 'Seleccionar...',
                                      style: TextStyle(
                                        color:
                                            _fechaSeleccionada != null
                                                ? cs.onSurface
                                                : cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _descripcionController,
                        decoration: inputDecoration.copyWith(
                          labelText: 'Descripción / Motivo',
                          prefixIcon: Icon(Icons.notes, color: cs.primary),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        validator:
                            (value) => value!.isEmpty ? 'Requerido' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer (Actions)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
                ),
              ),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 12,
                overflowSpacing: 12,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _guardar,
                    icon:
                        _isSubmitting
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.save, size: 20),
                    label: Text(
                      _isSubmitting ? 'Guardando...' : 'Guardar',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
