import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bosque_flutter/core/state/depositos_cheques_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

final imageBytesIdentificarProvider = StateProvider.autoDispose<Uint8List?>(
  (ref) => null,
);

final depositosChequesIdentificarRegisterProvider =
    StateNotifierProvider.autoDispose<
      DepositosChequesNotifier,
      DepositosChequesState
    >((ref) => DepositosChequesNotifier(ref));

class DepositoChequeIdentificarScreen extends ConsumerStatefulWidget {
  const DepositoChequeIdentificarScreen({super.key});

  @override
  ConsumerState<DepositoChequeIdentificarScreen> createState() =>
      _DepositoChequeIdentificarScreenState();
}

class _DepositoChequeIdentificarScreenState
    extends ConsumerState<DepositoChequeIdentificarScreen> {
  /// Lo que anuncia la zona de carga («JPG, JPEG, PNG. Máximo 5MB»); se valida
  /// porque el texto solo no impide subir un archivo enorme o que no es imagen.
  static const int _maxBytesImagen = 5 * 1024 * 1024;
  static const Set<String> _tiposImagen = {
    'image/jpeg',
    'image/jpg',
    'image/png',
  };
  static const Set<String> _extensionesImagen = {'jpg', 'jpeg', 'png'};

  bool _isDragging = false;
  int _dragCounter = 0;
  final List<StreamSubscription> _dragSubs = [];

  // Controllers propios: con el formulario siempre montado y `initialValue`, lo
  // tecleado se perdía o quedaba desincronizado del estado.
  final TextEditingController _importeCtrl = TextEditingController();
  final TextEditingController _obsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    // El notifier ya no pide red al crearse: cada pantalla pide lo suyo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref
            .read(depositosChequesIdentificarRegisterProvider.notifier)
            .cargarEmpresasSiFalta(),
      );
    });

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
        html.document.onDrop.listen((event) {
          event.preventDefault();
          _dragCounter = 0;
          if (mounted) setState(() => _isDragging = false);
          final files = event.dataTransfer.files;
          if (files != null && files.isNotEmpty) {
            unawaited(_cargarArchivoSoltado(files[0]));
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
    _importeCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  /// `null` si el archivo cumple lo que anuncia la zona de carga; si no, el
  /// motivo del rechazo. [mime] puede venir vacío (móvil): se usa la extensión.
  String? _motivoRechazo({
    required int bytes,
    required String nombre,
    String? mime,
  }) {
    final punto = nombre.lastIndexOf('.');
    final extension = punto < 0 ? '' : nombre.substring(punto + 1);
    final tipoValido =
        _tiposImagen.contains((mime ?? '').toLowerCase()) ||
        _extensionesImagen.contains(extension.toLowerCase());
    if (!tipoValido) return 'El archivo debe ser una imagen JPG, JPEG o PNG.';
    if (bytes > _maxBytesImagen) {
      return 'La imagen supera el tamaño máximo de 5 MB.';
    }
    return null;
  }

  /// Valida y carga la imagen soltada sobre la página (solo web).
  Future<void> _cargarArchivoSoltado(html.File file) async {
    final motivo = _motivoRechazo(
      bytes: file.size,
      nombre: file.name,
      mime: file.type,
    );
    if (motivo != null) {
      if (mounted) mostrarAviso(context, motivo, tono: TonoAviso.aviso);
      return;
    }
    try {
      // ArrayBuffer directo: evita el data URL en base64 y sus copias
      // síncronas en el hilo de UI.
      final reader = html.FileReader()..readAsArrayBuffer(file);
      await reader.onLoadEnd.first;
      final resultado = reader.result;
      final bytes =
          resultado is Uint8List
              ? resultado
              : (resultado is ByteBuffer ? resultado.asUint8List() : null);
      if (bytes == null) throw StateError('No se pudo leer el archivo.');
      if (!mounted) return;
      ref.read(imageBytesIdentificarProvider.notifier).state = bytes;
    } catch (_) {
      if (mounted) {
        mostrarAviso(
          context,
          'No se pudo leer la imagen. Intente de nuevo.',
          tono: TonoAviso.error,
        );
      }
    }
  }

  /// Abre el selector, comprime la foto (la cámara entrega varios MB) y
  /// rechaza lo que no cumple tipo o tamaño.
  Future<void> _elegirImagen(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (pickedFile == null) return;
      final motivo = _motivoRechazo(
        bytes: await pickedFile.length(),
        nombre: pickedFile.name,
        mime: pickedFile.mimeType,
      );
      if (motivo != null) {
        if (mounted) mostrarAviso(context, motivo, tono: TonoAviso.aviso);
        return;
      }
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        if (!mounted) return;
        ref.read(imageBytesIdentificarProvider.notifier).state = bytes;
      } else {
        if (!mounted) return;
        ref
            .read(depositosChequesIdentificarRegisterProvider.notifier)
            .setImagenDeposito(File(pickedFile.path));
      }
    } catch (_) {
      if (mounted) {
        mostrarAviso(
          context,
          'No se pudo cargar la imagen. Intente de nuevo.',
          tono: TonoAviso.error,
        );
      }
    }
  }

  /// Quita la foto en ambas plataformas (web guarda bytes; móvil, un archivo).
  void _quitarImagen() {
    ref
        .read(depositosChequesIdentificarRegisterProvider.notifier)
        .setImagenDeposito(null);
    ref.read(imageBytesIdentificarProvider.notifier).state = null;
  }

  /// Vacía estado, campos de texto y foto.
  void _limpiarFormulario() {
    ref
        .read(depositosChequesIdentificarRegisterProvider.notifier)
        .limpiarFormulario();
    _importeCtrl.clear();
    _obsCtrl.clear();
    ref.read(imageBytesIdentificarProvider.notifier).state = null;
  }

  /// «12,5» (coma decimal, es-BO) y «1.234,50» se leen bien; lo inválido da 0.
  double _leerImporte(String texto) {
    var t = texto.trim();
    final coma = t.lastIndexOf(',');
    final punto = t.lastIndexOf('.');
    if (coma >= 0 && punto >= 0) {
      // Con ambos separadores, el último es el decimal y el otro es de miles.
      t =
          coma > punto
              ? t.replaceAll('.', '').replaceAll(',', '.')
              : t.replaceAll(',', '');
    } else {
      t = t.replaceAll(',', '.');
    }
    return double.tryParse(t) ?? 0.0;
  }

  /// Elige la empresa sin bajar clientes (esta pantalla no los usa). El
  /// notifier reinicia el importe al cambiar de empresa; como el campo conserva
  /// lo tecleado, se restituye. La parte síncrona de `seleccionarEmpresa` ya
  /// fijó el estado cuando retorna, por eso el orden.
  void _elegirEmpresa(dynamic notifier, dynamic empresa) {
    final importe = _leerImporte(_importeCtrl.text);
    unawaited(notifier.seleccionarEmpresa(empresa, cargarClientes: false));
    notifier.setImporteTotal(importe);
  }

  /// Lo que falta para poder guardar; vacío si ya se puede.
  List<String> _faltantes(DepositosChequesState state) {
    final empresa = state.empresaSeleccionada;
    final imagen =
        kIsWeb ? ref.read(imageBytesIdentificarProvider) : state.imagenDeposito;
    return [
      if (empresa == null || empresa.codEmpresa == 0) 'empresa',
      if (state.bancoSeleccionado == null) 'banco',
      if (state.monedaSeleccionada.isEmpty) 'moneda',
      if (state.importeTotal <= 0) 'importe mayor a 0',
      if (imagen == null) 'imagen del depósito',
    ];
  }

  Future<void> _guardar() async {
    final provider = depositosChequesIdentificarRegisterProvider;
    final state = ref.read(provider);
    final notifier = ref.read(provider.notifier);
    // Segundo toque antes de que el botón se deshabilite en pantalla.
    if (state.guardando) return;

    final faltantes = _faltantes(state);
    if (faltantes.isNotEmpty) {
      mostrarAviso(
        context,
        'Falta completar: ${faltantes.join(', ')}.',
        tono: TonoAviso.aviso,
      );
      return;
    }
    final Object? imagenParaEnviar =
        kIsWeb ? ref.read(imageBytesIdentificarProvider) : state.imagenDeposito;
    try {
      final ok = await notifier.registrarDeposito(imagenParaEnviar);
      if (!mounted) return;
      if (!ok) {
        mostrarAviso(
          context,
          'No se pudo registrar el depósito.',
          tono: TonoAviso.error,
        );
        return;
      }
      mostrarAviso(context, 'Depósito registrado correctamente.');
      _limpiarFormulario();
    } catch (e) {
      // `registrarDeposito` lanza con el motivo real (timeout, 500, backend).
      if (!mounted) return;
      mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
    }
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
    final faltantes = _faltantes(state);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Depósitos por Identificar'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
        // Alto fijo (2 px) esté o no cargando: el formulario no se desplaza y
        // nunca se desmonta por una operación en curso.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: SizedBox(
            height: 2,
            child: state.cargando ? const LinearProgressIndicator() : null,
          ),
        ),
      ),
      body: SingleChildScrollView(
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
                height: ResponsiveUtilsBosque.getVerticalPadding(context),
              ),
              isMobile
                  ? _buildMobileBancoFields(context, state, notifier)
                  : _buildDesktopBancoFields(context, state, notifier),
              SizedBox(
                height: ResponsiveUtilsBosque.getVerticalPadding(context),
              ),
              isMobile
                  ? _buildMobileImporteFields(context, state, notifier)
                  : _buildDesktopImporteFields(context, state, notifier),
              SizedBox(
                height: ResponsiveUtilsBosque.getVerticalPadding(context) * 1.5,
              ),
              _buildObservacionesField(context, notifier),
              SizedBox(
                height: ResponsiveUtilsBosque.getVerticalPadding(context) * 1.5,
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
                height: ResponsiveUtilsBosque.getVerticalPadding(context) * 0.5,
              ),
              _buildImageUploader(context, state, notifier, imageBytes, ref),
              SizedBox(
                height: ResponsiveUtilsBosque.getVerticalPadding(context) * 1.5,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton(
                      // No se limpia mientras se guarda: vaciaría el
                      // formulario a mitad de la subida.
                      onPressed: state.guardando ? null : _limpiarFormulario,
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
                      onPressed:
                          faltantes.isEmpty && !state.guardando
                              ? _guardar
                              : null,
                      icon:
                          state.guardando
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.save),
                      label: Text(state.guardando ? 'Guardando…' : 'Guardar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
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
              if (!state.guardando && faltantes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Para guardar falta: ${faltantes.join(', ')}.',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
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
    // «Todos» (codEmpresa 0) sirve para filtrar consultas, no para registrar:
    // dejaba los bancos vacíos.
    final empresas = state.empresas.where((e) => e.codEmpresa != 0).toList();
    final empresaSeleccionada =
        empresas.contains(state.empresaSeleccionada)
            ? state.empresaSeleccionada
            : null;
    final empresaItems =
        empresas
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
            if (state.cargandoEmpresas) _cargandoCampo(),
          ],
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<dynamic>(
          value: empresaSeleccionada,
          items: empresaItems,
          onChanged:
              state.cargandoEmpresas
                  ? null
                  : (value) => _elegirEmpresa(notifier, value),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText:
                state.cargandoEmpresas
                    ? 'Cargando empresas…'
                    : 'Seleccione una empresa',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          isExpanded: true,
        ),
        if (state.error != null &&
            state.errorEn == OperacionCarga.empresas &&
            !state.cargandoEmpresas) ...[
          const SizedBox(height: 8),
          MensajeError(
            error: state.error,
            compacto: true,
            onReintentar: notifier.reintentarUltimaCarga,
          ),
        ],
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
            if (state.cargandoBancos) _cargandoCampo(),
          ],
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<dynamic>(
          value: bancoSeleccionado,
          items: bancoItems,
          onChanged:
              state.cargandoBancos
                  ? null
                  : (value) => notifier.seleccionarBanco(value),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText:
                state.cargandoBancos
                    ? 'Cargando bancos…'
                    : 'Seleccione un banco',
            // Un combo vacío y deshabilitado no explica por qué.
            helperText:
                state.empresaSeleccionada != null &&
                        !state.cargandoBancos &&
                        state.error == null &&
                        bancos.isEmpty
                    ? 'Esta empresa no tiene bancos disponibles.'
                    : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          isExpanded: true,
        ),
        if (state.error != null &&
            state.errorEn == OperacionCarga.bancos &&
            !state.cargandoBancos) ...[
          const SizedBox(height: 8),
          MensajeError(
            error: state.error,
            compacto: true,
            onReintentar: notifier.reintentarUltimaCarga,
          ),
        ],
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
          controller: _importeCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '0.00',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (v) => notifier.setImporteTotal(_leerImporte(v)),
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
          controller: _obsCtrl,
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

  /// Indicador junto a la etiqueta de un combo que se está cargando.
  Widget _cargandoCampo() => const Padding(
    padding: EdgeInsets.only(left: 8),
    child: SizedBox(
      width: 12,
      height: 12,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );

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
                      _elegirImagen(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Cámara'),
                    onTap: () {
                      Navigator.pop(ctx2);
                      _elegirImagen(ImageSource.camera);
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
        _elegirImagen(ImageSource.gallery);
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
            // cacheWidth: se muestra a lo ancho de la pantalla, no hace falta
            // decodificar la foto completa.
            child: Image.memory(
              imageBytes,
              width: double.infinity,
              fit: BoxFit.contain,
              cacheWidth: 1200,
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: GestureDetector(
              onTap: _quitarImagen,
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
              cacheWidth: 1200,
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: GestureDetector(
              onTap: _quitarImagen,
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
