import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bosque_flutter/core/state/depositos_cheques_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'dart:typed_data';

// Proveedor para almacenar los bytes de la imagen (necesario para web)
final imageBytesProvider = StateProvider<Uint8List?>((ref) => null);

class DepositoChequeRegisterScreen extends ConsumerWidget {
  const DepositoChequeRegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(depositosChequesProvider);
    final notifier = ref.read(depositosChequesProvider.notifier);
    final imageBytes = ref.watch(imageBytesProvider);
    
    // Determinar si estamos en móvil o desktop
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    
    // Obtener los paddings responsivos
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Depósitos'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.teal,
      ),
      body: state.cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtilsBosque.getResponsiveValue(
                      context: context,
                      defaultValue: 16.0,
                      mobile: 12.0,
                      desktop: 20.0,
                    ),
                  ),
                ),
                padding: EdgeInsets.all(
                  ResponsiveUtilsBosque.getResponsiveValue(
                    context: context,
                    defaultValue: 24.0,
                    mobile: 16.0,
                    desktop: 32.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Layout responsivo para empresa y cliente
                    isMobile
                        ? _buildMobileFields(context, state, notifier)
                        : _buildDesktopFields(context, state, notifier),
                    // Tabla de notas de remisión
                    if (state.notasRemision.isNotEmpty) ...[
                      SizedBox(height: ResponsiveUtilsBosque.getVerticalPadding(context)),
                      _buildNotasRemisionTable(context, state, notifier),
                    ],
                    
                    SizedBox(height: ResponsiveUtilsBosque.getVerticalPadding(context)),
                    
                    // Layout responsivo para cuenta y banco
                    isMobile
                        ? _buildMobileBancoFields(context, state, notifier)
                        : _buildDesktopBancoFields(context, state, notifier),
                    
                    SizedBox(height: ResponsiveUtilsBosque.getVerticalPadding(context)),
                    
                    // Layout responsivo para importe y moneda
                    isMobile
                        ? _buildMobileImporteFields(context, state, notifier)
                        : _buildDesktopImporteFields(context, state, notifier),
                    
                    SizedBox(height: ResponsiveUtilsBosque.getVerticalPadding(context) * 1.5),
                    
                    // Sección de imagen del depósito
                    Text(
                      'Imagen del Depósito',
                      style: ResponsiveUtilsBosque.getResponsiveValue(
                        context: context,
                        defaultValue: Theme.of(context).textTheme.titleMedium,
                        desktop: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtilsBosque.getVerticalPadding(context) * 0.5),
                    
                    // Pasamos el imageBytes y ref para manejo multiplataforma
                    _buildImageUploader(context, state, notifier, imageBytes, ref),
                    
                    SizedBox(height: ResponsiveUtilsBosque.getVerticalPadding(context) * 1.5),
                    
                    // Botones de acción
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        alignment: WrapAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              notifier.limpiarFormulario();
                              // También limpiamos los bytes de la imagen
                              ref.read(imageBytesProvider.notifier).state = null;
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtilsBosque.getResponsiveValue(
                                  context: context,
                                  defaultValue: 16.0,
                                  mobile: 12.0,
                                  desktop: 24.0,
                                ),
                                vertical: ResponsiveUtilsBosque.getResponsiveValue(
                                  context: context,
                                  defaultValue: 12.0,
                                  mobile: 8.0,
                                  desktop: 16.0,
                                ),
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final tieneNotas = state.notasSeleccionadas.isNotEmpty;
                              final tieneACuenta = state.aCuenta > 0;
                              if (state.bancoSeleccionado == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Debe seleccionar un banco.')),
                                );
                                return;
                              }
                              if (!(tieneNotas || tieneACuenta) || state.importeTotal <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Debe seleccionar al menos una nota de remisión o ingresar un valor a cuenta mayor a 0. El importe total debe ser mayor a 0.')),
                                );
                                return;
                              }
                              final imageBytes = ref.read(imageBytesProvider);
                              final imagen = kIsWeb ? imageBytes : state.imagenDeposito;
                              if (imagen == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Debe cargar una imagen del depósito.')),
                                );
                                return;
                              }
                              try {
                                final okDeposito = await notifier.registrarDeposito(imagen);
                                if (!okDeposito) throw Exception('No se pudo registrar el depósito');
                                final okNotas = await notifier.guardarNotasRemision();
                                if (!okNotas) throw Exception('No se pudieron registrar todas las notas de remisión');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Depósito y notas de remisión registrados correctamente.')),
                                );
                                notifier.limpiarFormulario();
                                ref.read(imageBytesProvider.notifier).state = null;
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: ${e.toString()}')),
                                );
                              }
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Guardar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtilsBosque.getResponsiveValue(
                                  context: context,
                                  defaultValue: 16.0,
                                  mobile: 12.0,
                                  desktop: 24.0,
                                ),
                                vertical: ResponsiveUtilsBosque.getResponsiveValue(
                                  context: context,
                                  defaultValue: 12.0,
                                  mobile: 8.0,
                                  desktop: 16.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget para los campos de empresa y cliente en móvil (columna)
  Widget _buildMobileFields(BuildContext context, dynamic state, dynamic notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEmpresaField(context, state, notifier),
        SizedBox(height: ResponsiveUtilsBosque.getVerticalPadding(context)),
        _buildClienteField(context, state, notifier),
      ],
    );
  }

  // Widget para los campos de empresa y cliente en desktop (fila)
  Widget _buildDesktopFields(BuildContext context, dynamic state, dynamic notifier) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildEmpresaField(context, state, notifier)),
        SizedBox(width: ResponsiveUtilsBosque.getHorizontalPadding(context)),
        Expanded(child: _buildClienteField(context, state, notifier)),
      ],
    );
  }

  // Widget para los campos de A Cuenta y Banco en móvil (columna)
  Widget _buildMobileBancoFields(BuildContext context, dynamic state, dynamic notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildACuentaField(context, state, notifier),
        SizedBox(height: ResponsiveUtilsBosque.getVerticalPadding(context)),
        _buildBancoField(context, state, notifier),
      ],
    );
  }

  // Widget para los campos de A Cuenta y Banco en desktop (fila)
  Widget _buildDesktopBancoFields(BuildContext context, dynamic state, dynamic notifier) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildACuentaField(context, state, notifier)),
        SizedBox(width: ResponsiveUtilsBosque.getHorizontalPadding(context)),
        Expanded(child: _buildBancoField(context, state, notifier)),
      ],
    );
  }

  // Widget para los campos de Importe y Moneda en móvil (columna)
  Widget _buildMobileImporteFields(BuildContext context, dynamic state, dynamic notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImporteTotalField(context, state, notifier),
        SizedBox(height: ResponsiveUtilsBosque.getVerticalPadding(context)),
        _buildMonedaField(context, state, notifier),
      ],
    );
  }

  // Widget para los campos de Importe y Moneda en desktop (fila)
  Widget _buildDesktopImporteFields(BuildContext context, dynamic state, dynamic notifier) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildImporteTotalField(context, state, notifier)),
        SizedBox(width: ResponsiveUtilsBosque.getHorizontalPadding(context)),
        Expanded(child: _buildMonedaField(context, state, notifier)),
      ],
    );
  }

  // Campo de Empresa
  Widget _buildEmpresaField(BuildContext context, dynamic state, dynamic notifier) {
    // Corregir el error de tipo generando explícitamente los DropdownMenuItem<dynamic>
    final empresaItems = state.empresas.map<DropdownMenuItem<dynamic>>((e) => 
      DropdownMenuItem<dynamic>(
        value: e,
        child: Text(e.nombre),
      )
    ).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Empresa',
          style: TextStyle(
            fontSize: ResponsiveUtilsBosque.getResponsiveValue(
              context: context,
              defaultValue: 14.0,
              mobile: 14.0,
              desktop: 16.0,
            ),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<dynamic>(  // Especificar el tipo genérico aquí
          value: state.empresaSeleccionada,
          items: empresaItems,
          onChanged: (value) {
            // Primero limpiamos el cliente seleccionado antes de cambiar la empresa
            notifier.seleccionarCliente(null);
            // Luego cambiamos la empresa
            notifier.seleccionarEmpresa(value);
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Seleccione una empresa',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
        ),
      ],
    );
  }

  // Campo de Cliente con búsqueda
  Widget _buildClienteField(BuildContext context, dynamic state, dynamic notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cliente',
          style: TextStyle(
            fontSize: ResponsiveUtilsBosque.getResponsiveValue(
              context: context,
              defaultValue: 14.0,
              mobile: 14.0,
              desktop: 16.0,
            ),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        // Verificamos si hay clientes para mostrar
        state.clientes.isEmpty && state.empresaSeleccionada != null
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.red.shade50,
                ),
                child: const Text(
                  'No existen clientes para la empresa seleccionada.',
                  style: TextStyle(color: Colors.red),
                ),
              )
            : Stack(
                children: [
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: 'Buscar cliente',
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      suffixIcon: state.clienteSeleccionado != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => notifier.seleccionarCliente(null),
                            )
                          : null,
                    ),
                    controller: TextEditingController(
                      text: state.clienteSeleccionado?.nombreCompleto ?? '',
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => ClienteSearchDialog(
                          clientes: state.clientes,
                          onClienteSelected: (cliente) {
                            notifier.seleccionarCliente(cliente);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
      ],
    );
  }

  // Campo de A Cuenta
  Widget _buildACuentaField(BuildContext context, dynamic state, dynamic notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A Cuenta',
          style: TextStyle(
            fontSize: ResponsiveUtilsBosque.getResponsiveValue(
              context: context,
              defaultValue: 14.0,
              mobile: 14.0,
              desktop: 16.0,
            ),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          initialValue: state.aCuenta.toStringAsFixed(2),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (v) => notifier.setACuenta(double.tryParse(v) ?? 0.0),
        ),
      ],
    );
  }

  // Campo de Banco
  Widget _buildBancoField(BuildContext context, dynamic state, dynamic notifier) {
    // Corregir el error de tipo generando explícitamente los DropdownMenuItem<dynamic>
    final bancoItems = state.bancos.map<DropdownMenuItem<dynamic>>((b) => 
      DropdownMenuItem<dynamic>(
        value: b,
        child: Text(b.nombreBanco),
      )
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Banco',
          style: TextStyle(
            fontSize: ResponsiveUtilsBosque.getResponsiveValue(
              context: context,
              defaultValue: 14.0,
              mobile: 14.0,
              desktop: 16.0,
            ),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<dynamic>(  // Especificar el tipo genérico aquí
          value: state.bancoSeleccionado,
          items: bancoItems,
          onChanged: (value) => notifier.seleccionarBanco(value),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Seleccione un banco',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
        ),
      ],
    );
  }

  // Campo de Importe Total (solo lectura y calculado en tiempo real)
  Widget _buildImporteTotalField(BuildContext context, dynamic state, dynamic notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Importe Total',
          style: TextStyle(
            fontSize: ResponsiveUtilsBosque.getResponsiveValue(
              context: context,
              defaultValue: 14.0,
              mobile: 14.0,
              desktop: 16.0,
            ),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey.shade100,
          ),
          child: Text(
            state.importeTotal.toStringAsFixed(2),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // Campo de Moneda
  Widget _buildMonedaField(BuildContext context, dynamic state, dynamic notifier) {
    // Opciones con label y valor
    final monedaOptions = const [
      {'label': 'Bolivianos', 'value': 'BS'},
      {'label': 'Dólares', 'value': 'USD'},
    ];
    final monedaItems = monedaOptions.map<DropdownMenuItem<String>>((m) =>
      DropdownMenuItem<String>(
        value: m['value']!,
        child: Text(m['label']!),
      )
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Moneda',
          style: TextStyle(
            fontSize: ResponsiveUtilsBosque.getResponsiveValue(
              context: context,
              defaultValue: 14.0,
              mobile: 14.0,
              desktop: 16.0,
            ),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: state.monedaSeleccionada,
          items: monedaItems,
          onChanged: (value) => notifier.seleccionarMoneda(value),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
        ),
      ],
    );
  }

  // Widget para subir imágenes - COMPATIBLE CON WEB Y MÓVIL, CON OPCIÓN DE CÁMARA EN MÓVIL
  Widget _buildImageUploader(BuildContext context, dynamic state, dynamic notifier, Uint8List? imageBytes, WidgetRef ref) {
    final imageHeight = ResponsiveUtilsBosque.getResponsiveValue(
      context: context,
      defaultValue: 120.0,
      mobile: 100.0,
      tablet: 120.0,
      desktop: 150.0,
    );

    // Función para seleccionar/capturar imagen desde móvil o web
    Future<void> _pickImage(ImageSource source) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        if (kIsWeb) {
          // Para web, leemos los bytes directamente
          final bytes = await pickedFile.readAsBytes();
          ref.read(imageBytesProvider.notifier).state = bytes;
        } else {
          // Para móvil, usamos el File normalmente
          notifier.setImagenDeposito(File(pickedFile.path));
        }
      }
    }

    // Función para mostrar el modal de selección de origen de imagen en móvil
    void _showImageSourceActionSheet(BuildContext context) {
      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (BuildContext context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Seleccionar imagen desde',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Galería'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Cámara'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return GestureDetector(
      onTap: () {
        if (!kIsWeb && ResponsiveUtilsBosque.isMobile(context)) {
          // En móvil, mostramos el modal para elegir entre cámara y galería
          _showImageSourceActionSheet(context);
        } else {
          // En web o escritorio, solo permitimos seleccionar de la galería
          _pickImage(ImageSource.gallery);
        }
      },
      child: DottedBorder(
        color: Colors.grey,
        dashPattern: const [6, 3],
        borderType: BorderType.RRect,
        radius: Radius.circular(ResponsiveUtilsBosque.getResponsiveValue(
          context: context,
          defaultValue: 8.0,
          mobile: 6.0,
          desktop: 10.0,
        )),
        child: Container(
          height: imageHeight,
          width: double.infinity,
          alignment: Alignment.center,
          child: _buildImageContent(context, state, notifier, imageHeight, imageBytes, ref),
        ),
      ),
    );
  }

  // Contenido de la imagen - COMPATIBLE CON WEB Y MÓVIL
  Widget _buildImageContent(BuildContext context, dynamic state, dynamic notifier, double imageHeight, Uint8List? imageBytes, WidgetRef ref) {
    final isMobile = !kIsWeb && ResponsiveUtilsBosque.isMobile(context);
    
    // Si estamos en web y tenemos bytes de imagen
    if (kIsWeb && imageBytes != null) {
      return Stack(
        children: [
          Center(
            child: Image.memory(
              imageBytes,
              height: imageHeight,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: GestureDetector(
              onTap: () {
                // Eliminar la imagen en web
                ref.read(imageBytesProvider.notifier).state = null;
              },
              child: CircleAvatar(
                radius: ResponsiveUtilsBosque.getResponsiveValue(
                  context: context,
                  defaultValue: 14.0,
                  mobile: 12.0,
                  desktop: 16.0,
                ),
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.close,
                  size: ResponsiveUtilsBosque.getResponsiveValue(
                    context: context,
                    defaultValue: 18.0,
                    mobile: 16.0,
                    desktop: 20.0,
                  ),
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      );
    } 
    // Si no estamos en web y tenemos una imagen de archivo
    else if (!kIsWeb && state.imagenDeposito != null) {
      return Stack(
        children: [
          Center(
            child: Image.file(
              state.imagenDeposito!,
              height: imageHeight,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: GestureDetector(
              onTap: () => notifier.setImagenDeposito(null),
              child: CircleAvatar(
                radius: ResponsiveUtilsBosque.getResponsiveValue(
                  context: context,
                  defaultValue: 14.0,
                  mobile: 12.0,
                  desktop: 16.0,
                ),
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.close,
                  size: ResponsiveUtilsBosque.getResponsiveValue(
                    context: context,
                    defaultValue: 18.0,
                    mobile: 16.0,
                    desktop: 20.0,
                  ),
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      );
    } 
    // Si no hay imagen seleccionada
    else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload,
                size: ResponsiveUtilsBosque.getResponsiveValue(
                  context: context,
                  defaultValue: 36.0,
                  mobile: 28.0,
                  desktop: 40.0,
                ),
                color: Colors.grey,
              ),
              // Solo en móvil, mostramos el icono de la cámara
              if (isMobile) ...[
                SizedBox(width: 16),
                Icon(
                  Icons.camera_alt,
                  size: ResponsiveUtilsBosque.getResponsiveValue(
                    context: context,
                    defaultValue: 36.0,
                    mobile: 28.0,
                    desktop: 40.0,
                  ),
                  color: Colors.grey,
                ),
              ],
            ],
          ),
          SizedBox(height: 8),
          Text(
            isMobile
                ? 'Toca para capturar o seleccionar imagen'
                : 'Arrastra y suelta tu imagen aquí o haz clic para seleccionar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveUtilsBosque.getResponsiveValue(
                context: context,
                defaultValue: 14.0,
                mobile: 12.0,
                desktop: 14.0,
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Formatos permitidos: JPG, JPEG, PNG. Tamaño máximo: 5MB',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveUtilsBosque.getResponsiveValue(
                context: context,
                defaultValue: 12.0,
                mobile: 10.0,
                desktop: 12.0,
              ),
              color: Colors.grey,
            ),
          ),
        ],
      );
    }
  }

  // Widget para la tabla de notas de remisión
  Widget _buildNotasRemisionTable(BuildContext context, dynamic state, dynamic notifier) {
    final notas = state.notasRemision;
    final seleccionadas = state.notasSeleccionadas;
    final saldosEditados = state.saldosEditados;
    double totalSeleccionados = 0;
    for (var nota in notas) {
      if (seleccionadas.contains(nota.docNum)) {
        totalSeleccionados += saldosEditados[nota.docNum]?.toDouble() ?? nota.saldoPendiente.toDouble();
      }
    }
    final double nuevoImporteTotal = totalSeleccionados + (state.aCuenta ?? 0);
    if (state.importeTotal != nuevoImporteTotal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.setImporteTotal(nuevoImporteTotal);
      });
    }
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documentos Disponibles',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Número de Documento', style: TextStyle(color: Colors.green))),
              DataColumn(label: Text('Num. Factura', style: TextStyle(color: Colors.green))),
              DataColumn(label: Text('Fecha', style: TextStyle(color: Colors.green))),
              DataColumn(label: Text('Cliente', style: TextStyle(color: Colors.green))),
              DataColumn(label: Text('Total (Bs)', style: TextStyle(color: Colors.green))),
              DataColumn(label: Text('Saldo Pendiente (Bs)', style: TextStyle(color: Colors.green))),
            ],
            rows: notas.map<DataRow>((nota) {
              final seleccionado = seleccionadas.contains(nota.docNum);
              final saldoValue = saldosEditados[nota.docNum]?.toString() ?? nota.saldoPendiente.toString();
              return DataRow(
                selected: seleccionado,
                onSelectChanged: (selected) {
                  notifier.seleccionarNota(nota.docNum, selected ?? false);
                },
                cells: [
                  DataCell(Text(nota.docNum.toString())),
                  DataCell(Text(nota.numFact.toString())),
                  DataCell(Text('${nota.fecha.day.toString().padLeft(2, '0')}/${nota.fecha.month.toString().padLeft(2, '0')}/${nota.fecha.year}')),
                  DataCell(Text(nota.nombreCliente)),
                  DataCell(Text(nota.totalMonto.toString())),
                  DataCell(
                    seleccionado
                      ? _EditableSaldoPendienteCell(
                          valorOriginal: nota.saldoPendiente,
                          valorActual: saldoValue,
                          onChanged: (v, showError) {
                            final val = double.tryParse(v) ?? 0.0;
                            if (val <= nota.saldoPendiente) {
                              notifier.editarSaldoPendiente(nota.docNum, val);
                            }
                            showError(val > nota.saldoPendiente);
                          },
                        )
                      : Text(nota.saldoPendiente.toString()),
                  ),
                ],
              );
            }).toList(growable: false),
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total de documentos: ${notas.length}'),
            Text('Documentos seleccionados: ${seleccionadas.length} | Total de documentos: ${totalSeleccionados.toStringAsFixed(2)}'),
          ],
        ),
      ],
    );
  }
}

