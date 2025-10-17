import 'dart:ui';

import 'package:bosque_flutter/core/state/Consumo_tigo_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/utils/validators.dart';
import 'package:bosque_flutter/domain/entities/socio_tigo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormularioSocios extends ConsumerStatefulWidget {
  final String title;
  final SocioTigoEntity? socios;
  final int? codEmpleado;
  final String periodoCobrado;
  final bool isEditing;
  final Function(SocioTigoEntity) onSave;
  final VoidCallback onCancel;

  const FormularioSocios({
    Key? key,
    required this.title,
    this.socios,
    required this.codEmpleado,
    required this.periodoCobrado,
    required this.isEditing,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  FormularioSocioState createState() => FormularioSocioState();
}

class FormularioSocioState extends ConsumerState<FormularioSocios> {
  final _formKey = GlobalKey<FormState>();

  final _codEmpleadoController = TextEditingController();
  final _nombreCompletoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _descripcionController = TextEditingController();

  int? _socioSeleccionado;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.socios != null) {
      _codEmpleadoController.text = widget.socios!.nombreCompleto;
      _socioSeleccionado = widget.socios!.codEmpleado;
      _nombreCompletoController.text = widget.socios!.nombreCompleto;
      _telefonoController.text = widget.socios!.telefono.toString();
      _descripcionController.text = widget.socios?.descripcion ?? '';
    }
  }

  @override
  void dispose() {
    _codEmpleadoController.dispose();
    _nombreCompletoController.dispose();
    _telefonoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<int> getCodUsuario() async {
    return await ref.read(userProvider.notifier).getCodUsuario();
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final codEmpleadoValue = _socioSeleccionado ?? null;
      final telefonoIngresado = int.tryParse(_telefonoController.text);

    // VALIDACIÓN: Verificar si el teléfono ya existe en facturasTigoProvider
    final facturasAsync = ref.read(tigoResumenDetallado(widget.periodoCobrado));
    final facturas = facturasAsync.asData?.value ?? [];
    //print('Teléfono ingresado: $telefonoIngresado');
    //print('Facturas encontradas: ${facturas.length}');
    bool telefonoDuplicado = false;
    for (var factura in facturas) {
      //print('Comparando factura.nroCuenta=${factura.corporativo} con telefonoIngresado=$telefonoIngresado');
      // Ajusta el tipo de comparación según tu modelo
      if (factura.corporativo.toString() == telefonoIngresado.toString() &&
      (factura.nombreCompleto.toUpperCase() ) != 'SIN ASIGNAR') {
    telefonoDuplicado = true;
    break;
  }
    }
    //rint('¿Teléfono duplicado? $telefonoDuplicado');

    if (telefonoDuplicado) {
      if (context.mounted) {
        AppSnackbar.showError(
          context,
          'El número de teléfono ya está registrado. Por favor, ingrese un número diferente.',
        );
      }
      return; 
    }
      try {
        final socios = widget.isEditing && widget.socios != null
            ? widget.socios!.copyWith(
                codCuenta: widget.socios!.codCuenta,
                codEmpleado: codEmpleadoValue,
                nombreCompleto: _nombreCompletoController.text,
                telefono: int.parse(_telefonoController.text),
                descripcion: _descripcionController.text,
                audUsuario: await getCodUsuario(),
              )
            : SocioTigoEntity(
                codCuenta: 0,
                codEmpleado: _socioSeleccionado,
                nombreCompleto: _nombreCompletoController.text,
                telefono: int.parse(_telefonoController.text),
                descripcion: _descripcionController.text,
                periodoCobrado: widget.periodoCobrado,
                audUsuario: await getCodUsuario(),
              );

        if (!mounted) return;

        await widget.onSave(socios);

        if (context.mounted) {
          if (widget.isEditing) {
            AppSnackbarCustom.showEdit(
              context,
              'Socio actualizado correctamente',
            );
          } else {
            AppSnackbarCustom.showAdd(
              context,
              'Socio agregado correctamente',
            );
          }
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.showError(
            context,
            'Error al ${widget.isEditing ? 'actualizar' : 'agregar'} el socio',
          );
        }
      }
    }
  }

  @override
