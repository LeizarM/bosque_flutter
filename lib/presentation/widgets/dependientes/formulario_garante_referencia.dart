import 'dart:ui';

import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/utils/validators.dart';
import 'package:bosque_flutter/domain/entities/garante_referencia.dart';
import 'package:bosque_flutter/domain/entities/persona_entity.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/formulario_persona.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormularioGaranteReferencia extends ConsumerStatefulWidget {
  final String title;
  final GaranteReferenciaEntity? garanteReferencia;
  final int codEmpleado;

  final bool isEditing;
  final Function(GaranteReferenciaEntity) onSave;
  final VoidCallback onCancel;

  const FormularioGaranteReferencia({
    Key? key,
    required this.title,
    this.garanteReferencia,
    required this.codEmpleado,

    required this.isEditing,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  ConsumerState<FormularioGaranteReferencia> createState() =>
      _FormularioGaranteReferenciaState();
}

class _FormularioGaranteReferenciaState
    extends ConsumerState<FormularioGaranteReferencia> {
  final _formKey = GlobalKey<FormState>();
  final _direccionTrabajoController = TextEditingController();
  final _empresaTrabajoController = TextEditingController();
  final _tipoGaranteController = TextEditingController();
  final _observacionController = TextEditingController();
  String? _tipoGaranteSeleccionado;
  PersonaEntity? _personaSeleccionada;
  String? _mensajeNuevaPersona;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.garanteReferencia != null) {
      _direccionTrabajoController.text =
          widget.garanteReferencia!.direccionTrabajo;
      _empresaTrabajoController.text = widget.garanteReferencia!.empresaTrabajo;
      _tipoGaranteSeleccionado = widget.garanteReferencia!.tipo;
      _tipoGaranteController.text = widget.garanteReferencia!.tipo;
      _observacionController.text = widget.garanteReferencia!.observacion;
      _personaSeleccionada = widget.garanteReferencia!.persona;
     // Cargar la persona seleccionada
    ref.read(personaLstProvider.future).then((personas) {
      final encontrada = personas.where(
        (p) => p.codPersona == widget.garanteReferencia!.codPersona,
      );
      if (encontrada.isNotEmpty && mounted) {
        setState(() {
          _personaSeleccionada = encontrada.first;
        });
      }
    });
    }
  }

  @override
  void dispose() {
    _direccionTrabajoController.dispose();
    _empresaTrabajoController.dispose();
    _tipoGaranteController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  Future<int> getCodUsuario() async {
    return await ref.read(userProvider.notifier).getCodUsuario();
  }

  void _handleSubmit() async {
    // AÑADIDO: Validación de persona seleccionada
    if (_personaSeleccionada == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar o registrar una persona.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final codEmpleado = widget.codEmpleado;
      final garantesReferencias = await ref.read(
        obtenerGaranteReferenciaProvider(codEmpleado).future,
      );
      
      // Validación de cantidad máxima (Mantenido)
      const int maxGarantes = 4;
      if (!widget.isEditing && garantesReferencias.length >= maxGarantes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Solo se permite un máximo de $maxGarantes garantes/referencias.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Validacion de duplicados (Ajustado para usar _personaSeleccionada)
      final existeDuplicado =
          widget.isEditing
              ? garantesReferencias.any(
                  (g) =>
                      g.codPersona == _personaSeleccionada?.codPersona &&
                      g.tipo == _tipoGaranteSeleccionado &&
                      g.codGarante != widget.garanteReferencia?.codGarante,
                )
              : garantesReferencias.any(
                  (g) =>
                      g.codPersona == _personaSeleccionada?.codPersona &&
                      g.tipo == _tipoGaranteSeleccionado,
                );

      if (existeDuplicado) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Esta persona ya está registrada como garante o referencia.'
                  : 'Esta persona ya está registrada con este tipo de garante/referencia.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      try {
        // La PersonaEntity ya fue guardada/actualizada en el diálogo modal si fue necesario
        final garamteReferencia =
            widget.isEditing && widget.garanteReferencia != null
                ? widget.garanteReferencia!.copyWith(
                    codGarante: widget.garanteReferencia!.codGarante,
                    // Usamos el codPersona de la persona seleccionada/creada
                    codPersona: _personaSeleccionada!.codPersona, 
                    codEmpleado: widget.codEmpleado,
                    direccionTrabajo: _direccionTrabajoController.text,
                    empresaTrabajo: _empresaTrabajoController.text,
                    tipo: _tipoGaranteSeleccionado ?? _tipoGaranteController.text,
                    observacion: _observacionController.text,
                    audUsuario: await getCodUsuario(),
                  )
                : GaranteReferenciaEntity(
                    codGarante: 0, 
                    codPersona: _personaSeleccionada!.codPersona,
                    codEmpleado: widget.codEmpleado,
                    direccionTrabajo: _direccionTrabajoController.text,
                    empresaTrabajo: _empresaTrabajoController.text,
                    tipo: _tipoGaranteSeleccionado ?? _tipoGaranteController.text,
                    observacion: _observacionController.text,
                    audUsuario: await getCodUsuario(),
                  );
                  
        // Se llama a onSave solo con GaranteReferenciaEntity
        widget.onSave(garamteReferencia); 

        if (context.mounted) {
          if (widget.isEditing) {
            AppSnackbarCustom.showEdit(
              context, 
              'Garante/Referencia actualizado correctamente'
            );
          } else {
            AppSnackbarCustom.showAdd(
              context, 
              'Garante/Referencia agregado correctamente'
            );
          }
          if (Navigator.of(context).canPop() && !(ModalRoute.of(context)?.isFirst ?? false)) {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        // Mostrar SnackBar de error
        if (context.mounted) {
          AppSnackbar.showError(
            context, 
            'Error al ${widget.isEditing ? 'actualizar' : 'agregar'} Garante/Referencia'
          );
        }
      }
    }
  }
  Future<void> _mostrarDialogoEditarPersona(PersonaEntity persona) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: FormularioPersona(
            title: 'Editar Datos de Persona',
            isEditing: true,
            codPersona: persona.codPersona,
            persona: persona,
            onCancel: () => Navigator.pop(context),
            onSave: (personaEditada) async {
              try {
                // Guardar/Actualizar la Persona
                final updatedPersona = await ref.read(registrarPersonaProvider(personaEditada).future);
                
                // Invalidar el cache del provider de personas
                ref.invalidate(personaLstProvider);
                
                if (!mounted) return;
                Navigator.pop(context);
                
                // Actualizar el estado del Garante con la persona editada
                setState(() {
                  _personaSeleccionada = updatedPersona;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Datos de persona actualizados correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al actualizar: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        );
      },
    );
    Widget _buildEditPersonaButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.person_pin_circle_outlined, size: 20),
        label: const Text('EDITAR DATOS DE LA PERSONA SELECCIONADA'),
        onPressed: () => _mostrarDialogoEditarPersona(_personaSeleccionada!),
      ),
    );
  }
  }
  Future<void> _mostrarDialogoNuevaPersona() async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: FormularioPersona(
          title: 'Registrar Nueva Persona',
          isEditing: false,
          codPersona: 0,
          onCancel: () => Navigator.pop(context),
          onSave: (persona) async {
            try {
              // Guardar la persona
              final newPersona = await ref.read(registrarPersonaProvider(persona).future);
              // Invalidar el cache del provider de personas para forzar una recarga
              ref.invalidate(personaLstProvider);
              
              if (!mounted) return;
              Navigator.pop(context);
              
              // Actualizar el dropdown con la nueva persona
              setState(() {
                _personaSeleccionada = newPersona;
                  _mensajeNuevaPersona = 'persona registrada correctamente. Por favor, complete los demas campos.';

              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Persona registrada correctamente'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al registrar: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      );
    },
  );
}

   @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Container(
          width: isDesktop 
              ? screenWidth * 0.5  // 50% del ancho en desktop
              : screenWidth * 0.9, // 90% del ancho en móvil
          constraints: BoxConstraints(
            maxWidth: 800,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: _buildFormContent(context),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildPersonaSelector(),
                _buildInputField(
                  controller: _direccionTrabajoController,
                  label: 'DIRECCIÓN DE TRABAJO',
                ),
                _buildInputField(
                  controller: _empresaTrabajoController,
                  label: 'EMPRESA DE TRABAJO',
                ),
                _buildTipoGaranteDropdown(),
                _buildObservacionField(),
                _buildButtons(context),
              ].map((widget) => Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: widget,
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Text(
      widget.title,
      style: ResponsiveUtilsBosque.getTitleStyle(context),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPersonaSelector() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: DropdownSearch<PersonaEntity>(
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "SELECCIONAR PERSONA",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  border: const OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: ResponsiveUtilsBosque.getVerticalPadding(context),
                  ),
                ),
              ),
              asyncItems: (String filter) async {
                final personas = await ref.read(personaLstProvider.future);
                if (filter.isEmpty) return personas;
                return personas
                    .where((persona) => persona.datoPersona!.toLowerCase()
                        .contains(filter.toLowerCase()))
                    .toList();
              },
              itemAsString: (PersonaEntity? p) => p?.datoPersona ?? '',
              selectedItem: _personaSeleccionada,
              onChanged: (PersonaEntity? persona) {
                setState(() {
                  _personaSeleccionada = persona;
                  _mensajeNuevaPersona = null; // Oculta el mensaje si elige otra persona
                });
              },
              validator: (value) => value == null ? 'Seleccione una persona' : null,
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: const TextFieldProps(
                  decoration: InputDecoration(
                    labelText: 'BUSCAR PERSONA',
                    border: OutlineInputBorder(),
                  ),
                ),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _mostrarDialogoNuevaPersona,
            icon: const Icon(Icons.person_add),
            tooltip: 'Agregar nueva persona',
          ),
        ],
      ),
      if (_mensajeNuevaPersona != null)
        Padding(
          padding: const EdgeInsets.only(top: 6.0, left: 4.0),
          child: Text(
            _mensajeNuevaPersona!,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
    ],
  );
}

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: ResponsiveUtilsBosque.getVerticalPadding(context),
        ),
      ),
      validator: (value) => validarTextoMixto(value, esObligatorio: true),
      inputFormatters: bloquearEspacios,
    );
  }

  Widget _buildTipoGaranteDropdown() {
  return ref.watch(obtenerTipoGaranteReferenciaProvider).when(
    data: (tipoGarante) {
      // Lista de valores válidos
      final opciones = tipoGarante.map((tipo) => tipo.codTipos).toList();
      // Si el valor seleccionado no está en la lista, usa null
      final value = opciones.contains(_tipoGaranteSeleccionado)
          ? _tipoGaranteSeleccionado
          : null;

      return DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
  label: FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text(
      'TIPO DE GARANTE/REFERENCIA',
      style: TextStyle(fontSize: 16),
    ),
  ),
  border: const OutlineInputBorder(),
  contentPadding: EdgeInsets.symmetric(
    horizontal: 16,
    vertical: ResponsiveUtilsBosque.getVerticalPadding(context),
  ),
),
        isExpanded: true,
        items: tipoGarante.map((tipo) => DropdownMenuItem(
          value: tipo.codTipos,
          child: Text(
            tipo.nombre,
            overflow: TextOverflow.ellipsis,
          ),
        )).toList(),
        onChanged: (value) => setState(() => _tipoGaranteSeleccionado = value),
        validator: (value) => validarDropdown(
          value?.toString(),
          'Tipo de garante',
        ),
      );
    },
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, _) => Text('Error: $error'),
  );
}

  Widget _buildObservacionField() {
    return TextFormField(
      controller: _observacionController,
      decoration: InputDecoration(
        labelText: 'OBSERVACIÓN',
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: ResponsiveUtilsBosque.getVerticalPadding(context),
        ),
      ),
      maxLines: 2,
      validator: (value) => validarTextoMixto(value, esObligatorio: true),
      inputFormatters: bloquearEspacios,
    );
  }

  Widget _buildButtons(BuildContext context) {
    final buttonSpacing = ResponsiveUtilsBosque.getHorizontalPadding(context) / 2;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: widget.onCancel,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: buttonSpacing,
              vertical: 12,
            ),
          ),
          child: const Text('Cancelar'),
        ),
        SizedBox(width: buttonSpacing),
        ElevatedButton(
          onPressed: _handleSubmit,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: buttonSpacing,
              vertical: 12,
            ),
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
