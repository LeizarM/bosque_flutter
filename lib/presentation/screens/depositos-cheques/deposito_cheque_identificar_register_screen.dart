import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bosque_flutter/core/state/depositos_cheques_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

final imageBytesIdentificarProvider = StateProvider<Uint8List?>((ref) => null);

final depositosChequesIdentificarRegisterProvider =
    StateNotifierProvider<DepositosChequesNotifier, DepositosChequesState>(
      (ref) => DepositosChequesNotifier(ref),
    );

class DepositoChequeIdentificarScreen extends ConsumerStatefulWidget {
  const DepositoChequeIdentificarScreen({super.key});

  @override
  ConsumerState<DepositoChequeIdentificarScreen> createState() =>
      _DepositoChequeIdentificarScreenState();
}

class _DepositoChequeIdentificarScreenState
    extends ConsumerState<DepositoChequeIdentificarScreen> {
  bool _isDragging = false;
  int _dragCounter = 0;
  final List<StreamSubscription> _dragSubs = [];

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      _dragSubs.add(
        html.document.onDragEnter.listen((event) {
          event.preventDefault();
          _dragCounter++;
          if (_dragCounter == 1 && mounted) {
            setState(() => _isDragging = true);
          }
        }),
      );
      _dragSubs.add(
        html.document.onDragOver.listen((event) {
          event.preventDefault();
        }),
      );
      _dragSubs.add(
        html.document.onDragLeave.listen((event) {
          _dragCounter--;
          if (_dragCounter <= 0 && mounted) {
            _dragCounter = 0;
            setState(() => _isDragging = false);
          }
        }),
      );
      _dragSubs.add(
        html.document.onDrop.listen((event) async {
          event.preventDefault();
          _dragCounter = 0;
          if (mounted) setState(() => _isDragging = false);
          final files = event.dataTransfer.files;
          if (files != null && files.isNotEmpty) {
            final file = files[0];
            if (file.type.startsWith('image/')) {
              final reader = html.FileReader();
              reader.readAsDataUrl(file);
              await reader.onLoad.first;
              final dataUrl = reader.result as String;
              final base64Str = dataUrl.split(',').last;
              final bytes = base64Decode(base64Str);
              if (mounted) {
                ref
                    .read(imageBytesIdentificarProvider.notifier)
                    .state = Uint8List.fromList(bytes);
              }
            }
          }
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final sub in _dragSubs) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(depositosChequesIdentificarRegisterProvider);
    final notifier = ref.read(
      depositosChequesIdentificarRegisterProvider.notifier,
    );
    final imageBytes = ref.watch(imageBytesIdentificarProvider);
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(
      context,
    );
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Depósitos por Identificar'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
      body:
          state.cargando
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withValues(alpha: 0.4),
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
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Datos del Depósito',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      isMobile
                          ? _buildMobileFields(context, state, notifier)
                          : _buildDesktopFields(context, state, notifier),
                      SizedBox(
                        height: ResponsiveUtilsBosque.getVerticalPadding(
                          context,
                        ),
                      ),
                      isMobile
                          ? _buildMobileBancoFields(context, state, notifier)
                          : _buildDesktopBancoFields(context, state, notifier),
                      SizedBox(
                        height: ResponsiveUtilsBosque.getVerticalPadding(
                          context,
                        ),
                      ),
                      isMobile
                          ? _buildMobileImporteFields(context, state, notifier)
                          : _buildDesktopImporteFields(
                            context,
                            state,
                            notifier,
                          ),
                      SizedBox(
                        height:
                            ResponsiveUtilsBosque.getVerticalPadding(context) *
                            1.5,
                      ),
                      _buildObservacionesField(context, notifier),
                      SizedBox(
                        height:
                            ResponsiveUtilsBosque.getVerticalPadding(context) *
                            1.5,
                      ),
                      Text(
                        'Imagen del Depósito',
                        style: ResponsiveUtilsBosque.getResponsiveValue(
                          context: context,
                          defaultValue: Theme.of(context).textTheme.titleMedium,
                          desktop: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      SizedBox(
                        height:
                            ResponsiveUtilsBosque.getVerticalPadding(context) *
                            0.5,
                      ),
                      _buildImageUploader(
                        context,
                        state,
                        notifier,
                        imageBytes,
                        ref,
                      ),
                      SizedBox(
                        height:
                            ResponsiveUtilsBosque.getVerticalPadding(context) *
                            1.5,
                      ),
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
                                ref
                                    .read(
                                      imageBytesIdentificarProvider.notifier,
                                    )
                                    .state = null;
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      ResponsiveUtilsBosque.getResponsiveValue(
                                        context: context,
                                        defaultValue: 16.0,
                                        mobile: 12.0,
                                        desktop: 24.0,
                                      ),
                                  vertical:
                                      ResponsiveUtilsBosque.getResponsiveValue(
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
                              onPressed:
                                  _isGuardarEnabled(state)
                                      ? () async {
                                        if (state.empresaSeleccionada == null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Debe seleccionar una empresa.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        if (state.bancoSeleccionado == null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Debe seleccionar un banco.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        if (state.monedaSeleccionada == '') {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Debe seleccionar una moneda.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        if (state.importeTotal <= 0) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'El importe total debe ser mayor a 0.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        final imagenParaEnviar =
                                            kIsWeb
                                                ? ref.read(
                                                  imageBytesIdentificarProvider,
                                                )
                                                : state.imagenDeposito;
                                        if (imagenParaEnviar == null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Debe cargar una imagen del depósito.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        try {
                                          final okDeposito = await notifier
                                              .registrarDeposito(
                                                imagenParaEnviar,
                                              );
                                          if (!okDeposito) {
                                            throw Exception(
                                              'No se pudo registrar el depósito',
                                            );
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Depósito registrado correctamente.',
                                              ),
                                            ),
                                          );
                                          notifier.limpiarFormulario();
                                          ref
                                              .read(
                                                imageBytesIdentificarProvider
                                                    .notifier,
                                              )
                                              .state = null;
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error: ${e.toString()}',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                      : null,
                              icon: const Icon(Icons.save),
                              label: const Text('Guardar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      ResponsiveUtilsBosque.getResponsiveValue(
                                        context: context,
                                        defaultValue: 16.0,
                                        mobile: 12.0,
                                        desktop: 24.0,
                                      ),
                                  vertical:
                                      ResponsiveUtilsBosque.getResponsiveValue(
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

  Widget _buildMobileFields(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildEmpresaField(context, state, notifier)],
    );
  }

  Widget _buildDesktopFields(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: _buildEmpresaField(context, state, notifier))],
    );
  }

  Widget _buildMobileBancoFields(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildBancoField(context, state, notifier)],
    );
  }

  Widget _buildDesktopBancoFields(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: _buildBancoField(context, state, notifier))],
    );
  }

  Widget _buildMobileImporteFields(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImporteTotalField(context, state, notifier),
        SizedBox(height: ResponsiveUtilsBosque.getVerticalPadding(context)),
        _buildMonedaField(context, state, notifier),
      ],
    );
  }

  Widget _buildDesktopImporteFields(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildImporteTotalField(context, state, notifier)),
        SizedBox(width: ResponsiveUtilsBosque.getHorizontalPadding(context)),
        Expanded(child: _buildMonedaField(context, state, notifier)),
      ],
    );
  }

  Widget _buildEmpresaField(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
    final empresaItems =
        state.empresas
            .map<DropdownMenuItem<dynamic>>(
              (e) => DropdownMenuItem<dynamic>(value: e, child: Text(e.nombre)),
            )
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.business_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
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
          ],
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<dynamic>(
          value: state.empresaSeleccionada,
          items: empresaItems,
          onChanged: (value) {
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

  Widget _buildBancoField(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
    // Si el banco seleccionado ya no está en la lista, lo limpiamos
    final bancos = state.bancos;
    final bancoSeleccionado =
        bancos.contains(state.bancoSeleccionado)
            ? state.bancoSeleccionado
            : null;
    final bancoItems =
        bancos
            .map<DropdownMenuItem<dynamic>>(
              (b) => DropdownMenuItem<dynamic>(
                value: b,
                child: Text(b.nombreBanco),
              ),
            )
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
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
          ],
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<dynamic>(
          value: bancoSeleccionado,
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

  Widget _buildImporteTotalField(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.attach_money,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Importe',
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
          ],
        ),
        SizedBox(height: 8),
        TextFormField(
          initialValue: state.importeTotal.toStringAsFixed(2),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (v) => notifier.setImporteTotal(double.tryParse(v) ?? 0.0),
        ),
      ],
    );
  }

  Widget _buildMonedaField(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
    final monedaOptions = const [
      {'label': 'Bolivianos', 'value': 'BS'},
      {'label': 'Dólares', 'value': 'USD'},
    ];
    final monedaItems =
        monedaOptions
            .map<DropdownMenuItem<String>>(
              (m) => DropdownMenuItem<String>(
                value: m['value']!,
                child: Text(m['label']!),
              ),
            )
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.currency_exchange,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
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
          ],
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

  Widget _buildObservacionesField(BuildContext context, dynamic notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.notes_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Observaciones (opcional)',
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
          ],
        ),
        SizedBox(height: 8),
        TextFormField(
          maxLines: 2,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Ingrese observaciones (opcional)',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (v) => notifier.setObservaciones(v),
        ),
      ],
    );
  }

  bool _isGuardarEnabled(dynamic state) {
    final bancoSeleccionado = state.bancoSeleccionado != null;
    final importeValido = state.importeTotal > 0;
    final empresaSeleccionada = state.empresaSeleccionada != null;
    final monedaSeleccionada =
        state.monedaSeleccionada != null && state.monedaSeleccionada != '';
    final imagen =
        kIsWeb ? ref.read(imageBytesIdentificarProvider) : state.imagenDeposito;
    final imagenCargada = imagen != null;
    return bancoSeleccionado &&
        importeValido &&
        empresaSeleccionada &&
        monedaSeleccionada &&
        imagenCargada;
  }

  Widget _buildImageUploader(
    BuildContext context,
    dynamic state,
    dynamic notifier,
    Uint8List? imageBytes,
    WidgetRef ref,
  ) {
    final dropZoneHeight = ResponsiveUtilsBosque.getResponsiveValue(
      context: context,
      defaultValue: 220.0,
      mobile: 180.0,
      tablet: 220.0,
      desktop: 300.0,
    );
    final maxImageHeight = MediaQuery.of(context).size.height * 0.8;
    final hasImage =
        (kIsWeb && imageBytes != null) ||
        (!kIsWeb && state.imagenDeposito != null);

    Future<void> pickImage(ImageSource source) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          ref.read(imageBytesIdentificarProvider.notifier).state = bytes;
        } else {
          notifier.setImagenDeposito(File(pickedFile.path));
        }
      }
    }

    void showImageSourceActionSheet(BuildContext ctx) {
      showModalBottomSheet(
        context: ctx,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (BuildContext ctx2) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Seleccionar imagen desde',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Galería'),
                    onTap: () {
                      Navigator.pop(ctx2);
                      pickImage(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Cámara'),
                    onTap: () {
                      Navigator.pop(ctx2);
                      pickImage(ImageSource.camera);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = ResponsiveUtilsBosque.getResponsiveValue(
      context: context,
      defaultValue: 8.0,
      mobile: 6.0,
      desktop: 10.0,
    );

    final decoration = BoxDecoration(
      color:
          _isDragging
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: Border.all(
        color: _isDragging ? colorScheme.primary : colorScheme.outline,
        width: _isDragging ? 2.5 : 1.5,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
    );

    void onTap() {
      if (!kIsWeb && ResponsiveUtilsBosque.isMobile(context)) {
        showImageSourceActionSheet(context);
      } else {
        pickImage(ImageSource.gallery);
      }
    }

    if (hasImage) {
      return GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxImageHeight),
          child: Container(
            width: double.infinity,
            decoration: decoration,
            child: _buildImageContent(
              context,
              state,
              notifier,
              imageBytes,
              ref,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: dropZoneHeight,
        width: double.infinity,
        decoration: decoration,
        child: _buildImageContent(context, state, notifier, imageBytes, ref),
      ),
    );
  }

  Widget _buildImageContent(
    BuildContext context,
    dynamic state,
    dynamic notifier,
    Uint8List? imageBytes,
    WidgetRef ref,
  ) {
    final isMobile = !kIsWeb && ResponsiveUtilsBosque.isMobile(context);

    if (kIsWeb && imageBytes != null) {
      return Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.memory(
              imageBytes,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: GestureDetector(
              onTap: () {
                ref.read(imageBytesIdentificarProvider.notifier).state = null;
              },
              child: CircleAvatar(
                radius: ResponsiveUtilsBosque.getResponsiveValue(
                  context: context,
                  defaultValue: 16.0,
                  mobile: 14.0,
                  desktop: 18.0,
                ),
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                child: Icon(
                  Icons.close,
                  size: ResponsiveUtilsBosque.getResponsiveValue(
                    context: context,
                    defaultValue: 18.0,
                    mobile: 16.0,
                    desktop: 20.0,
                  ),
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (!kIsWeb && state.imagenDeposito != null) {
      return Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.file(
              state.imagenDeposito!,
              width: double.infinity,
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
                  defaultValue: 16.0,
                  mobile: 14.0,
                  desktop: 18.0,
                ),
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                child: Icon(
                  Icons.close,
                  size: ResponsiveUtilsBosque.getResponsiveValue(
                    context: context,
                    defaultValue: 18.0,
                    mobile: 16.0,
                    desktop: 20.0,
                  ),
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      final dropColorScheme = Theme.of(context).colorScheme;
      final iconColor = _isDragging ? dropColorScheme.primary : Colors.grey;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child:
                _isDragging
                    ? Icon(
                      Icons.file_download_outlined,
                      key: const ValueKey('drag_icon'),
                      size: ResponsiveUtilsBosque.getResponsiveValue(
                        context: context,
                        defaultValue: 64.0,
                        mobile: 44.0,
                        desktop: 80.0,
                      ),
                      color: dropColorScheme.primary,
                    )
                    : Row(
                      key: const ValueKey('normal_icon'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: ResponsiveUtilsBosque.getResponsiveValue(
                            context: context,
                            defaultValue: 52.0,
                            mobile: 36.0,
                            desktop: 64.0,
                          ),
                          color: iconColor,
                        ),
                        if (isMobile) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.camera_alt_outlined,
                            size: ResponsiveUtilsBosque.getResponsiveValue(
                              context: context,
                              defaultValue: 52.0,
                              mobile: 36.0,
                              desktop: 64.0,
                            ),
                            color: iconColor,
                          ),
                        ],
                      ],
                    ),
          ),
          const SizedBox(height: 14),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: ResponsiveUtilsBosque.getResponsiveValue(
                context: context,
                defaultValue: 14.0,
                mobile: 12.0,
                desktop: 15.0,
              ),
              fontWeight: _isDragging ? FontWeight.w600 : FontWeight.normal,
              color: _isDragging ? dropColorScheme.primary : null,
            ),
            child: Text(
              _isDragging
                  ? 'Suelta la imagen aquí'
                  : isMobile
                  ? 'Toca para capturar o seleccionar imagen'
                  : 'Arrastra y suelta tu imagen aquí o haz clic para seleccionar',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
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
}

//