Widget build(BuildContext context) {
  final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
  final screenWidth = MediaQuery.of(context).size.width;
  //final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
  final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);

  return Padding(
    padding: EdgeInsets.symmetric(
      horizontal: isDesktop ? screenWidth * 0.08 : 12,
      vertical: verticalPadding + 12,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context),
        const SizedBox(height: 18),
        _buildForm(context),
        const SizedBox(height: 24),
        _buildButtons(context),
      ],
    ),
  );
}

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          widget.isEditing ? Icons.edit : Icons.person_add,
          color: widget.isEditing ? Colors.orange[800] : Colors.blue[800],
          size: 32,
        ),
        const SizedBox(width: 12),
        Text(
          widget.title,
          style: ResponsiveUtilsBosque.getTitleStyle(context)?.copyWith(
            color: widget.isEditing ? Colors.orange[800] : Colors.blue[800],
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final spacing = ResponsiveUtilsBosque.getVerticalPadding(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSocios(),
          if (!widget.isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Nota: Para registrar un nuevo socio, deje el campo 'Socios' sin seleccionar y complete el nombre manualmente.",
                        style: TextStyle(
                          color: Colors.blueGrey[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: spacing),
          _buildNombreCompletoInput(),
          SizedBox(height: spacing),
          _buildTelefonoInput(),
          SizedBox(height: spacing),
          _buildDescripcionInput(),
        ],
      ),
    );
  }

 Widget _buildSocios() {
  final sociosTigo = ref.watch(obtenerSociosTigo);

  return sociosTigo.when(
    data: (tigoSocios) => DropdownButtonFormField<int>(
      isExpanded: true,
      value: tigoSocios.any((asociado) => asociado.codEmpleado == _socioSeleccionado)
          ? _socioSeleccionado
          : null,
      decoration: InputDecoration(
        labelText: 'Socios',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.group),
      ),
      items: tigoSocios
          .map((asociado) => DropdownMenuItem(
                value: asociado.codEmpleado, 
                child: Text(asociado.nombreCompleto),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _socioSeleccionado = value;
          // Autocompletar el nombre completo
          final seleccionado = tigoSocios.firstWhere(
            (s) => s.codEmpleado == value,
            orElse: () => SocioTigoEntity(
              codCuenta: 0,
              codEmpleado: 0,
              nombreCompleto: '',
              telefono: 0,
              descripcion: '',
              periodoCobrado: widget.periodoCobrado,
              audUsuario: 0,
            ),
          );
          _nombreCompletoController.text = seleccionado.nombreCompleto;
        });
      },
      validator: (value) {
        if (widget.isEditing && value == null) {
          return 'Debe seleccionar un socio.';
        }
        return null; // Si no hay error, devuelve null.
      },
    ),
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, _) => Text('Error: $error'),
  );
}

 Widget _buildNombreCompletoInput() {
  return TextFormField(
    controller: _nombreCompletoController,
    decoration: InputDecoration(
      labelText: 'Nombre Completo',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      prefixIcon: const Icon(Icons.person),
    ),
    validator: (value) => validarTextoMixto(value, esObligatorio: true),
    readOnly: _socioSeleccionado != null, // Solo lectura si hay socio seleccionado
  );
}

  Widget _buildTelefonoInput() {
  final nroSinAsignarAsync = ref.watch(obtenerNroSinAsignar(widget.periodoCobrado));

  return nroSinAsignarAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, _) => Text('Error: $error'),
    data: (nros) {
      print('Números sin asignar recibidos: ${nros.map((e) => e.telefono)}');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.centerRight,
            children: [
              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                  suffixIcon: nros.isNotEmpty
    ? IconButton(
        icon: const Icon(Icons.warning, color: Colors.orange),
        tooltip: 'Ver números sin asignar',
        onPressed: () => _mostrarDialogoNumerosSinAsignar(nros),
      )
    : null,
                ),
                keyboardType: TextInputType.number,
                validator: (value) => validarSoloNumeros(value, esObligatorio: true),
              ),
            ],
          ),
          if (nros.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 4.0),
              child: Text(
                '¡Hay números sin asignar!',
                style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold),
              ),
            ),
        ],
      );
    },
  );
}
Future<void> _mostrarDialogoNumerosSinAsignar(List<SocioTigoEntity> nros) async {
  if (nros.isEmpty) return;
  final seleccionado = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Números sin asignar'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: nros.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final nro = nros[index].telefono.toString();
            return ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: Text(
                nro,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              onTap: () => Navigator.of(ctx).pop(nro),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
  if (seleccionado != null) {
    _telefonoController.text = seleccionado;
  }
}

  Widget _buildDescripcionInput() {
    return TextFormField(
      controller: _descripcionController,
      decoration: InputDecoration(
        labelText: 'Descripción',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.description),
      ),
      validator: (value) => null, // Opcional
    );
  }

  Widget _buildButtons(BuildContext context) {
    //final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.close, color: Colors.red),
          label: const Text('Cancelar'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context) / 2,
              vertical: 14,
            ),
          ),
        ),
        SizedBox(width: ResponsiveUtilsBosque.getHorizontalPadding(context) / 2),
        ElevatedButton.icon(
          onPressed: _handleSubmit,
          icon: Icon(widget.isEditing ? Icons.save : Icons.check, color: Colors.white),
          label: Text(widget.isEditing ? 'Actualizar' : 'Guardar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isEditing ? Colors.orange[800] : Colors.blue[800],
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context) / 2,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}