import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bosque_flutter/core/state/depositos_cheques_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/shared/aviso.dart';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

// Proveedor para almacenar los bytes de la imagen (necesario para web).
// autoDispose: la foto de una visita anterior no reaparece al volver.
final imageBytesProvider = StateProvider.autoDispose<Uint8List?>((ref) => null);

// autoDispose: cada visita arranca con estado fresco. La pantalla lo observa
// con `ref.watch` mientras está abierta, así que no se descarta antes.
final depositosChequesRegisterProvider = StateNotifierProvider.autoDispose<
  DepositosChequesNotifier,
  DepositosChequesState
>((ref) => DepositosChequesNotifier(ref));

class DepositoChequeRegisterScreen extends ConsumerStatefulWidget {
  const DepositoChequeRegisterScreen({super.key});

  @override
  ConsumerState<DepositoChequeRegisterScreen> createState() =>
      _DepositoChequeRegisterScreenState();
}

class _DepositoChequeRegisterScreenState
    extends ConsumerState<DepositoChequeRegisterScreen> {
  // Tope que anuncia la etiqueta de la zona de carga y que se valida al elegir.
  static const int _maxMbImagen = 5;
  static const int _maxBytesImagen = _maxMbImagen * 1024 * 1024;

  bool _isDragging = false;
  int _dragCounter = 0;
  final List<StreamSubscription> _dragSubs = [];

  // En el State y no en build: un controller creado en build se recrea en cada
  // rebuild (pierde cursor y selección) y nunca se libera.
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _aCuentaController = TextEditingController(
    text: '0.00',
  );

  @override
  void initState() {
    super.initState();
    // El provider es autoDispose: el estado ya llega limpio en cada visita.
    // Solo se piden las empresas (si faltan) y se hace después del primer frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(depositosChequesRegisterProvider.notifier)
          .cargarEmpresasSiFalta();
    });

    // Los campos de texto no leen el estado por sí solos: se sincronizan cuando
    // cambia el cliente o se limpia el formulario.
    ref.listenManual<String>(
      depositosChequesRegisterProvider.select(
        (s) => s.clienteSeleccionado?.nombreCompleto ?? '',
      ),
      (_, nombre) {
        if (_clienteController.text != nombre) _clienteController.text = nombre;
      },
    );
    ref.listenManual<double>(
      depositosChequesRegisterProvider.select((s) => s.aCuenta),
      (_, aCuenta) {
        // Solo si difiere de lo escrito: no pisa lo que se está tecleando.
        if ((double.tryParse(_aCuentaController.text) ?? 0.0) != aCuenta) {
          _aCuentaController.text = aCuenta.toStringAsFixed(2);
        }
      },
    );

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
            if (!file.type.startsWith('image/')) {
              if (mounted) {
                mostrarAviso(
                  context,
                  'Solo se pueden cargar imágenes.',
                  tono: TonoAviso.aviso,
                );
              }
              return;
            }
            // El tamaño se valida antes de leer: no se copia un archivo que se
            // va a rechazar.
            if (file.size > _maxBytesImagen) {
              if (mounted) _avisarImagenGrande();
              return;
            }
            // readAsArrayBuffer entrega los bytes directo; con readAsDataUrl
            // eran cuatro copias en el hilo de la UI (base64, split, decode).
            final reader = html.FileReader();
            reader.readAsArrayBuffer(file);
            await reader.onLoadEnd.first;
            final resultado = reader.result;
            final bytes =
                resultado is Uint8List
                    ? resultado
                    : resultado is ByteBuffer
                    ? resultado.asUint8List()
                    : null;
            if (bytes != null && mounted) {
              ref.read(imageBytesProvider.notifier).state = bytes;
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
    _clienteController.dispose();
    _aCuentaController.dispose();
    super.dispose();
  }

  void _avisarImagenGrande() {
    mostrarAviso(
      context,
      'La imagen supera el tamaño máximo de $_maxMbImagen MB. Elija una más liviana.',
      tono: TonoAviso.aviso,
    );
  }

  String _conPunto(String texto) {
    final t = texto.trim();
    return t.endsWith('.') || t.endsWith('!') || t.endsWith('?') ? t : '$t.';
  }

  // Un solo llamado guarda depósito y notas (en lotes). Si algo queda a medias
  // el formulario se conserva: el siguiente Guardar reenvía solo lo pendiente.
  Future<void> _guardarDeposito(
    DepositosChequesNotifier notifier,
    Object imagen,
  ) async {
    try {
      final r = await notifier.guardarDepositoConNotas(imagen);
      // Sin pantalla ya no hay dónde avisar ni nada que limpiar.
      if (!mounted || r.ignorado) return;
      if (!r.depositoOk) {
        mostrarAviso(
          context,
          'No se pudo registrar el depósito.',
          tono: TonoAviso.error,
        );
      } else if (!r.notas.ok) {
        final faltan = r.notas.fallidas.length;
        final motivo =
            r.notas.error == null
                ? ''
                : ' ${_conPunto(textoParaUsuario(r.notas.error))}';
        mostrarAviso(
          context,
          'El depósito quedó registrado, pero '
          '${faltan == 1 ? 'falta 1 nota' : 'faltan $faltan notas'} de remisión '
          'por guardar.$motivo Vuelva a pulsar Guardar: se reenviarán solo las '
          'pendientes.',
          tono: TonoAviso.aviso,
        );
      } else {
        mostrarAviso(
          context,
          'Depósito y notas de remisión registrados correctamente.',
        );
        notifier.limpiarFormulario();
        ref.read(imageBytesProvider.notifier).state = null;
      }
    } catch (e) {
      if (!mounted) return;
      mostrarAviso(
        context,
        'No se pudo registrar el depósito. ${_conPunto(textoParaUsuario(e))}',
        tono: TonoAviso.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(depositosChequesRegisterProvider);
    final notifier = ref.read(depositosChequesRegisterProvider.notifier);
    final imageBytes = ref.watch(imageBytesProvider);

    // Determinar si estamos en móvil o desktop
    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    // Obtener los paddings responsivos
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(
      context,
    );
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Depósitos'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
        // Barra de altura fija: avisa que hay algo en curso sin desmontar el
        // formulario ni mover el contenido al aparecer.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: SizedBox(
            height: 3,
            child: state.cargando ? const LinearProgressIndicator() : null,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        // Mientras se guarda no se edita: cambiar empresa o cliente a
        // mitad del guardado dejaría notas sin enviar.
        child: IgnorePointer(
          ignoring: state.guardando,
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
                // Layout responsivo para empresa y cliente
                isMobile
                    ? _buildMobileFields(context, state, notifier)
                    : _buildDesktopFields(context, state, notifier),
                // Fallo de una carga (empresas, clientes, bancos o notas)
                if (state.error != null) ...[
                  SizedBox(
                    height: ResponsiveUtilsBosque.getVerticalPadding(context),
                  ),
                  MensajeError(
                    error: state.error,
                    compacto: true,
                    onReintentar: notifier.reintentarUltimaCarga,
                  ),
                ],
                // Tabla de notas de remisión
                if (state.notasRemision.isNotEmpty) ...[
                  SizedBox(
                    height: ResponsiveUtilsBosque.getVerticalPadding(context),
                  ),
                  _buildNotasRemisionTable(context, state, notifier),
                ] else if (state.cargandoNotas) ...[
                  SizedBox(
                    height: ResponsiveUtilsBosque.getVerticalPadding(context),
                  ),
                  _buildNotasCargando(),
                ],

                SizedBox(
                  height: ResponsiveUtilsBosque.getVerticalPadding(context),
                ),

                // Layout responsivo para cuenta y banco
                isMobile
                    ? _buildMobileBancoFields(context, state, notifier)
                    : _buildDesktopBancoFields(context, state, notifier),

                SizedBox(
                  height: ResponsiveUtilsBosque.getVerticalPadding(context),
                ),

                // Layout responsivo para importe y moneda
                isMobile
                    ? _buildMobileImporteFields(context, state, notifier)
                    : _buildDesktopImporteFields(context, state, notifier),

                SizedBox(
                  height:
                      ResponsiveUtilsBosque.getVerticalPadding(context) * 1.5,
                ),

                // Sección de imagen del depósito
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
                      ResponsiveUtilsBosque.getVerticalPadding(context) * 0.5,
                ),

                // Pasamos el imageBytes y ref para manejo multiplataforma
                _buildImageUploader(context, state, notifier, imageBytes, ref),

                SizedBox(
                  height:
                      ResponsiveUtilsBosque.getVerticalPadding(context) * 1.5,
                ),

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
                            horizontal:
                                ResponsiveUtilsBosque.getResponsiveValue(
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
                            (_isGuardarEnabled(state, ref) && !state.guardando)
                                ? () async {
                                  final tieneNotas =
                                      state.notasSeleccionadas.isNotEmpty;
                                  final tieneACuenta = state.aCuenta > 0;
                                  if (state.bancoSeleccionado == null) {
                                    mostrarAviso(
                                      context,
                                      'Debe seleccionar un banco.',
                                      tono: TonoAviso.aviso,
                                    );
                                    return;
                                  }
                                  if (!(tieneNotas || tieneACuenta) ||
                                      state.importeTotal <= 0) {
                                    mostrarAviso(
                                      context,
                                      'Debe seleccionar al menos una nota de remisión o ingresar un valor a cuenta mayor a 0. El importe total debe ser mayor a 0.',
                                      tono: TonoAviso.aviso,
                                    );
                                    return;
                                  }
                                  final imageBytes = ref.read(
                                    imageBytesProvider,
                                  );
                                  final imagen =
                                      kIsWeb
                                          ? imageBytes
                                          : state.imagenDeposito;
                                  if (imagen == null) {
                                    mostrarAviso(
                                      context,
                                      'Debe cargar una imagen del depósito.',
                                      tono: TonoAviso.aviso,
                                    );
                                    return;
                                  }
                                  await _guardarDeposito(notifier, imagen);
                                }
                                : null,
                        icon:
                            state.guardando
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
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
                            horizontal:
                                ResponsiveUtilsBosque.getResponsiveValue(
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
      ),
    );
  }

  // Widget para los campos de empresa y cliente en móvil (columna)
  Widget _buildMobileFields(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
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
  Widget _buildDesktopFields(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
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
  Widget _buildMobileBancoFields(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
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
  Widget _buildDesktopBancoFields(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
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

  // Widget para los campos de Importe y Moneda en desktop (fila)
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

  // Campo de Empresa
  Widget _buildEmpresaField(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
    // Corregir el error de tipo generando explícitamente los DropdownMenuItem<dynamic>
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
          key: ValueKey(
            'reg-empresa-${state.empresaSeleccionada?.codEmpresa ?? 0}_${state.empresas.length}',
          ),
          value: state.empresaSeleccionada,
          items: empresaItems,
          onChanged: (value) {
            notifier.seleccionarEmpresa(value);
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText:
                state.cargandoEmpresas
                    ? 'Cargando empresas…'
                    : 'Seleccione una empresa',
            suffixIcon: _spinnerCampo(state.cargandoEmpresas),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          isExpanded: true,
        ),
      ],
    );
  }

  // Indicador chico dentro del campo mientras se cargan sus opciones.
  Widget? _spinnerCampo(bool cargando) {
    if (!cargando) return null;
    return const Padding(
      padding: EdgeInsets.all(12),
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  // Campo de Cliente con búsqueda
  Widget _buildClienteField(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
    final bool cargandoClientes = state.cargandoClientes;
    final empresa = state.empresaSeleccionada;
    // La opción "Todos" siempre va primero: sin clientes reales la lista solo
    // la tiene a ella. No se avisa mientras carga ni si la carga falló (ahí
    // manda el MensajeError con su Reintentar).
    final sinClientes =
        empresa != null &&
        empresa.codEmpresa != 0 &&
        !cargandoClientes &&
        state.error == null &&
        !(state.clientes as List).any((c) => c.codCliente != '');

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
        sinClientes
            ? const NotaDelDato(
              texto: 'No existen clientes para la empresa seleccionada.',
              tono: TonoNota.aviso,
            )
            : TextField(
              readOnly: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText:
                    cargandoClientes ? 'Cargando clientes…' : 'Buscar cliente',
                prefixIcon: const Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                suffixIcon:
                    cargandoClientes
                        ? _spinnerCampo(true)
                        : state.clienteSeleccionado != null
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => notifier.seleccionarCliente(null),
                        )
                        : null,
              ),
              controller: _clienteController,
              onTap:
                  cargandoClientes
                      ? null
                      : () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => ClienteSearchDialog(
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
    );
  }

  // Campo de A Cuenta
  Widget _buildACuentaField(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
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
          // Controller (no initialValue): así limpiarFormulario lo vacía.
          controller: _aCuentaController,
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
  Widget _buildBancoField(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
    // Corregir el error de tipo generando explícitamente los DropdownMenuItem<dynamic>
    final bancoItems =
        state.bancos
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
        DropdownButtonFormField<dynamic>(
          key: ValueKey(
            'reg-banco-${state.empresaSeleccionada?.codEmpresa ?? 0}_${state.bancos.length}',
          ),
          value: state.bancoSeleccionado,
          items: bancoItems,
          onChanged: (value) => notifier.seleccionarBanco(value),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText:
                state.cargandoBancos
                    ? 'Cargando bancos…'
                    : 'Seleccione un banco',
            suffixIcon: _spinnerCampo(state.cargandoBancos),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          isExpanded: true,
        ),
      ],
    );
  }

  // Campo de Importe Total (solo lectura y calculado en tiempo real)
  Widget _buildImporteTotalField(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
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
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(4),
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withValues(alpha: 0.5),
          ),
          child: Text(
            state.importeTotal.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  // Campo de Moneda
  Widget _buildMonedaField(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
    // Opciones con label y valor
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

    // Función para seleccionar/capturar imagen desde móvil o web
    Future<void> pickImage(ImageSource source) async {
      final picker = ImagePicker();
      // Se comprime al elegir: una foto de cámara pesa varios MB y viajaba tal
      // cual al servidor. Mismos valores que la pantalla de identificar.
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (pickedFile != null) {
        if (kIsWeb) {
          // Para web, leemos los bytes directamente
          final bytes = await pickedFile.readAsBytes();
          if (!mounted) return;
          if (bytes.length > _maxBytesImagen) {
            _avisarImagenGrande();
            return;
          }
          ref.read(imageBytesProvider.notifier).state = bytes;
        } else {
          final tamano = await pickedFile.length();
          if (!mounted) return;
          if (tamano > _maxBytesImagen) {
            _avisarImagenGrande();
            return;
          }
          // Para móvil, usamos el File normalmente
          notifier.setImagenDeposito(File(pickedFile.path));
        }
      }
    }

    // Función para mostrar el modal de selección de origen de imagen en móvil
    void showImageSourceActionSheet(BuildContext context) {
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Galería'),
                    onTap: () {
                      Navigator.pop(context);
                      pickImage(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Cámara'),
                    onTap: () {
                      Navigator.pop(context);
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

  // Contenido de la imagen - COMPATIBLE CON WEB Y MÓVIL
  Widget _buildImageContent(
    BuildContext context,
    dynamic state,
    dynamic notifier,
    Uint8List? imageBytes,
    WidgetRef ref,
  ) {
    final isMobile = !kIsWeb && ResponsiveUtilsBosque.isMobile(context);

    // Si estamos en web y tenemos bytes de imagen
    if (kIsWeb && imageBytes != null) {
      return Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            // cacheWidth: la vista previa no necesita decodificar la foto entera.
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
              onTap: () {
                // Eliminar la imagen en web
                ref.read(imageBytesProvider.notifier).state = null;
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
    }
    // Si no estamos en web y tenemos una imagen de archivo
    else if (!kIsWeb && state.imagenDeposito != null) {
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
    }
    // Si no hay imagen seleccionada
    else {
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
            'Formatos permitidos: JPG, JPEG, PNG. Tamaño máximo: ${_maxMbImagen}MB',
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

  // Ocupa el lugar de la tabla mientras se piden las notas del cliente.
  Widget _buildNotasCargando() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documentos Disponibles',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Cargando documentos del cliente…'),
            ],
          ),
        ),
      ],
    );
  }

  // Widget para la tabla de notas de remisión
  Widget _buildNotasRemisionTable(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final notas = state.notasRemision;
    final seleccionadas = state.notasSeleccionadas;
    final saldosEditados = state.saldosEditados;
    double totalSeleccionados = 0;
    for (var nota in notas) {
      if (seleccionadas.contains(nota.docNum)) {
        totalSeleccionados +=
            saldosEditados[nota.docNum]?.toDouble() ??
            nota.saldoPendiente.toDouble();
      }
    }
    final double nuevoImporteTotal = totalSeleccionados + (state.aCuenta ?? 0);
    if (state.importeTotal != nuevoImporteTotal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.setImporteTotal(nuevoImporteTotal);
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documentos Disponibles',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezados
                Container(
                  color: colorScheme.surfaceVariant.withValues(alpha: 0.4),
                  child: Row(
                    children: [
                      _buildTableHeader('Selección', 80),
                      _buildTableHeader('Número de Documento', 180),
                      _buildTableHeader('Num. Factura', 120),
                      _buildTableHeader('Fecha', 120),
                      _buildTableHeader('Cliente', 180),
                      _buildTableHeader('Total (Bs)', 120),
                      _buildTableHeader('Saldo Pendiente (Bs)', 200),
                    ],
                  ),
                ),
                // Filas
                ...notas.map((nota) {
                  final bool seleccionado = seleccionadas.contains(nota.docNum);
                  final saldoValue =
                      saldosEditados[nota.docNum]?.toString() ??
                      nota.saldoPendiente.toString();

                  return Container(
                    color:
                        seleccionado
                            ? Colors.green.withValues(alpha: 0.1)
                            : colorScheme.surface,
                    child: Row(
                      children: [
                        // Cambia aquí: usa Checkbox real
                        Container(
                          width: 80,
                          padding: EdgeInsets.all(8),
                          child: Center(
                            child: Checkbox(
                              value: seleccionado,
                              onChanged: (checked) {
                                notifier.seleccionarNota(
                                  nota.docNum,
                                  checked ?? false,
                                );
                              },
                              activeColor: Colors.green,
                            ),
                          ),
                        ),
                        _buildTableCell(nota.docNum.toString(), 180),
                        _buildTableCell(nota.numFact.toString(), 120),
                        _buildTableCell(
                          '${nota.fecha.day.toString().padLeft(2, '0')}/${nota.fecha.month.toString().padLeft(2, '0')}/${nota.fecha.year}',
                          120,
                        ),
                        _buildTableCell(nota.nombreCliente, 180),
                        _buildTableCell(nota.totalMonto.toString(), 120),
                        Container(
                          width: 200,
                          padding: EdgeInsets.all(8),
                          child:
                              seleccionado
                                  ? _EditableSaldoPendienteCell(
                                    valorOriginal: nota.saldoPendiente,
                                    valorActual: saldoValue,
                                    onChanged: (v, showError) {
                                      final val = double.tryParse(v) ?? 0.0;
                                      if (val <= nota.saldoPendiente) {
                                        notifier.editarSaldoPendiente(
                                          nota.docNum,
                                          val,
                                        );
                                      }
                                      showError(val > nota.saldoPendiente);
                                    },
                                  )
                                  : Text(
                                    nota.saldoPendiente.toString(),
                                    textAlign: TextAlign.center,
                                  ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            Text(
              'Total de documentos: ${notas.length}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Documentos seleccionados: ${seleccionadas.length}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Total seleccionado: ${totalSeleccionados.toStringAsFixed(2)} Bs',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableHeader(String text, double width) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text, double width) {
    return Container(
      width: width,
      padding: EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  bool _isGuardarEnabled(DepositosChequesState state, WidgetRef ref) {
    final tieneNotas = state.notasSeleccionadas.isNotEmpty;
    final tieneACuenta = state.aCuenta > 0;
    final bancoSeleccionado = state.bancoSeleccionado != null;
    final imagen = kIsWeb ? ref.read(imageBytesProvider) : state.imagenDeposito;
    final imagenCargada = imagen != null;
    final importeValido = state.importeTotal > 0;
    // Validar que todos los saldos editados sean <= al original. Búsqueda por
    // docNum sin firstWhere: una selección sin nota (lista ya cambiada) lanzaba
    // StateError en pleno build.
    final notasPorDoc = {for (final n in state.notasRemision) n.docNum: n};
    final saldosValidos = state.notasSeleccionadas.every((docNum) {
      final nota = notasPorDoc[docNum];
      // Selección huérfana: no hay nota que guardar, no se habilita.
      if (nota == null) return false;
      final saldoEditado = state.saldosEditados[docNum] ?? nota.saldoPendiente;
      return saldoEditado <= nota.saldoPendiente;
    });
    return bancoSeleccionado &&
        imagenCargada &&
        importeValido &&
        (tieneNotas || tieneACuenta) &&
        saldosValidos;
  }
}

// Diálogo de búsqueda de clientes
class ClienteSearchDialog extends StatefulWidget {
  final List<dynamic> clientes;
  final Function(dynamic) onClienteSelected;

  const ClienteSearchDialog({
    super.key,
    required this.clientes,
    required this.onClienteSelected,
  });

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
        _filteredClientes =
            widget.clientes
                .where(
                  (cliente) => cliente.nombreCompleto.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
                )
                .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final dialogWidth =
        isDesktop
            ? MediaQuery.of(context).size.width * 0.4
            : MediaQuery.of(context).size.width * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  maxHeight:
                      MediaQuery.of(context).size.height *
                      (isDesktop ? 0.6 : 0.4),
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

// Widget para celda editable de saldo pendiente con validación y error en tiempo real
class _EditableSaldoPendienteCell extends StatefulWidget {
  final double valorOriginal;
  final String valorActual;
  final void Function(String, void Function(bool)) onChanged;
  const _EditableSaldoPendienteCell({
    required this.valorOriginal,
    required this.valorActual,
    required this.onChanged,
  });

  @override
  State<_EditableSaldoPendienteCell> createState() =>
      _EditableSaldoPendienteCellState();
}

class _EditableSaldoPendienteCellState
    extends State<_EditableSaldoPendienteCell> {
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
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.vertical,
      crossAxisAlignment: WrapCrossAlignment.start,
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
                  _errorText =
                      show ? 'No puede ser mayor al saldo original' : null;
                });
              });
            },
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              errorText: null, // No uses errorText aquí, lo mostramos abajo
            ),
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: Text(
              _errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