// Diálogo de búsqueda de clientes
class ClienteSearchDialog extends StatefulWidget {
  final List<dynamic> clientes;
  final Function(dynamic) onClienteSelected;

  const ClienteSearchDialog({
    Key? key,
    required this.clientes,
    required this.onClienteSelected,
  }) : super(key: key);

  @override
  State<ClienteSearchDialog> createState() => _ClienteSearchDialogState();
}

class _ClienteSearchDialogState extends State<ClienteSearchDialog> {
  late TextEditingController _searchController;
  List<dynamic> _filteredClientes = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredClientes = List.from(widget.clientes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterClientes(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredClientes = List.from(widget.clientes);
      });
    } else {
      setState(() {
        _filteredClientes = widget.clientes
            .where((cliente) => 
                cliente.nombreCompleto.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final dialogWidth = isDesktop 
        ? MediaQuery.of(context).size.width * 0.4 
        : MediaQuery.of(context).size.width * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: dialogWidth,
        padding: EdgeInsets.all(
          ResponsiveUtilsBosque.getResponsiveValue(
            context: context,
            defaultValue: 16.0,
            mobile: 12.0,
            desktop: 20.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buscar Cliente',
              style: TextStyle(
                fontSize: ResponsiveUtilsBosque.getResponsiveValue(
                  context: context,
                  defaultValue: 18.0,
                  mobile: 16.0,
                  desktop: 20.0,
                ),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Ingrese nombre del cliente',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterClientes,
              autofocus: true,
            ),
            SizedBox(height: 16),
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * (isDesktop ? 0.6 : 0.4),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredClientes.length,
                  itemBuilder: (context, index) {
                    final cliente = _filteredClientes[index];
                    return ListTile(
                      title: Text(
                        cliente.nombreCompleto,
                        style: TextStyle(
                          fontSize: ResponsiveUtilsBosque.getResponsiveValue(
                            context: context,
                            defaultValue: 14.0,
                            mobile: 14.0,
                            desktop: 16.0,
                          ),
                        ),
                      ),
                      onTap: () => widget.onClienteSelected(cliente),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// DottedBorder widget (puedes usar el paquete dotted_border)
class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final List<double> dashPattern;
  final BorderType borderType;
  final Radius radius;
  const DottedBorder({
    required this.child,
    this.color = Colors.grey,
    this.dashPattern = const [6, 3],
    this.borderType = BorderType.RRect,
    this.radius = const Radius.circular(8),
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    // Aquí deberías usar el widget del paquete dotted_border real
    // Esto es solo un placeholder visual
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color, style: BorderStyle.solid),
        borderRadius: BorderRadius.all(radius),
      ),
      child: child,
    );
  }
}

enum BorderType { RRect }

// Widget para celda editable de saldo pendiente con validación y error en tiempo real
class _EditableSaldoPendienteCell extends StatefulWidget {
  final double valorOriginal;
  final String valorActual;
  final void Function(String, void Function(bool)) onChanged;
  const _EditableSaldoPendienteCell({
    required this.valorOriginal,
    required this.valorActual,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<_EditableSaldoPendienteCell> createState() => _EditableSaldoPendienteCellState();
}

class _EditableSaldoPendienteCellState extends State<_EditableSaldoPendienteCell> {
  late TextEditingController _controller;
  String? _errorText;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.valorActual);
  }

  @override
  void didUpdateWidget(covariant _EditableSaldoPendienteCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo actualiza el texto si el valor cambió y el campo NO tiene el foco
    if (oldWidget.valorActual != widget.valorActual && !_focusNode.hasFocus) {
      _controller.text = widget.valorActual;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: TextFormField(
            controller: _controller,
            keyboardType: TextInputType.number,
            focusNode: _focusNode,
            onChanged: (v) {
              final val = double.tryParse(v) ?? 0.0;
              if (val > widget.valorOriginal) {
                setState(() {
                  _errorText = 'No puede ser mayor al saldo original';
                });
              } else {
                setState(() {
                  _errorText = null;
                });
              }
              widget.onChanged(v, (show) {
                setState(() {
                  _errorText = show ? 'No puede ser mayor al saldo original' : null;
                });
              });
            },
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              errorText: _errorText,
            ),
          ),
        ),
      ],
    );
  }
}